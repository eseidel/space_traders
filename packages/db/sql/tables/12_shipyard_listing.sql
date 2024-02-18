-- Describes an shipyard.
CREATE TABLE IF NOT EXISTS "shipyard_listing_" (
  -- The symbol of the shipyard.
  "symbol" text NOT NULL PRIMARY KEY,
  -- Types of ships available at the shipyard.
  "types" text [] NOT NULL,
);