import 'package:db/src/migration.dart';

/// Migration to create the contract_ table for storing contract information.
class CreateContractMigration implements Migration {
  @override
  int get version => 16;

  @override
  String get up => '''
    CREATE TABLE IF NOT EXISTS "contract_" (
      "id" text NOT NULL PRIMARY KEY,
      "accepted" boolean NOT NULL,
      "fulfilled" boolean NOT NULL,
      "deadline_to_accept" timestamp NOT NULL,
      "json" json NOT NULL
    );
  ''';

  @override
  String get down => 'DROP TABLE IF EXISTS "contract_";';
}
