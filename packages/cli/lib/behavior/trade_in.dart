import 'package:cli/behavior/job.dart';
import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/nav/exploring.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/plan/ships.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// Upcycle the ship.
Future<JobResult> doTradeInJob(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  // Will also dock the ship.
  await visitLocalShipyard(
    db,
    api,
    caches.waypoints,
    caches.static,
    caches.agent,
    ship,
  );
  // Get the purchase price of a new ship of this type.
  final shipyardShips = await caches.static.shipyardShips.snapshot();
  final shipType = assertNotNull(
    shipyardShips.guessShipType(ship),
    'No ship type found.',
    const Duration(minutes: 5),
  );

  final price = assertNotNull(
    await db.shipyardPriceAt(ship.waypointSymbol, shipType),
    'No price found.',
    const Duration(minutes: 5),
  );

  final scrapTransaction = assertNotNull(
    await getScrapValue(api, ship.symbol),
    'No scrap value found',
    const Duration(minutes: 5),
  );
  final scrapValue = scrapTransaction.totalPrice;
  jobAssert(
    scrapValue > price.purchasePrice,
    'Scrap value is too low.',
    const Duration(minutes: 5),
  );
  // New ships are cheaper than the scrap value, trade in!
  await purchaseShip(db, api, caches.agent, ship.waypointSymbol, shipType);
  await scrapShipAndLog(api, db, caches.agent, ship);
  return JobResult.complete();
}

/// Advance the trade in.
final advanceTradeIn = const MultiJob('Trade In', [doTradeInJob]).run;
