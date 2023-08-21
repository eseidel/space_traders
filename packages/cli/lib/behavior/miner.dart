import 'dart:math';

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
import 'package:db/db.dart';
import 'package:types/types.dart';

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
  required WaypointSymbol marketSymbol,
}) {
  // I'm not yet sure what to do with deposit size.
  // Look at each of the possible returns.
  // Price them at the passed in market.
  // This will fail if the passed in market doesn't sell everything.

  final totalValue = survey.deposits.fold<int>(0, (total, deposit) {
    final sellPrice = marketPrices.recentSellPrice(
          deposit.tradeSymbol,
          marketSymbol: marketSymbol,
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
    startSystem: start.systemSymbolObject,
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
  Database db,
  MarketPrices marketPrices, {
  required WaypointSymbol surveyWaypointSymbol,
  required WaypointSymbol nearbyMarketSymbol,
  int minimumSurveys = 10,
  double percentileThreshold = 0.9,
  DateTime Function() getNow = defaultGetNow,
}) async {
  // Get N recent surveys for this waypoint, including expired and exhausted.
  final recentSurveys = await db.recentSurveysAtWaypoint(
    surveyWaypointSymbol,
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
  final valuedSurveys = recentSurveys
      .map((s) {
        return _ValuedSurvey(
          expectedValue: expectedValueFromSurvey(
            marketPrices,
            s.survey,
            marketSymbol: nearbyMarketSymbol,
          ),
          survey: s.survey,
          isActive:
              !s.exhausted && s.survey.expiration.isAfter(oneMinuteFromNow),
        );
      })
      .toList()
      .sortedBy<num>((s) => s.expectedValue);
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
  //     '${creditsString(best.expectedValue)}',
  //   );
  // }
  return best?.survey;
}

final _laserMountSymbols = {
  ShipMountSymbolEnum.MINING_LASER_I,
  ShipMountSymbolEnum.MINING_LASER_II,
  ShipMountSymbolEnum.MINING_LASER_III,
};

int _laserMountStrength(Ship ship) {
  return ship.mounts.fold(0, (sum, m) {
    if (_laserMountSymbols.contains(m.symbol)) {
      return sum + (m.strength ?? 0);
    }
    return sum;
  });
}

// https://discord.com/channels/792864705139048469/792864705139048472/1132761138849923092
// "Each laser adds its strength +-5. Power is 10 for laser I, 25 for laser II,
// 60 for laser III. So for example laser I plus laser II is 35 +- 10"
/// Compute the maximum number of units we can expect from an extraction.
int maxExtractedUnits(Ship ship) {
  var laserStrength = 0;
  var variance = 0;
  for (final mount in ship.mounts) {
    if (_laserMountSymbols.contains(mount.symbol)) {
      final strength = mount.strength;
      // We could log here, this should never happen.
      if (strength == null) {
        continue;
      }
      laserStrength += strength;
      variance += 5;
    }
  }
  return min(laserStrength + variance, ship.cargo.capacity);
}

/// Extract resources from a mine.
class MineJob {
  /// Create a new mine job.
  MineJob({required this.mine, required this.market});

  /// The mine to extract from.
  final WaypointSymbol mine;

  /// The market to value goods against.
  final WaypointSymbol market;
}

// Miner stages
// - Empty cargo if needed
// - Navigate to mine
// - Survey if needed
// - Mine
// - Handle cargo (navigate to market, sell, jettison, etc)
// - Navigate to market

/// Apply the miner behavior to the ship.
Future<DateTime?> advanceMiner(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  BehaviorState state,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final currentWaypoint = await caches.waypoints.waypoint(ship.waypointSymbol);

  // Sell if our next extraction could overflow our cargo.
  if (ship.availableSpace < maxExtractedUnits(ship)) {
    // Sell cargo and refuel if needed.
    final currentMarket =
        await visitLocalMarket(api, db, caches, currentWaypoint, ship);
    if (currentMarket != null) {
      await sellAllCargoAndLog(
        api,
        db,
        caches.marketPrices,
        caches.agent,
        currentMarket,
        ship,
        AccountingType.goods,
      );
      // This could also compare before cargo and after cargo and call
      // a change success.  That would allow ships to mine even when they have
      // cargo which is otherwise hard to sell.
      if (ship.cargo.isEmpty) {
        // Success!  We mined and sold all our cargo!
        // Reset our state now that we've mined + sold once.
        state.isComplete = true;
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
    final nearestMarket = assertNotNull(
      await nearbyMarketWhichTrades(
        caches.systems,
        caches.waypoints,
        caches.markets,
        currentWaypoint.waypointSymbol,
        largestCargo!.tradeSymbol,
      ),
      'No nearby market which trades ${largestCargo.symbol}.',
      const Duration(hours: 1),
    );
    return beingNewRouteAndLog(
      api,
      ship,
      state,
      caches.ships,
      caches.systems,
      caches.routePlanner,
      centralCommand,
      nearestMarket.waypointSymbol,
    );
  }

  final mineJob =
      centralCommand.mineJobForShip(caches.systems, caches.agent, ship);
  final mineSymbol = mineJob.mine;
  final marketSymbol = mineJob.market;

  if (ship.waypointSymbol != mineSymbol) {
    return beingNewRouteAndLog(
      api,
      ship,
      state,
      caches.ships,
      caches.systems,
      caches.routePlanner,
      centralCommand,
      mineSymbol,
    );
  }

  jobAssert(
    currentWaypoint.canBeMined,
    "${waypointDescription(currentWaypoint)} can't be mined.",
    const Duration(hours: 1),
  );

  // Both surveying and mining require being undocked.
  await undockIfNeeded(api, caches.ships, ship);

  // See if we have a good survey to mine.
  final maybeSurvey = await surveyWorthMining(
    db,
    caches.marketPrices,
    surveyWaypointSymbol: currentWaypoint.waypointSymbol,
    nearbyMarketSymbol: marketSymbol,
    minimumSurveys: centralCommand.minimumSurveys,
    percentileThreshold: centralCommand.surveyPercentileThreshold,
  );
  // If not, add some new surveys.
  if (maybeSurvey == null && ship.hasSurveyor) {
    final response = await surveyAndLog(api, db, ship, getNow: getNow);
    // Count completion of survey as a success, otherwise we could end up
    // surveying for a long time before checking other behaviors.
    // We don't need to do this for miners since they don't change as often.
    if (ship.isCommand) {
      state.isComplete = true;
    }
    // We wait the full cooldown because our next action will be either
    // surveying or mining, both of which require the reactor cooldown.
    return response.cooldown.expiration;
  }

  // If we either have a survey or don't have a surveyer, mine.
  try {
    final response = await extractResources(api, ship, survey: maybeSurvey);
    final yield_ = response.extraction.yield_;
    final cargo = response.cargo;
    await db.insertExtraction(
      ExtractionRecord(
        shipSymbol: ship.shipSymbol,
        waypointSymbol: mineSymbol,
        tradeSymbol: yield_.symbol,
        quantity: yield_.units,
        power: _laserMountStrength(ship),
        surveySignature: maybeSurvey?.signature,
        timestamp: getNow(),
      ),
    );
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
    /// ApiException 400: {"error":{"message":
    /// Ship ESEIDEL-1B does not have a required mining laser mount.",
    /// "code":4243,"data":{"shipSymbol":"ESEIDEL-1B",
    /// "miningLasers":["MOUNT_MINING_LASER_I","MOUNT_MINING_LASER_II",
    /// "MOUNT_MINING_LASER_III"]}}}

    if (isSurveyExhaustedException(e)) {
      // If the survey is exhausted, record it as such and try again.
      shipDetail(ship, 'Survey ${maybeSurvey!.signature} exhausted.');
      await db.markSurveyExhausted(maybeSurvey);
      return null;
    }
    // This should have been caught before using the survey, but we'll
    // just mark it exhausted and try again.
    if (isSurveyExpiredException(e)) {
      shipWarn(ship, 'Survey ${maybeSurvey!.signature} expired.');
      // It's not technically exhausted, but that's our easy way to disable
      // the survey.  We use a warning to catch if we're doing this often.
      await db.markSurveyExhausted(maybeSurvey);
      return null;
    }
    rethrow;
  }
}
