//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi;

class Market {
  /// Returns a new [Market] instance.
  Market({
    required this.symbol,
    this.exports = const [],
    this.imports = const [],
    this.exchange = const [],
    this.transactions = const [],
    this.tradeGoods = const [],
  });

  /// The symbol of the market. The symbol is the same as the waypoint where the market is located.
  String symbol;

  /// The list of goods that are exported from this market.
  List<TradeGood> exports;

  /// The list of goods that are sought as imports in this market.
  List<TradeGood> imports;

  /// The list of goods that are bought and sold between agents at this market.
  List<TradeGood> exchange;

  /// The list of recent transactions at this market. Visible only when a ship is present at the market.
  List<MarketTransaction> transactions;

  /// The list of goods that are traded at this market. Visible only when a ship is present at the market.
  List<MarketTradeGood> tradeGoods;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Market &&
          other.symbol == symbol &&
          _deepEquality.equals(other.exports, exports) &&
          _deepEquality.equals(other.imports, imports) &&
          _deepEquality.equals(other.exchange, exchange) &&
          _deepEquality.equals(other.transactions, transactions) &&
          _deepEquality.equals(other.tradeGoods, tradeGoods);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (symbol.hashCode) +
      (exports.hashCode) +
      (imports.hashCode) +
      (exchange.hashCode) +
      (transactions.hashCode) +
      (tradeGoods.hashCode);

  @override
  String toString() =>
      'Market[symbol=$symbol, exports=$exports, imports=$imports, exchange=$exchange, transactions=$transactions, tradeGoods=$tradeGoods]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'symbol'] = this.symbol;
    json[r'exports'] = this.exports;
    json[r'imports'] = this.imports;
    json[r'exchange'] = this.exchange;
    json[r'transactions'] = this.transactions;
    json[r'tradeGoods'] = this.tradeGoods;
    return json;
  }

  /// Returns a new [Market] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Market? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Market[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Market[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Market(
        symbol: mapValueOfType<String>(json, r'symbol')!,
        exports: TradeGood.listFromJson(json[r'exports']),
        imports: TradeGood.listFromJson(json[r'imports']),
        exchange: TradeGood.listFromJson(json[r'exchange']),
        transactions: MarketTransaction.listFromJson(json[r'transactions']),
        tradeGoods: MarketTradeGood.listFromJson(json[r'tradeGoods']),
      );
    }
    return null;
  }

  static List<Market> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Market>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Market.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Market> mapFromJson(dynamic json) {
    final map = <String, Market>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Market.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Market-objects as value to a dart map
  static Map<String, List<Market>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Market>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Market.listFromJson(
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
    'exports',
    'imports',
    'exchange',
  };
}
