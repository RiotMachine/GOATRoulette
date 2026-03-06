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


-- Game_id | Time | Location | Stage | Away | Away score | Home | Home score
CREATE VIEW view_game (
    id,
    time,
    location,
    stage,
    awayTeam,
    awayScore,
    homeTeam,
    homeScore
) AS SELECT game.id, DATE(game.startDate), IF(atNeutralSite, 'Neutral site', homeTeam.city),
    game.stageNumber, CONCAT(awayTeam.city, ' ', awayTeam.mascot), game.awayScore,
    CONCAT(homeTeam.city, ' ', homeTeam.mascot), game.homeScore
    FROM game
      INNER JOIN team AS awayTeam
        ON game.away_id = team.franchise_id
      INNER JOIN team AS homeTeam
        ON game.home_id = team.franchise_id


-- Season | Stage | Game in stage | Game details
CREATE VIEW view_playoffs (

)


-- Team | Season start | Season end | Regular szn wins | Reg szn losses | Playoff performance
CREATE VIEW view_teamSeason(

)


CREATE VIEW view_emptyTeamGames (

)