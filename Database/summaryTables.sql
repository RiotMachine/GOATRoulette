-- Assuming nuke and pave for these for now
-- Not sure yet whether I want cron jobs or triggers 
-- INSERTs can be found in scripts.sql


-- Which teams participate in which playoff rounds by season
CREATE TABLE playoffParticipant_summary (
    season_id     INTEGER NOT NULL REFERENCES season,
    round         INTEGER NOT NULL
        CHECK (round > 0),
    franchise_id  INTEGER NOT NULL REFERENCES franchise,
  PRIMARY KEY(season_id, round, franchise_id)
) STRICT, WITHOUT ROWID;


-- Team's regular season W/L/T record
CREATE TABLE team_regularSeason_summary (
    franchise_id      INTEGER NOT NULL REFERENCES franchise,
    season_id         INTEGER NOT NULL REFERENCES season,
    wins              INTEGER NOT NULL DEFAULT 0
        CHECK (wins >= 0),
    losses            INTEGER NOT NULL DEFAULT 0
        CHECK (losses >= 0),
    ties              INTEGER NOT NULL DEFAULT 0
        CHECK (ties >= 0),
  PRIMARY KEY(franchise_id, season_id)
) STRICT, WITHOUT ROWID;