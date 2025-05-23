import 'package:spacetraders/model/chart.dart';
import 'package:spacetraders/model/waypoint_faction.dart';
import 'package:spacetraders/model/waypoint_orbital.dart';
import 'package:spacetraders/model/waypoint_trait.dart';
import 'package:spacetraders/model/waypoint_type.dart';

class ScannedWaypoint {
  ScannedWaypoint({
    required this.symbol,
    required this.type,
    required this.systemSymbol,
    required this.x,
    required this.y,
    required this.orbitals,
    required this.faction,
    required this.traits,
    required this.chart,
  });

  factory ScannedWaypoint.fromJson(Map<String, dynamic> json) {
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

  final String symbol;
  final WaypointType type;
  final String systemSymbol;
  final int x;
  final int y;
  final List<WaypointOrbital> orbitals;
  final WaypointFaction faction;
  final List<WaypointTrait> traits;
  final Chart chart;

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'type': type.toJson(),
      'systemSymbol': systemSymbol,
      'x': x,
      'y': y,
      'orbitals': orbitals.map((e) => e.toJson()).toList(),
      'faction': faction.toJson(),
      'traits': traits.map((e) => e.toJson()).toList(),
      'chart': chart.toJson(),
    };
  }
}
