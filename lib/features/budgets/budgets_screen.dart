import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import '../../core/utils/helpers.dart';
import '../../core/theme/app_theme.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetsStreamProvider);
    final currency = ref.watch(currencyProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Text('Budgets', style: textTheme.titleLarge),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: budgets.when(
              data: (budgetList) {
                if (budgetList.isEmpty) {
                  return SliverFillRemaining(child: _emptyState(context));
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == 0) {
                      return _OverallBudgetCard(
                        budgets: budgetList,
                        currency: currency,
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
                    }
                    final budget = budgetList[index - 1];
                    return _BudgetCard(budget: budget, currency: currency)
                        .animate()
                        .fadeIn(delay: (index * 60).ms, duration: 300.ms)
                        .slideX(begin: -0.05);
                  }, childCount: budgetList.length + 1),
                );
              },
              loading:
                  () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
              error:
                  (e, _) => SliverFillRemaining(
                    child: Center(child: Text('Error: $e')),
                  ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBudget(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Budget'),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.track_changes_outlined,
          size: 96,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        const SizedBox(height: 16),
        Text(
          'No budgets set',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Set your first budget to track spending',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms);
  }

  void _showAddBudget(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AddBudgetSheet(),
    );
  }
}

class _OverallBudgetCard extends ConsumerWidget {
  final List<BudgetEntity> budgets;
  final String currency;

  const _OverallBudgetCard({required this.budgets, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalBudget = budgets.fold<double>(0, (s, b) => s + b.amount);
    final monthExpense = ref.watch(monthExpenseProvider).valueOrNull ?? 0;
    final pct =
        totalBudget > 0 ? (monthExpense / totalBudget).clamp(0, 1.5) : 0.0;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Color progressColor;
    if (pct < 0.7) {
      progressColor = ExpensioTheme.incomeGreen;
    } else if (pct < 0.9) {
      progressColor = Colors.amber;
    } else {
      progressColor = ExpensioTheme.expenseRed;
    }

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overall Monthly Budget', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyUtils.formatAmount(monthExpense, currency: currency),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: progressColor,
                  ),
                ),
                Text(
                  'of ${CurrencyUtils.formatAmount(totalBudget, currency: currency)}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct.clamp(0, 1).toDouble()),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 12,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(progressColor),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  final BudgetEntity budget;
  final String currency;

  const _BudgetCard({required this.budget, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // FIX: Normalize the DateTime so it doesn't create thousands of distinct provider instances!
    final now = DateTime.now();
    final monthArg = DateTime(now.year, now.month, 1);
    final expenses = ref.watch(netSpentByCategoryProvider(monthArg));
    final categoriesAsync = ref.watch(categoriesProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return expenses.when(
      data: (expMap) {
        final spent = expMap[budget.categoryId] ?? 0;
        final pct =
            budget.amount > 0 ? (spent / budget.amount).clamp(0, 1.5) : 0.0;
        final exceeded = pct > 1.0;

        Color progressColor;
        if (pct < 0.7) {
          progressColor = ExpensioTheme.incomeGreen;
        } else if (pct < 0.9) {
          progressColor = Colors.amber;
        } else {
          progressColor = ExpensioTheme.expenseRed;
        }

        final allCats = categoriesAsync.valueOrNull ?? [];
        final cat = allCats.firstWhere(
          (c) => c.id == budget.categoryId,
          orElse:
              () => CategoryEntity(
                id: budget.categoryId,
                name: 'Miscellaneous',
                emoji: '🧾',
                isCustom: false,
                sortOrder: 0,
              ),
        );
        final emoji = cat.emoji;
        final displayName = cat.name;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          margin: const EdgeInsets.only(bottom: 10),
          color:
              exceeded
                  ? ExpensioTheme.expenseRed.withValues(alpha: 0.08)
                  : colorScheme.surfaceContainerLow,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onLongPress: () => _confirmDeleteBudget(context, ref, budget),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(displayName, style: textTheme.titleSmall),
                      ),
                      Text(
                        '${CurrencyUtils.formatAmount(spent, currency: currency)} / ${CurrencyUtils.formatAmount(budget.amount, currency: currency)}',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct.clamp(0, 1).toDouble()),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(progressColor),
                        ),
                      );
                    },
                  ),
                  if (exceeded)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '⚠️ Budget exceeded by ${CurrencyUtils.formatAmount(spent - budget.amount, currency: currency)}',
                        style: textTheme.labelSmall?.copyWith(
                          color: ExpensioTheme.expenseRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
      loading:
          () => Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            margin: const EdgeInsets.only(bottom: 10),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      error: (e, _) => Card(child: Center(child: Text('Error: $e'))),
    );
  }

