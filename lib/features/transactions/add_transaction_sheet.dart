import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/database/app_database.dart';
import '../../core/database/tables.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  final TransactionEntity? editTransaction;

  const AddTransactionSheet({super.key, this.editTransaction});

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  TransactionType _type = TransactionType.expense;
  String _amountStr = '0';
  String? _selectedCategory;
  DateTime _date = DateTime.now();
  bool _saving = false;
  bool _saved = false;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(
      text: widget.editTransaction?.note ?? '',
    );
    if (widget.editTransaction != null) {
      final t = widget.editTransaction!;
      _type = t.type;
      _amountStr = t.amount.toStringAsFixed(
        t.amount.truncateToDouble() == t.amount ? 0 : 2,
      );
      _selectedCategory = t.categoryId;
      _date = t.date;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }


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
    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    final noteText = _noteController.text.trim();

    await ref
        .read(transactionNotifierProvider.notifier)
        .addTransaction(
          id: widget.editTransaction?.id,
          amount: amount,
          type: _type,
          categoryId: _selectedCategory ?? 'other',
          date: _date,
          note: noteText.isNotEmpty ? noteText : null,
          paymentMethod: widget.editTransaction?.paymentMethod ?? PaymentMethod.unknown,
        );

    // Refresh data
    ref.invalidate(totalBalanceProvider);
    ref.invalidate(monthIncomeProvider);
    ref.invalidate(monthExpenseProvider);
    ref.invalidate(expensesByCategoryProvider);
    ref.invalidate(netSpentByCategoryProvider);
    ref.invalidate(dailyExpensesProvider);
    ref.invalidate(recentTransactionsProvider);

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
    final isExpense = _type == TransactionType.expense;

    final categoriesAsync = ref.watch(categoriesProvider);
    final allCats = categoriesAsync.valueOrNull ?? [];
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

    const defaultIncomeIds = {'salary', 'investments', 'freelance', 'business'};

    final rawExpenseCats =
        allCats
            .where(
              (c) =>
                  c.id != 'other' &&
                  !disabledSet.contains(c.id) &&
                  (c.id.startsWith('custom_expense_') ||
                      (defaultExpenseIds.contains(c.id) && !c.isCustom)),
            )
            .toList();

    final rawIncomeCats =
        allCats
            .where(
              (c) =>
                  c.id != 'other' &&
                  !disabledSet.contains(c.id) &&
                  (c.id.startsWith('custom_income_') ||
                      (defaultIncomeIds.contains(c.id) && !c.isCustom)),
            )
            .toList();

    final txns = ref.watch(transactionsStreamProvider).valueOrNull ?? [];
    final expenseCounts = <String, int>{};
    final incomeCounts = <String, int>{};
    for (final t in txns) {
      final catId = t.categoryId;
      if (catId == null) continue;
      if (t.type == TransactionType.expense) {
        expenseCounts[catId] = (expenseCounts[catId] ?? 0) + 1;
      } else if (t.type == TransactionType.income) {
        incomeCounts[catId] = (incomeCounts[catId] ?? 0) + 1;
      }
    }

    final filteredExpenseCats = List<CategoryEntity>.from(rawExpenseCats)
      ..sort((a, b) {
        final countA = expenseCounts[a.id] ?? 0;
        final countB = expenseCounts[b.id] ?? 0;
        return countB.compareTo(countA);
      });

    final filteredIncomeCats = List<CategoryEntity>.from(rawIncomeCats)
      ..sort((a, b) {
        final countA = incomeCounts[a.id] ?? 0;
        final countB = incomeCounts[b.id] ?? 0;
        return countB.compareTo(countA);
      });

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
                    // Type toggle
                    SegmentedButton<TransactionType>(
                      segments: [
                        ButtonSegment(
                          value: TransactionType.expense,
                          label: Text(
                            'EXPENSE',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color:
                                  isExpense ? ExpensioTheme.expenseRed : null,
                            ),
                          ),
                          icon: Icon(
                            Icons.arrow_downward,
                            color: isExpense ? ExpensioTheme.expenseRed : null,
                          ),
                        ),
                        ButtonSegment(
                          value: TransactionType.income,
                          label: Text(
                            'INCOME',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color:
                                  !isExpense ? ExpensioTheme.incomeGreen : null,
                            ),
                          ),
                          icon: Icon(
                            Icons.arrow_upward,
                            color:
                                !isExpense ? ExpensioTheme.incomeGreen : null,
                          ),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (set) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _type = set.first;
                          _selectedCategory = null;
                        });
                      },
                    ).animate().fadeIn(duration: 300.ms),

                    const SizedBox(height: 12),

                    // Amount display
                    Center(
                      child: Text(
                        '₹$_amountStr',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color:
                              isExpense
                                  ? ExpensioTheme.expenseRed
                                  : ExpensioTheme.incomeGreen,
                        ),
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                    // Category picker
                    Builder(
                      builder: (context) {
                        final currentCats =
                            isExpense
                                ? filteredExpenseCats
                                : filteredIncomeCats;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Category', style: textTheme.labelLarge),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 48,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: currentCats.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(width: 8),
                                itemBuilder: (context, i) {
                                  final cat = currentCats[i];
                                  final selected = _selectedCategory == cat.id;
                                  return ChoiceChip(
                                    label: Text('${cat.emoji} ${cat.name}'),
                                    selected: selected,
                                    onSelected: (_) {
                                      HapticFeedback.selectionClick();
                                      setState(
                                        () => _selectedCategory = cat.id,
                                      );
                                    },
                                  );
                                },
                              ),
                            ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    ),

                    // Note field
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        hintText: 'Add a note (optional)',
                        prefixIcon: Icon(Icons.note_outlined),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

                    const SizedBox(height: 12),

                    // Date picker
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          '${_date.day}/${_date.month}/${_date.year}',
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _date = picked);
                          }
                        },
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 300.ms),

                    const SizedBox(height: 12),

                    // Number pad
                    _buildNumberPad(),

                    const SizedBox(height: 12),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
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
                                  'Save Transaction',
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
