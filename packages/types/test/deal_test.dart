import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('Deal JSON roundtrip', () {
    final deal = Deal.test(
      sourceSymbol: WaypointSymbol.fromString('S-A-B'),
      destinationSymbol: WaypointSymbol.fromString('S-A-C'),
      tradeSymbol: TradeSymbol.FUEL,
      purchasePrice: 1,
      sellPrice: 2,
    );
    final json = deal.toJson();
    final deal2 = Deal.fromJson(json);
    final json2 = deal2.toJson();
    expect(deal, deal2);
    expect(deal.hashCode, deal2.hashCode);
    expect(json, json2);
  });

  test('CostedDeal JSON roundtrip', () {
    final start = WaypointSymbol.fromString('S-A-B');
    final end = WaypointSymbol.fromString('S-A-C');
    final deal = Deal.test(
      sourceSymbol: start,
      destinationSymbol: end,
      tradeSymbol: TradeSymbol.FUEL,
      purchasePrice: 1,
      sellPrice: 2,
    );
    final costed = CostedDeal(
      deal: deal,
      cargoSize: 1,
      transactions: [],
      startTime: DateTime(2021),
      route: RoutePlan(
        actions: [
          RouteAction(
            startSymbol: start,
            endSymbol: end,
            type: RouteActionType.navCruise,
            seconds: 10,
            fuelUsed: 10,
          ),
        ],
        fuelCapacity: 10,
        fuelUsed: 10,
        shipSpeed: 10,
      ),
      costPerFuelUnit: 100,
    );

    final json = costed.toJson();
    final costed2 = CostedDeal.fromJson(json);
    final json2 = costed2.toJson();
    // Can't compare objects via equals because CostedDeal is not immutable.
    expect(json, json2);
  });

  test('byAddingTransactions', () {
    final start = WaypointSymbol.fromString('S-A-B');
    final end = WaypointSymbol.fromString('S-A-C');
    final deal = Deal.test(
      sourceSymbol: start,
      destinationSymbol: end,
      tradeSymbol: TradeSymbol.FUEL,
      purchasePrice: 1,
      sellPrice: 2,
    );
    final costed = CostedDeal(
      deal: deal,
      cargoSize: 1,
      transactions: [],
      startTime: DateTime(2021),
      route: RoutePlan(
        actions: [
          RouteAction(
            startSymbol: start,
            endSymbol: end,
            type: RouteActionType.navCruise,
            seconds: 10,
            fuelUsed: 10,
          ),
        ],
        fuelCapacity: 10,
        fuelUsed: 10,
        shipSpeed: 10,
      ),
      costPerFuelUnit: 100,
    );
    const shipSymbol = ShipSymbol('S', 1);
    final transaction1 = Transaction(
      transactionType: TransactionType.market,
      shipSymbol: shipSymbol,
      waypointSymbol: start,
      tradeSymbol: TradeSymbol.FUEL,
      shipType: null,
      perUnitPrice: 10,
      tradeType: MarketTransactionTypeEnum.PURCHASE,
      quantity: 1,
      timestamp: DateTime(2021),
      agentCredits: 10,
      accounting: AccountingType.fuel,
      contractAction: null,
      contractId: null,
    );
    final transaction2 = Transaction(
      transactionType: TransactionType.market,
      shipSymbol: shipSymbol,
      waypointSymbol: end,
      tradeSymbol: TradeSymbol.FUEL,
      shipType: null,
      perUnitPrice: 10,
      tradeType: MarketTransactionTypeEnum.SELL,
      quantity: 1,
      timestamp: DateTime(2021),
      agentCredits: 10,
      accounting: AccountingType.fuel,
      contractAction: null,
      contractId: null,
    );
    final costed2 = costed.byAddingTransactions([transaction1]);
    expect(costed2.transactions, [transaction1]);
    final costed3 = costed2.byAddingTransactions([transaction2]);
    expect(costed3.transactions, [transaction1, transaction2]);
  });
}
