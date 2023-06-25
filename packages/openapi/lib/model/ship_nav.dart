//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class ShipNav {
  /// Returns a new [ShipNav] instance.
  ShipNav({
    required this.systemSymbol,
    required this.waypointSymbol,
    required this.route,
    required this.status,
    required this.flightMode,
  });

  /// The system symbol of the ship's current location.
  String systemSymbol;

  /// The waypoint symbol of the ship's current location, or if the ship is in-transit, the waypoint symbol of the ship's destination.
  String waypointSymbol;

  ShipNavRoute route;

  ShipNavStatus status;

  ShipNavFlightMode flightMode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShipNav &&
          other.systemSymbol == systemSymbol &&
          other.waypointSymbol == waypointSymbol &&
          other.route == route &&
          other.status == status &&
          other.flightMode == flightMode;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (systemSymbol.hashCode) +
      (waypointSymbol.hashCode) +
      (route.hashCode) +
      (status.hashCode) +
      (flightMode.hashCode);

  @override
  String toString() =>
      'ShipNav[systemSymbol=$systemSymbol, waypointSymbol=$waypointSymbol, route=$route, status=$status, flightMode=$flightMode]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'systemSymbol'] = this.systemSymbol;
    json[r'waypointSymbol'] = this.waypointSymbol;
    json[r'route'] = this.route;
    json[r'status'] = this.status;
    json[r'flightMode'] = this.flightMode;
    return json;
  }

  /// Returns a new [ShipNav] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ShipNav? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ShipNav[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ShipNav[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ShipNav(
        systemSymbol: mapValueOfType<String>(json, r'systemSymbol')!,
        waypointSymbol: mapValueOfType<String>(json, r'waypointSymbol')!,
        route: ShipNavRoute.fromJson(json[r'route'])!,
        status: ShipNavStatus.fromJson(json[r'status'])!,
        flightMode: ShipNavFlightMode.fromJson(json[r'flightMode'])!,
      );
    }
    return null;
  }

  static List<ShipNav>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipNav>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipNav.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ShipNav> mapFromJson(dynamic json) {
    final map = <String, ShipNav>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipNav.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ShipNav-objects as value to a dart map
  static Map<String, List<ShipNav>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ShipNav>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipNav.listFromJson(
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
    'systemSymbol',
    'waypointSymbol',
    'route',
    'status',
    'flightMode',
  };
}
