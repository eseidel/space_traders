//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class System {
  /// Returns a new [System] instance.
  System({
    this.constellation,
    required this.symbol,
    required this.sectorSymbol,
    required this.type,
    required this.x,
    required this.y,
    this.waypoints = const [],
    this.factions = const [],
    this.name,
  });

  /// The constellation that the system is part of.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? constellation;

  /// The symbol of the system.
  String symbol;

  /// The symbol of the sector.
  String sectorSymbol;

  SystemType type;

  /// Relative position of the system in the sector in the x axis.
  int x;

  /// Relative position of the system in the sector in the y axis.
  int y;

  /// Waypoints in this system.
  List<SystemWaypoint> waypoints;

  /// Factions that control this system.
  List<SystemFaction> factions;

  /// The name of the system.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is System &&
          other.constellation == constellation &&
          other.symbol == symbol &&
          other.sectorSymbol == sectorSymbol &&
          other.type == type &&
          other.x == x &&
          other.y == y &&
          _deepEquality.equals(other.waypoints, waypoints) &&
          _deepEquality.equals(other.factions, factions) &&
          other.name == name;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (constellation == null ? 0 : constellation!.hashCode) +
      (symbol.hashCode) +
      (sectorSymbol.hashCode) +
      (type.hashCode) +
      (x.hashCode) +
      (y.hashCode) +
      (waypoints.hashCode) +
      (factions.hashCode) +
      (name == null ? 0 : name!.hashCode);

  @override
  String toString() =>
      'System[constellation=$constellation, symbol=$symbol, sectorSymbol=$sectorSymbol, type=$type, x=$x, y=$y, waypoints=$waypoints, factions=$factions, name=$name]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.constellation != null) {
      json[r'constellation'] = this.constellation;
    } else {
      json[r'constellation'] = null;
    }
    json[r'symbol'] = this.symbol;
    json[r'sectorSymbol'] = this.sectorSymbol;
    json[r'type'] = this.type;
    json[r'x'] = this.x;
    json[r'y'] = this.y;
    json[r'waypoints'] = this.waypoints;
    json[r'factions'] = this.factions;
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    return json;
  }

  /// Returns a new [System] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static System? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "System[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "System[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return System(
        constellation: mapValueOfType<String>(json, r'constellation'),
        symbol: mapValueOfType<String>(json, r'symbol')!,
        sectorSymbol: mapValueOfType<String>(json, r'sectorSymbol')!,
        type: SystemType.fromJson(json[r'type'])!,
        x: mapValueOfType<int>(json, r'x')!,
        y: mapValueOfType<int>(json, r'y')!,
        waypoints: SystemWaypoint.listFromJson(json[r'waypoints']),
        factions: SystemFaction.listFromJson(json[r'factions']),
        name: mapValueOfType<String>(json, r'name'),
      );
    }
    return null;
  }

  static List<System> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <System>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = System.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, System> mapFromJson(dynamic json) {
    final map = <String, System>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = System.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of System-objects as value to a dart map
  static Map<String, List<System>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<System>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = System.listFromJson(
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
    'sectorSymbol',
    'type',
    'x',
    'y',
    'waypoints',
    'factions',
  };
}
