import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('Transaction JSON roundtrip', () {
    final moonLanding = DateTime.utc(1969, 7, 20, 20, 18, 04);
    final transaction = Transaction(
      transactionType: TransactionType.market,
      waypointSymbol: WaypointSymbol.fromString('S-E-P'),
      shipSymbol: const ShipSymbol('S', 1),
      tradeSymbol: TradeSymbol.FUEL,
      shipType: null,
      quantity: 1,
      tradeType: MarketTransactionTypeEnum.PURCHASE,
      perUnitPrice: 2,
      timestamp: moonLanding,
      agentCredits: 3,
      accounting: AccountingType.capital,
    );
    final json = transaction.toJson();
    final transaction2 = Transaction.fromJson(json);
    final json2 = transaction2.toJson();
    expect(json2, json);
    expect(transaction2, transaction);
  });

  // We don't actually care that hashCode is correct, we just implement it
  // because we implement equals.  But it was wrong at one point, so we test
  // that it's not wrong anymore.
  test('Transaction.hashCode', () {
    final moonLanding = DateTime.utc(1969, 7, 20, 20, 18, 04);

    final transaction = Transaction(
      transactionType: TransactionType.market,
      waypointSymbol: WaypointSymbol.fromString('S-E-P'),
      shipSymbol: const ShipSymbol('S', 1),
      tradeSymbol: TradeSymbol.FUEL,
      shipType: null,
      quantity: 1,
      tradeType: MarketTransactionTypeEnum.PURCHASE,
      perUnitPrice: 2,
      timestamp: moonLanding,
      agentCredits: 3,
      accounting: AccountingType.capital,
    );
    final transaction2 = Transaction(
      transactionType: TransactionType.market,
      waypointSymbol: WaypointSymbol.fromString('S-E-P'),
      shipSymbol: const ShipSymbol('S', 1),
      tradeSymbol: TradeSymbol.FUEL,
      shipType: null,
      quantity: 3,
      tradeType: MarketTransactionTypeEnum.PURCHASE,
      perUnitPrice: 2,
      timestamp: moonLanding,
      agentCredits: 1,
      accounting: AccountingType.capital,
    );
    // Note: Quanity and agentCredits are swapped relative to transaction1:
    expect(transaction.hashCode, isNot(transaction2.hashCode));
  });
}
