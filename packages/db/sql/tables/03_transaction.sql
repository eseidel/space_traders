-- Describes a transaction.
CREATE TABLE IF NOT EXISTS "transaction_" (
  -- The unique identifier for the transaction.
  "id" bigserial NOT NULL PRIMARY KEY,
  -- The type of transaction.
  "transaction_type" varchar(255) NOT NULL,
  -- The ship symbol which made the transaction.
  "ship_symbol" varchar(255) NOT NULL,
  -- The waypoint symbol where the transaction was made.
  "waypoint_symbol" varchar(255) NOT NULL,
  -- The trade symbol of the transaction. 
  -- Trade symbol is null for shipyard transactions.
  "trade_symbol" varchar(255),
  -- The ship type of the transaction.
  -- Ship type is null for non-shipyard transactions.
  "ship_type" varchar(255),
  -- The quantity of units transacted.
  "quantity" int NOT NULL,
  -- The trade type of the transaction.
  "trade_type" varchar(255) NOT NULL,
  -- The per-unit price of the transaction.
  "per_unit_price" int NOT NULL,
  -- The timestamp of the transaction.
  "timestamp" timestamp NOT NULL,
  -- The credits of the agent after the transaction.
  "agent_credits" int NOT NULL,
  -- The accounting classification of the transaction.
  "accounting" varchar(255) NOT NULL
);
