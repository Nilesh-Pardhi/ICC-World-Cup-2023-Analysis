
-- 1. Total Matches played
SELECT COUNT(*) AS total_matches
FROM matches_cleaned;


-- 2. Total teams participating
SELECT COUNT(*) AS total_teams
FROM (
	SELECT team1 AS team FROM matches_cleaned
    UNION 
    SELECT team2 AS team FROM matches_cleaned
) AS teams;


-- 3. Toal runs scored in the tournament
SELECT
	SUM(runs_off_bat + extras) AS total_runs
FROM deliveries_cleaned;


-- 4. Total wickets taken
SELECT
	COUNT(
		CASE
			WHEN wicket_type IS NOT NULL 
				AND wicket_type NOT IN ("No Wicket", "retired hurt")
			THEN 1
		END
	) AS total_wickets
FROM deliveries_cleaned;


-- 5. Highest Individul Score
SELECT
	batting_team,
    striker AS batter,
    match_id,
    SUM(runs_off_bat) AS individual_score
FROM deliveries_cleaned
GROUP BY batting_team, striker, match_id
ORDER BY individual_score DESC
limit 1;


-- 6. Leading run scorer
SELECT
    striker AS batter,
    batting_team,
    SUM(runs_off_bat) AS total_runs
FROM deliveries_cleaned
GROUP BY striker, batting_team
ORDER BY total_runs DESC
LIMIT 1;


-- 7. Leading wicket-taker
SELECT
    bowler,
    COUNT(
        CASE
            WHEN wicket_type IN (
                'bowled',
                'caught',
                'lbw',
                'stumped',
                'caught and bowled',
                'hit wicket'
            )
            THEN 1
        END
    ) AS total_wickets
FROM deliveries_cleaned
GROUP BY bowler
ORDER BY total_wickets DESC
LIMIT 1;


-- 8.  Points-table leader

SELECT
    team,
    points,
    net_run_rate
FROM points_table_cleaned
ORDER BY points DESC, net_run_rate DESC
LIMIT 1;


-- Q9 Find the total number of matches played in the tournament.
select count(*) 
from matches_cleaned;



-- Q10. Find the total number of teams in the points_table.
select count(*) 
from points_table_cleaned;

-- Q11. Display all matches won by India.
select *
from matches_cleaned
where winner = "India";

-- Q12. Find the number of matches won by each team using the matches table.
SELECT 
	winner AS team,
    count(*) AS total_wins
FROM matches_cleaned
WHERE winner IS NOT NULL 
GROUP BY winner 
ORDER BY total_wins DESC;

-- Q13. Display the top 5 teams based on points from the points_table.
SELECT 
	team,
	points
FROM points_table_cleaned
ORDER BY points DESC
LIMIT 5;

-- Q14. Find the total runs scored by each batting team using the deliveries table. Use runs_off_bat and extras appropriately.
SELECT
	batting_team,
    SUM(runs_off_bat + extras) AS total_runs
FROM deliveries_cleaned
GROUP BY batting_team
ORDER BY total_runs DESC;

-- Q15. Find the total number of deliveries recorded for each batting team.
SELECT
	batting_team,
    COUNT(*) AS total_deliveries
FROM deliveries_cleaned
GROUP BY batting_team
ORDER BY total_deliveries DESC;

-- Q16. Find the total wins, losses and points for each team using the points_table.
SELECT
	team,
    won,
    lost,
    points
FROM points_table_cleaned
ORDER BY points DESC;

-- Q17. Find the number of matches played at each venue.
    
SELECT 
	venue, 
    COUNT(*) total_matches
FROM matches_cleaned
GROUP BY venue
ORDER BY total_matches DESC;

-- Q18. Find the top 10 players with the highest total runs scored using deliveries

SELECT
	striker,
    SUM(runs_oFf_bat) AS total_runs
FROM deliveries_cleaned
GROUP BY striker
ORDER BY total_runs DESC
LIMIT 10;

-- Q19. Find the top 10 bowlers who took the most wickets. Exclude run-outs from bowler wickets.

SELECT 
	bowler,
    COUNT(wicket_type) AS total_wickets
FROM deliveries_cleaned
WHERE wicket_type IS NOT NULL
	AND wicket_type != "No Wicket"
    AND wicket_type != "run out"
GROUP BY bowler
ORDER BY total_wickets DESC
LIMIT 10;
    
    
-- Q20. Calculate each team's average runs scored per innings.
SELECT
    batting_team,
    ROUND(AVG(innings_runs),2) AS avg_runs_per_innings
