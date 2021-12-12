USE [Sales Sample Data];

-- Take a look 
SELECT TOP(10)
	*
FROM Sales;


-- Total Number of Orders 
SELECT
	COUNT(DISTINCT ordernumber) AS 'Number of Orders'
FROM Sales;


-- Cleaning the orderdate column. We have here a nvarchar type for this column, let's change it to an appropriate date form.
SELECT
	orderdate,
	CAST(orderdate AS date) AS DateOrder
FROM Sales;

-- Applying the changes to the orderdate
UPDATE Sales
SET orderdate = CONVERT(date, orderdate);


SELECT
	orderdate,
	--CONCAT( YEAR(orderdate), ' ', DATENAME(month, orderdate) ) AS YM,
	FORMAT(CONVERT(date, orderdate), 'yyyy-MMM') AS YM
FROM Sales;


SELECT DISTINCT
	ordernumber,
	FORMAT(CONVERT(date, orderdate), 'yyyy-MMM') AS YM
FROM Sales
WHERE ordernumber IN (10107, 10121)
ORDER BY 1;


-- We got here the number of orders by year and month, sorted ascending by date.
SELECT
	FORMAT(CONVERT(date, YearMonth + '-01'), 'yyyy-MMM') AS 'Year & Month name',
	COUNT(*) AS 'Number of Orders'
FROM (
	SELECT DISTINCT
		ordernumber,
		FORMAT(CONVERT(date, orderdate), 'yyyy-MM') AS YearMonth
	FROM Sales) AS x
GROUP BY YearMonth
ORDER BY YearMonth;


-- DealSize and Products by Quantity and Sales, sorted by DealSize in descending order from Large to Small.  ???!!! i dont see the reason to do this query
SELECT
	DealSize,
	ProductLine,
	SUM(quantityordered) AS Quantity,
	SUM(sales) AS Sales
FROM Sales
GROUP BY DealSize, productline
ORDER BY CASE 
			WHEN dealsize = 'Small' THEN 1
			WHEN dealsize = 'Medium' THEN 2
			WHEN dealsize = 'Large' THEN 3 END DESC,
		 Quantity DESC;


-- ordernumber and productline by Sales. I'm interested to see the salary where i have 4 products (different products) per each ordernumber.
-- Show the 1st and 3rd salary (sorted from largger to smaller), ordernumber and product name for each unique ordernumber.
SELECT
	ordernumber,
	productline,
	Sales
	--row_no,
	--count_products
FROM (	
	SELECT
		*,
		ROW_NUMBER() OVER(PARTITION BY ordernumber ORDER BY Sales DESC) as row_no,
		COUNT(productline) OVER(PARTITION BY ordernumber) AS count_products
	FROM (
		SELECT
			ordernumber,
			productline,
			SUM(Sales) AS Sales
		FROM Sales
		GROUP By ordernumber, productline
		) AS x
	) AS y
WHERE count_products = 4 AND row_no IN (1, 3)
ORDER BY ordernumber;
