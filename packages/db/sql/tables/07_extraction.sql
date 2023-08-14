-- Holds a record of an extraction.
CREATE TABLE IF NOT EXISTS "extraction_" (
    -- The unique identifier for the extraction.
    "id" bigserial NOT NULL PRIMARY KEY,
    -- The ship symbol which made the extraction.
    "ship_symbol" text NOT NULL,
    -- The waypoint symbol where the extraction was made.
    "waypoint_symbol" text NOT NULL,
    -- The trade symbol of the extracted goods.
    "trade_symbol" text NOT NULL,
    -- The quantity of units extracted.
    "quantity" integer NOT NULL,
    -- The sum of the mount power used in this extraction.
    "power" integer NOT NULL,
    -- The timestamp of the extraction.
    "timestamp" timestamp NOT NULL,
    -- What survey, if any, was used.
    "survey_signature" text
);