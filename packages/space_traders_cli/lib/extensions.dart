import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/logger.dart';

/// lookupWaypoint looks up a Waypoint by its symbol in the given list of
/// Waypoint objects.
/// Most cases you want to use WaypointCache instead of this.
Waypoint lookupWaypoint(String waypointSymbol, List<Waypoint> systemWaypoints) {
  return systemWaypoints.firstWhere((w) => w.symbol == waypointSymbol);
}

/// lookupMarket looks up a Market by its symbol in the given list of Market
/// objects.
/// Most cases you want to use MarketCache instead of this.
Market lookupMarket(String waypointSymbol, List<Market> markets) {
  return markets.firstWhere((m) => m.symbol == waypointSymbol);
}

/// parseWaypointString parses a waypoint string into its component parts.
({String sector, String system, String waypoint}) parseWaypointString(
  String headquarters,
) {
  final parts = headquarters.split('-');
  return (
    sector: parts[0],
    system: '${parts[0]}-${parts[1]}',
    waypoint: '${parts[0]}-${parts[1]}-${parts[2]}',
  );
}

/// Extensions onto Waypoint to make it easier to work with.
extension WaypointUtils on Waypoint {
  /// Returns true if the waypoint has the given trait.
  bool hasTrait(WaypointTraitSymbolEnum trait) {
    return traits.any((t) => t.symbol == trait);
  }

  /// Returns true if the waypoint has the given type.
  bool isType(WaypointType type) {
    return this.type == type;
  }

  /// Returns the distance to the given waypoint.
  int distanceTo(Waypoint other) {
    // Use euclidean distance.
    final dx = other.x - x;
    final dy = other.y - y;
    return sqrt(dx * dx + dy * dy).round();
  }

  /// Returns the fuel cost to the given waypoint.
  int fuelCostTo(
    Waypoint other, {
    ShipNavFlightMode flightMode = ShipNavFlightMode.CRUISE,
  }) {
    switch (flightMode) {
      case ShipNavFlightMode.DRIFT:
        return 1;
      case ShipNavFlightMode.STEALTH:
        return distanceTo(other);
      case ShipNavFlightMode.CRUISE:
        return distanceTo(other);
      case ShipNavFlightMode.BURN:
        return 2 * distanceTo(other);
    }
    throw UnimplementedError('Unknown flight mode: $flightMode');
  }

  /// Returns the flight time to the given waypoint.
  int flightTimeInSeconds(
    Waypoint other, {
    required ShipNavFlightMode flightMode,
    required int shipSpeed,
  }) {
    // https://github.com/SpaceTradersAPI/api-docs/wiki/Travel-Fuel-and-Time
    final distance = distanceTo(other);
    final distanceBySpeed = distance ~/ shipSpeed;

    switch (flightMode) {
      case ShipNavFlightMode.DRIFT:
        return 15 + 100 * distanceBySpeed;
      case ShipNavFlightMode.STEALTH:
        return 15 + 20 * distanceBySpeed;
      case ShipNavFlightMode.CRUISE:
        return 15 + 10 * distanceBySpeed;
      case ShipNavFlightMode.BURN:
        return 15 + 5 * distanceBySpeed;
    }
    throw UnimplementedError('Unknown flight mode: $flightMode');
  }

  /// Returns true if the waypoint is an asteroid field.
  bool get isAsteroidField => isType(WaypointType.ASTEROID_FIELD);

  /// Returns true if the waypoint is a jump gate.
  bool get isJumpGate => isType(WaypointType.JUMP_GATE);

  /// Returns true if the waypoint has a shipyard.
  bool get hasShipyard => hasTrait(WaypointTraitSymbolEnum.SHIPYARD);

  /// Returns true if the waypoint has a marketplace.
  bool get hasMarketplace => hasTrait(WaypointTraitSymbolEnum.MARKETPLACE);
}

/// Extensions onto ShipCargo to make it easier to work with.
extension CargoUtils on ShipCargo {
  /// Returns the amount of cargo space available on the ship.
  int get availableSpace => capacity - units;
}

/// Extensions onto Ship to make it easier to work with.
extension ShipUtils on Ship {
  /// Returns the emoji name of the ship.
  String get emojiName {
    // Ships are all AGENT_SYMBOL-1, AGENT_SYMBOL-2, etc.
    final number = symbol.split('-').last;
    return '🛸#$number';
  }

  /// Returns the amount of the given trade good the ship has.
  int countUnits(String tradeSymbol) {
    final maybeCargo = cargo.inventory.firstWhereOrNull(
      (i) => i.symbol == tradeSymbol,
    );
    return maybeCargo?.units ?? 0;
  }

