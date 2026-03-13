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
    away_id
    awayTeam,
    awayScore,
    home_id
    homeTeam,
    homeScore
) AS SELECT 
       game.id, 
       game.stageNumber,
       game.season_id, 
       DATE(game.startDate, 'unixepoch'), 
       IF(atNeutralSite, 'Neutral site', homeTeam.city),
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


CREATE VIEW view_playoffs (
    game_id,
    round,
    round_game,
    season_id,
    time,
    location,
    team1,
    team1_score
    team2,
    team2_score
) AS 
     SELECT 
       v_game.id,
       v_game.stageNumber + 1 - MIN(v_game.stageNumber) OVER (
         PARTITION BY v_game.season_id
       ),
       ROW_NUMBER() OVER (
         window_series
       ),
       v_game.season_id,
       v_game.time,
       v_game.location,


     FROM stage
     WHERE isPlayoff = TRUE
       INNER JOIN view_game AS v_game
         ON v_game.stage = stage.stageNumber
           AND v_game.season_id = stage.season_id            


      SUM(IF(team_1_score > team_2_score, 1, 0)) OVER (
        window_series
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ),
      SUM(IF(team_2_score > team_1_score, 1, 0)) OVER (
        window_series
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      )
     WINDOW window_series AS (
       PARTITION BY
         season_id, 
         round,
         team_1_id,
         team_2_id
       ORDER BY
         gameDeets.startDate
     );


-- Team | Season start | Season end | Regular szn wins | Reg szn losses | Playoff performance
CREATE VIEW view_teamSeason (

)


CREATE VIEW view_emptyTeamGames (
  
)