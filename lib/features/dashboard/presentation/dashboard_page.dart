import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/money.dart';
import '../../products/data/product_repository.dart';
import '../../reports/data/csv_report_exporter.dart';
import '../../reports/data/daily_profit_repository.dart';
import '../../reports/domain/profit_calculator.dart';

enum _ProfitRange { today, week, month, custom }

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  _ProfitRange _range = _ProfitRange.today;
  DateTimeRange? _customRange;
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final range = _selectedRange;
    final report = ref.watch(
      dailyProfitsProvider(ProfitDateRange(start: range.start, end: range.end)),
    );
    final lowStockProducts = (ref.watch(productsProvider).asData?.value ?? [])
        .where(
          (product) =>
              !product.isArchived &&
              product.lowStockThreshold != null &&
              product.stockQuantity <= product.lowStockThreshold!,
        )
        .toList();
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_longDate(now), style: _eyebrow),
                  const SizedBox(height: 7),
                  Text(greeting, style: _greeting),
                  const SizedBox(height: 3),
                  const Text(
                    'Your business, at a glance',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.roseLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_outlined,
                color: AppColors.rose,
                size: 19,
              ),
            ),
          ],
        ),
        if (lowStockProducts.isNotEmpty) ...[
          const SizedBox(height: 17),
          _LowStockAlert(products: lowStockProducts),
          const SizedBox(height: 19),
        ] else
          const SizedBox(height: 23),
        Wrap(
          spacing: 7,
          children: _ProfitRange.values.map((preset) {
            final label = switch (preset) {
              _ProfitRange.today => 'Today',
              _ProfitRange.week => '7 days',
              _ProfitRange.month => '30 days',
              _ProfitRange.custom =>
                _range == _ProfitRange.custom && _customRange != null
                    ? 'Custom'
                    : 'Choose dates',
            };
            return ChoiceChip(
              label: Text(label),
              selected: _range == preset,
              showCheckmark: false,
              onSelected: (_) => preset == _ProfitRange.custom
                  ? _chooseRange()
                  : setState(() => _range = preset),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        report.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(50),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const _ReportError(),
          data: (days) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Builder(
                  builder: (buttonContext) => TextButton.icon(
                    onPressed: _exporting
                        ? null
                        : () => _exportCsv(buttonContext, days, range),
                    icon: _exporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.file_download_outlined, size: 17),
                    label: Text(_exporting ? 'Preparing…' : 'Export CSV'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.rose,
                    ),
                  ),
                ),
              ),
              _ReportContent(days: days, rangeLabel: _rangeLabel),
            ],
          ),
        ),
      ],
    );
  }

  DateTimeRange get _selectedRange {
    final today = DateTime.now();
    final end = DateTime(today.year, today.month, today.day);
    return switch (_range) {
      _ProfitRange.today => DateTimeRange(start: end, end: end),
      _ProfitRange.week => DateTimeRange(
        start: end.subtract(const Duration(days: 6)),
        end: end,
      ),
      _ProfitRange.month => DateTimeRange(
        start: end.subtract(const Duration(days: 29)),
        end: end,
      ),
      _ProfitRange.custom =>
        _customRange ??
            DateTimeRange(
              start: end.subtract(const Duration(days: 6)),
              end: end,
            ),
    };
  }

  String get _rangeLabel => switch (_range) {
    _ProfitRange.today => 'Today',
    _ProfitRange.week => 'Last 7 days',
    _ProfitRange.month => 'Last 30 days',
    _ProfitRange.custom => 'Selected period',
  };

  Future<void> _exportCsv(
    BuildContext buttonContext,
    List<DailyProfit> days,
    DateTimeRange range,
  ) async {
    setState(() => _exporting = true);
    try {
      final renderObject = buttonContext.findRenderObject();
      final box = renderObject is RenderBox ? renderObject : null;
      await const CsvReportExporter().share(
        days,
        range: range,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not export this report.')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _chooseRange() async {
    final today = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year, today.month, today.day),
      initialDateRange: _customRange ?? _selectedRange,
      helpText: 'Choose a report period',
    );
    if (picked != null && mounted) {
      if (picked.duration.inDays > 364) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Choose a period of 12 months or less.'),
          ),
        );
        return;
      }
      setState(() {
        _customRange = DateTimeRange(
          start: DateTime(
            picked.start.year,
            picked.start.month,
            picked.start.day,
          ),
          end: DateTime(picked.end.year, picked.end.month, picked.end.day),
        );
        _range = _ProfitRange.custom;
      });
    }
  }
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({required this.days, required this.rangeLabel});

  final List<DailyProfit> days;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final summary = _combine(days);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfitCard(summary: summary, label: rangeLabel),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Sales',
                value: formatKes(summary.salesRevenueMinor),
                icon: Icons.south_west_rounded,
                tint: AppColors.sageLight,
                iconColor: AppColors.sage,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _MetricCard(
                label: 'Cost of goods',
                value: formatKes(summary.costOfGoodsSoldMinor),
                icon: Icons.inventory_2_outlined,
                tint: AppColors.roseLight,
                iconColor: AppColors.rose,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _MetricCard(
                label: 'Expenses',
                value: formatKes(summary.operatingExpensesMinor),
                icon: Icons.north_east_rounded,
                tint: AppColors.cream,
                iconColor: AppColors.plum,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Daily net profit', style: _section),
        const SizedBox(height: 10),
        _DailyChart(days: days),
        const SizedBox(height: 23),
        Row(
          children: [
            const Expanded(child: Text('Day-by-day', style: _section)),
            Text(rangeLabel, style: _caption),
          ],
        ),
        const SizedBox(height: 9),
        ...days.reversed.map(
          (day) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _DailyProfitTile(day: day),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Profit uses recorded sales, product costs, and active expenses.',
          style: TextStyle(color: AppColors.muted, fontSize: 10, height: 1.4),
        ),
      ],
    );
  }

  ProfitSummary _combine(List<DailyProfit> days) {
    var revenue = 0;
    var costs = 0;
    var expenses = 0;
    for (final day in days) {
      revenue += day.summary.salesRevenueMinor;
      costs += day.summary.costOfGoodsSoldMinor;
      expenses += day.summary.operatingExpensesMinor;
    }
    final gross = revenue - costs;
    return ProfitSummary(
      salesRevenueMinor: revenue,
      costOfGoodsSoldMinor: costs,
      grossProfitMinor: gross,
      operatingExpensesMinor: expenses,
      netProfitMinor: gross - expenses,
    );
  }
}

