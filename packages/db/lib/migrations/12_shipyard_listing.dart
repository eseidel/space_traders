import 'package:db/src/migration.dart';

/// Migration to create the shipyard_listing_ table for storing shipyard ship
/// types.
class CreateShipyardListingMigration implements Migration {
  @override
  int get version => 12;

  @override
  String get up => '''
    CREATE TABLE IF NOT EXISTS "shipyard_listing_" (
      "symbol" text NOT NULL PRIMARY KEY,
      "types" text [] NOT NULL
    );
  ''';

  @override
  String get down => 'DROP TABLE IF EXISTS "shipyard_listing_";';
}
