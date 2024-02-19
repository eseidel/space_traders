-- Describes a market price.
CREATE TABLE IF NOT EXISTS "market_price_" (
  -- The symbol of the market.
  "waypoint_symbol" text NOT NULL,
  -- The trade symbol being sold.
  "trade_symbol" text NOT NULL,
  -- The level of supply.
  "supply" text NOT NULL,
  -- Price to buy from this market.
  "purchase_price" int NOT NULL,
  -- Price to sell to this market.
  "sell_price" int NOT NULL,
  -- Maximum trade size at this market.
  "trade_volume" int NOT NULL,
  -- When this price was seen.
  "timestamp" timestamp NOT NULL,
  -- Activity level for the good at this market.
  "activity" text,
  CONSTRAINT "market_price__waypoint_symbol_trade_symbol__unique" UNIQUE ("waypoint_symbol", "trade_symbol")
);