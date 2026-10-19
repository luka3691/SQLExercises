
drop table imdb;
select * from imdb;
CREATE OR REPLACE PROCEDURE FormatIMDBData IS
BEGIN
    -- Handle Gross column: Remove commas and convert to a number
    BEGIN
        UPDATE imdb
        SET Gross = TO_NUMBER(REPLACE(Gross, ',', ''))
        WHERE REGEXP_LIKE(Gross, '^[0-9,]+$');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error formatting Gross column.');
    END;

    -- Handle No_of_Votes column: Remove commas and convert to a number
    BEGIN
        UPDATE imdb
        SET No_of_Votes = TO_NUMBER(REPLACE(No_of_Votes, ',', ''))
        WHERE REGEXP_LIKE(No_of_Votes, '^[0-9,]+$');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error formatting No_of_Votes column.');
    END;

    -- Handle Meta_score column: Convert to an integer
    BEGIN
        UPDATE imdb
        SET Meta_score = TO_NUMBER(Meta_score)
        WHERE REGEXP_LIKE(Meta_score, '^[0-9]+$');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error formatting Meta_score column.');
    END;

    -- Handle IMDB_Rating column: Ensure it's a decimal
    BEGIN
        UPDATE imdb
        SET IMDB_Rating = TO_NUMBER(IMDB_Rating)
        WHERE REGEXP_LIKE(IMDB_Rating, '^[0-9]+(\.[0-9]+)?$');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error formatting IMDB_Rating column.');
    END;

    -- Handle Released_Year column: Convert to an integer
    BEGIN
        UPDATE imdb
        SET Released_Year = TO_NUMBER(Released_Year)
        WHERE REGEXP_LIKE(Released_Year, '^[0-9]+$');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error formatting Released_Year column.');
    END;

    -- Handle Runtime column: Remove "min" and convert to an integer
    BEGIN
        UPDATE imdb
        SET Runtime = TO_NUMBER(REPLACE(Runtime, ' min', ''))
        WHERE Runtime LIKE '% min';
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error formatting Runtime column.');
    END;

    -- Commit all changes
    COMMIT;
END;
/
BEGIN
   FormatIMDBData;
END;
/
-- Alter Gross to NUMBER(15,2)
ALTER TABLE imdb MODIFY Gross NUMBER(15,2);

-- Alter No_of_Votes to NUMBER(10)
ALTER TABLE imdb MODIFY No_of_Votes NUMBER(10);

-- Alter Meta_score to NUMBER(3)
ALTER TABLE imdb MODIFY Meta_score NUMBER(3);

-- Alter IMDB_Rating to NUMBER(3,1)
ALTER TABLE imdb MODIFY IMDB_Rating NUMBER(3,1);

-- Alter Released_Year to NUMBER(4)
ALTER TABLE imdb MODIFY Released_Year NUMBER(4);

-- Alter Runtime to NUMBER(5)
ALTER TABLE imdb MODIFY Runtime NUMBER(5);

-- Backup the data into a temporary table
CREATE TABLE imdb_backup AS SELECT * FROM imdb;

-- Drop the original table
DROP TABLE imdb;

-- Recreate the table with the correct datatypes
CREATE TABLE imdb (
    Series_Title VARCHAR2(255),
    Released_Year NUMBER(4),
    Certificate VARCHAR2(10),
    Runtime NUMBER(5),
    Genre VARCHAR2(255),
    IMDB_Rating NUMBER(3,1),
    Meta_score NUMBER(3),
    Director VARCHAR2(255),
    Star1 VARCHAR2(255),
    Star2 VARCHAR2(255),
    Star3 VARCHAR2(255),
    Star4 VARCHAR2(255),
    No_of_Votes NUMBER(10),
    Gross NUMBER(15)
);
--napravenie chyby v datach
UPDATE imdb_backup
        SET Released_Year = '1995'
        WHERE Series_Title = 'Apollo 13';
    
