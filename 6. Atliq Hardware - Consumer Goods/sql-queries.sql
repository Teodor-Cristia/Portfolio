USE codebasics_challenge_4_gdb023;

SELECT * FROM dim_customer;
SELECT * FROM dim_product;
SELECT * FROM fact_gross_price;
SELECT * FROM fact_manufacturing_cost;
SELECT * FROM fact_pre_invoice_deductions;
SELECT * FROM fact_sales_monthly;


/*
1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
*/
SELECT DISTINCT
	market
FROM dim_customer
WHERE customer = 'Atliq Exclusive'
	AND region = 'APAC'
ORDER BY market;


/*
1. Extra. Get insights: Analyzing the quantity sold and gross sales in each market can reveal its importance to 
customer Atliq Exclusive in terms of revenue and growth potential in the APAC region.
*/
WITH atliq_exclusive_apac_qty AS (
	SELECT
		c.market,
		SUM(s.sold_quantity) AS total_sold_quantity,
        ROUND(
				SUM(s.sold_quantity * gp.gross_price) / 1000000, 2
            ) AS gross_sales_mln
	FROM fact_sales_monthly s
    JOIN fact_gross_price gp
		ON s.product_code = gp.product_code
        AND s.fiscal_year = gp.fiscal_year
	JOIN dim_customer c
		ON s.customer_code = c.customer_code
	WHERE customer = 'Atliq Exclusive'
		AND region = 'APAC'
	GROUP BY market
)
SELECT
	market,
    ROUND(
		total_sold_quantity / SUM(total_sold_quantity) OVER() * 100, 2
	) AS sold_qty_percentage,
    gross_sales_mln
FROM atliq_exclusive_apac_qty
ORDER BY gross_sales_mln DESC;


/*
2. What is the percentage of unique product increase in 2021 vs. 2020?
The final output contains these fields:
	unique_products_2020
	unique_products_2021
	percentage_chg
*/
WITH unique_products AS (
	SELECT
		COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END) AS unique_products_2020,
		COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) AS unique_products_2021
	FROM fact_sales_monthly
)
SELECT 
	unique_products_2020,
    unique_products_2021,
    ROUND(
		(unique_products_2021 - unique_products_2020) * 100.0 / unique_products_2020, 2
	) AS percentage_chg
FROM unique_products;


/*
3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
The final output contains 2 fields:
	segment
	product_count
*/
SELECT
	p.segment,
    COUNT(DISTINCT s.product_code) AS product_count
FROM fact_sales_monthly s
JOIN dim_product p
	ON s.product_code = p.product_code
GROUP BY p.segment
ORDER BY product_count DESC;


/*
4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?
The final output contains these fields:
	segment
    product_count_2020
    product_count_2021
    difference
*/
WITH segment_products AS (
		SELECT
			p.segment,
			COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN s.product_code END) AS product_count_2020,
			COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN s.product_code END) AS product_count_2021,
			COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN s.product_code END) - 
			COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN s.product_code END) AS difference
		FROM fact_sales_monthly s
		JOIN dim_product p
			ON p.product_code = s.product_code
		WHERE fiscal_year IN (2020, 2021)
		GROUP BY p.segment
)
SELECT
	*
FROM segment_products
WHERE difference = (
		SELECT MAX(difference)
        FROM segment_products
	);


/*
5. Get the products that have the highest and lowest manufacturing costs.
 The final output should contain these fields:
	product_code
    product
    manufacturing_cost
*/
SELECT
	m.product_code,
    p.category,
	CONCAT(p.product, " - ", p.variant) AS product_name,
	m.manufacturing_cost
FROM fact_manufacturing_cost m
JOIN dim_product p
	ON m.product_code = p.product_code
