-- Holds a record of contract.
CREATE TABLE IF NOT EXISTS "contract_" (
    -- The id of the contract.
    "id" text NOT NULL PRIMARY KEY,
    -- The Contract object as json.
    "json" json NOT NULL
);