-- =====================================================================
--  Netflix Data Analysis & Insights Analytics - SQL Project
-- =====================================================================

-- ============================================================
-- Project: Netflix Data Analysis & Insights
-- Database Engine: MySQL
-- Author: Riya Pareek
-- Table Used: netflixutf
-- ============================================================

-- ==============================================================================================
-- DATABASE SETUP
-- ==============================================================================================

create database netflix_db;
USE netflix_db;

-- ===========================================================================
--  Project Overview
-- ===========================================================================
--    Netflix Data Analysis & Insights is a SQL-based data analytics project designed to analyze and evaluate key
--    content trends and patterns across the Netflix platform.
-- --------------------------------------------------------------

--    The project uses a comprehensive Netflix dataset covering movies, TV shows, directors, cast, countries,
--    ratings, genres, release years, durations, and content descriptions. SQL is used to explore content
--    distribution, rating patterns, country-wise production, genre trends, director and actor contributions,
--    release-year trends, and movie duration.
-- ----------------------------------------------

--    The primary objective of this project is to demonstrate how SQL can be used to transform raw Netflix
--    content data into meaningful insights that support data-driven analysis and better understanding of
--    content trends and distribution.
-- --------------------------------------

-- Key Areas of Analysis
--  1. Content Type Analysis
--  2. Rating Analysis
--  3. Country-wise Content Analysis
--  4. Director & Actor Analysis
--  5. Genre Analysis
--  6. Release Year & Content Trends
--  7. Movie Duration Analysis
--  8. Content Distribution & Performance Insights


/* =============================================================
        SECTION 1: DATA EXPLORATION & CHECKS
 =============================================================*/

-- 1. Total records count
SELECT COUNT(*) AS total_rows FROM netflixutf;

-- 2. Check distinct content types (Movies vs TV Shows)
SELECT DISTINCT type FROM netflixutf;

-- 3. Check data completeness (Null values check)
SELECT 
    COUNT(*) AS total_records,
    SUM(CASE WHEN director IS NULL OR director = '' THEN 1 ELSE 0 END) AS missing_directors,
    SUM(CASE WHEN country IS NULL OR country = '' THEN 1 ELSE 0 END) AS missing_countries,
    SUM(CASE WHEN rating IS NULL OR rating = '' THEN 1 ELSE 0 END) AS missing_ratings
FROM netflixutf;


-- =============================================================
--      SECTION 2: BUSINESS PROBLEMS & DATA ANALYSIS
-- =============================================================
-- =============================================================
--      Basic Level (1 - 5)
-- =============================================================
-- Task 1: Count the number of Movies vs TV Shows
SELECT 
    type, 
    COUNT(*) AS total_content
FROM netflixutf
GROUP BY type;


-- Task 2: Find the most common rating for Movies and TV Shows
WITH RatingRankings AS (
    SELECT 
        type, 
        rating, 
        COUNT(*) AS count,
        RANK() OVER (PARTITION BY type ORDER BY COUNT(*) DESC) AS ranking
    FROM netflixutf
    WHERE rating IS NOT NULL AND rating != ''
    GROUP BY type, rating
)
SELECT type, rating, count AS total_titles
FROM RatingRankings
WHERE ranking = 1;


-- Task 3: List all Movies released in a specific year (e.g., 2021)
SELECT show_id, title, release_year 
FROM netflixutf
WHERE type = 'Movie' AND release_year = 2021;


-- Task 4: Find the top 5 countries with the most content on Netflix
SELECT 
    country, 
    COUNT(*) AS total_content
FROM netflixutf
WHERE country IS NOT NULL AND country != ''
GROUP BY country
ORDER BY total_content DESC
LIMIT 5;


-- Task 5: Identify the longest Movie duration
SELECT title, duration 
FROM netflixutf
WHERE type = 'Movie' AND duration IS NOT NULL
ORDER BY CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) DESC
LIMIT 1;

-- =============================================================
--       Intermediate Level (6 - 13)
-- =============================================================


-- Task 6: Find all content added in the last 5 years
SELECT title, type, release_year 
FROM netflixutf
WHERE release_year >= (YEAR(CURDATE()) - 5);


-- Task 7: Find all Movies/TV Shows by Director 'Kirsten Johnson'
SELECT type, title, release_year 
FROM netflixutf
WHERE director LIKE '%Kirsten Johnson%';


-- Task 8: List all TV Shows with more than 2 Seasons
SELECT title, duration 
FROM netflixutf
WHERE type = 'TV Show' 
  AND CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) > 2;


-- Task 9: Categorize Content Based on Keywords in Description
SELECT 
    CASE 
        WHEN LOWER(description) LIKE '%kill%' OR LOWER(description) LIKE '%violence%' THEN 'Bad/Adult Content'
        ELSE 'Family Friendly'
    END AS category,
    COUNT(*) AS content_count
FROM netflixutf
GROUP BY category;

-- Task 10: Find directors who have directed both Movies and TV Shows
SELECT director
FROM netflixutf
WHERE director IS NOT NULL AND director != ''
GROUP BY director
HAVING COUNT(DISTINCT type) = 2;


-- Task 11: List all Movies that are Documentaries
SELECT title, release_year, duration
FROM netflixutf
WHERE type = 'Movie' 
  AND listed_in LIKE '%Documentaries%';


-- Task 12: Count the total number of items released each year after 2015
SELECT release_year, COUNT(*) AS total_releases
FROM netflixutf
WHERE release_year > 2015
GROUP BY release_year
ORDER BY release_year DESC;


