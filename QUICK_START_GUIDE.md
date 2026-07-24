# 🚀 Quick Start Guide — Get Running in 5 Minutes

**Step-by-step setup to run this analysis in Google BigQuery.**

---

## Prerequisites

- ✅ Google Cloud account (free tier available at [cloud.google.com](https://cloud.google.com))
- ✅ Access to BigQuery (included in free tier)
- ✅ This repository cloned or downloaded

**Estimated Time:** 5–10 minutes  
**Cost:** Free (first 1 TB query/month included in BigQuery free tier)

---

## Option A: Using Public BigQuery Dataset (Easiest)

Target Brazil data is available in BigQuery's public datasets. No setup needed!

### Step 1: Open BigQuery Console

1. Go to [console.cloud.google.com/bigquery](https://console.cloud.google.com/bigquery)
2. Sign in with your Google account (create one if needed)
3. Create a project or use an existing one

### Step 2: Locate the Public Dataset

1. In the **Explorer** panel (left side), click **+ Add Data**
2. Search for **`bigquery-public-data.thelook_ecommerce`**
3. Click to add it to your view

The dataset should now appear in your Explorer with these tables:
- `users` (similar to `customers`)
- `orders`
- `order_items`
- `events` (similar to `reviews`)
- `products`
- `distribution_centers` (similar to `sellers`)

### Step 3: Copy a Test Query

1. Open the **Editor** (main text area)
2. Copy this simple test query:

```sql
SELECT 
  COUNT(DISTINCT order_id) as total_orders,
  MIN(created_date) as start_date,
  MAX(created_date) as end_date
FROM `bigquery-public-data.thelook_ecommerce.orders`
LIMIT 100;
```

3. Click **Run** (blue button, top right)
4. Results appear in ~2–5 seconds

✅ **Success!** You're now running SQL on BigQuery.

---

## Option B: Using Your Own Target Brazil Dataset

If you have a private/imported Target Brazil dataset:

### Step 1: Import Data into BigQuery

#### Via Google Cloud Storage (GCS):
1. Upload CSV files to a GCS bucket
2. Go to BigQuery → **Create Dataset**
3. Create tables from GCS files (wizard-driven)
4. Match column names to the schema in `DATA_SCHEMA.md`

#### Via BigQuery Console:
1. Go to BigQuery → **Create Dataset** → name it `target_brazil`
2. Click **Create Table**
3. Upload CSV or select **Google Cloud Storage** source
4. Auto-detect schema or manually match to `DATA_SCHEMA.md`

### Step 2: Update Project Reference in Queries

In all queries from `queries.sql`, replace `project` with your actual project ID:

**Before:**
```sql
SELECT * FROM project.orders;
```

**After:**
```sql
SELECT * FROM `my-gcp-project.target_brazil.orders`;
```

### Step 3: Run the Queries

Copy-paste each query from `queries.sql` into the BigQuery Editor and run.

---

## Running the Analysis Queries

### Method 1: Copy-Paste Individual Queries

1. Open `queries.sql` in this repo
2. Copy a query block (e.g., **1A. Data types in customers**)
3. Paste into BigQuery **Editor**
4. Click **Run**
5. View results in the **Results** tab below

### Method 2: Save Queries as Favorites (Advanced)

1. In BigQuery Editor, click **Save**
2. Choose **Save query**
3. Name it (e.g., "2A YoY Order Growth")
4. Queries appear in left panel under **Saved queries**
5. Click any saved query to reload it

### Method 3: Use Query Scheduler (For Reports)

1. Run a query → Results tab
2. Click **Schedule** (top right)
3. Set frequency (e.g., weekly)
4. Results automatically exported to **Google Sheets** or **Cloud Storage**

---

## Understanding Query Sections

The `queries.sql` file is organized into 6 sections:

### Section 1: Initial Exploration (Queries 1A–1C)
**Purpose:** Understand data structure, date ranges, geographic spread  
**Time:** <1 second each  
**Expected:** Data types, timestamps, city/state counts

```sql
-- 1A: Check data types
SELECT table_name, column_name, data_type
FROM project.INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'customers';
```

### Section 2: In-Depth Exploration (Queries 2A–2C)
**Purpose:** Spot growth trends, seasonality, time-of-day patterns  
**Time:** 1–3 seconds each  
**Expected:** YoY growth %, monthly trends, peak shopping hours

```sql
-- 2A: YoY order growth
SELECT EXTRACT(YEAR FROM order_purchase_timestamp) AS year, COUNT(order_id) AS total_orders
FROM project.orders
GROUP BY year
ORDER BY year DESC;
```

### Section 3: Geographic Evolution (Queries 3A–3B)
**Purpose:** State-level order and customer distribution  
**Time:** 2–5 seconds each  
**Expected:** Which states growing fastest, customer concentration

### Section 4: Economic Impact (Queries 4A–4C)
**Purpose:** Revenue growth, pricing trends, freight costs by region  
**Time:** 3–8 seconds each  
**Expected:** Revenue %, state-level pricing, geographic cost disparities

### Section 5: Logistics & Delivery (Queries 5A–5D)
**Purpose:** Delivery times, freight costs, estimate accuracy  
**Time:** 2–5 seconds each  
**Expected:** States with best/worst delivery times, cost spreads

### Section 6: Payment Analysis (Queries 6A–6B)
**Purpose:** Payment method distribution, installment preferences  
**Time:** 1–3 seconds each  
**Expected:** Credit card dominance %, installment breakdown

---

## Expected Query Performance

| Query Type | Complexity | Typical Runtime | Cost |
|------------|-----------|-----------------|------|
| Simple aggregations (COUNT, MIN/MAX) | Low | 1–2 sec | $0.05 |
| Joins (2–3 tables) | Medium | 2–5 sec | $0.10–0.20 |
| Complex joins (3+ tables) + window functions | High | 3–10 sec | $0.20–0.50 |
| Full dataset scans | Very High | 5–15 sec | $0.50–1.00 |

**Total Cost to Run All Queries:** ~$5–10

---

## Interpreting Results

### Example: YoY Order Growth (Query 2A)

**Query:**
```sql
SELECT EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
       COUNT(order_id) AS total_orders
FROM project.orders
GROUP BY year
ORDER BY year DESC;
```

**Results:**
```
year    | total_orders
--------|---------------
2018    | 54,011
2017    | 45,101
2016    | 329
```

**Interpretation:**
- 2016 is partial year (launched Sept), ignore for growth calc
- 2017 → 2018: **(54,011 - 45,101) / 45,101 × 100 = +19.7% growth**
- Healthy sustained growth signal for investors/stakeholders

---

## Common Issues & Fixes

### ❌ "Table not found: project.orders"

**Fix:** Replace `project` with your actual GCP project ID:
```sql
SELECT * FROM `my-gcp-project.target_brazil.orders`;
```

### ❌ "Access Denied: Project my-gcp-project"

**Fix:** 
1. Ensure you're logged into the correct Google account
2. Go to [console.cloud.google.com](https://console.cloud.google.com)
3. Check **Project Selector** (top left) → select correct project

### ❌ "Field 'order_purchase_timestamp' is unknown"

**Fix:** Column names differ in public dataset. Use:
- `created_date` (instead of `order_purchase_timestamp`)
- Refer to `DATA_SCHEMA.md` for public dataset mappings

### ❌ Query times out (>60 seconds)

**Fix:**
1. Add time filter: `WHERE EXTRACT(YEAR FROM order_purchase_timestamp) >= 2017`
2. Reduce scope: limit to single state first
3. Use **partitioning** if running same query repeatedly

---

## Tips for Best Results

### ✅ Do's
- ✅ **Start with Section 1** to verify data is loaded
- ✅ **Run queries in order** — each builds on prior insights
- ✅ **Export results** to Google Sheets for charts/viz
- ✅ **Use LIMIT 100** when testing new queries (cheaper + faster)
- ✅ **Set up saved queries** for frequently-run analysis

### ❌ Don'ts
- ❌ **Don't run `SELECT *` without LIMIT** (slow, expensive)
- ❌ **Don't query without time filters** on large tables (will timeout)
- ❌ **Don't forget to replace `project` reference** in queries
- ❌ **Don't assume column names** — check `DATA_SCHEMA.md` first

---

## Exporting Results for Analysis

### To Google Sheets
1. Run query → **Results** tab
2. Click **Explore Data** → **Explore in Sheets**
3. Auto-creates Sheets with results
4. Build charts/visualizations in Sheets

### To CSV
1. Run query → **Results** tab
2. Click **Download** → **CSV**
3. Download to your local machine

### To Cloud Storage
1. Click **Save Results** (top right)
2. Choose **BigQuery table** or **Cloud Storage**
3. Results persist for re-use

---

## Next Steps After Setup

### 📊 1. Verify Data Loads (5 min)
- Run Query 1A (data types) → confirm columns exist
- Run Query 1B (date range) → confirm data spans 2016–2018
- Run Query 1C (cities/states) → confirm ~4K cities, 27 states

### 📈 2. Explore Growth Trends (10 min)
- Run Query 2A (YoY growth) → confirm +19.7%
- Run Query 2C (time-of-day) → confirm afternoon peak
- Run Query 4A (revenue growth) → confirm +137%

### 🗺️ 3. Deep Dive Geographic (15 min)
- Run Query 3B (customer by state) → identify concentration in SP
- Run Query 5B & 5C (freight & delivery by state) → identify cost/speed disparities
- Run Query 5D (delivery estimate accuracy) → see padding in remote states

### 💳 4. Review Payment Behavior (5 min)
- Run Query 6A (payment types) → confirm 92%+ credit card
- Run Query 6B (installments) → confirm 55%+ single payment

### 🎯 5. Generate Insights (Ongoing)
- Cross-reference `INSIGHTS_SUMMARY.md` against your query results
- Build custom queries for specific business questions
- Export top findings to Google Sheets for stakeholder presentations

---

## Resources & Support

### 📚 Documentation
- **BigQuery Docs:** [cloud.google.com/bigquery/docs](https://cloud.google.com/bigquery/docs)
- **SQL Reference:** [cloud.google.com/bigquery/docs/reference/standard-sql](https://cloud.google.com/bigquery/docs/reference/standard-sql)
- **Pricing:** [cloud.google.com/bigquery/pricing](https://cloud.google.com/bigquery/pricing)

### 🤔 Questions?
- Check `DATA_SCHEMA.md` for column details
- Review `README.md` for full analysis context
- See `INSIGHTS_SUMMARY.md` for expected findings

### 📞 Contact
**Naveen V** — vnaveen088@gmail.com  
Portfolio project for Data Analyst roles | Scaler Academy

---

## Checklist: Ready to Analyze?

- [ ] BigQuery console open & logged in
- [ ] Dataset created or public dataset added
- [ ] Test query (Query 1A) runs successfully
- [ ] Results tab shows data
- [ ] Query costs <$1 per run
- [ ] Ready to copy queries from `queries.sql`

**You're all set! 🎉 Start with Query 1A and work through each section.**

---

**Last Updated:** July 24, 2026  
**Status:** ✅ Ready for use
