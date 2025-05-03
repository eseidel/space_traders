import 'package:db/src/migration.dart';

/// Migration to create the response_ table for storing API responses.
class CreateResponseMigration implements Migration {
  @override
  int get version => 2;

  @override
  String get up => '''
    CREATE TABLE IF NOT EXISTS "response_" (
      "id" bigserial NOT NULL PRIMARY KEY,
      "request_id" bigserial NOT NULL,
      "json" json NOT NULL,
      "created_at" timestamp NULL DEFAULT CURRENT_TIMESTAMP
    );
  ''';

  @override
  String get down => 'DROP TABLE IF EXISTS "response_";';
}