  void _confirmDeleteBudget(
    BuildContext context,
    WidgetRef ref,
    BudgetEntity budget,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryCapitalized =
        budget.categoryId.isNotEmpty
            ? budget.categoryId.replaceFirst(
              budget.categoryId[0],
              budget.categoryId[0].toUpperCase(),
            )
            : 'Budget';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Budget'),
            content: Text(
              'Are you sure you want to delete the budget for $categoryCapitalized?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await ref
                      .read(budgetNotifierProvider.notifier)
                      .deleteBudget(budget.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$categoryCapitalized budget deleted'),
                      ),
                    );
                  }
                },
                child: Text(
                  'Delete',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ],
          ),
    );
  }
}

class _AddBudgetSheet extends ConsumerStatefulWidget {
  const _AddBudgetSheet();

  @override
  ConsumerState<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends ConsumerState<_AddBudgetSheet> {
  String _amountStr = '0';
  String? _selectedCategory;
  bool _saving = false;
  bool _saved = false;

  void _onNumberTap(String val) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (val == '⌫') {
        if (_amountStr.length > 1) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        } else {
          _amountStr = '0';
        }
      } else if (val == '.') {
        if (!_amountStr.contains('.')) {
          _amountStr += '.';
        }
      } else {
        if (_amountStr == '0') {
          _amountStr = val;
        } else {
          _amountStr += val;
        }
      }
    });
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountStr);
    if (amount == null || amount <= 0 || _selectedCategory == null) return;

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    await ref
        .read(budgetNotifierProvider.notifier)
        .addBudget(categoryId: _selectedCategory!, amount: amount);

    setState(() {
      _saving = false;
      _saved = true;
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final categoriesAsync = ref.watch(categoriesProvider);
    final disabledSet = ref.watch(disabledCategoriesProvider);

    const defaultExpenseIds = {
      'groceries',
      'food',
      'fuel',
      'entertainment',
      'shopping',
      'investments',
      'internet',
      'electricity',
      'water',
      'travel',
      'electronics',
      'taxes',
      'health',
      'transport',
      'leisure',
      'rent',
      'education',
      'insurance',
    };

    final allCats = categoriesAsync.valueOrNull ?? [];
    final filteredCategories =
        allCats.where((c) {
          if (c.id == 'other') return false;
          if (disabledSet.contains(c.id)) return false;
          return c.id.startsWith('custom_expense_') ||
              (defaultExpenseIds.contains(c.id) && !c.isCustom);
        }).toList();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        'Set Budget',
                        style: textTheme.titleLarge,
                      ).animate().fadeIn(duration: 300.ms),
                    ),
                    const SizedBox(height: 12),

                    // Amount display
                    Center(
                      child: Text(
                        '₹$_amountStr',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                    const SizedBox(height: 12),

                    // Category picker
                    Text('Category', style: textTheme.labelLarge),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: filteredCategories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final cat = filteredCategories[i];
                          final selected = _selectedCategory == cat.id;
                          return ChoiceChip(
                            label: Text('${cat.emoji} ${cat.name}'),
                            selected: selected,
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedCategory = cat.id);
                            },
                          );
                        },
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

                    const SizedBox(height: 12),

                    // Number pad
                    _buildNumberPad(),

                    const SizedBox(height: 12),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed:
                            _saving
                                ? null
                                : () {
                                  if (_selectedCategory == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please select a category for the budget',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  if (double.tryParse(_amountStr) == null ||
                                      double.parse(_amountStr) <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please enter a valid amount',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  _save();
                                },
                        child:
                            _saved
                                ? const Icon(
                                  Icons.check_rounded,
                                  size: 28,
                                ).animate().scale(
                                  begin: const Offset(0, 0),
                                  duration: 400.ms,
                                  curve: Curves.easeOutBack,
                                )
                                : _saving
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                                : const Text(
                                  'Save Budget',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'],
    ];
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children:
          keys.map((row) {
            return Row(
              children:
                  row.map((key) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Material(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _onNumberTap(key),
                            child: Container(
                              height: 56,
                              alignment: Alignment.center,
                              child:
                                  key == '⌫'
                                      ? Icon(
                                        Icons.backspace_outlined,
                                        color: colorScheme.onSurface,
                                      )
                                      : Text(
                                        key,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 24,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            );
          }).toList(),
    );
  }
}
