enum SaleFinancialStatus { completed, voided }

class SaleLineAmounts {
  const SaleLineAmounts({
    required this.quantity,
    required this.unitSellingPriceMinor,
    required this.unitCostMinor,
  });

  final int quantity;
  final int unitSellingPriceMinor;
  final int unitCostMinor;
}

class SaleFinancialRecord {
  const SaleFinancialRecord({
    required this.items,
    this.discountMinor = 0,
    this.refundedMinor = 0,
    this.returnedCostMinor = 0,
    this.status = SaleFinancialStatus.completed,
  });

  final List<SaleLineAmounts> items;
  final int discountMinor;
  final int refundedMinor;

  /// Cost of goods returned to stock as part of the refund.
  final int returnedCostMinor;
  final SaleFinancialStatus status;
}

class ExpenseFinancialRecord {
  const ExpenseFinancialRecord({
    required this.amountMinor,
    this.isVoided = false,
  });

  final int amountMinor;
  final bool isVoided;
}

class ProfitSummary {
  const ProfitSummary({
    required this.salesRevenueMinor,
    required this.costOfGoodsSoldMinor,
    required this.grossProfitMinor,
    required this.operatingExpensesMinor,
    required this.netProfitMinor,
  });

  final int salesRevenueMinor;
  final int costOfGoodsSoldMinor;
  final int grossProfitMinor;
  final int operatingExpensesMinor;
  final int netProfitMinor;
}

abstract final class ProfitCalculator {
  static ProfitSummary calculate({
    required Iterable<SaleFinancialRecord> sales,
    required Iterable<ExpenseFinancialRecord> expenses,
  }) {
    var revenueMinor = 0;
    var costOfGoodsSoldMinor = 0;

    for (final sale in sales) {
      if (sale.status == SaleFinancialStatus.voided) continue;
      if (sale.items.isEmpty) {
        throw ArgumentError('A completed sale must contain at least one item.');
      }

      var saleRevenueMinor = 0;
      var saleCostMinor = 0;
      for (final item in sale.items) {
        if (item.quantity <= 0 ||
            item.unitSellingPriceMinor < 0 ||
            item.unitCostMinor < 0) {
          throw ArgumentError(
            'Sale quantities, prices, and costs are invalid.',
          );
        }
        saleRevenueMinor += item.quantity * item.unitSellingPriceMinor;
        saleCostMinor += item.quantity * item.unitCostMinor;
      }

      if (sale.discountMinor < 0 || sale.discountMinor > saleRevenueMinor) {
        throw ArgumentError('Discount must be between zero and sale revenue.');
      }
      final afterDiscountMinor = saleRevenueMinor - sale.discountMinor;
      if (sale.refundedMinor < 0 || sale.refundedMinor > afterDiscountMinor) {
        throw ArgumentError('Refund cannot exceed the discounted sale amount.');
      }
      if (sale.returnedCostMinor < 0 ||
          sale.returnedCostMinor > saleCostMinor) {
        throw ArgumentError(
          'Returned cost cannot exceed the original sale cost.',
        );
      }

      revenueMinor += afterDiscountMinor - sale.refundedMinor;
      costOfGoodsSoldMinor += saleCostMinor - sale.returnedCostMinor;
    }

    var operatingExpensesMinor = 0;
    for (final expense in expenses) {
      if (expense.amountMinor < 0) {
        throw ArgumentError('Expense amount cannot be negative.');
      }
      if (!expense.isVoided) {
        operatingExpensesMinor += expense.amountMinor;
      }
    }

    final grossProfitMinor = revenueMinor - costOfGoodsSoldMinor;
    return ProfitSummary(
      salesRevenueMinor: revenueMinor,
      costOfGoodsSoldMinor: costOfGoodsSoldMinor,
      grossProfitMinor: grossProfitMinor,
      operatingExpensesMinor: operatingExpensesMinor,
      netProfitMinor: grossProfitMinor - operatingExpensesMinor,
    );
  }
}
