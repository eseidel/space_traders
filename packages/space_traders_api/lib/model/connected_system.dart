//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class ConnectedSystem {
  /// Returns a new [ConnectedSystem] instance.
  ConnectedSystem({
    required this.symbol,
    required this.sectorSymbol,
    required this.type,
    this.factionSymbol,
    required this.x,
    required this.y,
    required this.distance,
  });

  /// The symbol of the system.
  String symbol;

  /// The sector of this system.
  String sectorSymbol;

  SystemType type;

  /// The symbol of the faction that owns the connected jump gate in the system.
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? factionSymbol;

  /// Position in the universe in the x axis.
  int x;

  /// Position in the universe in the y axis.
  int y;

  /// The distance of this system to the connected Jump Gate.
  int distance;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectedSystem &&
          other.symbol == symbol &&
          other.sectorSymbol == sectorSymbol &&
          other.type == type &&
          other.factionSymbol == factionSymbol &&
          other.x == x &&
          other.y == y &&
          other.distance == distance;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode) +
      (sectorSymbol.hashCode) +
      (type.hashCode) +
      (factionSymbol == null ? 0 : factionSymbol!.hashCode) +
      (x.hashCode) +
      (y.hashCode) +
      (distance.hashCode);

  @override
  String toString() =>
      'ConnectedSystem[symbol=$symbol, sectorSymbol=$sectorSymbol, type=$type, factionSymbol=$factionSymbol, x=$x, y=$y, distance=$distance]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    json[r'sectorSymbol'] = this.sectorSymbol;
    json[r'type'] = this.type;
    if (this.factionSymbol != null) {
      json[r'factionSymbol'] = this.factionSymbol;
    } else {
      json[r'factionSymbol'] = null;
    }
    json[r'x'] = this.x;
    json[r'y'] = this.y;
    json[r'distance'] = this.distance;
    return json;
  }

  /// Returns a new [ConnectedSystem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ConnectedSystem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ConnectedSystem[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ConnectedSystem[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ConnectedSystem(
        symbol: mapValueOfType<String>(json, r'symbol')!,
        sectorSymbol: mapValueOfType<String>(json, r'sectorSymbol')!,
        type: SystemType.fromJson(json[r'type'])!,
        factionSymbol: mapValueOfType<String>(json, r'factionSymbol'),
        x: mapValueOfType<int>(json, r'x')!,
        y: mapValueOfType<int>(json, r'y')!,
        distance: mapValueOfType<int>(json, r'distance')!,
      );
    }
    return null;
  }

  static List<ConnectedSystem>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ConnectedSystem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ConnectedSystem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ConnectedSystem> mapFromJson(dynamic json) {
    final map = <String, ConnectedSystem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ConnectedSystem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ConnectedSystem-objects as value to a dart map
  static Map<String, List<ConnectedSystem>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ConnectedSystem>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ConnectedSystem.listFromJson(
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
    'symbol',
    'sectorSymbol',
    'type',
    'x',
    'y',
    'distance',
  };
}
