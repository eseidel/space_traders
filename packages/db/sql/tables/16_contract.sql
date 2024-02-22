-- Holds a record of contract.
CREATE TABLE IF NOT EXISTS "contract_" (
    -- The id of the contract.
    "id" text NOT NULL PRIMARY KEY,
    -- Has the contract been accepted.
    "accepted" boolean NOT NULL,
    -- Has the contract been fulfilled.
    "fulfilled" boolean NOT NULL,
    -- Time the contract must be accepted by or it expires.
    "deadline_to_accept" timestamp NOT NULL,
    -- The Contract object as json.
    "json" json NOT NULL
);