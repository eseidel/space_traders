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

  // We don't import info from cached shipyard ships into parts as
  // ShipyardShips only update when we visit a Shipyard, where as parts can
  // update from live ships (via this script).
  // If we saved dates with our static data we could be more sophisticated
  // and update based on data freshness.
}

void main(List<String> args) async {
  await runOffline(args, command);
}
