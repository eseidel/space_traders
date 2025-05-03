import 'package:db/src/migration.dart';

/// Migration to create the behavior_ table for storing ship behavior states.
class CreateBehaviorMigration implements Migration {
  @override
  int get version => 6;

  @override
  String get up => '''
    CREATE TABLE IF NOT EXISTS "behavior_" (
      "ship_symbol" text NOT NULL PRIMARY KEY,
      "behavior" text NOT NULL,
      "json" json NOT NULL
    );
  ''';

  @override
  String get down => 'DROP TABLE IF EXISTS "behavior_";';
}
