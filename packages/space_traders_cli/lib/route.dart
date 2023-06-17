import 'dart:math';

import 'package:space_traders_cli/api.dart';

/// Returns the distance to the given waypoint.
int distanceBetweenWaypointsInSystem(Waypoint a, Waypoint b) {
  return distanceWithinSystem(a.toSystemWaypoint(), b.toSystemWaypoint());
}

/// Returns the distance to the given waypoint.
int distanceWithinSystem(SystemWaypoint a, SystemWaypoint b) {
  if (a.systemSymbol != b.systemSymbol) {
    throw ArgumentError(
      'Waypoints must be in the same system: $a, $b',
    );
  }
  // Use euclidean distance.
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return sqrt(dx * dx + dy * dy).round();
}

/// Returns the fuel cost to the given waypoint.
int fuelUsedWithinSystem(
  SystemWaypoint a,
  SystemWaypoint b, {
  ShipNavFlightMode flightMode = ShipNavFlightMode.CRUISE,
}) {
  final distance = distanceWithinSystem(a, b);
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
  final distance = distanceWithinSystem(a, b);
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
