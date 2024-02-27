import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/ships.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final startSymbol =
      await startWaypointFromArg(db, argResults.rest.firstOrNull);
  final staticCaches = StaticCaches.load(fs);
  final systemsCache = SystemsCache.load(fs)!;
  final charting = ChartingCache(db);
  final construction = ConstructionCache(db);
  final waypointCache = WaypointCache.cachedOnly(
    systemsCache,
    charting,
    construction,
    staticCaches.waypointTraits,
  );
  final systemConnectivity = await loadSystemConnectivity(db);

  final ships = await ShipSnapshot.load(db);
  final centralCommand = CentralCommand();

  final origin = systemsCache.waypoint(startSymbol);
  final ship = staticCaches.shipyardShips.shipForTest(
    ShipType.PROBE,
    origin: origin,
  )!;
  const maxJumps = 5;
  final behaviors = await BehaviorSnapshot.load(db);
  final destinationSymbol = await centralCommand.nextWaypointToChart(
    ships,
    behaviors,
    systemsCache,
    waypointCache,
    systemConnectivity,
    ship,
    maxJumps: maxJumps,
  );
  if (destinationSymbol == null) {
    logger.info('No uncharted waypoints found within $maxJumps jumps.');
  } else {
    logger.info('Next uncharted waypoint: $destinationSymbol');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
