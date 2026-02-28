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

### Philosophy
GOAT enforces data consistency and integrity for UPDATEs and INSERTs. In case you want to add more rows, or add descriptive fields to existing rows within the Sqlite3 CLI, you can sleep soundly. DELETEs, on the other hand, are permissive with regard to integrity when they do not affect FK relations.

Base-data, such as franchises and games, are directly relied upon by prediction models. Printing-data are for terminal output. The FK structure prevents base-data deletion when it affects data consistency and integrity. However, we have allowed DELETEs of printing-data even if printing-data integrity would be harmed. 

This may seem unintuitive for SQL pros. Typically, UPDATEs are permissive, and DELETEs are used only in extreme cases. Whether you agree with our design decision, it’s worth knowing its philosophy.

In a typical business dB, integrity and ease are more valued than consistency. Though these surgical changes in a database are a threat to consistency, this trade-off makes sense for enterprises. 

Given that our database is an open-source modeling tool, our tack is different. An illogical database causes a noisy model. In use cases like ours, we feel it’s better to delete offending subsets and re-upload corrected versions than to make post facto corrections. In this world of UPDATEs that prioritize consistency, DELETEs are the only option for broken data. Furthermore, users might want to expand the database schema, making UPDATE integrity doubly important so inputs concurrent with these changes don’t inadvertently undermine data.

We have tried to limit the extent of what you need to re-input. For example, if your confused team chronology within a franchise somehow got past our INSERT filters, you should be able to delete those teams and re-upload sound team data without touching other tables. Base-data inaccuracies may need varying degrees of nuke and pave.

We attempt to create views and workflows which one can use before deleting and re-inserting printing-data, but do not warrant their completeness or correctness.

In general, when deleting printing-data:
1) Begin a transaction. 
2) Complete the series of DELETEs and INSERTs you think would rectify the problem.
3) Run the suggested view query
4a) If the query is successful, commit.
4b) If the query is unsuccessful, rollback

BEGIN
(SQL statements)
(View query)
COMMIT or ROLLBACK

#### Printing-data views
No team-orphaned games
