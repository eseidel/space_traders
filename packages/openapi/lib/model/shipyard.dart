//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class Shipyard {
  /// Returns a new [Shipyard] instance.
  Shipyard({
    required this.symbol,
    this.shipTypes = const [],
    this.transactions = const [],
    this.ships = const [],
    required this.modificationsFee,
  });

  /// The symbol of the shipyard. The symbol is the same as the waypoint where the shipyard is located.
  String symbol;

  /// The list of ship types available for purchase at this shipyard.
  List<ShipyardShipTypesInner> shipTypes;

  /// The list of recent transactions at this shipyard.
  List<ShipyardTransaction> transactions;

  /// The ships that are currently available for purchase at the shipyard.
  List<ShipyardShip> ships;

  /// The fee to modify a ship at this shipyard. This includes installing or removing modules and mounts on a ship. In the case of mounts, the fee is a flat rate per mount. In the case of modules, the fee is per slot the module occupies.
  int modificationsFee;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Shipyard &&
          other.symbol == symbol &&
          _deepEquality.equals(other.shipTypes, shipTypes) &&
          _deepEquality.equals(other.transactions, transactions) &&
          _deepEquality.equals(other.ships, ships) &&
          other.modificationsFee == modificationsFee;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode) +
      (shipTypes.hashCode) +
      (transactions.hashCode) +
      (ships.hashCode) +
      (modificationsFee.hashCode);

  @override
  String toString() =>
      'Shipyard[symbol=$symbol, shipTypes=$shipTypes, transactions=$transactions, ships=$ships, modificationsFee=$modificationsFee]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    json[r'shipTypes'] = this.shipTypes;
    json[r'transactions'] = this.transactions;
    json[r'ships'] = this.ships;
    json[r'modificationsFee'] = this.modificationsFee;
    return json;
  }

  /// Returns a new [Shipyard] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Shipyard? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Shipyard[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Shipyard[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Shipyard(
        symbol: mapValueOfType<String>(json, r'symbol')!,
        shipTypes: ShipyardShipTypesInner.listFromJson(json[r'shipTypes']),
        transactions: ShipyardTransaction.listFromJson(json[r'transactions']),
        ships: ShipyardShip.listFromJson(json[r'ships']),
        modificationsFee: mapValueOfType<int>(json, r'modificationsFee')!,
      );
    }
    return null;
  }

  static List<Shipyard> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Shipyard>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Shipyard.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Shipyard> mapFromJson(dynamic json) {
    final map = <String, Shipyard>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Shipyard.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Shipyard-objects as value to a dart map
  static Map<String, List<Shipyard>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Shipyard>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Shipyard.listFromJson(
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
    'shipTypes',
    'modificationsFee',
  };
}
