SELECT 
    CASE 
        WHEN oi.price < 50 THEN '1. Low Price (<50)'
        WHEN oi.price BETWEEN 50 AND 200 THEN '2. Medium Price (50-200)'
        ELSE '3. High Price (>200)'
    END AS price_category,
    COUNT(DISTINCT r.order_id) AS total_reviewed_orders,
    SUM(CASE WHEN r.review_score IN (1, 2) THEN 1 ELSE 0 END) AS low_rating_count,
    CAST(SUM(CASE WHEN r.review_score IN (1, 2) THEN 1.0 ELSE 0.0 END) * 100.0 / COUNT(DISTINCT r.order_id) AS DECIMAL(5,2)) AS low_rating_pct
FROM [Olist_DB].[dbo].[order_items] oi
JOIN [Olist_DB].[dbo].[order_reviews] r ON oi.order_id = r.order_id
GROUP BY 
    CASE 
        WHEN oi.price < 50 THEN '1. Low Price (<50)'
        WHEN oi.price BETWEEN 50 AND 200 THEN '2. Medium Price (50-200)'
        ELSE '3. High Price (>200)'
    END
ORDER BY price_category ASC;