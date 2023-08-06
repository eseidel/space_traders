-- Describes a request to be made to the API.
CREATE TABLE IF NOT EXISTS "request_" (
  -- The unique identifier for the request.
  "id" bigserial NOT NULL PRIMARY KEY,
  -- When the request was created.
  "created_at" timestamp NULL DEFAULT CURRENT_TIMESTAMP
);