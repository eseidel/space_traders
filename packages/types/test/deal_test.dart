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
            duration: 10,
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
}
