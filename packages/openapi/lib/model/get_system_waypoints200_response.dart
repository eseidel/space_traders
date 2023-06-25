//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class GetSystemWaypoints200Response {
  /// Returns a new [GetSystemWaypoints200Response] instance.
  GetSystemWaypoints200Response({
    this.data = const [],
    required this.meta,
  });

  List<Waypoint> data;

  Meta meta;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetSystemWaypoints200Response &&
          other.data == data &&
          other.meta == meta;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (data.hashCode) + (meta.hashCode);

  @override
  String toString() => 'GetSystemWaypoints200Response[data=$data, meta=$meta]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'data'] = this.data;
    json[r'meta'] = this.meta;
    return json;
  }

  /// Returns a new [GetSystemWaypoints200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GetSystemWaypoints200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "GetSystemWaypoints200Response[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "GetSystemWaypoints200Response[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GetSystemWaypoints200Response(
        data: Waypoint.listFromJson(json[r'data'])!,
        meta: Meta.fromJson(json[r'meta'])!,
      );
    }
    return null;
  }

  static List<GetSystemWaypoints200Response>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GetSystemWaypoints200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GetSystemWaypoints200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GetSystemWaypoints200Response> mapFromJson(dynamic json) {
    final map = <String, GetSystemWaypoints200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GetSystemWaypoints200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GetSystemWaypoints200Response-objects as value to a dart map
  static Map<String, List<GetSystemWaypoints200Response>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GetSystemWaypoints200Response>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GetSystemWaypoints200Response.listFromJson(
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
    'data',
    'meta',
  };
}
