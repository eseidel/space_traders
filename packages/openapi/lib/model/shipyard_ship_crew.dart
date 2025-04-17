//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class ShipyardShipCrew {
  /// Returns a new [ShipyardShipCrew] instance.
  ShipyardShipCrew({
    required this.required_,
    required this.capacity,
  });

  int required_;

  int capacity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShipyardShipCrew &&
          other.required_ == required_ &&
          other.capacity == capacity;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (required_.hashCode) + (capacity.hashCode);

  @override
  String toString() =>
      'ShipyardShipCrew[required_=$required_, capacity=$capacity]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'required'] = this.required_;
    json[r'capacity'] = this.capacity;
    return json;
  }

  /// Returns a new [ShipyardShipCrew] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ShipyardShipCrew? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ShipyardShipCrew[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ShipyardShipCrew[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ShipyardShipCrew(
        required_: mapValueOfType<int>(json, r'required')!,
        capacity: mapValueOfType<int>(json, r'capacity')!,
      );
    }
    return null;
  }

  static List<ShipyardShipCrew> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipyardShipCrew>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipyardShipCrew.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ShipyardShipCrew> mapFromJson(dynamic json) {
    final map = <String, ShipyardShipCrew>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipyardShipCrew.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ShipyardShipCrew-objects as value to a dart map
  static Map<String, List<ShipyardShipCrew>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ShipyardShipCrew>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ShipyardShipCrew.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'required',
    'capacity',
  };
}
