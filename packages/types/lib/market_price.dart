import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:types/price.dart';
import 'package:types/types.dart';

// {"waypointSymbol": "X1-ZS60-53675E", "symbol": "IRON_ORE", "supply":
// "ABUNDANT", "purchasePrice": 6, "sellPrice": 4, "tradeVolume": 1000,
// "timestamp": "2023-05-14T21:52:56.530126100+00:00"}
/// Transaction data for a single trade symbol at a single waypoint.
@immutable
class MarketPrice extends PriceBase<TradeSymbol> {
  /// Create a new price record.
  const MarketPrice({
    required super.waypointSymbol,
    required super.symbol,
    required this.supply,
    required this.purchasePrice,
    required this.sellPrice,
    required this.tradeVolume,
    required super.timestamp,
    this.activity,
  });

  /// Create a new price record from a market trade good.
  factory MarketPrice.fromMarketTradeGood(
    MarketTradeGood good,
    WaypointSymbol waypointSymbol,
  ) =>
      MarketPrice(
        waypointSymbol: waypointSymbol,
        symbol: good.symbol,
        supply: good.supply,
        purchasePrice: good.purchasePrice,
        sellPrice: good.sellPrice,
        tradeVolume: good.tradeVolume,
        timestamp: DateTime.now(),
        activity: good.activity,
      );

  /// Create a new price record from a json map.
  factory MarketPrice.fromJson(Map<String, dynamic> json) {
    return MarketPrice(
      waypointSymbol: WaypointSymbol.fromJson(json['waypointSymbol'] as String),
      symbol: TradeSymbol.fromJson(json['symbol'] as String)!,
      supply: SupplyLevel.fromJson(json['supply'] as String)!,
      purchasePrice: json['purchasePrice'] as int,
      sellPrice: json['sellPrice'] as int,
      tradeVolume: json['tradeVolume'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      activity: ActivityLevel.fromJson(json['activity'] as String?),
    );
  }

  /// Create a new price record from a json map, or null if the map is null.
  static MarketPrice? fromJsonOrNull(Map<String, dynamic>? json) =>
      json == null ? null : MarketPrice.fromJson(json);

  /// Serialize Price as a json map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'waypointSymbol': waypointSymbol.toJson(),
      'symbol': symbol.toJson(),
      'supply': supply.toJson(),
      'purchasePrice': purchasePrice,
      'sellPrice': sellPrice,
      'tradeVolume': tradeVolume,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'activity': activity?.toJson(),
    };
  }

  /// The symbol of the trade good.
  TradeSymbol get tradeSymbol => symbol;

  /// The supply level of the trade good.
  final SupplyLevel supply;

  /// The activity level of the trade good.
  final ActivityLevel? activity;

  /// The price at which this good can be purchased from the market.
  final int purchasePrice;

  /// The price at which this good can be sold to the market.
  final int sellPrice;

  /// The trade volume of the trade good.
  final int tradeVolume;

  @override
  String toString() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketPrice &&
          runtimeType == other.runtimeType &&
          waypointSymbol == other.waypointSymbol &&
          symbol == other.symbol &&
          supply == other.supply &&
          purchasePrice == other.purchasePrice &&
          sellPrice == other.sellPrice &&
          tradeVolume == other.tradeVolume &&
          timestamp == other.timestamp &&
          activity == other.activity;

  @override
  int get hashCode => Object.hash(
        waypointSymbol,
        symbol,
        supply,
        purchasePrice,
        sellPrice,
        tradeVolume,
        timestamp,
        activity,
      );
}
