import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/nav/warp_pathing.dart';
import 'package:collection/collection.dart';

void main(List<String> args) async {
  await runOffline(
    args,
    command,
    addArgs: (parser) {
      // Timing is an option to allow for stable output for testing.
      parser.addFlag(
        'timing',
        abbr: 't',
        help: 'Show timings for each pathing operation',
      );
    },
  );
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  const shipType = ShipType.EXPLORER;
  final timing = argResults['timing'] as bool;

  final agentCache = await AgentCache.load(db);
  final systemsCache = SystemsCache.load(fs);
  final marketListings = await MarketListingSnapshot.load(db);
  final sellsFuel = defaultSellsFuel(marketListings);
  // final sellsFuel = defaultFuel;
  // bool sellsFuel(WaypointSymbol symbol) {
  //   return true;
  //   // if (defaultFuel(symbol) == true) return true;
  //   // final type = systemsCache.waypoint(symbol).type;
  //   // // Based on bin/markets_by_waypoint_type.dart
  //   // final sellsFuelTypes = [
  //   //   WaypointType.ASTEROID_BASE,
  //   //   WaypointType.ENGINEERED_ASTEROID,
  //   //   WaypointType.FUEL_STATION,
  //   //   WaypointType.JUMP_GATE,
  //   //   WaypointType.ORBITAL_STATION,
  //   // ];
  //   // return sellsFuelTypes.contains(type);
  // }

  final systemConnectivity = await loadSystemConnectivity(db);
  // final routePlanner = RoutePlanner.fromSystemsCache(
  //   systemsCache,
  //   systemConnectivity,
  //   sellsFuel: sellsFuel,
  // );

  final shipyardShips = ShipyardShipCache(db);
  final ship = await shipyardShips.get(shipType);
  final shipSpec = ship!.shipSpec;

  final start = agentCache!.headquartersSymbol;
  final interestingSystems = findInterestingSystems(systemsCache);
  final interestingWaypoints =
      interestingSystems
          .map((s) => systemsCache[s].jumpGateWaypoints.first.symbol)
          .toList();

  // Sort them by distance to start, do the easy ones first.
  final startSystem = systemsCache[start.system];
  interestingWaypoints.sortBy<num>(
    (s) => systemsCache[s.system].distanceTo(startSystem),
  );

  logger.info('Pathing to ${interestingWaypoints.length} systems...');
  for (final end in interestingWaypoints) {
    final systemDistance = systemsCache[end.system].distanceTo(startSystem);
    final distanceString = systemDistance.toStringAsFixed(2);
    logger.info('Pathing to $end ($distanceString)...');
    final routeStart = DateTime.timestamp();
    final actions = findRouteBetweenSystems(
      systemsCache,
      systemConnectivity,
      shipSpec,
      start: start,
      end: end,
      sellsFuel: sellsFuel,
    );
    final routeEnd = DateTime.timestamp();
    final duration = routeEnd.difference(routeStart);
    final timingString = timing ? ' (${duration.inMilliseconds}ms)' : '';
    if (actions == null) {
      logger.info('No route found$timingString');
    } else {
      final plan = RoutePlan(
        actions: actions,
        fuelCapacity: shipSpec.fuelCapacity,
        shipSpeed: shipSpec.speed,
      );
      logger
        ..info('Route found$timingString')
        ..info(describeRoutePlan(plan));
    }
  }
}
