CREATE VIEW vw_sla AS
SELECT
    o.order_id,
    c.customer_state,
    ROUND(EXTRACT(EPOCH FROM (order_delivered_customer_date - 
          order_purchase_timestamp)) / 86400, 1) AS actual_delivery_days,
    ROUND(EXTRACT(EPOCH FROM (order_estimated_delivery_date - 
          order_purchase_timestamp)) / 86400, 1) AS estimated_delivery_days,
    CASE
        WHEN order_delivered_customer_date IS NULL THEN 'Not Delivered'
        WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On Time'
        ELSE 'Late'
    END AS sla_flag
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE order_status = 'delivered';

CREATE VIEW vw_rfm AS
WITH rfm_base AS (
    SELECT
        c.customer_unique_id,
        c.customer_state,
        ROUND(EXTRACT(EPOCH FROM (
            '2018-10-01'::timestamp - MAX(o.order_purchase_timestamp))) / 86400) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(p.payment_value) AS monetary
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, c.customer_state
),
rfm_scored AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
)
SELECT *,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champion'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customer'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
        ELSE 'Potential'
    END AS segment
FROM rfm_scored;

CREATE VIEW vw_monthly_orders AS
SELECT
    DATE_TRUNC('month', order_purchase_timestamp) AS order_month,
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN order_status = 'delivered' THEN 1 END) AS delivered_orders,
    ROUND(SUM(p.payment_value)::numeric, 2) AS total_revenue
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
ORDER BY order_month;

CREATE VIEW vw_cohort AS
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
        EXTRACT(YEAR FROM AGE(co.order_month, ch.cohort_month)) * 12 +
        EXTRACT(MONTH FROM AGE(co.order_month, ch.cohort_month)) AS month_number
    FROM customer_orders co
    JOIN cohorts ch ON co.customer_unique_id = ch.customer_unique_id
)
SELECT
    TO_CHAR(cohort_month, 'YYYY-MM') AS cohort,
    month_number::INT AS month_number,
    COUNT(DISTINCT customer_unique_id) AS customers
FROM cohort_data
WHERE month_number BETWEEN 0 AND 12
GROUP BY cohort_month, month_number
ORDER BY cohort_month, month_number;

CREATE OR REPLACE VIEW vw_cohort AS
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
        EXTRACT(YEAR FROM AGE(co.order_month, ch.cohort_month)) * 12 +
        EXTRACT(MONTH FROM AGE(co.order_month, ch.cohort_month)) AS month_number
    FROM customer_orders co
    JOIN cohorts ch ON co.customer_unique_id = ch.customer_unique_id
),
cohort_size AS (
    SELECT cohort_month, COUNT(DISTINCT customer_unique_id) AS total_customers
    FROM cohorts
    GROUP BY cohort_month
)
SELECT
    TO_CHAR(cd.cohort_month, 'YYYY-MM') AS cohort,
    cd.month_number::INT AS month_number,
    COUNT(DISTINCT cd.customer_unique_id) AS customers,
    cs.total_customers AS cohort_size,
    ROUND(COUNT(DISTINCT cd.customer_unique_id) * 100.0 / cs.total_customers, 2) AS retention_pct
FROM cohort_data cd
JOIN cohort_size cs ON cd.cohort_month = cs.cohort_month
WHERE cd.month_number BETWEEN 0 AND 12
GROUP BY cd.cohort_month, cd.month_number, cs.total_customers
ORDER BY cd.cohort_month, cd.month_number;