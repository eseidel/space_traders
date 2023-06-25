//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class System {
  /// Returns a new [System] instance.
  System({
    required this.symbol,
    required this.sectorSymbol,
    required this.type,
    required this.x,
    required this.y,
    this.waypoints = const [],
    this.factions = const [],
  });

  /// The symbol of the system.
  String symbol;

  /// The symbol of the sector.
  String sectorSymbol;

  SystemType type;

  /// Position in the universe in the x axis.
  int x;

  /// Position in the universe in the y axis.
  int y;

  /// Waypoints in this system.
  List<SystemWaypoint> waypoints;

  /// Factions that control this system.
  List<SystemFaction> factions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is System &&
          other.symbol == symbol &&
          other.sectorSymbol == sectorSymbol &&
          other.type == type &&
          other.x == x &&
          other.y == y &&
          other.waypoints == waypoints &&
          other.factions == factions;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode) +
      (sectorSymbol.hashCode) +
      (type.hashCode) +
      (x.hashCode) +
      (y.hashCode) +
      (waypoints.hashCode) +
      (factions.hashCode);

  @override
  String toString() =>
      'System[symbol=$symbol, sectorSymbol=$sectorSymbol, type=$type, x=$x, y=$y, waypoints=$waypoints, factions=$factions]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    json[r'sectorSymbol'] = this.sectorSymbol;
    json[r'type'] = this.type;
    json[r'x'] = this.x;
    json[r'y'] = this.y;
    json[r'waypoints'] = this.waypoints;
    json[r'factions'] = this.factions;
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
        symbol: mapValueOfType<String>(json, r'symbol')!,
        sectorSymbol: mapValueOfType<String>(json, r'sectorSymbol')!,
        type: SystemType.fromJson(json[r'type'])!,
        x: mapValueOfType<int>(json, r'x')!,
        y: mapValueOfType<int>(json, r'y')!,
        waypoints: SystemWaypoint.listFromJson(json[r'waypoints'])!,
        factions: SystemFaction.listFromJson(json[r'factions'])!,
      );
    }
    return null;
  }

  static List<System>? listFromJson(
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
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = System.listFromJson(
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
    'sectorSymbol',
    'type',
    'x',
    'y',
    'waypoints',
    'factions',
  };
}
