-- Monthly Revenue with Month-over-Month Growth
-- Demonstrates: DATE_TRUNC, window functions (LAG), CTEs, NULLIF

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)      AS month,
        COUNT(DISTINCT o.order_id)                           AS orders,
        COUNT(DISTINCT c.customer_unique_id)                 AS customers,
        ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS revenue
    FROM orders o
    JOIN customers c    ON o.customer_id    = c.customer_id
    JOIN order_items oi ON o.order_id       = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT
    month,
    orders,
    customers,
    revenue,
    LAG(revenue) OVER (ORDER BY month)                        AS prev_month_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
              / NULLIF(LAG(revenue) OVER (ORDER BY month), 0),
        1
    )                                                          AS revenue_growth_pct,
    SUM(revenue) OVER (ORDER BY month ROWS UNBOUNDED PRECEDING) AS running_total
FROM monthly_revenue
ORDER BY month;
