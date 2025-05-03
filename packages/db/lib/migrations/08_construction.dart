import 'package:db/src/migration.dart';

/// Migration to create the construction_ table for storing waypoint
/// construction data.
class CreateConstructionMigration implements Migration {
  @override
  int get version => 8;

  @override
  String get up => '''
    CREATE TABLE IF NOT EXISTS "construction_" (
      "waypoint_symbol" text NOT NULL PRIMARY KEY,
      "timestamp" timestamp NOT NULL,
      "is_complete" boolean NOT NULL,
      "construction" json
    );
  ''';

  @override
  String get down => 'DROP TABLE IF EXISTS "construction_";';
}
