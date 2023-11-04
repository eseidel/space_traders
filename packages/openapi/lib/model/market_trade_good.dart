//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class MarketTradeGood {
  /// Returns a new [MarketTradeGood] instance.
  MarketTradeGood({
    required this.symbol,
    required this.type,
    required this.tradeVolume,
    required this.supply,
    this.activity,
    required this.purchasePrice,
    required this.sellPrice,
  });

  TradeSymbol symbol;

  /// The type of trade good (export, import, or exchange).
  MarketTradeGoodTypeEnum type;

  /// This is the maximum number of units that can be purchased or sold at this market in a single trade for this good. Trade volume also gives an indication of price volatility. A market with a low trade volume will have large price swings, while high trade volume will be more resilient to price changes.
  ///
  /// Minimum value: 1
  int tradeVolume;

  SupplyLevel supply;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  ActivityLevel? activity;

  /// The price at which this good can be purchased from the market.
  ///
  /// Minimum value: 0
  int purchasePrice;

  /// The price at which this good can be sold to the market.
  ///
  /// Minimum value: 0
  int sellPrice;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketTradeGood &&
          other.symbol == symbol &&
          other.type == type &&
          other.tradeVolume == tradeVolume &&
          other.supply == supply &&
          other.activity == activity &&
          other.purchasePrice == purchasePrice &&
          other.sellPrice == sellPrice;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode) +
      (type.hashCode) +
      (tradeVolume.hashCode) +
      (supply.hashCode) +
      (activity == null ? 0 : activity!.hashCode) +
      (purchasePrice.hashCode) +
      (sellPrice.hashCode);

  @override
  String toString() =>
      'MarketTradeGood[symbol=$symbol, type=$type, tradeVolume=$tradeVolume, supply=$supply, activity=$activity, purchasePrice=$purchasePrice, sellPrice=$sellPrice]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    json[r'type'] = this.type;
    json[r'tradeVolume'] = this.tradeVolume;
    json[r'supply'] = this.supply;
    if (this.activity != null) {
      json[r'activity'] = this.activity;
    } else {
      json[r'activity'] = null;
    }
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
          assert(json.containsKey(key),
              'Required key "MarketTradeGood[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "MarketTradeGood[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return MarketTradeGood(
        symbol: TradeSymbol.fromJson(json[r'symbol'])!,
        type: MarketTradeGoodTypeEnum.fromJson(json[r'type'])!,
        tradeVolume: mapValueOfType<int>(json, r'tradeVolume')!,
        supply: SupplyLevel.fromJson(json[r'supply'])!,
        activity: ActivityLevel.fromJson(json[r'activity']),
        purchasePrice: mapValueOfType<int>(json, r'purchasePrice')!,
        sellPrice: mapValueOfType<int>(json, r'sellPrice')!,
      );
    }
    return null;
  }

  static List<MarketTradeGood> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
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
  static Map<String, List<MarketTradeGood>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<MarketTradeGood>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MarketTradeGood.listFromJson(
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
    'tradeVolume',
    'supply',
    'purchasePrice',
    'sellPrice',
  };
}

/// The type of trade good (export, import, or exchange).
class MarketTradeGoodTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const MarketTradeGoodTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const EXPORT = MarketTradeGoodTypeEnum._(r'EXPORT');
  static const IMPORT = MarketTradeGoodTypeEnum._(r'IMPORT');
  static const EXCHANGE = MarketTradeGoodTypeEnum._(r'EXCHANGE');

  /// List of all possible values in this [enum][MarketTradeGoodTypeEnum].
  static const values = <MarketTradeGoodTypeEnum>[
    EXPORT,
    IMPORT,
    EXCHANGE,
  ];

  static MarketTradeGoodTypeEnum? fromJson(dynamic value) =>
      MarketTradeGoodTypeEnumTypeTransformer().decode(value);

  static List<MarketTradeGoodTypeEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <MarketTradeGoodTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MarketTradeGoodTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [MarketTradeGoodTypeEnum] to String,
/// and [decode] dynamic data back to [MarketTradeGoodTypeEnum].
class MarketTradeGoodTypeEnumTypeTransformer {
  factory MarketTradeGoodTypeEnumTypeTransformer() =>
      _instance ??= const MarketTradeGoodTypeEnumTypeTransformer._();

  const MarketTradeGoodTypeEnumTypeTransformer._();

  String encode(MarketTradeGoodTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a MarketTradeGoodTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  MarketTradeGoodTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'EXPORT':
          return MarketTradeGoodTypeEnum.EXPORT;
        case r'IMPORT':
          return MarketTradeGoodTypeEnum.IMPORT;
        case r'EXCHANGE':
          return MarketTradeGoodTypeEnum.EXCHANGE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [MarketTradeGoodTypeEnumTypeTransformer] instance.
  static MarketTradeGoodTypeEnumTypeTransformer? _instance;
}
