USE CovidProject;

-- convert the datetime column into date column only
SELECT
	date old_date_format,
	CONVERT(date, date) AS new_date_format
FROM CovidDeaths;

-- method 1
UPDATE CovidDeaths
SET date = CONVERT(date, date);

-- method 2
ALTER TABLE CovidDeaths
ALTER COLUMN date date;    --column_name date_type
