SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'product_category_translation', COUNT(*) FROM product_category_translation
UNION ALL
SELECT 'geolocation', COUNT(*) FROM geolocation;

SELECT
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN order_status != 'created' THEN 1 END) AS payment_approved,
    COUNT(CASE WHEN order_status IN ('shipped', 'delivered', 'invoiced') THEN 1 END) AS dispatched,
    COUNT(CASE WHEN order_status = 'delivered' THEN 1 END) AS delivered,
    COUNT(CASE WHEN order_status = 'delivered' 
          AND order_id IN (SELECT order_id FROM order_reviews) 
          THEN 1 END) AS reviewed
FROM orders;

SELECT
    99441 AS total_orders,
    99436 AS payment_approved,
    97899 AS dispatched,
    96478 AS delivered,
    95832 AS reviewed,
    ROUND(99436 * 100.0 / 99441, 2) AS approval_rate,
    ROUND(97899 * 100.0 / 99436, 2) AS dispatch_rate,
    ROUND(96478 * 100.0 / 97899, 2) AS delivery_rate,
    ROUND(95832 * 100.0 / 96478, 2) AS review_rate,
    ROUND(95832 * 100.0 / 99441, 2) AS end_to_end_rate;

SELECT 
    pct.product_category_name_english AS category,
    COUNT(o.order_id) AS total_orders,
    COUNT(CASE WHEN o.order_status = 'delivered' THEN 1 END) AS delivered,
    COUNT(CASE WHEN o.order_status IN ('canceled', 'unavailable') THEN 1 END) AS cancelled,
    ROUND(COUNT(CASE WHEN o.order_status IN ('canceled', 'unavailable') THEN 1 END) * 100.0 / 
          COUNT(o.order_id), 2) AS cancellation_rate
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN product_category_translation pct ON p.product_category_name = pct.product_category_name
GROUP BY pct.product_category_name_english
HAVING COUNT(o.order_id) > 100
ORDER BY cancellation_rate DESC
LIMIT 15;

SELECT 
    s.seller_state,
    COUNT(o.order_id) AS total_orders,
    COUNT(CASE WHEN o.order_status IN ('canceled', 'unavailable') THEN 1 END) AS cancelled,
    ROUND(COUNT(CASE WHEN o.order_status IN ('canceled', 'unavailable') THEN 1 END) * 100.0 / 
          COUNT(o.order_id), 2) AS cancellation_rate
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN sellers s ON oi.seller_id = s.seller_id
GROUP BY s.seller_state
HAVING COUNT(o.order_id) > 100
ORDER BY cancellation_rate DESC
LIMIT 10;