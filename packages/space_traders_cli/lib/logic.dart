import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/behavior/advance.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/data_store.dart';
import 'package:space_traders_cli/exceptions.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';
import 'package:space_traders_cli/ship_waiter.dart';
import 'package:space_traders_cli/shipyard_prices.dart';
import 'package:space_traders_cli/surveys.dart';
import 'package:space_traders_cli/systems_cache.dart';
import 'package:space_traders_cli/transactions.dart';
import 'package:space_traders_cli/waypoint_cache.dart';

// Consider having a config file like:
// https://gist.github.com/whyando/fed97534173437d8234be10ac03595e0
// instead of having this dynamic behavior function.
// At the top of the file because I change this so often.
Behavior _behaviorFor(
  BehaviorManager behaviorManager,
  Ship ship,
  Agent agent,
) {
  final disableBehaviors = <Behavior>[
    Behavior.buyShip,
    // Behavior.contractTrader,
    Behavior.arbitrageTrader,
    // Behavior.miner,
    // Behavior.idle,
    // Behavior.explorer,
  ];

  final behaviors = {
    ShipRole.COMMAND: [
      Behavior.contractTrader,
      Behavior.arbitrageTrader,
      Behavior.miner
    ],
    ShipRole.HAULER: [Behavior.contractTrader],
    ShipRole.EXCAVATOR: [Behavior.miner],
    ShipRole.SURVEYOR: [Behavior.explorer],
  }[ship.registration.role];
  if (behaviors != null) {
    for (final behavior in behaviors) {
      if (disableBehaviors.contains(behavior)) {
        continue;
      }
      if (behaviorManager.isEnabled(behavior)) {
        return behavior;
      }
    }
  } else {
    logger
        .warn('${ship.registration.role} has no specified behaviors, idling.');
  }
  return Behavior.idle;
}

/// One loop of the logic.
Future<void> logicLoop(
  Api api,
  DataStore db,
  SystemsCache systemsCache,
  PriceData priceData,
  ShipyardPrices shipyardPrices,
  SurveyData surveyData,
  TransactionLog transactions,
  ShipWaiter waiter,
) async {
  final waypointCache = WaypointCache(api, systemsCache);
  final marketCache = MarketCache(waypointCache);
  final agent = await getMyAgent(api);
  final myShips = await allMyShips(api).toList();
  waiter.updateForShips(myShips);

  // loop over all mining ships and advance them.
  for (final ship in myShips) {
    final previousWait = waiter.waitUntil(ship.symbol);
    if (previousWait != null) {
      continue;
    }
    // We should only generate a new behavior when we're done with our last
    // behavior?
    final behaviorManager = await BehaviorManager.load(db, (bm, shipSymbol) {
      // This logic is triggered twice for each ship, not sure why.
      final ship = myShips.firstWhere((s) => s.symbol == shipSymbol);
      final behavior = _behaviorFor(bm, ship, agent);
      // shipInfo(ship, 'Chose new behavior: $behavior');
      return behavior;
    });
    try {
      final ctx = BehaviorContext(
        api,
        db,
        priceData,
        shipyardPrices,
        ship,
        agent,
        systemsCache,
        waypointCache,
        marketCache,
        behaviorManager,
        surveyData,
        transactions,
      );
      final waitUntil = await advanceShipBehavior(ctx);
      waiter.updateWaitUntil(ship.symbol, waitUntil);
    } on ApiException catch (e) {
      // Handle the ship reactor cooldown exception which we can get when
      // running the script fresh with no state while a ship is still on
      // cooldown from a previous run.
      final expiration = expirationFromApiException(e);
      if (expiration == null) {
        // Was not a reactor cooldown, just rethrow.
        rethrow;
      }
      final difference = expiration.difference(DateTime.now());
      shipInfo(ship, '🥶 for ${durationString(difference)}');
      waiter.updateWaitUntil(ship.symbol, expiration);
    }
  }
}

/// Returns true if we should purchase a new ship.
/// Currently just returns true if we have no mining ships.
bool shouldPurchaseMiner(Agent myAgent, List<Ship> ships) {
  // If we have no mining ships, purchase one.
  if (ships.every((s) => !s.isExcavator)) {
    return true;
  }
  // This should be dynamic based on market prices?
  // Risk is that it will try to purchase and fail (causing an exception).
  return false;
  // return myAgent.credits > 140000;
}

/// Run the logic loop forever.
/// Currently just sends ships to mine and sell ore.
Future<void> logic(
  Api api,
  DataStore db,
  SystemsCache systemsCache,
  PriceData priceData,
  ShipyardPrices shipyardPrices,
  SurveyData surveyData,
  TransactionLog transactions,
) async {
  final waiter = ShipWaiter();

  while (true) {
    try {
      await logicLoop(
        api,
        db,
        systemsCache,
        priceData,
        shipyardPrices,
        surveyData,
        transactions,
        waiter,
      );
    } on ApiException catch (e) {
      if (isMaintenanceWindowException(e)) {
        logger.warn('Server down for maintenance, waiting 1 minute.');
        await Future<void>.delayed(const Duration(minutes: 1));
        continue;
      }

      // Need to handle token changes after reset.
      // ApiException 401: {"error":{"message":"Failed to parse token.
      // Token reset_date does not match the server. Server resets happen on a
      // weekly to bi-weekly frequency during alpha. After a reset, you should
      // re-register your agent. Expected: 2023-06-03, Actual: 2023-05-20",
      // "code":401,"data":{"expected":"2023-06-03","actual":"2023-05-20"}}}

      // Need to handle temporary service unavailable.
      // ApiException 503: Service Unavailable
      // Just use exponential backoff until it comes back.

      if (!isWindowsSemaphoreTimeout(e)) {
        rethrow;
      }
      // ignore windows semaphore timeout
      logger.warn('Ignoring windows semaphore timeout exception, waiting 5s.');
      // I've seen up to 4 of these happen in a row, so wait a few seconds for
      // the system to recover.
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    final earliestWaitUntil = waiter.earliestWaitUntil();
    // earliestWaitUntil can be past if an earlier ship needed to wait
    // but then later ships took longer than that wait time to process.
    if (earliestWaitUntil != null &&
        earliestWaitUntil.isAfter(DateTime.now())) {
      // This future waits until the earliest time we think the server
      // will be ready for us to do something.
      final waitDuration = earliestWaitUntil.difference(DateTime.now());
      // Extra space after emoji needed for windows powershell.
      logger.info(
        '⏱️  ${waitDuration.inSeconds}s until ${earliestWaitUntil.toLocal()}',
      );
      await Future<void>.delayed(earliestWaitUntil.difference(DateTime.now()));
    }
    // Otherwise we just loop again immediately and rely on rate limiting in the
    // API client to prevent us from sending requests too quickly.
  }
}
