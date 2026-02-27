-- use single quotes ' ' for string literals in SQL
-- " " for identifiers

-- using Unix Time for dates
-- sqlite uses 64 bit ints so type-safe
-- https://www.sqlite.org/datatype3.html
-- https://www.sqlite.org/floatingpoint.html

-- sqlite says b.p. is to index child keys

-- sqlite does not enforce foreign keys by default 
-- will need to set this up w/in C++ code
PRAGMA foreign_keys = true;


CREATE TABLE franchise (
    id         INTEGER PRIMARY KEY,
    startDate  INTEGER NOT NULL,
    endDate    INTEGER
        CHECK (endDate > startDate OR endDate IS NULL)
) STRICT;


CREATE TABLE team (
    franchise_id  INTEGER NOT NULL REFERENCES franchise,
    startDate     INTEGER NOT NULL,
    endDate       INTEGER
        CHECK (endDate > startDate OR endDate IS NULL),
    city          TEXT NOT NULL,
    mascot        TEXT NOT NULL,
  PRIMARY KEY (franchise_id, startDate)
) STRICT, WITHOUT ROWID;

CREATE INDEX idx_franchise_id
  ON team(franchise_id);

CREATE UNIQUE INDEX idx_endDate_null
  ON team(franchise_id) WHERE endDate IS NULL;


CREATE TABLE season (
    id                   INTEGER PRIMARY KEY,
    regularSeason_length INTEGER NOT NULL
        CHECK (regularSeason_length >= 0),
    length               INTEGER NOT NULL
        CHECK (length >= regularSeason_length),
    startDate            INTEGER NOT NULL,
    endDate              INTEGER NOT NULL
        CHECK (endDate > startDate)
) STRICT;


CREATE TABLE stage (
    season_id   INTEGER NOT NULL REFERENCES season,
    stageNumber INTEGER NOT NULL,
    isPlayoff   INTEGER NOT NULL DEFAULT FALSE
        CHECK (isPlayoff IN (TRUE, FALSE)),
  PRIMARY KEY (season_id, stageNumber)
) STRICT, WITHOUT ROWID;

CREATE INDEX idx_season_id
  ON stage(season_id);


CREATE TABLE game (
    id            INTEGER PRIMARY KEY,
    home_id       INTEGER NOT NULL REFERENCES franchise,
    away_id       INTEGER NOT NULL REFERENCES franchise
        CHECK (away_id != home_id),
    atNeutralSite INTEGER NOT NULL DEFAULT FALSE
        CHECK (atNeutralSite IN (TRUE, FALSE)),
    homeScore     INTEGER NOT NULL
        CHECK (homeScore >=0),
    awayScore     INTEGER NOT NULL
        CHECK (awayScore >=0),
    stageNumber   INTEGER NOT NULL,
    season_id     INTEGER NOT NULL,
    startDate     INTEGER NOT NULL,
  FOREIGN KEY (season_id, stageNumber) REFERENCES stage (season_id, stageNumber)
) STRICT;

CREATE INDEX idx_home_id
  ON game(home_id);
CREATE INDEX idx_away_id
  ON game(away_id);
CREATE INDEX idx_stageNumber_and_season_id
  ON game (stageNumber, season_id);


-- Season(desc) | Stage(asc) | isPlayoff | Game
CREATE VIEW view_databaseFlow (
    season_id,
    stage_number,
    isPlayoffStage,
    game_id
) AS SELECT season.id, stage.stageNumber, stage.isPlayoff, game.id
    FROM season
      INNER JOIN stage ON season.id = stage.season_id
      INNER JOIN game  ON season.id = game.season_id AND stage.stageNumber = game.stageNumber
    ORDER BY season.id DESC, stage.stageNumber ASC;


