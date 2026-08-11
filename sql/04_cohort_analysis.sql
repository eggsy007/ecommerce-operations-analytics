SELECT
    customer_unique_id,
    MIN(DATE_TRUNC('month', o.order_purchase_timestamp)) AS cohort_month
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY customer_unique_id;

WITH cohorts AS (
    SELECT
        c.customer_unique_id,
        MIN(DATE_TRUNC('month', o.order_purchase_timestamp)) AS cohort_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
),
customer_orders AS (
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
),
cohort_data AS (
    SELECT
        co.customer_unique_id,
        ch.cohort_month,
        co.order_month,
        EXTRACT(YEAR FROM AGE(co.order_month, ch.cohort_month)) * 12 +
        EXTRACT(MONTH FROM AGE(co.order_month, ch.cohort_month)) AS month_number
    FROM customer_orders co
    JOIN cohorts ch ON co.customer_unique_id = ch.customer_unique_id
)
SELECT
    TO_CHAR(cohort_month, 'YYYY-MM') AS cohort,
    COUNT(DISTINCT customer_unique_id) AS cohort_size,
    COUNT(DISTINCT CASE WHEN month_number = 0 THEN customer_unique_id END) AS month_0,
    COUNT(DISTINCT CASE WHEN month_number = 1 THEN customer_unique_id END) AS month_1,
    COUNT(DISTINCT CASE WHEN month_number = 2 THEN customer_unique_id END) AS month_2,
    COUNT(DISTINCT CASE WHEN month_number = 3 THEN customer_unique_id END) AS month_3,
    COUNT(DISTINCT CASE WHEN month_number = 6 THEN customer_unique_id END) AS month_6,
    COUNT(DISTINCT CASE WHEN month_number = 12 THEN customer_unique_id END) AS month_12
FROM cohort_data
GROUP BY cohort_month
ORDER BY cohort_month
LIMIT 15;