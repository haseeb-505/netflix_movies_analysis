-- Netflix Project

DROP TABLE IF EXISTS netflix_movies_data;
CREATE TABLE netflix_movies_data(
	show_id	VARCHAR(10),
	type	VARCHAR(25),
	title	VARCHAR(150),
	director	VARCHAR(250),
	film_cast	VARCHAR(1000),
	country		VARCHAR(150),
	date_added	VARCHAR(50),
	release_year	INT,
	rating		VARCHAR(10),
	duration	VARCHAR(50),
	listed_in	VARCHAR(150),
	description	VARCHAR(250)

);

SELECT * FROM netflix_movies_data;

-- 15 Business Problems & Solutions


-- 1. Count the number of Movies vs TV Shows
SELECT COUNT(DISTINCT title) FROM netflix_movies_data;

-- 2. Find the most common rating for movies and TV shows
SELECT rating, COUNT(rating) AS total_ratings 
FROM netflix_movies_data
GROUP BY rating
ORDER BY total_ratings  DESC
-- LIMIT 1 -- for most common rating
;
-- 3. List all movies released in a specific year (e.g., 2020)
SELECT title, release_year 
FROM netflix_movies_data 
WHERE release_year = 2020
	AND
	type = 'Movie' -- to select the only movies released in that certain year
;

-- 4. Find the top 5 countries with the most content on Netflix
SELECT country, COUNT(country) AS total_movies_country 
FROM netflix_movies_data 
GROUP BY country
ORDER BY total_movies_country DESC
LIMIT 5 -- for top 5 results
;

-- 5. Identify the longest movie
SELECT title, type, duration, 
	CAST(LEFT(duration, POSITION(' min' IN duration) -1) AS INTEGER) AS length_in_mins
FROM netflix_movies_data
WHERE type = 'Movie' 
	AND 
	duration IS NOT NULL -- some records have duration as null field
ORDER BY length_in_mins DESC
;

-- 6. Find content added in the last 5 years

SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'netflix_movies_data';

-- to check if any record is not following the standard date format
SELECT date_added FROM netflix_movies_data
WHERE date_added !~ '^\d{4}-\d{2}-\d{2}$';


SELECT date_added FROM netflix_movies_data
WHERE TRIM(date_added) ~ '^[A-Za-z]+ \d{2}, \d{4}$';

-- first normalizing the date to Sep 01, 2001
-- even if this was September, following code will first convert 
-- this to Sep
UPDATE netflix_movies_data
SET date_added = TO_CHAR(TO_DATE(TRIM(date_added), 'FMMonth DD, YYYY'), 'YYYY-MM-DD')
WHERE TRIM(date_added) ~ '^[A-Za-z]+ \s?\d{1,2}, \d{4}$';

SELECT date_added FROM netflix_movies_data
WHERE date_added !~ '^\d{4}-\d{2}-\d{2}$';

-- again check for data type
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'netflix_movies_data';

-- change date_added to date type
ALTER TABLE netflix_movies_data
ALTER COLUMN date_added TYPE DATE
USING date_added::DATE
;

-- Now getting the content added in last 6 years

SELECT title, date_added
FROM netflix_movies_data
WHERE date_added >= (CURRENT_DATE - INTERVAL '6 year')
ORDER BY date_added ASC
;


-- 7. Find all the movies/TV shows by director 'Rajiv Chilaka'!
SELECT title, director
FROM netflix_movies_data
WHERE director LIKE 'Rajiv Chilaka'
;
-- above query selects only those records where director is Rajiv Chilaka

SELECT title, director
FROM netflix_movies_data
WHERE director LIKE '%Rajiv Chilaka%'
-- to extract all the records which have Rajiv Chilaka as director
-- along with others as well
;

-- 8. List all TV shows with more than 5 seasons
SELECT title, type, number_of_seasons
FROM (
	SELECT title, type, duration,
	CAST(LEFT(duration, POSITION(' Season' IN duration) -1) AS INTEGER) AS number_of_seasons
	FROM netflix_movies_data
	WHERE type = 'TV Show'
	ORDER BY number_of_seasons DESC
)
WHERE number_of_seasons >= 5
;

-- 9. Count the number of content items in each genre
WITH genre_table AS(
	SELECT unnest(string_to_array(listed_in, ', ')) AS genre
	FROM netflix_movies_data
)
SELECT genre, COUNT(genre) AS number_of_movies_genre
FROM genre_table
GROUP BY genre
ORDER BY number_of_movies_genre DESC
;

-- 10.Find each year and the average numbers of content release in India on netflix.
-- return top 5 year with highest avg content release!
SELECT DISTINCT release_year, 
	COUNT(show_id) OVER(PARTITION BY release_year) AS avg_release_in_year
FROM netflix_movies_data
WHERE country = 'India'
ORDER BY release_year DESC
;

-- 11. List all movies that are documentaries
SELECT title, listed_in
FROM netflix_movies_data
WHERE 
	listed_in LIKE '%Documentaries%'
	OR
	listed_in LIKE '%documentaries%'
;

-- 12. Find all content without a director
SELECT *
FROM netflix_movies_data
WHERE director is NULL
;
-- 13. Find how many movies actor 'Salman Khan' appeared in last 10 years!
SELECT COUNT(show_id)
FROM netflix_movies_data
WHERE 
	film_cast LIKE '%Salman Khan%' 
	AND 
	release_year >= EXTRACT(YEAR FROM CURRENT_DATE - INTERVAL '10 years')
;
-- 14. Find the top 10 actors who have appeared in the highest number of movies produced in India.
WITH actor_count AS(
	SELECT unnest(string_to_array(film_cast, ', ')) AS actor
	FROM netflix_movies_data
	WHERE country='India'
),
	actor_ranking AS(
		SELECT actor,
		COUNT(actor) AS total_appearances,
		DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS actor_dense_rank
		FROM actor_count
		GROUP BY actor
		ORDER BY actor_dense_rank
)
SELECT actor, total_appearances, actor_dense_rank
FROM actor_ranking
WHERE actor_dense_rank <= 10
;

-- LIMIT 10 -- using limit will cause to select first 10 results
-- but it might stop at dense rank 5 or 6 or 7
-- So we use where caluse as ued above
-- as we can't directly use where clause here on actor_dense_rank
-- that's why we designed another common table expression

;
-- 15.
-- Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
-- the description field. Label content containing these keywords as 'Bad' and all other 
-- content as 'Good'. Count how many items fall into each category.

WITH labeling_movies AS(
	SELECT title, description,
		CASE 
			WHEN description LIKE '%kill%' 
				OR 
				description LIKE '%violence%' THEN 'Bad'
			ELSE 'Good'
		END AS movie_content
	FROM netflix_movies_data
)
SELECT movie_content,
	COUNT(movie_content)
FROM labeling_movies
GROUP BY movie_content
;








