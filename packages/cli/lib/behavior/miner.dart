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

// https://discord.com/channels/792864705139048469/792864705139048472/1112766963601645628
// const occurenceWeightBySymbol = <String, double>{
//   'ICE_WATER': 40,
//   'SILICON_CRYSTALS': 20,
//   'QUARTZ_SAND': 20,
//   'AMMONIA_ICE': 20,
//   'SILVER_ORE': 10,
//   'IRON_ORE': 10,
//   'COPPER_ORE': 10,
//   'ALUMINUM_ORE': 10,
//   'GOLD_ORE': 4,
//   'PLATINUM_ORE': 4,
//   'DIAMONDS': 0.2,
// };

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

/// Want to find systems which have both a mineable resource and a marketplace.
/// Want to sort by distance between the two.
/// As well as relative prices for the market.
/// Might also want to consider what resources the mine produces and if the
/// market buys them.

class _MineAndSell {
  _MineAndSell({
    required this.mineSymbol,
    required this.marketSymbol,
    required this.marketPercentile,
    required this.distanceBetweenMineAndMarket,
  });

  final String mineSymbol;
  final String marketSymbol;
  final int marketPercentile;
  final int distanceBetweenMineAndMarket;

  int get score {
    final creditsAboveAverage = marketPercentile - 50;
    final distancePenalty = distanceBetweenMineAndMarket;
    // The primary thing we care about is market percentile.
    // Distances other than 0 have a fuel cost associated with them.
    // Which would need to be made up by the market percentile?
    // Maybe this is just estimated profit per second?
    // Which then will be dominated by the presence of certain resources.
    return creditsAboveAverage - distancePenalty;
  }
}

class _SystemEval {
  _SystemEval({
    required this.systemSymbol,
    required this.jumps,
    required this.mineAndSells,
  });

  final String systemSymbol;
  final int jumps;
  final List<_MineAndSell> mineAndSells;

  int? get score {
    if (mineAndSells.isEmpty) {
      return null;
    }
    // This assumes these are sorted.
    return mineAndSells.last.score;
  }
}

int? _marketPercentile(
  MarketPrices marketPrices,
  Market market, {
  required String tradeSymbol,
}) {
  final sellPrice = estimateSellPrice(marketPrices, market, tradeSymbol);
  if (sellPrice == null) {
    return null;
  }
  return marketPrices.percentileForSellPrice(
    tradeSymbol,
    sellPrice,
  );
}

Future<_SystemEval> _evaluateSystem(
  Api api,
  MarketPrices marketPrices,
  WaypointCache waypointCache,
  MarketCache marketCache, {
  required String tradeSymbol,
  required String systemSymbol,
  required int jumps,
}) async {
  final waypoints = await waypointCache.waypointsInSystem(systemSymbol);
  final marketWaypoints = waypoints.where((w) => w.hasMarketplace);
  final markets = await marketCache.marketsInSystem(systemSymbol).toList();
  final marketToPercentile = {
    for (var m in markets)
      m.symbol: _marketPercentile(marketPrices, m, tradeSymbol: tradeSymbol),
  };
  final mines = waypoints.where((w) => w.canBeMined);
  final mineAndSells = <_MineAndSell>[];
  for (final mine in mines) {
    for (final market in marketWaypoints) {
      final marketPercentile = marketToPercentile[market.symbol];
      if (marketPercentile == null) {
        continue;
      }
      final distance = mine.distanceTo(market);
      mineAndSells.add(
        _MineAndSell(
          mineSymbol: mine.symbol,
          marketSymbol: market.symbol,
          marketPercentile: marketPercentile,
          distanceBetweenMineAndMarket: distance,
        ),
      );
    }
  }
  mineAndSells.sortBy<num>((m) => m.score);
  return _SystemEval(
    systemSymbol: systemSymbol,
    jumps: jumps,
    mineAndSells: mineAndSells,
  );
}

String _describeSystemEval(_SystemEval eval) {
  return '${eval.systemSymbol}: ${eval.jumps} jumps ${eval.score}';
}

