import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/nav/warp_pathing.dart';
import 'package:collection/collection.dart';

void main(List<String> args) async {
  await runOffline(args, command);
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  const shipType = ShipType.EXPLORER;

  final agentCache = await AgentCache.load(db);
  final systemsCache = SystemsCache.load(fs)!;
  final marketListings = await MarketListingSnapshot.load(db);
  final sellsFuel = defaultSellsFuel(marketListings);

  final systemConnectivity = await loadSystemConnectivity(db);
  // final routePlanner = RoutePlanner.fromSystemsCache(
  //   systemsCache,
  //   systemConnectivity,
  //   sellsFuel: sellsFuel,
  // );

  final shipyardShips = ShipyardShipCache.load(fs);
  final ship = shipyardShips[shipType]!;
  final shipSpec = ship.shipSpec;

  final start = agentCache!.headquartersSymbol;
  final interestingSystems = findInterestingSystems(systemsCache);
  final interestingWaypoints = interestingSystems
      .map((s) => systemsCache[s].jumpGateWaypoints.first.symbol)
      .toList();

  // Sort them by distance to start, do the easy ones first.
  final startSystem = systemsCache[start.system];
  interestingWaypoints
      .sortBy<num>((s) => systemsCache[s.system].distanceTo(startSystem));

  logger.info('Pathing to ${interestingWaypoints.length} systems...');
  for (final end in interestingWaypoints) {
    final systemDistance = systemsCache[end.system].distanceTo(startSystem);
    logger.info('Pathing to $end ($systemDistance)...');
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
    if (actions == null) {
      logger.err('No route found (${duration.inMilliseconds}ms)');
    } else {
      final plan = RoutePlan(
        actions: actions,
        fuelCapacity: shipSpec.fuelCapacity,
        shipSpeed: shipSpec.speed,
      );
      logger
        ..info('Route found (${duration.inMilliseconds}ms)')
        ..info(describeRoutePlan(plan));
    }
  }
}
