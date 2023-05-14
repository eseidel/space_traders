import 'dart:convert';

import 'package:space_traders_api/api.dart';

/// lookupWaypoint looks up a Waypoint by its symbol in the given list of
/// Waypoint objects.
Waypoint lookupWaypoint(String waypointSymbol, List<Waypoint> systemWaypoints) {
  return systemWaypoints.firstWhere((w) => w.symbol == waypointSymbol);
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
  // bool get hasMarketplace => hasTrait(WaypointTraitSymbolEnum.MARKETPLACE);
}

/// Extensions onto Ship to make it easier to work with.
extension ShipUtils on Ship {
  /// Returns the emoji name of the ship.
  String get emojiName {
    // Ships are all AGENT_SYMBOL-1, AGENT_SYMBOL-2, etc.
    final number = symbol.split('-').last;
    return '🛸#$number';
  }

  /// Returns the amount of space available on the ship.
  int get spaceAvailable => cargo.capacity - cargo.units;

  /// Returns true if the ship is an excavator.
  bool get isExcavator => registration.role == ShipRole.EXCAVATOR;

  /// Returns true if the ship is in transit.
  bool get isInTransit => nav.status == ShipNavStatus.IN_TRANSIT;

  /// Returns true if the ship is docked.
  bool get isDocked => nav.status == ShipNavStatus.DOCKED;

  /// Returns true if the ship is in orbit.
  bool get isOrbiting => nav.status == ShipNavStatus.IN_ORBIT;

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

// extension ContractUtils on Contract {
//   bool needsItem(String tradeSymbol) => goodNeeded(tradeSymbol) != null;

//   ContractDeliverGood? goodNeeded(String tradeSymbol) {
//     return terms.deliver
//         .firstWhereOrNull((item) => item.tradeSymbol == tradeSymbol);
//   }
// }

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
