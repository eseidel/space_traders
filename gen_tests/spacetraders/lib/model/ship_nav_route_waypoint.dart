import 'package:meta/meta.dart';
import 'package:spacetraders/model/system_symbol.dart';
import 'package:spacetraders/model/waypoint_type.dart';

@immutable
class ShipNavRouteWaypoint {
  const ShipNavRouteWaypoint({
    required this.symbol,
    required this.type,
    required this.systemSymbol,
    required this.x,
    required this.y,
  });

  factory ShipNavRouteWaypoint.fromJson(Map<String, dynamic> json) {
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

  final String symbol;
  final WaypointType type;
  final SystemSymbol systemSymbol;
  final int x;
  final int y;

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
