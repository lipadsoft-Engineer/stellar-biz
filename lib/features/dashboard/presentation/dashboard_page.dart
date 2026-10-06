import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekdays = const [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final months = const [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December'
    ];
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
                    Text(
                        '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}',
                        style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.05)),
                    const SizedBox(height: 7),
                    Text(greeting, style: _greeting),
                    const SizedBox(height: 3),
                    const Text('Your business, at a glance',
                        style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                            height: 1.35)),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                    color: AppColors.roseLight, shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome,
                    color: AppColors.rose, size: 19),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _ProfitCard(),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(
                  child: _MetricCard(
                      label: 'Sales today',
                      value: 'KES 8,450',
                      icon: Icons.south_west_rounded,
                      tint: AppColors.sageLight,
                      iconColor: AppColors.sage)),
              SizedBox(width: 12),
              Expanded(
                  child: _MetricCard(
                      label: 'Expenses',
                      value: 'KES 1,200',
                      icon: Icons.north_east_rounded,
                      tint: AppColors.roseLight,
                      iconColor: AppColors.rose)),
            ],
          ),
          const SizedBox(height: 27),
          Row(
            children: [
              const Expanded(child: Text('Profit at a glance', style: _section)),
              TextButton.icon(
                onPressed: () => _showComingSoon(context, 'Date range reports'),
                icon: const Icon(Icons.calendar_month_outlined, size: 17),
                label: const Text('This week'),
                style: TextButton.styleFrom(foregroundColor: AppColors.rose),
              ),
            ],
          ),
          const SizedBox(height: 9),
          const _WeekChart(),
          const SizedBox(height: 25),
          Row(
            children: [
              const Expanded(child: Text('Quick actions', style: _section)),
              const Text('A little progress, every day', style: _caption),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                  child: _ActionTile(
                      icon: Icons.add_shopping_cart_rounded,
                      title: 'Record a sale',
                      color: AppColors.rose,
                      onTap: () => _showComingSoon(context, 'Sales'))),
              const SizedBox(width: 12),
              Expanded(
                  child: _ActionTile(
                      icon: Icons.inventory_2_outlined,
                      title: 'Add a product',
                      color: AppColors.sage,
                      onTap: () => _showComingSoon(context, 'Products'))),
            ],
          ),
          const SizedBox(height: 25),
          const Row(
            children: [
              Expanded(child: Text('A gentle reminder', style: _section)),
              Icon(Icons.auto_awesome, color: AppColors.rose, size: 19),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFFF1EEE8),
                borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.rose),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'A quick reminder to record any expenses from today.',
                    style: TextStyle(
                        color: AppColors.ink.withValues(alpha: .8),
                        height: 1.4,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
  }
}

const _greeting = TextStyle(
    color: AppColors.ink,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.22,
    letterSpacing: -0.35);
const _section = TextStyle(
    color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.w700);
const _caption = TextStyle(color: AppColors.muted, fontSize: 11);

class _ProfitCard extends StatelessWidget {
  const _ProfitCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(21, 20, 21, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.plum, AppColors.plumDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(23),
          boxShadow: [
            BoxShadow(
                color: AppColors.plum.withValues(alpha: .15),
                blurRadius: 18,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('NET PROFIT TODAY',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          color: Color(0xFFE4CCD7), size: 12),
                      SizedBox(width: 4),
                      Text('Today',
                          style: TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            const Text('KES 4,860',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1)),
            const SizedBox(height: 5),
            const Text('A clear view of where you stand',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 18),
            Container(height: 1, color: Colors.white.withValues(alpha: .22)),
            const SizedBox(height: 13),
            const Row(
              children: [
                _ProfitBreakdown(label: 'Gross profit', amount: 'KES 6,060'),
                SizedBox(width: 26),
                _ProfitBreakdown(label: 'Expenses', amount: 'KES 1,200'),
              ],
            ),
          ],
        ),
      );
}

class _ProfitBreakdown extends StatelessWidget {
  const _ProfitBreakdown({required this.label, required this.amount});
  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
          const SizedBox(height: 3),
          Text(amount,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 29,
                  height: 29,
                  decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                  child: Icon(icon, color: iconColor, size: 15),
                ),
                const Spacer(),
                const Icon(Icons.more_horiz, color: AppColors.muted, size: 18),
              ],
            ),
            const SizedBox(height: 11),
            Text(label, style: _caption),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}

class _WeekChart extends StatelessWidget {
  const _WeekChart();
  static const values = [0.32, 0.54, 0.43, 0.76, 0.61, 0.92, 0.68];
  static const days = ['Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu'];

  @override
  Widget build(BuildContext context) => Container(
        height: 184,
        padding: const EdgeInsets.fromLTRB(16, 17, 16, 13),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(values.length, (index) {
            final active = index == values.length - 1;
            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(active ? '4.9k' : '',
                      style: const TextStyle(
                          color: AppColors.rose,
                          fontSize: 9,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 320 + index * 45),
                    curve: Curves.easeOutCubic,
                    width: 22,
                    height: 96 * values[index],
                    decoration: BoxDecoration(
                        color: active
                            ? AppColors.rose
                            : AppColors.roseLight,
                        borderRadius: BorderRadius.circular(9)),
                  ),
                  const SizedBox(height: 9),
                  Text(days[index],
                      style: TextStyle(
                          color: active ? AppColors.rose : AppColors.muted,
                          fontSize: 10,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w400)),
                ],
              ),
            );
          }),
        ),
      );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile(
      {required this.icon,
      required this.title,
      required this.color,
      required this.onTap});
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border)),
            child: Row(
              children: [
                Icon(icon, color: color, size: 19),
                const SizedBox(width: 9),
                Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ),
      );
}

void _showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$feature will be available in a later build.'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      duration: const Duration(seconds: 2),
    ),
  );
}
