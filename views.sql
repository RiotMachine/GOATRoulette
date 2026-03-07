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
      DATE(game.startDate), 
      IF(atNeutralSite, 'Neutral site', homeTeam.city),
      game.stageNumber, 
      CONCAT(awayTeam.city, ' ', awayTeam.mascot), 
      game.awayScore,
      CONCAT(homeTeam.city, ' ', homeTeam.mascot), 
      game.homeScore
    FROM game
      INNER JOIN team AS awayTeam
        ON game.away_id = awayTeam.franchise_id 
      INNER JOIN team AS homeTeam
        ON game.home_id = homeTeam.franchise_id;


-- Season | Stage | Game in stage |
-- Game details | Stage results to that point
CREATE VIEW view_playoffs (
    season_id,
    round,
    game,
    team_1,
    team_1_score,
    team_2,
    team_2_score,
    team_1_wins,
    team_2_wins
) AS
    SELECT 
      game.season_id, 
      game.stageNumber - season.regularSeason_length,
      ROW_NUMBER() OVER (
         PARTITION BY 
           game.season_id, 
           game.stageNumber, 
           MIN(game.away_id, game.home_id), 
           MAX(game.away_id, game.home_id)
         ORDER BY 
           game.date
      ),
      CONCAT(team_1.city, ' ', team_1.mascot),
      IF(team_1.franchise_id = game.home_id, game.homeScore, game.awayScore)
      CONCAT(team_2.city, ' ', team_2.mascot),
      IF(team_2.franchise_id = game.home_id, game.homeScore, game.awayScore)
      SUM(IF(team_1_score > team_2_score, 1, 0)) OVER (

      ),
      SUM(IF(team_2_score > team_1_score, 1, 0)) OVER (

      )
    FROM game
      INNER JOIN season
        ON game.season_id = season.id
      INNER JOIN team AS team_1
        ON MIN(game.away_id, game.home_id) = team_1.franchise_id
      INNER JOIN team AS team_2
        ON MAX(game.away_id, game.home_id) = team_2.franchise_id
      INNER JOIN stage
        ON game.season_id = stage.season_id
          AND game.stageNumber = stage.stageNumber
    WHERE stage.isPlayoff = TRUE


-- Team | Season start | Season end | Regular szn wins | Reg szn losses | Playoff performance
CREATE VIEW view_teamSeason (

)


CREATE VIEW view_emptyTeamGames (
  
)