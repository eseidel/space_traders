import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// Get all market prices.
Query allMarketPricesQuery() => const Query('SELECT * FROM market_price_');

/// Get all market prices with a given system symbol.
Query marketPricesInSystemQuery(SystemSymbol symbol) => Query(
  'SELECT * FROM market_price_ '
  'WHERE waypoint_symbol LIKE @symbol_pattern',
  parameters: {'symbol_pattern': '${symbol.toJson()}%'},
);

/// Query to upsert a market price.
Query upsertMarketPriceQuery(MarketPrice price) =>
    Query(parameters: marketPriceToColumnMap(price), '''
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
      ''');

/// Build a column map from a market price.
Map<String, dynamic> marketPriceToColumnMap(MarketPrice price) => {
  'waypoint_symbol': price.waypointSymbol.toJson(),
  'trade_symbol': price.tradeSymbol.toJson(),
  'supply': price.supply.toJson(),
  'purchase_price': price.purchasePrice,
  'sell_price': price.sellPrice,
  'trade_volume': price.tradeVolume,
  'timestamp': price.timestamp,
  'activity': price.activity?.toJson(),
};

/// Query to get the timestamp of the most recent market price for a waypoint.
Query timestampOfMostRecentMarketPriceQuery(WaypointSymbol symbol) => Query(
  'SELECT MAX(timestamp) FROM market_price_ '
  'WHERE waypoint_symbol = @symbol',
  parameters: {'symbol': symbol.toJson()},
);

/// Query to get a market price for a waypoint and trade symbol.
Query marketPriceQuery(WaypointSymbol waypoint, TradeSymbol trade) => Query(
  'SELECT * FROM market_price_ '
  'WHERE waypoint_symbol = @waypoint AND trade_symbol = @trade',
  parameters: {'waypoint': waypoint.toJson(), 'trade': trade.toJson()},
);

/// Query to get the median purchase price for a trade symbol.
Query medianMarketPurchasePriceQuery(TradeSymbol trade) => Query(
  '''
      SELECT percentile_disc(0.5)
      WITHIN GROUP (ORDER BY purchase_price)
      FROM market_price_
      WHERE trade_symbol = @trade;
      ''',
  parameters: {'trade': trade.toJson()},
);

/// Build a market price from a column map.
MarketPrice marketPriceFromColumnMap(Map<String, dynamic> values) {
  return MarketPrice(
    activity: values['activity'] == null
        ? null
        : ActivityLevel.fromJson(values['activity'] as String),
    waypointSymbol: WaypointSymbol.fromJson(
      values['waypoint_symbol'] as String,
    ),
    symbol: TradeSymbol.fromJson(values['trade_symbol'] as String),
    purchasePrice: values['purchase_price'] as int,
    sellPrice: values['sell_price'] as int,
    supply: SupplyLevel.fromJson(values['supply'] as String),
    timestamp: values['timestamp'] as DateTime,
    tradeVolume: values['trade_volume'] as int,
  );
}
