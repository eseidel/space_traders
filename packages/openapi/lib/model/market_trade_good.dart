import 'package:openapi/model/activity_level.dart';
import 'package:openapi/model/market_trade_good_type.dart';
import 'package:openapi/model/supply_level.dart';
import 'package:openapi/model/trade_symbol.dart';

class MarketTradeGood {
  MarketTradeGood({
    required this.symbol,
    required this.type,
    required this.tradeVolume,
    required this.supply,
    required this.purchasePrice,
    required this.sellPrice,
    this.activity,
  });

  factory MarketTradeGood.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return MarketTradeGood(
      symbol: TradeSymbol.fromJson(json['symbol'] as String),
      type: MarketTradeGoodType.fromJson(json['type'] as String),
      tradeVolume: json['tradeVolume'] as int,
      supply: SupplyLevel.fromJson(json['supply'] as String),
      activity: ActivityLevel.maybeFromJson(json['activity'] as String?),
      purchasePrice: json['purchasePrice'] as int,
      sellPrice: json['sellPrice'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static MarketTradeGood? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return MarketTradeGood.fromJson(json);
  }

  TradeSymbol symbol;
  MarketTradeGoodType type;
  int tradeVolume;
  SupplyLevel supply;
  ActivityLevel? activity;
  int purchasePrice;
  int sellPrice;

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol.toJson(),
      'type': type.toJson(),
      'tradeVolume': tradeVolume,
      'supply': supply.toJson(),
      'activity': activity?.toJson(),
      'purchasePrice': purchasePrice,
      'sellPrice': sellPrice,
    };
  }
}
