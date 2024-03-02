import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/printing.dart';
import 'package:collection/collection.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  // For a given destination, compute the time to travel there for each ship.
  final destination = WaypointSymbol.fromString(argResults.rest[0]);
  final ships = await ShipSnapshot.load(db);
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

  for (final ship in ships.ships) {
    final travelTime = travelTimeTo(ship, destination);
    travelTimes[ship.shipSymbol] = travelTime;
  }

  final sortedShips =
      ships.ships.sortedBy<Duration>((s) => travelTimes[s.shipSymbol]!);
  for (final ship in sortedShips) {
    final travelTime = travelTimes[ship.shipSymbol]!;
    logger.info('${ship.shipSymbol.hexNumber.padRight(3)} '
        '${approximateDuration(travelTime).padLeft(3)}');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
