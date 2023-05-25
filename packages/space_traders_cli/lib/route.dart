/// A route between two waypoints, including possibly jumping through gates.
/// Currently middle waypoints are always jumpgates.
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
