import 'package:flutter_test/flutter_test.dart';
import 'package:sole_proprietor/features/reports/domain/profit_calculator.dart';

void main() {
  group('ProfitCalculator', () {
    test('returns zero totals when there are no transactions', () {
      final result = ProfitCalculator.calculate(sales: [], expenses: []);

      expect(result.salesRevenueMinor, 0);
      expect(result.costOfGoodsSoldMinor, 0);
      expect(result.grossProfitMinor, 0);
      expect(result.operatingExpensesMinor, 0);
      expect(result.netProfitMinor, 0);
    });

    test('uses sale-time prices and costs to calculate net profit', () {
      final result = ProfitCalculator.calculate(
        sales: const [
          SaleFinancialRecord(
            items: [
              SaleLineAmounts(
                quantity: 3,
                unitSellingPriceMinor: 125,
                unitCostMinor: 75,
              ),
              SaleLineAmounts(
                quantity: 2,
                unitSellingPriceMinor: 240,
                unitCostMinor: 90,
              ),
            ],
            discountMinor: 55,
          ),
        ],
        expenses: const [ExpenseFinancialRecord(amountMinor: 125)],
      );

      expect(result.salesRevenueMinor, 800);
      expect(result.costOfGoodsSoldMinor, 405);
      expect(result.grossProfitMinor, 395);
      expect(result.operatingExpensesMinor, 125);
      expect(result.netProfitMinor, 270);
    });

    test('subtracts refunds and returned cost, and ignores voided sales', () {
      final result = ProfitCalculator.calculate(
        sales: const [
          SaleFinancialRecord(
            items: [
              SaleLineAmounts(
                quantity: 2,
                unitSellingPriceMinor: 500,
                unitCostMinor: 300,
              ),
            ],
            discountMinor: 100,
            refundedMinor: 250,
            returnedCostMinor: 150,
          ),
          SaleFinancialRecord(
            items: [
              SaleLineAmounts(
                quantity: 1,
                unitSellingPriceMinor: 900,
                unitCostMinor: 400,
              ),
            ],
            status: SaleFinancialStatus.voided,
          ),
        ],
        expenses: const [
          ExpenseFinancialRecord(amountMinor: 50),
          ExpenseFinancialRecord(amountMinor: 700, isVoided: true),
        ],
      );

      expect(result.salesRevenueMinor, 650);
      expect(result.costOfGoodsSoldMinor, 450);
      expect(result.grossProfitMinor, 200);
      expect(result.operatingExpensesMinor, 50);
      expect(result.netProfitMinor, 150);
    });

    test('keeps fractional currency out of calculations', () {
      final result = ProfitCalculator.calculate(
        sales: const [
          SaleFinancialRecord(
            items: [
              SaleLineAmounts(
                quantity: 3,
                unitSellingPriceMinor: 101,
                unitCostMinor: 33,
              ),
            ],
          ),
        ],
        expenses: const [],
      );

      expect(result.salesRevenueMinor, 303);
      expect(result.costOfGoodsSoldMinor, 99);
      expect(result.grossProfitMinor, 204);
    });

    test('rejects a discount greater than sale revenue', () {
      expect(
        () => ProfitCalculator.calculate(
          sales: const [
            SaleFinancialRecord(
              items: [
                SaleLineAmounts(
                  quantity: 1,
                  unitSellingPriceMinor: 100,
                  unitCostMinor: 40,
                ),
              ],
              discountMinor: 101,
            ),
          ],
          expenses: const [],
        ),
        throwsArgumentError,
      );
    });
  });
}
