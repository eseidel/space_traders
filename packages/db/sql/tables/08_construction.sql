-- Holds a record of an construction.
CREATE TABLE IF NOT EXISTS "construction_" (
    -- The waypoint symbol where the extraction was made.
    "waypoint_symbol" text NOT NULL PRIMARY KEY,
    -- The timestamp of the extraction.
    "timestamp" timestamp NOT NULL,
    -- Is the construction complete?
    "is_complete" boolean NOT NULL,
    -- The construction object as json if available.
    "json" json,
);