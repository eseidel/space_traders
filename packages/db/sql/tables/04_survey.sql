-- Describes a survey.
CREATE TABLE IF NOT EXISTS "survey_" (
    -- The unique identifier for the survey.
    "signature" text NOT NULL PRIMARY KEY,
    -- The waypoint symbol where the survey was taken.
    "waypoint_symbol" text NOT NULL,
    -- The deposits found (comma separated trade symbols).
    "deposits" text NOT NULL,
    -- The expiration time.
    "expiration" timestamp NOT NULL,
    -- The size of the survey.  SurveySizeEnum
    "size" text NOT NULL,
    -- The timestamp the survey was taken.
    "timestamp" timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    -- Whether the survey has been exhausted.
    "exhausted" boolean NOT NULL
);
