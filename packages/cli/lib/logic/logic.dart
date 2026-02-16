import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/config.dart';
import 'package:cli/logger.dart';
import 'package:cli/logic/advance.dart';
import 'package:cli/logic/printing.dart';
import 'package:cli/logic/ship_waiter.dart';
import 'package:cli/net/exceptions.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/net/register.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

// Pulled in to a separate function to help make sure we don't confuse
// the wait we needed for this ship with the next wait.
Future<void> _waitIfNeeded(ShipWaiterEntry entry) async {
  final waitUntil = entry.waitUntil;
  if (waitUntil != null && waitUntil.isAfter(DateTime.timestamp())) {
    final waitDuration = waitUntil.difference(DateTime.timestamp());
    final wait = approximateDuration(waitDuration);
    final log = waitDuration < const Duration(minutes: 1)
        ? logger.detail
        : logger.info;
    log('⏱️  $wait until ${waitUntil.toLocal()}');
    await Future<void>.delayed(waitDuration);
  }
}

/// Loop over our ships and advance them.  Runs until error.
Future<void> advanceShips(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  ShipWaiter waiter,
  TopOfLoopUpdater updater, {
  bool Function(Ship ship)? shipFilter,
}) async {
  await expectTime(
    api.requestCounts,
    db.queryCounts,
    'central planning',
    const Duration(seconds: 1),
    () async {
      await centralCommand.advanceCentralPlanning(db, api, caches);
    },
  );

  const allowableScheduleLag = Duration(milliseconds: 1000);

  // loop over all ships and advance them.
  for (var i = 0; i < config.centralPlanningInterval; i++) {
    await expectTime(
      api.requestCounts,
      db.queryCounts,
      'top of loop',
      const Duration(milliseconds: 500),
      () async {
        await updater.updateAtTopOfLoop(caches, db, api);
      },
    );

    // Make sure we check every time in case a ship was added.
    // TODO(eseidel): This should no longer be needed!
    final ships = await ShipSnapshot.load(db);
    waiter.scheduleMissingShips(ships.ships);

    final entry = waiter.nextShip();
    final shipSymbol = entry.shipSymbol;
    final waitUntil = entry.waitUntil;

    await _waitIfNeeded(entry);
    final ship = await db.ships.get(shipSymbol);
    if (ship == null) {
      // This can happen if a ship is scrapped.
      logger.warn('⚠️  ship $shipSymbol not found in db (probably scrapped)');
      continue;
    }
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
        db.queryCounts,
        () async =>
            await advanceShipBehavior(api, db, centralCommand, caches, ship),
        onComplete: (duration, requestCount, queryCounts) async {
          final behaviorState = await db.behaviors.get(shipSymbol);
          final expectedSeconds =
              (requestCount / networkConfig.targetRequestsPerSecond) * 1.2;
          if (duration.inSeconds > expectedSeconds) {
            final behaviorName = behaviorState?.behavior.name;
            final behaviorString = behaviorName == null
                ? ''
                : '($behaviorName) ';
            final logFn = duration.inSeconds > expectedSeconds * 5
                ? shipErr
                : shipWarn;
            logFn(
              ship,
              '$behaviorString'
              'took ${duration.inSeconds}s '
              '($requestCount requests, ${queryCounts.total} queries) '
              'expected ${expectedSeconds.toStringAsFixed(1)}s',
            );
            logCounts(queryCounts);
          }
        },
      );
      waiter.scheduleShip(shipSymbol, nextWaitUntil);
      // TODO(eseidel): Compare the ship object with what we have in our db.
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
  final oneMinuteAgo = DateTime.timestamp().subtract(
    const Duration(minutes: 1),
  );
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
    _lastRequestCount = _api.requestCounts.total;
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
      final requestCount = requestCounts.total;
      final requestsSinceLastPrint = requestCount - _lastRequestCount;
      _lastRequestCount = requestCount;
      final requestsPerSecond =
          requestsSinceLastPrint / timeSinceLastPrint.inSeconds;
      final max =
          timeSinceLastPrint.inSeconds * networkConfig.targetRequestsPerSecond;
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
  Caches caches,
) async {
  final ships = await ShipSnapshot.load(db);
  final waiter = ShipWaiter()
    ..scheduleMissingShips(ships.ships, suppressWarnings: true);
  final rateLimitTracker = RateLimitTracker(api);
  final updater = TopOfLoopUpdater();

  while (true) {
    rateLimitTracker.printStatsIfNeeded();
    try {
      await advanceShips(api, db, centralCommand, caches, waiter, updater);
    } on ApiException catch (e) {
      if (isMaintenanceWindowException(e)) {
        logger.warn('Server down for maintenance, waiting 1 minute.');
        await Future<void>.delayed(const Duration(minutes: 1));
        continue;
      }
      // Caller will handle token changes after reset.
      rethrow;
    }
  }
}

