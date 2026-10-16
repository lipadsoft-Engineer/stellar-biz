import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../domain/profit_calculator.dart';

final dailyProfitRepositoryProvider = Provider<DailyProfitRepository>(
  (ref) => DailyProfitRepository(ref.watch(appDatabaseProvider)),
);

final dailyProfitsProvider =
    StreamProvider.family<List<DailyProfit>, ProfitDateRange>(
      (ref, range) => ref
          .watch(dailyProfitRepositoryProvider)
          .watchDailyProfits(range.start, range.end),
    );

class ProfitDateRange {
  const ProfitDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) =>
      other is ProfitDateRange &&
      other.start.year == start.year &&
      other.start.month == start.month &&
      other.start.day == start.day &&
      other.end.year == end.year &&
      other.end.month == end.month &&
      other.end.day == end.day;

  @override
  int get hashCode => Object.hash(
    start.year,
    start.month,
    start.day,
    end.year,
    end.month,
    end.day,
  );
}

class DailyProfit {
  const DailyProfit({required this.date, required this.summary});

  final DateTime date;
  final ProfitSummary summary;
}

class DailyProfitRepository {
  const DailyProfitRepository(this._database);

  final AppDatabase _database;

  Stream<List<DailyProfit>> watchDailyProfits(DateTime start, DateTime end) {
    final first = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    final endExclusive = last.add(const Duration(days: 1));
    const sql = '''
      SELECT 'sale' AS kind,
             s.id AS sale_id,
             s.transaction_date AS transaction_date,
             s.discount_minor AS discount_minor,
             si.quantity AS quantity,
             si.unit_selling_price_minor AS selling_price_minor,
             si.unit_cost_minor AS cost_minor,
             0 AS amount_minor
      FROM sales AS s
      INNER JOIN sale_items AS si ON si.sale_id = s.id
      WHERE s.status = 'completed'
        AND s.transaction_date >= ?
        AND s.transaction_date < ?
      UNION ALL
      SELECT 'expense' AS kind,
             e.id AS sale_id,
             e.transaction_date AS transaction_date,
             0 AS discount_minor,
             0 AS quantity,
             0 AS selling_price_minor,
             0 AS cost_minor,
             e.amount_minor AS amount_minor
      FROM expenses AS e
      WHERE e.status = 'active'
        AND e.transaction_date >= ?
        AND e.transaction_date < ?
    ''';

    return _database
        .customSelect(
          sql,
          variables: [
            Variable<DateTime>(first),
            Variable<DateTime>(endExclusive),
            Variable<DateTime>(first),
            Variable<DateTime>(endExclusive),
          ],
          readsFrom: {_database.sales, _database.saleItems, _database.expenses},
        )
        .watch()
        .map((rows) => _summarize(rows, first, last));
  }

  List<DailyProfit> _summarize(
    List<QueryRow> rows,
    DateTime start,
    DateTime end,
  ) {
    final saleBuckets = <DateTime, Map<int, _SaleBucket>>{};
    final expenseBuckets = <DateTime, List<ExpenseFinancialRecord>>{};

    for (final row in rows) {
      final date = row.read<DateTime>('transaction_date');
      final day = DateTime(date.year, date.month, date.day);
      if (row.read<String>('kind') == 'expense') {
        expenseBuckets
            .putIfAbsent(day, () => [])
            .add(
              ExpenseFinancialRecord(
                amountMinor: row.read<int>('amount_minor'),
              ),
            );
        continue;
      }

      final saleId = row.read<int>('sale_id');
      final bucket = saleBuckets
          .putIfAbsent(day, () => {})
          .putIfAbsent(
            saleId,
            () => _SaleBucket(row.read<int>('discount_minor')),
          );
      bucket.lines.add(
        SaleLineAmounts(
          quantity: row.read<int>('quantity'),
          unitSellingPriceMinor: row.read<int>('selling_price_minor'),
          unitCostMinor: row.read<int>('cost_minor'),
        ),
      );
    }

    final daily = <DailyProfit>[];
    for (
      var date = start;
      !date.isAfter(end);
      date = date.add(const Duration(days: 1))
    ) {
      final sales = (saleBuckets[date]?.values ?? const <_SaleBucket>[]).map(
        (sale) => SaleFinancialRecord(
          items: sale.lines,
          discountMinor: sale.discountMinor,
        ),
      );
      final summary = ProfitCalculator.calculate(
        sales: sales,
        expenses: expenseBuckets[date] ?? const [],
      );
      daily.add(DailyProfit(date: date, summary: summary));
    }
    return daily;
  }
}

class _SaleBucket {
  _SaleBucket(this.discountMinor);

  final int discountMinor;
  final List<SaleLineAmounts> lines = [];
}
