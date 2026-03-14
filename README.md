# GOATRoulette
Sports odds and betting model
*Under development*

## Iteration 1
C++ SQL wrapper for stats querying

## Iteration 2
C++ advanced multi-layered stats querying

## Iteration 3
Built-in prediction modeling

## Iteration 4
Slider-based prediction modeling for both past and future events

## Iteration 5
User-driven model modulation and creation

## SQL

### Schema
Each database tracks results of a league across multiple seasons.

The schema is intentionally 'flat.' This accomodates the wide range of sports league structures. Views exist to give topography to this flat structure. In-season tournaments, pool play, and non-week-based regular seasons are all permitted.

Teams are printing-info wrappers for franchises.

The database enforces many things. For various reasons it does not enforce that a franchise has a team during the period it plays a game. Users should query view_emptyTeamGames to ensure all games have a team when they are played and/or use application logic to test for/enforce this.

view_playoff_tournamentGames allows one to view playoff tournament results round by round. It makes allowances for multi-elimination tournaments and best-of playoff series. 

#### Assumptions
- Consolation games are not documented. 
- Pool-play occurs during a regular season. 
- Playoffs are continuous (without regular-season interruption)

Users may need to tweak schema and/or application code depending on which assumptions are broken. It should be noted that we have defaulted to these assumptions only in cases of utmost extremity.