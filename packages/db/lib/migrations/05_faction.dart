import 'package:db/src/migration.dart';

/// Migration to create the faction_ table for storing faction information.
class CreateFactionMigration implements Migration {
  @override
  int get version => 5;

  @override
  String get up => '''
    CREATE TABLE IF NOT EXISTS "faction_" (
      "symbol" text NOT NULL PRIMARY KEY,
      "json" json NOT NULL
    );
  ''';

  @override
  String get down => 'DROP TABLE IF EXISTS "faction_";';
}
