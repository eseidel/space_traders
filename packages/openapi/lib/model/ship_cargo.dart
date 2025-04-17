//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class ShipCargo {
  /// Returns a new [ShipCargo] instance.
  ShipCargo({
    required this.capacity,
    required this.units,
    this.inventory = const [],
  });

  /// The max number of items that can be stored in the cargo hold.
  ///
  /// Minimum value: 0
  int capacity;

  /// The number of items currently stored in the cargo hold.
  ///
  /// Minimum value: 0
  int units;

  /// The items currently in the cargo hold.
  List<ShipCargoItem> inventory;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShipCargo &&
          other.capacity == capacity &&
          other.units == units &&
          _deepEquality.equals(other.inventory, inventory);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (capacity.hashCode) + (units.hashCode) + (inventory.hashCode);

  @override
  String toString() =>
      'ShipCargo[capacity=$capacity, units=$units, inventory=$inventory]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'capacity'] = this.capacity;
    json[r'units'] = this.units;
    json[r'inventory'] = this.inventory;
    return json;
  }

  /// Returns a new [ShipCargo] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ShipCargo? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ShipCargo[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ShipCargo[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ShipCargo(
        capacity: mapValueOfType<int>(json, r'capacity')!,
        units: mapValueOfType<int>(json, r'units')!,
        inventory: ShipCargoItem.listFromJson(json[r'inventory']),
      );
    }
    return null;
  }

  static List<ShipCargo> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipCargo>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipCargo.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ShipCargo> mapFromJson(dynamic json) {
    final map = <String, ShipCargo>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipCargo.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ShipCargo-objects as value to a dart map
  static Map<String, List<ShipCargo>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ShipCargo>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ShipCargo.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'capacity',
    'units',
    'inventory',
  };
}
