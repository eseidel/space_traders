import 'package:openapi/model/chart.dart';
import 'package:openapi/model/waypoint_faction.dart';
import 'package:openapi/model/waypoint_orbital.dart';
import 'package:openapi/model/waypoint_trait.dart';
import 'package:openapi/model/waypoint_type.dart';

class ScannedWaypoint {
  ScannedWaypoint({
    required this.symbol,
    required this.type,
    required this.systemSymbol,
    required this.x,
    required this.y,
    required this.orbitals,
    required this.traits,
    this.faction,
    this.chart,
  });

  factory ScannedWaypoint.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ScannedWaypoint(
      symbol: json['symbol'] as String,
      type: WaypointType.fromJson(json['type'] as String),
      systemSymbol: json['systemSymbol'] as String,
      x: json['x'] as int,
      y: json['y'] as int,
      orbitals:
          (json['orbitals'] as List<dynamic>)
              .map<WaypointOrbital>(
                (e) => WaypointOrbital.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      faction: WaypointFaction.fromJson(
        json['faction'] as Map<String, dynamic>,
      ),
      traits:
          (json['traits'] as List<dynamic>)
              .map<WaypointTrait>(
                (e) => WaypointTrait.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      chart: Chart.fromJson(json['chart'] as Map<String, dynamic>),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ScannedWaypoint? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ScannedWaypoint.fromJson(json);
  }

  String symbol;
  WaypointType type;
  String systemSymbol;
  int x;
  int y;
  List<WaypointOrbital> orbitals;
  WaypointFaction? faction;
  List<WaypointTrait> traits;
  Chart? chart;

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'type': type.toJson(),
      'systemSymbol': systemSymbol,
      'x': x,
      'y': y,
      'orbitals': orbitals.map((e) => e.toJson()).toList(),
      'faction': faction?.toJson(),
      'traits': traits.map((e) => e.toJson()).toList(),
      'chart': chart?.toJson(),
    };
  }
}
