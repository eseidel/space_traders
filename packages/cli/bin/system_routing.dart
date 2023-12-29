import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/printing.dart';
import 'package:cli_table/cli_table.dart';
import 'package:collection/collection.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  // Evalute the navigability of the starting system by ship type.
  // For each waypoint, print the time to reach said waypoint for a given
  // ship class.

  final db = await defaultDatabase();
  final staticCaches = StaticCaches.load(fs);
  final systems = SystemsCache.load(fs)!;
  final agentCache = AgentCache.load(fs)!;
  final hqSystemSymbol = agentCache.headquartersSystemSymbol;
  final marketListings = MarketListingCache.load(fs, staticCaches.tradeGoods);
  final shipyardListings = ShipyardListingCache.load(fs);
  final jumpGateCache = JumpGateCache.load(fs);
  final constructionSnapshot = await ConstructionSnapshot.load(db);
  final systemConnectivity =
      SystemConnectivity.fromJumpGates(jumpGateCache, constructionSnapshot);
  final routePlanner = RoutePlanner.fromSystemsCache(
    systems,
    systemConnectivity,
    sellsFuel: defaultSellsFuel(marketListings),
  );
  final waypoints = systems.waypointsInSystem(hqSystemSymbol);
  final shipyardListing =
      shipyardListings.listingsInSystem(hqSystemSymbol).first;
  final shipyard = systems.waypoint(shipyardListing.waypointSymbol);

  const shipType = ShipType.LIGHT_HAULER;
  final ship = staticCaches.shipyardShips[shipType]!;
  logger.info('Routes from ${shipyard.symbol} with $shipType');

  final table = Table(
    header: ['Waypoint', 'Distance', 'Time', 'Actions'],
    style: const TableStyle(compact: true),
  );

  for (final waypoint in waypoints) {
    final routePlan = routePlanner.planRoute(
      ship.shipSpec,
      start: shipyard.symbol,
      end: waypoint.symbol,
    );
    final duration = routePlan?.duration;
    final durationString =
        duration != null ? approximateDuration(duration) : 'unreachable';
    final actions = routePlan?.actions.length ?? 0;
    final distance = shipyard.distanceTo(waypoint);
    table.add([waypoint.symbol, distance, durationString, actions]);
  }
  table.sortBy<num>((a) => (a as List<dynamic>)[1] as num);
  logger.info(table.toString());

  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
