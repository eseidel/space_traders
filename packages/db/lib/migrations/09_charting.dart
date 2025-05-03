import 'package:db/src/migration.dart';

/// Migration to create the charting_ table for storing waypoint chart data.
class CreateChartingMigration implements Migration {
  @override
  int get version => 9;

  @override
  String get up => '''
    CREATE TABLE IF NOT EXISTS "charting_" (
      "waypoint_symbol" text NOT NULL PRIMARY KEY,
      "timestamp" timestamp NOT NULL,
      "values" json
    );
  ''';

  @override
  String get down => 'DROP TABLE IF EXISTS "charting_";';
}
