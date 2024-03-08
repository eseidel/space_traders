import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/nav/warp_pathing.dart';

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

  final shipyardShips = ShipyardShipCache.load(fs);
  final ship = shipyardShips[shipType]!;
  final shipSpec = ship.shipSpec;

  final start = agentCache!.headquartersSymbol;
  final interestingSystems = findInterestingSystems(systemsCache);
  final interestingWaypoints = interestingSystems
      .map((s) => systemsCache[s].jumpGateWaypoints.first.symbol)
      .toList();

  logger.info('Pathing to ${interestingWaypoints.length} systems...');
  for (final end in interestingWaypoints) {
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
