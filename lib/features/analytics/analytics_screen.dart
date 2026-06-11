import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import '../../core/utils/helpers.dart';
import '../../core/database/tables.dart';
import '../../core/theme/app_theme.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final currency = ref.watch(currencyProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Text('Analytics', style: textTheme.titleLarge),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Month selector
                _MonthSelector(
                  selectedMonth: selectedMonth,
                  onChanged:
                      (m) => ref.read(selectedMonthProvider.notifier).state = m,
                ).animate().fadeIn(duration: 300.ms),

                const SizedBox(height: 24),

                // Income vs Expense bar chart
                Text(
                  'Income vs Expense',
                  style: textTheme.titleMedium,
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 12),
                SizedBox(
                      height: 200,
                      child: _IncomeExpenseChart(selectedMonth: selectedMonth),
                    )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      curve: Curves.easeOutCubic,
                    ),

                const SizedBox(height: 24),

                // Daily spending line chart
                Text(
                  'Daily Spending',
                  style: textTheme.titleMedium,
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 12),
                SizedBox(
                      height: 200,
                      child: _DailySpendingChart(selectedMonth: selectedMonth),
                    )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      curve: Curves.easeOutCubic,
                    ),

                const SizedBox(height: 24),

                // Top spending categories
                Text(
                  'Top Spending Categories',
                  style: textTheme.titleMedium,
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 12),
                _TopCategoriesList(
                  selectedMonth: selectedMonth,
                  currency: currency,
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                const SizedBox(height: 24),

                // Spending insights
                Text(
                  'Spending Insights',
                  style: textTheme.titleMedium,
                ).animate().fadeIn(delay: 700.ms),
                const SizedBox(height: 12),
                _InsightsCards(
                  selectedMonth: selectedMonth,
                  currency: currency,
                ).animate().fadeIn(delay: 800.ms),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onChanged;

  const _MonthSelector({required this.selectedMonth, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed:
              () => onChanged(
                DateTime(selectedMonth.year, selectedMonth.month - 1),
              ),
        ),
        Text(
          DateUtils2.formatMonthYear(selectedMonth),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            final next = DateTime(selectedMonth.year, selectedMonth.month + 1);
            if (next.isBefore(DateTime.now()) ||
                next.month == DateTime.now().month) {
              onChanged(next);
            }
          },
        ),
      ],
    );
  }
}

class _IncomeExpenseChart extends ConsumerWidget {
  final DateTime selectedMonth;

  const _IncomeExpenseChart({required this.selectedMonth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    // Show last 6 months
    return FutureBuilder(
      future: _getLast6MonthsData(ref),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        if (data.isEmpty) {
          return Center(
            child: Text(
              'No data yet',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          );
        }

        return BarChart(
          BarChartData(
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx >= 0 && idx < data.length) {
                      return Text(
                        data[idx]['label'] as String,
                        style: Theme.of(context).textTheme.labelSmall,
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barGroups:
                data.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value['income'] as double,
                        color: ExpensioTheme.incomeGreenLight,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: e.value['expense'] as double,
                        color: ExpensioTheme.expenseRedLight,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getLast6MonthsData(WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final data = <Map<String, dynamic>>[];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    for (int i = 5; i >= 0; i--) {
      final m = DateTime(selectedMonth.year, selectedMonth.month - i);
      final start = DateTime(m.year, m.month, 1);
      final end = DateTime(m.year, m.month + 1, 0, 23, 59, 59);
      final income = await db.getTotalIncome(start, end);
      final expense = await db.getTotalExpense(start, end);
      data.add({
        'label': months[m.month - 1],
        'income': income,
        'expense': expense,
      });
    }
    return data;
  }
}

class _DailySpendingChart extends ConsumerWidget {
  final DateTime selectedMonth;

  const _DailySpendingChart({required this.selectedMonth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyExpenses = ref.watch(dailyExpensesProvider(selectedMonth));
    final colorScheme = Theme.of(context).colorScheme;

    return dailyExpenses.when(
      data: (data) {
        if (data.isEmpty) {
          return Center(
            child: Text(
              'No spending data',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          );
        }

        final daysInMonth =
            DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
        final spots = <FlSpot>[];
        for (int d = 1; d <= daysInMonth; d++) {
          spots.add(FlSpot(d.toDouble(), data[d] ?? 0));
        }

        return LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.3,
                color: colorScheme.primary,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _TopCategoriesList extends ConsumerWidget {
  final DateTime selectedMonth;
  final String currency;

  const _TopCategoriesList({
    required this.selectedMonth,
    required this.currency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesByCategoryProvider(selectedMonth));
    final categories = ref.watch(categoriesProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return expenses.when(
      data: (expMap) {
        if (expMap.isEmpty) {
          return const SizedBox(
            height: 60,
            child: Center(child: Text('No data')),
          );
        }

        final sorted =
            expMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final maxVal = sorted.first.value;
        final cats = categories.valueOrNull ?? [];

        return Column(
          children:
              sorted.take(5).toList().asMap().entries.map((entry) {
                final e = entry.value;
                final cat = cats.firstWhere(
                  (c) => c.id == e.key,
                  orElse:
                      () =>
                          cats.isNotEmpty
                              ? cats.last
                              : const CategoryEntity(
                                id: 'other',
                                name: 'Miscellaneous',
                                emoji: '🧾',
                                isCustom: false,
                                sortOrder: 0,
                              ),
                );
                final pct = e.value / maxVal;

                return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${cat.emoji} ${cat.name}',
                                style: textTheme.bodyMedium,
                              ),
                              Text(
                                CurrencyUtils.formatAmount(
                                  e.value,
                                  currency: currency,
                                ),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: pct),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: value,
                                  minHeight: 8,
                                  backgroundColor:
                                      colorScheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation(
                                    colorScheme.primary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: (entry.key * 80).ms, duration: 300.ms)
                    .slideX(begin: -0.05);
              }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _InsightsCards extends ConsumerWidget {
  final DateTime selectedMonth;
  final String currency;

  const _InsightsCards({required this.selectedMonth, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthTxns = ref.watch(monthTransactionsProvider(selectedMonth));
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return monthTxns.when(
      data: (txns) {
        if (txns.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Add some transactions to see insights ✨',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final expenses = txns.where((t) => t.type == TransactionType.expense);
        final totalExpense = expenses.fold<double>(0, (s, t) => s + t.amount);
        final biggest =
            expenses.isNotEmpty
                ? expenses.reduce((a, b) => a.amount > b.amount ? a : b)
                : null;

        final insights = <String>[
          '📊 You have ${txns.length} transactions this month.',
          if (totalExpense > 0)
            '💸 Total spending: ${CurrencyUtils.formatAmount(totalExpense, currency: currency)}.',
          if (biggest != null)
            '🏆 Biggest expense: ${CurrencyUtils.formatAmount(biggest.amount, currency: currency)}${biggest.merchant != null ? ' at ${biggest.merchant}' : ''}.',
        ];

        return Column(
          children:
              insights.asMap().entries.map((e) {
                return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(e.value, style: textTheme.bodyMedium),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: (e.key * 100).ms, duration: 300.ms)
                    .slideY(begin: 0.05);
              }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