CREATE OR REPLACE PROCEDURE insert_into_imdb_from_temp AS
BEGIN
    FOR temp_row IN (SELECT * FROM imdb_backup) LOOP
        BEGIN
            -- Attempt to insert the row into the imdb table
            INSERT INTO imdb (
                Series_Title,
                Released_Year,
                Certificate,
                Runtime,
                Genre,
                IMDB_Rating,
                Meta_score,
                Director,
                Star1,
                Star2,
                Star3,
                Star4,
                No_of_Votes,
                Gross
            )
            VALUES (
                temp_row.Series_Title,
                TO_NUMBER(temp_row.Released_Year DEFAULT NULL ON CONVERSION ERROR),
                temp_row.Certificate,
                TO_NUMBER(REPLACE(temp_row.Runtime, ' min', '') DEFAULT NULL ON CONVERSION ERROR),
                temp_row.Genre,
                CASE WHEN REGEXP_LIKE(temp_row.IMDB_Rating, '^\d+(\.\d+)?$') THEN TO_NUMBER(temp_row.IMDB_Rating, '9999.9') ELSE NULL END,
                TO_NUMBER(temp_row.Meta_score DEFAULT NULL ON CONVERSION ERROR),
                temp_row.Director,
                temp_row.Star1,
                temp_row.Star2,
                temp_row.Star3,
                temp_row.Star4,
                TO_NUMBER(REPLACE(temp_row.No_of_Votes, ',', '') DEFAULT NULL ON CONVERSION ERROR),
                TO_NUMBER(REPLACE(temp_row.Gross, ',', '') DEFAULT NULL ON CONVERSION ERROR)
            );
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    END LOOP;
END insert_into_imdb_from_temp;
/
EXEC insert_into_imdb_from_temp;

drop table imdb;

--1. Vytvorenie dátovej štruktúry a naplnenie tabuliek obsahom (generované dáta, resp. ideálne reálne)
--2. Vykonanie analytického spracovania dát - podmienka - použitie kombinácie agregaènej a analytickej funkcie. 
--3. Reprezentácia a prezentácia výsledkov
select released_year, series_title from imdb where gross > 10000000 order by released_year;

WITH Director_Years AS (
    SELECT
        Director,
        Released_Year,
        LAG(Released_Year) OVER (PARTITION BY Director ORDER BY Released_Year) AS Prev_Year
    FROM
        imdb
)
, Year_Groups AS (
    SELECT
        Director,
        Released_Year,
        CASE
            WHEN Released_Year - NVL(Prev_Year, Released_Year) > 1 THEN 1
            ELSE 0
        END AS Is_New_Sequence
    FROM
        Director_Years
)
SELECT
    Director,
    COUNT(Released_Year) AS Consecutive_Years
