import 'package:db/src/migration.dart';

/// Migration to create the shipyard_price_ table for storing ship purchase
/// prices.
class CreateShipyardPriceMigration implements Migration {
  @override
  int get version => 13;

  @override
  String get up => '''
    CREATE TABLE IF NOT EXISTS "shipyard_price_" (
      "waypoint_symbol" text NOT NULL,
      "ship_type" text NOT NULL,
      "purchase_price" integer NOT NULL,
      "timestamp" timestamp NOT NULL,
      CONSTRAINT "shipyard_price__waypoint_symbol_ship_type__unique" UNIQUE ("waypoint_symbol", "ship_type")
    );
  ''';

  @override
  String get down => 'DROP TABLE IF EXISTS "shipyard_price_";';
}