-- Task 13: Find top 3 genres (listed_in) with the highest number of titles
SELECT 
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(listed_in, ',', n.digit), ',', -1)) AS genre,
    COUNT(*) AS total_count
FROM netflixutf
JOIN (
    SELECT 1 AS digit UNION ALL SELECT 2 UNION ALL SELECT 3
) n ON LENGTH(listed_in) - LENGTH(REPLACE(listed_in, ',', '')) >= n.digit - 1
WHERE listed_in IS NOT NULL AND listed_in != ''
GROUP BY genre
ORDER BY total_count DESC
LIMIT 3;

-- =============================================================
--    Advanced Level (14 - 20)
-- =============================================================

-- Task 14: Calculate running total of content added over release years
SELECT 
    release_year,
    COUNT(*) AS yearly_count,
    SUM(COUNT(*)) OVER (ORDER BY release_year) AS running_total
FROM netflixutf
WHERE release_year IS NOT NULL
GROUP BY release_year
ORDER BY release_year;


-- Task 15: Find the actor who has appeared in the most content
SELECT 
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(cast, ',', n.digit), ',', -1)) AS actor_name,
    COUNT(*) AS total_appearances
FROM netflixutf
JOIN (
    SELECT 1 AS digit UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
) n ON LENGTH(cast) - LENGTH(REPLACE(cast, ',', '')) >= n.digit - 1
WHERE cast IS NOT NULL AND cast != ''
GROUP BY actor_name
ORDER BY total_appearances DESC
LIMIT 1;


-- Task 16: Rank movies within each release year based on duration
WITH MovieDurations AS (
    SELECT 
        title,
        release_year,
        CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) AS duration_minutes
    FROM netflixutf
    WHERE type = 'Movie' AND duration IS NOT NULL
)
SELECT 
    title,
    release_year,
    duration_minutes,
    DENSE_RANK() OVER (PARTITION BY release_year ORDER BY duration_minutes DESC) AS duration_rank
FROM MovieDurations;


-- Task 17: Find percentage of Movies vs TV Shows
SELECT 
    type,
    COUNT(*) AS count,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM netflixutf)), 2) AS percentage
FROM netflixutf
GROUP BY type;


-- Task 18: Identify multi-country co-productions vs single country content
SELECT 
    CASE 
        WHEN country LIKE '%,%' THEN 'Multi-Country Co-production'
        WHEN country IS NULL OR country = '' THEN 'Unknown'
        ELSE 'Single Country'
    END AS production_type,
    COUNT(*) AS total_titles
FROM netflixutf
GROUP BY production_type;


-- Task 19: Find average movie duration for each rating category
SELECT 
    rating,
    ROUND(AVG(CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED)), 2) AS avg_duration_mins
FROM netflixutf
WHERE type = 'Movie' 
  AND rating IS NOT NULL AND rating != ''
  AND duration LIKE '%min%'
GROUP BY rating
ORDER BY avg_duration_mins DESC;


-- Task 20: Categorize movie duration (Short, Medium, Long)
SELECT 
    CASE 
        WHEN CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) < 60 THEN 'Short (< 60 mins)'
        WHEN CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) BETWEEN 60 AND 120 THEN 'Medium (60-120 mins)'
        ELSE 'Long (> 120 mins)'
    END AS movie_length_category,
    COUNT(*) AS movie_count
FROM netflixutf
WHERE type = 'Movie' AND duration IS NOT NULL
GROUP BY movie_length_category;


-- ===========================================================================
-- Project Insights
-- ===========================================================================

/*    1. The analysis provides a clear comparison between Movies and TV Shows,
        helping understand the overall content distribution on Netflix.
------------------------------------------------------------------------

    2. Rating analysis identifies the most frequently occurring content ratings
       across Movies and TV Shows.
------------------------------------

    3. Country-wise analysis highlights the countries contributing the highest
       number of Netflix titles.
----------------------------------

    4. Release-year analysis helps identify content growth and distribution
       trends across different years.
---------------------------------------

    5. Genre analysis identifies the most frequently occurring content categories
       and provides an overview of Netflix's content preferences.
-------------------------------------------------------------------

    6. Director and actor analysis helps identify individuals associated with
       multiple Movies and TV Shows in the dataset.
-----------------------------------------------------

    7. Movie duration analysis provides insights into short, medium, and long
       movies and compares average duration across different rating categories.
---------------------------------------------------------------------------------

    8. The analysis identifies directors who have worked across both Movies and
       TV Shows, showing their contribution across different content types.
-----------------------------------------------------------------------------

    9. Multi-country production analysis distinguishes between single-country,
       multi-country, and unknown production information.
-----------------------------------------------------------

   10. Advanced SQL analysis using CTEs, subqueries, ranking functions, and
      window functions provides deeper insights into content trends and
      year-wise rankings. */


-- ===========================================================================
-- Project Conclusion
-- ===========================================================================

/*    This project demonstrates how SQL can be effectively used to analyze and understand
         Netflix content data and identify meaningful patterns across Movies and TV Shows.
---------------------------------------------------------------------------------------

    The analysis provides insights into content distribution, ratings, countries, genres,
    directors, actors, release years, and movie durations. It also demonstrates the use
    of advanced SQL techniques such as CTEs, subqueries, CASE statements, ranking functions,
    and window functions to perform detailed data analysis.
-------------------------------------------------------------

    Overall, the project highlights how structured SQL analysis can transform raw content
    data into meaningful insights and support data-driven understanding of Netflix's
    content catalog and its major trends.
    
    
=========================================================================================================================
        END OF Netflix Data Analysis & Insights Analytics - SQL Project 
=========================================================================================================================*/

















    
