import 'dart:math';

import 'package:cli/api.dart';
import 'package:cli/cache/systems_cache.dart';

/// Returns the fuel cost to the given waypoint.
int fuelUsedWithinSystem(
  SystemWaypoint a,
  SystemWaypoint b, {
  ShipNavFlightMode flightMode = ShipNavFlightMode.CRUISE,
}) {
  final distance = a.distanceTo(b);
  switch (flightMode) {
    case ShipNavFlightMode.DRIFT:
      return 1;
    case ShipNavFlightMode.STEALTH:
      return distance;
    case ShipNavFlightMode.CRUISE:
      return distance;
    case ShipNavFlightMode.BURN:
      return 2 * distance;
  }
  throw UnimplementedError('Unknown flight mode: $flightMode');
}

/// Returns the flight time to the given waypoint.
int flightTimeWithinSystemInSeconds(
  SystemWaypoint a,
  SystemWaypoint b, {
  required int shipSpeed,
  ShipNavFlightMode flightMode = ShipNavFlightMode.CRUISE,
}) {
  // https://github.com/SpaceTradersAPI/api-docs/wiki/Travel-Fuel-and-Time
  final distance = a.distanceTo(b);
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

/// Returns the fuel cost to travel between two waypoints.
/// This assumes the two waypoints are either within the same system
/// or are connected by jump gates.
int fuelUsedBetween(
  SystemsCache systemsCache,
  SystemWaypoint a,
  SystemWaypoint b,
) {
  if (a.systemSymbol == b.systemSymbol) {
    return fuelUsedWithinSystem(a, b);
  }
  // a -> jump gate
  // jump N times
// jump gate -> b
  final aJumpGate = systemsCache.jumpGateWaypointForSystem(a.systemSymbol);
  if (aJumpGate == null) {
    throw ArgumentError(
      'No jump gate for ${a.systemSymbol}',
    );
  }
  // Ignoring if there is actually a path between the jump gates.
  final bJumpGate = systemsCache.jumpGateWaypointForSystem(b.systemSymbol);
  if (bJumpGate == null) {
    throw ArgumentError(
      'No jump gate for ${b.systemSymbol}',
    );
  }
  return fuelUsedWithinSystem(a, aJumpGate) +
      fuelUsedWithinSystem(bJumpGate, b);
}

/// Returns the cooldown time after jumping between two systems.
int cooldownTimeForJumpBetweenSystems(System a, System b) {
  // This would need to check that this two are connected by a jumpgate.
  final distance = a.distanceTo(b);
  if (distance > 2000) {
    throw ArgumentError(
      'Distance ${a.symbol} to ${b.symbol} is too far $distance to jump.',
    );
  }
  return min(60, distance ~/ 10);
}

/// Returns flight time in seconds between two waypoints.
int flightTimeBetween(
  SystemsCache systemsCache,
  SystemWaypoint a,
  SystemWaypoint b, {
  required ShipNavFlightMode flightMode,
  required int shipSpeed,
}) {
  if (a.systemSymbol == b.systemSymbol) {
    return flightTimeWithinSystemInSeconds(
      a,
      b,
      flightMode: flightMode,
      shipSpeed: shipSpeed,
    );
  }
  // a -> jump gate
  // jump N times
  // jump gate -> b
  final aJumpGate = systemsCache.jumpGateWaypointForSystem(a.systemSymbol);
  if (aJumpGate == null) {
    throw ArgumentError(
      'No jump gate for ${a.systemSymbol}',
    );
  }
  // Ignoring if there is actually a path between the jump gates.
  final bJumpGate = systemsCache.jumpGateWaypointForSystem(b.systemSymbol);
  if (bJumpGate == null) {
    throw ArgumentError(
      'No jump gate for ${b.systemSymbol}',
    );
  }
  // Assuming a and b are connected systems!
  return flightTimeWithinSystemInSeconds(
        a,
        aJumpGate,
        flightMode: flightMode,
        shipSpeed: shipSpeed,
      ) +
      flightTimeWithinSystemInSeconds(
        bJumpGate,
        b,
        flightMode: flightMode,
        shipSpeed: shipSpeed,
      );
}
