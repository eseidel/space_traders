//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class GetStatus200ResponseHealth {
  /// Returns a new [GetStatus200ResponseHealth] instance.
  GetStatus200ResponseHealth({
    this.lastMarketUpdate,
  });

  /// The date/time when the market was last updated.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? lastMarketUpdate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetStatus200ResponseHealth &&
          other.lastMarketUpdate == lastMarketUpdate;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (lastMarketUpdate == null ? 0 : lastMarketUpdate!.hashCode);

  @override
  String toString() =>
      'GetStatus200ResponseHealth[lastMarketUpdate=$lastMarketUpdate]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.lastMarketUpdate != null) {
      json[r'lastMarketUpdate'] = this.lastMarketUpdate;
    } else {
      json[r'lastMarketUpdate'] = null;
    }
    return json;
  }

  /// Returns a new [GetStatus200ResponseHealth] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GetStatus200ResponseHealth? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "GetStatus200ResponseHealth[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "GetStatus200ResponseHealth[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GetStatus200ResponseHealth(
        lastMarketUpdate: mapValueOfType<String>(json, r'lastMarketUpdate'),
      );
    }
    return null;
  }

  static List<GetStatus200ResponseHealth> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GetStatus200ResponseHealth>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GetStatus200ResponseHealth.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GetStatus200ResponseHealth> mapFromJson(dynamic json) {
    final map = <String, GetStatus200ResponseHealth>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GetStatus200ResponseHealth.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GetStatus200ResponseHealth-objects as value to a dart map
  static Map<String, List<GetStatus200ResponseHealth>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GetStatus200ResponseHealth>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GetStatus200ResponseHealth.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{};
}
