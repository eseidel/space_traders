//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class RefuelShipRequest {
  /// Returns a new [RefuelShipRequest] instance.
  RefuelShipRequest({
    this.units,
    this.fromCargo,
  });

  /// The amount of fuel to fill in the ship's tanks. When not specified, the ship will be refueled to its maximum fuel capacity. If the amount specified is greater than the ship's remaining capacity, the ship will only be refueled to its maximum fuel capacity. The amount specified is not in market units but in ship fuel units.
  ///
  /// Minimum value: 1
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? units;

  bool? fromCargo;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RefuelShipRequest &&
          other.units == units &&
          other.fromCargo == fromCargo;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (units == null ? 0 : units!.hashCode) +
      (fromCargo == null ? 0 : fromCargo!.hashCode);

  @override
  String toString() => 'RefuelShipRequest[units=$units, fromCargo=$fromCargo]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.units != null) {
      json[r'units'] = this.units;
    } else {
      json[r'units'] = null;
    }
    if (this.fromCargo != null) {
      json[r'fromCargo'] = this.fromCargo;
    } else {
      json[r'fromCargo'] = null;
    }
    return json;
  }

  /// Returns a new [RefuelShipRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RefuelShipRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "RefuelShipRequest[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "RefuelShipRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return RefuelShipRequest(
        units: mapValueOfType<int>(json, r'units'),
        fromCargo: mapValueOfType<bool>(json, r'fromCargo'),
      );
    }
    return null;
  }

  static List<RefuelShipRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <RefuelShipRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RefuelShipRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RefuelShipRequest> mapFromJson(dynamic json) {
    final map = <String, RefuelShipRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RefuelShipRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RefuelShipRequest-objects as value to a dart map
  static Map<String, List<RefuelShipRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<RefuelShipRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RefuelShipRequest.listFromJson(
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
