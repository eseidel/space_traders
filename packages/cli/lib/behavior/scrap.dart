import 'package:cli/behavior/job.dart';
import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// Scrap the ship.
Future<JobResult> doScrapJob(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  // If we're at a shipyard, scrap the ship.
  // If we're not, find the nearest shipyard.
  // Navigate to that shipyard.

  final shipyardListings = await ShipyardListingSnapshot.load(db);
  final shipyard = assertNotNull(
    await nearestShipyard(
      caches.routePlanner,
      shipyardListings,
      ship.waypointSymbol,
    ),
    'No shipyard found.',
    const Duration(minutes: 5),
  );

  if (shipyard.waypointSymbol == ship.waypointSymbol) {
    // We're at the shipyard, scrap the ship.
    await scrapShipAndLog(
      api,
      db,
      caches.agent,
      ship,
    );
    shipErr(ship, 'Scrapped ship!');
    return JobResult.complete();
  }

  final waitTime = await beingNewRouteAndLog(
    api,
    db,
    centralCommand,
    caches,
    ship,
    state,
    shipyard.waypointSymbol,
  );
  return JobResult.wait(waitTime);
}

/// Advance the scrap.
final advanceScrap = const MultiJob('Scrap', [
  doScrapJob,
]).run;
