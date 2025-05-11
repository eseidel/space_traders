import 'package:db/src/migration.dart';

/// Migration to create the agent_ table for storing agent information.
class CreateAgentMigration implements Migration {
  @override
  int get version => 10;

  @override
  String get up => '''
    CREATE TABLE IF NOT EXISTS "agent_" (
      "symbol" text NOT NULL PRIMARY KEY,
      "headquarters" text NOT NULL,
      "credits" int NOT NULL,
      "starting_faction" text NOT NULL,
      "ship_count" int NOT NULL,
      "account_id" text NOT NULL
    );
  ''';

  @override
  String get down => 'DROP TABLE IF EXISTS "agent_";';
}
