import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/net/auth.dart';
import 'package:collection/collection.dart';

// List the 10 nearest systems which have 10+ markets and are not reachable
// via jumpgates from HQ.  Systems worth warping to should be charted already.
Future<void> command(Database db, ArgResults argResults) async {
  const limit = 10;
  const desiredMarketCount = 10;
  const shipType = ShipType.EXPLORER;

  final api = await defaultApi(db, getPriority: () => networkPriorityLow);

  final startSystemSymbol = await myHqSystemSymbol(db);

  final jumpGateSnapshot = await JumpGateSnapshot.load(db);
  final constructionCache = ConstructionCache(db);
  final systemConnectivity = SystemConnectivity.fromJumpGates(
    jumpGateSnapshot,
    await constructionCache.snapshot(),
  );
  final systemsCache = await db.snapshotAllSystems();
  final waypointCache = WaypointCache(api, db);
  final shipyardShips = ShipyardShipCache(db);

  final reachableSystemSymbols =
      systemConnectivity.systemsReachableFrom(startSystemSymbol).toSet();
  final startSystem = systemsCache.systemRecordBySymbol(startSystemSymbol);

  // List out systems by warp distance from HQ.
  // Filter out ones we know how to reach.
  final systemsByDistance = systemsCache.records
      .sortedBy<num>((s) => s.distanceTo(startSystem))
      .where((s) => !reachableSystemSymbols.contains(s.symbol));

  final systemsToWarpTo = <SystemRecord>[];
  for (final system in systemsByDistance) {
    if (systemsToWarpTo.length >= limit) {
      break;
    }
    final waypoints = await waypointCache.waypointsInSystem(system.symbol);
    final marketCount = waypoints.where((w) => w.hasMarketplace).length;
    if (marketCount < desiredMarketCount) {
      continue;
    }
    systemsToWarpTo.add(system);
  }

  logger.info(
    '$limit closest systems with $desiredMarketCount markets '
    'from $startSystemSymbol',
  );
  final shipSpeed = (await shipyardShips.get(shipType))!.engine.speed;
  for (final system in systemsToWarpTo) {
    final distance = system.distanceTo(startSystem);
    final seconds = warpTimeInSeconds(
      startSystem,
      system,
      shipSpeed: shipSpeed,
    );
    final timeString = approximateDuration(Duration(seconds: seconds));
    logger.info(' ${system.symbol} $distance in $timeString');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
