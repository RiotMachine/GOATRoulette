-- use single quotes ' ' for string literals in SQL
-- " " for identifiers


-- sqlite does not enforce foreign keys by default 
-- will need to set this up w/in C++ code
PRAGMA foreign_keys = true;


-- using Unix Time for dates
-- take type INTEGER

CREATE TABLE IF NOT EXISTS franchise (
    id INTEGER PRIMARY KEY,
) STRICT;

CREATE TABLE IF NOT EXISTS team (
    franchise_id INTEGER,
    startDate INTEGER NOT NULL,
    endDate INTEGER,
    name TEXT NOT NULL,
  PRIMARY KEY (franchise_id, startDate),
  FOREIGN KEY (franchise_id) REFERENCES franchise (id),
) STRICT, WITHOUT ROWID;
CREATE UNIQUE INDEX IF NOT EXISTS idx_endDate_null
  ON team(franchise_id) WHERE endDate IS NULL; 
