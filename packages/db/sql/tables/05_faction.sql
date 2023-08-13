-- Describes a faction from the API.
CREATE TABLE IF NOT EXISTS "faction_" (
    -- The unique identifier for the faction.
    "symbol" text NOT NULL PRIMARY KEY,
    -- The faction encoded as json
    "json" json NOT NULL
);