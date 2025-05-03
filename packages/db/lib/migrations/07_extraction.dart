import 'package:db/src/migration.dart';

/// Migration to create the extraction_ table for storing resource extraction records.
class CreateExtractionMigration implements Migration {
  @override
  int get version => 7;

  @override
  String get up => '''
    CREATE TABLE IF NOT EXISTS "extraction_" (
      "id" bigserial NOT NULL PRIMARY KEY,
      "ship_symbol" text NOT NULL,
      "waypoint_symbol" text NOT NULL,
      "trade_symbol" text NOT NULL,
      "quantity" integer NOT NULL,
      "power" integer NOT NULL,
      "timestamp" timestamp NOT NULL,
      "survey_signature" text
    );
  ''';

  @override
  String get down => 'DROP TABLE IF EXISTS "extraction_";';
}
