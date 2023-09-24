import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/net/queries.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// Apply the buy ship behavior.
Future<DateTime?> advanceBuyShip(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  BehaviorState state,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final currentWaypoint = await caches.waypoints.waypoint(ship.waypointSymbol);
  final shipyardSymbol = state.shipBuyJob!.shipyardSymbol;
  final shipType = state.shipBuyJob!.shipType;

  if (currentWaypoint.waypointSymbol != shipyardSymbol) {
    // We're not there, go to the shipyard to purchase.
    final waitTime = await beingNewRouteAndLog(
      api,
      ship,
      state,
      caches.ships,
      caches.systems,
      caches.routePlanner,
      centralCommand,
      shipyardSymbol,
    );
    return waitTime;
  }
  // Otherwise we're at the shipyard we intended to be at.

  // Update our shipyard prices regardless of any later errors.
  final shipyard = await getShipyard(api, currentWaypoint);
  recordShipyardDataAndLog(caches.shipyardPrices, shipyard, ship);

  // TODO(eseidel): Catch exceptions about insufficient credits.
  final result = await purchaseShipAndLog(
    api,
    db,
    caches.ships,
    caches.agent,
    ship,
    shipyard.waypointSymbol,
    shipType,
  );
  // Record our success!
  state.isComplete = true;
  jobAssert(
    false,
    'Purchased ${result.ship.symbol} ($shipType)!',
    const Duration(minutes: 10),
  );
  return null;
}
