-- Describes a shipyard price.
CREATE TABLE IF NOT EXISTS "shipyard_price_" (
  -- The symbol of the shipyard.
  "waypoint_symbol" text NOT NULL,
  -- The type of ship this price is for.
  "ship_type" text NOT NULL,
  -- The price of the ship.
  "purchase_price" integer NOT NULL,
  -- Timestamp of the last update.
  "timestamp" timestamp NOT NULL,
  CONSTRAINT "shipyard_price__waypoint_symbol_ship_type__unique" UNIQUE ("waypoint_symbol", "ship_type")
);