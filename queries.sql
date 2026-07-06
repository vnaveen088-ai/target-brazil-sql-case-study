-- ============================================================
-- Target Brazil E-Commerce SQL Case Study
-- All queries, organized by analysis section
-- Engine: Google BigQuery (Standard SQL)
-- ============================================================


-- ============================================================
-- 1. INITIAL EXPLORATION
-- ============================================================

-- 1A. Data type of all columns in the "customers" table
SELECT
  table_name,
  column_name,
  data_type
FROM project.INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'customers';

-- 1B. Time range between which orders were placed
SELECT
  MIN(order_purchase_timestamp) AS start_date,
  MAX(order_purchase_timestamp) AS end_date
FROM project.orders;

-- 1C. Count of cities & states of customers who ordered
SELECT
  COUNT(DISTINCT c.customer_city) AS cities,
  COUNT(DISTINCT c.customer_state) AS states
FROM project.customers c
JOIN project.orders o
  ON c.customer_id = o.customer_id
WHERE o.order_purchase_timestamp BETWEEN
  (SELECT MIN(order_purchase_timestamp) FROM project.orders)
  AND (SELECT MAX(order_purchase_timestamp) FROM project.orders);


-- ============================================================
-- 2. IN-DEPTH EXPLORATION
-- ============================================================

-- 2A. Growing trend in number of orders placed over the years
SELECT
  EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
  COUNT(order_id) AS total_count
FROM project.orders
GROUP BY year
ORDER BY year DESC;

-- 2B. Monthly seasonality in order volume
SELECT
  EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
  EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
  COUNT(order_id) AS total_orders
FROM project.orders
GROUP BY year, month
ORDER BY year, month;

-- 2C. Time of day customers mostly place orders
-- 0-6 Dawn | 7-12 Morning | 13-18 Afternoon | 19-23 Night
SELECT time_slot, COUNT(*) AS order_count
FROM (
  SELECT
    CASE
      WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 0 AND 6  THEN 'Dawn'
      WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 7 AND 12 THEN 'Morning'
      WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 13 AND 18 THEN 'Afternoon'
      WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 19 AND 23 THEN 'Night'
    END AS time_slot
  FROM project.orders
) t
GROUP BY time_slot
ORDER BY order_count DESC;


-- ============================================================
-- 3. EVOLUTION OF E-COMMERCE ORDERS IN BRAZIL
-- ============================================================

-- 3A. Month-on-month number of orders placed in each state
SELECT
  EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
  EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
  c.customer_state,
  COUNT(*) AS total_orders
FROM project.orders o
JOIN project.customers c
  ON c.customer_id = o.customer_id
GROUP BY year, month, c.customer_state
ORDER BY year, month, c.customer_state;

-- 3B. Customer distribution across all states
SELECT
  customer_state,
  COUNT(DISTINCT customer_id) AS total_customers
FROM project.customers
GROUP BY customer_state
ORDER BY total_customers;


-- ============================================================
-- 4. IMPACT ON ECONOMY
-- ============================================================

-- 4A. % increase in cost of orders, Jan-Aug 2017 vs. Jan-Aug 2018
SELECT
  ROUND((
    (
      SUM(CASE WHEN EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018
               AND EXTRACT(MONTH FROM o.order_purchase_timestamp) BETWEEN 1 AND 8
          THEN p.payment_value ELSE 0 END)
      -
      SUM(CASE WHEN EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2017
               AND EXTRACT(MONTH FROM o.order_purchase_timestamp) BETWEEN 1 AND 8
          THEN p.payment_value ELSE 0 END)
    )
    / SUM(CASE WHEN EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2017
                AND EXTRACT(MONTH FROM o.order_purchase_timestamp) BETWEEN 1 AND 8
           THEN p.payment_value ELSE 0 END)
    * 100
  ), 2) AS percentage_increase
FROM project.orders o
JOIN project.payments p ON o.order_id = p.order_id
WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) IN (2017, 2018)
  AND EXTRACT(MONTH FROM o.order_purchase_timestamp) BETWEEN 1 AND 8;

-- 4B. Total & average order price by state
SELECT
  c.customer_state,
  SUM(p.payment_value) AS total_price,
  AVG(p.payment_value) AS avg_price
FROM project.orders o
JOIN project.customers c ON c.customer_id = o.customer_id
JOIN project.payments p ON o.order_id = p.order_id
GROUP BY c.customer_state
ORDER BY total_price DESC;

-- 4C. Total & average order freight value by state
SELECT
  c.customer_state,
  SUM(i.freight_value) AS total_freight,
  AVG(i.freight_value) AS avg_freight
FROM project.orders o
JOIN project.customers c ON c.customer_id = o.customer_id
JOIN project.order_items i ON o.order_id = i.order_id
GROUP BY c.customer_state
ORDER BY total_freight DESC;


-- ============================================================
-- 5. SALES, FREIGHT & DELIVERY TIME ANALYSIS
-- ============================================================

-- 5A. Delivery time and delivery-date accuracy (single query)
SELECT
  order_id,
  DATE_DIFF(CAST(order_delivered_customer_date AS DATE),
            CAST(order_purchase_timestamp AS DATE), DAY) AS time_to_deliver,
  DATE_DIFF(CAST(order_delivered_customer_date AS DATE),
            CAST(order_estimated_delivery_date AS DATE), DAY) AS diff_estimated_delivery
FROM project.orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;

-- 5B. Top 5 states with highest & lowest average freight value
SELECT
  c.customer_state,
  ROUND(AVG(i.freight_value), 2) AS avg_freight_value
FROM project.orders o
JOIN project.order_items i ON o.order_id = i.order_id
JOIN project.customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_freight_value;  -- flip to DESC for the highest-value end

-- 5C. Top 5 states with highest & lowest average delivery time
SELECT
  c.customer_state,
  ROUND(AVG(DATE_DIFF(o.order_delivered_customer_date,
                       o.order_purchase_timestamp, DAY)), 2) AS avg_delivery_days
FROM project.orders o
JOIN project.customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_delivery_days;  -- flip to DESC for the slowest end

-- 5D. Top 5 states where delivery is fastest vs. estimated date
SELECT
  c.customer_state,
  AVG(DATE_DIFF(CAST(o.order_estimated_delivery_date AS DATE),
                CAST(o.order_delivered_customer_date AS DATE), DAY)) AS days_ahead_of_estimate
FROM project.orders o
JOIN project.customers c ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY days_ahead_of_estimate DESC
LIMIT 5;


-- ============================================================
-- 6. PAYMENT ANALYSIS
-- ============================================================

-- 6A. Month-on-month number of orders by payment type
SELECT
  EXTRACT(YEAR FROM o.order_purchase_timestamp) AS year,
  EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month,
  p.payment_type,
  COUNT(DISTINCT o.order_id) AS total_orders
FROM project.orders o
JOIN project.payments p ON o.order_id = p.order_id
GROUP BY year, month, p.payment_type
ORDER BY year, month;

-- 6B. Number of orders by payment installments
SELECT
  payment_installments,
  COUNT(order_id) AS number_of_orders
FROM project.payments
GROUP BY payment_installments
ORDER BY payment_installments;
