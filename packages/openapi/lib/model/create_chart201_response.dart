//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class CreateChart201Response {
  /// Returns a new [CreateChart201Response] instance.
  CreateChart201Response({
    required this.data,
  });

  CreateChart201ResponseData data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateChart201Response && other.data == data;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (data.hashCode);

  @override
  String toString() => 'CreateChart201Response[data=$data]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'data'] = this.data;
    return json;
  }

  /// Returns a new [CreateChart201Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateChart201Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "CreateChart201Response[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "CreateChart201Response[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CreateChart201Response(
        data: CreateChart201ResponseData.fromJson(json[r'data'])!,
      );
    }
    return null;
  }

  static List<CreateChart201Response> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreateChart201Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateChart201Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateChart201Response> mapFromJson(dynamic json) {
    final map = <String, CreateChart201Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateChart201Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateChart201Response-objects as value to a dart map
  static Map<String, List<CreateChart201Response>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CreateChart201Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateChart201Response.listFromJson(
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
