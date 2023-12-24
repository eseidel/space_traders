import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/ships.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
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
  final agentCache = AgentCache.load(fs)!;
  final hqSymbol = agentCache.headquartersSymbol;
  final jumpGateCache = JumpGateCache.load(fs);
  final constructionSnapshot = await ConstructionSnapshot.load(db);
  final systemConnectivity =
      SystemConnectivity.fromJumpGates(jumpGateCache, constructionSnapshot);

  final shipCache = ShipCache.load(fs)!;
  final behaviorCache = BehaviorCache.load(fs);
  final centralCommand = CentralCommand(
    shipCache: shipCache,
    behaviorCache: behaviorCache,
  );

  final origin = systemsCache.waypoint(hqSymbol);
  final ship = staticCaches.shipyardShips.shipForTest(
    ShipType.PROBE,
    origin: origin,
  )!;
  const maxJumps = 5;
  final destinationSymbol = await centralCommand.nextWaypointToChart(
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

  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