WHERE m.manufacturing_cost IN (
		(SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost),
        (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
);


/*
6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.
The final output contains these fields:
	customer_code
    customer
    average_discount_percentage
*/
WITH ranked_india_customers_2021 AS (
	SELECT
		c.customer_code,
		c.customer,
		pre_invoice_discount_pct,
		DENSE_RANK() OVER(ORDER BY pre_invoice_discount_pct DESC) AS drnk    
	FROM dim_customer c
	JOIN fact_pre_invoice_deductions pid
		ON c.customer_code = pid.customer_code
	WHERE market = "India"
		AND fiscal_year = 2021
)
SELECT
	customer_code,
    customer,
    pre_invoice_discount_pct
FROM ranked_india_customers_2021
WHERE drnk <= 5
	AND pre_invoice_discount_pct > (
			SELECT AVG(pre_invoice_discount_pct)
            FROM ranked_india_customers_2021
    );


/*
7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month.
This analysis helps to get an idea of low and high-performing months and take strategic decisions.
 The final report contains these columns:
	Month
	Year
    GrossSalesAmount
*/
SELECT
    s.fiscal_year,
	MONTHNAME( DATE_ADD(date, INTERVAL 4 MONTH)	) AS fiscal_month,
	ROUND( SUM(s.sold_quantity * gp.gross_price) / 1000000, 2 ) AS gross_sales_amount_mln
FROM fact_sales_monthly s
JOIN fact_gross_price gp
	ON s.product_code = gp.product_code
    AND s.fiscal_year = gp.fiscal_year
JOIN dim_customer c
	ON s.customer_code = c.customer_code
WHERE c.customer = "Atliq Exclusive"
GROUP BY fiscal_year, fiscal_month
ORDER BY gross_sales_amount_mln DESC;


/*
8. In which quarter of 2020, got the maximum total_sold_quantity?
The final output contains these fields sorted by the total_sold_quantity:
	Quarter
    total_sold_quantity
*/
SELECT
    CONCAT("Q",
			QUARTER( DATE_ADD(date, INTERVAL 4 MONTH) )
		) AS fiscal_quarter,
    FORMAT( SUM(sold_quantity), 0) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY fiscal_quarter
ORDER BY SUM(sold_quantity) DESC;


-- this way is faster
SELECT
	CASE
		WHEN MONTH(date) IN (9, 10, 11) THEN "Q1"
        WHEN MONTH(date) IN (12, 1, 2) THEN "Q2"
        WHEN MONTH(date) IN (3, 4, 5) THEN "Q3"
        WHEN MONTH(date) IN (6, 7, 8) THEN "Q4"
	END AS fiscal_quarter,
    SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY fiscal_quarter
ORDER BY total_sold_quantity DESC;


/*
9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
The final output contains these fields:
	channel
    gross_sales_mln
    percentage
*/
WITH channel_gross_sales AS (
	SELECT
		c.channel,
		ROUND(
			SUM(s.sold_quantity * gp.gross_price) / 1000000, 2
		) AS gross_sales_mln
	FROM fact_sales_monthly s
	JOIN dim_customer c
		ON s.customer_code = c.customer_code
	JOIN fact_gross_price gp
		ON s.product_code = gp.product_code
		AND s.fiscal_year = gp.fiscal_year
	WHERE s.fiscal_year = 2021
	GROUP BY c.channel
)
SELECT
	channel,
    gross_sales_mln,
    ROUND(
		gross_sales_mln / SUM(gross_sales_mln) OVER() * 100, 2
	) AS percentage
FROM channel_gross_sales
ORDER BY percentage DESC;


/*
10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
The final output contains these fields:
	division
    product_code
*/
WITH division_sold_qty AS (
	SELECT
		p.division,
		p.product_code,
		FORMAT(SUM(s.sold_quantity), 0) AS total_sold_quantity,
        DENSE_RANK() OVER(
				PARTITION BY division
				ORDER BY SUM(s.sold_quantity) DESC
			) AS drnk
	FROM fact_sales_monthly s
	JOIN dim_product p
		ON s.product_code = p.product_code
	WHERE fiscal_year = 2021
	GROUP BY p.division, p.product_code
)
SELECT
	d.division,
    d.product_code,
    CONCAT(p.product, ' - ', p.variant) AS product_name,
    d.total_sold_quantity
FROM division_sold_qty d
JOIN dim_product p
	ON d.product_code = p.product_code
WHERE drnk <= 3
ORDER BY division ASC, total_sold_quantity DESC;

