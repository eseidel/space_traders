//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class GetShipyard200Response {
  /// Returns a new [GetShipyard200Response] instance.
  GetShipyard200Response({
    required this.data,
  });

  Shipyard data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetShipyard200Response && other.data == data;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (data.hashCode);

  @override
  String toString() => 'GetShipyard200Response[data=$data]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'data'] = this.data;
    return json;
  }

  /// Returns a new [GetShipyard200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GetShipyard200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "GetShipyard200Response[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "GetShipyard200Response[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GetShipyard200Response(
        data: Shipyard.fromJson(json[r'data'])!,
      );
    }
    return null;
  }

  static List<GetShipyard200Response> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GetShipyard200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GetShipyard200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GetShipyard200Response> mapFromJson(dynamic json) {
    final map = <String, GetShipyard200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GetShipyard200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GetShipyard200Response-objects as value to a dart map
  static Map<String, List<GetShipyard200Response>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GetShipyard200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GetShipyard200Response.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'data',
  };
}
