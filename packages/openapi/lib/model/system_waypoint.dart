import 'package:openapi/model/waypoint_orbital.dart';
import 'package:openapi/model/waypoint_type.dart';
import 'package:openapi/model_helpers.dart';

class SystemWaypoint {
  SystemWaypoint({
    required this.symbol,
    required this.type,
    required this.x,
    required this.y,
    this.orbitals = const [],
    this.orbits,
  });

  factory SystemWaypoint.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return SystemWaypoint(
      symbol: json['symbol'] as String,
      type: WaypointType.fromJson(json['type'] as String),
      x: json['x'] as int,
      y: json['y'] as int,
      orbitals: (json['orbitals'] as List)
          .map<WaypointOrbital>(
            (e) => WaypointOrbital.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      orbits: json['orbits'] as String?,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static SystemWaypoint? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return SystemWaypoint.fromJson(json);
  }

  String symbol;
  WaypointType type;
  int x;
  int y;
  List<WaypointOrbital> orbitals;
  String? orbits;

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'type': type.toJson(),
      'x': x,
      'y': y,
      'orbitals': orbitals.map((e) => e.toJson()).toList(),
      'orbits': orbits,
    };
  }

  @override
  int get hashCode => Object.hash(symbol, type, x, y, orbitals, orbits);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SystemWaypoint &&
        symbol == other.symbol &&
        type == other.type &&
        x == other.x &&
        y == other.y &&
        listsEqual(orbitals, other.orbitals) &&
        orbits == other.orbits;
  }
}
