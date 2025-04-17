//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class CreateShipWaypointScan201ResponseData {
  /// Returns a new [CreateShipWaypointScan201ResponseData] instance.
  CreateShipWaypointScan201ResponseData({
    required this.cooldown,
    this.waypoints = const [],
  });

  Cooldown cooldown;

  /// List of scanned waypoints.
  List<ScannedWaypoint> waypoints;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateShipWaypointScan201ResponseData &&
          other.cooldown == cooldown &&
          _deepEquality.equals(other.waypoints, waypoints);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (cooldown.hashCode) + (waypoints.hashCode);

  @override
  String toString() =>
      'CreateShipWaypointScan201ResponseData[cooldown=$cooldown, waypoints=$waypoints]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'cooldown'] = this.cooldown;
    json[r'waypoints'] = this.waypoints;
    return json;
  }

  /// Returns a new [CreateShipWaypointScan201ResponseData] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateShipWaypointScan201ResponseData? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "CreateShipWaypointScan201ResponseData[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "CreateShipWaypointScan201ResponseData[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CreateShipWaypointScan201ResponseData(
        cooldown: Cooldown.fromJson(json[r'cooldown'])!,
        waypoints: ScannedWaypoint.listFromJson(json[r'waypoints']),
      );
    }
    return null;
  }

  static List<CreateShipWaypointScan201ResponseData> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreateShipWaypointScan201ResponseData>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateShipWaypointScan201ResponseData.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateShipWaypointScan201ResponseData> mapFromJson(
      dynamic json) {
    final map = <String, CreateShipWaypointScan201ResponseData>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value =
            CreateShipWaypointScan201ResponseData.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateShipWaypointScan201ResponseData-objects as value to a dart map
  static Map<String, List<CreateShipWaypointScan201ResponseData>>
      mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CreateShipWaypointScan201ResponseData>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateShipWaypointScan201ResponseData.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'cooldown',
    'waypoints',
  };
}
