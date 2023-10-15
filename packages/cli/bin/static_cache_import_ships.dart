import 'package:cli/cache/ship_cache.dart';
import 'package:cli/cache/static_cache.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final shipCache = ShipCache.loadCached(fs)!;
  final staticCaches = StaticCaches.load(fs);

  // Import all info from our current ships.
  for (final ship in shipCache.ships) {
    staticCaches.mounts.addAll(ship.mounts);
    staticCaches.modules.addAll(ship.modules);
    staticCaches.engines.add(ship.engine);
    staticCaches.reactors.add(ship.reactor);
  }

  // Import all info from cached shipyard ships (which for whatever reason
  // didn't import into parts caches earlier).  This is likely no longer
  // needed, was only added during bringup of the static_data caches.
  for (final ship in staticCaches.shipyardShips.values) {
    staticCaches.mounts.addAll(ship.mounts);
    staticCaches.modules.addAll(ship.modules);
    staticCaches.engines.add(ship.engine);
    staticCaches.reactors.add(ship.reactor);
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
