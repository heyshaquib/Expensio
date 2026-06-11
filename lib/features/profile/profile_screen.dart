import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';
import '../../core/database/tables.dart';
import '../../core/providers.dart';
import '../../core/utils/section_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);
    final currency = ref.watch(currencyProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Data')),
      body: ListView(
        children: [
          // Profile Settings
          SectionHeader('PROFILE SETTINGS'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Your Name'),
            subtitle: Text(userName),
            trailing: const Icon(Icons.edit_outlined, size: 20),
            onTap: () => _editName(context, ref, userName),
          ),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Currency'),
            subtitle: Text(currency),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectCurrency(context, ref, currency),
          ),
          const Divider(height: 32),

          // Categories
          SectionHeader('CATEGORIES'),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Manage Categories'),
            subtitle: const Text('Enable or disable active categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showManageCategories(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Add Category'),
            subtitle: const Text('Create a custom category tag'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAddCategory(context, ref),
          ),
          const Divider(height: 32),

          // Backup & Restore
          SectionHeader('BACKUP & RESTORE'),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('Backup Data'),
            subtitle: const Text('Export a copy of your Expensio data'),
            onTap: () => _backupData(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.settings_backup_restore_outlined),
            title: const Text('Restore Data'),
            subtitle: const Text('Restore your data from a backup file'),
            onTap: () => _restoreData(context, ref),
          ),
          const Divider(height: 32),

          // Danger Zone
          SectionHeader('DANGER ZONE'),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: colorScheme.error,
            ),
            title: Text(
              'Clear All Data',
              style: TextStyle(color: colorScheme.error),
            ),
            onTap: () => _confirmClearData(context, ref),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  void _editName(BuildContext context, WidgetRef ref, String current) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Your Name'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Enter your name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    ref.read(userNameProvider.notifier).state = name;
                    final db = ref.read(databaseProvider);
                    await db.setSetting('user_name', name);
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _selectCurrency(BuildContext context, WidgetRef ref, String current) {
    showDialog(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Select Currency'),
            children:
                ['INR', 'USD', 'EUR', 'GBP', 'AED', 'JPY', 'CAD', 'AUD', 'SGD']
                    .map(
                      (c) => RadioListTile<String>(
                        title: Text(c),
                        value: c,
                        // ignore: deprecated_member_use
                        groupValue: current,
                        // ignore: deprecated_member_use
                        onChanged: (v) async {
                          if (v != null) {
                            ref.read(currencyProvider.notifier).state = v;
                            final db = ref.read(databaseProvider);
                            await db.setSetting('currency', v);
                          }
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        },
                      ),
                    )
                    .toList(),
          ),
    );
  }

  Future<void> _backupData(BuildContext context, WidgetRef ref) async {
    try {
      final db = ref.read(databaseProvider);
      final dataMap = await db.exportToJson();
      final jsonString = const JsonEncoder.withIndent('  ').convert(dataMap);
      final jsonBytes = utf8.encode(jsonString);

      final dateStr = DateTime.now().toIso8601String().split('T')[0];

      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup File',
        fileName: 'expensio_backup_$dateStr.json',
        bytes: jsonBytes,
      );

      if (outputFile != null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup saved successfully!')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    }
  }

  Future<void> _restoreData(BuildContext context, WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Backup File',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final backupFile = File(result.files.single.path!);

        if (!context.mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Restore Backup?'),
                content: const Text(
                  'This will replace all your current data with the backup. The app will close after restoring. Continue?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      try {
                        final jsonString = await backupFile.readAsString();
                        final jsonMap =
                            jsonDecode(jsonString) as Map<String, dynamic>;

                        final db = ref.read(databaseProvider);
                        await db.importFromJson(jsonMap);

                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);

                        // Invalidate providers to force UI refresh
                        ref.invalidate(totalBalanceProvider);
                        ref.invalidate(monthIncomeProvider);
                        ref.invalidate(monthExpenseProvider);
                        ref.invalidate(expensesByCategoryProvider);
                        ref.invalidate(netSpentByCategoryProvider);
                        ref.invalidate(dailyExpensesProvider);
                        ref.invalidate(recentTransactionsProvider);
                        ref.invalidate(userNameProvider);
                        ref.invalidate(currencyProvider);

                        // Signal success and terminate app to safely reboot database connection and settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Restore successful. Restarting...'),
                          ),
                        );

                        await Future.delayed(const Duration(seconds: 1));
                        SystemNavigator.pop();
                      } catch (e) {
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Restore error: $e')),
                        );
                      }
                    },
                    child: const Text('Restore & Restart'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to read file: $e')));
    }
  }

  void _confirmClearData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear All Data?'),
            content: const Text(
              'This will permanently delete all transactions and budgets. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (ctx) => AlertDialog(
                          title: const Text('Are you absolutely sure?'),
                          content: const Text(
                            'All data will be permanently deleted.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                              ),
                              onPressed: () async {
                                await ref.read(databaseProvider).clearAllData();

                                // Invalidate all providers to force UI refresh
                                ref.invalidate(totalBalanceProvider);
                                ref.invalidate(monthIncomeProvider);
                                ref.invalidate(monthExpenseProvider);
                                ref.invalidate(expensesByCategoryProvider);
                                ref.invalidate(netSpentByCategoryProvider);
                                ref.invalidate(dailyExpensesProvider);
                                ref.invalidate(recentTransactionsProvider);
                                ref.invalidate(settingsCacheProvider);
                                ref.invalidate(userNameProvider);
                                ref.invalidate(currencyProvider);
                                ref.invalidate(onboardingCompleteProvider);
                                ref.invalidate(disabledCategoriesProvider);

                                if (!context.mounted) return;
                                Navigator.pop(ctx);
                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'All data cleared. Restarting...',
                                    ),
                                  ),
                                );

                                await Future.delayed(
                                  const Duration(seconds: 1),
                                );
                                SystemNavigator.pop();
                              },
                              child: const Text('Delete Everything'),
                            ),
                          ],
                        ),
                  );
                },
                child: const Text('Delete All'),
              ),
            ],
          ),
    );
  }

  void _showManageCategories(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _ManageCategoriesSheet(),
    );
  }

  void _showAddCategory(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _AddCategorySheet(),
    );
  }
}

