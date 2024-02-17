-- Describes an agent.
CREATE TABLE IF NOT EXISTS "agent_" (
  -- The symbol of the agent.
  "symbol" text NOT NULL PRIMARY KEY,
  -- The waypoint symbol of where the agent starts.
  "headquarters" text NOT NULL,
  -- How many credits the agent has.
  "credits" int NOT NULL,
  -- The faction of the agent.
  "starting_faction" text NOT NULL,
  -- How many ships the agent has.
  "shipCount" int NOT NULL,
  -- account id for this agent, only visible for your own agent.
  "account_id" text,
);
