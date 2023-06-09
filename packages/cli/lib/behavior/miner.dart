import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/explorer.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/net/exceptions.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';
import 'package:collection/collection.dart';

// my evaluation logic actually just assumes I'll get 10 extracts from each
// survey regardless of size - so room for improvement.... I just don't have the
// data on how many extracts to exhaust a deposit

// what I'd recommend as a fast solution is using taavi's evaluation logic on
// each survey you make, keep a record of the scores, and then only mine out
// surveys that historically would have been in the top third (edited)

// do you not divide by the number of deposits in the survey? Aren't you
// favouring the 5 deposit surveys too much here?

// scoreSurvey(
//     survey: Survey,
//     favourItemSymbols: ItemSymbol[] | undefined,
//     averageSellPrices: Record<ItemSymbol, number>,
//   ): number {
//     return survey.deposits.reduce(
//       (score, item) =>
//         (score +=
//           (averageSellPrices[item] ?? 1) *
//          (favourItemSymbols && favourItemSymbols.includes(item) ? 1000 : 1)),
//       0,
//     );
//   }

// Expected survey rates:
// https://discord.com/channels/792864705139048469/792864705139048472/1112766963601645628

/// Returns the expected value of the survey.
int expectedValueFromSurvey(
  MarketPrices marketPrices,
  Survey survey, {
  required String marketSymbol,
}) {
  // I'm not yet sure what to do with deposit size.
  // Look at each of the possible returns.
  // Price them at the passed in market.
  // This will fail if the passed in market doesn't sell everything.

  final totalValue = survey.deposits.fold<int>(0, (total, deposit) {
    final sellPrice = marketPrices.recentSellPrice(
          marketSymbol: marketSymbol,
          tradeSymbol: deposit.symbol,
        ) ??
        0; // null when prices database is empty.
    return total + sellPrice;
  });
  return totalValue ~/ survey.deposits.length;
}

/// Returns the nearest waypoint with a marketplace.
Future<Waypoint?> nearestWaypointWithMarket(
  WaypointCache waypointCache,
  Waypoint start, {
  int maxJumps = 1,
}) async {
  if (start.hasMarketplace) {
    return start;
  }
  await for (final waypoint in waypointCache.waypointsInJumpRadius(
    startSystem: start.systemSymbol,
    maxJumps: maxJumps,
  )) {
    if (waypoint.hasMarketplace) {
      return waypoint;
    }
  }
  return null;
}

class _ValuedSurvey {
  _ValuedSurvey({
    required this.expectedValue,
    required this.survey,
    required this.isActive,
  });

  final int expectedValue;
  final Survey survey;
  final bool isActive;
}

/// Finds a recent survey
Future<Survey?> surveyWorthMining(
  MarketPrices marketPrices,
  SurveyData surveyData, {
  required String surveyWaypointSymbol,
  required String nearbyMarketSymbol,
  int minimumSurveys = 10,
  double percentileThreshold = 0.9,
  DateTime Function() getNow = defaultGetNow,
}) async {
  // Get N recent surveys for this waypoint, including expired and exhausted.
  final recentSurveys = surveyData.recentSurveysAtWaypoint(
    waypointSymbol: surveyWaypointSymbol,
    count: 100,
  );
  // If we don't have enough surveys to compare, return null.
  if (recentSurveys.length < minimumSurveys) {
    return null;
  }
  // Compute the expected values of the surveys using the local market.
  // Note: this will fail if the passed market doesn't sell everything.
  // Use one minute from now as our expiration time to avoid surveys
  // expiring between when we compute the best survey and when we mine.
  final oneMinuteFromNow = getNow().add(const Duration(minutes: 1));
  final valuedSurveys = recentSurveys.map((s) {
    return _ValuedSurvey(
      expectedValue: expectedValueFromSurvey(
        marketPrices,
        s.survey,
        marketSymbol: nearbyMarketSymbol,
      ),
      survey: s.survey,
      isActive: !s.exhausted && s.survey.expiration.isAfter(oneMinuteFromNow),
    );
  }).sortedBy<num>((s) => s.expectedValue);
  // Find the index at the desired percentile threshold.
  final percentileIndex = (valuedSurveys.length * percentileThreshold).floor();
  // If we have active survey which is above the threshold, return it.
  final best =
      valuedSurveys.sublist(percentileIndex).lastWhereOrNull((s) => s.isActive);

  // if (best != null) {
  //   final survey = best.survey;
  //   logger.info(
  //     'Selected '
  //     '${survey.signature} ${survey.size} '
  //     '${survey.deposits.map((d) => d.symbol).join(', ')} '
  //     '${best.expectedValue}c',
  //   );
  // }
  return best?.survey;
}

