//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class ExtractResources201ResponseData {
  /// Returns a new [ExtractResources201ResponseData] instance.
  ExtractResources201ResponseData({
    required this.cooldown,
    required this.extraction,
    required this.cargo,
  });

  Cooldown cooldown;

  Extraction extraction;

  ShipCargo cargo;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtractResources201ResponseData &&
          other.cooldown == cooldown &&
          other.extraction == extraction &&
          other.cargo == cargo;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (cooldown.hashCode) + (extraction.hashCode) + (cargo.hashCode);

  @override
  String toString() =>
      'ExtractResources201ResponseData[cooldown=$cooldown, extraction=$extraction, cargo=$cargo]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'cooldown'] = this.cooldown;
    json[r'extraction'] = this.extraction;
    json[r'cargo'] = this.cargo;
    return json;
  }

  /// Returns a new [ExtractResources201ResponseData] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ExtractResources201ResponseData? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ExtractResources201ResponseData[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ExtractResources201ResponseData[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ExtractResources201ResponseData(
        cooldown: Cooldown.fromJson(json[r'cooldown'])!,
        extraction: Extraction.fromJson(json[r'extraction'])!,
        cargo: ShipCargo.fromJson(json[r'cargo'])!,
      );
    }
    return null;
  }

  static List<ExtractResources201ResponseData>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ExtractResources201ResponseData>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ExtractResources201ResponseData.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ExtractResources201ResponseData> mapFromJson(
      dynamic json) {
    final map = <String, ExtractResources201ResponseData>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ExtractResources201ResponseData.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ExtractResources201ResponseData-objects as value to a dart map
  static Map<String, List<ExtractResources201ResponseData>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ExtractResources201ResponseData>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ExtractResources201ResponseData.listFromJson(
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
    'cooldown',
    'extraction',
    'cargo',
  };
}
