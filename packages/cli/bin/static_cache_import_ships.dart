import 'package:cli/cli.dart';
import 'package:cli/plan/ships.dart';

Future<void> command(Database db, ArgResults argResults) async {
  final ships = await ShipSnapshot.load(db);

  // Import all info from our current ships.
  for (final ship in ships.ships) {
    recordShip(db, ship);
  }

  // We don't import info from cached shipyard ships into parts as
  // ShipyardShips only update when we visit a Shipyard, where as parts can
  // update from live ships (via this script).
  // If we saved dates with our static data we could be more sophisticated
  // and update based on data freshness.

  final engines = await db.shipEngines.snapshot();
  final modules = await db.shipModules.snapshot();
  final mounts = await db.shipMounts.snapshot();
  final shipyardShips = await db.shipyardShips.snapshot();

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
    recordShipyardShips(db, [copy]);
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
