--data uploaded directly into snowflake
USE DATABASE foodora;
USE SCHEMA public;
SHOW TABLES;

DESCRIBE TABLE foodora.public.customers;
DESCRIBE TABLE foodora.public.orders;
DESCRIBE TABLE foodora.public.vendors;

SELECT *
FROM foodora.public.vendors
LIMIT 10;

--Top 5 customers for the last 3 month
--This yeilded no results as the data available is for 2 months instead of 6

SELECT c.customer_id, 
    COUNT(o.order_id) AS order_count, 
    ROUND(SUM(o.order_gmv), 2) AS total_spent
FROM  CUSTOMERS c
JOIN  ORDERS o ON c.customer_id = o.customer_id
WHERE o.created_at_local >= DATEADD(MONTH, -3, CURRENT_DATE())
GROUP BY c.customer_id
ORDER BY order_count DESC
LIMIT 5;

-- Customers who placed the most orders in the 2 months along with the total amount spent

SELECT MIN(created_at_local) AS earliest_order,
    MAX(created_at_local) AS latest_order
FROM ORDERS;

SELECT c.customer_id, 
    COUNT(o.order_id) AS order_count, 
    ROUND(SUM(o.order_gmv),2) AS total_spent
FROM  CUSTOMERS c
JOIN  ORDERS o ON c.customer_id = o.customer_id
WHERE  o.created_at_local BETWEEN '2023-01-01' AND '2023-02-28'
GROUP BY c.customer_id
ORDER BY order_count DESC
LIMIT 5;

--testing if the highest order total corresponds with most orders placed

SELECT c.customer_id, 
    COUNT(o.order_id) AS order_count, 
    ROUND(SUM(o.order_gmv), 2) AS total_spent
FROM CUSTOMERS c
JOIN ORDERS o ON c.customer_id = o.customer_id
WHERE  o.created_at_local BETWEEN '2023-01-01' AND '2023-02-28'
GROUP BY c.customer_id
ORDER BY total_spent DESC
LIMIT 5;



-- Average order value by vendor Ascending
 SELECT  v.vendor_id, 
    ROUND(AVG(o.order_gmv),2) AS average_order_value
FROM VENDORS v
JOIN ORDERS o ON v.vendor_id = o.vendor_id
WHERE o.created_at_local BETWEEN '2023-01-01' AND '2023-02-28'
GROUP BY v.vendor_id
ORDER BY average_order_value ASC;

-- Average order value by vendor Descending
 SELECT  v.vendor_id, 
    ROUND(AVG(o.order_gmv),2) AS average_order_value
FROM VENDORS v
JOIN ORDERS o ON v.vendor_id = o.vendor_id
WHERE o.created_at_local BETWEEN '2023-01-01' AND '2023-02-28'
GROUP BY v.vendor_id
ORDER BY average_order_value DESC;

-- Why is there such a big gap in Average order value from vendors?
-- Calculate vendor performance based on their days active DESC order

SELECT v.vendor_id, v.primary_cuisine, v.pd_activation_date, 
 ('2023-02-28'::date - v.pd_activation_date::date)::int AS days_active, 
ROUND(AVG(o.order_gmv), 2) AS average_order_value,
COUNT(o.order_id) AS order_count, 
ROUND(SUM(o.order_gmv), 2) AS total_revenue 
FROM VENDORS v
JOIN ORDERS o ON v.vendor_id = o.vendor_id
WHERE  o.created_at_local BETWEEN '2023-01-01' AND '2023-02-28'
GROUP BY  v.vendor_id, v.primary_cuisine, v.pd_activation_date
ORDER BY total_revenue DESC;


-- Calculate vendor performance based on their days active ASC order to compare

SELECT v.vendor_id, v.primary_cuisine, v.pd_activation_date, 
 ('2023-02-28'::date - v.pd_activation_date::date)::int AS days_active, 
ROUND(AVG(o.order_gmv), 2) AS average_order_value,
COUNT(o.order_id) AS order_count, 
ROUND(SUM(o.order_gmv), 2) AS total_revenue 
FROM VENDORS v
JOIN ORDERS o ON v.vendor_id = o.vendor_id
WHERE  o.created_at_local BETWEEN '2023-01-01' AND '2023-02-28'
GROUP BY  v.vendor_id, v.primary_cuisine, v.pd_activation_date
ORDER BY total_revenue ASC;




