import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import '../../core/utils/helpers.dart';
import '../dashboard/widgets/transaction_tile.dart';
import 'add_transaction_sheet.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currency = ref.watch(currencyProvider);
    final filter = ref.watch(transactionFilterProvider);
    final transactions = ref.watch(filteredTransactionsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Text('Transactions', style: textTheme.titleLarge),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(108),
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search transactions...',
                        prefixIcon: const Icon(Icons.search),
                        fillColor: colorScheme.surfaceContainerHigh,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      onChanged:
                          (q) =>
                              ref.read(searchQueryProvider.notifier).state = q,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Filter chips
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: filter == TransactionFilter.all,
                          onTap:
                              () =>
                                  ref
                                      .read(transactionFilterProvider.notifier)
                                      .state = TransactionFilter.all,
                        ),
                        _FilterChip(
                          label: 'Income',
                          selected: filter == TransactionFilter.income,
                          onTap:
                              () =>
                                  ref
                                      .read(transactionFilterProvider.notifier)
                                      .state = TransactionFilter.income,
                        ),
                        _FilterChip(
                          label: 'Expense',
                          selected: filter == TransactionFilter.expense,
                          onTap:
                              () =>
                                  ref
                                      .read(transactionFilterProvider.notifier)
                                      .state = TransactionFilter.expense,
                        ),
                        _FilterChip(
                          label: 'This Week',
                          selected: filter == TransactionFilter.thisWeek,
                          onTap:
                              () =>
                                  ref
                                      .read(transactionFilterProvider.notifier)
                                      .state = TransactionFilter.thisWeek,
                        ),
                        _FilterChip(
                          label: 'This Month',
                          selected: filter == TransactionFilter.thisMonth,
                          onTap:
                              () =>
                                  ref
                                      .read(transactionFilterProvider.notifier)
                                      .state = TransactionFilter.thisMonth,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (transactions.isEmpty)
            SliverFillRemaining(child: _emptyState(context))
          else
            _buildGroupedList(context, ref, transactions, currency),
        ],
      ),
    );
  }

  Widget _buildGroupedList(
    BuildContext context,
    WidgetRef ref,
    List<TransactionEntity> transactions,
    String currency,
  ) {
    // Group by date
    final grouped = <String, List<TransactionEntity>>{};
    for (final t in transactions) {
      final key = DateUtils2.formatDateShort(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    final entries = grouped.entries.toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final entry = entries[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                entry.key,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            // Transactions for this date
            ...entry.value.asMap().entries.map((e) {
              final txn = e.value;
              return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Dismissible(
                      key: ValueKey(txn.id),
                      direction: DismissDirection.horizontal,
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 24),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit, color: Colors.blue),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete, color: Colors.red),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.endToStart) {
                          // Allow deletion swipe animation to complete
                          return true;
                        } else {
                          // Edit
                          if (context.mounted) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder:
                                  (_) =>
                                      AddTransactionSheet(editTransaction: txn),
                            );
                          }
                          return false;
                        }
                      },
                      onDismissed: (direction) async {
                        if (direction == DismissDirection.endToStart) {
                          // Perform actual deletion after the swipe animation is complete
                          await ref
                              .read(transactionNotifierProvider.notifier)
                              .deleteTransaction(txn.id);
                          ref.invalidate(totalBalanceProvider);
                          ref.invalidate(monthIncomeProvider);
                          ref.invalidate(monthExpenseProvider);
                          ref.invalidate(expensesByCategoryProvider);
                          ref.invalidate(netSpentByCategoryProvider);
                          ref.invalidate(dailyExpensesProvider);
                          ref.invalidate(recentTransactionsProvider);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Transaction deleted'),
                                duration: const Duration(seconds: 5),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () async {
                                    await ref
                                        .read(
                                          transactionNotifierProvider.notifier,
                                        )
                                        .restoreTransaction(txn);
                                    ref.invalidate(totalBalanceProvider);
                                    ref.invalidate(monthIncomeProvider);
                                    ref.invalidate(monthExpenseProvider);
                                    ref.invalidate(expensesByCategoryProvider);
                                    ref.invalidate(netSpentByCategoryProvider);
                                    ref.invalidate(dailyExpensesProvider);
                                    ref.invalidate(recentTransactionsProvider);
                                  },
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: TransactionTile(
                        transaction: txn,
                        currency: currency,
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: (e.key * 40).ms, duration: 300.ms)
                  .slideX(begin: -0.05);
            }),
          ],
        );
      }, childCount: entries.length),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.receipt_long_outlined,
          size: 96,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        const SizedBox(height: 16),
        Text(
          'No transactions yet',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your transactions will appear here',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
      ),
    );
  }
}
