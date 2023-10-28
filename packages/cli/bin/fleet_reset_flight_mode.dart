import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/net/auth.dart';

Future<void> main(List<String> args) async {
  await runOffline(args, command);
}

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final api = defaultApi(fs, db, getPriority: () => 0);
  final shipCache = ShipCache.loadCached(fs)!;
  final ships = shipCache.ships;
  for (final ship in ships) {
    final flightMode = ship.nav.flightMode;
    if (flightMode == ShipNavFlightMode.CRUISE) {
      continue;
    }
    if (ship.nav.status == ShipNavStatus.IN_TRANSIT) {
      shipWarn(ship, 'flightMode = $flightMode, but in transit, skipping.');
      continue;
    }
    await api.fleet.patchShipNav(
      ship.symbol,
      patchShipNavRequest:
          PatchShipNavRequest(flightMode: ShipNavFlightMode.CRUISE),
    );
  }
  // Required or main() will hang.
  await db.close();
}
