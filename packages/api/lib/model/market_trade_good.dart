//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of space_traders_api;

class MarketTradeGood {
  /// Returns a new [MarketTradeGood] instance.
  MarketTradeGood({
    required this.symbol,
    required this.tradeVolume,
    required this.supply,
    required this.purchasePrice,
    required this.sellPrice,
  });

  /// The symbol of the trade good.
  String symbol;

  /// The typical volume flowing through the market for this type of good. The larger the trade volume, the more stable prices will be.
  ///
  /// Minimum value: 1
  int tradeVolume;

  /// A rough estimate of the total supply of this good in the marketplace.
  MarketTradeGoodSupplyEnum supply;

  /// The price at which this good can be purchased from the market.
  ///
  /// Minimum value: 0
  int purchasePrice;

  /// The price at which this good can be sold to the market.
  ///
  /// Minimum value: 0
  int sellPrice;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MarketTradeGood &&
     other.symbol == symbol &&
     other.tradeVolume == tradeVolume &&
     other.supply == supply &&
     other.purchasePrice == purchasePrice &&
     other.sellPrice == sellPrice;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (symbol.hashCode) +
    (tradeVolume.hashCode) +
    (supply.hashCode) +
    (purchasePrice.hashCode) +
    (sellPrice.hashCode);

  @override
  String toString() => 'MarketTradeGood[symbol=$symbol, tradeVolume=$tradeVolume, supply=$supply, purchasePrice=$purchasePrice, sellPrice=$sellPrice]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'symbol'] = this.symbol;
      json[r'tradeVolume'] = this.tradeVolume;
      json[r'supply'] = this.supply;
      json[r'purchasePrice'] = this.purchasePrice;
      json[r'sellPrice'] = this.sellPrice;
    return json;
  }

  /// Returns a new [MarketTradeGood] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MarketTradeGood? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "MarketTradeGood[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "MarketTradeGood[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return MarketTradeGood(
        symbol: mapValueOfType<String>(json, r'symbol')!,
        tradeVolume: mapValueOfType<int>(json, r'tradeVolume')!,
        supply: MarketTradeGoodSupplyEnum.fromJson(json[r'supply'])!,
        purchasePrice: mapValueOfType<int>(json, r'purchasePrice')!,
        sellPrice: mapValueOfType<int>(json, r'sellPrice')!,
      );
    }
    return null;
  }

  static List<MarketTradeGood>? listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MarketTradeGood>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MarketTradeGood.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MarketTradeGood> mapFromJson(dynamic json) {
    final map = <String, MarketTradeGood>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MarketTradeGood.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MarketTradeGood-objects as value to a dart map
  static Map<String, List<MarketTradeGood>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MarketTradeGood>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MarketTradeGood.listFromJson(entry.value, growable: growable,);
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
    'tradeVolume',
    'supply',
    'purchasePrice',
    'sellPrice',
  };
}

/// A rough estimate of the total supply of this good in the marketplace.
class MarketTradeGoodSupplyEnum {
  /// Instantiate a new enum with the provided [value].
  const MarketTradeGoodSupplyEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const SCARCE = MarketTradeGoodSupplyEnum._(r'SCARCE');
  static const LIMITED = MarketTradeGoodSupplyEnum._(r'LIMITED');
  static const MODERATE = MarketTradeGoodSupplyEnum._(r'MODERATE');
  static const ABUNDANT = MarketTradeGoodSupplyEnum._(r'ABUNDANT');

  /// List of all possible values in this [enum][MarketTradeGoodSupplyEnum].
  static const values = <MarketTradeGoodSupplyEnum>[
    SCARCE,
    LIMITED,
    MODERATE,
    ABUNDANT,
  ];

  static MarketTradeGoodSupplyEnum? fromJson(dynamic value) => MarketTradeGoodSupplyEnumTypeTransformer().decode(value);

  static List<MarketTradeGoodSupplyEnum>? listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MarketTradeGoodSupplyEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MarketTradeGoodSupplyEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [MarketTradeGoodSupplyEnum] to String,
/// and [decode] dynamic data back to [MarketTradeGoodSupplyEnum].
class MarketTradeGoodSupplyEnumTypeTransformer {
  factory MarketTradeGoodSupplyEnumTypeTransformer() => _instance ??= const MarketTradeGoodSupplyEnumTypeTransformer._();

  const MarketTradeGoodSupplyEnumTypeTransformer._();

  String encode(MarketTradeGoodSupplyEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a MarketTradeGoodSupplyEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  MarketTradeGoodSupplyEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'SCARCE': return MarketTradeGoodSupplyEnum.SCARCE;
        case r'LIMITED': return MarketTradeGoodSupplyEnum.LIMITED;
        case r'MODERATE': return MarketTradeGoodSupplyEnum.MODERATE;
        case r'ABUNDANT': return MarketTradeGoodSupplyEnum.ABUNDANT;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [MarketTradeGoodSupplyEnumTypeTransformer] instance.
  static MarketTradeGoodSupplyEnumTypeTransformer? _instance;
}


