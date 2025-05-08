import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli_table/cli_table.dart';
import 'package:collection/collection.dart';

Future<void> command(Database db, ArgResults argResults) async {
  // Evaluate the navigability of the starting system by ship type.
  // For each waypoint, print the time to reach said waypoint for a given
  // ship class.

  final systems = await db.systems.snapshotAllSystems();
  final hqSystemSymbol = await myHqSystemSymbol(db);
  final shipyardListings = await ShipyardListingSnapshot.load(db);
  final systemConnectivity = await loadSystemConnectivity(db);
  final routePlanner = RoutePlanner.fromSystemsSnapshot(
    systems,
    systemConnectivity,
    sellsFuel: await defaultSellsFuel(db),
  );
  final waypoints = systems.waypointsInSystem(hqSystemSymbol);
  final shipyardListing =
      shipyardListings.listingsInSystem(hqSystemSymbol).first;
  final shipyard = systems.waypoint(shipyardListing.waypointSymbol);

  const shipType = ShipType.LIGHT_HAULER;
  final shipyardShips = ShipyardShipCache(db);
  final ship = await shipyardShips.get(shipType);
  logger.info('Routes from ${shipyard.symbol} with $shipType');

  final table = Table(
    header: ['Waypoint', 'Distance', 'Time', 'Actions'],
    style: const TableStyle(compact: true),
  );

  for (final waypoint in waypoints) {
    final routePlan = routePlanner.planRoute(
      ship!.shipSpec,
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
}

void main(List<String> args) async {
  await runOffline(args, command);
}
