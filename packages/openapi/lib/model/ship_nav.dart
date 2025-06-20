import 'package:openapi/model/ship_nav_flight_mode.dart';
import 'package:openapi/model/ship_nav_route.dart';
import 'package:openapi/model/ship_nav_status.dart';
import 'package:openapi/model/system_symbol.dart';
import 'package:openapi/model/waypoint_symbol.dart';

class ShipNav {
  ShipNav({
    required this.systemSymbol,
    required this.waypointSymbol,
    required this.route,
    required this.status,
    this.flightMode = ShipNavFlightMode.CRUISE,
  });

  factory ShipNav.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ShipNav(
      systemSymbol: SystemSymbol(json['systemSymbol'] as String),
      waypointSymbol: WaypointSymbol(json['waypointSymbol'] as String),
      route: ShipNavRoute.fromJson(json['route'] as Map<String, dynamic>),
      status: ShipNavStatus.fromJson(json['status'] as String),
      flightMode: ShipNavFlightMode.fromJson(json['flightMode'] as String),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipNav? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ShipNav.fromJson(json);
  }

  SystemSymbol systemSymbol;
  WaypointSymbol waypointSymbol;
  ShipNavRoute route;
  ShipNavStatus status;
  ShipNavFlightMode flightMode;

  Map<String, dynamic> toJson() {
    return {
      'systemSymbol': systemSymbol.toJson(),
      'waypointSymbol': waypointSymbol.toJson(),
      'route': route.toJson(),
      'status': status.toJson(),
      'flightMode': flightMode.toJson(),
    };
  }

  @override
  int get hashCode =>
      Object.hash(systemSymbol, waypointSymbol, route, status, flightMode);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShipNav &&
        systemSymbol == other.systemSymbol &&
        waypointSymbol == other.waypointSymbol &&
        route == other.route &&
        status == other.status &&
        flightMode == other.flightMode;
  }
}
