import 'package:protocol/src/messages/get_fleet/get_fleet_response.dart';
import 'package:test/test.dart';

void main() {
  test(GetFleetResponse, () {
    final response = GetFleetResponse(
      ships: [
        FleetShip(
          symbol: 'ship1',
          route: ShipRoutePlan(
            waypointSymbol: 'system1:waypoint1',
            timeToArrival: 100,
          ),
          cargo: Cargo(
            capacity: 1000,
            units: 1000,
            inventory: [
              PricedItem(
                symbol: 'item1',
                pricePerUnit: 1000,
                units: 1000,
                totalPrice: 1000,
              ),
            ],
          ),
        ),
      ],
    );
    final json = response.toJson();
    expect(json, isA<Map<String, dynamic>>());
    final response2 = GetFleetResponse.fromJson(json);
    expect(response2, equals(response));
  });
}
