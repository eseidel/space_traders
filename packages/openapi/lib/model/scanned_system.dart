//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class ScannedSystem {
  /// Returns a new [ScannedSystem] instance.
  ScannedSystem({
    required this.symbol,
    required this.sectorSymbol,
    required this.type,
    required this.x,
    required this.y,
    required this.distance,
  });

  /// Symbol of the system.
  String symbol;

  /// Symbol of the system's sector.
  String sectorSymbol;

  SystemType type;

  /// Position in the universe in the x axis.
  int x;

  /// Position in the universe in the y axis.
  int y;

  /// The system's distance from the scanning ship.
  int distance;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScannedSystem &&
          other.symbol == symbol &&
          other.sectorSymbol == sectorSymbol &&
          other.type == type &&
          other.x == x &&
          other.y == y &&
          other.distance == distance;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode) +
      (sectorSymbol.hashCode) +
      (type.hashCode) +
      (x.hashCode) +
      (y.hashCode) +
      (distance.hashCode);

  @override
  String toString() =>
      'ScannedSystem[symbol=$symbol, sectorSymbol=$sectorSymbol, type=$type, x=$x, y=$y, distance=$distance]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    json[r'sectorSymbol'] = this.sectorSymbol;
    json[r'type'] = this.type;
    json[r'x'] = this.x;
    json[r'y'] = this.y;
    json[r'distance'] = this.distance;
    return json;
  }

  /// Returns a new [ScannedSystem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ScannedSystem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ScannedSystem[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ScannedSystem[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ScannedSystem(
        symbol: mapValueOfType<String>(json, r'symbol')!,
        sectorSymbol: mapValueOfType<String>(json, r'sectorSymbol')!,
        type: SystemType.fromJson(json[r'type'])!,
        x: mapValueOfType<int>(json, r'x')!,
        y: mapValueOfType<int>(json, r'y')!,
        distance: mapValueOfType<int>(json, r'distance')!,
      );
    }
    return null;
  }

  static List<ScannedSystem> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ScannedSystem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ScannedSystem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ScannedSystem> mapFromJson(dynamic json) {
    final map = <String, ScannedSystem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ScannedSystem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ScannedSystem-objects as value to a dart map
  static Map<String, List<ScannedSystem>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ScannedSystem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ScannedSystem.listFromJson(
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
    'sectorSymbol',
    'type',
    'x',
    'y',
    'distance',
  };
}
