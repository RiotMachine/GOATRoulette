-- Season | Stage(asc) | isPlayoff | Game
CREATE VIEW view_databaseFlow (
    season_id,
    stage_number,
    isPlayoffStage,
    game_id
) AS SELECT season.id, stage.stageNumber, stage.isPlayoff, game.id
    FROM season
      INNER JOIN stage
        ON season.id = stage.season_id
      INNER JOIN game
        ON season.id = game.season_id 
          AND stage.stageNumber = game.stageNumber;


CREATE VIEW view_game (
    id,
    stage,
    season_id,
    time,
    location,
    away_id,
    awayTeam,
    awayScore,
    home_id,
    homeTeam,
    homeScore
) AS SELECT 
       game.id, 
       game.stageNumber,
       game.season_id, 
       DATE(game.startDate, 'unixepoch'), 
       IIF(atNeutralSite, 'Neutral site', homeTeam.city),
       awayTeam.franchise_id,
       CONCAT(awayTeam.city, ' ', awayTeam.mascot), 
       game.awayScore,
       homeTeam.franchise_id,
       CONCAT(homeTeam.city, ' ', homeTeam.mascot), 
       game.homeScore
     FROM game
       INNER JOIN team AS awayTeam
         ON game.away_id = awayTeam.franchise_id
           AND game.startDate >= awayTeam.startDate
           AND (game.startDate <= awayTeam.endDate OR awayTeam.endDate IS NULL) 
       INNER JOIN team AS homeTeam
         ON game.home_id = homeTeam.franchise_id
           AND game.startDate >= homeTeam.startDate
           AND (game.startDate <= homeTeam.endDate OR homeTeam.endDate IS NULL);


CREATE VIEW view_game_generic
  AS SELECT
       id,
       stage,
       season_id,
       time,
       location,
       MIN(away_id, home_id) AS team1_id,
       IIF(
         MIN(away_id, home_id) = away_id, awayTeam, homeTeam
       ) AS team1_name,
       IIF(
         MIN(away_id, home_id) = away_id, awayScore, homeScore
       ) AS team1_score,
       MAX(away_id, home_id) AS team2_id,
       IIF(
         MAX(away_id, home_id) = away_id, awayTeam, homeTeam
       ) AS team2_name,
       IIF(
         MAX(away_id, home_id) = away_id, awayScore, homeScore
       ) AS team2_score
     FROM view_game;


CREATE VIEW view_playoff_bracketGames (
    game_id,
    round,
    round_game,
    season_id,
    time,
    location,
    team1_name,
    team1_score,
    team2_name,
    team2_score,
    team1_wins,
    team2_wins
) AS SELECT 
       v_game.id,
       DENSE_RANK() OVER (
         PARTITION BY v_game.season_id
         ORDER BY v_game.stage
       ),
       ROW_NUMBER() OVER (
         window_series
       ),
       v_game.season_id,
       v_game.time,
       v_game.location,
       team1_name,
       team1_score,
       team2_name,
       team2_score,
       SUM(IIF(team1_score > team2_score, 1, 0)) OVER (
         window_series
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ),
       SUM(IIF(team1_score < team2_score, 1, 0)) OVER (
         window_series
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       )
     FROM view_game_generic AS v_game
       INNER JOIN stage
         ON stage.stageNumber = v_game.stage
           AND stage.season_id = v_game.season_id
           AND stage.isPlayoff = TRUE            
     WINDOW window_series AS (
       PARTITION BY
         v_game.season_id, 
         v_game.stage,
         team1_id,
         team2_id
       ORDER BY
         v_game.time
     );


-- Team | Season start | Season end | Regular szn wins |
-- Reg szn losses | Playoff performance
CREATE VIEW view_franchisePerformance
  AS SELECT
       trs.franchise_id
       trs.season_id,
       IFNULL( 
         (SELECT CONCAT(team.city, ' ', team.mascot)
          FROM team
          WHERE team.franchise_id = trs.franchise_id
            AND team.startDate <= season.startDate
            AND (team.endDate >= season.endDate OR team.endDate IS NULL))
         , 'No one team spans season'
       ) AS team_name,
       DATE(season.startDate, 'unixepoch') AS seasonStart,
       DATE(season.endDate  , 'unixepoch') AS seasonEnd,
       trs.wins,
       trs.losses,
       trs.ties,
       IFNULL(
         (SELECT MAX(pas.round)
          FROM playoffParticipant_summary AS pas
          WHERE pas.season_id = trs.season_id
            AND pas.franchise_id = trs.franchise_id)
         , 0
       ) AS finalPlayoffRound,
       season.length - season.regularSeason_length AS totalPlayoffRounds,
       IFNULL(
         (SELECT TRUE
          FROM champion
          WHERE champion.franchise_id = trs.franchise_id
            AND champion.season_id = trs.season_id),
         , FALSE
       ) AS championBool
     FROM team_regularSeason_summary AS trs
       INNER JOIN season
         ON season.id = trs.season_id;


CREATE VIEW view_emptyTeamGames (
  
)