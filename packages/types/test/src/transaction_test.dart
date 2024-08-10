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
      contractAction: ContractAction.accept,
      contractId: '1234',
    );
    final json = transaction.toJson();
    final transaction2 = Transaction.fromJson(json);
    final json2 = transaction2.toJson();
    expect(json2, json);
    expect(transaction2, transaction);
    expect(transaction2.hashCode, transaction.hashCode);
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
      contractAction: null,
      contractId: null,
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
      contractAction: null,
      contractId: null,
    );
    // Note: Quantity and agentCredits are swapped relative to transaction1:
    expect(transaction.hashCode, isNot(transaction2.hashCode));
  });

  test('Transaction.fromMarketTransaction', () {
    final marketTransaction = MarketTransaction(
      waypointSymbol: 'A-B-C',
      shipSymbol: 'S-1',
      tradeSymbol: 'FUEL',
      type: MarketTransactionTypeEnum.PURCHASE,
      units: 10,
      pricePerUnit: 10,
      totalPrice: 100,
      timestamp: DateTime(2021),
    );
    final transaction = Transaction.fromMarketTransaction(
      marketTransaction,
      100,
      AccountingType.goods,
    );
    expect(transaction.transactionType, TransactionType.market);
    expect(transaction.waypointSymbol, WaypointSymbol.fromString('A-B-C'));
    expect(transaction.shipSymbol, const ShipSymbol('S', 1));
    expect(transaction.tradeSymbol, TradeSymbol.FUEL);
    expect(transaction.shipType, null);
    expect(transaction.quantity, 10);
    expect(transaction.tradeType, MarketTransactionTypeEnum.PURCHASE);
    expect(transaction.perUnitPrice, 10);
    expect(transaction.timestamp, DateTime(2021));
    expect(transaction.agentCredits, 100);
    expect(transaction.accounting, AccountingType.goods);
  });

  test('Transaction.fromShipyardTransaction', () {
    final shipyardTransaction = ShipyardTransaction(
      waypointSymbol: 'A-B-C',
      shipSymbol: 'S-1',
      shipType: ShipType.EXPLORER.value,
      price: 100,
      agentSymbol: 'A',
      timestamp: DateTime(2021),
    );
    final transaction = Transaction.fromShipyardTransaction(
      shipyardTransaction,
      100,
      const ShipSymbol('A', 1),
    );
    expect(transaction.transactionType, TransactionType.shipyard);
    expect(transaction.waypointSymbol, WaypointSymbol.fromString('A-B-C'));
    expect(transaction.shipSymbol, const ShipSymbol('A', 1));
    expect(transaction.tradeSymbol, null);
    expect(transaction.shipType, ShipType.EXPLORER);
    expect(transaction.quantity, 1);
    expect(transaction.tradeType, MarketTransactionTypeEnum.PURCHASE);
    expect(transaction.perUnitPrice, 100);
    expect(transaction.timestamp, DateTime(2021));
    expect(transaction.agentCredits, 100);
    expect(transaction.accounting, AccountingType.capital);
  });

  test('Transaction.fromShipModificationTransaction', () {
    final shipModificationTransaction = ShipModificationTransaction(
      waypointSymbol: 'A-B-C',
      shipSymbol: 'S-1',
      tradeSymbol: ShipMountSymbolEnum.GAS_SIPHON_I.value,
      totalPrice: 100,
      timestamp: DateTime(2021),
    );
    final transaction = Transaction.fromShipModificationTransaction(
      shipModificationTransaction,
      100,
    );
    expect(transaction.transactionType, TransactionType.shipModification);
    expect(transaction.waypointSymbol, WaypointSymbol.fromString('A-B-C'));
    expect(transaction.shipSymbol, const ShipSymbol('S', 1));
    expect(transaction.tradeSymbol, TradeSymbol.MOUNT_GAS_SIPHON_I);
    expect(transaction.shipType, null);
    expect(transaction.quantity, 1);
    expect(transaction.tradeType, MarketTransactionTypeEnum.PURCHASE);
  });

  test('Transaction.fromConstructionDelivery', () {
    final delivery = ConstructionDelivery(
      unitsDelivered: 100,
      tradeSymbol: TradeSymbol.ADVANCED_CIRCUITRY,
      waypointSymbol: WaypointSymbol.fromString('A-B-C'),
      shipSymbol: const ShipSymbol('S', 1),
      timestamp: DateTime(2021),
    );
    final transaction = Transaction.fromConstructionDelivery(
      delivery,
      100,
    );
    expect(transaction.transactionType, TransactionType.construction);
    expect(transaction.waypointSymbol, WaypointSymbol.fromString('A-B-C'));
    expect(transaction.shipSymbol, const ShipSymbol('S', 1));
    expect(transaction.tradeSymbol, TradeSymbol.ADVANCED_CIRCUITRY);
    expect(transaction.shipType, null);
    expect(transaction.quantity, 100);
    expect(transaction.tradeType, null);
  });
}
