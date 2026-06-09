-- Customer Lifetime Value by RFM Segment
-- Demonstrates: CTEs, CASE WHEN segmentation, aggregate window functions, PERCENTILE

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id)                           AS order_count,
        ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_spend,
        MIN(o.order_purchase_timestamp)                      AS first_purchase,
        MAX(o.order_purchase_timestamp)                      AS last_purchase,
        EXTRACT(DAY FROM (
            MAX(o.order_purchase_timestamp) - MIN(o.order_purchase_timestamp)
        ))                                                   AS customer_lifespan_days
    FROM orders o
    JOIN customers   c  ON o.customer_id = c.customer_id
    JOIN order_items oi ON o.order_id    = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
),
clv AS (
    SELECT
        customer_unique_id,
        order_count,
        total_spend,
        customer_lifespan_days,
        -- Simple CLV: avg order value × purchase frequency
        ROUND(total_spend / NULLIF(order_count, 0), 2)       AS avg_order_value,
        ROUND(
            order_count::NUMERIC
          / NULLIF(GREATEST(customer_lifespan_days, 1), 0)
          * 365,
            2
        )                                                     AS orders_per_year,
        -- Segment by total spend percentile
        NTILE(4) OVER (ORDER BY total_spend) AS spend_quartile
    FROM customer_orders
)
SELECT
    CASE spend_quartile
        WHEN 4 THEN 'Platinum (Top 25%)'
        WHEN 3 THEN 'Gold'
        WHEN 2 THEN 'Silver'
        ELSE       'Bronze (Bottom 25%)'
    END                                             AS clv_segment,
    COUNT(*)                                        AS customers,
    ROUND(AVG(total_spend), 2)                      AS avg_lifetime_spend,
    ROUND(AVG(avg_order_value), 2)                  AS avg_order_value,
    ROUND(AVG(order_count), 2)                      AS avg_orders,
    ROUND(AVG(customer_lifespan_days), 0)           AS avg_lifespan_days,
    ROUND(SUM(total_spend), 2)                      AS segment_total_revenue,
    ROUND(
        100.0 * SUM(total_spend)
              / SUM(SUM(total_spend)) OVER (),
        1
    )                                               AS pct_of_total_revenue
FROM clv
GROUP BY 1, spend_quartile
ORDER BY spend_quartile DESC;
