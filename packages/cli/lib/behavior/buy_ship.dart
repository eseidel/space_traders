import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/net/exceptions.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/trading.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// CostedTrip for ShipyardPrice.
typedef ShipyardTrip = CostedTrip<ShipyardPrice>;

List<ShipyardTrip> _shipyardsSellingByDistance(
  ShipyardPriceSnapshot shipyardPrices,
  RoutePlanner routePlanner,
  Ship ship,
  ShipType shipType,
) {
  final prices = shipyardPrices.pricesFor(shipType).toList();
  if (prices.isEmpty) {
    return [];
  }
  final start = ship.waypointSymbol;

  // If there are a lot of prices we could cut down the search space by only
  // looking at prices at or below median?
  // final medianPrice = marketPrices.medianPurchasePrice(tradeSymbol)!;
  // Find the closest 10 prices which are median or below.
  // final medianOrBelow = prices.where((e) => e.purchasePrice <= medianPrice);

  final costed = <ShipyardTrip>[];
  for (final price in prices) {
    final end = price.waypointSymbol;
    final trip = costTrip(
      routePlanner,
      price,
      ship.shipSpec,
      start: start,
      end: end,
    );
    if (trip != null) {
      costed.add(trip);
    } else {
      logger.warn('No route from $start to $end');
    }
  }

  final sorted = costed.toList()
    ..sort((a, b) => a.route.duration.compareTo(b.route.duration));
  return sorted;
}

/// Find the best market to buy a given item from.
/// expectedCreditsPerSecond is the time value of money (e.g. 7c/s)
/// used for evaluating the trade-off between "closest" vs. "cheapest".
ShipyardTrip? findBestShipyardToBuy(
  ShipyardPriceSnapshot shipyardPrices,
  RoutePlanner routePlanner,
  Ship ship,
  ShipType shipType, {
  required int expectedCreditsPerSecond,
}) {
  final sorted = _shipyardsSellingByDistance(
    shipyardPrices,
    routePlanner,
    ship,
    shipType,
  );
  if (sorted.isEmpty) {
    return null;
  }
  final nearest = sorted.first;
  var best = nearest;
  // Pick any one further that saves more than expectedCreditsPerSecond
  for (final trip in sorted.sublist(1)) {
    final priceDiff = trip.price.purchasePrice - nearest.price.purchasePrice;
    final savings = -priceDiff;
    final extraTime = trip.route.duration - nearest.route.duration;
    final savingsPerSecond = savings / extraTime.inSeconds;
    if (savingsPerSecond > expectedCreditsPerSecond) {
      best = trip;
      break;
    }
  }

  return best;
}

/// Log a warning if the purchased ship does not match the expected template.
// void verifyShipMatchesTemplate(Ship ship, ShipType shipType) {
//   final fromTemplate = makeShip(
//     type: shipType,
//     shipSymbol: ship.shipSymbol,
//     factionSymbol: ship.registration.factionSymbol,
//     origin: ship.nav.route.origin,
//     now: ship.nav.route.arrival,
//   );
// }

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
  final shipyardSymbol = state.shipBuyJob!.shipyardSymbol;
  final shipType = state.shipBuyJob!.shipType;

  if (ship.waypointSymbol != shipyardSymbol) {
    // We're not there, go to the shipyard to purchase.
    final waitTime = await beingNewRouteAndLog(
      api,
      db,
      centralCommand,
      caches,
      ship,
      state,
      shipyardSymbol,
    );
    return waitTime;
  }
  // Otherwise we're at the shipyard we intended to be at.

  // Update our shipyard prices regardless of any later errors.
  final shipyard = await getShipyard(api, ship.waypointSymbol);
  recordShipyardDataAndLog(
    db,
    caches.static,
    shipyard,
    ship,
  );

  final PurchaseShip201ResponseData result;
  try {
    result = await purchaseShipAndLog(
      api,
      db,
      caches.ships,
      caches.agent,
      ship,
      shipyard.waypointSymbol,
      shipType,
    );
    recordShip(caches.static, result.ship);
  } on ApiException catch (e) {
    // ApiException 400: {"error":{"message":"Failed to purchase ship.
    // Agent has insufficient funds.","code":4216,
    // "data":{"creditsAvailable":116103,"creditsNeeded":172355}}}
    final neededCredits = neededCreditsFromPurchaseShipException(e);
    if (neededCredits == null) {
      // Was not an insufficient credits exception.
      rethrow;
    }
    failJob(
      'Failed to purchase ship ${caches.agent.agent.credits} < $neededCredits',
      const Duration(minutes: 10),
    );
  }

  // Record our success!
  state.isComplete = true;
  // Rate limiting for ship buying is done by CentralCommand.
  shipWarn(ship, 'Purchased ${result.ship.symbol} ($shipType)!');
  return null;
}
