import 'package:db/src/migration.dart';

/// Migration to create the survey_ table for storing waypoint survey data.
class CreateSurveyMigration implements Migration {
  @override
  int get version => 4;

  @override
  String get up => '''
    CREATE TABLE IF NOT EXISTS "survey_" (
      "signature" text NOT NULL PRIMARY KEY,
      "waypoint_symbol" text NOT NULL,
      "deposits" text[] NOT NULL,
      "expiration" timestamp NOT NULL,
      "size" text NOT NULL,
      "timestamp" timestamp NULL DEFAULT CURRENT_TIMESTAMP,
      "exhausted" boolean NOT NULL
    );
  ''';

  @override
  String get down => 'DROP TABLE IF EXISTS "survey_";';
}
