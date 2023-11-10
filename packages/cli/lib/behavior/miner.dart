import 'dart:math';

import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/exploring.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/net/exceptions.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';
import 'package:collection/collection.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// This is mostly used for reference.
final kOreHoundDefault = ShipTemplate(
  frameSymbol: ShipFrameSymbolEnum.MINER,
  mounts: MountSymbolSet.from([
    ShipMountSymbolEnum.MINING_LASER_I,
    ShipMountSymbolEnum.SURVEYOR_I,
  ]),
);

// According to SAF: Surveyor = 2x mk2s,  miner = 2x mk2 + 1x mk1
/// A template for a ship which mines and surveys.
final kMineAndSurveyTemplate = ShipTemplate(
  frameSymbol: ShipFrameSymbolEnum.MINER,
  mounts: MountSymbolSet.from([
    ShipMountSymbolEnum.MINING_LASER_II,
    ShipMountSymbolEnum.MINING_LASER_II,
    ShipMountSymbolEnum.SURVEYOR_I,
  ]),
);

/// A template for a ship which only surveys.
/// Only available after we've found SURVEYOR_II modules to buy.
final kSurveyOnlyTemplate = ShipTemplate(
  frameSymbol: ShipFrameSymbolEnum.MINER,
  mounts: MountSymbolSet.from([
    ShipMountSymbolEnum.SURVEYOR_II,
    ShipMountSymbolEnum.SURVEYOR_II,
    ShipMountSymbolEnum.SURVEYOR_II,
  ]),
);

/// A template for a ship which only mines.
/// Only used after we have dedicated surveyors.
final kMineOnlyTemplate = ShipTemplate(
  frameSymbol: ShipFrameSymbolEnum.MINER,
  mounts: MountSymbolSet.from([
    ShipMountSymbolEnum.MINING_LASER_II,
    ShipMountSymbolEnum.MINING_LASER_II,
    ShipMountSymbolEnum.MINING_LASER_I,
  ]),
);

/// A group of ships which mine and survey together.
class MiningSquad {
  /// Creates a new mining squad from a list of ships.
  MiningSquad(this.ships);

  /// Determines the template to use for [ship].
  ShipTemplate templateForShip(
    Ship ship, {
    required Set<ShipMountSymbolEnum> availableMounts,
  }) {
    if (!ships.any((s) => s.symbol == ship.symbol)) {
      throw ArgumentError('Ship ${ship.symbol} not in squad.');
    }
    // If we're the only ship in this squad, we need to both mine and survey.
    if (ships.length == 1) {
      return kMineAndSurveyTemplate;
    }
    // If we have SURVEYOR_II, our first ship should be a surveyor.
    final surveyor = ships.first;
    if (surveyor.symbol == ship.symbol) {
      if (availableMounts.contains(ShipMountSymbolEnum.SURVEYOR_II)) {
        return kSurveyOnlyTemplate;
      } else {
        return kMineAndSurveyTemplate;
      }
    }
    // If our first ship has already mounted at least one surveyor, we should
    // only mine.
    if (surveyor.mountedMountSymbols
        .contains(ShipMountSymbolEnum.SURVEYOR_II)) {
      return kMineOnlyTemplate;
    }
    // Otherwise we also need to survey.
    return kMineAndSurveyTemplate;
  }

  /// Returns true if this squad contains [ship].
  bool contains(Ship ship) => ships.any((s) => s.symbol == ship.symbol);

  /// The ships in this squad.
  final List<Ship> ships;
}

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

/// A survey with an expected value against a given market.
class ValuedSurvey {
  /// Creates a new valued survey.
  ValuedSurvey({
    required this.expectedValue,
    required this.survey,
    required this.isActive,
  });

  /// The expected value of the survey.
  final int expectedValue;

  /// The survey.
  final Survey survey;

  /// True if the survey is still active (not expired or exhausted).
  final bool isActive;
}

