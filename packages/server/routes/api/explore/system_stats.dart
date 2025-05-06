import 'package:cli/caches.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:db/db.dart';
import 'package:protocol/protocol.dart';
import 'package:server/read_async.dart';
import 'package:types/types.dart';

/// Compute system stats from our caches starting from a given system.
Future<SystemStats> computeSystemStats({
  required Database db,
  required SystemSymbol startSystemSymbol,
}) async {
  final systemsCache = await db.snapshotAllSystems();
  // Can't use loadSystemConnectivity because need jumpGateSnapshot later.
  final jumpGateSnapshot = await JumpGateSnapshot.load(db);
  final constructionSnapshot = await ConstructionSnapshot.load(db);
  final systemConnectivity = SystemConnectivity.fromJumpGates(
    jumpGateSnapshot,
    constructionSnapshot,
  );

  var totalSystems = 0;
  var totalJumpgates = 0;
  var totalWaypoints = 0;
  for (final system in systemsCache.records) {
    totalSystems += 1;
    totalWaypoints += system.waypointSymbols.length;
    totalJumpgates += systemsCache.hasJumpGate(system.symbol) ? 1 : 0;
  }

  final reachableSystems =
      systemConnectivity.systemsReachableFrom(startSystemSymbol).toSet();

  var jumpGates = 0;
  var asteroids = 0;
  var waypointCount = 0;
  for (final systemSymbol in reachableSystems) {
    final systemRecord = systemsCache.systemBySymbol(systemSymbol);
    waypointCount += systemRecord.waypoints.length;
    jumpGates += systemRecord.jumpGateWaypoints.length;
    asteroids += systemRecord.waypoints.where((w) => w.isAsteroid).length;
  }

  // How many waypoints are charted?
  final chartingSnapshot = await ChartingSnapshot.load(db);
  var chartedWaypoints = 0;
  var chartedAsteroids = 0;
  var chartedJumpGates = 0;
  for (final record in chartingSnapshot.records) {
    if (!record.isCharted) {
      continue;
    }
    // We could sort first by system to save ourselves some lookups.
    final systemSymbol = record.waypointSymbol.system;
    if (!reachableSystems.contains(systemSymbol)) {
      continue;
    }
    chartedWaypoints += 1;
    final waypoint = systemsCache.waypoint(record.waypointSymbol);
    if (waypoint.isJumpGate) {
      chartedJumpGates += 1;
    }
    if (waypoint.isAsteroid) {
      chartedAsteroids += 1;
    }
  }

  // How many markets?
  final marketListings = await MarketListingSnapshot.load(db);
  var markets = 0;
  for (final listing in marketListings.listings) {
    // We could sort first by system to save ourselves some lookups.
    final systemSymbol = listing.waypointSymbol.system;
    if (reachableSystems.contains(systemSymbol)) {
      markets += 1;
    }
  }

  // How many shipyards?
  final shipyardListings = await ShipyardListingSnapshot.load(db);
  var shipyards = 0;
  for (final listing in shipyardListings.listings) {
    // We could sort first by system to save ourselves some lookups.
    final systemSymbol = listing.waypointSymbol.system;
    if (reachableSystems.contains(systemSymbol)) {
      shipyards += 1;
    }
  }

  // How many are cached?
  var cachedJumpGates = 0;
  for (final record in jumpGateSnapshot.values) {
    // We could sort first by system to save ourselves some lookups.
    final systemSymbol = record.waypointSymbol.system;
    if (reachableSystems.contains(systemSymbol)) {
      cachedJumpGates += 1;
    }
  }

  // How many blocked connections?
  // To how many unique blocked endpoints?

  return SystemStats(
    startSystem: startSystemSymbol,
    totalJumpgates: totalJumpgates,
    totalSystems: totalSystems,
    totalWaypoints: totalWaypoints,
    reachableSystems: reachableSystems.length,
    reachableWaypoints: waypointCount,
    reachableMarkets: markets,
    reachableShipyards: shipyards,
    reachableAsteroids: asteroids,
    reachableJumpGates: jumpGates,
    cachedJumpGates: cachedJumpGates,
    chartedWaypoints: chartedWaypoints,
    chartedAsteroids: chartedAsteroids,
    chartedJumpGates: chartedJumpGates,
  );
}

Future<Response> onRequest(RequestContext context) async {
  final db = await context.readAsync<Database>();

  final agentCache = await AgentCache.load(db);
  final stats = await computeSystemStats(
    db: db,
    startSystemSymbol: agentCache!.headquartersSymbol.system,
  );

  return Response.json(body: stats.toJson());
}
