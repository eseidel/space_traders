import 'package:cli/behavior/job.dart';
import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/logic/printing.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/plan/mining.dart';
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
  final mineJob = assertNotNull(
    state.extractionJob,
    'Requires a mine job.',
    const Duration(minutes: 10),
  );
  final mineSymbol = mineJob.source;
  if (ship.waypointSymbol != mineSymbol) {
    return beingNewRouteAndLog(
      api,
      db,
      centralCommand,
      caches,
      ship,
      state,
      mineSymbol,
    );
  }
  jobAssert(
    await caches.waypoints.canBeMined(ship.waypointSymbol),
    'Requires a mineable waypoint.',
    const Duration(minutes: 10),
  );
  jobAssert(ship.hasSurveyor, 'Requires a surveyor.', const Duration(hours: 1));

  // Surveying requires being undocked.
  await undockIfNeeded(db, api, ship);
  final response = await surveyAndLog(db, api, ship, getNow: getNow);

  verifyCooldown(
    ship,
    'Survey',
    cooldownTimeForSurvey(ship),
    response.cooldown,
  );

  // Each survey is the whole behavior.
  state.isComplete = true;
  return response.cooldown.expiration;
}
