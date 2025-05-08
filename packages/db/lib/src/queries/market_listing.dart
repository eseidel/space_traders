import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// Lookup a market listing by WaypointSymbol.
Query marketListingByWaypointSymbolQuery(WaypointSymbol symbol) => Query(
  'SELECT * FROM market_listing_ WHERE symbol = @symbol',
  parameters: {'symbol': symbol.waypoint},
);

/// Query all market listings.
Query allMarketListingsQuery() => const Query('SELECT * FROM market_listing_');

/// Query all market listings within a system.
Query marketListingsInSystemQuery(SystemSymbol system) => Query(
  'SELECT * FROM market_listing_ WHERE starts_with(symbol, @system)',
  parameters: {'system': system.system},
);

/// Query to upsert a market listing.
Query upsertMarketListingQuery(MarketListing listing) =>
    Query(parameters: marketListingToColumnMap(listing), '''
      INSERT INTO market_listing_ (symbol, exports, imports, exchange)
      VALUES (@symbol, @exports, @imports, @exchange)
      ON CONFLICT (symbol) DO UPDATE SET
        exports = @exports,
        imports = @imports,
        exchange = @exchange
      ''');

/// Query to find all markets with a given import in the system.
Query marketsWithImportInSystemQuery(
  SystemSymbol system,
  TradeSymbol tradeSymbol,
) =>
// TODO(eseidel): This should only be imports, but that currently breaks
// the ability to find mining locations in starting systems.
Query(
  '''
      SELECT symbol FROM market_listing_
      WHERE starts_with(symbol, @system) AND (@tradeSymbol = ANY(imports)
        OR @tradeSymbol = ANY(exchange))
      ''',
  parameters: {'system': system.system, 'tradeSymbol': tradeSymbol.toJson()},
);

/// Query to find all markets with a given export in the system.
Query marketsWithExportInSystemQuery(
  SystemSymbol system,
  TradeSymbol tradeSymbol,
) => Query(
  '''
      SELECT symbol FROM market_listing_
      WHERE starts_with(symbol, @system) AND @tradeSymbol = ANY(exports)
      ''',
  parameters: {'system': system.system, 'tradeSymbol': tradeSymbol.toJson()},
);

/// Query to return all markets which buys a given symbol within a system.
Query marketsWhichBuysTradeSymbolInSystemQuery(
  SystemSymbol system,
  TradeSymbol tradeSymbol,
) => Query(
  '''
      SELECT symbol FROM market_listing_
      WHERE starts_with(symbol, @system)
      AND (@tradeSymbol = ANY(imports) OR @tradeSymbol = ANY(exchange))
      ''',
  parameters: {'system': system.system, 'tradeSymbol': tradeSymbol.toJson()},
);

/// Query to return if we know of a market which trades a given symbol.
Query knowOfMarketWhichTradesQuery(TradeSymbol tradeSymbol) => Query(
  '''
      SELECT EXISTS(
        SELECT 1 FROM market_listing_
        WHERE @tradeSymbol = ANY(imports)
        OR @tradeSymbol = ANY(exports)
        OR @tradeSymbol = ANY(exchange)
      )
      ''',
  parameters: {'tradeSymbol': tradeSymbol.toJson()},
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
    exports:
        (values['exports'] as List<dynamic>)
            .cast<String>()
            .map((e) => TradeSymbol.fromJson(e)!)
            .toSet(),
    imports:
        (values['imports'] as List<dynamic>)
            .cast<String>()
            .map((e) => TradeSymbol.fromJson(e)!)
            .toSet(),
    exchange:
        (values['exchange'] as List<dynamic>)
            .cast<String>()
            .map((e) => TradeSymbol.fromJson(e)!)
            .toSet(),
  );
}

/// Convert a column map to a market listing symbol.
WaypointSymbol marketListingSymbolFromColumnMap(Map<String, dynamic> map) =>
    WaypointSymbol.fromString(map['symbol'] as String);
