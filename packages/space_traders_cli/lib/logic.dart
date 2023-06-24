import 'package:space_traders_cli/behavior/advance.dart';
import 'package:space_traders_cli/behavior/central_command.dart';
import 'package:space_traders_cli/cache/caches.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/net/exceptions.dart';
import 'package:space_traders_cli/net/rate_limit.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/ship_waiter.dart';

/// One loop of the logic.
Future<void> advanceShips(
  Api api,
  CentralCommand centralCommand,
  Caches caches,
  ShipWaiter waiter, {
  bool Function(Ship ship)? shipFilter,
}) async {
  // WaypointCache and MarketCache only live for one loop over the ships.
  caches.waypoints.resetForLoop();
  caches.markets.resetForLoop();

  await caches.ships.ensureShipsUpToDate(api);
  await caches.agent.ensureAgentUpToDate(api);

  waiter.updateForShips(caches.ships.ships);

  final shipSymbols = caches.ships.shipSymbols;

  // loop over all ships and advance them.
  for (final shipSymbol in shipSymbols) {
    final previousWait = waiter.waitUntil(shipSymbol);
    if (previousWait != null) {
      continue;
    }
    final ship = caches.ships.ship(shipSymbol);
    if (shipFilter != null && !shipFilter(ship)) {
      continue;
    }
    try {
      final waitUntil = await advanceShipBehavior(
        api,
        centralCommand,
        caches,
        ship,
      );
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
    caches.ships.updateShip(ship);
  }
}

/// RateLimitTracker tracks the rate limit usage and prints stats.
class RateLimitTracker {
  /// Construct a rate limit tracker.
  RateLimitTracker(Api api, {this.printEvery = const Duration(minutes: 1)})
      : _rateLimit = api.apiClient,
        _lastPrintTime = DateTime.timestamp() {
    _lastRequestCount = _rateLimit.requestCounts.totalRequests();
  }

  /// The rate limit stats are printed every this often.
  final Duration printEvery;

  final RateLimitedApiClient _rateLimit;
  DateTime _lastPrintTime;
  late int _lastRequestCount;

  /// Print the stats if it has been long enough since the last print.
  void printStatsIfNeeded() {
    final now = DateTime.timestamp();
    final timeSinceLastPrint = now.difference(_lastPrintTime);
    final requestCounts = _rateLimit.requestCounts;
    if (timeSinceLastPrint > printEvery) {
      final requestCount = requestCounts.totalRequests();
      final requestsSinceLastPrint = requestCount - _lastRequestCount;
      _lastRequestCount = requestCount;
      final requestsPerSecond =
          requestsSinceLastPrint / timeSinceLastPrint.inSeconds;
      final max =
          timeSinceLastPrint.inSeconds * _rateLimit.maxRequestsPerSecond;
      final percent = ((requestsSinceLastPrint / max) * 100).round();
      logger.info(
        '${requestsPerSecond.toStringAsFixed(1)} requests per second '
        '($percent% of max)',
      );
      _lastPrintTime = now;
    }
  }
}

/// Run the logic loop forever.
Future<void> logic(
  Api api,
  CentralCommand centralCommand,
  Caches caches,
) async {
  final waiter = ShipWaiter();
  final rateLimitTracker = RateLimitTracker(api);

  while (true) {
    rateLimitTracker.printStatsIfNeeded();
    try {
      await advanceShips(
        api,
        centralCommand,
        caches,
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
        earliestWaitUntil.isAfter(DateTime.timestamp())) {
      // This future waits until the earliest time we think the server
      // will be ready for us to do something.
      final waitDuration = earliestWaitUntil.difference(DateTime.timestamp());
      if (waitDuration.inSeconds > 5) {
        // Extra space after emoji needed for windows powershell.
        final wait = approximateDuration(waitDuration);
        logger.info('⏱️  $wait until ${earliestWaitUntil.toLocal()}');
      }
      await Future<void>.delayed(
        earliestWaitUntil.difference(DateTime.timestamp()),
      );
    }
    // Otherwise we just loop again immediately and rely on rate limiting in the
    // API client to prevent us from sending requests too quickly.
  }
}
