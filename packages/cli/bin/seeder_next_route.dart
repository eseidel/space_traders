import 'package:cli/behavior/seeder.dart';
import 'package:cli/cli.dart';

void main(List<String> args) async {
  await runOffline(args, command);
}

Future<void> command(Database db, ArgResults argResults) async {
  final agent = await db.getMyAgent();

  final systemsCache = await db.systems.snapshotAllSystems();
  final ships = await ShipSnapshot.load(db);

  // Find ones not in our main cluster.
  final routePlanner = await defaultRoutePlanner(db);

  final explorer = ships.ships.firstWhere((s) => s.isExplorer);
  final behaviors = await BehaviorSnapshot.load(db);

  final route = await routeToNextSystemToSeed(
    agent!,
    ships,
    behaviors,
    systemsCache,
    routePlanner,
    explorer,
  );
  if (route == null) {
    logger.info('No route found.');
    return;
  }
  logger.info(describeRoutePlan(route));
}
