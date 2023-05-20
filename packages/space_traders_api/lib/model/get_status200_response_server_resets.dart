//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class GetStatus200ResponseServerResets {
  /// Returns a new [GetStatus200ResponseServerResets] instance.
  GetStatus200ResponseServerResets({
    required this.next,
    required this.frequency,
  });

  /// The date and time when the game server will reset.
  String next;

  /// How often we intend to reset the game server.
  String frequency;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetStatus200ResponseServerResets &&
          other.next == next &&
          other.frequency == frequency;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (next.hashCode) + (frequency.hashCode);

  @override
  String toString() =>
      'GetStatus200ResponseServerResets[next=$next, frequency=$frequency]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'next'] = this.next;
    json[r'frequency'] = this.frequency;
    return json;
  }

  /// Returns a new [GetStatus200ResponseServerResets] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GetStatus200ResponseServerResets? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "GetStatus200ResponseServerResets[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "GetStatus200ResponseServerResets[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GetStatus200ResponseServerResets(
        next: mapValueOfType<String>(json, r'next')!,
        frequency: mapValueOfType<String>(json, r'frequency')!,
      );
    }
    return null;
  }

  static List<GetStatus200ResponseServerResets>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GetStatus200ResponseServerResets>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GetStatus200ResponseServerResets.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GetStatus200ResponseServerResets> mapFromJson(
      dynamic json) {
    final map = <String, GetStatus200ResponseServerResets>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GetStatus200ResponseServerResets.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GetStatus200ResponseServerResets-objects as value to a dart map
  static Map<String, List<GetStatus200ResponseServerResets>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GetStatus200ResponseServerResets>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GetStatus200ResponseServerResets.listFromJson(
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
    'next',
    'frequency',
  };
}
