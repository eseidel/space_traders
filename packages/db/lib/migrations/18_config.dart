import 'package:db/src/migration.dart';

/// Migration to create the config_ table for storing global configuration
/// settings.
class CreateConfigMigration implements Migration {
  @override
  int get version => 18;

  @override
  String get up => '''
    CREATE TABLE IF NOT EXISTS "config_" (
      "key" TEXT NOT NULL PRIMARY KEY,
      "value" TEXT NOT NULL
    );
  ''';

  @override
  String get down => 'DROP TABLE IF EXISTS "config_";';
}
