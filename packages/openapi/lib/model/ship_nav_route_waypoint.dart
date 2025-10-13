import 'package:openapi/model/system_symbol.dart';
import 'package:openapi/model/waypoint_type.dart';

/// The destination or departure of a ships nav route.

class ShipNavRouteWaypoint {
  ShipNavRouteWaypoint({
    required this.symbol,
    required this.type,
    required this.systemSymbol,
    required this.x,
    required this.y,
  });

  factory ShipNavRouteWaypoint.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ShipNavRouteWaypoint(
      symbol: json['symbol'] as String,
      type: WaypointType.fromJson(json['type'] as String),
      systemSymbol: SystemSymbol.fromJson(json['systemSymbol'] as String),
      x: json['x'] as int,
      y: json['y'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipNavRouteWaypoint? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ShipNavRouteWaypoint.fromJson(json);
  }

  String symbol;
  WaypointType type;
  SystemSymbol systemSymbol;
  int x;
  int y;

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'type': type.toJson(),
      'systemSymbol': systemSymbol.toJson(),
      'x': x,
      'y': y,
    };
  }

  @override
  int get hashCode => Object.hashAll([symbol, type, systemSymbol, x, y]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShipNavRouteWaypoint &&
        symbol == other.symbol &&
        type == other.type &&
        systemSymbol == other.systemSymbol &&
        x == other.x &&
        y == other.y;
  }
}
