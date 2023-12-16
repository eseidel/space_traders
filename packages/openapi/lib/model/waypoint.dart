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
    this.orbits,
    this.faction,
    this.traits = const [],
    this.modifiers = const [],
    this.chart,
    required this.isUnderConstruction,
  });

  /// The symbol of the waypoint.
  String symbol;

  WaypointType type;

  /// The symbol of the system.
  String systemSymbol;

  /// Relative position of the waypoint on the system's x axis. This is not an absolute position in the universe.
  int x;

  /// Relative position of the waypoint on the system's y axis. This is not an absolute position in the universe.
  int y;

  /// Waypoints that orbit this waypoint.
  List<WaypointOrbital> orbitals;

  /// The symbol of the parent waypoint, if this waypoint is in orbit around another waypoint. Otherwise this value is undefined.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? orbits;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  WaypointFaction? faction;

  /// The traits of the waypoint.
  List<WaypointTrait> traits;

  /// The modifiers of the waypoint.
  List<WaypointModifier> modifiers;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Chart? chart;

  /// True if the waypoint is under construction.
  bool isUnderConstruction;

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
          other.orbits == orbits &&
          other.faction == faction &&
          other.traits == traits &&
          other.modifiers == modifiers &&
          other.chart == chart &&
          other.isUnderConstruction == isUnderConstruction;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode) +
      (type.hashCode) +
      (systemSymbol.hashCode) +
      (x.hashCode) +
      (y.hashCode) +
      (orbitals.hashCode) +
      (orbits == null ? 0 : orbits!.hashCode) +
      (faction == null ? 0 : faction!.hashCode) +
      (traits.hashCode) +
      (modifiers.hashCode) +
      (chart == null ? 0 : chart!.hashCode) +
      (isUnderConstruction.hashCode);

  @override
  String toString() =>
      'Waypoint[symbol=$symbol, type=$type, systemSymbol=$systemSymbol, x=$x, y=$y, orbitals=$orbitals, orbits=$orbits, faction=$faction, traits=$traits, modifiers=$modifiers, chart=$chart, isUnderConstruction=$isUnderConstruction]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    json[r'type'] = this.type;
    json[r'systemSymbol'] = this.systemSymbol;
    json[r'x'] = this.x;
    json[r'y'] = this.y;
    json[r'orbitals'] = this.orbitals;
    if (this.orbits != null) {
      json[r'orbits'] = this.orbits;
    } else {
      json[r'orbits'] = null;
    }
    if (this.faction != null) {
      json[r'faction'] = this.faction;
    } else {
      json[r'faction'] = null;
    }
    json[r'traits'] = this.traits;
    json[r'modifiers'] = this.modifiers;
    if (this.chart != null) {
      json[r'chart'] = this.chart;
    } else {
      json[r'chart'] = null;
    }
    json[r'isUnderConstruction'] = this.isUnderConstruction;
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
        orbitals: WaypointOrbital.listFromJson(json[r'orbitals']),
        orbits: mapValueOfType<String>(json, r'orbits'),
        faction: WaypointFaction.fromJson(json[r'faction']),
        traits: WaypointTrait.listFromJson(json[r'traits']),
        modifiers: WaypointModifier.listFromJson(json[r'modifiers']),
        chart: Chart.fromJson(json[r'chart']),
        isUnderConstruction:
            mapValueOfType<bool>(json, r'isUnderConstruction')!,
      );
    }
    return null;
  }

  static List<Waypoint> listFromJson(
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
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Waypoint.listFromJson(
          entry.value,
          growable: growable,
        );
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
    'isUnderConstruction',
  };
}
