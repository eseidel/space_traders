import 'package:collection/collection.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/behavior/navigation.dart';
import 'package:space_traders_cli/behavior/trading.dart';
import 'package:space_traders_cli/data_store.dart';
import 'package:space_traders_cli/exceptions.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/route.dart';
import 'package:space_traders_cli/surveys.dart';
import 'package:space_traders_cli/systems_cache.dart';
import 'package:space_traders_cli/transactions.dart';
import 'package:space_traders_cli/waypoint_cache.dart';

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
  PriceData priceData,
  Waypoint market,
  Survey survey,
) {
  // I'm not yet sure what to do with deposit size.
  // Look at each of the possible returns.
  // Price them at the passed in market.
  // This will fail if the passed in market doesn't sell everything.

  final totalValue = survey.deposits.fold<int>(
    0,
    (total, deposit) =>
        total +
        priceData.recentSellPrice(
          marketSymbol: market.symbol,
          tradeSymbol: deposit.symbol,
        )!,
  );
  return totalValue ~/ survey.deposits.length;
}

/// Returns the nearest waypoint with a marketplace.
Future<Waypoint> nearestWaypointWithMarket(
  SystemsCache systemsCache,
  WaypointCache waypointCache,
  Waypoint start,
) async {
  if (start.hasMarketplace) {
    return start;
  }
  await for (final waypoint in waypointsInJumpRadius(
    systemsCache: systemsCache,
    waypointCache: waypointCache,
    startSystem: start.systemSymbol,
    maxJumps: 1,
  )) {
    if (waypoint.hasMarketplace) {
      return waypoint;
    }
  }
  throw Exception(
    'No waypoints with marketplaces found in jump radius of ${start.symbol}',
  );
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

int? _marketPercentile(PriceData priceData, Market market) {
  const tradeSymbol = 'ICE_WATER';
  final sellPrice = estimateSellPrice(priceData, market, tradeSymbol);
  if (sellPrice == null) {
    return null;
  }
  return priceData.percentileForSellPrice(
    tradeSymbol,
    sellPrice,
  );
}

Future<_SystemEval> _evaluateSystem(
  Api api,
  PriceData priceData,
  WaypointCache waypointCache,
  MarketCache marketCache,
  String systemSymbol,
  int jumps,
) async {
  final waypoints = await waypointCache.waypointsInSystem(systemSymbol);
  final marketWaypoints = waypoints.where((w) => w.hasMarketplace);
  final markets = await marketCache.marketsInSystem(systemSymbol).toList();
  final marketToPercentile = {
    for (var m in markets) m.symbol: _marketPercentile(priceData, m),
  };
  final mines = waypoints.where((w) => w.canBeMined);
  final mineAndSells = <_MineAndSell>[];
  for (final mine in mines) {
    for (final market in marketWaypoints) {
      final marketPercentile = marketToPercentile[market.symbol];
      if (marketPercentile == null) {
        continue;
      }
      final distance = distanceBetweenWaypointsInSystem(
        mine,
        market,
      );
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
  PriceData priceData,
  SystemsCache systemsCache,
  WaypointCache waypointCache,
  MarketCache marketCache,
  Waypoint start,
  int maxJumps, {
  bool Function(String systemSymbol)? systemFilter,
}) async {
  final evals = <_SystemEval>[];
  await for (final (systemSymbol, jumps) in systemSymbolsInJumpRadius(
    systemsCache: systemsCache,
    startSystem: start.systemSymbol,
    maxJumps: maxJumps,
  )) {
    if (systemFilter != null && !systemFilter(systemSymbol)) {
      continue;
    }
    final eval = await _evaluateSystem(
      api,
      priceData,
      waypointCache,
      marketCache,
      systemSymbol,
      jumps,
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
  PriceData priceData,
  SurveyData surveyData,
  Waypoint waypoint, {
  double percentileThreshold = 0.9,
}) async {
  // Get N recent surveys for this waypoint, including expired and exhausted.
  final recentSurveys = surveyData.recentSurveysAtWaypoint(
    waypointSymbol: waypoint.symbol,
    count: 100,
  );
  // If we don't have enough surveys to compare, return null.
  if (recentSurveys.length < 10) {
    return null;
  }
  // Compute the expected values of the surveys using the local market.
  // Note: this will fail if the passed market doesn't sell everything.
  final now = DateTime.now().toUtc();
  final valuedSurveys = recentSurveys.map((s) {
    return _ValuedSurvey(
      expectedValue: expectedValueFromSurvey(priceData, waypoint, s.survey),
      survey: s.survey,
      isActive: !s.exhausted && s.survey.expiration.isAfter(now),
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
  DataStore db,
  PriceData priceData,
  Agent agent,
  Ship ship,
  SystemsCache systemsCache,
  WaypointCache waypointCache,
  MarketCache marketCache,
  TransactionLog transactionLog,
  BehaviorManager behaviorManager,
  SurveyData surveyData,
) async {
  final navResult = await continueNavigationIfNeeded(
    api,
    ship,
    systemsCache,
    behaviorManager,
  );
  if (navResult.shouldReturn()) {
    return navResult.waitTime;
  }
  final currentWaypoint = await waypointCache.waypoint(ship.nav.waypointSymbol);

  // It's not worth potentially waiting a minute just to get a few pieces
  // of cargo, when a surveyed mining operation could pull 10+ pieces.
  // Hence selling when we're down to 15 or fewer spaces.
  // This eventually should be dependent on market availability.
  // How much to expect:
  // https://discord.com/channels/792864705139048469/1106265069630804019/1112585073712173086
  final shouldSell = ship.availableSpace < 15;
  if (shouldSell) {
    // Sell cargo and refuel if needed.
    if (currentWaypoint.hasMarketplace) {
      final cargoBefore = ship.cargo.units;
      await dockIfNeeded(api, ship);
      final market = await recordMarketDataIfNeededAndLog(
        priceData,
        marketCache,
        ship,
        currentWaypoint.symbol,
      );
      await refuelIfNeededAndLog(
        api,
        priceData,
        transactionLog,
        agent,
        market,
        ship,
      );

      await sellAllCargoAndLog(api, priceData, transactionLog, ship);
      if (cargoBefore != ship.cargo.units) {
        // Success!  We mined and sold our cargo!
        // Reset our state now that we've done the behavior once.
        await behaviorManager.completeBehavior(ship.symbol);
        // This return null maybe wrong if we failed to sell?
        return null;
      }
      shipWarn(ship, 'Failed to sell cargo, trying a different market.');
    } else {
      shipInfo(
          ship,
          'No marketplace at ${currentWaypoint.symbol}, '
          'navigating to nearest marketplace.');
    }

    final largestCargo = ship.largestCargo();
    final nearestMarket = await nearbyMarketWhichTrades(
      systemsCache,
      waypointCache,
      marketCache,
      currentWaypoint,
      largestCargo!.symbol,
    );
    if (nearestMarket == null) {
      shipWarn(
        ship,
        'No nearby market which trades ${largestCargo.symbol}, '
        'disabling miner behavior.',
      );
      await behaviorManager.disableBehavior(ship, Behavior.miner);
      return null;
    }
    return beingRouteAndLog(
      api,
      ship,
      systemsCache,
      behaviorManager,
      nearestMarket.symbol,
    );
  }

  if (!currentWaypoint.canBeMined) {
    shipInfo(
      ship,
      "${waypointShortString(currentWaypoint)} can't be mined, navigating "
      'to nearest asteroid field.',
    );
    // We're not at an asteroid field, so we need to navigate to one.
    final systemWaypoints =
        systemsCache.waypointsInSystem(ship.nav.systemSymbol);
    final maybeAsteroidField =
        systemWaypoints.firstWhereOrNull((w) => w.canBeMined);

    if (maybeAsteroidField != null) {
      return navigateToLocalWaypointAndLog(api, ship, maybeAsteroidField);
    }
    // TODO(eseidel): This should instead find the nearest minable system.
    shipWarn(
      ship,
      'No minable waypoint in ${ship.nav.systemSymbol}, '
      'finding nearby system with best mining.',
    );
    const maxJumps = 10;
    final mine = await nearestMineWithGoodMining(
      api,
      priceData,
      systemsCache,
      waypointCache,
      marketCache,
      currentWaypoint,
      maxJumps,
    );
    if (mine == null) {
      shipWarn(
        ship,
        'No good mining system found in '
        '$maxJumps radius of ${ship.nav.systemSymbol}',
      );
      await behaviorManager.disableBehavior(ship, Behavior.miner);
      return null;
    }

    // Otherwise navigate to our new mine.
    return beingRouteAndLog(
      api,
      ship,
      systemsCache,
      behaviorManager,
      mine,
    );
  }

  // If we still have space, mine.
  // Must be undocked before surveying or mining.
  await undockIfNeeded(api, ship);
  // Load a survey set, or if we have surveying capabilities, survey.

  // Load up survey set for this waypoint.
  // If it has an non-expired survey which is worth mining, mine it.
  // A survey is worth mining when it's expected value is greater than
  // 70% of previous surveys.
  // Otherwise add a new survey.

  final nearestMarket = await nearestWaypointWithMarket(
    systemsCache,
    waypointCache,
    currentWaypoint,
  );

  // See if we have a good survey to mine.
  final maybeSurvey = await surveyWorthMining(
    priceData,
    surveyData,
    nearestMarket,
  );
  // If not, add some new surveys.
  if (maybeSurvey == null && ship.hasSurveyor) {
    try {
      final outer = await api.fleet.createSurvey(ship.symbol);
      final response = outer!.data;
      // shipDetail(ship, '🔭 ${ship.nav.waypointSymbol}');
      // Record survey.
      await surveyData.recordSurveys(response.surveys);
      // Wait for cooldown.
      return response.cooldown.expiration;
    } on ApiException catch (e) {
      // 500 doesn't make sense, but there is a current issue:
      // https://github.com/SpaceTradersAPI/api-docs/issues/62
      if (e.code == 500) {
        shipWarn(ship, 'Survey failed, with 500 error, moving systems.');
        final mineSymbol = await nearestMineWithGoodMining(
          api,
          priceData,
          systemsCache,
          waypointCache,
          marketCache,
          nearestMarket,
          5,
          systemFilter: (systemSymbol) => systemSymbol != ship.nav.systemSymbol,
        );
        if (mineSymbol != null) {
          return beingRouteAndLog(
            api,
            ship,
            systemsCache,
            behaviorManager,
            mineSymbol,
          );
        } else {
          shipWarn(
            ship,
            'No good mining system found in 5 radius of '
            '${ship.nav.systemSymbol}, disabling miner behavior.',
          );
          await behaviorManager.disableBehavior(ship, Behavior.miner);
          return null;
        }
      }
      rethrow;
    }
  }

  /// If we either have a survey or don't have a surveyer, mine.
  try {
    final response = await extractResources(api, ship, survey: maybeSurvey);
    final yield_ = response.extraction.yield_;
    final cargo = response.cargo;
    // Could use TradeSymbol.values.reduce() to find the longest symbol.
    shipDetail(
        ship,
        // pickaxe requires an extra space on mac?
        '⛏️  ${yield_.units.toString().padLeft(2)} '
        '${yield_.symbol.padRight(18)} '
        // Space after emoji is needed on windows to not bleed together.
        '📦 ${cargo.units.toString().padLeft(2)}/${cargo.capacity}');
    // We could sell here before putting ourselves to sleep.
    return response.cooldown.expiration;
  } on ApiException catch (e) {
    if (isExhaustedSurveyException(e)) {
      // If the survey is exhausted, record it as such and try again.
      shipDetail(ship, 'Survey ${maybeSurvey!.signature} exhausted.');
      await surveyData.markSurveyExhausted(maybeSurvey);
      return null;
    }
    rethrow;
  }
}
