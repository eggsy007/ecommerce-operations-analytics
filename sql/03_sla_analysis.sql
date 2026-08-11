SELECT
    order_id,
    order_purchase_timestamp,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    ROUND(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp)) 
          / 86400, 1) AS actual_delivery_days,
    ROUND(EXTRACT(EPOCH FROM (order_estimated_delivery_date - order_purchase_timestamp)) 
          / 86400, 1) AS estimated_delivery_days,
    CASE 
        WHEN order_delivered_customer_date IS NULL THEN 'Not Delivered'
        WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On Time'
        ELSE 'Late'
    END AS sla_flag
FROM orders
WHERE order_status = 'delivered';

SELECT
    sla_flag,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage,
    ROUND(AVG(actual_delivery_days), 1) AS avg_delivery_days
FROM (
    SELECT
        ROUND(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp)) 
              / 86400, 1) AS actual_delivery_days,
        CASE 
            WHEN order_delivered_customer_date IS NULL THEN 'Not Delivered'
            WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On Time'
            ELSE 'Late'
        END AS sla_flag
    FROM orders
    WHERE order_status = 'delivered'
) subquery
GROUP BY sla_flag
ORDER BY order_count DESC;

SELECT
    c.customer_state,
    COUNT(*) AS total_delivered,
    COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
               THEN 1 END) AS late_orders,
    ROUND(COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
                     THEN 1 END) * 100.0 / COUNT(*), 2) AS late_rate,
    ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - 
              o.order_purchase_timestamp)) / 86400), 1) AS avg_delivery_days
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
HAVING COUNT(*) > 100
ORDER BY late_rate DESC
LIMIT 10;

SELECT
    pct.product_category_name_english AS category,
    COUNT(*) AS total_delivered,
    COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
               THEN 1 END) AS late_orders,
    ROUND(COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
                     THEN 1 END) * 100.0 / COUNT(*), 2) AS late_rate
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN product_category_translation pct ON p.product_category_name = pct.product_category_name
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY pct.product_category_name_english
HAVING COUNT(*) > 200
ORDER BY late_rate DESC
LIMIT 10;