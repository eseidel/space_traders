import 'package:cli/api.dart';
import 'package:cli/cache/transactions.dart';
import 'package:test/test.dart';

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
  test('Transaction TransactionRecord roundtrip', () {
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
    final record = transaction.toRecord();
    final transaction2 = Transaction.fromRecord(record);
    final record2 = transaction2.toRecord();
    expect(record2, record);
    expect(transaction2, transaction);
  });
}
