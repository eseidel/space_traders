//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class MarketTransaction {
  /// Returns a new [MarketTransaction] instance.
  MarketTransaction({
    required this.waypointSymbol,
    required this.shipSymbol,
    required this.tradeSymbol,
    required this.type,
    required this.units,
    required this.pricePerUnit,
    required this.totalPrice,
    required this.timestamp,
  });

  /// The symbol of the waypoint.
  String waypointSymbol;

  /// The symbol of the ship that made the transaction.
  String shipSymbol;

  /// The symbol of the trade good.
  String tradeSymbol;

  /// The type of transaction.
  MarketTransactionTypeEnum type;

  /// The number of units of the transaction.
  ///
  /// Minimum value: 0
  int units;

  /// The price per unit of the transaction.
  ///
  /// Minimum value: 0
  int pricePerUnit;

  /// The total price of the transaction.
  ///
  /// Minimum value: 0
  int totalPrice;

  /// The timestamp of the transaction.
  DateTime timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketTransaction &&
          other.waypointSymbol == waypointSymbol &&
          other.shipSymbol == shipSymbol &&
          other.tradeSymbol == tradeSymbol &&
          other.type == type &&
          other.units == units &&
          other.pricePerUnit == pricePerUnit &&
          other.totalPrice == totalPrice &&
          other.timestamp == timestamp;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (waypointSymbol.hashCode) +
      (shipSymbol.hashCode) +
      (tradeSymbol.hashCode) +
      (type.hashCode) +
      (units.hashCode) +
      (pricePerUnit.hashCode) +
      (totalPrice.hashCode) +
      (timestamp.hashCode);

  @override
  String toString() =>
      'MarketTransaction[waypointSymbol=$waypointSymbol, shipSymbol=$shipSymbol, tradeSymbol=$tradeSymbol, type=$type, units=$units, pricePerUnit=$pricePerUnit, totalPrice=$totalPrice, timestamp=$timestamp]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'waypointSymbol'] = this.waypointSymbol;
    json[r'shipSymbol'] = this.shipSymbol;
    json[r'tradeSymbol'] = this.tradeSymbol;
    json[r'type'] = this.type;
    json[r'units'] = this.units;
    json[r'pricePerUnit'] = this.pricePerUnit;
    json[r'totalPrice'] = this.totalPrice;
    json[r'timestamp'] = this.timestamp.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [MarketTransaction] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MarketTransaction? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "MarketTransaction[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "MarketTransaction[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return MarketTransaction(
        waypointSymbol: mapValueOfType<String>(json, r'waypointSymbol')!,
        shipSymbol: mapValueOfType<String>(json, r'shipSymbol')!,
        tradeSymbol: mapValueOfType<String>(json, r'tradeSymbol')!,
        type: MarketTransactionTypeEnum.fromJson(json[r'type'])!,
        units: mapValueOfType<int>(json, r'units')!,
        pricePerUnit: mapValueOfType<int>(json, r'pricePerUnit')!,
        totalPrice: mapValueOfType<int>(json, r'totalPrice')!,
        timestamp: mapDateTime(json, r'timestamp', r'')!,
      );
    }
    return null;
  }

  static List<MarketTransaction> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MarketTransaction>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MarketTransaction.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MarketTransaction> mapFromJson(dynamic json) {
    final map = <String, MarketTransaction>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MarketTransaction.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MarketTransaction-objects as value to a dart map
  static Map<String, List<MarketTransaction>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<MarketTransaction>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MarketTransaction.listFromJson(
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
    'tradeSymbol',
    'type',
    'units',
    'pricePerUnit',
    'totalPrice',
    'timestamp',
  };
}

/// The type of transaction.
class MarketTransactionTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const MarketTransactionTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const PURCHASE = MarketTransactionTypeEnum._(r'PURCHASE');
  static const SELL = MarketTransactionTypeEnum._(r'SELL');

  /// List of all possible values in this [enum][MarketTransactionTypeEnum].
  static const values = <MarketTransactionTypeEnum>[
    PURCHASE,
    SELL,
  ];

  static MarketTransactionTypeEnum? fromJson(dynamic value) =>
      MarketTransactionTypeEnumTypeTransformer().decode(value);

  static List<MarketTransactionTypeEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MarketTransactionTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MarketTransactionTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [MarketTransactionTypeEnum] to String,
/// and [decode] dynamic data back to [MarketTransactionTypeEnum].
class MarketTransactionTypeEnumTypeTransformer {
  factory MarketTransactionTypeEnumTypeTransformer() =>
      _instance ??= const MarketTransactionTypeEnumTypeTransformer._();

  const MarketTransactionTypeEnumTypeTransformer._();

  String encode(MarketTransactionTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a MarketTransactionTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  MarketTransactionTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'PURCHASE':
          return MarketTransactionTypeEnum.PURCHASE;
        case r'SELL':
          return MarketTransactionTypeEnum.SELL;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [MarketTransactionTypeEnumTypeTransformer] instance.
  static MarketTransactionTypeEnumTypeTransformer? _instance;
}
