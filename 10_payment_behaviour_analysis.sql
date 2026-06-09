-- Payment Behaviour — Instalment Patterns & Revenue by Payment Type
-- Demonstrates: CASE WHEN bucketing, multiple aggregations, ratio calculations

WITH payment_summary AS (
    SELECT
        op.payment_type,
        CASE
            WHEN op.payment_installments = 1  THEN 'Single payment'
            WHEN op.payment_installments <= 3 THEN '2-3 instalments'
            WHEN op.payment_installments <= 6 THEN '4-6 instalments'
            WHEN op.payment_installments <= 12 THEN '7-12 instalments'
            ELSE '12+ instalments'
        END                                                      AS instalment_band,
        COUNT(DISTINCT op.order_id)                              AS orders,
        ROUND(SUM(op.payment_value)::NUMERIC, 2)                 AS total_payment_value,
        ROUND(AVG(op.payment_value)::NUMERIC, 2)                 AS avg_payment_value,
        ROUND(AVG(op.payment_installments)::NUMERIC, 1)          AS avg_instalments,
        ROUND(AVG(r.review_score)::NUMERIC, 2)                   AS avg_review_score
    FROM order_payments op
    JOIN orders         o  ON op.order_id = o.order_id
    JOIN order_reviews  r  ON op.order_id = r.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1, 2
)
SELECT
    payment_type,
    instalment_band,
    orders,
    total_payment_value,
    avg_payment_value,
    avg_instalments,
    avg_review_score,
    ROUND(
        100.0 * orders / SUM(orders) OVER (PARTITION BY payment_type),
        1
    )                                                             AS pct_within_payment_type,
    ROUND(
        100.0 * total_payment_value
              / SUM(total_payment_value) OVER (),
        2
    )                                                             AS pct_of_total_revenue
FROM payment_summary
ORDER BY payment_type, avg_payment_value DESC;
