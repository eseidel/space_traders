//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class PatchShipNav200ResponseData {
  /// Returns a new [PatchShipNav200ResponseData] instance.
  PatchShipNav200ResponseData({
    required this.nav,
    required this.fuel,
    this.events = const [],
  });

  ShipNav nav;

  ShipFuel fuel;

  List<ShipConditionEvent> events;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatchShipNav200ResponseData &&
          other.nav == nav &&
          other.fuel == fuel &&
          _deepEquality.equals(other.events, events);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (nav.hashCode) + (fuel.hashCode) + (events.hashCode);

  @override
  String toString() =>
      'PatchShipNav200ResponseData[nav=$nav, fuel=$fuel, events=$events]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'nav'] = this.nav;
    json[r'fuel'] = this.fuel;
    json[r'events'] = this.events;
    return json;
  }

  /// Returns a new [PatchShipNav200ResponseData] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PatchShipNav200ResponseData? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "PatchShipNav200ResponseData[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "PatchShipNav200ResponseData[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PatchShipNav200ResponseData(
        nav: ShipNav.fromJson(json[r'nav'])!,
        fuel: ShipFuel.fromJson(json[r'fuel'])!,
        events: ShipConditionEvent.listFromJson(json[r'events']),
      );
    }
    return null;
  }

  static List<PatchShipNav200ResponseData> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PatchShipNav200ResponseData>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PatchShipNav200ResponseData.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PatchShipNav200ResponseData> mapFromJson(dynamic json) {
    final map = <String, PatchShipNav200ResponseData>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PatchShipNav200ResponseData.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PatchShipNav200ResponseData-objects as value to a dart map
  static Map<String, List<PatchShipNav200ResponseData>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PatchShipNav200ResponseData>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PatchShipNav200ResponseData.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'nav',
    'fuel',
    'events',
  };
}
