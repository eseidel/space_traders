import 'package:protocol/src/messages/get_deals_nearby/get_deals_nearby_response.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('GetDealsNearbyResponse', () {
    // We need to use actual symbols because Deal requires start/end to
    // be different.
    final startSymbol = WaypointSymbol.fromString('A-B-1');
    final endSymbol = WaypointSymbol.fromString('A-B-2');
    const tradeSymbol = TradeSymbol.FUEL;
    final response = DealsNearbyResponse(
      shipType: ShipType.BULK_FREIGHTER,
      shipSpec: const ShipSpec(
        fuelCapacity: 1000,
        speed: 1000,
        canWarp: true,
        cargoCapacity: 1000,
      ),
      startSymbol: startSymbol,
      credits: 1000,
      extraSellOpps: const [],
      tradeSymbolCount: 1000,
      deals: [
        NearbyDeal(
          inProgress: true,
          costed: CostedDeal(
            transactions: const [],
            startTime: DateTime.now(),
            route: RoutePlan(
              fuelCapacity: 1000,
              shipSpeed: 1000,
              actions: const [],
            ),
            cargoSize: 1000,
            costPerFuelUnit: 1000,
            costPerAntimatterUnit: 1000,
            deal: Deal(
              source: BuyOpp(
                MarketPrice.test(
                  waypointSymbol: startSymbol,
                  symbol: tradeSymbol,
                ),
              ),
              destination: SellOpp.fromMarketPrice(
                MarketPrice.test(
                  waypointSymbol: endSymbol,
                  symbol: tradeSymbol,
                ),
              ),
            ),
          ),
        ),
      ],
    );
    final json = response.toJson();
    expect(json, isNotEmpty);
    final decoded = DealsNearbyResponse.fromJson(json);
    // We can't compare the entire response because some of the sub-objects
    // do not implement ==.
    expect(decoded.shipType, response.shipType);
  });
}
