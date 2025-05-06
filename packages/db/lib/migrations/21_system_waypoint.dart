import 'package:db/src/migration.dart';

/// Migration to create the system_waypoint_ table for storing system waypoints.
class CreateSystemWaypointMigration implements Migration {
  @override
  int get version => 21;

  @override
  String get up => '''
    CREATE TABLE IF NOT EXISTS "system_waypoint_" (
      "symbol" text NOT NULL,
      "type" text NOT NULL,
      "x" integer NOT NULL,
      "y" integer NOT NULL,
      "system" text NOT NULL,
      PRIMARY KEY ("symbol"),
      INDEX "system_waypoint_system_idx" ON "system_waypoint_" ("system")
    );
  ''';

  @override
  String get down => 'DROP TABLE IF EXISTS "system_waypoint_";';
}
