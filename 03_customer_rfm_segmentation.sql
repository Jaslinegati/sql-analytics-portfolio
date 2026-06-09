-- RFM Segmentation using Window Functions
-- Demonstrates: NTILE, CURRENT_DATE, multiple CTEs chained, CASE WHEN logic

WITH reference AS (
    SELECT MAX(order_purchase_timestamp) + INTERVAL '1 day' AS ref_date
    FROM orders
    WHERE order_status = 'delivered'
),
customer_rfm AS (
    SELECT
        c.customer_unique_id,
        -- Recency: days since last purchase
        EXTRACT(DAY FROM (ref.ref_date - MAX(o.order_purchase_timestamp))) AS recency,
        -- Frequency: number of orders
        COUNT(DISTINCT o.order_id)                                          AS frequency,
        -- Monetary: total spend
        ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2)                AS monetary
    FROM orders o
    JOIN customers  c   ON o.customer_id    = c.customer_id
    JOIN order_items oi ON o.order_id       = oi.order_id
    CROSS JOIN reference ref
    WHERE o.order_status = 'delivered'
    GROUP BY 1, ref.ref_date
),
rfm_scores AS (
    SELECT
        customer_unique_id,
        recency,
        frequency,
        monetary,
        -- Score 1-5 (5 = best). Recency is inverted: lower days = higher score
        NTILE(5) OVER (ORDER BY recency DESC)   AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)  AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)   AS m_score
    FROM customer_rfm
)
SELECT
    customer_unique_id,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    r_score + f_score + m_score AS total_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champion'
        WHEN r_score >= 3 AND f_score >= 3                  THEN 'Loyal'
        WHEN r_score >= 4 AND f_score <= 2                  THEN 'New Customer'
        WHEN r_score >= 3 AND f_score <= 2 AND m_score >= 3 THEN 'Potential Loyalist'
        WHEN r_score <= 2 AND f_score >= 3                  THEN 'At Risk'
        WHEN r_score <= 2 AND m_score >= 3                  THEN 'Cannot Lose Them'
        WHEN r_score <= 2                                   THEN 'Churned'
        ELSE 'Needs Attention'
    END AS segment
FROM rfm_scores
ORDER BY total_score DESC;
