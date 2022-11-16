-- Cleaning the orderdate column. We have here a nvarchar type for this column, let's change it to an appropriate date form.
SELECT
	orderdate,
	CAST(orderdate AS date) AS DateOrder
FROM [Sales Sample Data]..Sales;

-- Applying the changes to the orderdate
UPDATE [Sales Sample Data]..Sales
SET orderdate = CONVERT(date, orderdate);

