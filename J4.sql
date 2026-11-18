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

OverallLowRatingRate AS (
    SELECT 
        SUM(CASE WHEN v.review_score IN (1, 2) THEN 1.0 ELSE 0.0 END) / COUNT(v.order_id) AS overall_rate
    FROM DeliveredOrdersBase d
    JOIN ValidOrderReviews v ON d.order_id = v.order_id
),

ProductCategories AS (
    SELECT 
        p.product_id,
        COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown') AS category_name
    FROM [Olist_DB].[dbo].[products] p
    LEFT JOIN [Olist_DB].[dbo].[category_translation] t ON p.product_category_name = t.product_category_name
),
OrderItemsCategory AS (
    SELECT 
        oi.order_id,
        oi.seller_id,
        oi.product_id,
        pc.category_name
    FROM [Olist_DB].[dbo].[order_items] oi
    JOIN ProductCategories pc ON oi.product_id = pc.product_id
),
OrderCategoryCount AS (
    SELECT 
        order_id,
        MAX(category_name) AS category_name,
        COUNT(DISTINCT category_name) AS distinct_categories_count
    FROM OrderItemsCategory
    GROUP BY order_id
),
SingleCategoryOrders AS (
    SELECT 
        oc.order_id,
        oc.category_name,
        v.review_score
    FROM OrderCategoryCount oc
    JOIN DeliveredOrdersBase d ON oc.order_id = d.order_id
    JOIN ValidOrderReviews v ON oc.order_id = v.order_id
    WHERE oc.distinct_categories_count = 1
),

TargetHighLowRatingCategories AS (
    SELECT 
        sco.category_name
    FROM SingleCategoryOrders sco
    GROUP BY sco.category_name
    HAVING COUNT(sco.order_id) >= 30
       AND SUM(CASE WHEN sco.review_score IN (1, 2) THEN 1.0 ELSE 0.0 END) / COUNT(sco.order_id) > (SELECT overall_rate FROM OverallLowRatingRate)
)

SELECT 
    oi.seller_id,
    oic.category_name AS exposed_category,
    COUNT(DISTINCT oi.order_id) AS seller_orders_in_category,
    SUM(CASE WHEN v.review_score IN (1, 2) THEN 1 ELSE 0 END) as seller_low_ratings_in_category,
    CAST(SUM(CASE WHEN v.review_score IN (1, 2) THEN 1.0 ELSE 0.0 END) * 100.0 / NULLIF(COUNT(v.order_id), 0) AS DECIMAL(5,2)) AS seller_low_rating_share_pct
FROM [Olist_DB].[dbo].[order_items] oi
JOIN OrderItemsCategory oic ON oi.order_id = oic.order_id AND oi.seller_id = oic.seller_id AND oi.product_id = oic.product_id
JOIN DeliveredOrdersBase d ON oi.order_id = d.order_id
LEFT JOIN ValidOrderReviews v ON oi.order_id = v.order_id
WHERE oic.category_name IN (SELECT category_name FROM TargetHighLowRatingCategories)
GROUP BY oi.seller_id, oic.category_name
ORDER BY seller_orders_in_category DESC, seller_low_ratings_in_category DESC;