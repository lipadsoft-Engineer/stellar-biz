import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../domain/stock_adjustment_request.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => InventoryRepository(ref.watch(appDatabaseProvider)),
);

final productMovementsProvider =
    StreamProvider.family<List<InventoryMovement>, int>(
      (ref, productId) => ref
          .watch(inventoryRepositoryProvider)
          .watchMovementsForProduct(productId),
    );

class InventoryRepository {
  const InventoryRepository(this._database);

  final AppDatabase _database;

  Stream<List<InventoryMovement>> watchMovementsForProduct(int productId) =>
      (_database.select(_database.inventoryMovements)
            ..where((movement) => movement.productId.equals(productId))
            ..orderBy([
              (movement) => OrderingTerm.desc(movement.createdAt),
              (movement) => OrderingTerm.desc(movement.id),
            ]))
          .watch();

  Future<void> adjustStock(StockAdjustmentRequest request) async {
    if (request.productId <= 0 || request.quantity <= 0) {
      throw const InventoryValidationException(
        'Enter a quantity greater than zero.',
      );
    }
    if (request.kind == StockAdjustmentKind.correction &&
        (request.reason == null || request.reason!.trim().isEmpty)) {
      throw const InventoryValidationException(
        'Add a reason for this stock correction.',
      );
    }

    final delta = request.kind == StockAdjustmentKind.restock
        ? request.quantity
        : -request.quantity;
    final now = DateTime.now();

    await _database.transaction(() async {
      final product = await (_database.select(
        _database.products,
      )..where((row) => row.id.equals(request.productId))).getSingleOrNull();
      if (product == null) {
        throw const InventoryValidationException(
          'This product no longer exists.',
        );
      }
      if (product.isArchived) {
        throw const InventoryValidationException(
          'Restore this product before changing its stock.',
        );
      }
      if (delta < 0 && product.stockQuantity < -delta) {
        throw InventoryValidationException(
          'Only ${product.stockQuantity} units are available.',
        );
      }

      final update = _database.update(_database.products)
        ..where((row) {
          final activeProduct =
              row.id.equals(request.productId) & row.isArchived.equals(false);
          return delta < 0
              ? activeProduct & row.stockQuantity.isBiggerOrEqualValue(-delta)
              : activeProduct;
        });
      final changed = await update.write(
        ProductsCompanion.custom(
          stockQuantity: _database.products.stockQuantity + Constant(delta),
          updatedAt: Constant(now),
        ),
      );

      if (changed != 1) {
        throw const InventoryValidationException(
          'Stock changed before this update was saved. Try again.',
        );
      }

      await _database
          .into(_database.inventoryMovements)
          .insert(
            InventoryMovementsCompanion.insert(
              productId: request.productId,
              quantityDelta: delta,
              movementType: request.kind == StockAdjustmentKind.restock
                  ? 'restock'
                  : 'adjustment',
              reason: Value(_cleanReason(request.reason)),
              createdAt: Value(now),
            ),
          );
    });
  }

  String? _cleanReason(String? reason) {
    final value = reason?.trim();
    return value == null || value.isEmpty ? null : value;
  }
}
