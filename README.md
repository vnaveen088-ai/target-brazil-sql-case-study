# Target Brazil E-Commerce SQL Case Study

A SQL-driven analysis of ~100,000 orders placed on Target's Brazilian e-commerce marketplace between 2016 and 2018. The project explores order growth, seasonality, customer distribution, pricing, freight, delivery performance, and payment behavior — and translates the findings into business recommendations.

## Overview

- **Role simulated:** Data Analyst at Target
- **Data:** 8 relational tables — `customers`, `orders`, `order_items`, `payments`, `products`, `sellers`, `reviews`, `geolocation`
- **Tool used:** Google BigQuery (Standard SQL)
- **Scope:** Exploratory analysis, trend analysis, revenue/economic impact, delivery performance, and payment behavior

## Dataset

| Table | Description |
|---|---|
| `customers` | Customer ID, unique ID, zip code, city, state |
| `sellers` | Seller ID, zip code, city, state |
| `order_items` | Order-item level detail — price, freight value, shipping deadline |
| `geolocation` | Zip-code-level latitude/longitude |
| `payments` | Payment type, installments, payment value |
| `orders` | Order status and purchase/delivery/estimated-delivery timestamps |
| `reviews` | Review score, title, comment, timestamps |
| `products` | Product category, dimensions, weight, photo count |

## Business Questions & Findings

### 1. Initial Exploration

**A. Column data types in `customers`**
```sql
SELECT table_name, column_name, data_type
FROM project.INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'customers';
```
`customer_id`, `customer_unique_id`, `customer_city`, and `customer_state` are `STRING`; `customer_zip_code_prefix` is `INT64`.

**B. Time range of orders placed**
```sql
SELECT MIN(order_purchase_timestamp) AS start_date,
       MAX(order_purchase_timestamp) AS end_date
FROM project.orders;
```
Orders span **September 4, 2016 to October 17, 2018** (~2 years, 1 month).

**C. Cities & states covered**
```sql
SELECT COUNT(DISTINCT c.customer_city) AS cities,
       COUNT(DISTINCT c.customer_state) AS states
FROM project.customers c
JOIN project.orders o ON c.customer_id = o.customer_id;
```
Orders came from **4,119 cities across all 27 Brazilian states**, confirming nationwide reach.

---

### 2. In-Depth Exploration

