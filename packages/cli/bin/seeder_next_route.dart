import 'package:cli/behavior/seeder.dart';
import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/navigation.dart';

void main(List<String> args) async {
  await runOffline(args, command);
}

Future<void> command(Database db, ArgResults argResults) async {
  final agentCache = await AgentCache.load(db);
  final marketListings = await MarketListingSnapshot.load(db);

  final systemsCache = await db.systems.snapshot();
  final ships = await ShipSnapshot.load(db);

  // Find ones not in our main cluster.
  final systemConnectivity = await loadSystemConnectivity(db);
  final routePlanner = RoutePlanner.fromSystemsSnapshot(
    systemsCache,
    systemConnectivity,
    sellsFuel: defaultSellsFuel(marketListings),
  );

  final explorer = ships.ships.firstWhere((s) => s.isExplorer);
  final behaviors = await BehaviorSnapshot.load(db);

  final route = await routeToNextSystemToSeed(
    agentCache!,
    ships,
    behaviors,
    systemsCache,
    routePlanner,
    systemConnectivity,
    explorer,
  );
  if (route == null) {
    logger.info('No route found.');
    return;
  }
  logger.info(describeRoutePlan(route));
}
