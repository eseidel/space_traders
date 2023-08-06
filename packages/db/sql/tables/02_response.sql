-- Describes a response from the API.
CREATE TABLE IF NOT EXISTS "response_" (
  -- The unique identifier for the response.
  "id" bigserial NOT NULL PRIMARY KEY,
  -- The url for the response.
  "url" VARCHAR NOT NULL,
  -- The body of the response.
  "body" VARCHAR NOT NULL,
  -- When the response was created.
  "created_at" timestamp NULL DEFAULT CURRENT_TIMESTAMP
);