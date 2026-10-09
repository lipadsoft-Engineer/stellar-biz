final class SaleValidationException implements Exception {
  const SaleValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
