-- Describes a response from the API.
CREATE TABLE IF NOT EXISTS "response_" (
  -- The unique identifier for the response.
  "id" bigserial NOT NULL PRIMARY KEY,
  -- The unique identifier for the request that caused this response.
  "request_id" bigserial NOT NULL,
  -- The response encoded as json
  "json" json NOT NULL,
  -- When the response was created.
  "created_at" timestamp NULL DEFAULT CURRENT_TIMESTAMP
);