class _LowStockAlert extends StatelessWidget {
  const _LowStockAlert({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final visible = products.take(3).toList();
    final extraCount = products.length - visible.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 13, 12),
      decoration: BoxDecoration(
        color: AppColors.roseLight,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.rose.withValues(alpha: .18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.rose,
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${products.length} low-stock ${products.length == 1 ? 'product' : 'products'}',
                  style: const TextStyle(
                    color: AppColors.plum,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/products'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.plum,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                ),
                child: const Text('Manage', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ...visible.map(
            (product) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '${product.stockQuantity} left · alert at ${product.lowStockThreshold}',
                    style: const TextStyle(
                      color: AppColors.rose,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (extraCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                'And $extraCount more',
                style: const TextStyle(
                  color: AppColors.plum,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfitCard extends StatelessWidget {
  const _ProfitCard({required this.summary, required this.label});

  final ProfitSummary summary;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 19, 20, 17),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.plum, AppColors.plumDeep],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(23),
      boxShadow: [
        BoxShadow(
          color: AppColors.plum.withValues(alpha: .14),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NET PROFIT · ${label.toUpperCase()}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatKes(summary.netProfitMinor),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 33,
              fontWeight: FontWeight.w700,
              letterSpacing: -.8,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Gross profit  ${formatKes(summary.grossProfitMinor)}',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 11, 9, 12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 14),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _caption,
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DailyChart extends StatelessWidget {
  const _DailyChart({required this.days});

  final List<DailyProfit> days;

  @override
  Widget build(BuildContext context) {
    final chartWidth = math.max(300.0, days.length * 45.0).toDouble();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 15, 12, 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: chartWidth,
          child: Column(
            children: [
              SizedBox(
                height: 120,
                width: chartWidth,
                child: CustomPaint(
                  painter: _ProfitChartPainter(
                    days.map((day) => day.summary.netProfitMinor).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: days
                    .map(
                      (day) => SizedBox(
                        width: chartWidth / days.length,
                        child: Text(
                          '${day.date.day}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfitChartPainter extends CustomPainter {
  const _ProfitChartPainter(this.values);
  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final positiveMax = values
        .where((value) => value > 0)
        .fold<int>(0, math.max);
    final negativeMax = values
        .where((value) => value < 0)
        .fold<int>(0, (max, value) => math.max(max, -value));
    final baseline = size.height * .70;
    final linePaint = Paint()..color = AppColors.border;
    canvas.drawLine(
      Offset(0, baseline),
      Offset(size.width, baseline),
      linePaint,
    );
    final slot = size.width / values.length;
    for (var index = 0; index < values.length; index++) {
      final value = values[index];
      if (value == 0) continue;
      final height = value > 0
          ? (value / positiveMax) * (baseline - 12)
          : (-value / negativeMax) * (size.height - baseline - 9);
      final top = value > 0 ? baseline - height : baseline;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(index * slot + slot * .30, top, slot * .40, height),
        const Radius.circular(5),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = value > 0 ? AppColors.rose : AppColors.sage,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProfitChartPainter oldDelegate) =>
      !listEquals(values, oldDelegate.values);
}

class _DailyProfitTile extends StatelessWidget {
  const _DailyProfitTile({required this.day});
  final DailyProfit day;

  @override
  Widget build(BuildContext context) {
    final summary = day.summary;
    final negative = summary.netProfitMinor < 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _shortDate(day.date),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                formatKes(summary.netProfitMinor),
                style: TextStyle(
                  color: negative ? AppColors.rose : AppColors.plum,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Sales ${formatKes(summary.salesRevenueMinor)}  ·  Cost ${formatKes(summary.costOfGoodsSoldMinor)}  ·  Expenses ${formatKes(summary.operatingExpensesMinor)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _caption,
          ),
        ],
      ),
    );
  }
}

class _ReportError extends StatelessWidget {
  const _ReportError();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(32),
    child: Center(child: Text('Profit totals could not be loaded.')),
  );
}

String _longDate(DateTime date) =>
    '${_weekdays[date.weekday - 1].toUpperCase()}, ${_months[date.month - 1].toUpperCase()} ${date.day}';

String _shortDate(DateTime date) =>
    '${_weekdays[date.weekday - 1].substring(0, 3)}, ${_months[date.month - 1]} ${date.day}';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const _eyebrow = TextStyle(
  color: AppColors.muted,
  fontSize: 10,
  fontWeight: FontWeight.w700,
  letterSpacing: 1.05,
);
const _greeting = TextStyle(
  color: AppColors.ink,
  fontSize: 22,
  fontWeight: FontWeight.w700,
  height: 1.22,
  letterSpacing: -.35,
);
const _section = TextStyle(
  color: AppColors.ink,
  fontSize: 16,
  fontWeight: FontWeight.w700,
);
const _caption = TextStyle(color: AppColors.muted, fontSize: 10);
