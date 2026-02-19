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
) STRICT;


CREATE TABLE team (
    franchise_id INTEGER NOT NULL REFERENCES franchise,
    startDate    INTEGER NOT NULL,
    endDate      INTEGER,
    name         TEXT NOT NULL,
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

CREATE TRIGGER tgr_new_stageNumber_not_incremental
  BEFORE INSERT ON stage
    WHEN NEW.stageNumber != (1 + IFNULL(
      (SELECT MAX(stageNumber) FROM stage WHERE season_id = NEW.season_id), 0))
    BEGIN
      SELECT RAISE (ABORT, 'Stages must monotonically increase');
    END;

CREATE TRIGGER tgr_new_stageNumber_exceeds_length
  BEFORE INSERT ON stage
    WHEN NEW.stageNumber >
      (SELECT length FROM season WHERE id = NEW.season_id)
    BEGIN
      SELECT RAISE (ROLLBACK, 'Stage number cannot be greater than season.length');
    END;

CREATE TRIGGER tgr_modify_stageNumber_not_allowed
  BEFORE UPDATE OF stageNumber ON stage
    BEGIN
      SELECT RAISE (ABORT, 'Modifying a stage''s number is not allowed.');
    END;

CREATE TRIGGER tgr_new_stage_set_isPlayoff
  AFTER INSERT ON stage
    WHEN NEW.stageNumber >
      (SELECT regularSeason_length FROM season WHERE id = NEW.season_id)
    BEGIN
      UPDATE stage SET isPlayoff = TRUE WHERE season_id = NEW.season_id
        AND stageNumber = NEW.stageNumber;
    END;

CREATE TRIGGER tgr_mod_season_len
  BEFORE UPDATE OF length ON season
    WHEN NEW.length <
      (SELECT MAX(stageNumber) FROM stage WHERE season_id = NEW.id)
    BEGIN
      SELECT RAISE (ABORT, 'Season length cannot be less than season''s max stage.stageNumber');
    END;

CREATE TRIGGER tgr_mod_season_len_set_isPlayoff
  AFTER UPDATE OF regularSeason_length ON season
    WHEN NEW.regularSeason_length != OLD.regularSeason_length
    BEGIN
      UPDATE stage SET isPlayoff = TRUE WHERE stageNumber > NEW.regularSeason_length;
    END;


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
  FOREIGN KEY (stageNumber, season_id) REFERENCES stage (stageNumber, season_id)
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



-- how do we know the winner of a playoff round?
-- how to record games that start but are cancelled?

-- nice-to-haves
-- 1) view that combines game deets with team deets for printing
