import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:space_traders_api/api.dart';

/// lookupWaypoint looks up a Waypoint by its symbol in the given list of
/// Waypoint objects.
Waypoint lookupWaypoint(String waypointSymbol, List<Waypoint> systemWaypoints) {
  return systemWaypoints.firstWhere((w) => w.symbol == waypointSymbol);
}

/// lookupMarket looks up a Market by its symbol in the given list of Market
/// objects.
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

  /// Returns true if the waypoint is an asteroid field.
  bool get isAsteroidField => isType(WaypointType.ASTEROID_FIELD);

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

  /// Returns true if the ship is in transit.
  bool get isInTransit => nav.status == ShipNavStatus.IN_TRANSIT;

  /// Returns true if the ship is docked.
  bool get isDocked => nav.status == ShipNavStatus.DOCKED;

  /// Returns true if the ship is in orbit.
  bool get isOrbiting => nav.status == ShipNavStatus.IN_ORBIT;

  /// Returns true if the ship has a surveyor module.
  // bool get hasSurveyor {
  //   const surveyorModules = [
  //     ShipMountSymbolEnum.SURVEYOR_I,
  //     ShipMountSymbolEnum.SURVEYOR_II,
  //     ShipMountSymbolEnum.SURVEYOR_III,
  //   ];
  //   return modules.any((m) => surveyorModules.contains(m.symbol));
  // }

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
}

extension ContractDeliverGoodUtils on ContractDeliverGood {
  /// Returns the amount of the given trade good the contract needs.
  int get amountNeeded => unitsRequired - unitsFulfilled;
}

/// Error 4000 is just a cooldown error and we can retry.
/// Detect that case and return the retry time.
/// https://docs.spacetraders.io/api-guide/response-errors
DateTime? expirationFromApiException(ApiException e) {
  if (e.code == 409) {
    // What we tried to do was still on cooldown.
    final jsonString = e.message;
    if (jsonString != null) {
      final exceptionJson = jsonDecode(jsonString) as Map<String, dynamic>;
      final error = exceptionJson['error'] as Map<String, dynamic>?;
      final errorData = error?['data'] as Map<String, dynamic>?;
      final cooldown = errorData?['cooldown'];
      final expiration = mapDateTime(cooldown, 'expiration');
      return expiration;
    }
  }
  return null;
}
