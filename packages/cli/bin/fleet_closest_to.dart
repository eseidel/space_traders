import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/printing.dart';
import 'package:collection/collection.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  // For a given destination, compute the time to travel there for each ship.
  final destination = WaypointSymbol.fromString(argResults.rest[0]);
  final shipCache = await ShipSnapshot.load(db);
  final systemsCache = SystemsCache.load(fs)!;
  final marketListings = await MarketListingSnapshot.load(db);

  final systemConnectivity = await loadSystemConnectivity(db);
  final routePlanner = RoutePlanner.fromSystemsCache(
    systemsCache,
    systemConnectivity,
    sellsFuel: defaultSellsFuel(marketListings),
  );

  // TODO(eseidel): This needs to be centralized somewhere.
  Duration travelTimeTo(Ship ship, WaypointSymbol waypoint) {
    final route = routePlanner.planRoute(
      ship.shipSpec,
      start: ship.waypointSymbol,
      end: waypoint,
    );
    final routeDuration = route!.duration;
    if (ship.isInTransit) {
      return routeDuration + ship.nav.route.timeUntilArrival();
    }
    return routeDuration;
  }

  final travelTimes = <ShipSymbol, Duration>{};

  for (final ship in shipCache.ships) {
    final travelTime = travelTimeTo(ship, destination);
    travelTimes[ship.shipSymbol] = travelTime;
  }

  final sortedShips =
      shipCache.ships.sortedBy<Duration>((s) => travelTimes[s.shipSymbol]!);
  for (final ship in sortedShips) {
    final travelTime = travelTimes[ship.shipSymbol]!;
    logger.info('${ship.shipSymbol.hexNumber.padRight(3)} '
        '${approximateDuration(travelTime).padLeft(3)}');
  }

  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
