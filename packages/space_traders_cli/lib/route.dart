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
