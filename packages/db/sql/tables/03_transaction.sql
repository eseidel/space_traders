-- Describes a transaction.
CREATE TABLE IF NOT EXISTS "transaction_" (
  -- The unique identifier for the transaction.
  "id" bigserial NOT NULL PRIMARY KEY,
  -- The type of transaction.
  "transaction_type" text NOT NULL,
  -- The ship symbol which made the transaction.
  "ship_symbol" text NOT NULL,
  -- The waypoint symbol where the transaction was made.
  "waypoint_symbol" text NOT NULL,
  -- The trade symbol of the transaction. 
  -- Trade symbol is null for non-trade transactions.
  "trade_symbol" text,
  -- The ship type of the transaction.
  -- Ship type is null for non-shipyard transactions.
  "ship_type" text,
  -- The quantity of units transacted.
  "quantity" int NOT NULL,
  -- The trade type of the transaction.
  -- The trade type is null for non-trade transactions.
  "trade_type" text,
  -- The per-unit price of the transaction.
  "per_unit_price" int NOT NULL,
  -- The timestamp of the transaction.
  "timestamp" timestamp NOT NULL,
  -- The credits of the agent after the transaction.
  "agent_credits" int NOT NULL,
  -- The accounting classification of the transaction.
  "accounting" text NOT NULL,
  -- The contract id of the transaction.
  -- Contract id is null for non-contract transactions.
  "contract_id" text,
  -- The contract action of the transaction.
  -- Contract action is null for non-contract transactions.
  "contract_action" text
);
