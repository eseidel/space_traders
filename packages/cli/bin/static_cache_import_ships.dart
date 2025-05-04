import 'package:cli/cache/ship_snapshot.dart';
import 'package:cli/cache/static_cache.dart';
import 'package:cli/cli.dart';
import 'package:cli/plan/ships.dart';

Future<void> command(Database db, ArgResults argResults) async {
  final ships = await ShipSnapshot.load(db);
  final staticCaches = StaticCaches(db);

  // Import all info from our current ships.
  for (final ship in ships.ships) {
    recordShip(staticCaches, ship);
  }

  // We don't import info from cached shipyard ships into parts as
  // ShipyardShips only update when we visit a Shipyard, where as parts can
  // update from live ships (via this script).
  // If we saved dates with our static data we could be more sophisticated
  // and update based on data freshness.

  final engines = await staticCaches.engines.snapshot();
  final modules = await staticCaches.modules.snapshot();
  final mounts = await staticCaches.mounts.snapshot();
  final shipyardShips = await staticCaches.shipyardShips.snapshot();

  // However we will update our shipyard cache with the parts from our active
  // ships, for parts which we know are not yet changeable.
  for (final ship in ships.ships) {
    final shipType = shipyardShips.shipTypeFromFrame(ship.frame.symbol);
    if (shipType == null) {
      continue;
    }
    final shipyardShip = shipyardShips[shipType];
    if (shipyardShip == null) {
      continue;
    }
    final copy =
        shipyardShips.copyAndNormalize(shipyardShip)
          ..engine = engines.copyAndNormalize(ship.engine)
          // We don't have a ship frame cache it seems?
          ..frame = ship.frame
          ..modules = ship.modules.map(modules.copyAndNormalize).toList()
          // Mounts on the shipyardShip might be stale, use ones from cache.
          ..mounts = mounts.records.map((m) => mounts[m.symbol]!).toList();
    recordShipyardShips(staticCaches, [copy]);
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
