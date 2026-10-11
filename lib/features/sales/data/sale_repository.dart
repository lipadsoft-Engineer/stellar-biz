import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../domain/record_sale_request.dart';
import '../domain/sale_validation_exception.dart';

final saleRepositoryProvider = Provider<SaleRepository>(
  (ref) => SaleRepository(ref.watch(appDatabaseProvider)),
);

final salesProvider = StreamProvider<List<Sale>>(
  (ref) => ref.watch(saleRepositoryProvider).watchSales(),
);

class SaleRepository {
  const SaleRepository(this._database);

  final AppDatabase _database;

  Stream<List<Sale>> watchSales() =>
      (_database.select(_database.sales)..orderBy([
            (sale) => OrderingTerm.desc(sale.transactionDate),
            (sale) => OrderingTerm.desc(sale.id),
          ]))
          .watch();

  Future<int> recordSale(RecordSaleRequest request) {
    if (request.items.isEmpty) {
      throw const SaleValidationException('Add at least one product.');
    }
    if (request.discountMinor < 0 || request.amountPaidMinor < 0) {
      throw const SaleValidationException('Amounts cannot be negative.');
    }

    final quantities = <int, int>{};
    for (final item in request.items) {
      if (item.productId <= 0 || item.quantity <= 0) {
        throw const SaleValidationException(
          'Choose a product and enter a quantity greater than zero.',
        );
      }
      quantities.update(
        item.productId,
        (quantity) => quantity + item.quantity,
        ifAbsent: () => item.quantity,
      );
    }

    return _database.transaction(() async {
      final saleLines = <({Product product, int quantity})>[];
      var subtotalMinor = 0;

      for (final entry in quantities.entries) {
        final product = await (_database.select(
          _database.products,
        )..where((row) => row.id.equals(entry.key))).getSingleOrNull();

        if (product == null || product.isArchived) {
          throw const SaleValidationException(
            'A selected product is unavailable.',
          );
        }
        if (product.stockQuantity < entry.value) {
          throw SaleValidationException(
            'Not enough stock for ${product.name}.',
          );
        }
        if (product.sellingPriceMinor < 0 || product.unitCostMinor < 0) {
          throw const SaleValidationException(
            'Product prices and costs must be zero or more.',
          );
        }

        saleLines.add((product: product, quantity: entry.value));
        subtotalMinor += product.sellingPriceMinor * entry.value;
      }

      if (request.discountMinor > subtotalMinor) {
        throw const SaleValidationException(
          'Discount cannot exceed the sale subtotal.',
        );
      }

      final totalMinor = subtotalMinor - request.discountMinor;
      if (request.amountPaidMinor > totalMinor) {
        throw const SaleValidationException(
          'Amount paid cannot exceed the sale total.',
        );
      }

      final transactionDate = request.transactionDate ?? DateTime.now();
      final paymentStatus = request.amountPaidMinor == 0
          ? 'unpaid'
          : request.amountPaidMinor == totalMinor
          ? 'paid'
          : 'partial';

      final saleId = await _database
          .into(_database.sales)
          .insert(
            SalesCompanion.insert(
              transactionDate: Value(transactionDate),
              status: const Value('completed'),
              subtotalMinor: subtotalMinor,
              discountMinor: Value(request.discountMinor),
              totalMinor: totalMinor,
              amountPaidMinor: Value(request.amountPaidMinor),
              paymentStatus: Value(paymentStatus),
              paymentMethod: Value(request.paymentMethod),
            ),
          );

      for (final line in saleLines) {
        final product = line.product;
        final quantity = line.quantity;
        final lineTotalMinor = product.sellingPriceMinor * quantity;

        await _database
            .into(_database.saleItems)
            .insert(
              SaleItemsCompanion.insert(
                saleId: saleId,
                productId: product.id,
                quantity: quantity,
                unitSellingPriceMinor: product.sellingPriceMinor,
                unitCostMinor: product.unitCostMinor,
                lineTotalMinor: lineTotalMinor,
              ),
            );

        final updatedRows =
            await (_database.update(_database.products)..where(
                  (row) =>
                      row.id.equals(product.id) &
                      row.stockQuantity.isBiggerOrEqualValue(quantity),
                ))
                .write(
                  ProductsCompanion.custom(
                    stockQuantity:
                        _database.products.stockQuantity - Constant(quantity),
                    updatedAt: Constant(DateTime.now()),
                  ),
                );
        if (updatedRows != 1) {
          throw SaleValidationException(
            'Stock changed while recording ${product.name}. Try again.',
          );
        }

        await _database
            .into(_database.inventoryMovements)
            .insert(
              InventoryMovementsCompanion.insert(
                productId: product.id,
                quantityDelta: -quantity,
                movementType: 'sale',
                saleId: Value(saleId),
              ),
            );
      }

      if (request.amountPaidMinor > 0) {
        await _database
            .into(_database.payments)
            .insert(
              PaymentsCompanion.insert(
                saleId: saleId,
                amountMinor: request.amountPaidMinor,
                paymentMethod: Value(request.paymentMethod),
                paidAt: Value(request.paidAt ?? DateTime.now()),
              ),
            );
      }

      return saleId;
    });
  }

  Future<void> recordPayment({
    required int saleId,
    required int amountMinor,
    required String paymentMethod,
  }) async {
    if (amountMinor <= 0) {
      throw const SaleValidationException('Enter a payment greater than zero.');
    }
    await _database.transaction(() async {
      final sale = await (_database.select(
        _database.sales,
      )..where((row) => row.id.equals(saleId))).getSingleOrNull();
      if (sale == null) {
        throw const SaleValidationException('This sale no longer exists.');
      }
      final balance = sale.totalMinor - sale.amountPaidMinor;
      if (amountMinor > balance) {
        throw const SaleValidationException(
          'Payment cannot exceed the remaining balance.',
        );
      }

      final method = paymentMethod.trim();
      await _database
          .into(_database.payments)
          .insert(
            PaymentsCompanion.insert(
              saleId: saleId,
              amountMinor: amountMinor,
              paymentMethod: Value(method.isEmpty ? null : method),
            ),
          );
      final paid = sale.amountPaidMinor + amountMinor;
      await (_database.update(
        _database.sales,
      )..where((row) => row.id.equals(saleId))).write(
        SalesCompanion(
          amountPaidMinor: Value(paid),
          paymentStatus: Value(paid == sale.totalMinor ? 'paid' : 'partial'),
          paymentMethod: Value(
            sale.paymentMethod == null || sale.paymentMethod == method
                ? method
                : 'multiple',
          ),
        ),
      );
    });
  }
}
