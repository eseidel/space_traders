import 'package:db/src/migration.dart';

/// Migration to create the jump_gate_ table for storing jump gate connections.
class CreateJumpGateMigration implements Migration {
  @override
  int get version => 15;

  @override
  String get up => '''
    CREATE TABLE IF NOT EXISTS "jump_gate_" (
      "symbol" text NOT NULL PRIMARY KEY,
      "connections" text [] NOT NULL
    );
  ''';

  @override
  String get down => 'DROP TABLE IF EXISTS "jump_gate_";';
}
