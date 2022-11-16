USE CovidProject;

SELECT *
FROM CovidVaccinations;

CREATE OR ALTER VIEW vaccinations AS (
	SELECT
		cv.continent,
		cv.location,
		cv.date,
		population,
		new_vaccinations,
		total_vaccinations,
		people_fully_vaccinated
	FROM CovidVaccinations cv
	JOIN CovidDeaths cd
		ON cv.iso_code = cd.iso_code
			AND cv.location = cd.location
			AND cv.continent = cd.continent
			AND cv.date = cd.date);


-- people fully vaccinated per day
SELECT
	continent,
	location,
	CONVERT(date, date) as date,
	people_fully_vaccinated,
	CAST(people_fully_vaccinated AS BIGINT) - LAG(people_fully_vaccinated, 1, 0) OVER(PARTITION BY location ORDER BY date) AS pfv_per_day
FROM CovidVaccinations
WHERE continent IS NOT NULL
	AND people_fully_vaccinated IS NOT NULL
ORDER BY continent, location, date;
	

-- total people fully vaccinated by continent
SELECT
	continent,
	FORMAT(SUM(pfv_per_day), '#,#') AS 'Total pfv_per_day'
FROM (
	SELECT
		continent,
		location,
		CONVERT(date, date) as date,
		people_fully_vaccinated,
		CAST(people_fully_vaccinated AS BIGINT) - LAG(people_fully_vaccinated, 1, 0) OVER(PARTITION BY location ORDER BY date) AS pfv_per_day
	FROM CovidVaccinations
	WHERE continent IS NOT NULL
		AND people_fully_vaccinated IS NOT NULL
	) AS x
GROUP BY continent;


-- vaccinations stats order by continent and location
SELECT
	continent,
	location,
	CONVERT(date, date) AS date,
	population,
	new_vaccinations,
	total_vaccinations,
	people_fully_vaccinated
FROM (
	SELECT
		*,
		ROW_NUMBER() OVER(PARTITION BY location ORDER BY date DESC) as row_no
	FROM vaccinations
	WHERE continent IS NOT NULL
		AND people_fully_vaccinated IS NOT NULL
	) AS x
WHERE row_no = 1
ORDER BY continent, location;



-- total people fully vaccinated
SELECT
	FORMAT(SUM(CAST(people_fully_vaccinated AS float)), '#,#') AS 'Total people_fully_vaccinated'
FROM (
	SELECT
		*,
		ROW_NUMBER() OVER(PARTITION BY location ORDER BY date DESC) as row_no
	FROM vaccinations
	WHERE continent IS NOT NULL
		AND people_fully_vaccinated IS NOT NULL
	) AS x
WHERE row_no = 1;



-- check the data to see if something went wrong
SELECT
	continent,
	location,
	CONVERT(date, date) AS date,
	FORMAT(population, '#,#') AS population,
	FORMAT(CAST(people_fully_vaccinated AS BIGINT), '#,#') AS people_fully_vaccinated
FROM (
	SELECT
		*,
		ROW_NUMBER() OVER(PARTITION BY location ORDER BY date DESC) as row_no
	FROM vaccinations
	WHERE continent IS NOT NULL
		AND people_fully_vaccinated IS NOT NULL
	) AS x
WHERE row_no = 1
ORDER BY CAST(people_fully_vaccinated AS BIGINT) DESC;



-- population of each location
SELECT
	continent,
	location,
	population
FROM (
	SELECT
		continent,
		location,
		date,
		population,
		ROW_NUMBER() OVER(PARTITION BY location ORDER BY date DESC) AS rn
	FROM CovidDeaths
	WHERE continent IS NOT NULL
	) AS X
WHERE x.rn = 1;



-- population by continent
SELECT
	continent,
	FORMAT(SUM(population), '#,#') AS population
FROM (
	SELECT
		continent,
		location,
		date,
		population,
		ROW_NUMBER() OVER(PARTITION BY location ORDER BY date DESC) AS rn
	FROM CovidDeaths
	WHERE continent IS NOT NULL
	) AS X
WHERE x.rn = 1
GROUP BY continent;




-- see the procentage of cases and procentage of deaths by continent
SELECT
	continent,
	FORMAT(population, '#,#') AS population,
	FORMAT(total_cases, '#,#') AS total_cases,
	CAST(total_cases / population * 100 AS decimal(3,2)) AS ratio_infection,
	FORMAT(CAST(total_deaths AS float), '#,#') AS total_deaths,
	FORMAT(total_deaths / total_cases * 100, 'N2') AS ratio_death,
	--FORMAT(total_deaths / population * 100, 'N3') AS ratio_death_by_population
FROM (
	SELECT
		continent,
		SUM(population) AS population,
		SUM(total_cases) AS total_cases,
		SUM(CAST(total_deaths AS FLOAT)) AS total_deaths
	FROM (
		SELECT
			continent,
			location,
			date,
			population,
			total_cases,
			total_deaths,
			ROW_NUMBER() OVER(PARTITION BY continent, location ORDER BY date DESC) AS row_no
		FROM CovidDeaths
		WHERE continent IS NOT NULL
		) AS x
	WHERE row_no = 1
	GROUP BY continent
	) AS temp;
