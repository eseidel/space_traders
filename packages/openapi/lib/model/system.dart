import 'package:openapi/model/system_faction.dart';
import 'package:openapi/model/system_type.dart';
import 'package:openapi/model/system_waypoint.dart';

class System {
  System({
    required this.constellation,
    required this.symbol,
    required this.sectorSymbol,
    required this.type,
    required this.x,
    required this.y,
    required this.waypoints,
    required this.factions,
    required this.name,
  });

  factory System.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return System(
      constellation: json['constellation'] as String,
      symbol: json['symbol'] as String,
      sectorSymbol: json['sectorSymbol'] as String,
      type: SystemType.fromJson(json['type'] as String),
      x: json['x'] as int,
      y: json['y'] as int,
      waypoints:
          (json['waypoints'] as List<dynamic>)
              .map<SystemWaypoint>(
                (e) => SystemWaypoint.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      factions:
          (json['factions'] as List<dynamic>)
              .map<SystemFaction>(
                (e) => SystemFaction.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      name: json['name'] as String,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static System? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return System.fromJson(json);
  }

  String constellation;
  String symbol;
  String sectorSymbol;
  SystemType type;
  int x;
  int y;
  List<SystemWaypoint> waypoints;
  List<SystemFaction> factions;
  String name;

  Map<String, dynamic> toJson() {
    return {
      'constellation': constellation,
      'symbol': symbol,
      'sectorSymbol': sectorSymbol,
      'type': type.toJson(),
      'x': x,
      'y': y,
      'waypoints': waypoints.map((e) => e.toJson()).toList(),
      'factions': factions.map((e) => e.toJson()).toList(),
      'name': name,
    };
  }
}
