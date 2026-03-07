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
        ON season.id = game.season_id AND stage.stageNumber = game.stageNumber;


-- Game_id | Time | Location | Stage |
-- Away | Away score | Home | Home score
CREATE VIEW view_game (
    id,
    time,
    location,
    stage,
    awayTeam,
    awayScore,
    homeTeam,
    homeScore
) AS SELECT 
      game.id, 
      DATE(game.startDate, 'unixepoch'), 
      IF(atNeutralSite, 'Neutral site', homeTeam.city),
      game.stageNumber, 
      CONCAT(awayTeam.city, ' ', awayTeam.mascot), 
      game.awayScore,
      CONCAT(homeTeam.city, ' ', homeTeam.mascot), 
      game.homeScore
    FROM game
      INNER JOIN team AS awayTeam
        ON game.away_id = awayTeam.franchise_id
          AND game.startDate > awayTeam.startDate
          AND (game.startDate < awayTeam.endDate OR endDate IS NULL) 
      INNER JOIN team AS homeTeam
        ON game.home_id = homeTeam.franchise_id
          AND game.startDate > homeTeam.startDate
          AND (game.startDate < homeTeam.endDate OR endDate IS NULL);


-- Season | Stage | Game in stage |
-- Game details | Stage results to that point
CREATE VIEW view_playoffs (
    season_id, round, game,
    team_1, 
    team_1_score,
    team_2, 
    team_2_score,
    team_1_wins, 
    team_2_wins
) AS
    WITH gameDeets (
      season_id, round,
      team_1_id, team_1_score,
      team_2_id, team_2_score,
      startDate
    )
    AS (
      SELECT 
        game.season_id,
        game.stageNumber + 1 - MIN(game.stageNumber) OVER (
          PARTITION BY game.season_id
        ),
        MIN(game.away_id, game.home_id),
        IF (MIN(game.away_id, game.home_id) = game.home_id, game.homeScore, game.awayScore),
        MAX(game.away_id, game.home_id),
        IF (MAX(game.away_id, game.home_id) = game.home_id, game.homeScore, game.awayScore),
        game.startDate
      FROM game
        INNER JOIN stage
          ON game.season_id = stage.season_id
            AND game.stageNumber = stage.stageNumber
            AND stage.isPlayoff = TRUE
    )            
    SELECT
      season_id, round,
      ROW_NUMBER() OVER (
        window_series
      ),
      CONCAT(team_1.city, ' ', team_1.mascot), team_1_score,
      CONCAT(team_2.city, ' ', team_2.mascot), team_2_score,
      SUM(IF(team_1_score > team_2_score, 1, 0)) OVER (
        window_series
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ),
      SUM(IF(team_2_score > team_1_score, 1, 0)) OVER (
        window_series
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      )
    FROM gameDeets
      INNER JOIN team AS team_1
        ON gameDeets.team_1_id = team_1.franchise_id
      INNER JOIN team AS team_2
        ON gameDeets.team_2_id = team_2.franchise_id
    WINDOW window_series AS (
      PARTITION BY
        season_id, 
        round,
        team_1_id,
        team_2_id
      ORDER BY
        startDate
      )



-- Team | Season start | Season end | Regular szn wins | Reg szn losses | Playoff performance
CREATE VIEW view_teamSeason (

)


CREATE VIEW view_emptyTeamGames (
  
)