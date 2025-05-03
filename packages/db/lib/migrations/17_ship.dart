import 'package:db/src/migration.dart';

/// Migration to create the ship_ table for storing ship server state.
class CreateShipMigration implements Migration {
  @override
  int get version => 17;

  @override
  String get up => '''
    CREATE TABLE IF NOT EXISTS "ship_" (
      "symbol" text NOT NULL PRIMARY KEY,
      "json" json NOT NULL
    );
  ''';

  @override
  String get down => 'DROP TABLE IF EXISTS "ship_";';
}
