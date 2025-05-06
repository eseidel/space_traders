import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/navigation.dart';
import 'package:collection/collection.dart';

Future<void> command(Database db, ArgResults argResults) async {
  // For a given destination, compute the time to travel there for each ship.
  final destination = WaypointSymbol.fromString(argResults.rest[0]);
  final ships = await ShipSnapshot.load(db);
  final systemsCache = await db.systems.snapshotAllSystems();
  final marketListings = await MarketListingSnapshot.load(db);

  final systemConnectivity = await loadSystemConnectivity(db);
  final routePlanner = RoutePlanner.fromSystemsSnapshot(
    systemsCache,
    systemConnectivity,
    sellsFuel: defaultSellsFuel(marketListings),
  );

  final travelTimes = <ShipSymbol, Duration>{};

  for (final ship in ships.ships) {
    final travelTime = travelTimeTo(routePlanner, ship, destination);
    travelTimes[ship.symbol] = travelTime;
  }

  final sortedShips = ships.ships.sortedBy<Duration>(
    (s) => travelTimes[s.symbol]!,
  );
  for (final ship in sortedShips) {
    final travelTime = travelTimes[ship.symbol]!;
    logger.info(
      '${ship.symbol.hexNumber.padRight(3)} '
      '${approximateDuration(travelTime).padLeft(3)}',
    );
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
