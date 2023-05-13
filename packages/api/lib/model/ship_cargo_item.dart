//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class ShipCargoItem {
  /// Returns a new [ShipCargoItem] instance.
  ShipCargoItem({
    required this.symbol,
    required this.name,
    required this.description,
    required this.units,
  });

  /// The unique identifier of the cargo item type.
  String symbol;

  /// The name of the cargo item type.
  String name;

  /// The description of the cargo item type.
  String description;

  /// The number of units of the cargo item.
  ///
  /// Minimum value: 1
  int units;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ShipCargoItem &&
     other.symbol == symbol &&
     other.name == name &&
     other.description == description &&
     other.units == units;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (symbol.hashCode) +
    (name.hashCode) +
    (description.hashCode) +
    (units.hashCode);

  @override
  String toString() => 'ShipCargoItem[symbol=$symbol, name=$name, description=$description, units=$units]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'symbol'] = this.symbol;
      json[r'name'] = this.name;
      json[r'description'] = this.description;
      json[r'units'] = this.units;
    return json;
  }

  /// Returns a new [ShipCargoItem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ShipCargoItem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ShipCargoItem[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ShipCargoItem[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ShipCargoItem(
        symbol: mapValueOfType<String>(json, r'symbol')!,
        name: mapValueOfType<String>(json, r'name')!,
        description: mapValueOfType<String>(json, r'description')!,
        units: mapValueOfType<int>(json, r'units')!,
      );
    }
    return null;
  }

  static List<ShipCargoItem>? listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ShipCargoItem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipCargoItem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ShipCargoItem> mapFromJson(dynamic json) {
    final map = <String, ShipCargoItem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipCargoItem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ShipCargoItem-objects as value to a dart map
  static Map<String, List<ShipCargoItem>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ShipCargoItem>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipCargoItem.listFromJson(entry.value, growable: growable,);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'symbol',
    'name',
    'description',
    'units',
  };
}

