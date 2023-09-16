//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class GetStatus200ResponseAnnouncementsInner {
  /// Returns a new [GetStatus200ResponseAnnouncementsInner] instance.
  GetStatus200ResponseAnnouncementsInner({
    required this.title,
    required this.body,
  });

  String title;

  String body;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetStatus200ResponseAnnouncementsInner &&
          other.title == title &&
          other.body == body;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (title.hashCode) + (body.hashCode);

  @override
  String toString() =>
      'GetStatus200ResponseAnnouncementsInner[title=$title, body=$body]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'title'] = this.title;
    json[r'body'] = this.body;
    return json;
  }

  /// Returns a new [GetStatus200ResponseAnnouncementsInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GetStatus200ResponseAnnouncementsInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "GetStatus200ResponseAnnouncementsInner[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "GetStatus200ResponseAnnouncementsInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GetStatus200ResponseAnnouncementsInner(
        title: mapValueOfType<String>(json, r'title')!,
        body: mapValueOfType<String>(json, r'body')!,
      );
    }
    return null;
  }

  static List<GetStatus200ResponseAnnouncementsInner> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <GetStatus200ResponseAnnouncementsInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GetStatus200ResponseAnnouncementsInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GetStatus200ResponseAnnouncementsInner> mapFromJson(
      dynamic json) {
    final map = <String, GetStatus200ResponseAnnouncementsInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value =
            GetStatus200ResponseAnnouncementsInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GetStatus200ResponseAnnouncementsInner-objects as value to a dart map
  static Map<String, List<GetStatus200ResponseAnnouncementsInner>>
      mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<GetStatus200ResponseAnnouncementsInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GetStatus200ResponseAnnouncementsInner.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'title',
    'body',
  };
}
