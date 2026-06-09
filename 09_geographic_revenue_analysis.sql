-- Geographic Revenue & Customer Distribution
-- Demonstrates: GROUP BY multiple dimensions, RANK partitioned by region, ROLLUP

WITH state_metrics AS (
    SELECT
        c.customer_state                                     AS state,
        COUNT(DISTINCT c.customer_unique_id)                 AS customers,
        COUNT(DISTINCT o.order_id)                          AS orders,
        ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS revenue,
        ROUND(AVG(oi.price + oi.freight_value)::NUMERIC, 2) AS avg_order_value,
        ROUND(AVG(r.review_score)::NUMERIC, 2)              AS avg_review_score,
        ROUND(AVG(
            EXTRACT(DAY FROM (
                o.order_delivered_customer_date - o.order_purchase_timestamp
            ))
        )::NUMERIC, 1)                                       AS avg_delivery_days
    FROM orders       o
    JOIN customers    c  ON o.customer_id = c.customer_id
    JOIN order_items  oi ON o.order_id    = oi.order_id
    JOIN order_reviews r ON o.order_id    = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
    GROUP BY 1
)
SELECT
    state,
    customers,
    orders,
    revenue,
    avg_order_value,
    avg_review_score,
    avg_delivery_days,
    RANK() OVER (ORDER BY revenue DESC)          AS revenue_rank,
    RANK() OVER (ORDER BY avg_review_score DESC) AS satisfaction_rank,
    ROUND(
        100.0 * revenue / SUM(revenue) OVER (),
        2
    )                                            AS pct_of_total_revenue,
    -- Flag states where delivery is slow AND satisfaction is low
    CASE
        WHEN avg_delivery_days > 20 AND avg_review_score < 4.0
            THEN 'Fulfilment Risk'
        WHEN avg_review_score >= 4.3
            THEN 'High Satisfaction'
        ELSE 'Standard'
    END AS state_flag
FROM state_metrics
ORDER BY revenue DESC;
