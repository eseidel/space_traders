import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// Get all market prices.
Query allMarketPricesQuery() => const Query('SELECT * FROM market_price');

/// Query to upsert a market price.
Query upsertMarketPriceQuery(MarketPrice price) => Query(
      '''
      INSERT INTO market_price (symbol, good, purchase_price, sale_price, supply, timestamp, trade_volume)
      VALUES (@symbol, @good, @purchase_price, @sale_price, @supply, @timestamp, @trade_volume)
      ON CONFLICT (symbol, good) DO UPDATE SET
        purchase_price = @purchase_price,
        sale_price = @sale_price,
        supply = @supply,
        timestamp = @timestamp,
        trade_volume = @trade_volume
      ''',
      parameters: marketPriceToColumnMap(price),
    );

/// Build a column map from a market price.
Map<String, dynamic> marketPriceToColumnMap(MarketPrice price) => {
      'symbol': price.waypointSymbol.toString(),
      'good': price.symbol.toString(),
      'purchase_price': price.purchasePrice,
      'sale_price': price.sellPrice,
      'supply': price.supply.toString(),
      'timestamp': price.timestamp.toIso8601String(),
      'trade_volume': price.tradeVolume,
    };

/// Build a market price from a column map.
MarketPrice marketPriceFromColumnMap(Map<String, dynamic> values) {
  return MarketPrice(
    waypointSymbol: WaypointSymbol.fromString(values['symbol'] as String),
    symbol: TradeSymbol.fromJson(values['good'] as String)!,
    purchasePrice: values['purchase_price'] as int,
    sellPrice: values['sale_price'] as int,
    supply: SupplyLevel.fromJson(values['supply'] as String)!,
    timestamp: DateTime.parse(values['timestamp'] as String),
    tradeVolume: values['trade_volume'] as int,
  );
}
