//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class ScrapTransaction {
  /// Returns a new [ScrapTransaction] instance.
  ScrapTransaction({
    required this.waypointSymbol,
    required this.shipSymbol,
    required this.totalPrice,
    required this.timestamp,
  });

  /// The symbol of the waypoint.
  String waypointSymbol;

  /// The symbol of the ship.
  String shipSymbol;

  /// The total price of the transaction.
  ///
  /// Minimum value: 0
  int totalPrice;

  /// The timestamp of the transaction.
  DateTime timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScrapTransaction &&
          other.waypointSymbol == waypointSymbol &&
          other.shipSymbol == shipSymbol &&
          other.totalPrice == totalPrice &&
          other.timestamp == timestamp;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (waypointSymbol.hashCode) +
      (shipSymbol.hashCode) +
      (totalPrice.hashCode) +
      (timestamp.hashCode);

  @override
  String toString() =>
      'ScrapTransaction[waypointSymbol=$waypointSymbol, shipSymbol=$shipSymbol, totalPrice=$totalPrice, timestamp=$timestamp]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'waypointSymbol'] = this.waypointSymbol;
    json[r'shipSymbol'] = this.shipSymbol;
    json[r'totalPrice'] = this.totalPrice;
    json[r'timestamp'] = this.timestamp.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [ScrapTransaction] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ScrapTransaction? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ScrapTransaction[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ScrapTransaction[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ScrapTransaction(
        waypointSymbol: mapValueOfType<String>(json, r'waypointSymbol')!,
        shipSymbol: mapValueOfType<String>(json, r'shipSymbol')!,
        totalPrice: mapValueOfType<int>(json, r'totalPrice')!,
        timestamp: mapDateTime(json, r'timestamp', r'')!,
      );
    }
    return null;
  }

  static List<ScrapTransaction> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ScrapTransaction>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ScrapTransaction.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ScrapTransaction> mapFromJson(dynamic json) {
    final map = <String, ScrapTransaction>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ScrapTransaction.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ScrapTransaction-objects as value to a dart map
  static Map<String, List<ScrapTransaction>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ScrapTransaction>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ScrapTransaction.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'waypointSymbol',
    'shipSymbol',
    'totalPrice',
    'timestamp',
  };
}
