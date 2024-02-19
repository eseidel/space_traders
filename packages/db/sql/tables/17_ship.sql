-- Holds a ship's server state.
CREATE TABLE IF NOT EXISTS "ship_" (
    -- The unique identifier for the ship.
    "ship_symbol" text NOT NULL PRIMARY KEY,
    -- The server state encoded as json
    "json" json NOT NULL
);