//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class GetStatus200ResponseStats {
  /// Returns a new [GetStatus200ResponseStats] instance.
  GetStatus200ResponseStats({
    this.accounts,
    required this.agents,
    required this.ships,
    required this.systems,
    required this.waypoints,
  });

  /// Total number of accounts registered on the game server.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? accounts;

  /// Number of registered agents in the game.
  int agents;

  /// Total number of ships in the game.
  int ships;

  /// Total number of systems in the game.
  int systems;

  /// Total number of waypoints in the game.
  int waypoints;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetStatus200ResponseStats &&
          other.accounts == accounts &&
          other.agents == agents &&
          other.ships == ships &&
          other.systems == systems &&
          other.waypoints == waypoints;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (accounts == null ? 0 : accounts!.hashCode) +
      (agents.hashCode) +
      (ships.hashCode) +
      (systems.hashCode) +
      (waypoints.hashCode);

  @override
  String toString() =>
      'GetStatus200ResponseStats[accounts=$accounts, agents=$agents, ships=$ships, systems=$systems, waypoints=$waypoints]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.accounts != null) {
      json[r'accounts'] = this.accounts;
    } else {
      json[r'accounts'] = null;
    }
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
        accounts: mapValueOfType<int>(json, r'accounts'),
        agents: mapValueOfType<int>(json, r'agents')!,
        ships: mapValueOfType<int>(json, r'ships')!,
        systems: mapValueOfType<int>(json, r'systems')!,
        waypoints: mapValueOfType<int>(json, r'waypoints')!,
      );
    }
    return null;
  }

  static List<GetStatus200ResponseStats> listFromJson(
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
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GetStatus200ResponseStats.listFromJson(
          entry.value,
          growable: growable,
        );
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
