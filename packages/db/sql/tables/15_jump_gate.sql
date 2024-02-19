-- Describes a jump gate.
CREATE TABLE IF NOT EXISTS "jump_gate_" (
  -- The symbol of the jump gate.
  "symbol" text NOT NULL PRIMARY KEY,
  -- Other jump gates this connects to.
  "connections" text [] NOT NULL
);