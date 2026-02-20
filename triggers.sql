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
        AND (NEW.endDate IS NULL OR franchise.endDate < NEW.endDate))
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
  BEFORE UPDATE OF startDate on team
    WHEN NEW.startDate <
      (SELECT startDate FROM franchise WHERE id = NEW.franchise_id)
    BEGIN
      SELECT RAISE (ABORT,
      'A team cannot start before its franchise');
    END;

CREATE TRIGGER tgr_mod_team_end
  BEFORE UPDATE of endDate on team
    WHEN EXISTS
      (SELECT 1 FROM franchise WHERE id = NEW.franchise_id
        AND endDate IS NOT NULL
        AND (NEW.endDate IS NULL OR franchise.endDate < NEW.endDate))
    BEGIN
      SELECT RAISE (ABORT,
      'A team cannot end after its franchise');
    END;


-- Stages must monotonically increase (1, 2, 3...)
-- They also must occur during a season
-- Season length tracks num of stages in a season
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
      SELECT RAISE (ROLLBACK,
      'Stage number cannot be greater than season.length');
    END;

CREATE TRIGGER tgr_modify_stageNumber_not_allowed
  BEFORE UPDATE OF stageNumber ON stage
    BEGIN
      SELECT RAISE (ABORT, 'Modifying a stage''s number is not allowed.');
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
      UPDATE stage SET isPlayoff = TRUE WHERE season_id = NEW.season_id
        AND stageNumber = NEW.stageNumber;
    END;

CREATE TRIGGER tgr_mod_season_len_set_isPlayoff
  AFTER UPDATE OF regularSeason_length ON season
    WHEN NEW.regularSeason_length != OLD.regularSeason_length
    BEGIN
      UPDATE stage SET isPlayoff = TRUE
        WHERE stageNumber > NEW.regularSeason_length;
      UPDATE stage SET isPlayoff = FALSE
        WHERE stageNumber <= NEW.regularSeason_length;
    END;


-- Game needs to occur during a season
CREATE TRIGGER tgr_new_game_startDate_outside_season
  BEFORE INSERT ON game
    WHEN NEW.startDate NOT BETWEEN
      (SELECT startDate FROM season WHERE id = NEW.season_id)
    AND
      (SELECT endDate FROM season WHERE id = NEW.season_id)
    BEGIN
      SELECT RAISE(ROLLBACK,
      'Game must occur between season.startDate and season.endDate');
    END;

CREATE TRIGGER tgr_mod_game_startDate_outside_season
  BEFORE UPDATE OF startDate ON game
    WHEN NEW.startDate NOT BETWEEN
      (SELECT startDate FROM season WHERE id = NEW.season_id)
    AND
      (SELECT endDate FROM season WHERE id = NEW.season_id)
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