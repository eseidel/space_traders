-- Holds a record of an construction.
CREATE TABLE IF NOT EXISTS "construction_" (
    -- The waypoint symbol where the construction is.
    "waypoint_symbol" text NOT NULL PRIMARY KEY,
    -- The timestamp of when the construction was last updated.
    "timestamp" timestamp NOT NULL,
    -- Is the construction complete?
    "is_complete" boolean NOT NULL,
    -- The construction object as json if available.
    "construction" json
);