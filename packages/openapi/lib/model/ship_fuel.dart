//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class ShipFuel {
  /// Returns a new [ShipFuel] instance.
  ShipFuel({
    required this.current,
    required this.capacity,
    this.consumed,
  });

  /// The current amount of fuel in the ship's tanks.
  ///
  /// Minimum value: 0
  int current;

  /// The maximum amount of fuel the ship's tanks can hold.
  ///
  /// Minimum value: 0
  int capacity;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  ShipFuelConsumed? consumed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShipFuel &&
          other.current == current &&
          other.capacity == capacity &&
          other.consumed == consumed;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (current.hashCode) +
      (capacity.hashCode) +
      (consumed == null ? 0 : consumed!.hashCode);

  @override
  String toString() =>
      'ShipFuel[current=$current, capacity=$capacity, consumed=$consumed]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'current'] = this.current;
    json[r'capacity'] = this.capacity;
    if (this.consumed != null) {
      json[r'consumed'] = this.consumed;
    } else {
      json[r'consumed'] = null;
    }
    return json;
  }

  /// Returns a new [ShipFuel] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ShipFuel? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ShipFuel[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ShipFuel[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ShipFuel(
        current: mapValueOfType<int>(json, r'current')!,
        capacity: mapValueOfType<int>(json, r'capacity')!,
        consumed: ShipFuelConsumed.fromJson(json[r'consumed']),
      );
    }
    return null;
  }

  static List<ShipFuel>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipFuel>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipFuel.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ShipFuel> mapFromJson(dynamic json) {
    final map = <String, ShipFuel>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipFuel.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ShipFuel-objects as value to a dart map
  static Map<String, List<ShipFuel>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ShipFuel>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipFuel.listFromJson(
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
    'current',
    'capacity',
  };
}