FROM (
    SELECT
        Director, Released_Year,
        SUM(Is_New_Sequence) OVER (PARTITION BY Director ORDER BY Released_Year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Sequence_Group
    FROM
        Year_Groups
)
GROUP BY
    Director, Sequence_Group
ORDER BY
    Consecutive_Years DESC;

select released_year, round(avg(runtime/gross)) from imdb group by released_year order by released_year;

  
select * from imdb where director = 'Billy Wilder' order by released_year;
SELECT
    Actor,
    LISTAGG(Series_Title, ', ') WITHIN GROUP (ORDER BY Series_Title) AS Movies,
    count(Series_Title) as Times_starred,
    RANK() OVER (ORDER BY COUNT(Series_Title) DESC) AS Rank_By_Movies
FROM (
    SELECT Star1 AS Actor, Series_Title, released_year FROM imdb
    UNION ALL
    SELECT Star2 AS Actor, Series_Title, released_year FROM imdb
    UNION ALL
    SELECT Star3 AS Actor, Series_Title, released_year FROM imdb
    UNION ALL
    SELECT Star4 AS Actor, Series_Title, released_year FROM imdb
)
WHERE Actor IS NOT NULL
GROUP BY Actor
ORDER BY Times_starred desc;

select actor,
    count(Series_Title) as Times_starred,
    round(Avg_Release_Year),
    First_Movie_Year,
    Latest_Movie_Year,
    Latest_Movie_Year - First_Movie_Year as years_on_screen,
    LISTAGG(Series_Title, ', ') WITHIN GROUP (ORDER BY Series_Title) AS Movies from (
SELECT
    Actor,
    AVG(released_year) OVER (PARTITION BY Actor) AS Avg_Release_Year,
    MIN(released_year) OVER (PARTITION BY Actor) AS First_Movie_Year,
    MAX(released_year) OVER (PARTITION BY Actor) AS Latest_Movie_Year, 
    Series_Title
FROM (
    SELECT Star1 AS Actor, Series_Title, Released_Year FROM imdb
    UNION ALL
    SELECT Star2 AS Actor, Series_Title, Released_Year FROM imdb
    UNION ALL
    SELECT Star3 AS Actor, Series_Title, Released_Year FROM imdb
    UNION ALL
    SELECT Star4 AS Actor, Series_Title, Released_Year FROM imdb
)
WHERE Actor IS NOT NULL)
group by actor, Avg_Release_Year,
    First_Movie_Year,
    Latest_Movie_Year
    order by Times_starred desc
;
select distinct certificate from imdb;

select * from imdb;
WITH Director_Years AS (
    SELECT
        Director,
        Released_Year,
        LAG(Released_Year) OVER (PARTITION BY Director ORDER BY Released_Year) AS Prev_Year
    FROM
        imdb
)
, Year_Groups AS (
    SELECT
        Director,
        Released_Year,
        SUM(CASE 
                WHEN Released_Year - NVL(Prev_Year, Released_Year) > 1 THEN 1
                ELSE 0
            END) OVER (PARTITION BY Director ORDER BY Released_Year) AS Sequence_Group
    FROM
        Director_Years
)
SELECT
    Director,
    COUNT(*) AS Consecutive_Years
FROM
    Year_Groups
GROUP BY
    Director, Sequence_Group;
    SELECT
        Director,
        Released_Year,
        SUM(CASE 
                WHEN Released_Year - NVL(Prev_Year, Released_Year) > 1 THEN 1
                ELSE 0
            END) OVER (PARTITION BY Director ORDER BY Released_Year)
    FROM
        (
    SELECT
        Director,
        Released_Year,
        LAG(Released_Year) OVER (PARTITION BY Director ORDER BY Released_Year) AS Prev_Year
    FROM
        imdb);
        
select * from imdb_backup;

WITH Comparison AS (
    SELECT
        Released_Year,
        Series_Title,
        CASE
            WHEN Meta_Score > IMDB_Rating*10 THEN 'Meta Higher'
            WHEN Meta_Score < IMDB_Rating*10 THEN 'IMDB Higher'
            ELSE 'Equal'
        END AS Comparison_Result,
        Gross
    FROM
        imdb
    WHERE
        Meta_Score IS NOT NULL
        AND IMDB_Rating IS NOT NULL
        AND Gross IS NOT NULL
),
Yearly_Stats AS (
    SELECT
        Released_Year,
        Comparison_Result,
        COUNT(*) AS Movie_Count,
        ROUND(SUM(Gross) / NULLIF(SUM(SUM(Gross)) OVER (PARTITION BY Released_Year), 0) * 100, 2) AS Percentage_Gross
    FROM
        Comparison
    GROUP BY
        Released_Year, Comparison_Result
)
SELECT
    Released_Year,
    Comparison_Result,
    Movie_Count,
    Percentage_Gross
FROM
    Yearly_Stats
ORDER BY
    Released_Year, Percentage_Gross DESC;
    
WITH Comparison AS (
    SELECT Released_Year,
        CASE
            WHEN Meta_Score > IMDB_Rating*10 THEN 'Meta Higher'
            WHEN Meta_Score < IMDB_Rating*10 THEN 'IMDB Higher'
            ELSE 'Equal'
        END AS Comparison_Result,
        Gross
    FROM imdb
        WHERE Meta_Score IS NOT NULL AND IMDB_Rating IS NOT NULL
),
Yearly_Stats AS (
    SELECT Released_Year, Comparison_Result, COUNT(*) AS Movie_Count,
        ROUND(SUM(Gross) / NULLIF(SUM(SUM(Gross)) OVER (PARTITION BY Released_Year), 0) * 100, 2) AS Percentage_Gross
    FROM Comparison
        GROUP BY Released_Year, Comparison_Result
),
Ranked_Stats AS (
    SELECT Released_Year, Comparison_Result, Movie_Count,
        ROW_NUMBER() OVER (PARTITION BY Released_Year ORDER BY Movie_Count DESC) AS Rank, Percentage_Gross
    FROM Yearly_Stats
)
SELECT Released_Year, Comparison_Result, Movie_Count, Percentage_Gross
    FROM Ranked_Stats
        WHERE Rank = 1
        ORDER BY Released_Year;