class _ManageCategoriesSheet extends ConsumerWidget {
  const _ManageCategoriesSheet();

  static const _defaultExpenseIds = {
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

  void _confirmDeleteCustomCategory(
    BuildContext context,
    WidgetRef ref,
    CategoryEntity cat,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Delete “${cat.name}”?'),
            content: const Text(
              'Budgets will be deleted, and transactions will be moved to Miscellaneous.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final db = ref.read(databaseProvider);
                  await db.deleteCustomCategory(cat.id);
                  ref.invalidate(categoriesProvider);
                  ref.invalidate(budgetsStreamProvider);
                  ref.invalidate(totalBalanceProvider);
                  ref.invalidate(monthIncomeProvider);
                  ref.invalidate(monthExpenseProvider);
                  ref.invalidate(expensesByCategoryProvider);
                  ref.invalidate(netSpentByCategoryProvider);
                  ref.invalidate(dailyExpensesProvider);
                  ref.invalidate(recentTransactionsProvider);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Category "${cat.name}" deleted')),
                    );
                  }
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final disabledSet = ref.watch(disabledCategoriesProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('Manage Categories', style: textTheme.titleLarge),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: categoriesAsync.when(
                data: (cats) {
                  final filteredCats =
                      cats.where((c) => c.id != 'other').toList();

                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredCats.length,
                    separatorBuilder:
                        (_, __) => const Divider(height: 1, indent: 64),
                    itemBuilder: (context, i) {
                      final cat = filteredCats[i];
                      final isEnabled = !disabledSet.contains(cat.id);
                      final isExpense =
                          cat.id.startsWith('custom_expense_') ||
                          (_defaultExpenseIds.contains(cat.id) &&
                              !cat.isCustom);

                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            cat.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        title: Text(cat.name),
                        subtitle: Text(
                          isExpense ? 'Expense Category' : 'Income Category',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (cat.isCustom)
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: colorScheme.error,
                                ),
                                onPressed:
                                    () => _confirmDeleteCustomCategory(
                                      context,
                                      ref,
                                      cat,
                                    ),
                              ),
                            Switch(
                              value: isEnabled,
                              onChanged: (val) async {
                                HapticFeedback.selectionClick();
                                final newSet = Set<String>.from(disabledSet);
                                if (val) {
                                  newSet.remove(cat.id);
                                } else {
                                  newSet.add(cat.id);
                                }
                                final db = ref.read(databaseProvider);
                                await db.setSetting(
                                  'disabled_categories',
                                  newSet.join(','),
                                );
                                ref.invalidate(settingsCacheProvider);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading:
                    () => const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                error:
                    (e, _) => SizedBox(
                      height: 200,
                      child: Center(child: Text('Error: $e')),
                    ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _AddCategorySheet extends ConsumerStatefulWidget {
  const _AddCategorySheet();

  @override
  ConsumerState<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends ConsumerState<_AddCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedEmoji = '🥦';
  TransactionType _type = TransactionType.expense;
  bool _saving = false;

  final List<String> _popularEmojis = [
    '🥦',
    '🍕',
    '⛽',
    '🍿',
    '🛍️',
    '💵',
    '📶',
    '💡',
    '💧',
    '✈️',
    '📱',
    '💳',
    '💊',
    '🚗',
    '💸',
    '🍔',
    '☕',
    '🎬',
    '🎮',
    '⚽',
    '🎒',
    '🚕',
    '💇',
    '🎁',
    '🐶',
    '🏠',
    '🛠️',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final name = _nameController.text.trim();
      final uuid = const Uuid().v4();
      final isExpense = _type == TransactionType.expense;
      final categoryId = 'custom_${isExpense ? "expense" : "income"}_$uuid';

      final db = ref.read(databaseProvider);
      await db
          .into(db.categories)
          .insert(
            CategoryEntity(
              id: categoryId,
              name: name,
              emoji: _selectedEmoji,
              isCustom: true,
              sortOrder: 0,
            ),
          );

      ref.invalidate(categoriesProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Category "$name" created')));
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create category: $e')),
        );
      }
    }
  }

  void _showCustomEmojiDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Custom Emoji'),
            content: TextField(
              controller: controller,
              maxLength: 8,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32),
              autofocus: true,
              decoration: const InputDecoration(counterText: ''),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    setState(() {
                      _selectedEmoji = text;
                    });
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isExpense = _type == TransactionType.expense;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      'Add Custom Category',
                      style: textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Segmented Button Toggle for Type
                  SegmentedButton<TransactionType>(
                    segments: [
                      ButtonSegment(
                        value: TransactionType.expense,
                        label: Text(
                          'EXPENSE',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color:
                                isExpense
                                    ? Theme.of(context).colorScheme.error
                                    : null,
                          ),
                        ),
                        icon: Icon(
                          Icons.arrow_downward,
                          color:
                              isExpense
                                  ? Theme.of(context).colorScheme.error
                                  : null,
                        ),
                      ),
                      ButtonSegment(
                        value: TransactionType.income,
                        label: Text(
                          'INCOME',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: !isExpense ? Colors.green : null,
                          ),
                        ),
                        icon: Icon(
                          Icons.arrow_upward,
                          color: !isExpense ? Colors.green : null,
                        ),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (set) {
                      HapticFeedback.selectionClick();
                      setState(() => _type = set.first);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Category Name Input
                  TextFormField(
                    controller: _nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a category name';
                      }
                      if (value.trim().length > 30) {
                        return 'Name is too long (max 30 chars)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Emoji selector
                  Text('Select Emoji', style: textTheme.labelLarge),
                  const SizedBox(height: 8),
                  // Current Selected Emoji Preview
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _selectedEmoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grid of Popular Emojis
                  SizedBox(
                    height: 120,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                      itemCount: _popularEmojis.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _popularEmojis.length) {
                          // The custom emoji + button
                          return InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _showCustomEmojiDialog();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.add,
                                color: colorScheme.primary,
                                size: 24,
                              ),
                            ),
                          );
                        }

                        final emoji = _popularEmojis[index];
                        final isSelected = emoji == _selectedEmoji;
                        return InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedEmoji = emoji);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? colorScheme.primaryContainer
                                      : colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  isSelected
                                      ? Border.all(
                                        color: colorScheme.primary,
                                        width: 1,
                                      )
                                      : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child:
                          _saving
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Create Category',
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
        ),
      ),
    );
  }
}
