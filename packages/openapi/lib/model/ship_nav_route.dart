//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class ShipNavRoute {
  /// Returns a new [ShipNavRoute] instance.
  ShipNavRoute({
    required this.destination,
    required this.origin,
    required this.departureTime,
    required this.arrival,
  });

  ShipNavRouteWaypoint destination;

  ShipNavRouteWaypoint origin;

  /// The date time of the ship's departure.
  DateTime departureTime;

  /// The date time of the ship's arrival. If the ship is in-transit, this is the expected time of arrival.
  DateTime arrival;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShipNavRoute &&
          other.destination == destination &&
          other.origin == origin &&
          other.departureTime == departureTime &&
          other.arrival == arrival;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (destination.hashCode) +
      (origin.hashCode) +
      (departureTime.hashCode) +
      (arrival.hashCode);

  @override
  String toString() =>
      'ShipNavRoute[destination=$destination, origin=$origin, departureTime=$departureTime, arrival=$arrival]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'destination'] = this.destination;
    json[r'origin'] = this.origin;
    json[r'departureTime'] = this.departureTime.toUtc().toIso8601String();
    json[r'arrival'] = this.arrival.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [ShipNavRoute] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ShipNavRoute? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ShipNavRoute[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ShipNavRoute[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ShipNavRoute(
        destination: ShipNavRouteWaypoint.fromJson(json[r'destination'])!,
        origin: ShipNavRouteWaypoint.fromJson(json[r'origin'])!,
        departureTime: mapDateTime(json, r'departureTime', r'')!,
        arrival: mapDateTime(json, r'arrival', r'')!,
      );
    }
    return null;
  }

  static List<ShipNavRoute> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipNavRoute>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipNavRoute.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ShipNavRoute> mapFromJson(dynamic json) {
    final map = <String, ShipNavRoute>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipNavRoute.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ShipNavRoute-objects as value to a dart map
  static Map<String, List<ShipNavRoute>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ShipNavRoute>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ShipNavRoute.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'destination',
    'origin',
    'departureTime',
    'arrival',
  };
}