**A. Year-over-year order growth**
```sql
SELECT EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
       COUNT(order_id) AS total_orders
FROM project.orders
GROUP BY year
ORDER BY year DESC;
```
| Year | Orders | YoY Growth |
|---|---|---|
| 2016 | 329 | — |
| 2017 | 45,101 | +45,101 (platform's first full year) |
| 2018 | 54,011 | +19.7% |

*2016 only reflects a partial launch period (starting September), so the 2017→2018 comparison is the more meaningful growth signal — a healthy ~20% year-over-year increase.*

**B. Monthly seasonality**
```sql
SELECT EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
       EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
       COUNT(order_id) AS total_orders
FROM project.orders
GROUP BY year, month
ORDER BY year, month;
```
Order volume rises steadily through 2017 into 2018 with visible month-to-month fluctuation, consistent with typical retail seasonality (e.g., late-year peaks).

**C. Time-of-day ordering pattern**
```sql
SELECT time_slot, COUNT(*) AS order_count
FROM (
  SELECT CASE
    WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 0 AND 6  THEN 'Dawn'
    WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 7 AND 12 THEN 'Morning'
    WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 13 AND 18 THEN 'Afternoon'
    WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 19 AND 23 THEN 'Night'
  END AS time_slot
  FROM project.orders
) t
GROUP BY time_slot
ORDER BY order_count DESC;
```
| Time Slot | Orders |
|---|---|
| Afternoon | 38,135 |
| Night | 28,331 |
| Morning | 27,733 |
| Dawn | 5,242 |

Most orders are placed in the **afternoon**, followed closely by **night** — suggesting customers shop during lunch breaks and after work/dinner. Dawn has minimal activity.

---

### 3. Evolution of E-Commerce Across Brazil

**A. Month-on-month orders by state**
```sql
SELECT EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
       EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
       c.customer_state,
       COUNT(*) AS total_orders
FROM project.orders o
JOIN project.customers c ON c.customer_id = o.customer_id
GROUP BY year, month, c.customer_state
ORDER BY year, month, c.customer_state;
```
Order growth is broad-based across states rather than concentrated in one region, though the pace differs.

**B. Customer distribution by state**
```sql
SELECT customer_state,
       COUNT(DISTINCT customer_id) AS total_customers
FROM project.customers
GROUP BY customer_state
ORDER BY total_customers;
```
**São Paulo (SP)** dominates the customer base, while **Roraima (RR), Amapá (AP), and Acre (AC)** — northern states with smaller populations — have the fewest customers (well under 100 each).

---

### 4. Impact on Economy

**A. % increase in order value, Jan–Aug 2017 vs. Jan–Aug 2018**
```sql
SELECT ROUND((
  SUM(CASE WHEN EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018
           AND EXTRACT(MONTH FROM o.order_purchase_timestamp) BETWEEN 1 AND 8
      THEN p.payment_value ELSE 0 END)
  -
  SUM(CASE WHEN EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2017
           AND EXTRACT(MONTH FROM o.order_purchase_timestamp) BETWEEN 1 AND 8
      THEN p.payment_value ELSE 0 END)
) / SUM(CASE WHEN EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2017
              AND EXTRACT(MONTH FROM o.order_purchase_timestamp) BETWEEN 1 AND 8
         THEN p.payment_value ELSE 0 END) * 100, 2) AS percentage_increase
FROM project.orders o
JOIN project.payments p ON o.order_id = p.order_id
WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) IN (2017, 2018)
  AND EXTRACT(MONTH FROM o.order_purchase_timestamp) BETWEEN 1 AND 8;
```
Total order value grew by **136.98%** from Jan–Aug 2017 to Jan–Aug 2018 — a strong indicator of the platform's growing economic footprint in Brazil.

**B. Total & average order value by state**
```sql
SELECT c.customer_state,
       SUM(p.payment_value) AS total_price,
       AVG(p.payment_value) AS avg_price
FROM project.orders o
JOIN project.customers c ON c.customer_id = o.customer_id
JOIN project.payments p ON o.order_id = p.order_id
GROUP BY c.customer_state
ORDER BY total_price DESC;
```
**São Paulo (SP)** leads total revenue (~R$6.0M) by a wide margin, followed by Rio de Janeiro (RJ) and Minas Gerais (MG) — expected, given SP's larger customer base. Interestingly, **average order value is not highest in SP**; smaller states like Santa Catarina (SC) and Bahia (BA) show higher average basket sizes.

**C. Total & average freight value by state**
```sql
SELECT c.customer_state,
       SUM(i.freight_value) AS total_freight,
       AVG(i.freight_value) AS avg_freight
FROM project.orders o
JOIN project.customers c ON c.customer_id = o.customer_id
JOIN project.order_items i ON o.order_id = i.order_id
GROUP BY c.customer_state
ORDER BY total_freight DESC;
```
SP has the lowest average freight cost (~R$15) due to shorter shipping distances from major distribution hubs, while remote states carry noticeably higher per-order freight costs.

---

### 5. Sales, Freight & Delivery Time Analysis

**A. Delivery time and delivery-date accuracy (single query)**
```sql
SELECT order_id,
       DATE_DIFF(CAST(order_delivered_customer_date AS DATE),
                 CAST(order_purchase_timestamp AS DATE), DAY) AS time_to_deliver,
       DATE_DIFF(CAST(order_delivered_customer_date AS DATE),
                 CAST(order_estimated_delivery_date AS DATE), DAY) AS diff_estimated_delivery
FROM project.orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;
```
This gives an order-level view of actual delivery time and how it compares to the promised delivery estimate (negative = delivered early, positive = delivered late).

**B. Top 5 states — highest & lowest average freight**
| Lowest | Value | Highest | Value |
|---|---|---|---|
| SP | R$15.15 | RR | R$42.98 |
| PR | R$20.53 | PB | R$42.72 |
| MG | R$20.63 | RO | R$41.07 |
| RJ | R$20.96 | AC | R$40.07 |
| DF | R$21.04 | PI | R$39.15 |

**C. Top 5 states — highest & lowest average delivery time**
| Fastest | Days | Slowest | Days |
|---|---|---|---|
| SP | 8.3 | RR | 28.98 |
| PR | 11.53 | AP | 26.73 |
| MG | 11.54 | AM | 25.99 |
| DF | 12.51 | AL | 24.04 |
| SC | 14.48 | PA | 23.32 |

**D. States with the biggest gap between estimated and actual delivery (earliest deliveries)**
```sql
SELECT c.customer_state,
       AVG(DATE_DIFF(CAST(o.order_estimated_delivery_date AS DATE),
                      CAST(o.order_delivered_customer_date AS DATE), DAY)) AS days_ahead_of_estimate
FROM project.orders o
JOIN project.customers c ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY days_ahead_of_estimate DESC
LIMIT 5;
```
AC, RO, AP, AM, and RR — the same remote states with the *longest* absolute delivery times — also show the largest buffer between estimated and actual delivery. This suggests Target's estimation model is deliberately conservative for these regions, padding timelines to manage expectations rather than these orders arriving unusually fast in absolute terms.

---

### 6. Payment Behavior

**A. Month-on-month orders by payment type**
```sql
SELECT EXTRACT(YEAR FROM o.order_purchase_timestamp) AS year,
       EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month,
       p.payment_type,
       COUNT(DISTINCT o.order_id) AS total_orders
FROM project.orders o
JOIN project.payments p ON o.order_id = p.order_id
GROUP BY year, month, p.payment_type
ORDER BY year, month;
```
**Credit card is the dominant payment method** every month, with vouchers and other digital payment types making up a small share. Order volume across all payment types dips in late 2016, consistent with the platform still ramping up.

**B. Orders by number of payment installments**
```sql
SELECT payment_installments,
       COUNT(order_id) AS number_of_orders
FROM project.payments
GROUP BY payment_installments
ORDER BY payment_installments;
```
The majority of orders (over half) are paid **in a single installment**; demand drops off sharply as the number of installments increases, though a meaningful tail of customers spreads payments over multiple months.

---

## Key Insights

1. **Strong, broad-based growth** — order volume and order value both grew substantially year over year (+19.7% orders, +137% revenue), across nearly all states, not just São Paulo.
2. **Afternoon and night are peak shopping windows** — marketing pushes and flash sales are best timed around these hours.
3. **Logistics cost and speed correlate with geography** — São Paulo enjoys the cheapest, fastest delivery; the North region (RR, AP, AC, RO, AM) is consistently the most expensive and slowest to serve.
4. **Delivery estimates for remote states are heavily padded** — the biggest "early delivery" states are also the slowest in absolute terms, meaning the estimate, not the logistics, is driving the perception of speed.
5. **Credit card and single-installment payments dominate** — there's clear room to grow adoption of installment plans and alternate payment types (debit, vouchers) with targeted incentives.
6. **Customer base is concentrated** — SP, RJ, and MG account for the bulk of customers and revenue, while northern states remain underpenetrated.

## Recommendations

- **Regional logistics investment:** Prioritize a regional fulfillment hub or courier partnership for the North region (RR, AP, AC, RO, AM) to cut both freight cost and delivery time.
- **Re-calibrate delivery estimates:** Tighten estimated delivery windows for remote states using real historical delivery data rather than a flat conservative buffer, to build customer trust without overpromising.
- **Time-targeted promotions:** Schedule flash sales, push notifications, and ad spend around the afternoon and night windows when purchase intent is highest.
- **Underpenetrated-state growth push:** Run targeted discounts and localized advertising in RR, AP, and AC to grow the customer base where it's currently smallest.
- **Payment mix diversification:** Offer small incentives (cashback, discounts) for debit card and installment-plan usage to reduce dependency on a single payment channel.
- **Track cancellations alongside growth:** Extend this analysis to include order cancellation/return rates alongside the growth trend, to ensure volume growth isn't offset by rising order failures.

## Tech Stack

- **SQL Engine:** Google BigQuery (Standard SQL)
- **Techniques used:** CTEs, window-style aggregations, `CASE WHEN` bucketing, `DATE_DIFF`, multi-table joins, `INFORMATION_SCHEMA` metadata queries

## Repository Structure

```
target-brazil-sql-case-study/
├── README.md          # This file — full write-up of questions, queries, insights, and recommendations
└── queries.sql         # All SQL queries in one file, organized by section
```

## About

This case study was completed as part of a Data Analytics program (Scaler Academy) and is shared here as a portfolio project for Data Analyst roles.
