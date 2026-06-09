-- Product Category Performance — Revenue vs Satisfaction Quadrant
-- Demonstrates: Multiple JOINs, COALESCE, HAVING, RANK window function, CASE quadrant logic

WITH category_metrics AS (
    SELECT
        COALESCE(t.product_category_name_english,
                 p.product_category_name, 'Unknown')         AS category,
        COUNT(DISTINCT oi.order_id)                          AS total_orders,
        COUNT(DISTINCT o.customer_id)                        AS unique_customers,
        ROUND(SUM(oi.price)::NUMERIC, 2)                     AS total_revenue,
        ROUND(AVG(oi.price)::NUMERIC, 2)                     AS avg_item_price,
        ROUND(AVG(r.review_score)::NUMERIC, 2)               AS avg_review_score,
        COUNT(CASE WHEN r.review_score <= 2 THEN 1 END)      AS low_score_count,
        ROUND(
            100.0 * COUNT(CASE WHEN r.review_score <= 2 THEN 1 END)
                  / NULLIF(COUNT(r.review_score), 0),
            1
        )                                                     AS low_score_pct
    FROM order_items oi
    JOIN products    p   ON oi.product_id         = p.product_id
    JOIN orders      o   ON oi.order_id           = o.order_id
    JOIN order_reviews r ON oi.order_id           = r.order_id
    LEFT JOIN product_category_name_translation t
                         ON p.product_category_name = t.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY 1
    HAVING COUNT(DISTINCT oi.order_id) > 100
),
revenue_median AS (
    SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_revenue) AS med_rev
    FROM category_metrics
),
satisfaction_median AS (
    SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_review_score) AS med_sat
    FROM category_metrics
)
SELECT
    cm.category,
    cm.total_orders,
    cm.total_revenue,
    cm.avg_review_score,
    cm.low_score_pct,
    RANK() OVER (ORDER BY cm.total_revenue DESC)      AS revenue_rank,
    RANK() OVER (ORDER BY cm.avg_review_score DESC)   AS satisfaction_rank,
    -- Quadrant classification for visualisation
    CASE
        WHEN cm.total_revenue >= rm.med_rev AND cm.avg_review_score >= sm.med_sat
            THEN 'Star (High Revenue, High Satisfaction)'
        WHEN cm.total_revenue >= rm.med_rev AND cm.avg_review_score <  sm.med_sat
            THEN 'Problem (High Revenue, Low Satisfaction)'
        WHEN cm.total_revenue <  rm.med_rev AND cm.avg_review_score >= sm.med_sat
            THEN 'Niche (Low Revenue, High Satisfaction)'
        ELSE
            'Laggard (Low Revenue, Low Satisfaction)'
    END AS quadrant
FROM category_metrics cm
CROSS JOIN revenue_median    rm
CROSS JOIN satisfaction_median sm
ORDER BY cm.total_revenue DESC;
