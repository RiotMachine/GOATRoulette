CREATE TABLE playoff_summary (
    season_id     INTEGER NOT NULL REFERENCES season,
    round         INTEGER NOT NULL
        CHECK (round > 0),
    franchise_id  INTEGER NOT NULL REFERENCES franchise,
  PRIMARY KEY(season_id, round, franchise_id)
) STRICT, WITHOUT ROWID;

WITH 
  playoffs AS (
    SELECT 
      game.season_id,
      game.stageNumber,
      home_id,
      away_id
    FROM game
      INNER JOIN stage
        ON stage.stageNumber = game.stageNumber
          AND stage.season_id = game.season_id
          AND stage.isPlayoff = TRUE
  )
INSERT INTO playoff_summary
    (season_id, round, franchise_id)
  SELECT
    season_id,
    DENSE_RANK() OVER (
      PARTITION BY season_id
      ORDER BY stageNumber
    ),
    home_id AS franchise_id
  FROM playoffs

  UNION

  SELECT
    season_id,
    DENSE_RANK() OVER (
      PARTITION BY season_id
      ORDER BY stageNumber
    ),
    away_id AS franchise_id
  FROM playoffs;


CREATE TABLE performance_summary (
    franchise_id      INTEGER NOT NULL REFERENCES franchise,
    season_id         INTEGER NOT NULL REFERENCES season,
    wins              INTEGER NOT NULL DEFAULT 0
        CHECK (wins >= 0),
    losses            INTEGER NOT NULL DEFAULT 0
        CHECK (losses >= 0),
    ties              INTEGER NOT NULL DEFAULT 0
        CHECK (ties >= 0),
    finalPlayoffRound INTEGER NOT NULL DEFAULT 0
        CHECK (finalPlayoffRound >= 0),
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
      IIF(homeScore > awayScore, 1, 0) AS win,
      IIF(homeScore < awayScore, 1, 0) AS loss,
      IIF(homeScore = awayScore, 1, 0) AS tie
    FROM regularSeasonGame

    UNION ALL

    SELECT
      away_id AS franchise_id,
      season_id,
      IIF(awayScore > homeScore, 1, 0) AS win,
      IIF(awayScore < homeScore, 1, 0) AS loss,
      IIF(awayScore = homeScore, 1, 0) AS tie
    FROM regularSeasonGame         
  )
INSERT INTO performance_summary
    (franchise_id, season_id,
     wins, losses, ties,
     finalPlayoffRound) 
  SELECT
    rsr.franchise_id,
    rsr.season_id,
    SUM(rsr.win),
    SUM(rsr.loss),
    SUM(rsr.tie),
    IFNULL(
      (SELECT MAX(playoff.round)
       FROM playoff_summary AS playoff
       WHERE playoff.season_id = rsr.season_id
       AND playoff.franchise_id = rsr.franchise_id)
      , 0
    )
  FROM regularSeasonResult AS rsr
  GROUP BY franchise_id, season_id;