-- Customers who have not placed an order in the given time period

SELECT c.customer_id AS inactive_customer
FROM CUSTOMERS c
LEFT JOIN ORDERS o ON c.customer_id = o.customer_id 
AND o.created_at_local BETWEEN '2023-01-01' AND '2023-02-28'
WHERE o.customer_id IS NULL;
    
-- comparing the 2 months data given

SELECT
    (SELECT ROUND(SUM(order_value), 2)
     FROM Orders
     WHERE created_at_local BETWEEN '2023-01-01' AND '2023-01-31') AS january_revenue,
    (SELECT ROUND(SUM(order_value), 2)
     FROM Orders
     WHERE created_at_local BETWEEN '2023-02-01' AND '2023-02-28') AS february_revenue;


--Top 3 vendors

WITH VendorRevenue AS (
SELECT vendor_id, 
     ROUND(SUM(order_value),2) AS total_revenue
FROM Orders
GROUP BY vendor_id),TopVendors AS (
SELECT vendor_id, total_revenue
FROM VendorRevenue
ORDER BY total_revenue DESC
LIMIT 3),
OverallRevenue AS (
SELECT 
ROUND(SUM(total_revenue),2) AS total_revenue
FROM  VendorRevenue)
-- Calculate each top vendor's revenue and their contribution percentage
SELECT 
    t.vendor_id,
    t.total_revenue AS top_vendor_revenue,
    (t.total_revenue / o.total_revenue) * 100 AS contribution_percentage
FROM 
    TopVendors t
CROSS JOIN 
    OverallRevenue o;

-- Calculate the total revenue for all vendors

WITH total_revenue AS (
    SELECT SUM(order_gmv) AS overall_revenue
    FROM ORDERS
    WHERE created_at_local BETWEEN '2023-01-01' AND '2023-02-28')


-- Calculate the total revenue for top 3 vendors and their revenue percentage

SELECT v.vendor_id,
    ROUND(SUM(o.order_gmv), 2) AS total_revenue,
    ROUND(SUM(o.order_gmv) / 
    (SELECT SUM(order_gmv) 
     FROM ORDERS 
    WHERE created_at_local BETWEEN '2023-01-01' AND '2023-02-28') * 100, 2)
    AS contribution_percentage
FROM VENDORS v
JOIN ORDERS o ON v.vendor_id = o.vendor_id
WHERE o.created_at_local BETWEEN '2023-01-01' AND '2023-02-28'
GROUP BY v.vendor_id
ORDER BY total_revenue DESC
LIMIT 3;


-- Analyze cuisine type trends between January and February

WITH MonthlyCuisine AS (
    SELECT v.primary_cuisine,
        DATE_TRUNC('month', o.created_at_local) AS month,
        COUNT(o.order_id) AS order_count,
        ROUND(SUM(o.order_gmv), 2) AS total_revenue
FROM ORDERS o
JOIN   VENDORS v ON o.vendor_id = v.vendor_id
WHERE   o.created_at_local BETWEEN '2023-01-01' AND '2023-02-28'
GROUP BY  v.primary_cuisine, DATE_TRUNC('month', o.created_at_local)
)
SELECT  primary_cuisine,
    COALESCE(SUM(CASE WHEN month = '2023-01-01' THEN order_count END), 0) AS jan_order_count,
    COALESCE(SUM(CASE WHEN month = '2023-02-01' THEN order_count END), 0) AS feb_order_count,
    COALESCE(SUM(CASE WHEN month = '2023-01-01' THEN total_revenue END), 0) AS jan_revenue,
    COALESCE(SUM(CASE WHEN month = '2023-02-01' THEN total_revenue END), 0) AS feb_revenue,
    ROUND((COALESCE(SUM(CASE WHEN month = '2023-02-01' THEN total_revenue END), 0) - 
         COALESCE(SUM(CASE WHEN month = '2023-01-01' THEN total_revenue END), 0)) / 
        NULLIF(COALESCE(SUM(CASE WHEN month = '2023-01-01' THEN total_revenue END), 0), 0) * 100, 
        2) AS revenue_percentage_difference
FROM  MonthlyCuisine
GROUP BY  primary_cuisine
ORDER BY feb_revenue DESC
LIMIT 10;
