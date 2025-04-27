-- static data from the server
CREATE TABLE IF NOT EXISTS "static_data_" (
    -- the type of static data
    "type" text NOT NULL,
    -- the reset in which this static data was last updated
    "reset" text NOT NULL,
    -- the key of the static data (contents differ based on the type)
    "key" text NOT NULL,
    -- the value of the static data
    "json" json NOT NULL,
    PRIMARY KEY ("type", "key")
);
