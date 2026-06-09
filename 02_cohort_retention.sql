-- Cohort Retention Analysis
-- Demonstrates: CTEs, DATE_TRUNC, self-join, window functions, EXTRACT

WITH first_orders AS (
    -- Each customer's cohort = the month of their first purchase
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month', MIN(o.order_purchase_timestamp)) AS cohort_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
),
customer_activity AS (
    -- Every month a customer was active
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS activity_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
cohort_data AS (
    SELECT
        f.cohort_month,
        EXTRACT(YEAR  FROM AGE(a.activity_month, f.cohort_month)) * 12
      + EXTRACT(MONTH FROM AGE(a.activity_month, f.cohort_month)) AS period_number,
        COUNT(DISTINCT a.customer_unique_id)                        AS retained_customers
    FROM first_orders f
    JOIN customer_activity a ON f.customer_unique_id = a.customer_unique_id
    GROUP BY 1, 2
),
cohort_sizes AS (
    SELECT cohort_month, retained_customers AS cohort_size
    FROM cohort_data
    WHERE period_number = 0
)
SELECT
    cd.cohort_month,
    cd.period_number,
    cd.retained_customers,
    cs.cohort_size,
    ROUND(100.0 * cd.retained_customers / cs.cohort_size, 2) AS retention_pct
FROM cohort_data   cd
JOIN cohort_sizes  cs ON cd.cohort_month = cs.cohort_month
ORDER BY 1, 2;
