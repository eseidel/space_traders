//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class SiphonResources201ResponseData {
  /// Returns a new [SiphonResources201ResponseData] instance.
  SiphonResources201ResponseData({
    required this.cooldown,
    required this.siphon,
    required this.cargo,
    this.events = const [],
  });

  Cooldown cooldown;

  Siphon siphon;

  ShipCargo cargo;

  List<ShipConditionEvent> events;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiphonResources201ResponseData &&
          other.cooldown == cooldown &&
          other.siphon == siphon &&
          other.cargo == cargo &&
          _deepEquality.equals(other.events, events);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (cooldown.hashCode) +
      (siphon.hashCode) +
      (cargo.hashCode) +
      (events.hashCode);

  @override
  String toString() =>
      'SiphonResources201ResponseData[cooldown=$cooldown, siphon=$siphon, cargo=$cargo, events=$events]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'cooldown'] = this.cooldown;
    json[r'siphon'] = this.siphon;
    json[r'cargo'] = this.cargo;
    json[r'events'] = this.events;
    return json;
  }

  /// Returns a new [SiphonResources201ResponseData] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SiphonResources201ResponseData? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "SiphonResources201ResponseData[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "SiphonResources201ResponseData[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SiphonResources201ResponseData(
        cooldown: Cooldown.fromJson(json[r'cooldown'])!,
        siphon: Siphon.fromJson(json[r'siphon'])!,
        cargo: ShipCargo.fromJson(json[r'cargo'])!,
        events: ShipConditionEvent.listFromJson(json[r'events']),
      );
    }
    return null;
  }

  static List<SiphonResources201ResponseData> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <SiphonResources201ResponseData>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SiphonResources201ResponseData.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SiphonResources201ResponseData> mapFromJson(dynamic json) {
    final map = <String, SiphonResources201ResponseData>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SiphonResources201ResponseData.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SiphonResources201ResponseData-objects as value to a dart map
  static Map<String, List<SiphonResources201ResponseData>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<SiphonResources201ResponseData>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SiphonResources201ResponseData.listFromJson(
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
    'siphon',
    'cargo',
    'events',
  };
}
