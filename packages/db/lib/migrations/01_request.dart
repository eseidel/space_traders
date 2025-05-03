import 'package:db/src/migration.dart';

/// Migration to create the request_ table for storing API requests.
class CreateRequestMigration implements Migration {
  @override
  int get version => 1;

  @override
  String get up => '''
    CREATE TABLE IF NOT EXISTS "request_" (
      "id" bigserial NOT NULL PRIMARY KEY,
      "priority" integer NOT NULL,
      "json" json NOT NULL,
      "created_at" timestamp NULL DEFAULT CURRENT_TIMESTAMP
    );
  ''';

  @override
  String get down => 'DROP TABLE IF EXISTS "request_";';
}
