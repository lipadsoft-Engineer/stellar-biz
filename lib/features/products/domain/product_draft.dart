final class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.unitCostMinor,
    required this.sellingPriceMinor,
    required this.initialStockQuantity,
    this.sku,
    this.category,
    this.imagePath,
    this.lowStockThreshold,
  });

  final String name;
  final String? sku;
  final String? category;
  final String? imagePath;
  final int unitCostMinor;
  final int sellingPriceMinor;
  final int initialStockQuantity;
  final int? lowStockThreshold;
}

final class ProductValidationException implements Exception {
  const ProductValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
