-- Rollbacking if we're adding
-- Aborting if we're modifying
-- If we're pushing a simulation or uploading a db
--     our base data is all probs f-ed up
-- If we're modifying the db
--     not every surgical change invalidates other changes

-- Teams must exist during associated Franchise
-- If end-date is NULL, team/franchise is extant
CREATE TRIGGER tgr_new_team_before_franchise_start
  BEFORE INSERT ON team
    WHEN NEW.startDate <
      (SELECT startDate FROM franchise WHERE id = NEW.franchise_id)
    BEGIN
      SELECT RAISE (ROLLBACK,
      'Team cannot exist before franchise start date');
    END;

CREATE TRIGGER tgr_new_team_after_franchise_end
  BEFORE INSERT ON team
    WHEN EXISTS
      (SELECT 1 FROM franchise WHERE id = NEW.franchise_id
        AND endDate IS NOT NULL
        AND (NEW.endDate IS NULL OR endDate < NEW.endDate))
    BEGIN
      SELECT RAISE (ROLLBACK,
      'Team cannot exist after franchise end date');
    END;

CREATE TRIGGER tgr_mod_franchise_start
  BEFORE UPDATE OF startDate ON franchise
    WHEN NEW.startDate >
      (SELECT MIN(startDate) FROM team WHERE franchise_id = NEW.id)
    BEGIN
      SELECT RAISE (ABORT,
      'A franchise cannot start after one of its teams');
    END;

CREATE TRIGGER tgr_mod_franchise_end
  BEFORE UPDATE OF endDate ON franchise
    WHEN NEW.endDate IS NOT NULL
      AND EXISTS
        (SELECT 1 FROM team WHERE franchise_id = NEW.id
          AND (endDate IS NULL OR endDate > NEW.endDate))
    BEGIN
      SELECT RAISE (ABORT,
      'A franchise cannot end before one of its teams');
    END;

CREATE TRIGGER tgr_mod_team_start
  BEFORE UPDATE OF startDate ON team
    WHEN NEW.startDate <
      (SELECT startDate FROM franchise WHERE id = NEW.franchise_id)
    BEGIN
      SELECT RAISE (ABORT,
      'A team cannot start before its franchise');
    END;

CREATE TRIGGER tgr_mod_team_end
  BEFORE UPDATE OF endDate ON team
    WHEN EXISTS
      (SELECT 1 FROM franchise WHERE id = NEW.franchise_id
        AND endDate IS NOT NULL
        AND (NEW.endDate IS NULL OR endDate < NEW.endDate))
    BEGIN
      SELECT RAISE (ABORT,
      'A team cannot end after its franchise');
    END;


-- Franchise can only have one team at any given time
CREATE TRIGGER tgr_add_team_franchise_would_have_two
  BEFORE INSERT ON team
    WHEN EXISTS (
      SELECT 1 FROM team 
        WHERE franchise_id = NEW.franchise_id
        AND (
          (NEW.startDate < endDate OR endDate IS NULL) 
          AND 
          (NEW.endDate > startDate OR NEW.endDate IS NULL)
        )
      )
    BEGIN
      SELECT RAISE (ROLLBACK,
      'A franchise can only have one team at a time');
    END;

CREATE TRIGGER tgr_mod_team_franchise_would_have_two
  BEFORE UPDATE OF franchise_id, startDate, endDate ON team
    WHEN EXISTS (
      SELECT 1 FROM team 
        WHERE franchise_id = NEW.franchise_id
        AND startDate != OLD.startDate
        AND (
          (NEW.startDate < endDate OR endDate IS NULL) 
          AND 
          (NEW.endDate > startDate OR NEW.endDate IS NULL)
        )
      )
    BEGIN
      SELECT RAISE (ABORT,
      'A franchise can only have one team at a time');
    END;


-- Stages must monotonically increase (1, 2, 3...)
-- They also must occur during a season
-- Season length tracks num of stages in a season
CREATE TRIGGER tgr_new_stageNumber_not_incremental
  BEFORE INSERT ON stage
    WHEN NEW.stageNumber != (1 + IFNULL(
      (SELECT MAX(stageNumber) FROM stage WHERE season_id = NEW.season_id), 0))
    BEGIN
      SELECT RAISE (ROLLBACK, 
      'Stages must monotonically increase');
    END;

CREATE TRIGGER tgr_new_stageNumber_exceeds_length
  BEFORE INSERT ON stage
    WHEN NEW.stageNumber >
      (SELECT length FROM season WHERE id = NEW.season_id)
    BEGIN
      SELECT RAISE (ROLLBACK,
      'Stage number cannot be greater than season.length');
    END;

CREATE TRIGGER tgr_modify_stageNumber_not_allowed
  BEFORE UPDATE OF stageNumber ON stage
    BEGIN
      SELECT RAISE (ABORT, 
      'Modifying a stage''s number is not allowed.');
    END;

CREATE TRIGGER tgr_mod_season_len
  BEFORE UPDATE OF length ON season
    WHEN NEW.length <
      (SELECT MAX(stageNumber) FROM stage WHERE season_id = NEW.id)
    BEGIN
      SELECT RAISE (ABORT,
      'Season length cannot be less than season''s max stage.stageNumber');
    END;


