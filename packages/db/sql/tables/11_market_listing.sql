-- Describes an market.
CREATE TABLE IF NOT EXISTS "market_listing_" (
  -- The symbol of the market.
  "symbol" text NOT NULL PRIMARY KEY,
  -- Exports from the market.
  "exports" text [] NOT NULL,
  -- Imports to the market.
  "imports" text [] NOT NULL,
  -- Goods available for exchange at the market.
  "exchange" text [] NOT NULL
);