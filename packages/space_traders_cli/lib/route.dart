import 'dart:math';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/queries.dart';

/// A route between two waypoints, including possibly jumping through gates.
/// Currently middle waypoints are always jumpgates.
/// Routes are directional, they list jumpgate waypoints in the system
/// they are jumping from.
@immutable
class Route {
  /// Create a route between the given [waypointSymbols].
  const Route(this.waypointSymbols);

  /// Create a route from JSON.
  factory Route.fromJson(Map<String, dynamic> json) {
    final waypointSymbols = (json['waypointSymbols'] as List<dynamic>)
        .map((s) => s as String)
        .toList();
    return Route(waypointSymbols);
  }

  /// The symbol of the first waypoint in the route.
  String get start => waypointSymbols.first;

  /// The symbol of the last waypoint in the route.
  String get end => waypointSymbols.last;

  /// The symbols of the waypoints in the route.
  final List<String> waypointSymbols;

  /// Converts the route to JSON.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'waypointSymbols': waypointSymbols,
      };

  @override
  int get hashCode => waypointSymbols.hashCode;

  @override
  bool operator ==(Object other) =>
      other is Route &&
      const ListEquality<String>()
          .equals(waypointSymbols, other.waypointSymbols);
}

// int expectedFuelCost(Route route) {

// }

/// Plans routes between waypoints.
class RoutePlanner {
  /// Create a new RoutePlanner.
  RoutePlanner(this._waypointCache);

  final WaypointCache _waypointCache;

  /// Find a route between the given waypoints.
  Future<Route?> findRoute(
    String start,
    String end,
  ) async {
    if (start == end) {
      return Route([start]);
    }
    final startWaypoint = await _waypointCache.waypoint(start);
    final endWaypoint = await _waypointCache.waypoint(end);
    final startSystem = startWaypoint.systemSymbol;
    final endSystem = endWaypoint.systemSymbol;
    if (startSystem == endSystem) {
      return Route([start, end]);
    }
    final connectedSystems =
        await _waypointCache.connectedSystems(startSystem).toList();
    final connectedSystem = connectedSystems.firstWhereOrNull(
      (s) => s.symbol == endSystem,
    );
    if (connectedSystem != null) {
      // We don't know how to plan multi-jump routes yet.
      return null;
    }
    final jumpGate =
        await _waypointCache.jumpGateWaypointForSystem(startSystem);
    if (jumpGate == null) {
      // We don't know how to plan routes w/o jumpgates yet.
      return null;
    }
    return Route([start, jumpGate.symbol, end]);
  }
}

/// Returns the distance to the given waypoint.
int? distanceWithinSystem(Waypoint a, Waypoint b) {
  if (a.systemSymbol != b.systemSymbol) {
    return null;
  }
  // Use euclidean distance.
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return sqrt(dx * dx + dy * dy).round();
}

/// Returns the fuel cost to the given waypoint.
int fuelCostWithinSystem(
  Waypoint a,
  Waypoint b, {
  ShipNavFlightMode flightMode = ShipNavFlightMode.CRUISE,
}) {
  final distance = distanceWithinSystem(a, b)!;
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
  Waypoint a,
  Waypoint b, {
  required ShipNavFlightMode flightMode,
  required int shipSpeed,
}) {
  // https://github.com/SpaceTradersAPI/api-docs/wiki/Travel-Fuel-and-Time
  final distance = distanceWithinSystem(a, b)!;
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
