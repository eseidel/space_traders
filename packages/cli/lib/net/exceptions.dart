import 'dart:convert';

import 'package:cli/api.dart';
import 'package:cli/logger.dart';

/// Error 4224 is a survey exhausted error.
bool isSurveyExhaustedException(ApiException e) {
  // ApiException 409: {"error":{"message":"Ship extract failed.
  // Survey X1-VS75-67965Z-D0F7C6 has been exhausted.","code":4224}}
  return isAPIExceptionWithCode(e, 4224);
}

/// Error 4221 is a survey expired error.
bool isSurveyExpiredException(ApiException e) {
  // ApiException 400: {"error":{"message":"Ship survey failed. Target
  // signature is no longer in range or valid.","code":4221}}
  return isAPIExceptionWithCode(e, 4221);
}

/// Error 4000 is just a cooldown error and we can retry.
/// Detect that case and return the retry time.
/// https://docs.spacetraders.io/api-guide/response-errors
DateTime? expirationFromApiException(ApiException e) {
  // We ignore the error code at the http level, since we only care about
  // the error code in the response body.
  // I've seen both 409 and 400 for this error.

  final jsonString = e.message;
  if (jsonString != null) {
    Map<String, dynamic> exceptionJson;
    try {
      exceptionJson = jsonDecode(jsonString) as Map<String, dynamic>;
    } on FormatException catch (e) {
      // Catch any json decode errors, so the original exception can be
      // rethrown by the caller instead of a json decode error.
      logger.warn('Failed to parse exception json: $e');
      return null;
    }
    final error = mapCastOfType<String, dynamic>(exceptionJson, 'error');
    final code = mapValueOfType<int>(error, 'code');
    if (code != 4000) {
      return null;
    }
    final errorData = mapCastOfType<String, dynamic>(error, 'data');
    final cooldown = mapCastOfType<String, dynamic>(errorData, 'cooldown');
    return mapDateTime(cooldown, 'expiration');
  }
  return null;
}

/// Returns true if [e] is an API exception with the given [expectedCode].
bool isAPIExceptionWithCode(ApiException e, int expectedCode) {
  // We ignore the error code at the http level, since we only care about
  // the error code in the response body.
  final jsonString = e.message;
  if (jsonString == null) {
    return false;
  }
  Map<String, dynamic> exceptionJson;
  try {
    exceptionJson = jsonDecode(jsonString) as Map<String, dynamic>;
  } on FormatException catch (e) {
    // Catch any json decode errors, so the original exception can be
    // rethrown by the caller instead of a json decode error.
    logger.warn('Failed to parse exception json: $e');
    return false;
  }
  final error = mapCastOfType<String, dynamic>(exceptionJson, 'error');
  final code = mapValueOfType<int>(error, 'code');
  return code == expectedCode;
}

// {"error":{"message":"Market purchase failed. Trade good FUEL is not
// available at X1-BZ43-47417A.","code":4601,"data":{"waypointSymbol":
// "X1-BZ43-47417A","tradeSymbol":"FUEL"}}}
/// Returns true if [e] is a market purchase failed exception.
bool isMarketDoesNotSellFuelException(ApiException e) {
  return isAPIExceptionWithCode(e, 4601);
}

// {"error":{"message":"Navigate request failed. Ship ESEIDEL-2 requires 14
// more fuel for navigation.","code":4203,"data":{"shipSymbol":"ESEIDEL-2",
// "fuelRequired":39,"fuelAvailable":25}}}
/// Returns true if [e] is an insufficient fuel exception.
bool isInfuficientFuelException(ApiException e) {
  return isAPIExceptionWithCode(e, 4203);
}

// ApiException 503: {"error":{"message":"SpaceTraders is currently in
// maintenance mode and unavailable. This will hopefully only last a few
// minutes while we update or upgrade our servers. Check discord for updates
// https://discord.com/invite/jh6zurdWk5 and consider donating to keep the
// servers running https://donate.stripe.com/28o29m5vxcri6OccMM","code":503}}
/// Returns true if the exception is a maintenance window exception.
bool isMaintenanceWindowException(ApiException e) {
  // Is 503 and contains "maintenance"
  return isAPIExceptionWithCode(e, 503) && e.toString().contains('maintenance');
}

