import 'package:protocol/src/messages/get_accounting_summary/get_accounting_summary_response.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('get_accounting_summary_response', () {
    final response = AccountingSummaryResponse(
      balanceSheet: BalanceSheet(
        cash: 1000,
        loans: 1000,
        inventory: 1000,
        ships: 1000,
        time: DateTime.now(),
      ),
      incomeStatement: IncomeStatement(
        start: DateTime.now(),
        end: DateTime.now(),
        goodsRevenue: 1000,
        contractsRevenue: 1000,
        chartingRevenue: 1000,
        assetSale: 1000,
        goodsPurchase: 1000,
        fuelPurchase: 1000,
        constructionMaterials: 1000,
        capEx: 1000,
        numberOfTransactions: 1000,
      ),
    );
    final json = response.toJson();
    expect(json, isA<Map<String, dynamic>>());
    final response2 = AccountingSummaryResponse.fromJson(json);
    expect(response2, equals(response));
  });
}
