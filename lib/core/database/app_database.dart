import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Categories, Transactions, Budgets, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal() : super(_openConnection());

  static AppDatabase? _instance;
  static AppDatabase get instance {
    _instance ??= AppDatabase._internal();
    return _instance!;
  }

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _seedCategories();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Drop automation-related tables that are no longer used
        await customStatement('DROP TABLE IF EXISTS pending_notifications');
        await customStatement('DROP TABLE IF EXISTS monitored_apps');
      }
      if (from < 3) {
        // Drop unused accounts table and SMS tracking columns from transactions/budgets
        await customStatement('DROP TABLE IF EXISTS accounts');
        await m.alterTable(TableMigration(transactions));
        await m.alterTable(TableMigration(budgets));
      }
      if (from < 4) {
        await m.createTable(settings);

        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys();
        for (final key in keys) {
          final val = prefs.get(key);
          if (val != null) {
            await into(settings).insert(
              SettingsCompanion.insert(key: key, value: val.toString()),
              mode: InsertMode.insertOrReplace,
            );
          }
        }
      }
      if (from < 5) {
        await customStatement(
          "UPDATE categories SET name = 'Miscellaneous' WHERE id = 'other'",
        );
      }
      if (from < 6) {
        await customStatement(
          "UPDATE categories SET emoji = '🧾' WHERE id = 'other'",
        );
      }
      if (from < 7) {
        // Delete old unused default categories
        await customStatement(
          "DELETE FROM categories WHERE id IN ('bills', 'rent', 'emi', 'investment')",
        );
        // Seed/refresh new categories
        await _seedCategories();
      }
      if (from < 8) {
        // Seed/refresh new categories including leisure
        await _seedCategories();
      }
      if (from < 9) {
        // Seed/refresh new categories including rent
        await _seedCategories();
      }
      if (from < 10) {
        // Seed/refresh new categories including education and insurance
        await _seedCategories();
      }
    },
  );

  Future<void> _seedCategories() async {
    final defaultCategories = [
      CategoriesCompanion.insert(
        id: 'groceries',
        name: 'Groceries',
        emoji: const Value('🥦'),
      ),
      CategoriesCompanion.insert(
        id: 'food',
        name: 'Food',
        emoji: const Value('🍕'),
      ),
      CategoriesCompanion.insert(
        id: 'fuel',
        name: 'Fuel',
        emoji: const Value('⛽'),
      ),
      CategoriesCompanion.insert(
        id: 'entertainment',
        name: 'Entertainment',
        emoji: const Value('🍿'),
      ),
      CategoriesCompanion.insert(
        id: 'shopping',
        name: 'Shopping',
        emoji: const Value('🛍️'),
      ),
      CategoriesCompanion.insert(
        id: 'investments',
        name: 'Investments',
        emoji: const Value('💵'),
      ),
      CategoriesCompanion.insert(
        id: 'internet',
        name: 'Internet',
        emoji: const Value('📶'),
      ),
      CategoriesCompanion.insert(
        id: 'electricity',
        name: 'Electricity',
        emoji: const Value('💡'),
      ),
      CategoriesCompanion.insert(
        id: 'water',
        name: 'Water',
        emoji: const Value('💧'),
      ),
      CategoriesCompanion.insert(
        id: 'travel',
        name: 'Travel',
        emoji: const Value('✈️'),
      ),
      CategoriesCompanion.insert(
        id: 'electronics',
        name: 'Electronics',
        emoji: const Value('📱'),
      ),
      CategoriesCompanion.insert(
        id: 'taxes',
        name: 'Taxes',
        emoji: const Value('💳'),
      ),
      CategoriesCompanion.insert(
        id: 'health',
        name: 'Health',
        emoji: const Value('💊'),
      ),
      CategoriesCompanion.insert(
        id: 'transport',
        name: 'Transport',
        emoji: const Value('🚗'),
      ),
      CategoriesCompanion.insert(
        id: 'leisure',
        name: 'Leisure',
        emoji: const Value('🏖️'),
      ),
      CategoriesCompanion.insert(
        id: 'rent',
        name: 'Rent',
        emoji: const Value('🏠'),
      ),
      CategoriesCompanion.insert(
        id: 'education',
        name: 'Education',
        emoji: const Value('🎓'),
      ),
      CategoriesCompanion.insert(
        id: 'insurance',
        name: 'Insurance',
        emoji: const Value('🛡️'),
      ),
      CategoriesCompanion.insert(
        id: 'salary',
        name: 'Salary',
        emoji: const Value('💲'),
      ),
      CategoriesCompanion.insert(
        id: 'freelance',
        name: 'Freelance',
        emoji: const Value('📋'),
      ),
      CategoriesCompanion.insert(
        id: 'business',
        name: 'Business',
        emoji: const Value('💰'),
      ),
      CategoriesCompanion.insert(
        id: 'other',
        name: 'Miscellaneous',
        emoji: const Value('🧾'),
      ),
    ];
    for (final cat in defaultCategories) {
      await into(categories).insert(cat, mode: InsertMode.insertOrReplace);
    }
  }

  // Categories

  Future<List<CategoryEntity>> getAllCategories() => select(categories).get();

  // Settings

  Future<String?> getSetting(String key) async {
    final result =
        await (select(settings)
          ..where((s) => s.key.equals(key))).getSingleOrNull();
    return result?.value;
  }

  Future<void> setSetting(String key, String value) async {
    await into(settings).insert(
      SettingsCompanion.insert(key: key, value: value),
      mode: InsertMode.insertOrReplace,
    );
  }

  // Transactions

  Stream<List<TransactionEntity>> watchAllTransactions() =>
      (select(transactions)
        ..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();

  Future<List<TransactionEntity>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) =>
      (select(transactions)
            ..where(
              (t) =>
                  t.date.isBiggerOrEqualValue(start) &
                  t.date.isSmallerOrEqualValue(end),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

  Stream<List<TransactionEntity>> watchRecentTransactions(int limit) =>
      (select(transactions)
            ..orderBy([(t) => OrderingTerm.desc(t.date)])
            ..limit(limit))
          .watch();

  Future<int> insertTransaction(TransactionsCompanion txn) =>
      into(transactions).insert(txn, mode: InsertMode.insertOrReplace);

  Future<int> deleteTransaction(String id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  // Aggregation queries

  Future<double> getTotalIncome([DateTime? start, DateTime? end]) async {
    final query = selectOnly(transactions)
      ..addColumns([transactions.amount.sum()]);
    query.where(transactions.type.equals(TransactionType.income.index));
    if (start != null) {
      query.where(transactions.date.isBiggerOrEqualValue(start));
    }
    if (end != null) {
      query.where(transactions.date.isSmallerOrEqualValue(end));
    }
    final result = await query.getSingle();
    return result.read(transactions.amount.sum()) ?? 0.0;
  }

  Future<double> getTotalExpense([DateTime? start, DateTime? end]) async {
    final query = selectOnly(transactions)
      ..addColumns([transactions.amount.sum()]);
    query.where(transactions.type.equals(TransactionType.expense.index));
    if (start != null) {
      query.where(transactions.date.isBiggerOrEqualValue(start));
    }
    if (end != null) {
      query.where(transactions.date.isSmallerOrEqualValue(end));
    }
    final result = await query.getSingle();
    return result.read(transactions.amount.sum()) ?? 0.0;
  }

  Future<Map<String, double>> getExpensesByCategory(
    DateTime start,
    DateTime end,
  ) async {
    final txns = await getTransactionsByDateRange(start, end);
    final map = <String, double>{};
    for (final txn in txns) {
      final catId = txn.categoryId;
      if (catId == null) continue;
      final amount = txn.amount;
      if (txn.type == TransactionType.expense) {
        map[catId] = (map[catId] ?? 0.0) + amount;
      }
    }
    return map;
  }

  Future<Map<String, double>> getNetSpentByCategory(
    DateTime start,
    DateTime end,
  ) async {
    final txns = await getTransactionsByDateRange(start, end);
    final map = <String, double>{};
    for (final txn in txns) {
      final catId = txn.categoryId;
      if (catId == null) continue;
      final amount = txn.amount;
      if (txn.type == TransactionType.expense) {
        map[catId] = (map[catId] ?? 0.0) + amount;
      } else if (txn.type == TransactionType.income) {
        map[catId] = (map[catId] ?? 0.0) - amount;
      }
    }
    return map;
  }

  Future<Map<int, double>> getDailyExpenses(
    DateTime start,
    DateTime end,
  ) async {
    final txns = await getTransactionsByDateRange(start, end);
    final map = <int, double>{};
    for (final txn in txns) {
      if (txn.type == TransactionType.expense) {
        final day = txn.date.day;
        map[day] = (map[day] ?? 0) + txn.amount;
      }
    }
    return map;
  }

  // Budgets

  Stream<List<BudgetEntity>> watchAllBudgets() => select(budgets).watch();

  Future<int> insertBudget(BudgetsCompanion budget) =>
      into(budgets).insert(budget, mode: InsertMode.insertOrReplace);

  Future<int> deleteBudget(String id) =>
      (delete(budgets)..where((b) => b.id.equals(id))).go();

  // Clear all

  Future<void> clearAllData() async {
    await delete(transactions).go();
    await delete(budgets).go();
    await (delete(categories)..where((c) => c.isCustom.equals(true))).go();
    await delete(settings).go();
  }

  // Backup & Restore JSON Helpers

  Future<Map<String, dynamic>> exportToJson() async {
    final cats = await select(categories).get();
    final txns = await select(transactions).get();
    final bdgts = await select(budgets).get();
    final setts = await select(settings).get();

    return {
      'version': schemaVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'settings': setts.map((s) => {'key': s.key, 'value': s.value}).toList(),
      'categories':
          cats
              .map(
                (c) => {
                  'id': c.id,
                  'name': c.name,
                  'emoji': c.emoji,
                  'isCustom': c.isCustom,
                  'sortOrder': c.sortOrder,
                },
              )
              .toList(),
      'transactions':
          txns
              .map(
                (t) => {
                  'id': t.id,
                  'amount': t.amount,
                  'type': t.type.index,
                  'categoryId': t.categoryId,
                  'merchant': t.merchant,
                  'note': t.note,
                  'date': t.date.toIso8601String(),
                  'paymentMethod': t.paymentMethod.index,
                  'createdAt': t.createdAt.toIso8601String(),
                },
              )
              .toList(),
      'budgets':
          bdgts
              .map(
                (b) => {
                  'id': b.id,
                  'categoryId': b.categoryId,
                  'amount': b.amount,
                  'period': b.period.index,
                  'createdAt': b.createdAt.toIso8601String(),
                },
              )
              .toList(),
    };
  }

  Future<void> importFromJson(Map<String, dynamic> json) async {
    await transaction(() async {
      // 1. Clear existing data
      await delete(transactions).go();
      await delete(budgets).go();
      await delete(categories).go();
      await delete(settings).go();

      // 2. Import Settings
      if (json['settings'] != null) {
        for (final item in json['settings']) {
          final s = SettingEntity(
            key: item['key'] as String,
            value: item['value'] as String,
          );
          await into(settings).insert(s, mode: InsertMode.insertOrReplace);
        }
      }

      // 3. Import Categories
      if (json['categories'] != null) {
        for (final item in json['categories']) {
          final c = CategoryEntity(
            id: item['id'] as String,
            name: item['name'] as String,
            emoji: item['emoji'] as String,
            isCustom: item['isCustom'] as bool? ?? false,
            sortOrder: item['sortOrder'] as int? ?? 0,
          );
          await into(categories).insert(c, mode: InsertMode.insertOrReplace);
        }
      }

      // 4. Import Transactions
      if (json['transactions'] != null) {
        for (final item in json['transactions']) {
          final t = TransactionEntity(
            id: item['id'] as String,
            amount: (item['amount'] as num).toDouble(),
            type: TransactionType.values[item['type'] as int],
            categoryId: item['categoryId'] as String?,
            merchant: item['merchant'] as String?,
            note: item['note'] as String?,
            date: DateTime.parse(item['date'] as String),
            paymentMethod:
                PaymentMethod.values[item['paymentMethod'] as int? ?? 5],
            createdAt:
                item['createdAt'] != null
                    ? DateTime.parse(item['createdAt'] as String)
                    : DateTime.now(),
          );
          await into(transactions).insert(t, mode: InsertMode.insertOrReplace);
        }
      }

      // 5. Import Budgets
      if (json['budgets'] != null) {
        for (final item in json['budgets']) {
          final b = BudgetEntity(
            id: item['id'] as String,
            categoryId: item['categoryId'] as String,
            amount: (item['amount'] as num).toDouble(),
            period: BudgetPeriod.values[item['period'] as int? ?? 1],
            createdAt:
                item['createdAt'] != null
                    ? DateTime.parse(item['createdAt'] as String)
                    : DateTime.now(),
          );
          await into(budgets).insert(b, mode: InsertMode.insertOrReplace);
        }
      }
    });
  }

  Future<void> deleteCustomCategory(String categoryId) async {
    await transaction(() async {
      // Update any transactions associated with this category to default to 'other'
      await (update(transactions)..where(
        (t) => t.categoryId.equals(categoryId),
      )).write(const TransactionsCompanion(categoryId: Value('other')));
      // Delete any budgets associated with this category
      await (delete(budgets)
        ..where((b) => b.categoryId.equals(categoryId))).go();
      // Delete the category itself
      await (delete(categories)
        ..where((c) => c.id.equals(categoryId) & c.isCustom.equals(true))).go();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'expensio.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
