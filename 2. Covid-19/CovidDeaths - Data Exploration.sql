-- set the project covid as deafult database
USE CovidProject;

-- getting an idea about the data, sorted by location and date
SELECT *
FROM CovidDeaths
ORDER BY location, date;



-- select only the relevant columns, ignoring the continents in the location column
SELECT
	continent,
	location,
	date,
	population,
	total_cases,
	new_cases,
	total_deaths,
	new_deaths
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;



-- Show the last update population by date of each location
SELECT
	location,
	population
FROM (
	SELECT
		location,
		population,
		ROW_NUMBER() OVER( PARTITION BY location ORDER BY date DESC) as row_no
	FROM CovidDeaths
	WHERE continent IS NOT NULL
	) AS x
WHERE x.row_no = 1;



-- investigate if there are locations with no values in population column
SELECT
	location,
	date,
	population
FROM CovidDeaths
WHERE continent IS NOT NULL AND population IS NULL;


--
SELECT
	location,
	date,
	population
FROM CovidDeaths
WHERE location = 'Northern Cyprus' AND population IS NOT NULL;


--see the total cases and total deaths by continent
SELECT
	location,
	FORMAT(date, 'dd-MM-yyyy') AS date,
	FORMAT(population, '#,#') AS population,
	FORMAT(total_cases, '#,#') AS total_cases,
	FORMAT(new_cases, '#,#') AS total_cases,
	FORMAT(CAST(total_deaths AS float), '#,#') AS total_deaths,
	FORMAT(CAST(new_deaths AS FLOAT), '#,#') AS new_deaths
FROM (
	SELECT
		*,
		ROW_NUMBER() OVER(PARTITION BY location ORDER BY date DESC) as row_no		
	FROM CovidDeaths
	WHERE continent IS NULL
	) AS x
WHERE row_no = 1;



-- total cases and deaths by location
SELECT
	continent,
	location,
	FORMAT(SUM(new_cases), '#,#') AS 'Total Cases',
	FORMAT(SUM(CAST(new_deaths AS INT)), '#,#') AS 'Total Death'
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location
ORDER BY 1,2;



-- Global stats 
SELECT
	FORMAT(SUM(population), '#,#') AS 'Global Population',
	FORMAT(SUM([Total Cases]), '#,#') AS 'Global Cases',
	FORMAT(SUM([Total Death]), '#,#') As 'Global Deaths'
FROM (
	SELECT
		continent,
		location,
		MAX(population) AS population,		-- not a good idea to use max here... 
		SUM(new_cases) AS 'Total Cases',
		SUM(CAST(new_deaths AS INT)) AS 'Total Death'
	FROM CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY continent, location
	) AS x;



-- Number of countries
SELECT
	COUNT(DISTINCT location) AS Number_of_Countries
FROM CovidDeaths
WHERE continent is not null;



-- Show the details of 'Australia' on date: 7.10.2021
SELECT *
FROM CovidVaccinations
WHERE location = 'Australia'
	AND DATEPART(yy, date) = 2021 AND DATEPART(mm, date) = 10 AND DATEPART(dd, date) = 7;


