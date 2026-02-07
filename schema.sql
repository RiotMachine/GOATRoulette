-- use single quotes ' ' for string literals in SQL
-- " " for identifiers

-- using Unix Time for dates
-- sqlite says b.p. is to index child keys

-- sqlite does not enforce foreign keys by default 
-- will need to set this up w/in C++ code
PRAGMA foreign_keys = true;


CREATE TABLE franchise (
    id INTEGER PRIMARY KEY,
) STRICT;


CREATE TABLE team (
    franchise_id INTEGER NOT NULL REFERENCES franchise,
    startDate    INTEGER NOT NULL,
    endDate      INTEGER,
    name         TEXT NOT NULL,
  PRIMARY KEY (franchise_id, startDate),
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
) STRICT;


CREATE TABLE stage (
    season_id   INTEGER NOT NULL REFERENCES season,
    stageNumber INTEGER NOT NULL,
    isPlayoff   INTEGER NOT NULL DEFAULT FALSE
        CHECK (isPlayoff IN (TRUE, FALSE)),
  PRIMARY KEY (season_id, stageNumber),
) STRICT, WITHOUT ROWID;

CREATE INDEX idx_season_id
  ON stage(season_id);

CREATE TRIGGER tgr_new_stageNumber
  BEFORE INSERT ON stage
    WHEN NEW.stageNumber > (SELECT length FROM season WHERE id = NEW.season_id)
    BEGIN
      SELECT RAISE (ROLLBACK, 'Stage number is greater than season.length');
    END;

CREATE TRIGGER tgr_modify_stageNumber
  BEFORE UPDATE OF stageNumber ON stage
    WHEN NEW.stageNumber > (SELECT length FROM season WHERE id = NEW.season_id)
    BEGIN
      SELECT RAISE (ROLLBACK, 'Stage number is greater than season.length');
    END;

CREATE TRIGGER tgr_newStage_setPlayoffBool
  AFTER INSERT ON stage
    WHEN NEW.stageNumber >
      (SELECT regularSeason_length FROM season WHERE id = NEW.season_id)
    BEGIN
      UPDATE stage SET isPlayoff = TRUE WHERE season_id = NEW.season_id
        AND stageNumber = NEW.stageNumber;
    END;

CREATE TRIGGER tgr_modifyStage_setPlayoffBool
  AFTER UPDATE ON STAGE
    WHEN NEW.stageNumber != OLD.stageNumber
    BEGIN
      UPDATE stage SET isPlayoff = IFF(stageNumber >
          (SELECT regularSeason_length FROM season WHERE id = NEW.season_id),
        TRUE, FALSE)
      WHERE season_id = NEW.season_id AND stageNumber = NEW.stageNumber;
    END;


CREATE TABLE game (
    id            INTEGER PRIMARY KEY,
    home_id       INTEGER NOT NULL REFERENCES franchise,
    away_id       INTEGER NOT NULL REFERENCES franchise,
    atNeutralSite INTEGER NOT NULL DEFAULT FALSE
        CHECK (atNeutralSite IN (TRUE, FALSE)),
    homeScore     INTEGER NOT NULL
        CHECK (homeScore >=0),
    awayScore     INTEGER NOT NULL
        CHECK (awayScore >=0),
    stageNumber   INTEGER NOT NULL,
    season_id     INTEGER NOT NULL,
  FOREIGN KEY (stageNumber, season_id) REFERENCES stage (stageNumber, season_id),
) STRICT;

CREATE INDEX idx_home_id
  ON game(home_id);
CREATE INDEX idx_away_id
  ON game(away_id);
CREATE INDEX idx_stageNumber_and_season_id
  ON game (stageNumber, season_id);

CREATE UNIQUE INDEX idx_home_id_and_away_id
  ON game(home_id, away_id);
-- prevent new games for inactive franchises
-- prevent new teams for inactive franchises
