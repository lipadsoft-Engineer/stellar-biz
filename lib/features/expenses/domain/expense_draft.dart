final class ExpenseDraft {
  const ExpenseDraft({
    required this.amountMinor,
    required this.category,
    required this.transactionDate,
    this.description,
    this.paymentMethod,
  });

  final int amountMinor;
  final String category;
  final DateTime transactionDate;
  final String? description;
  final String? paymentMethod;
}

final class ExpenseValidationException implements Exception {
  const ExpenseValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
