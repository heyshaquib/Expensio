import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/providers.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/theme/app_theme.dart';

class TransactionTile extends ConsumerWidget {
  final TransactionEntity transaction;
  final String currency;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.currency,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isExpense = transaction.type == TransactionType.expense;
    final amountColor =
        isExpense ? ExpensioTheme.expenseRed : ExpensioTheme.incomeGreen;
    final prefix = isExpense ? '-' : '+';

    final categoriesAsync = ref.watch(categoriesProvider);
    final allCats = categoriesAsync.valueOrNull ?? [];

    final cat = allCats.firstWhere(
      (c) => c.id == transaction.categoryId,
      orElse:
          () => CategoryEntity(
            id: transaction.categoryId ?? 'other',
            name: 'Miscellaneous',
            emoji: transaction.type == TransactionType.income ? '💰' : '🧾',
            isCustom: false,
            sortOrder: 0,
          ),
    );

    final emoji = cat.emoji;
    final categoryName = cat.name;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Category emoji
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.merchant ?? categoryName,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      transaction.note != null && transaction.note!.isNotEmpty
                          ? '${transaction.note} • ${DateUtils2.formatTime(transaction.date)}'
                          : DateUtils2.formatTime(transaction.date),
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Amount
              Text(
                '$prefix${CurrencyUtils.formatAmount(transaction.amount, currency: currency)}',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
