-- Holds a ship's planner state.
CREATE TABLE IF NOT EXISTS "behavior_" (
    -- The unique identifier for the ship.
    "ship_symbol" text NOT NULL PRIMARY KEY,
    -- The behavior enum as a string.
    "behavior" text NOT NULL,
    -- The behavior state encoded as json
    "json" json NOT NULL
);