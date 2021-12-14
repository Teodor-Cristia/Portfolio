USE [Sales Sample Data];

SELECT TOP(10)
	*
FROM Sales;


-- Total Number of Orders 
SELECT
	COUNT(DISTINCT ordernumber) AS 'Number of Orders'
FROM Sales;


-- Let's get the number of orders by year and month, sorted by date.
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


-- ordernumber and productline by Sales. I'm interested to see the salary where i have 4 products (unique products) per each ordernumber.
-- Show only the 1st and 3rd salary (sorted from largger to smaller), ordernumber and product name for each unique ordernumber.
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


-- Checking the Data. Comparing the SQL results with the Power BI dashboard / report 
-- Sales by country
SELECT
	Country,
	FORMAT(SUM(sales), 'N2') AS 'Total Sales'
FROM Sales
GROUP BY Country
ORDER BY SUM(sales) DESC;							--I used the aggregate function 'SUM(sales)' to sort the results because the output of the 'Total Sales' column is a nvarchar / string format


-- Sales by product
SELECT
	Product,
	'$' + FORMAT([Total Sales], 'N2') AS 'Total Sales'
FROM (
	SELECT
		productline AS Product,
		SUM(Sales) AS 'Total Sales'
	FROM Sales
	GROUP BY productline
	) AS product_grouping
ORDER BY product_grouping.[Total Sales] DESC;


-- sort by status in a specific order
SELECT
	productline as Product,
	Status,
	SUM(sales) AS 'Total Sales'
FROM Sales
GROUP BY productline, status
ORDER BY Product,
		 CASE
			WHEN status LIKE '%proces%' THEN 1
			WHEN status LIKE '%Hold' THEN 2
			WHEN status = 'Shipped' THEN 3
			WHEN status = 'Disputed' THEN 4
			WHEN status = 'Resolved' THEN 5
			WHEN status = 'Cancelled' THEN 6
		 END;
