import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/miner.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/printing.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// For dedicated survey ships.
Future<DateTime?> advanceSurveyor(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  BehaviorState state,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final currentWaypoint = await caches.waypoints.waypoint(ship.waypointSymbol);

  final mineJob =
      centralCommand.mineJobForShip(caches.systems, caches.agent, ship);
  final mineSymbol = mineJob.mine;
  if (ship.waypointSymbol != mineSymbol) {
    return beingNewRouteAndLog(
      api,
      ship,
      state,
      caches.ships,
      caches.systems,
      caches.routePlanner,
      centralCommand,
      mineSymbol,
    );
  }
  jobAssert(
    currentWaypoint.canBeMined,
    'Requires a mineable waypoint.',
    const Duration(minutes: 10),
  );
  jobAssert(ship.hasSurveyor, 'Requires a surveyor.', const Duration(hours: 1));

  // Surveying requires being undocked.
  await undockIfNeeded(api, caches.ships, ship);
  final response =
      await surveyAndLog(api, db, caches.ships, ship, getNow: getNow);

  verifyCooldown(
    ship,
    'Survey',
    cooldownTimeForSurvey(ship),
    response.cooldown,
  );

  // for (final survey in response.surveys) {
  //   printSurvey(survey, caches.marketPrices, mineJob.market);
  // }

  // Each survey is the whole behavior.
  state.isComplete = true;
  return response.cooldown.expiration;
}
