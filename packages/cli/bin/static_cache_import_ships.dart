import 'package:cli/cache/ship_cache.dart';
import 'package:cli/cache/static_cache.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final shipCache = ShipCache.loadCached(fs)!;
  final staticCaches = StaticCaches.load(fs);

  // Import all info from our current ships.
  for (final ship in shipCache.ships) {
    recordShip(staticCaches, ship);
  }

  // Import all info from cached shipyard ships (which for whatever reason
  // didn't import into parts caches earlier).  This is likely no longer
  // needed, was only added during bringup of the static_data caches.
  recordShipyardShips(staticCaches, staticCaches.shipyardShips.values);
}

void main(List<String> args) async {
  await runOffline(args, command);
}
