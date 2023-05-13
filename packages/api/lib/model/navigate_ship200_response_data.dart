//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class NavigateShip200ResponseData {
  /// Returns a new [NavigateShip200ResponseData] instance.
  NavigateShip200ResponseData({
    required this.fuel,
    required this.nav,
  });

  ShipFuel fuel;

  ShipNav nav;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NavigateShip200ResponseData &&
     other.fuel == fuel &&
     other.nav == nav;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (fuel.hashCode) +
    (nav.hashCode);

  @override
  String toString() => 'NavigateShip200ResponseData[fuel=$fuel, nav=$nav]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'fuel'] = this.fuel;
      json[r'nav'] = this.nav;
    return json;
  }

  /// Returns a new [NavigateShip200ResponseData] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NavigateShip200ResponseData? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NavigateShip200ResponseData[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NavigateShip200ResponseData[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NavigateShip200ResponseData(
        fuel: ShipFuel.fromJson(json[r'fuel'])!,
        nav: ShipNav.fromJson(json[r'nav'])!,
      );
    }
    return null;
  }

  static List<NavigateShip200ResponseData>? listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NavigateShip200ResponseData>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NavigateShip200ResponseData.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NavigateShip200ResponseData> mapFromJson(dynamic json) {
    final map = <String, NavigateShip200ResponseData>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NavigateShip200ResponseData.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NavigateShip200ResponseData-objects as value to a dart map
  static Map<String, List<NavigateShip200ResponseData>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NavigateShip200ResponseData>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NavigateShip200ResponseData.listFromJson(entry.value, growable: growable,);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'fuel',
    'nav',
  };
}

