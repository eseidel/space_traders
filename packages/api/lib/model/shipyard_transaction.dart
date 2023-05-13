//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class ShipyardTransaction {
  /// Returns a new [ShipyardTransaction] instance.
  ShipyardTransaction({
    required this.waypointSymbol,
    required this.shipSymbol,
    required this.price,
    required this.agentSymbol,
    required this.timestamp,
  });

  /// The symbol of the waypoint where the transaction took place.
  String waypointSymbol;

  /// The symbol of the ship that was purchased.
  String shipSymbol;

  /// The price of the transaction.
  ///
  /// Minimum value: 1
  int price;

  /// The symbol of the agent that made the transaction.
  String agentSymbol;

  /// The timestamp of the transaction.
  DateTime timestamp;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ShipyardTransaction &&
     other.waypointSymbol == waypointSymbol &&
     other.shipSymbol == shipSymbol &&
     other.price == price &&
     other.agentSymbol == agentSymbol &&
     other.timestamp == timestamp;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (waypointSymbol.hashCode) +
    (shipSymbol.hashCode) +
    (price.hashCode) +
    (agentSymbol.hashCode) +
    (timestamp.hashCode);

  @override
  String toString() => 'ShipyardTransaction[waypointSymbol=$waypointSymbol, shipSymbol=$shipSymbol, price=$price, agentSymbol=$agentSymbol, timestamp=$timestamp]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'waypointSymbol'] = this.waypointSymbol;
      json[r'shipSymbol'] = this.shipSymbol;
      json[r'price'] = this.price;
      json[r'agentSymbol'] = this.agentSymbol;
      json[r'timestamp'] = this.timestamp.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [ShipyardTransaction] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ShipyardTransaction? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ShipyardTransaction[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ShipyardTransaction[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ShipyardTransaction(
        waypointSymbol: mapValueOfType<String>(json, r'waypointSymbol')!,
        shipSymbol: mapValueOfType<String>(json, r'shipSymbol')!,
        price: mapValueOfType<int>(json, r'price')!,
        agentSymbol: mapValueOfType<String>(json, r'agentSymbol')!,
        timestamp: mapDateTime(json, r'timestamp', '')!,
      );
    }
    return null;
  }

  static List<ShipyardTransaction>? listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ShipyardTransaction>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipyardTransaction.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ShipyardTransaction> mapFromJson(dynamic json) {
    final map = <String, ShipyardTransaction>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipyardTransaction.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ShipyardTransaction-objects as value to a dart map
  static Map<String, List<ShipyardTransaction>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ShipyardTransaction>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ShipyardTransaction.listFromJson(entry.value, growable: growable,);
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
    'price',
    'agentSymbol',
    'timestamp',
  };
}

