//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class GetStatus200ResponseStats {
  /// Returns a new [GetStatus200ResponseStats] instance.
  GetStatus200ResponseStats({
    required this.agents,
    required this.ships,
    required this.systems,
    required this.waypoints,
  });

  int agents;

  int ships;

  int systems;

  int waypoints;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetStatus200ResponseStats &&
          other.agents == agents &&
          other.ships == ships &&
          other.systems == systems &&
          other.waypoints == waypoints;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (agents.hashCode) +
      (ships.hashCode) +
      (systems.hashCode) +
      (waypoints.hashCode);

  @override
  String toString() =>
      'GetStatus200ResponseStats[agents=$agents, ships=$ships, systems=$systems, waypoints=$waypoints]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'agents'] = this.agents;
    json[r'ships'] = this.ships;
    json[r'systems'] = this.systems;
    json[r'waypoints'] = this.waypoints;
    return json;
  }

  /// Returns a new [GetStatus200ResponseStats] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GetStatus200ResponseStats? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "GetStatus200ResponseStats[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "GetStatus200ResponseStats[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GetStatus200ResponseStats(
        agents: mapValueOfType<int>(json, r'agents')!,
        ships: mapValueOfType<int>(json, r'ships')!,
        systems: mapValueOfType<int>(json, r'systems')!,
        waypoints: mapValueOfType<int>(json, r'waypoints')!,
      );
    }
    return null;
  }

  static List<GetStatus200ResponseStats>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GetStatus200ResponseStats>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GetStatus200ResponseStats.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GetStatus200ResponseStats> mapFromJson(dynamic json) {
    final map = <String, GetStatus200ResponseStats>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GetStatus200ResponseStats.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GetStatus200ResponseStats-objects as value to a dart map
  static Map<String, List<GetStatus200ResponseStats>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GetStatus200ResponseStats>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GetStatus200ResponseStats.listFromJson(
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
    'agents',
    'ships',
    'systems',
    'waypoints',
  };
}
