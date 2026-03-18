CREATE TABLE playoffParticipant_summary (
    season_id     INTEGER NOT NULL REFERENCES season,
    round         INTEGER NOT NULL
        CHECK (round > 0),
    franchise_id  INTEGER NOT NULL REFERENCES franchise,
  PRIMARY KEY(season_id, round, franchise_id)
) STRICT, WITHOUT ROWID;

WITH 
  playoffGame AS (
    SELECT 
      game.season_id,
      DENSE_RANK() OVER (
        PARTITION BY game.season_id
        ORDER BY game.stageNumber
      ) AS round,
      home_id,
      away_id
    FROM game
      INNER JOIN stage
        ON stage.stageNumber = game.stageNumber
          AND stage.season_id = game.season_id
          AND stage.isPlayoff = TRUE
  )
INSERT INTO playoffParticipant_summary
    (season_id, round, franchise_id)
  SELECT
    season_id,
    round,
    home_id AS franchise_id
  FROM playoffGame

  UNION

  SELECT
    season_id,
    round,
    away_id AS franchise_id
  FROM playoffGame;


CREATE TABLE team_regularSeason_summary (
    franchise_id      INTEGER NOT NULL REFERENCES franchise,
    season_id         INTEGER NOT NULL REFERENCES season,
    wins              INTEGER NOT NULL DEFAULT 0
        CHECK (wins >= 0),
    losses            INTEGER NOT NULL DEFAULT 0
        CHECK (losses >= 0),
    ties              INTEGER NOT NULL DEFAULT 0
        CHECK (ties >= 0)
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
INSERT INTO team_regularSeason_summary
    (franchise_id, season_id,
     wins, losses, ties) 
  SELECT
    rsr.franchise_id,
    rsr.season_id,
    SUM(rsr.win),
    SUM(rsr.loss),
    SUM(rsr.tie),
  FROM regularSeasonResult AS rsr
  GROUP BY franchise_id, season_id;