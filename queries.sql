-- ================================================
-- PROJECT: IPL Sponsorship ROI Framework
-- AUTHOR:  Suhani Lalwani
-- PURPOSE: Data-driven investment guide for brand 
--          managers making IPL sponsorship decisions
-- ================================================

-- QUERY 1: Team consistency
-- Marketing question: Which team is the safest long-term sponsorship bet?

USE ipl_db;
SELECT season, winner,
  COUNT(*) AS matches_won
FROM matches
WHERE winner != 'NA'
  AND winner != ''
GROUP BY season, winner
ORDER BY season ASC, matches_won DESC;

-- ================================================
-- QUERY 2: Venue exposure
-- Marketing question: Where should a brand activate on-ground for maximum fan reach?

USE ipl_db;
SELECT venue, city,
  COUNT(*) AS total_matches,
  COUNT(DISTINCT season) AS seasons_active,
  COUNT(DISTINCT team1) AS unique_teams_hosted
FROM matches
GROUP BY venue, city
ORDER BY total_matches DESC
LIMIT 20;

-- ================================================
-- QUERY 3: Team win rate
-- Marketing question: Which team has the strongest performance equity for brand association transfer?

USE ipl_db;
SELECT team, total_matches, total_wins,
  ROUND(
    (CAST(total_wins AS DECIMAL(10,2)) / total_matches) * 100
  , 1) AS win_rate_pct
FROM (
  SELECT team1 AS team,
    COUNT(*) AS total_matches,
    SUM(CASE WHEN winner = team1 THEN 1 ELSE 0 END) AS total_wins
  FROM matches
  GROUP BY team1
) AS team_stats
ORDER BY win_rate_pct DESC;

-- ================================================
-- QUERY 4A: Top run scorers
-- Marketing question: Which players are the biggest campaign faces a brand can build content around?

USE ipl_db;
SELECT batter, SUM(batsman_runs) AS total_runs, COUNT(DISTINCT match_id) AS matches_played,
  ROUND(
    CAST(SUM(batsman_runs) AS DECIMAL(10,2)) / COUNT(DISTINCT match_id)
  , 1) AS avg_runs_per_match
FROM deliveries
GROUP BY batter
ORDER BY total_runs DESC
LIMIT 20;

-- ================================================
-- QUERY 4B: Man of the Match frequency
-- Marketing question: Which players generate the most premium broadcast moments for a jersey sponsor?

USE ipl_db;
SELECT player_of_match,
  COUNT(*) AS mom_awards,
  COUNT(DISTINCT season) AS seasons_won_in
FROM matches
WHERE player_of_match != 'NA'
  AND player_of_match != ''
GROUP BY player_of_match
ORDER BY mom_awards DESC
LIMIT 20;

-- ================================================
-- QUERY 5: Sponsor Value Score
-- Marketing question: Which team delivers the highest overall ROI across performance, exposure and star power?
-- Formula: 40% win rate + 35% matches played + 25% MOM awards
-- Weights reflect FMCG brand priority of broad reach over prestige, consistent performance over one-off wins
USE ipl_db;
SELECT m.team, m.total_matches, m.win_rate_pct,
  COALESCE(mom.total_mom, 0) AS star_power_score,
  ROUND(
    (m.win_rate_pct * 0.40) +
    (m.total_matches * 0.35) +
    (COALESCE(mom.total_mom, 0) * 0.25)
  , 1) AS sponsor_value_score
FROM (
  SELECT team1 AS team,
    COUNT(*) AS total_matches,
    ROUND(
      (CAST(SUM(CASE WHEN winner = team1 THEN 1 ELSE 0 END)
        AS DECIMAL(10,2)) / COUNT(*)) * 100
    , 1) AS win_rate_pct
  FROM matches
  GROUP BY team1
) AS m
LEFT JOIN (
  SELECT 
    team1 AS team,
    COUNT(*) AS total_mom
  FROM matches
  WHERE player_of_match != 'NA'
    AND player_of_match != ''
  GROUP BY team1
) AS mom ON m.team = mom.team
ORDER BY sponsor_value_score DESC;