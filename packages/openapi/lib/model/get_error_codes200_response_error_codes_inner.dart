//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class GetErrorCodes200ResponseErrorCodesInner {
  /// Returns a new [GetErrorCodes200ResponseErrorCodesInner] instance.
  GetErrorCodes200ResponseErrorCodesInner({
    required this.code,
    required this.name,
  });

  num code;

  String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetErrorCodes200ResponseErrorCodesInner &&
          other.code == code &&
          other.name == name;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (code.hashCode) + (name.hashCode);

  @override
  String toString() =>
      'GetErrorCodes200ResponseErrorCodesInner[code=$code, name=$name]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'code'] = this.code;
    json[r'name'] = this.name;
    return json;
  }

  /// Returns a new [GetErrorCodes200ResponseErrorCodesInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GetErrorCodes200ResponseErrorCodesInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "GetErrorCodes200ResponseErrorCodesInner[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "GetErrorCodes200ResponseErrorCodesInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GetErrorCodes200ResponseErrorCodesInner(
        code: num.parse('${json[r'code']}'),
        name: mapValueOfType<String>(json, r'name')!,
      );
    }
    return null;
  }

  static List<GetErrorCodes200ResponseErrorCodesInner> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GetErrorCodes200ResponseErrorCodesInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GetErrorCodes200ResponseErrorCodesInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GetErrorCodes200ResponseErrorCodesInner> mapFromJson(
      dynamic json) {
    final map = <String, GetErrorCodes200ResponseErrorCodesInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value =
            GetErrorCodes200ResponseErrorCodesInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GetErrorCodes200ResponseErrorCodesInner-objects as value to a dart map
  static Map<String, List<GetErrorCodes200ResponseErrorCodesInner>>
      mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GetErrorCodes200ResponseErrorCodesInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GetErrorCodes200ResponseErrorCodesInner.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'code',
    'name',
  };
}
