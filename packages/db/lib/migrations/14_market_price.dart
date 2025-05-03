import 'package:db/src/migration.dart';

/// Migration to create the market_price_ table for storing market trade prices.
class CreateMarketPriceMigration implements Migration {
  @override
  int get version => 14;

  @override
  String get up => '''
    CREATE TABLE IF NOT EXISTS "market_price_" (
      "waypoint_symbol" text NOT NULL,
      "trade_symbol" text NOT NULL,
      "supply" text NOT NULL,
      "purchase_price" int NOT NULL,
      "sell_price" int NOT NULL,
      "trade_volume" int NOT NULL,
      "timestamp" timestamp NOT NULL,
      "activity" text,
      CONSTRAINT "market_price__waypoint_symbol_trade_symbol__unique" UNIQUE ("waypoint_symbol", "trade_symbol")
    );
  ''';

  @override
  String get down => 'DROP TABLE IF EXISTS "market_price_";';
}
