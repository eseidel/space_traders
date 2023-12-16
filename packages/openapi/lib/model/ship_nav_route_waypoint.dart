//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class ShipNavRouteWaypoint {
  /// Returns a new [ShipNavRouteWaypoint] instance.
  ShipNavRouteWaypoint({
    required this.symbol,
    required this.type,
    required this.systemSymbol,
    required this.x,
    required this.y,
  });

  /// The symbol of the waypoint.
  String symbol;

  WaypointType type;

  /// The symbol of the system.
  String systemSymbol;

  /// Position in the universe in the x axis.
  int x;

  /// Position in the universe in the y axis.
  int y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShipNavRouteWaypoint &&
          other.symbol == symbol &&
          other.type == type &&
          other.systemSymbol == systemSymbol &&
          other.x == x &&
          other.y == y;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode) +
      (type.hashCode) +
      (systemSymbol.hashCode) +
      (x.hashCode) +
      (y.hashCode);

  @override
  String toString() =>
      'ShipNavRouteWaypoint[symbol=$symbol, type=$type, systemSymbol=$systemSymbol, x=$x, y=$y]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    json[r'type'] = this.type;
    json[r'systemSymbol'] = this.systemSymbol;
    json[r'x'] = this.x;
    json[r'y'] = this.y;
    return json;
  }

  /// Returns a new [ShipNavRouteWaypoint] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ShipNavRouteWaypoint? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ShipNavRouteWaypoint[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ShipNavRouteWaypoint[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ShipNavRouteWaypoint(
        symbol: mapValueOfType<String>(json, r'symbol')!,
        type: WaypointType.fromJson(json[r'type'])!,
        systemSymbol: mapValueOfType<String>(json, r'systemSymbol')!,
        x: mapValueOfType<int>(json, r'x')!,
        y: mapValueOfType<int>(json, r'y')!,
      );
    }
    return null;
  }

  static List<ShipNavRouteWaypoint> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipNavRouteWaypoint>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipNavRouteWaypoint.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ShipNavRouteWaypoint> mapFromJson(dynamic json) {
    final map = <String, ShipNavRouteWaypoint>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipNavRouteWaypoint.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ShipNavRouteWaypoint-objects as value to a dart map
  static Map<String, List<ShipNavRouteWaypoint>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ShipNavRouteWaypoint>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ShipNavRouteWaypoint.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'symbol',
    'type',
    'systemSymbol',
    'x',
    'y',
  };
}
