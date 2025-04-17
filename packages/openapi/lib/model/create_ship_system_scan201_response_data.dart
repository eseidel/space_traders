//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class CreateShipSystemScan201ResponseData {
  /// Returns a new [CreateShipSystemScan201ResponseData] instance.
  CreateShipSystemScan201ResponseData({
    required this.cooldown,
    this.systems = const [],
  });

  Cooldown cooldown;

  /// List of scanned systems.
  List<ScannedSystem> systems;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateShipSystemScan201ResponseData &&
          other.cooldown == cooldown &&
          _deepEquality.equals(other.systems, systems);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (cooldown.hashCode) + (systems.hashCode);

  @override
  String toString() =>
      'CreateShipSystemScan201ResponseData[cooldown=$cooldown, systems=$systems]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'cooldown'] = this.cooldown;
    json[r'systems'] = this.systems;
    return json;
  }

  /// Returns a new [CreateShipSystemScan201ResponseData] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateShipSystemScan201ResponseData? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "CreateShipSystemScan201ResponseData[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "CreateShipSystemScan201ResponseData[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CreateShipSystemScan201ResponseData(
        cooldown: Cooldown.fromJson(json[r'cooldown'])!,
        systems: ScannedSystem.listFromJson(json[r'systems']),
      );
    }
    return null;
  }

  static List<CreateShipSystemScan201ResponseData> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <CreateShipSystemScan201ResponseData>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateShipSystemScan201ResponseData.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateShipSystemScan201ResponseData> mapFromJson(
      dynamic json) {
    final map = <String, CreateShipSystemScan201ResponseData>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateShipSystemScan201ResponseData.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateShipSystemScan201ResponseData-objects as value to a dart map
  static Map<String, List<CreateShipSystemScan201ResponseData>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<CreateShipSystemScan201ResponseData>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateShipSystemScan201ResponseData.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'cooldown',
    'systems',
  };
}
