-- Delivery Delay Impact on Customer Satisfaction
-- Demonstrates: DATE_DIFF, CASE bucketing, aggregation, subquery comparison

SELECT
    CASE
        WHEN delivered_early_days >= 3              THEN '3+ days early'
        WHEN delivered_early_days BETWEEN 1 AND 2   THEN '1-2 days early'
        WHEN delivered_early_days = 0               THEN 'Exactly on time'
        WHEN delay_days BETWEEN 1 AND 3             THEN '1-3 days late'
        WHEN delay_days BETWEEN 4 AND 7             THEN '4-7 days late'
        WHEN delay_days > 7                         THEN 'Over a week late'
        ELSE 'On time'
    END                                             AS delivery_bucket,
    COUNT(*)                                        AS orders,
    ROUND(AVG(r.review_score), 2)                   AS avg_review_score,
    ROUND(100.0 * SUM(CASE WHEN r.review_score >= 4 THEN 1 ELSE 0 END)
              / COUNT(*), 1)                        AS positive_review_pct,
    ROUND(100.0 * SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END)
              / COUNT(*), 1)                        AS negative_review_pct
FROM (
    SELECT
        o.order_id,
        -- Days late (positive = late, negative = early)
        EXTRACT(DAY FROM (
            o.order_delivered_customer_date - o.order_estimated_delivery_date
        ))                                          AS delay_days,
        GREATEST(0, EXTRACT(DAY FROM (
            o.order_estimated_delivery_date - o.order_delivered_customer_date
        )))                                         AS delivered_early_days
    FROM orders o
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
) delivery_data
JOIN order_reviews r ON delivery_data.order_id = r.order_id
GROUP BY 1
ORDER BY avg_review_score DESC;
