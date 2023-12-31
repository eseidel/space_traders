import 'dart:math';

import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/exploring.dart';
import 'package:cli/logger.dart';
import 'package:cli/mining.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/net/exceptions.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';
import 'package:collection/collection.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// Returns the expected value of the survey.
int expectedValueFromSurvey(
  MarketPrices marketPrices,
  Survey survey, {
  required Map<TradeSymbol, WaypointSymbol> marketForGood,
}) {
  // I'm not yet sure what to do with deposit size.
  // Look at each of the possible returns.
  // Price them at the passed in market.
  // This will fail if the passed in market doesn't sell everything.

  final totalValue = survey.deposits.fold<int>(0, (total, deposit) {
    final marketSymbol = marketForGood[deposit.tradeSymbol];
    if (marketSymbol == null) {
      logger.warn('No market for ${deposit.tradeSymbol}.');
      return total;
    }
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
  required Map<TradeSymbol, WaypointSymbol> marketForGood,
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
            marketForGood: marketForGood,
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

int _minSpaceForExtraction(Ship ship) {
  // Currently we'd rather overflow occasionally, than waste time and fuel.
  return expectedExtractedUnits(ship);
}

/// Logs a warning if the extraction size is outside the expected range.
void verifyExtractionSize(Ship ship, int extractedUnits) {
  final min = minExtractedUnits(ship);
  final max = maxExtractedUnits(ship);
  if (extractedUnits < min || extractedUnits > max) {
    shipWarn(
      ship,
      'Extracted $extractedUnits units, outside expected range $min-$max.',
    );
  }
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
  if (ship.availableSpace < _minSpaceForExtraction(ship)) {
    shipWarn(
      ship,
      'Not enough space (${ship.availableSpace}) to extract '
      '(expecting ${_minSpaceForExtraction(ship)})',
    );
    return JobResult.complete();
  }

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

    verifyExtractionSize(ship, yield_.units);

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
  final mineJob = assertNotNull(
    state.extractionJob,
    'No mine job.',
    const Duration(minutes: 10),
  );
  final mineSymbol = mineJob.source;

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

  jobAssert(
    await caches.waypoints.canBeMined(ship.waypointSymbol),
    "${ship.waypointSymbol} can't be mined.",
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
    surveyWaypointSymbol: ship.waypointSymbol,
    marketForGood: mineJob.marketForGood,
    minimumSurveys: centralCommand.minimumSurveys,
    percentileThreshold: centralCommand.surveyPercentileThreshold,
  );
  final maybeSurvey = worthMining.firstOrNull?.survey;
  // If not, add some new surveys.
  if (maybeSurvey == null && ship.hasSurveyor) {
    final response =
        await surveyAndLog(api, db, caches.ships, ship, getNow: getNow);

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
  final currentMarket = await visitLocalMarket(
    api,
    db,
    caches,
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
      'No market at ${ship.waypointSymbol}, navigating to nearest.',
    );
  }

  final largestCargo = ship.largestCargo();
  final nearestMarketSymbol = nearbyMarketWhichTrades(
    caches.systems,
    caches.marketListings,
    ship.waypointSymbol,
    largestCargo!.tradeSymbol,
  );
  if (nearestMarketSymbol == null) {
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
    nearestMarketSymbol,
  );
  return JobResult.wait(waitTime);
}

Ship? _nextArrivingHauler(
  List<Ship> haulers,
  WaypointSymbol here,
) {
  if (haulers.isEmpty) {
    return null;
  }

  final haulersInTransit = haulers
      .where((h) => h.waypointSymbol == here && h.isInTransit)
      .sortedBy((h) => h.nav.route.arrival);
  // TODO(eseidel): Should this use Ship.timeToArrival?
  final arrivalTime = haulersInTransit.firstOrNull?.nav.route.arrival;
  if (arrivalTime != null) {
    return haulersInTransit.firstOrNull;
  }
  // Otherwise none of the haulers are headed towards us.
  return null;
}

/// Attempt to sell cargo ourselves by traveling to a market.
Future<JobResult> travelAndSellCargo(
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

  final costedTrip = assertNotNull(
    findBestMarketToSell(
      caches.marketPrices,
      caches.marketListings,
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

  final currentMarket = assertNotNull(
    await visitLocalMarket(
      api,
      db,
      caches,
      ship,
      getNow: getNow,
    ),
    'No market at ${ship.waypointSymbol}.',
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

JobResult _waitForHauler(
  List<Ship> haulers,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) {
  final nextHauler = _nextArrivingHauler(haulers, ship.waypointSymbol);
  if (nextHauler != null) {
    final waitTime = nextHauler.nav.route.arrival;
    final duration = waitTime.difference(getNow());
    if (duration.isNegative) {
      shipWarn(
        ship,
        'Hauler ${nextHauler.symbol} is already here, waiting 1 minute.',
      );
      return JobResult.wait(getNow().add(const Duration(minutes: 1)));
    }
    shipInfo(
      ship,
      'Waiting ${approximateDuration(duration)} for hauler arrival.',
    );
    return JobResult.wait(waitTime);
  } else {
    final haulerSymbols = haulers.map((h) => h.symbol).join(', ');
    shipInfo(
      ship,
      'No haulers at ${ship.waypointSymbol}, unknown next arrival time for '
      '$haulerSymbols, checking in 1 minute.',
    );
    for (final hauler in haulers) {
      final arrivalDuration = hauler.nav.route.arrival.difference(getNow());
      shipInfo(
        ship,
        'Hauler ${hauler.symbol} is ${hauler.nav.status} '
        'to ${hauler.waypointSymbol} '
        'arrival ${approximateDuration(arrivalDuration)}, '
        'with ${hauler.cargo.availableSpace} space available.',
      );
    }
    return JobResult.wait(getNow().add(const Duration(minutes: 1)));
  }
}

/// Attempt to transfer cargo to haulers, or wait for them to arrive.
Future<JobResult> transferToHaulersOrWait(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final haulers = assertNotNull(
    centralCommand.squadForShip(ship)?.haulers.toList(),
    'No haulers.',
    const Duration(minutes: 1),
  );

  // If there are haulers for this squad, and they are here, transfer to them.
  final haulersHere = haulers
      .where((h) => h.waypointSymbol == ship.waypointSymbol && !h.isInTransit)
      // Sort the haulers by available space, so we fill the smallest first.
      .sortedBy<num>((h) => h.cargo.availableSpace);
  // If they are not here, wait.
  if (haulersHere.isEmpty) {
    return _waitForHauler(haulers, ship, getNow: getNow);
  }
  // If they are here, transfer to them.
  for (final item in ship.cargo.inventory) {
    for (final hauler in haulersHere) {
      final transferAmount = min(
        item.units,
        hauler.cargo.availableSpace,
      );
      if (transferAmount > 0) {
        await transferCargoAndLog(
          api,
          caches.ships,
          from: ship,
          to: hauler,
          tradeSymbol: item.symbol,
          units: transferAmount,
        );
        break; // Exit the inner for loop and move to the next item.
      }
    }
  }
  if (ship.cargo.isEmpty) {
    return JobResult.complete();
  }
  shipInfo(
    ship,
    'Still have ${ship.cargo.units} cargo, waiting for hauler to arrive.',
  );
  // If we still have cargo to off-load, wait for an empty hauler to arrive.
  return _waitForHauler(haulers, ship, getNow: getNow);
}

/// Attempt to sell cargo at the best price.
Future<JobResult> transferOrSellCargo(
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

  // TODO(eseidel): We should decide if this cargo is even worth selling.
  // This currently optimizes for price and does not consider requests.
  // Some cargo should jettison and some should transfer to haulers.

  // Don't use the job on the behavior state, since our squad assignment might
  // have changed and we don't want to wait for a hauler which isn't coming to
  // this location.
  final waitLocation = centralCommand.squadForShip(ship)?.job.source;

  // Only wait for haulers at the mine, otherwise we can deadlock where
  // haulers are waiting for our return and we're somewhere else waiting for
  // hauer to arrive.
  if (ship.waypointSymbol == waitLocation) {
    final haulers = centralCommand.squadForShip(ship)?.haulers.toList() ?? [];
    if (haulers.isNotEmpty) {
      return transferToHaulersOrWait(
        state,
        api,
        db,
        centralCommand,
        caches,
        ship,
        getNow: getNow,
      );
    }
  }

  return travelAndSellCargo(state, api, db, centralCommand, caches, ship);
}

/// Advance the miner.
final advanceMiner = const MultiJob('Miner', [
  doMineJob,
  transferOrSellCargo,
]).run;
