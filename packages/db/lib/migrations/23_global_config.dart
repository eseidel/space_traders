import 'package:db/src/migration.dart';

/// Migration to create the global_ table for storing global configuration
/// settings.
class GlobalConfigMigration implements Migration {
  @override
  int get version => 23;

  @override
  String get up => '''
    CREATE TABLE IF NOT EXISTS "global_" (
      "key" TEXT NOT NULL PRIMARY KEY,
      "value" TEXT NOT NULL
    );
  ''';

  @override
  String get down => 'DROP TABLE IF EXISTS "global_";';
}
