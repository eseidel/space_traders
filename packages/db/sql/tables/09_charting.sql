-- Holds a record of charting a waypoint.
CREATE TABLE IF NOT EXISTS "charting_" (
    -- The waypoint symbol where the chart is.
    "waypoint_symbol" text NOT NULL PRIMARY KEY,
    -- The timestamp of when the chart was last updated.
    "timestamp" timestamp NOT NULL,
    -- The ChartedValues object as json if available.
    "values" json
);