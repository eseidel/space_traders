import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// Get all market prices.
Query allMarketPricesQuery() => const Query('SELECT * FROM market_price_');

/// Query to upsert a market price.
Query upsertMarketPriceQuery(MarketPrice price) => Query(
      '''
      INSERT INTO market_price_ (
        waypoint_symbol,
        trade_symbol,
        supply,
        purchase_price,
        sell_price,
        trade_volume,
        timestamp,
        activity
      ) VALUES (
        @waypoint_symbol,
        @trade_symbol,
        @supply,
        @purchase_price,
        @sell_price,
        @trade_volume,
        @timestamp,
        @activity
      ) ON CONFLICT (waypoint_symbol, trade_symbol)
      DO UPDATE SET
        supply = @supply,
        purchase_price = @purchase_price,
        sell_price = @sell_price,
        trade_volume = @trade_volume,
        timestamp = @timestamp,
        activity = @activity;
      ''',
      parameters: marketPriceToColumnMap(price),
    );

/// Build a column map from a market price.
Map<String, dynamic> marketPriceToColumnMap(MarketPrice price) => {
      'waypoint_symbol': price.waypointSymbol.toJson(),
      'trade_symbol': price.tradeSymbol.toJson(),
      'supply': price.supply.toJson(),
      'purchase_price': price.purchasePrice,
      'sell_price': price.sellPrice,
      'trade_volume': price.tradeVolume,
      'timestamp': price.timestamp.toIso8601String(),
      'activity': price.activity?.toJson(),
    };

/// Build a market price from a column map.
MarketPrice marketPriceFromColumnMap(Map<String, dynamic> values) {
  return MarketPrice(
    activity: values['activity'] == null
        ? null
        : ActivityLevel.fromJson(values['activity'] as String),
    waypointSymbol:
        WaypointSymbol.fromJson(values['waypoint_symbol'] as String),
    symbol: TradeSymbol.fromJson(values['trade_symbol'] as String)!,
    purchasePrice: values['purchase_price'] as int,
    sellPrice: values['sell_price'] as int,
    supply: SupplyLevel.fromJson(values['supply'] as String)!,
    timestamp: values['timestamp'] as DateTime,
    tradeVolume: values['trade_volume'] as int,
  );
}
