import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:collection/collection.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final knownHomeSystemSymbols = [
    'X1-TV94',
    'X1-XX13',
    'X1-CJ63',
    'X1-JN91',
    'X1-HY21',
    'X1-AY51',
    'X1-GB33',
    'X1-TN62',
    'X1-HV90',
    'X1-CU29',
  ].map(SystemSymbol.fromString).toSet();
  final systemsCache = SystemsCache.load(fs)!;

  // Compare # of waypoints of home systems vs. average?
  // Compare # of asteroids of home systems vs. average?

  final homeSystems =
      knownHomeSystemSymbols.map((symbol) => systemsCache[symbol]).toList();
  final homeSystemAsteroidCounts = homeSystems
      .map((system) => system.waypoints.where((w) => w.isAsteroid).length)
      .toList();
  logger.info('Home system asteroid counts: $homeSystemAsteroidCounts');
  final homeSystemWaypointCounts =
      homeSystems.map((system) => system.waypoints.length).toList();
  logger.info('Home system waypoint counts: $homeSystemWaypointCounts');

  /// Non-asteroid counts for home systems:
  final homeSystemNonAsteroidCounts = homeSystems
      .map((system) => system.waypoints.where((w) => !w.isAsteroid).length)
      .toList();
  logger.info('Home system non-asteroid counts: $homeSystemNonAsteroidCounts');

  final allSystems = systemsCache.systems;
  final allSystemsAvgAsteroidCount = allSystems
      .map((system) => system.waypoints.where((w) => w.isAsteroid).length)
      .average;
  logger
      .info('All systems average asteroid count: $allSystemsAvgAsteroidCount');
  final allSystemsAvgWaypointCount =
      allSystems.map((system) => system.waypoints.length).average;
  logger
      .info('All systems average waypoint count: $allSystemsAvgWaypointCount');

  // All systems with over 50 asteroids:
  final asteroidSystems = allSystems
      .where(
        (system) => system.waypoints.where((w) => w.isAsteroid).length > 50,
      )
      .toList();
  logger.info('Asteroid systems: ${asteroidSystems.length}');
  // All systems with over 50 waypoints:
  final waypointSystems = allSystems
      .where(
        (system) => system.waypoints.length > 80,
      )
      .toList();
  logger.info('Waypoint systems: ${waypointSystems.length}');

  // All systems with over 25 non-asteroid waypoints:
  final nonAsteroidSystems = allSystems
      .where(
        (system) => system.waypoints.where((w) => !w.isAsteroid).length > 20,
      )
      .toList();
  logger.info('Non-asteroid systems: ${nonAsteroidSystems.length}');
}

void main(List<String> args) async {
  await runOffline(args, command);
}
