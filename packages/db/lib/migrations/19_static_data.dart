import 'package:db/src/migration.dart';

/// Migration to create the static_data_ table for storing server static data.
class CreateStaticDataMigration implements Migration {
  @override
  int get version => 19;

  @override
  String get up => '''
    CREATE TABLE IF NOT EXISTS "static_data_" (
      "type" text NOT NULL,
      "reset" text NOT NULL,
      "key" text NOT NULL,
      "json" json NOT NULL,
      PRIMARY KEY ("type", "key")
    );
  ''';

  @override
  String get down => 'DROP TABLE IF EXISTS "static_data_";';
}
