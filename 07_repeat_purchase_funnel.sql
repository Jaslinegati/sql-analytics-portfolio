-- Repeat Purchase Funnel — How Many Customers Reach Each Order Number?
-- Demonstrates: ROW_NUMBER, funnel analysis, self-referencing CTE

WITH order_sequence AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp
        ) AS order_number
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
funnel AS (
    SELECT
        order_number,
        COUNT(DISTINCT customer_unique_id) AS customers_at_this_order
    FROM order_sequence
    WHERE order_number <= 10
    GROUP BY 1
),
funnel_with_rates AS (
    SELECT
        order_number,
        customers_at_this_order,
        FIRST_VALUE(customers_at_this_order) OVER (ORDER BY order_number) AS total_customers,
        LAG(customers_at_this_order) OVER (ORDER BY order_number)         AS prev_step_customers
    FROM funnel
)
SELECT
    order_number,
    customers_at_this_order,
    -- % of all customers who reach this order number
    ROUND(100.0 * customers_at_this_order / total_customers, 2)      AS pct_of_all_customers,
    -- Drop-off from previous step
    ROUND(100.0 * (prev_step_customers - customers_at_this_order)
               / NULLIF(prev_step_customers, 0), 2)                  AS step_dropoff_pct
FROM funnel_with_rates
ORDER BY order_number;
