import 'package:drift/drift.dart';

class Products extends Table {
  @override
  String get tableName => 'products';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get sku => text().nullable().unique()();
  TextColumn get category => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  IntColumn get unitCostMinor => integer()();
  IntColumn get sellingPriceMinor => integer()();
  IntColumn get stockQuantity => integer().withDefault(const Constant(0))();
  IntColumn get lowStockThreshold => integer().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
}

class Sales extends Table {
  @override
  String get tableName => 'sales';

  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get transactionDate =>
      dateTime().clientDefault(DateTime.now)();
  TextColumn get status => text().withDefault(const Constant('completed'))();
  IntColumn get subtotalMinor => integer()();
  IntColumn get discountMinor => integer().withDefault(const Constant(0))();
  IntColumn get totalMinor => integer()();
  IntColumn get amountPaidMinor => integer().withDefault(const Constant(0))();
  TextColumn get paymentStatus =>
      text().withDefault(const Constant('unpaid'))();
  TextColumn get paymentMethod => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
}

class SaleItems extends Table {
  @override
  String get tableName => 'sale_items';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId =>
      integer().references(Sales, #id, onDelete: KeyAction.restrict)();
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.restrict)();
  IntColumn get quantity => integer()();
  IntColumn get unitSellingPriceMinor => integer()();
  IntColumn get unitCostMinor => integer()();
  IntColumn get lineTotalMinor => integer()();
}

class Expenses extends Table {
  @override
  String get tableName => 'expenses';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get amountMinor => integer()();
  TextColumn get category => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get transactionDate =>
      dateTime().clientDefault(DateTime.now)();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
}

class Payments extends Table {
  @override
  String get tableName => 'payments';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId =>
      integer().references(Sales, #id, onDelete: KeyAction.restrict)();
  IntColumn get amountMinor => integer()();
  TextColumn get paymentMethod => text().nullable()();
  DateTimeColumn get paidAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
}

class InventoryMovements extends Table {
  @override
  String get tableName => 'inventory_movements';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.restrict)();
  IntColumn get quantityDelta => integer()();
  TextColumn get movementType => text()();
  IntColumn get saleId => integer().nullable().references(
    Sales,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
}
