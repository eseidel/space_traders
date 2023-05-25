import 'dart:math';

import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/data_store.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';

/// Either loads a cached survey set or creates a new one if we have a surveyor.
Future<SurveySet?> loadOrCreateSurveySetIfPossible(
  Api api,
  DataStore db,
  Ship ship,
) async {
  final cachedSurveySet = await loadSurveySet(db, ship.nav.waypointSymbol);
  if (cachedSurveySet != null) {
    return cachedSurveySet;
  }
  if (!ship.hasSurveyor) {
    return null;
  }
  // Survey
  final response = await api.fleet.createSurvey(ship.symbol);
  final survey = response!.data;
  final surveySet = SurveySet(
    waypointSymbol: ship.nav.waypointSymbol,
    surveys: survey.surveys,
  );
  await saveSurveySet(db, surveySet);
  shipInfo(ship, 'Surveyed ${ship.nav.waypointSymbol}');
  return null;
}

Survey? _chooseBestSurvey(SurveySet? surveySet) {
  if (surveySet == null) {
    return null;
  }
  // Each Survey can have multiple deposits.  The survey itself has a
  // size.  We should probably choose the most valuable ore based
  // on market price and then choose the largest deposit of that ore?
  if (surveySet.surveys.isEmpty) {
    return null;
  }
  // Just picking at random for now.
  return surveySet.surveys[Random().nextInt(surveySet.surveys.length)];
}

/// Apply the miner behavior to the ship.
Future<DateTime?> advanceMiner(
  Api api,
  DataStore db,
  PriceData priceData,
  Agent agent,
  Ship ship,
  WaypointCache waypointCache,
) async {
  if (ship.isInTransit) {
    // Go back to sleep until we arrive.
    return logRemainingTransitTime(ship);
  }
  final currentWaypoint = await waypointCache.waypoint(ship.nav.waypointSymbol);
  if (!currentWaypoint.isAsteroidField) {
    // We're not at an asteroid field, so we need to navigate to one.
    final systemWaypoints =
        await waypointCache.waypointsInSystem(ship.nav.systemSymbol);
    final asteroidField = systemWaypoints.firstWhere((w) => w.isAsteroidField);
    return navigateToAndLog(api, ship, asteroidField);
  }
  // It's not worth potentially waiting a minute just to get a few pieces
  // of cargo, when a surveyed mining operation could pull 10+ pieces.
  // Hence selling when we're down to 15 or fewer spaces.
  if (ship.availableSpace < 15) {
    // Otherwise, sell cargo and refuel if needed.
    await dockIfNeeded(api, ship);
    await refuelIfNeededAndLog(api, priceData, agent, ship);
    await sellCargoAndLog(api, priceData, ship);
    return null;
  }

  // If we still have space, mine.
  // Must be undocked before surveying or mining.
  await undockIfNeeded(api, ship);
  // Load a survey set, or if we have surveying capabilities, survey.
  final surveySet = await loadOrCreateSurveySetIfPossible(api, db, ship);
  final maybeSurvey = _chooseBestSurvey(surveySet);
  try {
    final response = await extractResources(api, ship, survey: maybeSurvey);
    final yield_ = response.extraction.yield_;
    final cargo = response.cargo;
    // Could use TradeSymbol.values.reduce() to find the longest symbol.
    shipInfo(
        ship,
        // pickaxe requires an extra space on mac?
        '⛏️  ${yield_.units.toString().padLeft(2)} '
        '${yield_.symbol.padRight(18)} '
        // Space after emoji is needed on windows to not bleed together.
        '📦 ${cargo.units.toString().padLeft(2)}/${cargo.capacity}');
    // We could sell here before putting ourselves to sleep.
    return response.cooldown.expiration;
  } on ApiException catch (e) {
    if (isExpiredSurveyException(e)) {
      // If the survey is expired, delete it and try again.
      await deleteSurveySet(db, ship.nav.waypointSymbol);
      return null;
    }
    rethrow;
  }
}
