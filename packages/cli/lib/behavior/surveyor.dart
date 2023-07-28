import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';

/// For dedicated survey ships.
Future<DateTime?> advanceSurveyor(
  Api api,
  CentralCommand centralCommand,
  Caches caches,
  BehaviorState state,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final currentWaypoint = await caches.waypoints.waypoint(ship.waypointSymbol);

  final mineSymbol =
      centralCommand.mineSymbolForShip(caches.systems, caches.agent, ship);
  if (mineSymbol == null) {
    centralCommand.disableBehaviorForShip(
      ship,
      'No desired mine for ship.',
      const Duration(hours: 1),
    );
    return null;
  }
  if (ship.waypointSymbol != mineSymbol) {
    return beingNewRouteAndLog(
      api,
      ship,
      caches.ships,
      caches.systems,
      caches.routePlanner,
      centralCommand,
      mineSymbol,
    );
  }
  jobAssert(
    currentWaypoint.canBeMined,
    'Must be at a mineable waypoint.',
    const Duration(minutes: 10),
  );
  jobAssert(
    ship.hasSurveyor,
    'Must have a surveyor.',
    const Duration(hours: 1),
  );

  // Surveying requires being undocked.
  await undockIfNeeded(api, caches.ships, ship);

  final outer = await api.fleet.createSurvey(ship.symbol);
  final response = outer!.data;
  // shipDetail(ship, '🔭 ${ship.waypointSymbol}');
  shipInfo(ship, '🔭 Got ${response.surveys.length} surveys!');
  caches.surveys.recordSurveys(response.surveys, getNow: getNow);
  // Each survey is the whole behavior.
  centralCommand.completeBehavior(ship.shipSymbol);
  return response.cooldown.expiration;
}
