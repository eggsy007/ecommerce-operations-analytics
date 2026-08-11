WITH rfm_base AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS last_order_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(p.payment_value) AS monetary
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    customer_unique_id,
    ROUND(EXTRACT(EPOCH FROM (
        '2018-10-01'::timestamp - last_order_date)) / 86400) AS recency_days,
    frequency,
    ROUND(monetary::numeric, 2) AS monetary
FROM rfm_base
ORDER BY monetary DESC
LIMIT 10;

WITH rfm_base AS (
    SELECT
        c.customer_unique_id,
        ROUND(EXTRACT(EPOCH FROM (
            '2018-10-01'::timestamp - MAX(o.order_purchase_timestamp))) / 86400) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(p.payment_value) AS monetary
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
rfm_scored AS (
    SELECT
        customer_unique_id,
        recency_days,
        frequency,
        ROUND(monetary::numeric, 2) AS monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
)
SELECT
    customer_unique_id,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champion'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customer'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
        ELSE 'Potential'
    END AS segment
FROM rfm_scored
ORDER BY monetary DESC
LIMIT 15;

WITH rfm_base AS (
    SELECT
        c.customer_unique_id,
        ROUND(EXTRACT(EPOCH FROM (
            '2018-10-01'::timestamp - MAX(o.order_purchase_timestamp))) / 86400) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(p.payment_value) AS monetary
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
rfm_scored AS (
    SELECT
        customer_unique_id,
        recency_days,
        frequency,
        ROUND(monetary::numeric, 2) AS monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
)
SELECT
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champion'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customer'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
        ELSE 'Potential'
    END AS segment,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage,
    ROUND(AVG(monetary)::numeric, 2) AS avg_monetary,
    ROUND(AVG(recency_days)::numeric, 0) AS avg_recency_days
FROM rfm_scored
GROUP BY segment
ORDER BY customer_count DESC;

CREATE VIEW vw_funnel AS
SELECT
    'Order Placed' AS stage, 1 AS stage_order, COUNT(*) AS order_count FROM orders
UNION ALL
SELECT 'Payment Approved', 2, COUNT(*) FROM orders WHERE order_status != 'created'
UNION ALL
SELECT 'Dispatched', 3, COUNT(*) FROM orders WHERE order_status IN ('shipped','delivered','invoiced')
UNION ALL
SELECT 'Delivered', 4, COUNT(*) FROM orders WHERE order_status = 'delivered'
UNION ALL
SELECT 'Reviewed', 5, COUNT(*) FROM orders WHERE order_status = 'delivered'
AND order_id IN (SELECT order_id FROM order_reviews);