FROM (
    SELECT
        match_id,
        innings,
        batting_team,
        SUM(runs_off_bat + extras) AS innings_runs
    FROM deliveries_cleaned
    GROUP BY match_id, innings, batting_team
) AS inning_summary
GROUP BY batting_team
ORDER BY avg_runs_per_innings DESC;

-- Q21. Find matches where the toss winner was also the match winner. 
SELECT 
	toss_winner,
    winner
FROM matches_cleaned
WHERE toss_winner = winner;

-- Q22. Find the percentage of matches won by the team that won the toss.
Select
	COUNT(*) AS total_matches_won_by_toss_winner,
    ROUND(
		COUNT(*) * 100.0 / (SELECT COUNT(*) FROM matches_cleaned),
        2
	) AS toss_winner_win_percentage
FROM matches_cleaned
WHERE toss_winner = winner;
    

-- Q23. Find the Player of the Match award count for each player and display the top 10. 

select 
	player_of_match,
	count(*) AS player_of_match_awards
FROM matches_cleaned
GROUP BY player_of_match
ORDER BY player_of_match_awards DESC
LIMIT 10;

-- Q24. Rank all teams by points and net run rate using the points_table
SELECT 
	team, 
    points,
    net_run_rate,
	RANK() OVER (
		ORDER BY points DESC, net_run_rate DESC
	) AS team_rank
FROM points_table_cleaned
ORDER BY points DESC, net_run_rate DESC;
	

-- Q25. Find the top 3 run scorers for each batting team using a window function.
WITH batter_runs AS (
	SELECT 
		batting_team, 
		striker,
		SUM(runs_off_bat) AS total_runs
	FROM deliveries_cleaned
    GROUP BY batting_team, striker
),
ranked_batters AS (
	SELECT
		batting_team, 
		striker,
        total_runs,
		ROW_NUMBER() OVER(
			PARTITION BY batting_team
			ORDER BY total_runs DESC
		) as batsman_rank
	FROM batter_runs
)
SELECT * 
FROM ranked_batters
WHERE batsman_rank <= 3
ORDER BY batting_team, batsman_rank;


-- Q26. Find the top 3 wicket-taking bowlers for each bowling team.

WITH bowler_wickets AS (
    SELECT
        bowling_team,
        bowler,
        COUNT(
            CASE
                WHEN wicket_type IS NOT NULL
                 AND wicket_type NOT IN (
                    'run out',
                    'retired hurt',
                    'obstructing the field',
                    'retired out',
                    'No Wicket'
                 )
                THEN 1
            END
        ) AS total_wickets
    FROM deliveries_cleaned
    GROUP BY bowling_team, bowler
),
ranked_bowler AS (
    SELECT
        bowling_team,
        bowler,
        total_wickets,
        ROW_NUMBER() OVER (
            PARTITION BY bowling_team
            ORDER BY total_wickets DESC
        ) AS bowling_rank
    FROM bowler_wickets
)
SELECT *
FROM ranked_bowler
WHERE bowling_rank <= 3
ORDER BY bowling_team, bowling_rank;


-- Q27. Calculate each batter's strike rate using total runs off the bat and legal balls faced. Exclude wides from balls faced.
SELECT 
	striker,
    SUM(runs_off_bat) AS total_runs,
    SUM(
		CASE
			WHEN COALESCE(wides, 0) = 0
				AND COALESCE(noballs, 0) = 0
            THEN 1
            ELSE 0
		END
	) AS legal_balls_faced,
    ROUND(
		SUM(runs_off_bat) * 100.0 /
        NULLIF(
			SUM(
				CASE 
					WHEN COALESCE(wides, 0) = 0
						AND COALESCE(noballs, 0) = 0
					THEN 1
                    ELSE 0
				END
			), 0
		), 
        2
	) AS strike_rate
FROM deliveries_cleaned
GROUP BY striker
ORDER BY strike_rate DESC;
    
-- Q28. Find each team's highest-scoring innings and the match in which it occurred.
WITH innings_scores AS (
	SELECT 
		match_id,
		batting_team,
		innings,
		SUM(runs_off_bat + extras) AS innings_runs
	FROM deliveries_cleaned
    GROUP BY match_id, batting_team, innings
), 
ranked_innings AS(
	SELECT 
		match_id,
		batting_team,
		innings,
        innings_runs,
		ROW_NUMBER() OVER(
			PARTITION BY batting_team
			ORDER BY innings_runs DESC
		) AS team_rank
	FROM innings_scores
)
SELECT 
	batting_team,
    match_id,
    innings,
    innings_runs
FROM ranked_innings
WHERE team_rank = 1
ORDER BY innings_runs DESC;
		


