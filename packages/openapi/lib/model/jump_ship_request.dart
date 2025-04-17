//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class JumpShipRequest {
  /// Returns a new [JumpShipRequest] instance.
  JumpShipRequest({
    required this.waypointSymbol,
  });

  /// The symbol of the waypoint to jump to. The destination must be a connected waypoint.
  String waypointSymbol;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JumpShipRequest && other.waypointSymbol == waypointSymbol;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (waypointSymbol.hashCode);

  @override
  String toString() => 'JumpShipRequest[waypointSymbol=$waypointSymbol]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'waypointSymbol'] = this.waypointSymbol;
    return json;
  }

  /// Returns a new [JumpShipRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static JumpShipRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "JumpShipRequest[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "JumpShipRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return JumpShipRequest(
        waypointSymbol: mapValueOfType<String>(json, r'waypointSymbol')!,
      );
    }
    return null;
  }

  static List<JumpShipRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <JumpShipRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = JumpShipRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, JumpShipRequest> mapFromJson(dynamic json) {
    final map = <String, JumpShipRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = JumpShipRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of JumpShipRequest-objects as value to a dart map
  static Map<String, List<JumpShipRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<JumpShipRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = JumpShipRequest.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'waypointSymbol',
  };
}
