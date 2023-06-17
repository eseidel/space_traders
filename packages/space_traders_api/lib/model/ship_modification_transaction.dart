//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class ShipModificationTransaction {
  /// Returns a new [ShipModificationTransaction] instance.
  ShipModificationTransaction({
    required this.waypointSymbol,
    required this.shipSymbol,
    required this.tradeSymbol,
    required this.totalPrice,
    required this.timestamp,
  });

  /// The symbol of the waypoint where the transaction took place.
  String waypointSymbol;

  /// The symbol of the ship that made the transaction.
  String shipSymbol;

  /// The symbol of the trade good.
  String tradeSymbol;

  /// The total price of the transaction.
  ///
  /// Minimum value: 0
  int totalPrice;

  /// The timestamp of the transaction.
  DateTime timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShipModificationTransaction &&
          other.waypointSymbol == waypointSymbol &&
          other.shipSymbol == shipSymbol &&
          other.tradeSymbol == tradeSymbol &&
          other.totalPrice == totalPrice &&
          other.timestamp == timestamp;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (waypointSymbol.hashCode) +
      (shipSymbol.hashCode) +
      (tradeSymbol.hashCode) +
      (totalPrice.hashCode) +
      (timestamp.hashCode);

  @override
  String toString() =>
      'ShipModificationTransaction[waypointSymbol=$waypointSymbol, shipSymbol=$shipSymbol, tradeSymbol=$tradeSymbol, totalPrice=$totalPrice, timestamp=$timestamp]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'waypointSymbol'] = this.waypointSymbol;
    json[r'shipSymbol'] = this.shipSymbol;
    json[r'tradeSymbol'] = this.tradeSymbol;
    json[r'totalPrice'] = this.totalPrice;
    json[r'timestamp'] = this.timestamp.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [ShipModificationTransaction] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ShipModificationTransaction? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ShipModificationTransaction[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ShipModificationTransaction[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ShipModificationTransaction(
        waypointSymbol: mapValueOfType<String>(json, r'waypointSymbol')!,
        shipSymbol: mapValueOfType<String>(json, r'shipSymbol')!,
        tradeSymbol: mapValueOfType<String>(json, r'tradeSymbol')!,
        totalPrice: mapValueOfType<int>(json, r'totalPrice')!,
        timestamp: mapDateTime(json, r'timestamp', '')!,
      );
    }
    return null;
  }

  static List<ShipModificationTransaction>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ShipModificationTransaction>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipModificationTransaction.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ShipModificationTransaction> mapFromJson(dynamic json) {
    final map = <String, ShipModificationTransaction>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipModificationTransaction.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ShipModificationTransaction-objects as value to a dart map
  static Map<String, List<ShipModificationTransaction>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ShipModificationTransaction>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipModificationTransaction.listFromJson(
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
    'waypointSymbol',
    'shipSymbol',
    'tradeSymbol',
    'totalPrice',
    'timestamp',
  };
}
