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
Future<JobResult> _doSurveyor(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
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
    final waitUntil = await beingNewRouteAndLog(
      api,
      db,
      centralCommand,
      caches,
      ship,
      state,
      mineSymbol,
    );
    return JobResult.wait(waitUntil);
  }
  jobAssert(
    await caches.waypoints.canBeMined(ship.waypointSymbol),
    'Requires a mineable waypoint.',
    const Duration(minutes: 10),
  );
  jobAssert(ship.hasSurveyor, 'Requires a surveyor.', const Duration(hours: 1));

  // Surveying requires being undocked.
  await undockIfNeeded(db, api, ship);

  // We need to be off cooldown to continue.
  final expiration = reactorCooldownExpiration(ship, getNow);
  if (expiration != null) {
    return JobResult.wait(expiration);
  }

  final response = await surveyAndLog(db, api, ship, getNow: getNow);

  verifyCooldown(
    ship,
    'Survey',
    cooldownTimeForSurvey(ship),
    response.cooldown,
  );
  // Return immediately, even though the reactor is on cooldown.  If we
  // loop back to surveying again, that code will wait for the cooldown.
  return JobResult.complete();
}

/// Advance the behavior of the given ship.
final advanceSurveyor = const MultiJob('Surveyor', [
  _doSurveyor,
]).run;
