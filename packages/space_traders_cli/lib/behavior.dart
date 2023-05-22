/// Enum to specify which behavior the ship should follow.
enum Behavior {
  /// Trade to fulfill the current contract.
  contractTrader,

  /// Trade for profit.
  arbitrageTrader,

  /// Mine asteroids and sell the ore.
  miner,
}

/// A route between two waypoints, including possibly jumping through gates.
class Route {
  /// Create a route between the given [waypointSymbols].
  const Route(this.waypointSymbols);

  /// The symbol of the first waypoint in the route.
  String get start => waypointSymbols.first;

  /// The symbol of the last waypoint in the route.
  String get end => waypointSymbols.last;

  /// The symbols of the waypoints in the route.
  final List<String> waypointSymbols;
}

/// Class holding the persistent state for a behavior.
class BehaviorState {
  /// Create a new behavior state.
  BehaviorState(this.behavior);

  /// The current behavior.
  final Behavior behavior;

  /// The current route.
  Route? route;
}
