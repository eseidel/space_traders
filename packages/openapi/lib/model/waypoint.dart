//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class Waypoint {
  /// Returns a new [Waypoint] instance.
  Waypoint({
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

  /// Symbol fo the waypoint.
  String symbol;

  WaypointType type;

  /// The symbol of the system this waypoint belongs to.
  String systemSymbol;

  /// Position in the universe in the x axis.
  int x;

  /// Position in the universe in the Y axis.
  int y;

  /// Waypoints that orbit this waypoint.
  List<WaypointOrbital> orbitals;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  WaypointFaction? faction;

  /// The traits of the waypoint.
  List<WaypointTrait> traits;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Chart? chart;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Waypoint &&
          other.symbol == symbol &&
          other.type == type &&
          other.systemSymbol == systemSymbol &&
          other.x == x &&
          other.y == y &&
          other.orbitals == orbitals &&
          other.faction == faction &&
          other.traits == traits &&
          other.chart == chart;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode) +
      (type.hashCode) +
      (systemSymbol.hashCode) +
      (x.hashCode) +
      (y.hashCode) +
      (orbitals.hashCode) +
      (faction == null ? 0 : faction!.hashCode) +
      (traits.hashCode) +
      (chart == null ? 0 : chart!.hashCode);

  @override
  String toString() =>
      'Waypoint[symbol=$symbol, type=$type, systemSymbol=$systemSymbol, x=$x, y=$y, orbitals=$orbitals, faction=$faction, traits=$traits, chart=$chart]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    json[r'type'] = this.type;
    json[r'systemSymbol'] = this.systemSymbol;
    json[r'x'] = this.x;
    json[r'y'] = this.y;
    json[r'orbitals'] = this.orbitals;
    if (this.faction != null) {
      json[r'faction'] = this.faction;
    } else {
      json[r'faction'] = null;
    }
    json[r'traits'] = this.traits;
    if (this.chart != null) {
      json[r'chart'] = this.chart;
    } else {
      json[r'chart'] = null;
    }
    return json;
  }

  /// Returns a new [Waypoint] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Waypoint? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Waypoint[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Waypoint[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Waypoint(
        symbol: mapValueOfType<String>(json, r'symbol')!,
        type: WaypointType.fromJson(json[r'type'])!,
        systemSymbol: mapValueOfType<String>(json, r'systemSymbol')!,
        x: mapValueOfType<int>(json, r'x')!,
        y: mapValueOfType<int>(json, r'y')!,
        orbitals: WaypointOrbital.listFromJson(json[r'orbitals'])!,
        faction: WaypointFaction.fromJson(json[r'faction']),
        traits: WaypointTrait.listFromJson(json[r'traits'])!,
        chart: Chart.fromJson(json[r'chart']),
      );
    }
    return null;
  }

  static List<Waypoint>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Waypoint>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Waypoint.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Waypoint> mapFromJson(dynamic json) {
    final map = <String, Waypoint>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Waypoint.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Waypoint-objects as value to a dart map
  static Map<String, List<Waypoint>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Waypoint>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Waypoint.listFromJson(
          entry.value,
          growable: growable,
        );
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'symbol',
    'type',
    'systemSymbol',
    'x',
    'y',
    'orbitals',
    'traits',
  };
}