/// Find nearest mine with good mining.
Future<String?> nearestMineWithGoodMining(
  Api api,
  MarketPrices marketPrices,
  SystemsCache systemsCache,
  WaypointCache waypointCache,
  MarketCache marketCache,
  Waypoint start, {
  required String tradeSymbol,
  required int maxJumps,
  bool Function(String systemSymbol)? systemFilter,
}) async {
  // TODO(eseidel): These evals should be cached on centralCommand.
  final evals = <_SystemEval>[];
  for (final (systemSymbol, jumps) in systemsCache.systemSymbolsInJumpRadius(
    startSystem: start.systemSymbol,
    maxJumps: maxJumps,
  )) {
    if (systemFilter != null && !systemFilter(systemSymbol)) {
      continue;
    }
    final eval = await _evaluateSystem(
      api,
      marketPrices,
      waypointCache,
      marketCache,
      tradeSymbol: tradeSymbol,
      systemSymbol: systemSymbol,
      jumps: jumps,
    );
    logger.info(
      _describeSystemEval(eval),
    );
    // Want to know if the market buys what the mine produces?
    if (eval.score != null) {
      evals.add(eval);
    }
  }
  final sorted = evals.sortedBy<num>((e) => e.score!);
  final best = sorted.lastOrNull;
  if (best == null) {
    return null;
  }
  return best.mineAndSells.last.mineSymbol;
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

Future<DateTime?> _navigateToNewSystemForMining(
  Api api,
  MarketPrices marketPrices,
  Ship ship,
  SystemsCache systemsCache,
  WaypointCache waypointCache,
  MarketCache marketCache,
  CentralCommand centralCommand,
  Waypoint currentWaypoint, {
  int maxJumps = 5,
}) async {
  final mine = await nearestMineWithGoodMining(
    api,
    marketPrices,
    systemsCache,
    waypointCache,
    marketCache,
    currentWaypoint,
    maxJumps: maxJumps,
    tradeSymbol: 'PRECIOUS_STONES',
  );
  if (mine == null) {
    await centralCommand.disableBehaviorForShip(
      ship,
      Behavior.miner,
      'No good mining system found in '
      '$maxJumps radius of ${ship.nav.systemSymbol}.',
      const Duration(hours: 1),
    );
    return null;
  }

  // Otherwise navigate to our new mine.
  return beingRouteAndLog(
    api,
    ship,
    systemsCache,
    centralCommand,
    mine,
  );
}

// This could be fancier and pick one actually nearby, instead it just
// returns the first.
SystemWaypoint? _nearbyMineWithinSystem(
  SystemsCache systemsCache,
  String systemSymbol,
) {
  final systemWaypoints = systemsCache.waypointsInSystem(systemSymbol);
  return systemWaypoints.firstWhereOrNull((w) => w.canBeMined);
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
          'No marketplace at ${currentWaypoint.symbol}, '
          'navigating to nearest marketplace.');
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
    return beingRouteAndLog(
      api,
      ship,
      caches.systems,
      centralCommand,
      nearestMarket.symbol,
    );
  }

  if (!currentWaypoint.canBeMined) {
    shipInfo(
      ship,
      "${waypointDescription(currentWaypoint)} can't be mined, navigating "
      'to nearest asteroid field.',
    );
    // We're not at an asteroid field, so we need to navigate to one.
    final nearbyMine =
        _nearbyMineWithinSystem(caches.systems, ship.nav.systemSymbol);
    if (nearbyMine != null) {
      return navigateToLocalWaypointAndLog(api, ship, nearbyMine);
    }
    shipWarn(
      ship,
      'No minable waypoint in ${ship.nav.systemSymbol}, '
      'finding nearby system with best mining.',
    );
    return _navigateToNewSystemForMining(
      api,
      caches.marketPrices,
      ship,
      caches.systems,
      caches.waypoints,
      caches.markets,
      centralCommand,
      currentWaypoint,
    );
  }
  // This is wrong, we don't know if this market will be able to sell
  // the goods we can mine.
  final nearestMarket = await nearestWaypointWithMarket(
    caches.waypoints,
    currentWaypoint,
  );
  if (nearestMarket == null) {
    shipWarn(
      ship,
      'No nearby market, navigating to new system for mining.',
    );
    return _navigateToNewSystemForMining(
      api,
      caches.marketPrices,
      ship,
      caches.systems,
      caches.waypoints,
      caches.markets,
      centralCommand,
      currentWaypoint,
    );
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
    try {
      final outer = await api.fleet.createSurvey(ship.symbol);
      final response = outer!.data;
      // shipDetail(ship, '🔭 ${ship.nav.waypointSymbol}');
      // Record survey.
      await caches.surveys.recordSurveys(response.surveys, getNow: getNow);
      // Wait for cooldown.
      return response.cooldown.expiration;
    } on ApiException catch (e) {
      // 500 doesn't make sense, but there is a current issue:
      // https://github.com/SpaceTradersAPI/api-docs/issues/62
      if (e.code == 500) {
        shipWarn(ship, 'Survey failed, with 500 error, moving systems.');
        return _navigateToNewSystemForMining(
          api,
          caches.marketPrices,
          ship,
          caches.systems,
          caches.waypoints,
          caches.markets,
          centralCommand,
          currentWaypoint,
        );
      }
      rethrow;
    }
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
