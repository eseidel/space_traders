import 'package:db/src/migration.dart';

/// Migration to create the transaction_ table for storing trade and shipyard
/// transactions.
class CreateTransactionMigration implements Migration {
  @override
  int get version => 3;

  @override
  String get up => '''
    CREATE TABLE IF NOT EXISTS "transaction_" (
      "id" bigserial NOT NULL PRIMARY KEY,
      "transaction_type" text NOT NULL,
      "ship_symbol" text NOT NULL,
      "waypoint_symbol" text NOT NULL,
      "trade_symbol" text,
      "ship_type" text,
      "quantity" int NOT NULL,
      "trade_type" text,
      "per_unit_price" int NOT NULL,
      "timestamp" timestamp NOT NULL,
      "agent_credits" int NOT NULL,
      "accounting" text NOT NULL,
      "contract_id" text,
      "contract_action" text
    );
  ''';

  @override
  String get down => 'DROP TABLE IF EXISTS "transaction_";';
}
