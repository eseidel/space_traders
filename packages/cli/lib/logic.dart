import 'package:cli/behavior/advance.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/config.dart';
import 'package:cli/idle_queue.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/counts.dart';
import 'package:cli/net/exceptions.dart';
import 'package:cli/printing.dart';
import 'package:cli/ship_waiter.dart';
import 'package:db/db.dart';

// Pulled in to a separate function to help make sure we don't confuse
// the wait we needed for this ship with the next wait.
Future<void> _waitIfNeeded(ShipWaiterEntry entry) async {
  final waitUntil = entry.waitUntil;
  if (waitUntil != null && waitUntil.isAfter(DateTime.timestamp())) {
    final waitDuration = waitUntil.difference(DateTime.timestamp());
    final wait = approximateDuration(waitDuration);
    logger.info('⏱️  $wait until ${waitUntil.toLocal()}');
    await Future<void>.delayed(waitDuration);
  }
}

Future<void> _runIdleTasksIfPossible(
  ShipWaiterEntry entry,
  IdleQueue queue,
  Api api,
  Caches caches,
) async {
  if (!config.serviceIdleQueue) {
    return;
  }
  final waitUntil = entry.waitUntil;
  if (waitUntil == null) {
    return;
  }
  if (queue.isDone) {
    return;
  }
  logger.info('🔎 $queue');
  while (!queue.isDone &&
      DateTime.timestamp().add(queue.minProcessingTime).isBefore(waitUntil)) {
    await expectTime(
      api.requestCounts,
      'idle queue',
      queue.minProcessingTime,
      () async => await queue.runOne(api, caches),
    );
  }
}

/// Loop over our ships and advance them.  Runs until error.
Future<void> advanceShips(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  IdleQueue queue,
  ShipWaiter waiter, {
  required int loopCount,
  bool Function(Ship ship)? shipFilter,
}) async {
  // loopCount is only used to control how often we reset our waypoint and
  // market caches.  If we got rid of those we could get rid of loopCount.

  await expectTime(api.requestCounts, 'top of loop', const Duration(seconds: 1),
      () async {
    await caches.updateAtTopOfLoop(api);
    await centralCommand.advanceCentralPlanning(api, caches);
  });

  const allowableScheduleLag = Duration(milliseconds: 1000);

  // loop over all ships and advance them.
  for (var i = 0; i < loopCount; i++) {
    // Make sure we check every time in case a ship was added.
    waiter.scheduleMissingShips(caches.ships.ships, shipFilter: shipFilter);

    final entry = waiter.nextShip();
    final shipSymbol = entry.shipSymbol;
    final waitUntil = entry.waitUntil;

    await _runIdleTasksIfPossible(entry, queue, api, caches);
    await _waitIfNeeded(entry);
    final ship = caches.ships[shipSymbol];
    if (shipFilter != null && !shipFilter(ship)) {
      continue;
    }
    try {
      final before = DateTime.timestamp();
      if (waitUntil != null) {
        final lag = before.difference(waitUntil);
        if (lag > allowableScheduleLag) {
          shipWarn(ship, 'late ${approximateDuration(lag)}');
        }
      }

      final nextWaitUntil = await captureTimeAndRequests(
        api.requestCounts,
        () async => await advanceShipBehavior(
          api,
          db,
          centralCommand,
          caches,
          ship,
        ),
        onComplete: (duration, requestCount) {
          final behaviorState = caches.behaviors.getBehavior(shipSymbol);
          final expectedSeconds = requestCount / config.targetRequestsPerSecond;
          if (duration.inSeconds > expectedSeconds * 1.2) {
            final behaviorName = behaviorState?.behavior.name;
            final behaviorString =
                behaviorName == null ? '' : '($behaviorName) ';
            shipWarn(
              ship,
              '$behaviorString'
              'took ${duration.inSeconds}s ($requestCount requests) '
              'expected ${expectedSeconds.toStringAsFixed(1)}s',
            );
          }
        },
      );
      waiter.scheduleShip(shipSymbol, nextWaitUntil);
    } on ApiException catch (e) {
      // Handle the ship reactor cooldown exception which we can get when
      // running the script fresh with no state while a ship is still on
      // cooldown from a previous run.
      final expiration = expirationFromApiException(e);
      if (expiration == null) {
        // Was not a reactor cooldown, just rethrow.
        rethrow;
      }
      final difference = expiration.difference(DateTime.timestamp());
      // shipInfo(ship, '${e.message} $stackTrace');
      shipInfo(ship, '🥶 for ${approximateDuration(difference)}');
      waiter.scheduleShip(shipSymbol, expiration);
    }
  }

  // Print a warning about any ships that have been waiting too long.
  final oneMinuteAgo =
      DateTime.timestamp().subtract(const Duration(minutes: 1));
  final starvedShips = waiter.starvedShips(oneMinuteAgo);
  if (starvedShips.isNotEmpty) {
    logger.warn('⚠️  ${starvedShips.length} starved ships: $starvedShips');
  }
}

/// RateLimitTracker tracks the rate limit usage and prints stats.
class RateLimitTracker {
  /// Construct a rate limit tracker.
  RateLimitTracker(Api api, {this.printEvery = const Duration(minutes: 2)})
      : _api = api,
        _lastPrintTime = DateTime.timestamp() {
    _lastRequestCount = _api.requestCounts.totalRequests;
  }

  /// The rate limit stats are printed every this often.
  final Duration printEvery;

  final Api _api;
  DateTime _lastPrintTime;
  late int _lastRequestCount;

  /// Print the stats if it has been long enough since the last print.
  void printStatsIfNeeded() {
    final now = DateTime.timestamp();
    final timeSinceLastPrint = now.difference(_lastPrintTime);
    final requestCounts = _api.requestCounts;
    if (timeSinceLastPrint > printEvery) {
      final requestCount = requestCounts.totalRequests;
      final requestsSinceLastPrint = requestCount - _lastRequestCount;
      _lastRequestCount = requestCount;
      final requestsPerSecond =
          requestsSinceLastPrint / timeSinceLastPrint.inSeconds;
      final max = timeSinceLastPrint.inSeconds * config.targetRequestsPerSecond;
      final percent = ((requestsSinceLastPrint / max) * 100).round();
      // No sense in printing low percentages, as that will just end up being
      // most of what we print.
      logger.info(
        '${requestsPerSecond.toStringAsFixed(1)} requests per second '
        '($percent% of max)',
      );
      _lastPrintTime = now;
    }
  }
}

/// Run the logic loop forever.
Future<Never> logic(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches, {
  bool Function(Ship ship)? shipFilter,
}) async {
  final waiter = ShipWaiter()
    ..scheduleMissingShips(
      caches.ships.ships,
      suppressWarnings: true,
      shipFilter: shipFilter,
    );
  final rateLimitTracker = RateLimitTracker(api);
  final queue = IdleQueue()
    ..queueSystem(caches.agent.headquartersSystemSymbol, jumpDistance: 0);

  while (true) {
    rateLimitTracker.printStatsIfNeeded();
    try {
      await advanceShips(
        api,
        db,
        centralCommand,
        caches,
        queue,
        waiter,
        shipFilter: shipFilter,
        loopCount: 20,
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
      rethrow;
    }
  }
}