// ApiException 400: {"error":{"message":"Cannot register agent. Call sign
// has been reserved between resets: ESEIDEL. If you reserved your call
// sign and cannot register, please reach out on Discord, Twitter, or
// email us at contact@spacetraders.io","code":4110}}
/// Returns true if the exception is a reserved handle exception.
bool isReservedHandleException(ApiException e) {
  return isAPIExceptionWithCode(e, 4110);
}

// ApiException 400: {"error":{"message":"Waypoint already charted:
// X1-ZY63-71980E","code":4230,"data":{"waypointSymbol":"X1-ZY63-71980E"}}}
/// Returns true if the exception is a waypoint already charted exception.
/// This can happen if we try to chart a waypoint that is already charted
/// which is typically a race with another player.
bool isWaypointAlreadyChartedException(ApiException e) {
  return isAPIExceptionWithCode(e, 4230);
}

/// Returns true if the inner exception is a windows semaphore timeout.
/// This is a workaround for some behavior in windows I do not understand.
/// These seem to occur only once every few hours at random.
bool isWindowsSemaphoreTimeout(ApiException e) {
  final innerException = e.innerException;
  if (innerException == null) {
    return false;
  }
  return innerException
      .toString()
      .contains('The semaphore timeout period has expired.');
}

// ApiException 400: {"error":{"message":"Market purchase failed. Agent
// does not have sufficient credits to purchase 10 unit(s) of
// MODULE_MINERAL_PROCESSOR_I","code":4600,"data":{"agentCredits":44815,
// "totalPrice":44930,"tradeSymbol":"MODULE_MINERAL_PROCESSOR_I",
// "units":10,"purchasePrice":4493}}}
/// Returns true if the exception is an insufficient credits exception.
/// This can happen if we try to buy something we cannot afford, even
/// if we check before it's possible for the price to change as a result
/// of another player buying something.
bool isInsufficientCreditsException(ApiException e) {
  return isAPIExceptionWithCode(e, 4600);
}

// ApiException 400: {"error":{"message":
// "Ship action failed. Ship is not currently in orbit at X1-PA79-91721F.",
// "code":4236,"data":{"waypointSymbol":"X1-PA79-91721F"}}}
/// Returns true if the exception is a ship not in orbit exception.
bool isShipNotInOrbitException(ApiException e) {
  return isAPIExceptionWithCode(e, 4236);
}

// ApiException 400: {"error":{"message":"Failed to purchase ship.
// Agent has insufficient funds.","code":4216,
// "data":{"creditsAvailable":116103,"creditsNeeded":172355}}}
// bool isInsufficientCreditsToPurchaseShipException(ApiException e) {
//   return isAPIExceptionWithCode(e, 4216);
// }

/// Returns the number of credits needed to purchase a ship from the
/// exception, or null if the exception is not an insufficient credits
/// exception.
int? neededCreditsFromPurchaseShipException(ApiException e) {
  final jsonString = e.message;
  if (jsonString != null) {
    Map<String, dynamic> exceptionJson;
    try {
      exceptionJson = jsonDecode(jsonString) as Map<String, dynamic>;
    } on FormatException catch (e) {
      // Catch any json decode errors, so the original exception can be
      // rethrown by the caller instead of a json decode error.
      logger.warn('Failed to parse exception json: $e');
      return null;
    }
    final error = mapCastOfType<String, dynamic>(exceptionJson, 'error');
    final code = mapValueOfType<int>(error, 'code');
    if (code != 4216) {
      return null;
    }
    final errorData = mapCastOfType<String, dynamic>(error, 'data');
    return mapValueOfType<int>(errorData, 'creditsNeeded');
  }
  return null;
}

// ApiException 400: {"error":{"message":
// "Construction material requirements for ADVANCED_CIRCUITRY have been met.",
// "code":4801}}
/// Returns true if the exception is a construction requirements met exception.
bool isConstructionRequirementsMet(ApiException e) {
  return isAPIExceptionWithCode(e, 4801);
}

// ApiException 400: {"error":{"message": "Market purchase failed. "
// "Trade good ANTIMATTER is not available at X1-RJ35-CF7C.","code":4601,
// "data":{"waypointSymbol":"X1-RJ35-CF7C","tradeSymbol":"ANTIMATTER"}}}
/// Returns true if the exception is a market does not sell antimatter exception.
/// This happens due to a bug in the game.
bool isMarketDoesNotSellAntimatterException(ApiException e) {
  return isAPIExceptionWithCode(e, 4601);
}
