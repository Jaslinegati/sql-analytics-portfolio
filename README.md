# SQL Analytics Portfolio
### 10 production-style queries demonstrating advanced SQL for data analysis

**Database:** PostgreSQL / DuckDB compatible  
**Context:** Olist Brazilian E-Commerce dataset, 100k orders, 2016–2018

Each query solves a real business question. Written to the standard you'd find in a data team's query library, CTEs for readability, window functions for ranking and time-series, documented logic.

---

## Queries

| # | File | Business Question | Key Techniques |
|---|------|-------------------|----------------|
| 01 | [monthly_revenue_mom_growth](01_monthly_revenue_mom_growth.sql) | How is revenue trending month over month? | `LAG`, running totals, `DATE_TRUNC` |
| 02 | [cohort_retention](02_cohort_retention.sql) | What % of customers return after their first purchase? | Multi-CTE, cohort logic, `EXTRACT` |
| 03 | [customer_rfm_segmentation](03_customer_rfm_segmentation.sql) | How do we segment customers by value? | `NTILE`, chained CTEs, `CASE WHEN` |
| 04 | [product_category_performance](04_product_category_performance.sql) | Which categories have high revenue but low satisfaction? | Multi-table JOIN, `RANK`, quadrant logic, `PERCENTILE_CONT` |
| 05 | [delivery_delay_impact](05_delivery_delay_impact.sql) | How does delivery timing affect review scores? | Date arithmetic, `CASE` bucketing, subquery |
| 06 | [customer_lifetime_value](06_customer_lifetime_value.sql) | What is each customer segment worth over their lifetime? | `NTILE`, CLV formula, `SUM() OVER()` |
| 07 | [repeat_purchase_funnel](07_repeat_purchase_funnel.sql) | How many customers reach their 2nd, 3rd, 4th order? | `ROW_NUMBER`, funnel analysis, `FIRST_VALUE` |
| 08 | [seller_performance_ranking](08_seller_performance_ranking.sql) | Who are the top-performing sellers? | `DENSE_RANK`, `PERCENT_RANK`, composite scoring |
| 09 | [geographic_revenue_analysis](09_geographic_revenue_analysis.sql) | Which states drive the most revenue, and which have fulfilment problems? | Partitioned `RANK`, `SUM() OVER()`, multi-flag logic |
| 10 | [payment_behaviour_analysis](10_payment_behaviour_analysis.sql) | How do payment type and instalment patterns affect order value? | `PARTITION BY`, instalment bucketing, ratio calculations |

---

## SQL Techniques Demonstrated

| Technique | Queries |
|-----------|---------|
| Window functions (`LAG`, `LEAD`, `RANK`, `DENSE_RANK`, `NTILE`, `PERCENT_RANK`) | 01, 03, 06, 07, 08, 09 |
| CTEs (`WITH` clause, chained CTEs) | 01, 02, 03, 04, 06, 07, 08 |
| Date arithmetic and `DATE_TRUNC` | 01, 02, 05 |
| Subqueries | 05 |
| `CASE WHEN` segmentation and bucketing | 03, 04, 05, 06, 08, 09, 10 |
| `PERCENTILE_CONT` | 04, 06 |
| Multi-table JOINs (4+ tables) | 04, 08, 09 |
| Aggregate window functions (`SUM OVER`, `FIRST_VALUE`) | 01, 06, 07, 09, 10 |
| `NULLIF` for safe division | 01, 03, 07 |
| `CROSS JOIN` for scalar reference values | 03, 04 |

---

## How to Run

These queries are written for **PostgreSQL** syntax and are also compatible with **DuckDB**.

To run against the Olist dataset using DuckDB in Python:

```python
import duckdb
import pandas as pd

# Load CSVs
con = duckdb.connect()
con.execute("CREATE TABLE orders    AS SELECT * FROM read_csv_auto('olist_orders_dataset.csv')")
con.execute("CREATE TABLE customers AS SELECT * FROM read_csv_auto('olist_customers_dataset.csv')")
con.execute("CREATE TABLE order_items AS SELECT * FROM read_csv_auto('olist_order_items_dataset.csv')")
con.execute("CREATE TABLE order_reviews AS SELECT * FROM read_csv_auto('olist_order_reviews_dataset.csv')")
con.execute("CREATE TABLE products  AS SELECT * FROM read_csv_auto('olist_products_dataset.csv')")

# Run any query
with open('01_monthly_revenue_mom_growth.sql') as f:
    result = con.execute(f.read()).df()
print(result.head())
```

Dataset: [Olist Brazilian E-Commerce, Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

---

*Jasline Mwita · Data Analyst & Data Scientist*