/// Apply the miner behavior to the ship.
Future<DateTime?> advanceMiner(
  Api api,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  assert(!ship.isInTransit, 'Ship ${ship.symbol} is in transit');

  final currentWaypoint =
      await caches.waypoints.waypoint(ship.nav.waypointSymbol);

  // It's not worth potentially waiting a minute just to get a few pieces
  // of cargo, when a surveyed mining operation could pull 10+ pieces.
  // Hence selling when we're down to 15 or fewer spaces.
  // This eventually should be dependent on market availability.
  // How much to expect:
  // https://discord.com/channels/792864705139048469/1106265069630804019/1112585073712173086
  final shouldSell = ship.availableSpace < 15;
  if (shouldSell) {
    // Sell cargo and refuel if needed.
    final currentMarket =
        await visitLocalMarket(api, caches, currentWaypoint, ship);
    if (currentMarket != null) {
      await sellAllCargoAndLog(
        api,
        caches.marketPrices,
        caches.transactions,
        caches.agent,
        currentMarket,
        ship,
      );
      // This could also compare before cargo and after cargo and call
      // a change success.  That would allow ships to mine even when they have
      // cargo which is otherwise hard to sell.
      if (ship.cargo.isEmpty) {
        // Success!  We mined and sold all our cargo!
        // Reset our state now that we've mined + sold once.
        await centralCommand.completeBehavior(ship.symbol);
        return null;
      }
      shipWarn(ship, 'Failed to sell some cargo, trying a different market.');
    } else {
      shipInfo(
        ship,
        'No market at ${currentWaypoint.symbol}, navigating to nearest.',
      );
    }

    final largestCargo = ship.largestCargo();
    final nearestMarket = await nearbyMarketWhichTrades(
      caches.systems,
      caches.waypoints,
      caches.markets,
      currentWaypoint,
      largestCargo!.symbol,
    );
    if (nearestMarket == null) {
      await centralCommand.disableBehaviorForShip(
        ship,
        Behavior.miner,
        'No nearby market which trades ${largestCargo.symbol}.',
        const Duration(hours: 1),
      );
      return null;
    }
    return beingNewRouteAndLog(
      api,
      ship,
      caches.systems,
      caches.systemConnectivity,
      caches.jumps,
      centralCommand,
      nearestMarket.symbol,
    );
  }

  final mineSymbol = centralCommand.mineSymbolForShip(caches.systems, ship);
  if (mineSymbol == null) {
    await centralCommand.disableBehaviorForShip(
      ship,
      Behavior.miner,
      'No desired mine for ship.',
      const Duration(hours: 1),
    );
    return null;
  }
  if (ship.nav.waypointSymbol != mineSymbol) {
    return beingNewRouteAndLog(
      api,
      ship,
      caches.systems,
      caches.systemConnectivity,
      caches.jumps,
      centralCommand,
      mineSymbol,
    );
  }

  /// This could be an assert, since central command told us to be here.
  if (!currentWaypoint.canBeMined) {
    await centralCommand.disableBehaviorForShip(
      ship,
      Behavior.miner,
      "${waypointDescription(currentWaypoint)} can't be mined.",
      const Duration(hours: 1),
    );
    return null;
  }
  // This is wrong, we don't know if this market will be able to sell
  // the goods we can mine.
  final nearestMarket = await nearestWaypointWithMarket(
    caches.waypoints,
    currentWaypoint,
  );
  if (nearestMarket == null) {
    await centralCommand.disableBehaviorForShip(
      ship,
      Behavior.miner,
      'No nearby market for ${waypointDescription(currentWaypoint)}.',
      const Duration(hours: 1),
    );
    return null;
  }

  // Both surveying and mining require being undocked.
  await undockIfNeeded(api, ship);

  // See if we have a good survey to mine.
  final maybeSurvey = await surveyWorthMining(
    caches.marketPrices,
    caches.surveys,
    surveyWaypointSymbol: currentWaypoint.symbol,
    nearbyMarketSymbol: nearestMarket.symbol,
  );
  // If not, add some new surveys.
  if (maybeSurvey == null && ship.hasSurveyor) {
    final outer = await api.fleet.createSurvey(ship.symbol);
    final response = outer!.data;
    // shipDetail(ship, '🔭 ${ship.nav.waypointSymbol}');
    await caches.surveys.recordSurveys(response.surveys, getNow: getNow);
    return response.cooldown.expiration;
  }

  // If we either have a survey or don't have a surveyer, mine.
  try {
    final response = await extractResources(api, ship, survey: maybeSurvey);
    final yield_ = response.extraction.yield_;
    final cargo = response.cargo;
    // Could use TradeSymbol.values.reduce() to find the longest symbol.
    shipDetail(
        ship,
        // pickaxe requires an extra space on mac?
        '⛏️  ${yield_.units.toString().padLeft(2)} '
        '${yield_.symbol.value.padRight(18)} '
        // Space after emoji is needed on windows to not bleed together.
        '📦 ${cargo.units.toString().padLeft(2)}/${cargo.capacity}');
    // We could sell here before putting ourselves to sleep.
    return response.cooldown.expiration;
  } on ApiException catch (e) {
    if (isSurveyExhaustedException(e)) {
      // If the survey is exhausted, record it as such and try again.
      shipDetail(ship, 'Survey ${maybeSurvey!.signature} exhausted.');
      await caches.surveys.markSurveyExhausted(maybeSurvey);
      return null;
    }
    // This should have been caught before using the survey, but we'll
    // just mark it exhausted and try again.
    if (isSurveyExpiredException(e)) {
      shipWarn(ship, 'Survey ${maybeSurvey!.signature} expired.');
      // It's not technically exhausted, but that's our easy way to disable
      // the survey.  We use a warning to catch if we're doing this often.
      await caches.surveys.markSurveyExhausted(maybeSurvey);
      return null;
    }
    rethrow;
  }
}
