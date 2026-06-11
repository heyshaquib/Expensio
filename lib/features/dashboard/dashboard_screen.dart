import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/providers.dart';
import '../../core/utils/helpers.dart';
import '../../core/theme/app_theme.dart';
import '../settings/settings_screen.dart';
import 'home_shell.dart';
import 'widgets/summary_card.dart';
import 'widgets/donut_chart_widget.dart';
import 'widgets/transaction_tile.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);
    final currency = ref.watch(currencyProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final monthIncome = ref.watch(monthIncomeProvider);
    final monthExpense = ref.watch(monthExpenseProvider);
    final recentTxns = ref.watch(recentTransactionsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(totalBalanceProvider);
          ref.invalidate(monthIncomeProvider);
          ref.invalidate(monthExpenseProvider);
          ref.invalidate(expensesByCategoryProvider);
          ref.invalidate(netSpentByCategoryProvider);
          ref.invalidate(dailyExpensesProvider);
          ref.invalidate(recentTransactionsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              snap: true,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${DateUtils2.greeting()}, $userName',
                    style: textTheme.titleLarge,
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                ),
              ],
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),

                  // Summary cards
                  SizedBox(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      children: [
                        SummaryCard(
                              title: 'Total Balance',
                              value: totalBalance.valueOrNull ?? 0,
                              currency: currency,
                              icon: Icons.account_balance_wallet_rounded,
                              gradient: [
                                colorScheme.primaryContainer,
                                colorScheme.primary.withValues(alpha: 0.7),
                              ],
                              onLongPress: () {
                                final val = totalBalance.valueOrNull ?? 0;
                                Clipboard.setData(
                                  ClipboardData(
                                    text: CurrencyUtils.formatAmount(
                                      val,
                                      currency: currency,
                                    ),
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Balance copied to clipboard',
                                    ),
                                  ),
                                );
                                HapticFeedback.mediumImpact();
                              },
                            )
                            .animate()
                            .fadeIn(delay: 100.ms, duration: 400.ms)
                            .slideX(begin: -0.1),
                        const SizedBox(width: 12),
                        SummaryCard(
                              title: 'Income',
                              value: monthIncome.valueOrNull ?? 0,
                              currency: currency,
                              icon: Icons.trending_up_rounded,
                              gradient: [
                                ExpensioTheme.incomeGreen.withValues(
                                  alpha: 0.3,
                                ),
                                ExpensioTheme.incomeGreenLight.withValues(
                                  alpha: 0.5,
                                ),
                              ],
                              valueColor: ExpensioTheme.incomeGreen,
                            )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 400.ms)
                            .slideX(begin: -0.1),
                        const SizedBox(width: 12),
                        SummaryCard(
                              title: 'Expenses',
                              value: monthExpense.valueOrNull ?? 0,
                              currency: currency,
                              icon: Icons.trending_down_rounded,
                              gradient: [
                                ExpensioTheme.expenseRed.withValues(alpha: 0.3),
                                ExpensioTheme.expenseRedLight.withValues(
                                  alpha: 0.5,
                                ),
                              ],
                              valueColor: ExpensioTheme.expenseRed,
                            )
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 400.ms)
                            .slideX(begin: -0.1),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Donut chart
                  Text(
                    'Spending by Category',
                    style: textTheme.titleMedium,
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 12),
                  const DonutChartWidget()
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 600.ms)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        curve: Curves.easeOutBack,
                      ),

                  const SizedBox(height: 24),

                  // Recent transactions header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Transactions', style: textTheme.titleMedium),
                      TextButton(
                        onPressed: () {
                          ref.read(selectedTabProvider.notifier).state = 1;
                        },
                        child: const Text('See all'),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms),

                  // Recent transactions list
                  recentTxns.when(
                    data:
                        (txns) =>
                            txns.isEmpty
                                ? _emptyState(context)
                                : Column(
                                  children:
                                      txns.asMap().entries.map((entry) {
                                        return TransactionTile(
                                              transaction: entry.value,
                                              currency: currency,
                                            )
                                            .animate()
                                            .fadeIn(
                                              delay: (700 + entry.key * 40).ms,
                                              duration: 300.ms,
                                            )
                                            .slideX(begin: -0.05);
                                      }).toList(),
                                ),
                    loading:
                        () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(48),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    error:
                        (e, _) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(48),
                            child: Text('Error: $e'),
                          ),
                        ),
                  ),
                  const SizedBox(height: 100), // Space for FAB
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first transaction',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }
}
