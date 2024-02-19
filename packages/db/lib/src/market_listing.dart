import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// Lookup a market listing by WaypointSymbol.
Query marketListingByWaypointSymbolQuery(WaypointSymbol symbol) => Query(
      'SELECT * FROM market_listing_ WHERE symbol = @symbol',
      parameters: {'symbol': symbol.waypoint},
    );

/// Query all market listings.
Query allMarketListingsQuery() => const Query('SELECT * FROM market_listing_');

/// Query to upsert a market listing.
Query upsertMarketListingQuery(MarketListing listing) => Query(
      '''
      INSERT INTO market_listing_ (symbol, exports, imports, exchange)
      VALUES (@symbol, @exports, @imports, @exchange)
      ON CONFLICT (symbol) DO UPDATE SET
        exports = @exports,
        imports = @imports,
        exchange = @exchange
      ''',
      parameters: marketListingToColumnMap(listing),
    );

/// Build a column map from a market listing.
Map<String, dynamic> marketListingToColumnMap(MarketListing marketListing) => {
      'symbol': marketListing.waypointSymbol.toJson(),
      'exports': marketListing.exports.map((e) => e.toJson()).toList(),
      'imports': marketListing.imports.map((e) => e.toJson()).toList(),
      'exchange': marketListing.exchange.map((e) => e.toJson()).toList(),
    };

/// Build a market listing from a column map.
MarketListing marketListingFromColumnMap(Map<String, dynamic> values) {
  return MarketListing(
    waypointSymbol: WaypointSymbol.fromString(values['symbol'] as String),
    exports: (values['exports'] as List<dynamic>)
        .cast<String>()
        .map((e) => TradeSymbol.fromJson(e)!)
        .toSet(),
    imports: (values['imports'] as List<dynamic>)
        .cast<String>()
        .map((e) => TradeSymbol.fromJson(e)!)
        .toSet(),
    exchange: (values['exchange'] as List<dynamic>)
        .cast<String>()
        .map((e) => TradeSymbol.fromJson(e)!)
        .toSet(),
  );
}