-- Q29. Find the top 5 players with the best batting average, using a clearly defined dismissal-based calculation and a minimum of 100 runs.
WITH batter_runs  AS(
	SELECT
		striker AS batter,
        SUM(runs_off_bat) AS total_runs
	FROM deliveries_cleaned
    GROUP BY striker
),
batter_dismissals AS(
	SELECT
		player_dismissed AS batter,
        COUNT(*) AS times_dismissed
	FROM deliveries_cleaned
    WHERE player_dismissed IS NOT NULL
		AND wicket_type <> 'retired hurt'
	GROUP BY player_dismissed
)

SELECT
	r.batter,
    r.total_runs,
    COALESCE(d.times_dismissed, 0) AS times_dismissed,
    ROUND(
		r.total_runs / NULLIF(d.times_dismissed, 0),
        2
	) AS batting_average
	
FROM batter_runs AS r
LEFT JOIN batter_dismissals AS d
	ON r.batter = d.batter
WHERE r.total_runs >= 100
	AND COALESCE(d.times_dismissed, 0) > 0
ORDER BY batting_average DESC
LIMIT 5;

-- Q30. Calculate the percentage of total tournament runs contributed by each team.
WITH team_runs  AS(
	SELECT 
		batting_team,
        SUM(runs_off_bat + extras) as total_runs
	FROM deliveries_cleaned
    GROUP BY batting_team
)
SELECT 	
	batting_team,
	total_runs,
    ROUND(
		total_runs * 100.0 / ( SELECT SUM(total_runs) FROM team_runs),
        2
	) AS run_contribution_percentage
FROM team_runs
ORDER BY run_contribution_percentage DESC;
		

-- Q31. Does winning the toss appear to improve a team's chance of winning the match? Compare both outcomes and calculate percentages.
SELECT
	CASE
		WHEN toss_winner = winner THEN 'Toss Winner Won Match'
        ELSE 'Toss Winner Lost Match'
	END AS match_outcome,
    COUNT(*) AS total_matches,
    ROUND(
		COUNT(*) * 100.0 / (SELECT COUNT(*) FROM matches_cleaned),
        2
	) AS percentage
FROM matches_cleaned
WHERE toss_winner IS NOT NULL 
	AND winner IS NOT NULL
GROUP BY match_outcome;



-- Q32. Which venues had the highest average first-innings scores?

SELECT 
	m.venue,
    ROUND(AVG(i.innings_runs), 2) AS avg_first_innings_score
FROM (
	SELECT
		match_id,
        SUM(runs_off_bat + extras) AS innings_runs
	FROM deliveries_cleaned
    WHERE innings = 1
    GROUP BY match_id
) AS i
JOIN matches_cleaned AS m
	ON i.match_id = m.match_number
GROUP BY m.venue
ORDER BY avg_first_innings_score DESC;

-- Q33. Which batters scored the most runs in the first semi-final?
SELECT 
	striker AS batter,
    SUM(runs_off_bat) AS total_runs
FROM deliveries_cleaned
WHERE match_id = (
	SELECT match_number
    FROM matches_cleaned
    WHERE team1 = "India"
	  AND team2 = "New Zealand"
      AND date = "2023-11-15"
)
GROUP BY striker
ORDER BY total_runs DESC
LIMIT 10;


-- Q34. Which bowlers took the most wickets in this semi-final?
SELECT
	bowler,
    COUNT(
		CASE 
			WHEN wicket_type IN(
				"bowled",
                "caught",
                "lbw",
                "stumped",
                "caught and bowled",
                "hit wicket"
			)
            THEN 1
		END
	) AS total_wickets
FROM deliveries_cleaned
WHERE match_id = (
	SELECT match_number
    FROM matches_cleaned
    WHERE date = "2023-11-16"
    AND(
		(team1 = "South Africa" AND team2 = "Australia")
        OR
        (team1 = "Australia" AND team2 = "South Africa")
    )
)
GROUP BY bowler
ORDER BY total_wickets DESC
LIMIT 10;

-- Q35. How many runs did each team score in the final, and which team scored more?
SELECT
    batting_team,
    SUM(runs_off_bat + extras) AS total_runs
FROM deliveries_cleaned
WHERE match_id = (
    SELECT match_number
    FROM matches_cleaned
    WHERE date = '2023-11-19'
      AND (
          (team1 = 'India' AND team2 = 'Australia')
          OR
          (team1 = 'Australia' AND team2 = 'India')
      )
)
GROUP BY batting_team
ORDER BY total_runs DESC;


-- Q36. Which team won the ICC Men's Cricket World Cup 2023 Final, and by what victory margin?
SELECT
    team1,
    team2,
    winner,
    win_type
FROM matches_cleaned
WHERE date = '2023-11-19'
  AND winner = 'Australia';
