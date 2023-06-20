import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/behavior/advance.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/cache/agent_cache.dart';
import 'package:space_traders_cli/cache/data_store.dart';
import 'package:space_traders_cli/cache/prices.dart';
import 'package:space_traders_cli/cache/ship_cache.dart';
import 'package:space_traders_cli/cache/shipyard_prices.dart';
import 'package:space_traders_cli/cache/surveys.dart';
import 'package:space_traders_cli/cache/systems_cache.dart';
import 'package:space_traders_cli/cache/transactions.dart';
import 'package:space_traders_cli/cache/waypoint_cache.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/net/exceptions.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/ship_waiter.dart';

/// One loop of the logic.
Future<void> advanceShips(
  Api api,
  DataStore db,
  SystemsCache systemsCache,
  PriceData priceData,
  ShipyardPrices shipyardPrices,
  SurveyData surveyData,
  TransactionLog transactions,
  BehaviorManager behaviorManager,
  ShipWaiter waiter,
  ShipCache shipCache,
  AgentCache agentCache,
) async {
  // WaypointCache and MarketCache only live for one loop over the ships.
  final waypointCache = WaypointCache(api, systemsCache);
  final marketCache = MarketCache(waypointCache);

  await shipCache.ensureShipsUpToDate(api);
  await agentCache.ensureAgentUpToDate(api);

  waiter.updateForShips(shipCache.ships);

  final shipSymbols = shipCache.shipSymbols;

  // loop over all ships and advance them.
  for (final shipSymbol in shipSymbols) {
    final previousWait = waiter.waitUntil(shipSymbol);
    if (previousWait != null) {
      continue;
    }
    final ship = shipCache.ship(shipSymbol);
    try {
      final ctx = BehaviorContext(
        api,
        db,
        priceData,
        shipyardPrices,
        shipCache,
        agentCache,
        systemsCache,
        waypointCache,
        marketCache,
        behaviorManager,
        surveyData,
        transactions,
        ship,
      );
      final waitUntil = await advanceShipBehavior(ctx);
      waiter.updateWaitUntil(shipSymbol, waitUntil);
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
      waiter.updateWaitUntil(shipSymbol, expiration);
    }
    // This assumes that advanceShipBehavior updated the passed in ship.
    shipCache.updateShip(ship);
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
Future<void> logic(
  Api api,
  DataStore db,
  SystemsCache systemsCache,
  PriceData priceData,
  ShipyardPrices shipyardPrices,
  SurveyData surveyData,
  TransactionLog transactions,
  BehaviorManager behaviorManager,
  AgentCache agentCache,
  ShipCache shipCache,
) async {
  final waiter = ShipWaiter();

  while (true) {
    try {
      await advanceShips(
        api,
        db,
        systemsCache,
        priceData,
        shipyardPrices,
        surveyData,
        transactions,
        behaviorManager,
        waiter,
        shipCache,
        agentCache,
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
        earliestWaitUntil.isAfter(DateTime.timestamp())) {
      // This future waits until the earliest time we think the server
      // will be ready for us to do something.
      final waitDuration = earliestWaitUntil.difference(DateTime.timestamp());
      // Extra space after emoji needed for windows powershell.
      final time = waitDuration.inSeconds < 1
          ? '${waitDuration.inMilliseconds}ms'
          : '${waitDuration.inSeconds}s';
      logger.info('⏱️  $time until ${earliestWaitUntil.toLocal()}');
      await Future<void>.delayed(
        earliestWaitUntil.difference(DateTime.timestamp()),
      );
    }
    // Otherwise we just loop again immediately and rely on rate limiting in the
    // API client to prevent us from sending requests too quickly.
  }
}
