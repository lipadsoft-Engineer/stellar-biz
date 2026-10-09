final class RecordSaleRequest {
  const RecordSaleRequest({
    required this.items,
    this.discountMinor = 0,
    this.amountPaidMinor = 0,
    this.paymentMethod,
    this.transactionDate,
    this.paidAt,
  });

  final List<RecordSaleLine> items;
  final int discountMinor;
  final int amountPaidMinor;
  final String? paymentMethod;
  final DateTime? transactionDate;
  final DateTime? paidAt;
}

final class RecordSaleLine {
  const RecordSaleLine({required this.productId, required this.quantity});

  final int productId;
  final int quantity;
}
