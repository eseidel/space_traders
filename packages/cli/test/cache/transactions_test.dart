import 'package:cli/api.dart';
import 'package:cli/cache/transactions.dart';
import 'package:test/test.dart';

void main() {
  test('Transaction JSON roundtrip', () {
    final moonLanding = DateTime.utc(1969, 7, 20, 20, 18, 04);
    final price = Transaction(
      waypointSymbol: WaypointSymbol.fromString('S-E-P'),
      shipSymbol: const ShipSymbol('S', 1),
      tradeSymbol: TradeSymbol.FUEL.value,
      quantity: 1,
      tradeType: MarketTransactionTypeEnum.PURCHASE,
      perUnitPrice: 2,
      timestamp: moonLanding,
      agentCredits: 3,
      accounting: AccountingType.capital,
    );
    final json = price.toJson();
    final price2 = Transaction.fromJson(json);
    final json2 = price2.toJson();
    expect(price2, price);
    expect(json2, json);
  });
}