/// Finds a recent survey
Future<List<ValuedSurvey>> surveysWorthMining(
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
  // If we don't have enough surveys to compare, return empty.
  if (recentSurveys.length < minimumSurveys) {
    return [];
  }
  // Compute the expected values of the surveys using the local market.
  // Note: this will fail if the passed market doesn't sell everything.
  // Use one minute from now as our expiration time to avoid surveys
  // expiring between when we compute the best survey and when we mine.
  final oneMinuteFromNow = getNow().add(const Duration(minutes: 1));
  final valuedSurveys = recentSurveys
      .map((s) {
        return ValuedSurvey(
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
  final best = valuedSurveys.sublist(percentileIndex);

  return best.where((s) => s.isActive).toList().reversed.toList();
}

/// Prints a survey to the log.
void printSurvey(
  Survey survey,
  MarketPrices marketPrices,
  WaypointSymbol marketSymbol,
) {
  final expectedValue =
      expectedValueFromSurvey(marketPrices, survey, marketSymbol: marketSymbol);
  logger.info(
    '${survey.signature} ${survey.size} '
    '${survey.deposits.map((d) => d.symbol).join(', ')} '
    'ev ${creditsString(expectedValue)}',
  );
}

/// Compute the number of surveys we can expect to complete with [mounts].
/// This is used when you have a template you want to know how many surveys
/// you can expect to complete with, rather than a specific ship.
int surveysExpectedPerSurveyWithMounts(
  ShipMountCache mountCache,
  MountSymbolSet mounts,
) {
  return mounts.fold(0, (sum, mountSymbol) {
    if (!kSurveyMountSymbols.contains(mountSymbol)) {
      return sum;
    }
    return sum + mountCache[mountSymbol]!.strength!;
  });
}

/// Compute the cooldown time for an extraction by [ship].
int cooldownTimeForExtraction(Ship ship) {
  final power = powerUsedByLasers(ship);
  return 60 + 10 * power;
}

/// Compute the cooldown time for a survey by [ship].
int cooldownTimeForSurvey(Ship ship) {
  final power = powerUsedBySurveyors(ship);
  return 60 + 10 * power;
}

// https://discord.com/channels/792864705139048469/792864705139048472/1132761138849923092
// "Each laser adds its strength +-5. Power is 10 for laser I, 25 for laser II,
// 60 for laser III. So for example laser I plus laser II is 35 +- 10"
/// Compute the maximum number of units we can expect from an extraction.
int maxExtractedUnits(Ship ship) {
  const variancePerLaser = 5;
  return min(
    ship.cargo.capacity,
    expectedExtractedUnits(ship) +
        ship.mountedMiningLasers.length * variancePerLaser,
  );
}

/// Compute the number of units we can expect from an extraction.
int expectedExtractedUnits(Ship ship) {
  return min(
    ship.cargo.capacity,
    ship.mountedMiningLasers.map((m) => m.strength!).sum,
  );
}

int _minSpaceForExtraction(Ship ship) {
  // Currently we'd rather overflow occasionally, than waste time and fuel.
  return expectedExtractedUnits(ship);
}

/// Tell [ship] to extract resources and log the result.
Future<JobResult> extractAndLog(
  Api api,
  Database db,
  Ship ship,
  ShipCache shipCache,
  Survey? maybeSurvey, {
  required DateTime Function() getNow,
}) async {
  // If we somehow got into a bad state, just complete this job and loop.
  jobAssert(
    ship.availableSpace >= _minSpaceForExtraction(ship),
    'Not enough space (${ship.availableSpace}) to extract '
    '(expecting ${_minSpaceForExtraction(ship)})',
    const Duration(minutes: 1),
  );

  // If we either have a survey or don't have a surveyor, mine.
  try {
    final ExtractResources201ResponseData response;
    if (maybeSurvey != null) {
      response =
          await extractResourcesWithSurvey(api, ship, shipCache, maybeSurvey);
    } else {
      response = await extractResources(api, ship, shipCache);
    }
    final yield_ = response.extraction.yield_;
    final cargo = response.cargo;
    final laserStrength = laserMountStrength(ship);
    await db.insertExtraction(
      ExtractionRecord(
        shipSymbol: ship.shipSymbol,
        waypointSymbol: ship.waypointSymbol,
        tradeSymbol: yield_.symbol,
        quantity: yield_.units,
        power: laserStrength,
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

    verifyCooldown(
      ship,
      'Extraction',
      cooldownTimeForExtraction(ship),
      response.cooldown,
    );

    // If we still have space wait the cooldown and continue mining.
    if (ship.availableSpace >= _minSpaceForExtraction(ship)) {
      return JobResult.wait(response.cooldown.expiration);
    }
    // Complete this job (go sell) if an extraction could overflow our cargo.
    return JobResult.complete();
  } on ApiException catch (e) {
    if (isSurveyExhaustedException(e)) {
      // If the survey is exhausted, record it as such and try again.
      shipInfo(ship, 'Survey ${maybeSurvey!.signature} exhausted.');
      await db.markSurveyExhausted(maybeSurvey);
      return JobResult.wait(null);
    }
    // This should have been caught before using the survey, but we'll
    // just mark it exhausted and try again.
    if (isSurveyExpiredException(e)) {
      shipWarn(ship, 'Survey ${maybeSurvey!.signature} expired.');
      // It's not technically exhausted, but that's our easy way to disable
      // the survey.  We use a warning to catch if we're doing this often.
      await db.markSurveyExhausted(maybeSurvey);
      return JobResult.wait(null);
    }
    // https://discord.com/channels/792864705139048469/1168786078866604053
    if (isAPIExceptionWithCode(e, 4228)) {
      shipWarn(ship, 'Spurious cargo warning, retrying.');
      return JobResult.wait(null);
    }
    rethrow;
  }
}

/// Execute the MineJob.
Future<JobResult> doMineJob(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final mineJob =
      assertNotNull(state.mineJob, 'No mine job.', const Duration(hours: 1));
  final mineSymbol = mineJob.mine;
  final marketSymbol = mineJob.market;

  if (ship.waypointSymbol != mineSymbol) {
    final waitTime = await beingNewRouteAndLog(
      api,
      db,
      centralCommand,
      caches,
      ship,
      state,
      mineSymbol,
    );
    return JobResult.wait(waitTime);
  }

  final currentWaypoint = await caches.waypoints.waypoint(ship.waypointSymbol);
  jobAssert(
    currentWaypoint.canBeMined,
    "${waypointDescription(currentWaypoint)} can't be mined.",
    const Duration(hours: 1),
  );

  // Both surveying and mining require being undocked.
  await undockIfNeeded(api, caches.ships, ship);

  // We need to be off cooldown to continue.
  final expiration = ship.cooldown.expiration;
  if (expiration != null && expiration.isAfter(getNow())) {
    final duration = expiration.difference(getNow());
    shipDetail(ship, 'Waiting ${approximateDuration(duration)} on cooldown.');
    return JobResult.wait(expiration);
  }

  // See if we have a good survey to mine.
  final worthMining = await surveysWorthMining(
    db,
    caches.marketPrices,
    surveyWaypointSymbol: currentWaypoint.waypointSymbol,
    nearbyMarketSymbol: marketSymbol,
    minimumSurveys: centralCommand.minimumSurveys,
    percentileThreshold: centralCommand.surveyPercentileThreshold,
  );
  final maybeSurvey = worthMining.firstOrNull?.survey;
  // If not, add some new surveys.
  if (maybeSurvey == null && ship.hasSurveyor) {
    final response =
        await surveyAndLog(api, db, caches.ships, ship, getNow: getNow);

    // for (final survey in response.surveys) {
    //   printSurvey(survey, caches.marketPrices, marketSymbol);
    // }

    verifyCooldown(
      ship,
      'Survey',
      cooldownTimeForSurvey(ship),
      response.cooldown,
    );

    // Count completion of survey as a success, otherwise we could end up
    // surveying for a long time before checking other behaviors.
    // We don't need to do this for miners since they don't change as often.
    if (ship.isCommand) {
      state.isComplete = true;
    }
    // We wait the full cooldown because our next action will be either
    // surveying or mining, both of which require the reactor cooldown.
    return JobResult.wait(response.cooldown.expiration);
  }

  // if (maybeSurvey != null) {
  //   printSurvey(maybeSurvey, caches.marketPrices, marketSymbol);
  // }

  // Regardless of whether we have a survey, we should try to mine.
  final result = await extractAndLog(
    api,
    db,
    ship,
    caches.ships,
    maybeSurvey,
    getNow: getNow,
  );
  return result;
}

/// Init the MineJob.
Future<JobResult> _initMineJob(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final mineJob = await centralCommand.mineJobForShip(
    caches.waypoints,
    caches.marketListings,
    caches.agent,
    ship,
  );
  state.mineJob = mineJob;
  return JobResult.complete();
}

/// Attempt to empty cargo if needed, will navigate to a market if needed.
Future<JobResult> emptyCargoIfNeededForMining(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  return emptyCargoIfNeeded(
    state,
    api,
    db,
    centralCommand,
    caches,
    ship,
    minSpaceNeeded: _minSpaceForExtraction(ship),
    getNow: getNow,
  );
}

/// Attempt to empty cargo if needed, will navigate to a market if needed.
Future<JobResult> emptyCargoIfNeeded(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  required int minSpaceNeeded,
  DateTime Function() getNow = defaultGetNow,
}) async {
  // Sell if an extraction could overflow our cargo.
  if (ship.availableSpace >= minSpaceNeeded) {
    return JobResult.complete();
  }

  // Sell cargo and refuel if needed.
  final currentWaypoint = await caches.waypoints.waypoint(ship.waypointSymbol);
  final currentMarket = await visitLocalMarket(
    api,
    db,
    caches,
    currentWaypoint,
    ship,
    getNow: getNow,
  );
  if (currentMarket != null) {
    await sellAllCargoAndLog(
      api,
      db,
      caches.marketPrices,
      caches.agent,
      currentMarket,
      caches.ships,
      ship,
      AccountingType.goods,
    );
    // This could also compare before cargo and after cargo and call
    // a change success.  That would allow ships to mine even when they have
    // cargo which is otherwise hard to sell.
    if (ship.cargo.isEmpty) {
      return JobResult.complete();
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
    caches.marketListings,
    currentWaypoint.waypointSymbol,
    largestCargo!.tradeSymbol,
  );
  if (nearestMarket == null) {
    shipErr(
      ship,
      'No nearby market to sell ${largestCargo.symbol}, jetisoning cargo!',
    );
    // Only jettison the item we don't know how to sell, others might sell.
    await jettisonCargoAndLog(api, caches.ships, ship, largestCargo);
    if (ship.cargo.isEmpty) {
      return JobResult.complete();
    }
    // If we still have cargo to off-load, loop again.
    return JobResult.wait(null);
  }
  final waitTime = await beingNewRouteAndLog(
    api,
    db,
    centralCommand,
    caches,
    ship,
    state,
    nearestMarket.waypointSymbol,
  );
  return JobResult.wait(waitTime);
}

/// Attempt to sell cargo at the best price.
Future<JobResult> sellCargoIfNeeded(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  // This picks largest, but maybe should pick most valuable?
  final largestCargo = ship.largestCargo();
  if (largestCargo == null) {
    return JobResult.complete();
  }

  // FIXME(eseidel): We should decide if this cargo is even worth selling.
  // This currently optimizes for price and does not consider requests.
  // Some cargo should jettison and some should transfer to haulers.

  final costedTrip = assertNotNull(
    findBestMarketToSell(
      caches.marketPrices,
      caches.routePlanner,
      ship,
      largestCargo.tradeSymbol,
      expectedCreditsPerSecond: centralCommand.expectedCreditsPerSecond(ship),
      unitsToSell: largestCargo.units,
      // Don't use ship.cooldown.remainingSeconds because it may be stale.
      minimumDuration: ship.remainingCooldown(getNow()),
      includeRoundTripCost: true,
      requireFuelAtDestination: true,
    ),
    'No market for ${largestCargo.symbol}.',
    const Duration(minutes: 10),
  );

  if (costedTrip.route.endSymbol != ship.waypointSymbol) {
    shipInfo(ship, 'Traveling to ${costedTrip.route.endSymbol} to sell.');
    final waitTime = await beingNewRouteAndLog(
      api,
      db,
      centralCommand,
      caches,
      ship,
      state,
      costedTrip.route.endSymbol,
    );
    return JobResult.wait(waitTime);
  }

  final currentWaypoint = await caches.waypoints.waypoint(ship.waypointSymbol);
  final currentMarket = assertNotNull(
    await visitLocalMarket(
      api,
      db,
      caches,
      currentWaypoint,
      ship,
      getNow: getNow,
    ),
    'No market at ${currentWaypoint.symbol}.',
    const Duration(minutes: 10),
  );

  await sellAllCargoAndLog(
    api,
    db,
    caches.marketPrices,
    caches.agent,
    currentMarket,
    caches.ships,
    ship,
    // We don't have a good way to know what type of cargo this is.
    // Assuming it's goods (rather than captial) is probably fine.
    AccountingType.goods,
  );

  if (ship.cargo.isEmpty) {
    return JobResult.complete();
  }

  final nextLargestCargo = assertNotNull(
    ship.largestCargo(),
    'No cargo to sell?',
    const Duration(minutes: 10),
  );
  shipInfo(
    ship,
    'Cargo hold still not empty, finding '
    'market to sell ${nextLargestCargo.symbol}.',
  );
  return JobResult.wait(null);
}

// Miner stages
// - Empty cargo if needed
// - Navigate to mine
// - Survey if needed
// - Mine
// - Handle cargo (navigate to market, sell, jettison, etc)
// - Navigate to market

/// Advance the miner.
final advanceMiner = const MultiJob('Miner', [
  _initMineJob,
  // Is this step needed?  Or should we just have mining fail if we don't have
  // space?
  emptyCargoIfNeededForMining,
  doMineJob,
  sellCargoIfNeeded,
]).run;
