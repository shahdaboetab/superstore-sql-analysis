-- ==========================================================
-- Superstore SQL Business Analysis  |  SQLite  |  superstore.db
-- Tables: customers, products, orders, order_items
-- ==========================================================

-- Q1: How big is the business? (headline KPIs, to reconcile with the Excel dashboard)
-- Technique: JOIN, aggregate functions, COUNT DISTINCT
SELECT ROUND(SUM(oi.sales), 2)                                  AS total_sales,
       ROUND(SUM(oi.profit), 2)                                 AS total_profit,
       ROUND(100.0 * SUM(oi.profit) / SUM(oi.sales), 1)         AS margin_pct,
       COUNT(DISTINCT oi.order_id)                              AS orders,
       COUNT(DISTINCT o.customer_id)                            AS customers,
       SUM(oi.quantity)                                         AS units_sold,
       ROUND(SUM(oi.sales) / COUNT(DISTINCT oi.order_id), 2)    AS avg_order_value
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id;

-- Q2: Which regions earn the most, and which earn the least per dollar of sales?
-- Technique: JOIN, GROUP BY
SELECT o.region,
       ROUND(SUM(oi.sales), 0)                          AS sales,
       ROUND(SUM(oi.profit), 0)                         AS profit,
       ROUND(100.0 * SUM(oi.profit) / SUM(oi.sales), 1) AS margin_pct
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY o.region
ORDER BY sales DESC;

-- Q3: How do categories and sub-categories compare on sales, profit and margin?
-- Technique: JOIN, GROUP BY, multi-column grouping
SELECT p.category, p.sub_category,
       ROUND(SUM(oi.sales), 0)                          AS sales,
       ROUND(SUM(oi.profit), 0)                         AS profit,
       ROUND(100.0 * SUM(oi.profit) / SUM(oi.sales), 1) AS margin_pct
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.category, p.sub_category
ORDER BY profit DESC;

-- Q4: Which sub-categories lose money overall?
-- Technique: GROUP BY + HAVING
SELECT p.category, p.sub_category,
       ROUND(SUM(oi.sales), 0)  AS sales,
       ROUND(SUM(oi.profit), 0) AS profit
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.category, p.sub_category
HAVING SUM(oi.profit) < 0
ORDER BY profit;

-- Q5: How fast are sales and profit growing year over year?
-- Technique: CTE + LAG window function
WITH yearly AS (
    SELECT strftime('%Y', o.order_date) AS year,
           SUM(oi.sales)  AS sales,
           SUM(oi.profit) AS profit
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY year
)
SELECT year,
       ROUND(sales, 0)                                  AS sales,
       ROUND(profit, 0)                                 AS profit,
       ROUND(100.0 * profit / sales, 1)                 AS margin_pct,
       ROUND(100.0 * (sales - LAG(sales) OVER (ORDER BY year))
                   / LAG(sales) OVER (ORDER BY year), 1) AS sales_yoy_pct
FROM yearly
ORDER BY year;

-- Q6: What does the monthly sales pattern look like, and when is the peak?
-- Technique: CTE + LAG window function
WITH monthly AS (
    SELECT strftime('%Y-%m', o.order_date) AS month,
           SUM(oi.sales) AS sales
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY month
)
SELECT month,
       ROUND(sales, 0) AS sales,
       ROUND(100.0 * (sales - LAG(sales) OVER (ORDER BY month))
                   / LAG(sales) OVER (ORDER BY month), 1) AS mom_growth_pct
FROM monthly
ORDER BY month;

-- Q7: What are the 3 most profitable products in each category?
-- Technique: CTE + RANK() OVER (PARTITION BY)
WITH product_profit AS (
    SELECT p.category, p.product_name,
           SUM(oi.profit) AS profit,
           SUM(oi.sales)  AS sales
    FROM order_items oi
    JOIN products p ON p.product_id = oi.product_id
    GROUP BY p.category, p.product_id
),
ranked AS (
    SELECT *, RANK() OVER (PARTITION BY category ORDER BY profit DESC) AS rnk
    FROM product_profit
)
SELECT category, rnk AS rank, product_name,
       ROUND(sales, 0) AS sales, ROUND(profit, 0) AS profit
FROM ranked
WHERE rnk <= 3
ORDER BY category, rnk;

