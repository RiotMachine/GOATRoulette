# GOATRoulette
Sports odds and betting model
*Under development*

GOAT Roulette is a terminal application for predicting head-to-head matchup results.

## SQL

### Schema
Each database tracks results of a league across multiple seasons.

The schema is intentionally 'flat.' This accomodates the wide range of league structures. In-season tournaments, pool play, and non-week-based regular seasons are all permitted.

Teams are printing-info wrappers for franchises.

Season and Champion are one-to-zero/one-to-many. We wanted to accomodate situations where a season is cancelled early and no title is awarded, or a title is vacated. We also wanted to make allowances for seasons when a championship is shared across multiple teams.

dBs should be instantiated schema -> summaryTables -> views -> triggers -> data.

### Views
Views exist to give topography to the flat database structure.

The database enforces many things. For various reasons it does not enforce that a franchise has a team during the period it plays a game. Users should query view_emptyTeamGames to ensure all games have a team when they are played and/or use application logic to test for/enforce this.

view_playoff_bracketGames allows one to view playoff tournament results round by round. It makes allowances for multi-elimination tournaments and best-of playoff series. 

### Assumptions
- Consolation games are not documented as playoff games (if at all)

Users may need to tweak schema and/or application code depending on which assumptions are broken.

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