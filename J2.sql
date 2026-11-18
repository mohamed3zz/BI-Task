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
    SELECT 
        o.order_id,
        FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS order_month
    FROM [Olist_DB].[dbo].[orders] o
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
),
MonthlyAggregatesBase AS (
    SELECT 
        d.order_month,
        COUNT(d.order_id) AS total_delivered_orders,
        SUM(CASE WHEN v.review_score IS NOT NULL THEN 1 ELSE 0 END) AS reviewed_orders_count,
        CAST(AVG(CAST(v.review_score AS FLOAT)) AS DECIMAL(4,2)) AS monthly_mean_score,
        SUM(CASE WHEN v.review_score IN (1, 2) THEN 1 ELSE 0 END) AS low_rated_orders_count
    FROM DeliveredOrdersBase d
    LEFT JOIN ValidOrderReviews v ON d.order_id = v.order_id
    GROUP BY d.order_month
),
CalculatedMetrics AS (
    SELECT 
        order_month,
        total_delivered_orders,
        reviewed_orders_count,
        monthly_mean_score,
        CAST(reviewed_orders_count * 100.0 / NULLIF(total_delivered_orders, 0) AS DECIMAL(5,2)) AS review_coverage_pct,
        CAST(low_rated_orders_count * 100.0 / NULLIF(reviewed_orders_count, 0) AS DECIMAL(5,2)) AS low_rating_rate_pct
    FROM MonthlyAggregatesBase
)
SELECT 
    order_month,
    total_delivered_orders,
    monthly_mean_score,
    low_rating_rate_pct,
    review_coverage_pct,
    
    CAST(monthly_mean_score - LAG(monthly_mean_score, 1) OVER (ORDER BY order_month) AS DECIMAL(4,2)) AS score_change_units,
    
    CAST(low_rating_rate_pct - LAG(low_rating_rate_pct, 1) OVER (ORDER BY order_month) AS DECIMAL(5,2)) AS low_rating_rate_change_pp,
    
    CAST(review_coverage_pct - LAG(review_coverage_pct, 1) OVER (ORDER BY order_month) AS DECIMAL(5,2)) AS review_coverage_change_pp
FROM CalculatedMetrics
ORDER BY order_month ASC;