import 'package:db/src/migration.dart';

/// Migration to create the system_record_ table for storing system records.
class CreateSystemRecordMigration implements Migration {
  @override
  int get version => 20;

  @override
  String get up => '''
    CREATE TABLE IF NOT EXISTS "system_record_" (
      "symbol" text NOT NULL,
      "type" text NOT NULL,
      "x" integer NOT NULL,
      "y" integer NOT NULL,
      "waypoint_symbols" text[] NOT NULL,
      PRIMARY KEY ("symbol")
    );
  ''';

  @override
  String get down => 'DROP TABLE IF EXISTS "system_record_";';
}
