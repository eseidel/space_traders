import 'package:openapi/model/ship_nav_route_waypoint.dart';

/// The routing information for the ship's most recent transit or current
/// location.

class ShipNavRoute {
  ShipNavRoute({
    required this.destination,
    required this.origin,
    required this.departureTime,
    required this.arrival,
  });

  factory ShipNavRoute.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ShipNavRoute(
      destination: ShipNavRouteWaypoint.fromJson(
        json['destination'] as Map<String, dynamic>,
      ),
      origin: ShipNavRouteWaypoint.fromJson(
        json['origin'] as Map<String, dynamic>,
      ),
      departureTime: DateTime.parse(json['departureTime'] as String),
      arrival: DateTime.parse(json['arrival'] as String),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipNavRoute? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ShipNavRoute.fromJson(json);
  }

  ShipNavRouteWaypoint destination;
  ShipNavRouteWaypoint origin;
  DateTime departureTime;
  DateTime arrival;

  Map<String, dynamic> toJson() {
    return {
      'destination': destination.toJson(),
      'origin': origin.toJson(),
      'departureTime': departureTime.toIso8601String(),
      'arrival': arrival.toIso8601String(),
    };
  }

  @override
  int get hashCode =>
      Object.hashAll([destination, origin, departureTime, arrival]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShipNavRoute &&
        destination == other.destination &&
        origin == other.origin &&
        departureTime == other.departureTime &&
        arrival == other.arrival;
  }
}
