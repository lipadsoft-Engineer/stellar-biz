enum StockAdjustmentKind { restock, correction }

final class StockAdjustmentRequest {
  const StockAdjustmentRequest({
    required this.productId,
    required this.quantity,
    required this.kind,
    this.reason,
  });

  final int productId;
  final int quantity;
  final StockAdjustmentKind kind;
  final String? reason;
}

final class InventoryValidationException implements Exception {
  const InventoryValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
