WITH OrderReviewPaymentStatus AS (
    SELECT 
        o.order_id,
        FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS purchase_month,
        CASE WHEN EXISTS (
            SELECT 1 FROM [Olist_DB].[dbo].[order_reviews] r 
            WHERE r.order_id = o.order_id AND r.review_score IS NOT NULL
        ) THEN 1 ELSE 0 END AS has_review,
        CASE WHEN EXISTS (
            SELECT 1 FROM [Olist_DB].[dbo].[order_payments] p 
            WHERE p.order_id = o.order_id
        ) THEN 1 ELSE 0 END AS has_payment
    FROM [Olist_DB].[dbo].[orders] o
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01' 
      AND o.order_purchase_timestamp < '2018-09-01'
)
SELECT 
    purchase_month,
    COUNT(order_id) AS total_delivered_orders,
    SUM(has_review) AS orders_with_review,
    COUNT(order_id) - SUM(has_review) AS orders_without_review,
    CAST(SUM(has_review) * 100.0 / COUNT(order_id) AS DECIMAL(5,2)) AS review_coverage_pct,
    SUM(has_payment) AS orders_with_payment,
    COUNT(order_id) - SUM(has_payment) AS orders_without_payment
FROM OrderReviewPaymentStatus
GROUP BY purchase_month
ORDER BY purchase_month;