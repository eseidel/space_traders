import 'package:db/src/migration.dart';

/// Migration to create the market_listing_ table for storing market trade
/// listings.
class CreateMarketListingMigration implements Migration {
  @override
  int get version => 11;

  @override
  String get up => '''
    CREATE TABLE IF NOT EXISTS "market_listing_" (
      "symbol" text NOT NULL PRIMARY KEY,
      "exports" text [] NOT NULL,
      "imports" text [] NOT NULL,
      "exchange" text [] NOT NULL
    );
  ''';

  @override
  String get down => 'DROP TABLE IF EXISTS "market_listing_";';
}
