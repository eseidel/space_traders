import 'dart:convert';

import 'package:cli/cache/ship_snapshot.dart';
import 'package:cli/cache/static_cache.dart';
import 'package:cli/cli.dart';
import 'package:cli/plan/ships.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final ships = await ShipSnapshot.load(db);
  final staticCaches = StaticCaches.load(fs);

  // Import all info from our current ships.
  for (final ship in ships.ships) {
    recordShip(staticCaches, ship);
  }

  // We don't import info from cached shipyard ships into parts as
  // ShipyardShips only update when we visit a Shipyard, where as parts can
  // update from live ships (via this script).
  // If we saved dates with our static data we could be more sophisticated
  // and update based on data freshness.

  // However we will update our shipyard cache with the parts from our active
  // ships, for parts which we know are not yet changeable.
  for (final ship in ships.ships) {
    final shipType =
        staticCaches.shipyardShips.shipTypeFromFrame(ship.frame.symbol);
    if (shipType == null) {
      continue;
    }
    final shipyardShip = staticCaches.shipyardShips[shipType];
    if (shipyardShip == null) {
      continue;
    }
    final copy =
        ShipyardShip.fromJson(jsonDecode(jsonEncode(shipyardShip.toJson())))!
          ..engine = staticCaches.engines.copyAndNormalize(ship.engine)
          // We don't have a ship frame cache it seems?
          ..frame = ship.frame
          ..modules =
              ship.modules.map(staticCaches.modules.copyAndNormalize).toList()
          // Mounts on the shipyardShip might be stale, use ones from cache.
          ..mounts = shipyardShip.mounts
              .map((ShipMount m) => staticCaches.mounts[m.symbol]!)
              .toList();
    recordShipyardShips(staticCaches, [copy]);
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
