import 'package:meta/meta.dart';
import 'package:types/types.dart';

// {"waypointSymbol": "X1-ZS60-53675E", "symbol": "IRON_ORE", "supply":
// "ABUNDANT", "purchasePrice": 6, "sellPrice": 4, "tradeVolume": 1000,
// "timestamp": "2023-05-14T21:52:56.530126100+00:00"}
/// Transaction data for a single trade symbol at a single waypoint.
@immutable
class MarketPrice {
  /// Create a new price record.
  const MarketPrice({
    required this.waypointSymbol,
    required this.symbol,
    required this.supply,
    required this.purchasePrice,
    required this.sellPrice,
    required this.tradeVolume,
    required this.timestamp,
  });

  /// Create a new price record from a market trade good.
  MarketPrice.fromMarketTradeGood(MarketTradeGood good, this.waypointSymbol)
      : symbol = good.tradeSymbol,
        supply = good.supply,
        purchasePrice = good.purchasePrice,
        sellPrice = good.sellPrice,
        tradeVolume = good.tradeVolume,
        timestamp = DateTime.timestamp();

  /// Create a new price record from a json map.
  factory MarketPrice.fromJson(Map<String, dynamic> json) {
    return MarketPrice(
      waypointSymbol: WaypointSymbol.fromJson(json['waypointSymbol'] as String),
      symbol: TradeSymbol.fromJson(json['symbol'] as String)!,
      supply: MarketTradeGoodSupplyEnum.fromJson(json['supply'] as String)!,
      purchasePrice: json['purchasePrice'] as int,
      sellPrice: json['sellPrice'] as int,
      tradeVolume: json['tradeVolume'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

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
    };
  }

  /// The waypoint of the market where this price was recorded.
  final WaypointSymbol waypointSymbol;

  /// The symbol of the trade good.
  // rename to tradeSymbol.
  final TradeSymbol symbol;

  /// The symbol of the trade good.
  TradeSymbol get tradeSymbol => symbol;

  /// The supply level of the trade good.
  final MarketTradeGoodSupplyEnum supply;

  /// The price at which this good can be purchased from the market.
  final int purchasePrice;

  /// The price at which this good can be sold to the market.
  final int sellPrice;

  /// The trade volume of the trade good.
  final int tradeVolume;

  /// The timestamp of the price record.
  final DateTime timestamp;

  @override
  String toString() {
    return 'MarketPrice{waypointSymbol: $waypointSymbol, symbol: $symbol, '
        'supply: $supply, purchasePrice: $purchasePrice, '
        'sellPrice: $sellPrice, tradeVolume: $tradeVolume, '
        'timestamp: $timestamp}';
  }

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
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(
        waypointSymbol,
        symbol,
        supply,
        purchasePrice,
        sellPrice,
        tradeVolume,
        timestamp,
      );
}