  /// Returns the amount of space available on the ship.
  int get availableSpace => cargo.availableSpace;

  /// Returns true if the ship is an excavator.
  bool get isExcavator => registration.role == ShipRole.EXCAVATOR;

  /// Returns true if the ship can mine.
  bool get canMine {
    const minerMounts = [
      ShipMountSymbolEnum.MINING_LASER_I,
      ShipMountSymbolEnum.MINING_LASER_II,
      ShipMountSymbolEnum.MINING_LASER_III,
    ];
    return mounts.any((m) => minerMounts.contains(m.symbol));
  }

  /// Returns true if the ship is in transit.
  bool get isInTransit => nav.status == ShipNavStatus.IN_TRANSIT;

  /// Returns true if the ship is docked.
  bool get isDocked => nav.status == ShipNavStatus.DOCKED;

  /// Returns true if the ship is in orbit.
  bool get isOrbiting => nav.status == ShipNavStatus.IN_ORBIT;

  /// Returns true if the ship has a surveyor module.
  bool get hasSurveyor {
    const surveyerMounts = [
      ShipMountSymbolEnum.SURVEYOR_I,
      ShipMountSymbolEnum.SURVEYOR_II,
      ShipMountSymbolEnum.SURVEYOR_III,
    ];
    return mounts.any((m) => surveyerMounts.contains(m.symbol));
  }

  /// Returns the average condition of the ship with 100 being perfect and 0
  /// being destroyed. This is the average of the engine, frame, and reactor
  /// conditions.
  int get averageCondition {
    var total = 0;
    total += engine.condition ?? 100;
    total += frame.condition ?? 100;
    total += reactor.condition ?? 100;
    return total ~/ 3;
  }

  /// Returns a string representing the current navigation status of the ship.
  String get navStatusString {
    switch (nav.status) {
      case ShipNavStatus.DOCKED:
        return 'Docked at ${nav.waypointSymbol}';
      case ShipNavStatus.IN_ORBIT:
        return 'Orbiting ${nav.waypointSymbol}';
      case ShipNavStatus.IN_TRANSIT:
        return 'In transit to ${nav.waypointSymbol}';
    }
    return 'Unknown';
  }
}

/// Extensions onto Contract to make it easier to work with.
extension ContractUtils on Contract {
  // bool needsItem(String tradeSymbol) => goodNeeded(tradeSymbol) != null;

  /// Returns the ContractDeliverGood for the given trade good symbol or null if
  /// the contract doesn't need that good.
  ContractDeliverGood? goodNeeded(String tradeSymbol) {
    return terms.deliver
        .firstWhereOrNull((item) => item.tradeSymbol == tradeSymbol);
  }

  /// Returns the duration until the contract deadline.
  Duration get timeUntilDeadline => terms.deadline.difference(DateTime.now());
}

/// Extensions onto ContractDeliverGood to make it easier to work with.
extension ContractDeliverGoodUtils on ContractDeliverGood {
  /// Returns the amount of the given trade good the contract needs.
  int get amountNeeded => unitsRequired - unitsFulfilled;
}

/// Enum representing the type of trades available for a good at a market.
enum ExchangeType {
  /// Market imports this good. (Likely to be sold at a higher price.)
  imports,

  /// Market exports this good. (Likely to be bought at a lower price.)
  exports,

  /// Market allows agents to exchange this good.
  exchange,
}

/// Extensions onto Market to make it easier to work with.
extension MarketUtils on Market {
  /// Returns the TradeType for the given trade symbol or null if the market
  /// doesn't trade that good.
  ExchangeType? exchangeType(String tradeSymbol) {
    if (imports.any((g) => g.symbol.value == tradeSymbol)) {
      return ExchangeType.imports;
    }
    if (exports.any((g) => g.symbol.value == tradeSymbol)) {
      return ExchangeType.exports;
    }
    if (exchange.any((g) => g.symbol.value == tradeSymbol)) {
      return ExchangeType.exchange;
    }
    return null;
  }

  /// Returns all TradeSymbols that the market trades.
  Set<TradeSymbol> get allTradeSymbols {
    final symbols = <TradeSymbol>{
      ...imports.map((g) => g.symbol),
      ...exports.map((g) => g.symbol),
      ...exchange.map((g) => g.symbol)
    };
    return symbols;
  }
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

/// Error 4224 is a survey expired error.
bool isExpiredSurveyException(ApiException e) {
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
