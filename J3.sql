WITH RankedReviews AS (
    SELECT 
        r.order_id,
        r.review_score,
        ROW_NUMBER() OVER (
            PARTITION BY r.order_id 
            ORDER BY 
                CASE WHEN r.review_answer_timestamp IS NULL THEN 1 ELSE 0 END ASC,
                r.review_answer_timestamp DESC, 
                r.review_creation_date DESC, 
                r.review_id DESC
        ) AS rn
    FROM [Olist_DB].[dbo].[order_reviews] r
    WHERE r.review_score BETWEEN 1 AND 5
),
ValidOrderReviews AS (
    SELECT order_id, review_score
    FROM RankedReviews
    WHERE rn = 1
),
DeliveredOrdersBase AS (
    SELECT o.order_id
    FROM [Olist_DB].[dbo].[orders] o
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
),

OrderCategory AS (
    SELECT 
        oi.order_id,
        COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown') AS category_name
    FROM [Olist_DB].[dbo].[order_items] oi
    JOIN [Olist_DB].[dbo].[products] p ON oi.product_id = p.product_id
    LEFT JOIN [Olist_DB].[dbo].[category_translation] t ON p.product_category_name = t.product_category_name
    GROUP BY oi.order_id, COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown')
),
OrderData AS (
    SELECT 
        oc.category_name,
        v.order_id,
        v.review_score
    FROM OrderCategory oc
    JOIN DeliveredOrdersBase d ON oc.order_id = d.order_id
    JOIN ValidOrderReviews v ON oc.order_id = v.order_id
),
CategoryAverages AS (
    SELECT 
        category_name,
        AVG(CAST(review_score AS FLOAT)) AS category_avg
    FROM OrderData
    GROUP BY category_name
)

SELECT 
    od.category_name AS Category,
    COUNT(od.order_id) AS reviewed_orders,
    CAST(MAX(ca.category_avg) AS DECIMAL(4,2)) AS category_mean,
    SUM(CASE WHEN od.review_score < ca.category_avg THEN 1 ELSE 0 END) AS below_mean_count
FROM OrderData od
JOIN CategoryAverages ca ON od.category_name = ca.category_name
GROUP BY od.category_name
ORDER BY below_mean_count DESC, reviewed_orders DESC;