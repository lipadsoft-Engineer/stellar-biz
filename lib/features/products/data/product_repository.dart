import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../domain/product_draft.dart';

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(ref.watch(appDatabaseProvider)),
);

final productsProvider = StreamProvider<List<Product>>(
  (ref) => ref.watch(productRepositoryProvider).watchProducts(),
);

class ProductRepository {
  const ProductRepository(this._database);

  final AppDatabase _database;

  Stream<List<Product>> watchProducts() => (_database.select(
    _database.products,
  )..orderBy([(product) => OrderingTerm.asc(product.name)])).watch();

  Future<int> createProduct(ProductDraft draft) {
    _validate(draft);
    return _database.transaction(() async {
      final now = DateTime.now();
      final productId = await _database
          .into(_database.products)
          .insert(
            ProductsCompanion.insert(
              name: draft.name.trim(),
              sku: Value(_optionalText(draft.sku)),
              category: Value(_optionalText(draft.category)),
              unitCostMinor: draft.unitCostMinor,
              sellingPriceMinor: draft.sellingPriceMinor,
              stockQuantity: Value(draft.initialStockQuantity),
              lowStockThreshold: Value(draft.lowStockThreshold),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      if (draft.initialStockQuantity > 0) {
        await _database
            .into(_database.inventoryMovements)
            .insert(
              InventoryMovementsCompanion.insert(
                productId: productId,
                quantityDelta: draft.initialStockQuantity,
                movementType: 'opening_balance',
                reason: const Value('Opening stock'),
              ),
            );
      }
      return productId;
    });
  }

  Future<void> updateProduct(int id, ProductDraft draft) async {
    _validate(draft);
    final rows =
        await (_database.update(
          _database.products,
        )..where((product) => product.id.equals(id))).write(
          ProductsCompanion(
            name: Value(draft.name.trim()),
            sku: Value(_optionalText(draft.sku)),
            category: Value(_optionalText(draft.category)),
            unitCostMinor: Value(draft.unitCostMinor),
            sellingPriceMinor: Value(draft.sellingPriceMinor),
            lowStockThreshold: Value(draft.lowStockThreshold),
            updatedAt: Value(DateTime.now()),
          ),
        );
    if (rows == 0) {
      throw const ProductValidationException('This product no longer exists.');
    }
  }

  Future<void> setArchived(int id, {required bool archived}) async {
    final rows =
        await (_database.update(
          _database.products,
        )..where((product) => product.id.equals(id))).write(
          ProductsCompanion(
            isArchived: Value(archived),
            updatedAt: Value(DateTime.now()),
          ),
        );
    if (rows == 0) {
      throw const ProductValidationException('This product no longer exists.');
    }
  }

  Future<void> deleteUnusedProduct(int id) async {
    await _database.transaction(() async {
      final saleItem =
          await (_database.select(_database.saleItems)
                ..where((item) => item.productId.equals(id))
                ..limit(1))
              .getSingleOrNull();
      final movement =
          await (_database.select(_database.inventoryMovements)
                ..where((row) => row.productId.equals(id))
                ..limit(1))
              .getSingleOrNull();

      if (saleItem != null || movement != null) {
        throw const ProductValidationException(
          'This product has history. Archive it to keep its records.',
        );
      }

      final rows = await (_database.delete(
        _database.products,
      )..where((product) => product.id.equals(id))).go();
      if (rows == 0) {
        throw const ProductValidationException(
          'This product no longer exists.',
        );
      }
    });
  }

  void _validate(ProductDraft draft) {
    if (draft.name.trim().isEmpty) {
      throw const ProductValidationException('Enter a product name.');
    }
    if (draft.unitCostMinor < 0 || draft.sellingPriceMinor < 0) {
      throw const ProductValidationException('Prices cannot be negative.');
    }
    if (draft.initialStockQuantity < 0) {
      throw const ProductValidationException('Stock cannot be negative.');
    }
    if (draft.lowStockThreshold != null && draft.lowStockThreshold! < 0) {
      throw const ProductValidationException(
        'Low-stock quantity cannot be negative.',
      );
    }
  }

  String? _optionalText(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
