//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class GetErrorCodes200Response {
  /// Returns a new [GetErrorCodes200Response] instance.
  GetErrorCodes200Response({
    this.errorCodes = const [],
  });

  List<GetErrorCodes200ResponseErrorCodesInner> errorCodes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetErrorCodes200Response &&
          _deepEquality.equals(other.errorCodes, errorCodes);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (errorCodes.hashCode);

  @override
  String toString() => 'GetErrorCodes200Response[errorCodes=$errorCodes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'errorCodes'] = this.errorCodes;
    return json;
  }

  /// Returns a new [GetErrorCodes200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GetErrorCodes200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "GetErrorCodes200Response[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "GetErrorCodes200Response[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GetErrorCodes200Response(
        errorCodes: GetErrorCodes200ResponseErrorCodesInner.listFromJson(
            json[r'errorCodes']),
      );
    }
    return null;
  }

  static List<GetErrorCodes200Response> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GetErrorCodes200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GetErrorCodes200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GetErrorCodes200Response> mapFromJson(dynamic json) {
    final map = <String, GetErrorCodes200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GetErrorCodes200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GetErrorCodes200Response-objects as value to a dart map
  static Map<String, List<GetErrorCodes200Response>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GetErrorCodes200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GetErrorCodes200Response.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'errorCodes',
  };
}