-- Q8: Which customers spend more than the average customer?
-- Technique: CTE + scalar subquery
WITH customer_sales AS (
    SELECT c.customer_id, c.customer_name, c.segment,
           SUM(oi.sales)  AS sales,
           SUM(oi.profit) AS profit
    FROM customers c
    JOIN orders o       ON o.customer_id = c.customer_id
    JOIN order_items oi ON oi.order_id   = o.order_id
    GROUP BY c.customer_id
)
SELECT customer_name, segment,
       ROUND(sales, 0)  AS sales,
       ROUND(profit, 0) AS profit,
       ROUND((SELECT AVG(sales) FROM customer_sales), 0) AS avg_customer_sales
FROM customer_sales
WHERE sales > (SELECT AVG(sales) FROM customer_sales)
ORDER BY sales DESC
LIMIT 15;

-- Q9: How concentrated is revenue? Do the top 25% of customers drive most of it?
-- Technique: CTE + NTILE window function
WITH customer_sales AS (
    SELECT o.customer_id, SUM(oi.sales) AS sales
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY o.customer_id
),
quartiles AS (
    SELECT *, NTILE(4) OVER (ORDER BY sales DESC) AS quartile
    FROM customer_sales
)
SELECT quartile,
       COUNT(*)                                                   AS customers,
       ROUND(SUM(sales), 0)                                       AS sales,
       ROUND(100.0 * SUM(sales) / (SELECT SUM(sales) FROM customer_sales), 1) AS share_of_sales_pct
FROM quartiles
GROUP BY quartile
ORDER BY quartile;

-- Q10: How many customers buy once vs come back, and how many orders do repeat customers place?
-- Technique: CTE, CASE, GROUP BY
WITH orders_per_customer AS (
    SELECT customer_id, COUNT(*) AS n_orders
    FROM orders
    GROUP BY customer_id
)
SELECT CASE WHEN n_orders = 1 THEN 'One-time' ELSE 'Repeat (2+ orders)' END AS customer_type,
       COUNT(*)                          AS customers,
       ROUND(AVG(n_orders), 1)           AS avg_orders_per_customer
FROM orders_per_customer
GROUP BY customer_type;

-- Q11: How does the discount level affect profit?
-- Technique: CASE, GROUP BY, conditional aggregation
SELECT CASE WHEN discount = 0    THEN '1 No discount'
            WHEN discount <= 0.2 THEN '2 Low (1-20%)'
            WHEN discount <= 0.4 THEN '3 Medium (21-40%)'
            ELSE                      '4 High (>40%)' END     AS discount_band,
       COUNT(*)                                               AS lines,
       ROUND(SUM(sales), 0)                                   AS sales,
       ROUND(SUM(profit), 0)                                  AS profit,
       ROUND(100.0 * SUM(profit) / SUM(sales), 1)             AS margin_pct,
       ROUND(100.0 * SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_lines_at_loss
FROM order_items
GROUP BY discount_band
ORDER BY discount_band;

-- Q12: How long does delivery take by ship mode? (used instead of a payments table, which this dataset does not have)
-- Technique: Date arithmetic with julianday, GROUP BY
SELECT ship_mode,
       COUNT(*) AS orders,
       ROUND(AVG(julianday(ship_date) - julianday(order_date)), 1) AS avg_delivery_days,
       MAX(CAST(julianday(ship_date) - julianday(order_date) AS INTEGER)) AS max_delivery_days
FROM orders
GROUP BY ship_mode
ORDER BY avg_delivery_days;

-- Q13: Which large customers cost us money?
-- Technique: CTE, JOIN, filter on aggregates
WITH customer_totals AS (
    SELECT c.customer_name, c.segment,
           SUM(oi.sales)  AS sales,
           SUM(oi.profit) AS profit
    FROM customers c
    JOIN orders o       ON o.customer_id = c.customer_id
    JOIN order_items oi ON oi.order_id   = o.order_id
    GROUP BY c.customer_id
)
SELECT customer_name, segment,
       ROUND(sales, 0)  AS sales,
       ROUND(profit, 0) AS profit
FROM customer_totals
WHERE profit < 0
ORDER BY sales DESC
LIMIT 10;

-- Q14: Which states lose the most money?
-- Technique: JOIN, GROUP BY, ORDER BY + LIMIT
SELECT o.state, o.region,
       ROUND(SUM(oi.sales), 0)                          AS sales,
       ROUND(SUM(oi.profit), 0)                         AS profit,
       ROUND(100.0 * SUM(oi.profit) / SUM(oi.sales), 1) AS margin_pct
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY o.state, o.region
ORDER BY profit
LIMIT 10;
