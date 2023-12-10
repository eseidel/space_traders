import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/printing.dart';
import 'package:collection/collection.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  // For a given destination, compute the time to travel there for each ship.
  final destination = WaypointSymbol.fromString(argResults.rest[0]);
  final shipCache = ShipCache.load(fs)!;
  final systemsCache = SystemsCache.load(fs)!;
  final staticCaches = StaticCaches.load(fs);
  final marketListings = MarketListingCache.load(fs, staticCaches.tradeGoods);

  final jumpGateCache = JumpGateCache.load(fs);
  final constructionCache = ConstructionCache.load(fs);
  final routePlanner = RoutePlanner.fromCaches(
    systemsCache,
    jumpGateCache,
    constructionCache,
    sellsFuel: defaultSellsFuel(marketListings),
  );

  Duration travelTimeTo(Ship ship, WaypointSymbol waypoint) {
    final route = routePlanner.planRoute(
      start: ship.waypointSymbol,
      end: waypoint,
      fuelCapacity: ship.frame.fuelCapacity,
      shipSpeed: ship.engine.speed,
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
}

void main(List<String> args) async {
  await runOffline(args, command);
}
