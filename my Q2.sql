SELECT 
    CASE 
        WHEN oi.freight_value = 0 THEN '1. Free Shipping'
        ELSE '2. Paid Shipping'
    END AS shipping_type,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    SUM(CASE WHEN r.review_score IN (1, 2) THEN 1 ELSE 0 END) AS low_rating_count,
    CAST(SUM(CASE WHEN r.review_score IN (1, 2) THEN 1.0 ELSE 0.0 END) * 100.0 / COUNT(DISTINCT oi.order_id) AS DECIMAL(5,2)) AS low_rating_pct
FROM [Olist_DB].[dbo].[order_items] oi
JOIN [Olist_DB].[dbo].[order_reviews] r ON oi.order_id = r.order_id
WHERE r.review_score BETWEEN 1 AND 5
GROUP BY 
    CASE 
        WHEN oi.freight_value = 0 THEN '1. Free Shipping'
        ELSE '2. Paid Shipping'
    END;