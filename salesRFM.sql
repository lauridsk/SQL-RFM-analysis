-- Inspect data
SELECT * FROM salesdata

-- Since orderdate column is a string I want to convert it into a proper date format (yyyy-mm-dd) so I can perform date operations on it
SELECT orderdate FROM salesdata
SELECT str_to_date(orderdate, '%m/%d/%Y %i:%s') FROM salesdata

UPDATE salesdata 
SET orderdate = str_to_date(orderdate, '%m/%d/%Y %i:%s') 

-- Inspecting some of the data

SELECT DISTINCT status FROM salesdata
SELECT DISTINCT year_id FROM salesdata
SELECT DISTINCT productline FROM salesdata
SELECT DISTINCT country FROM salesdata
SELECT DISTINCT dealsize FROM salesdata
SELECT DISTINCT territory FROM salesdata

----------------Analysis----------------

-- Grouping sales by productline
SELECT productline, sum(sales) AS Revenue
FROM salesdata
GROUP BY productline
ORDER BY 2 DESC

-- Grouping sales by year
SELECT year_id, sum(sales) AS Revenue
FROM salesdata
GROUP BY year_id
ORDER BY 2 DESC

-- Grouping sales by dealsize
SELECT dealsize, sum(sales) AS Revenue
FROM salesdata
GROUP BY dealsize
ORDER BY 2 DESC

-- Best month for sales in a given year? E.g. 2003 used here, could also see for 2004 and 2005
SELECT month_id, sum(sales) AS Revenue, count(ordernumber) AS Orders
FROM salesdata
WHERE year_id = 2003
GROUP BY month_id
ORDER BY 2 DESC

-- November seems to the best month for sales, what products do they sell in November?
SELECT productline, sum(sales) AS Revenue, count(ordernumber) AS Orders
FROM salesdata
WHERE year_id = 2003 and month_id = 11
GROUP BY productline
ORDER BY 2 DESC

-- Who is our best customer (Recency, Frequency, Monetary analysis)
   
/*
1. For all customers I want to find their recent orders (Recency), how many times they ordered (Frequency), 
and their monetary value (Monetary). I want to "save" this result in a temp table
*/

CREATE TEMPORARY TABLE RFM_temp AS
WITH RFM AS
(
	SELECT
		customername,
		SUM(sales) AS MonetaryValue,
		AVG(sales) AS AvgMonetaryValue,
		COUNT(ordernumber) AS Frequency,
		MAX(orderdate) AS last_order_date,
		(SELECT MAX(orderdate) FROM salesdata) AS max_order_date,
		DATEDIFF(MAX(orderdate), (SELECT MAX(orderdate) FROM salesdata)) AS Recency
	FROM salesdata 
	GROUP BY customername
),
RFM_calc AS
(
	SELECT *,
		NTILE(4) OVER (ORDER BY Recency) AS RFM_Recency,
		NTILE(4) OVER (ORDER BY Frequency) AS RFM_Frequency,
		NTILE(4) OVER (ORDER BY MonetaryValue) AS RFM_Monetary
	FROM RFM
)

SELECT 
	*, RFM_Recency + RFM_Frequency + RFM_Monetary AS RFM_cell,
	CONCAT(RFM_Recency, RFM_Frequency, RFM_Monetary) AS rfm_cell_string
FROM RFM_calc

-- 

SELECT * FROM RFM_temp

SELECT customername, RFM_Recency, RFM_Frequency, RFM_Monetary,
	CASE 
		WHEN rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) THEN 'lost_customers'  -- lost customers
		WHEN rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) THEN 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		WHEN rfm_cell_string in (311, 411, 331) THEN 'new customers'
		WHEN rfm_cell_string in (222, 223, 233, 322) THEN 'potential churners'
		WHEN rfm_cell_string in (323, 333,321, 422, 332, 432) THEN 'active' -- (Customers who buy often & recently, but at low price points)
		WHEN rfm_cell_string in (433, 434, 443, 444) THEN 'loyal' -- Keep engaged and nurture relationship
	END RFM_Segment
FROM RFM_temp







































	

