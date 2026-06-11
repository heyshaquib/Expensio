import 'package:drift/drift.dart';

/// Enum-like column for transaction type
class TransactionTypeConverter extends TypeConverter<TransactionType, int> {
  const TransactionTypeConverter();

  @override
  TransactionType fromSql(int fromDb) => TransactionType.values[fromDb];

  @override
  int toSql(TransactionType value) => value.index;
}

enum TransactionType { income, expense }

enum PaymentMethod { cash, upi, card, netBanking, wallet, unknown }

class PaymentMethodConverter extends TypeConverter<PaymentMethod, int> {
  const PaymentMethodConverter();

  @override
  PaymentMethod fromSql(int fromDb) => PaymentMethod.values[fromDb];

  @override
  int toSql(PaymentMethod value) => value.index;
}

enum BudgetPeriod { weekly, monthly }

class BudgetPeriodConverter extends TypeConverter<BudgetPeriod, int> {
  const BudgetPeriodConverter();

  @override
  BudgetPeriod fromSql(int fromDb) => BudgetPeriod.values[fromDb];

  @override
  int toSql(BudgetPeriod value) => value.index;
}

// Tables

@DataClassName('CategoryEntity')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get emoji => text().withDefault(const Constant('🧾'))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionEntity')
class Transactions extends Table {
  TextColumn get id => text()();
  RealColumn get amount => real()();
  IntColumn get type => integer().map(const TransactionTypeConverter())();
  TextColumn get categoryId => text().references(Categories, #id).nullable()();

  TextColumn get merchant => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get date => dateTime()();
  IntColumn get paymentMethod =>
      integer()
          .map(const PaymentMethodConverter())
          .withDefault(const Constant(5))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BudgetEntity')
class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().references(Categories, #id)();
  RealColumn get amount => real()();
  IntColumn get period =>
      integer()
          .map(const BudgetPeriodConverter())
          .withDefault(const Constant(1))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SettingEntity')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
