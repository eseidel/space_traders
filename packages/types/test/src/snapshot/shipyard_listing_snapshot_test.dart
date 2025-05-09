import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  group('ShipyardListingSnapshot', () {
    test('withShip', () {
      final snapshot = ShipyardListingSnapshot([
        ShipyardListing(
          waypointSymbol: WaypointSymbol.fromString('A-B-C'),
          shipTypes: const {ShipType.ORE_HOUND},
        ),
      ]);
      expect(snapshot.withShip(ShipType.ORE_HOUND).length, 1);
    });

    test('knowOfShipyardWithShip', () {
      final snapshot = ShipyardListingSnapshot([
        ShipyardListing(
          waypointSymbol: WaypointSymbol.fromString('A-B-C'),
          shipTypes: const {ShipType.ORE_HOUND},
        ),
      ]);
      expect(snapshot.knowOfShipyardWithShip(ShipType.ORE_HOUND), isTrue);
      expect(
        snapshot.knowOfShipyardWithShip(ShipType.COMMAND_FRIGATE),
        isFalse,
      );
    });

    test('at', () {
      final waypointSymbol = WaypointSymbol.fromString('A-B-C');
      final snapshot = ShipyardListingSnapshot([
        ShipyardListing(
          waypointSymbol: waypointSymbol,
          shipTypes: const {ShipType.ORE_HOUND},
        ),
      ]);
      expect(snapshot.at(waypointSymbol), isNotNull);
      expect(snapshot[waypointSymbol], isNotNull);
      expect(snapshot.at(WaypointSymbol.fromString('A-B-D')), isNull);
    });

    test('inSystem', () {
      final snapshot = ShipyardListingSnapshot([
        ShipyardListing(
          waypointSymbol: WaypointSymbol.fromString('A-B-C'),
          shipTypes: const {ShipType.ORE_HOUND},
        ),
      ]);
      expect(snapshot.inSystem(SystemSymbol.fromString('A-B')).length, 1);
    });

    test('countInSystem', () {
      final snapshot = ShipyardListingSnapshot([
        ShipyardListing(
          waypointSymbol: WaypointSymbol.fromString('A-B-C'),
          shipTypes: const {ShipType.ORE_HOUND},
        ),
      ]);
      expect(snapshot.countInSystem(SystemSymbol.fromString('A-B')), 1);
    });
  });
}
