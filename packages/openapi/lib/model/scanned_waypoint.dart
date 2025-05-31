import 'package:openapi/model/chart.dart';
import 'package:openapi/model/waypoint_faction.dart';
import 'package:openapi/model/waypoint_orbital.dart';
import 'package:openapi/model/waypoint_trait.dart';
import 'package:openapi/model/waypoint_type.dart';
import 'package:openapi/model_helpers.dart';

class ScannedWaypoint {
  ScannedWaypoint({
    required this.symbol,
    required this.type,
    required this.systemSymbol,
    required this.x,
    required this.y,
    this.orbitals = const [],
    this.faction,
    this.traits = const [],
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
          (json['orbitals'] as List)
              .map<WaypointOrbital>(
                (e) => WaypointOrbital.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      faction: WaypointFaction.maybeFromJson(
        json['faction'] as Map<String, dynamic>?,
      ),
      traits:
          (json['traits'] as List)
              .map<WaypointTrait>(
                (e) => WaypointTrait.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      chart: Chart.maybeFromJson(json['chart'] as Map<String, dynamic>?),
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

  @override
  int get hashCode => Object.hash(
    symbol,
    type,
    systemSymbol,
    x,
    y,
    orbitals,
    faction,
    traits,
    chart,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScannedWaypoint &&
        symbol == other.symbol &&
        type == other.type &&
        systemSymbol == other.systemSymbol &&
        x == other.x &&
        y == other.y &&
        listsEqual(orbitals, other.orbitals) &&
        faction == other.faction &&
        listsEqual(traits, other.traits) &&
        chart == other.chart;
  }
}
