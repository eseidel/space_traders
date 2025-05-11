import 'package:cli/api.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/queries.dart';
import 'package:db/db.dart';

// Checks our db to see if we already have all the systems in the game
// cached, if not starts to walk through them until they're cached.

/// Fetches all systems from the API and caches them in the database.
class SystemsFetcher {
  /// Creates a new [SystemsFetcher] instance.
  SystemsFetcher(this._db, this._api);

  final Api _api;
  final Database _db;

  /// Ensures all systems are cached in the database.
  Future<void> ensureAllSystemsCached() async {
    // First we ask the API how many systems there are.
    final galaxy = await getGalaxyStats(_api);

    // Ask the db how many systems it has.
    final cachedSystemCount = await _db.systems.countSystemRecords();
    final cachedWaypointsCount = await _db.systems.countSystemWaypoints();
    if (cachedSystemCount >= galaxy.systemCount &&
        cachedWaypointsCount >= galaxy.waypointCount) {
      logger.info('All systems and waypoints are cached, skipping fetch.');
      return;
    }

    final missingSystems = galaxy.systemCount - cachedSystemCount;
    final missingWaypoints = galaxy.waypointCount - cachedWaypointsCount;
    logger.info(
      'Missing $missingSystems systems and $missingWaypoints waypoints.',
    );

    // Otherwise we start the process of fetching systems.
    const logEvery = 1000;
    var i = 0;
    await allSystems(_api).forEach((system) {
      _db.systems.upsertSystem(system);
      if (i % logEvery == 0) {
        logger.info('Fetched $i systems');
      }
      i++;
    });

    // Confirm we've cached them all.
    final afterMissingSystems =
        galaxy.systemCount - await _db.systems.countSystemRecords();
    final afterMissingWaypoints =
        galaxy.waypointCount - await _db.systems.countSystemWaypoints();
    if (afterMissingSystems > 0) {
      logger.err('Still missing $afterMissingSystems systems');
    }
    if (afterMissingWaypoints > 0) {
      logger.err('Still missing $afterMissingWaypoints waypoints');
    }
  }
}
