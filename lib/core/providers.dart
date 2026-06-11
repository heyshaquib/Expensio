import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/app_database.dart';
import '../core/database/tables.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// Database
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

// Settings Cache
final settingsCacheProvider = FutureProvider<Map<String, String>>((ref) async {
  final db = ref.watch(databaseProvider);
  final allSettings = await db.select(db.settings).get();
  return {for (var s in allSettings) s.key: s.value};
});

// Settings
final userNameProvider = StateProvider<String>((ref) {
  final settings = ref.watch(settingsCacheProvider).valueOrNull ?? {};
  return settings['user_name'] ?? 'User';
});

final currencyProvider = StateProvider<String>((ref) {
  final settings = ref.watch(settingsCacheProvider).valueOrNull ?? {};
  return settings['currency'] ?? 'INR';
});

final themeModeProvider = StateProvider<String>((ref) {
  final settings = ref.watch(settingsCacheProvider).valueOrNull ?? {};
  return settings['theme_mode'] ?? 'system';
});

final dynamicColorProvider = StateProvider<bool>((ref) {
  final settings = ref.watch(settingsCacheProvider).valueOrNull ?? {};
  return (settings['dynamic_color'] ?? 'true') == 'true';
});

final onboardingCompleteProvider = StateProvider<bool>((ref) {
  final settings = ref.watch(settingsCacheProvider).valueOrNull ?? {};
  return (settings['onboarding_complete'] ?? 'false') == 'true';
});

final disabledCategoriesProvider = StateProvider<Set<String>>((ref) {
  final settings = ref.watch(settingsCacheProvider).valueOrNull ?? {};
  final raw = settings['disabled_categories'] ?? '';
  if (raw.isEmpty) return const <String>{};
  return raw.split(',').toSet();
});

// Categories
final categoriesProvider = FutureProvider<List<CategoryEntity>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getAllCategories();
});

// Transactions
final transactionsStreamProvider = StreamProvider<List<TransactionEntity>>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  return db.watchAllTransactions();
});

final recentTransactionsProvider = StreamProvider<List<TransactionEntity>>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  return db.watchRecentTransactions(10);
});

final monthTransactionsProvider =
    FutureProvider.family<List<TransactionEntity>, DateTime>((ref, month) {
      final db = ref.watch(databaseProvider);
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      return db.getTransactionsByDateRange(start, end);
    });

// Aggregated data
final totalBalanceProvider = FutureProvider<double>((ref) async {
  final db = ref.watch(databaseProvider);
  final income = await db.getTotalIncome();
  final expense = await db.getTotalExpense();
  return income - expense;
});

final monthIncomeProvider = FutureProvider<double>((ref) {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  return db.getTotalIncome(start, end);
});

final monthExpenseProvider = FutureProvider<double>((ref) {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  return db.getTotalExpense(start, end);
});

final expensesByCategoryProvider =
    FutureProvider.family<Map<String, double>, DateTime>((ref, month) {
      final db = ref.watch(databaseProvider);
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      return db.getExpensesByCategory(start, end);
    });

final netSpentByCategoryProvider =
    FutureProvider.family<Map<String, double>, DateTime>((ref, month) {
      final db = ref.watch(databaseProvider);
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      return db.getNetSpentByCategory(start, end);
    });

final dailyExpensesProvider = FutureProvider.family<Map<int, double>, DateTime>(
  (ref, month) {
    final db = ref.watch(databaseProvider);
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return db.getDailyExpenses(start, end);
  },
);

// Budgets
final budgetsStreamProvider = StreamProvider<List<BudgetEntity>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllBudgets();
});

// Transaction operations
class TransactionNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;

  TransactionNotifier(this._db) : super(const AsyncValue.data(null));

  Future<void> addTransaction({
    String? id,
    required double amount,
    required TransactionType type,
    String? categoryId,
    String? merchant,
    String? note,
    required DateTime date,
    PaymentMethod paymentMethod = PaymentMethod.unknown,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _db.insertTransaction(
        TransactionsCompanion.insert(
          id: id ?? _uuid.v4(),
          amount: amount,
          type: type,
          categoryId: Value(categoryId),
          merchant: Value(merchant),
          note: Value(note),
          date: date,
          paymentMethod: Value(paymentMethod),
        ),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> restoreTransaction(TransactionEntity transaction) async {
    state = const AsyncValue.loading();
    try {
      await _db.insertTransaction(
        TransactionsCompanion.insert(
          id: transaction.id,
          amount: transaction.amount,
          type: transaction.type,
          categoryId: Value(transaction.categoryId),
          merchant: Value(transaction.merchant),
          note: Value(transaction.note),
          date: transaction.date,
          paymentMethod: Value(transaction.paymentMethod),
        ),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
  }
}

final transactionNotifierProvider =
    StateNotifierProvider<TransactionNotifier, AsyncValue<void>>((ref) {
      return TransactionNotifier(ref.watch(databaseProvider));
    });

// Budget operations
class BudgetNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;

  BudgetNotifier(this._db) : super(const AsyncValue.data(null));

  Future<void> addBudget({
    required String categoryId,
    required double amount,
    BudgetPeriod period = BudgetPeriod.monthly,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _db.insertBudget(
        BudgetsCompanion.insert(
          id: _uuid.v4(),
          categoryId: categoryId,
          amount: amount,
          period: Value(period),
        ),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteBudget(String id) async {
    await _db.deleteBudget(id);
  }
}

final budgetNotifierProvider =
    StateNotifierProvider<BudgetNotifier, AsyncValue<void>>((ref) {
      return BudgetNotifier(ref.watch(databaseProvider));
    });

// Search & filter
final searchQueryProvider = StateProvider<String>((ref) => '');

enum TransactionFilter { all, income, expense, thisWeek, thisMonth }

final transactionFilterProvider = StateProvider<TransactionFilter>(
  (ref) => TransactionFilter.all,
);

final filteredTransactionsProvider = Provider<List<TransactionEntity>>((ref) {
  final allTxns = ref.watch(transactionsStreamProvider).valueOrNull ?? [];
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final filter = ref.watch(transactionFilterProvider);

  var filtered = allTxns;

  // Apply text search
  if (query.isNotEmpty) {
    filtered =
        filtered.where((t) {
          return (t.merchant?.toLowerCase().contains(query) ?? false) ||
              (t.note?.toLowerCase().contains(query) ?? false) ||
              (t.categoryId?.toLowerCase().contains(query) ?? false) ||
              t.amount.toString().contains(query);
        }).toList();
  }

  // Apply type/date filter
  final now = DateTime.now();
  switch (filter) {
    case TransactionFilter.income:
      filtered =
          filtered.where((t) => t.type == TransactionType.income).toList();
      break;
    case TransactionFilter.expense:
      filtered =
          filtered.where((t) => t.type == TransactionType.expense).toList();
      break;
    case TransactionFilter.thisWeek:
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      filtered =
          filtered
              .where(
                (t) => t.date.isAfter(
                  DateTime(weekStart.year, weekStart.month, weekStart.day),
                ),
              )
              .toList();
      break;
    case TransactionFilter.thisMonth:
      filtered =
          filtered
              .where(
                (t) => t.date.month == now.month && t.date.year == now.year,
              )
              .toList();
      break;
    case TransactionFilter.all:
      break;
  }

  return filtered;
});

// Analytics
final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());
