import 'package:collection/collection.dart';
import 'package:space_traders_cli/queries.dart';

/// A route between two waypoints, including possibly jumping through gates.
/// Currently middle waypoints are always jumpgates.
/// Routes are directional, they list jumpgate waypoints in the system
/// they are jumping from.
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