-- isPlayoff should be auto-set based on regular-season length
CREATE TRIGGER tgr_new_stage_set_isPlayoff
  AFTER INSERT ON stage
    WHEN NEW.stageNumber >
      (SELECT regularSeason_length FROM season WHERE id = NEW.season_id)
    BEGIN
      UPDATE stage SET isPlayoff = TRUE 
        WHERE season_id = NEW.season_id
          AND stageNumber = NEW.stageNumber;
    END;

CREATE TRIGGER tgr_mod_regularSeason_shorter_set_isPlayoff
  AFTER UPDATE OF regularSeason_length ON season
    WHEN NEW.regularSeason_length < OLD.regularSeason_length
    BEGIN
      UPDATE stage SET isPlayoff = TRUE
        WHERE stageNumber > NEW.regularSeason_length
          AND stageNumber <= OLD.regularSeason_length
          AND season_id = NEW.season_id;
    END;

CREATE TRIGGER tgr_mod_seasonLength_longer_set_isPlayoff
  AFTER UPDATE OF regularSeason_length ON season
    WHEN NEW.regularSeason_length > OLD.regularSeason_length
    BEGIN
      UPDATE stage SET isPlayoff = FALSE
        WHERE stageNumber > OLD.regularSeason_length
          AND stageNumber <= NEW.regularSeason_length
          AND season_id = NEW.season_id;
    END;


-- Game needs to occur during a season
CREATE TRIGGER tgr_new_game_startDate_outside_season
  BEFORE INSERT ON game
    WHEN EXISTS
      (SELECT 1 FROM season
        WHERE id = NEW.season_id
          AND (NEW.startDate < startDate OR NEW.startDate > endDate))
    BEGIN
      SELECT RAISE(ROLLBACK,
      'Game must occur between season.startDate and season.endDate');
    END;

CREATE TRIGGER tgr_mod_game_startDate_outside_season
  BEFORE UPDATE OF startDate ON game
    WHEN EXISTS
      (SELECT 1 FROM season
        WHERE id = NEW.season_id
          AND (NEW.startDate < startDate OR NEW.startDate > endDate))
    BEGIN
      SELECT RAISE(ABORT,
      'Game must occur between season.startDate and season.endDate');
    END;

CREATE TRIGGER tgr_mod_season_startDate
  BEFORE UPDATE OF startDate ON season
    WHEN NEW.startDate >
      (SELECT MIN(startDate) FROM game WHERE season_id = NEW.id)
    BEGIN
      SELECT RAISE(ABORT,
      'Setting season startDate to this value would cause invalid game dates');
    END;

CREATE TRIGGER tgr_mod_season_endDate
  BEFORE UPDATE OF endDate ON season
    WHEN NEW.endDate <
      (SELECT MAX(startDate) FROM game WHERE season_id = NEW.id)
    BEGIN
      SELECT RAISE(ABORT,
      'Setting season endDate to this value would cause invalid game dates');
    END;


-- A franchise needs to have a team when it plays a game
CREATE TRIGGER tgr_add_game_need_team
  BEFORE INSERT ON game
    WHEN NOT EXISTS (
      SELECT 1 FROM team
        WHERE franchise_id = NEW.home_id
          AND NEW.startDate >= startDate
          AND (NEW.startDate <= endDate OR endDate IS NULL)
    )
    OR NOT EXISTS (
      SELECT 1 FROM team
        WHERE franchise_id = NEW.away_id
          AND NEW.startDate >= startDate
          AND (NEW.startDate <= endDate OR endDate IS NULL)
    )
    BEGIN
      SELECT RAISE(ROLLBACK,
      'A franchise must have a team when the game was played');
    END;

CREATE TRIGGER tgr_mod_game_need_team
  BEFORE UPDATE OF home_id, away_id, startDate ON game
    WHEN NOT EXISTS (
      SELECT 1 FROM team
        WHERE franchise_id = NEW.home_id 
          AND NEW.startDate >= startDate
          AND (NEW.startDate <= endDate OR endDate IS NULL)
    )
    OR NOT EXISTS (
      SELECT 1 FROM team
        WHERE franchise_id = NEW.away_id
          AND NEW.startDate >= startDate
          AND (NEW.startDate <= endDate OR endDate IS NULL)
    )
    BEGIN
      SELECT RAISE(ABORT,
      'A franchise must have a team when the game was played');
    END;


-- Cant modify a team's start/end if it would orphan a game
CREATE TRIGGER tgr_mod_team_orphans_game
  BEFORE UPDATE OF franchise_id, startDate, endDate ON team
    WHEN EXISTS (
      SELECT 1 FROM game
        WHERE (home_id = OLD.franchise_id OR away_id = OLD.franchise_id)
        AND startDate >= OLD.startDate
        AND (startDate <= OLD.endDate OR OLD.endDate IS NULL)
        AND (
          startDate < NEW.startDate
          OR (startDate > NEW.endDate AND NEW.endDate IS NOT NULL)
        )
    )
    BEGIN
      SELECT RAISE(ABORT,
      'Modifying this team in this way would orphan a game');
    END;