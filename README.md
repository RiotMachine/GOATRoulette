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
Teams are printing-info wrappers for franchises.

The database enforces many things. For various reasons it does not enforce that a franchise has a team during the period it plays a game. Users should query view_game_teams to ensure all games have a team when they are played and/or use application logic to test for/enforce this.
