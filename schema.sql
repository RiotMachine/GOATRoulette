-- use single quotes ' ' for string literals in SQL
-- " " for identifiers

-- using Unix Time for dates

-- sqlite does not enforce foreign keys by default 
-- will need to set this up w/in C++ code
PRAGMA foreign_keys = true;


CREATE TABLE IF NOT EXISTS franchise (
    id INTEGER PRIMARY KEY,
) STRICT;


CREATE TABLE IF NOT EXISTS team (
    franchise_id INTEGER NOT NULL REFERENCES franchise,
    startDate INTEGER NOT NULL,
    endDate INTEGER,
    name TEXT NOT NULL,
  PRIMARY KEY (franchise_id, startDate),
) STRICT, WITHOUT ROWID;

CREATE INDEX IF NOT EXISTS idx_franchise_id ON team(franchise_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_endDate_null
  ON team(franchise_id) WHERE endDate IS NULL;


CREATE TABLE IF NOT EXISTS season (
    id INTEGER PRIMARY KEY,
    regularSeason_length INTEGER NOT NULL
        CHECK (regularSeason_length >= 0),
    length INTEGER NOT NULL
        CHECK (length >= regularSeason_length),
) STRICT;


CREATE TABLE IF NOT EXISTS stage (
    season_id INTEGER NOT NULL REFERENCES season,
    stageNumber -- autoincrement according to season.length
    isPlayoff -- bool autoset by increment > regularSeason_length
  PRIMARY KEY (season_id, stageNumber),
) STRICT, WITHOUT ROWID;

CREATE INDEX IF NOT EXISTS idx_season_id ON stage(season_id);


CREATE TABLE IF NOT EXISTS game (
    id INTEGER PRIMARY KEY,
    home_id INTEGER NOT NULL REFERENCES franchise,
    away_id INTEGER NOT NULL REFERENCES franchise,
    atNeutralSite INTEGER NOT NULL DEFAULT FALSE
        CHECK (atNeutralSite IN (TRUE, FALSE)),
    homeScore INTEGER NOT NULL
        CHECK (homeScore >=0),
    awayScore INTEGER NOT NULL
        CHECK (awayScore >=0),
    stageNumber INTEGER NOT NULL,
    season_id INTEGER NOT NULL,
  FOREIGN KEY (stageNumber, season_id) REFERENCES stage (stageNumber, season_id),
) STRICT;

CREATE INDEX IF NOT EXISTS idx_home_id ON game(home_id);
CREATE INDEX IF NOT EXISTS idx_away_id ON game(away_id);
CREATE INDEX IF NOT EXISTS idx_stageNumber_and_season_id ON game (stageNumber, season_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_home_id_and_away_id
  ON game(home_id, away_id);
-- prevent new games for inactive franchises
-- prevent new teams for inactive franchises
