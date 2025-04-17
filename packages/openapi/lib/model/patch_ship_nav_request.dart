//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class PatchShipNavRequest {
  /// Returns a new [PatchShipNavRequest] instance.
  PatchShipNavRequest({
    this.flightMode,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  ShipNavFlightMode? flightMode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatchShipNavRequest && other.flightMode == flightMode;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (flightMode == null ? 0 : flightMode!.hashCode);

  @override
  String toString() => 'PatchShipNavRequest[flightMode=$flightMode]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.flightMode != null) {
      json[r'flightMode'] = this.flightMode;
    } else {
      json[r'flightMode'] = null;
    }
    return json;
  }

  /// Returns a new [PatchShipNavRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PatchShipNavRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "PatchShipNavRequest[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "PatchShipNavRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PatchShipNavRequest(
        flightMode: ShipNavFlightMode.fromJson(json[r'flightMode']),
      );
    }
    return null;
  }

  static List<PatchShipNavRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <PatchShipNavRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PatchShipNavRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PatchShipNavRequest> mapFromJson(dynamic json) {
    final map = <String, PatchShipNavRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PatchShipNavRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PatchShipNavRequest-objects as value to a dart map
  static Map<String, List<PatchShipNavRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<PatchShipNavRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PatchShipNavRequest.listFromJson(
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
