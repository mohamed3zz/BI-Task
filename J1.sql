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
OrderReviewMapping AS (
    SELECT 
        d.order_id,
        v.review_score
    FROM DeliveredOrdersBase d
    LEFT JOIN ValidOrderReviews v ON d.order_id = v.order_id
)

SELECT 
    CAST(v.review_score AS VARCHAR(20)) AS review_category,
    COUNT(v.order_id) AS order_count,
    CAST(COUNT(v.order_id) * 100.0 / (SELECT COUNT(*) FROM DeliveredOrdersBase) AS DECIMAL(5,2)) AS percentage_of_total_delivered
FROM OrderReviewMapping m
JOIN ValidOrderReviews v ON m.order_id = v.order_id
GROUP BY v.review_score

UNION ALL

SELECT 
    'Missing Review' AS review_category,
    COUNT(order_id) AS order_count,
    CAST(COUNT(order_id) * 100.0 / (SELECT COUNT(*) FROM DeliveredOrdersBase) AS DECIMAL(5,2)) AS percentage_of_total_delivered
FROM OrderReviewMapping
WHERE review_score IS NULL

ORDER BY review_category ASC;