-- playoffParticipant_summary table setup
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


-- team_regularSeason_summary table setup
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
    SUM(rsr.tie)
  FROM regularSeasonResult AS rsr
  GROUP BY franchise_id, season_id;


-- insert playoff winners into Champion
-- vulnerable to 'final' rounds with >2 participants
WITH
  championshipStage AS (
    SELECT
      MAX(stageNumber) AS stage,
      season_id
    FROM stage
      WHERE isPlayoff = TRUE
    GROUP BY season_id
  ),
  championStageGame AS (
    SELECT
      vgg.season_id,
      vgg.team1_id,
      vgg.team1_score,
      vgg.team2_id,
      vgg.team2_score
    FROM championshipStage as cs
      INNER JOIN view_game_generic AS vgg
        ON vgg.season_id = cs.season_id
          AND vgg.stage = cs.stage
  ),
  championshipRecord AS (
    SELECT
      season_id,
      team1_id,
      SUM(
        IIF(team1_score > team2_score, 1, 0)
      ) AS team1_wins,
      team2_id,
      SUM(
        IIF(team1_score < team2_score, 1, 0)
      ) AS team2_wins
    FROM championStageGame
    GROUP BY season_id, team1_id, team2_id
  )
INSERT INTO champion
    (season_id, franchise_id)
  SELECT
    season_id,
    CASE
      WHEN team1_wins > team2_wins
        THEN team1_id
      ELSE
        team2_id
      END
  FROM championshipRecord
  WHERE team1_wins != team2_wins;