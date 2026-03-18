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
CREATE INDEX idx_season_id_and_stageNumber
  ON game(season_id, stageNumber);


CREATE TABLE performance_summary (
    franchise_id  INTEGER NOT NULL REFERENCES franchise,
    season_id     INTEGER NOT NULL REFERENCES season,
    wins          INTEGER NOT NULL DEFAULT 0
        CHECK (wins >= 0),
    losses        INTEGER NOT NULL DEFAULT 0
        CHECK (losses >= 0),
    ties          INTEGER NOT NULL DEFAULT 0
        CHECK (ties >= 0),
  PRIMARY KEY(franchise_id, season_id)
) STRICT, WITHOUT ROWID;

WITH 
  regularSeasonGame AS (
    SELECT 
      game.season_id,
      home_id,
      away_id,
      homeScore,
      awayScore
    FROM game
      INNER JOIN stage
        ON stage.stageNumber = game.stageNumber
          AND stage.season_id = game.season_id
          AND stage.isPlayoff = FALSE
  ),
  regularSeasonResult AS (
    SELECT
      home_id AS franchise_id,
      season_id,
      IF(homeScore > awayScore, 1, 0) AS win,
      IF(homeScore < awayScore, 1, 0) AS loss,
      IF(homeScore = awayScore, 1, 0) AS tie
    FROM regularSeasonGame

    UNION ALL

    SELECT
      away_id AS franchise_id,
      season_id,
      IF(awayScore > homeScore, 1, 0) AS win,
      IF(awayScore < homeScore, 1, 0) AS loss,
      IF(awayScore = homeScore, 1, 0) AS tie
    FROM regularSeasonGame         
  )
INSERT INTO performance_summary
    (franchise_id, season_id,
     wins, losses, ties) 
  SELECT
    rsr.franchise_id,
    rsr.season_id,
    SUM(rsr.win),
    SUM(rsr.loss),
    SUM(rsr.tie)
  FROM regularSeasonResult AS rsr
  GROUP BY franchise_id, season_id;