-- Seller Performance Ranking with Percentile Bands
-- Demonstrates: DENSE_RANK, PERCENT_RANK, multiple aggregations, performance tiers

WITH seller_metrics AS (
    SELECT
        oi.seller_id,
        COUNT(DISTINCT oi.order_id)                          AS total_orders,
        COUNT(DISTINCT o.customer_id)                        AS unique_customers,
        ROUND(SUM(oi.price)::NUMERIC, 2)                     AS total_revenue,
        ROUND(AVG(oi.price)::NUMERIC, 2)                     AS avg_item_price,
        ROUND(AVG(r.review_score)::NUMERIC, 2)               AS avg_review_score,
        ROUND(AVG(
            EXTRACT(DAY FROM (
                o.order_delivered_customer_date
              - o.order_purchase_timestamp
            ))
        )::NUMERIC, 1)                                       AS avg_delivery_days,
        COUNT(CASE WHEN r.review_score <= 2 THEN 1 END)      AS negative_reviews
    FROM order_items   oi
    JOIN orders         o  ON oi.order_id   = o.order_id
    JOIN order_reviews  r  ON oi.order_id   = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
    GROUP BY 1
    HAVING COUNT(DISTINCT oi.order_id) >= 20  -- minimum order threshold
)
SELECT
    seller_id,
    total_orders,
    total_revenue,
    avg_review_score,
    avg_delivery_days,
    negative_reviews,
    DENSE_RANK() OVER (ORDER BY total_revenue DESC)       AS revenue_rank,
    DENSE_RANK() OVER (ORDER BY avg_review_score DESC)    AS satisfaction_rank,
    ROUND(PERCENT_RANK() OVER (ORDER BY total_revenue) * 100, 1) AS revenue_percentile,
    -- Composite score: weighted revenue rank + satisfaction rank
    CASE
        WHEN avg_review_score >= 4.5 AND total_revenue >= 10000 THEN 'Elite Seller'
        WHEN avg_review_score >= 4.0 AND total_revenue >= 5000  THEN 'Top Performer'
        WHEN avg_review_score >= 3.5                            THEN 'Solid Seller'
        WHEN avg_review_score < 3.0                             THEN 'At Risk'
        ELSE 'Standard'
    END AS seller_tier
FROM seller_metrics
ORDER BY total_revenue DESC;