/// Similar to waitFor in idle_queue.dart.
Future<void> waitForSystem(Database db, GalaxyStats galaxy) async {
  while (true) {
    final systems = await db.systems.countSystemRecords();
    final waypoints = await db.systems.countSystemWaypoints();
    if (systems >= galaxy.systemCount && waypoints >= galaxy.waypointCount) {
      logger.info('$systems systems and $waypoints waypoints are cached.');
      return;
    }
    logger.info(
      'Waiting for systems and waypoints to be cached... '
      '$systems/${galaxy.systemCount} systems and '
      '$waypoints/${galaxy.waypointCount} waypoints.',
    );
    await Future<void>.delayed(const Duration(minutes: 1));
  }
}

/// Print the status of the server.
void printStatus(GetStatus200Response s) {
  final mostCreditsString = s.leaderboards.mostCredits
      .map(
        (e) =>
            '${e.agentSymbol.padLeft(14)} '
            '${creditsString(e.credits).padLeft(14)}',
      )
      .join(', ');
  final mostChartsString = s.leaderboards.mostSubmittedCharts
      .map(
        (e) =>
            '${e.agentSymbol.padLeft(14)} '
            '${e.chartCount.toString().padLeft(14)}',
      )
      .join(', ');
  final now = DateTime.timestamp();
  final resetDate = DateTime.tryParse(s.resetDate)!;
  final sinceLastReset = approximateDuration(now.difference(resetDate));
  final nextResetDate = DateTime.tryParse(s.serverResets.next)!;
  final untilNextReset = approximateDuration(nextResetDate.difference(now));
  final statsParts = [
    '${s.stats.agents} agents',
    '${s.stats.ships} ships',
    '${s.stats.systems} systems',
    '${s.stats.waypoints} waypoints',
  ].map((e) => e.padLeft(20)).toList();

  logger
    ..info('Stats: ${statsParts.join(' ')}')
    ..info('Most Credits: $mostCreditsString')
    ..info('Most Charts:  $mostChartsString')
    ..info(
      'Last reset $sinceLastReset ago, '
      'next reset: $untilNextReset, '
      'cadence: ${s.serverResets.frequency}',
    );
  final knownAnnouncementTitles = ['Server Resets', 'Discord', 'Support Us'];
  for (final announcement in s.announcements) {
    if (knownAnnouncementTitles.contains(announcement.title)) {
      continue;
    }
    logger.info('Announcement: ${announcement.title}');
  }
}

/// Print the stats of the database.
Future<void> printDbStats(Database db) async {
  final marketPricesCount = await db.marketPrices.count();
  final marketWaypointsCount = await db.marketPrices.countWaypoints();
  final shipyardPricesCount = await db.shipyardPrices.count();
  final shipyardWaypointsCount = await db.shipyardPrices.waypointCount();
  logger.info(
    'Loaded $marketPricesCount prices from '
    '$marketWaypointsCount markets and '
    '$shipyardPricesCount prices from '
    '$shipyardWaypointsCount shipyards.',
  );
}

/// Start executing on the current reset.
Future<void> enterReset(Api api, Database db, Uri baseUri) async {
  final myAgent = await api.agents.getMyAgent();
  final agentSymbol = myAgent.data.symbol;
  logger.info('Playing as $agentSymbol on $baseUri');

  // First we ask the API how many systems there are.
  final galaxy = await getGalaxyStats(api);
  // Wait for starting system to be cached if necessary.
  await waitForSystem(db, galaxy);

  // Print the leaderboards.
  final status = await api.defaultApi.getStatus();
  printStatus(status);

  await printDbStats(db);

  config = await Config.fromDb(db);
  final caches = await Caches.loadOrFetch(api, db);
  final centralCommand = CentralCommand();

  final agent = await fetchAndCacheMyAgent(db, api);
  final ships = await ShipSnapshot.load(db);
  logger
    ..info(
      'Welcome ${agent.symbol} of the ${agent.startingFaction}!'
      ' ${creditsString(agent.credits)}',
    )
    ..info('Fleet: ${describeShips(ships.ships)}');

  await logic(api, db, centralCommand, caches);
}

/// Run the agent loop forever, re-registering a new agent if necessary.
Future<void> reregisterLoop(
  Api api,
  Database db,
  Uri baseUri, {
  required String? agentSymbol,
}) async {
  while (true) {
    try {
      await enterReset(api, db, baseUri);
    } on ApiException catch (e) {
      if (isTokenMismatchException(e)) {
        logger.warn('Token mismatch, re-registering agent.');
        await db.config.clearAgentToken();
        final agentToken = await registerAgentIfNeeded(
          db,
          baseUri: baseUri,
          agentSymbol: agentSymbol,
        );
        api.apiClient.agentToken = agentToken;
        await db.config.setAgentToken(agentToken);
        continue;
      }
      rethrow;
    }
  }
}
