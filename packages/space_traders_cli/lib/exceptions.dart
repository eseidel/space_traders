import 'dart:convert';

import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/logger.dart';

/// Error 4224 is a survey exhausted error.
bool isExhaustedSurveyException(ApiException e) {
  // We ignore the error code at the http level, since we only care about
  // the error code in the response body.
  // ApiException 409: {"error":{"message":"Ship extract failed.
  // Survey X1-VS75-67965Z-D0F7C6 has been exhausted.","code":4224}}
  final jsonString = e.message;
  if (jsonString != null) {
    final exceptionJson = jsonDecode(jsonString) as Map<String, dynamic>;
    final error = mapCastOfType<String, dynamic>(exceptionJson, 'error');
    final code = mapValueOfType<int>(error, 'code');
    return code == 4224;
  }
  return false;
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
