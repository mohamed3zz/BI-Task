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
        o.customer_id,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
    FROM [Olist_DB].[dbo].[orders] o
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
),
OrderFinancials AS (
    SELECT 
        order_id,
        SUM(price) AS total_price,
        SUM(freight_value) AS total_freight
    FROM [Olist_DB].[dbo].[order_items]
    GROUP BY order_id
),

DeliveryAnalysis AS (
    SELECT 
        CASE 
            WHEN d.order_delivered_customer_date <= d.order_estimated_delivery_date THEN '1. On Time / Early'
            WHEN DATEDIFF(day, d.order_estimated_delivery_date, d.order_delivered_customer_date) BETWEEN 1 AND 7 THEN '2. Delayed (1-7 Days)'
            ELSE '3. Heavily Delayed (>7 Days)'
        END AS delivery_band,
        COUNT(d.order_id) AS sample_size,
        CAST(AVG(CAST(v.review_score AS FLOAT)) AS DECIMAL(4,2)) AS mean_score,
        CAST(SUM(CASE WHEN v.review_score IN (1, 2) THEN 1.0 ELSE 0.0 END) * 100.0 / COUNT(v.order_id) AS DECIMAL(5,2)) AS low_rating_rate_pct
    FROM DeliveredOrdersBase d
    JOIN ValidOrderReviews v ON d.order_id = v.order_id
    GROUP BY 
        CASE 
            WHEN d.order_delivered_customer_date <= d.order_estimated_delivery_date THEN '1. On Time / Early'
            WHEN DATEDIFF(day, d.order_estimated_delivery_date, d.order_delivered_customer_date) BETWEEN 1 AND 7 THEN '2. Delayed (1-7 Days)'
            ELSE '3. Heavily Delayed (>7 Days)'
        END
)

SELECT 'Delivery Band Analysis' AS dimension_type, delivery_band AS segment_name, sample_size, mean_score, low_rating_rate_pct
FROM DeliveryAnalysis
ORDER BY low_rating_rate_pct DESC;


----------------------------------------------------------------------------------------------------


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
    SELECT o.order_id, o.customer_id
    FROM [Olist_DB].[dbo].[orders] o
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
),
OrderFinancials AS (
    SELECT 
        order_id,
        SUM(price) AS total_price,
        SUM(freight_value) AS total_freight
    FROM [Olist_DB].[dbo].[order_items]
    GROUP BY order_id
)

SELECT 
    'Customer State Analysis' AS dimension_type,
    c.customer_state AS segment_name,
    COUNT(d.order_id) AS sample_size,
    CAST(AVG(CAST(v.review_score AS FLOAT)) AS DECIMAL(4,2)) AS mean_score,
    CAST(SUM(CASE WHEN v.review_score IN (1, 2) THEN 1.0 ELSE 0.0 END) * 100.0 / COUNT(v.order_id) AS DECIMAL(5,2)) AS low_rating_rate_pct
FROM DeliveredOrdersBase d
JOIN ValidOrderReviews v ON d.order_id = v.order_id
JOIN [Olist_DB].[dbo].[customers] c ON d.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY low_rating_rate_pct DESC;

-----------------------------------------------------------------------------------


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
OrderFinancials AS (
    SELECT 
        order_id,
        SUM(price) AS total_price,
        SUM(freight_value) AS total_freight
    FROM [Olist_DB].[dbo].[order_items]
    GROUP BY order_id
),
FreightBands AS (
    SELECT 
        d.order_id,
        v.review_score,
        CASE 
            WHEN f.total_freight / NULLIF(f.total_price, 0) < 0.15 THEN '1. Low Freight (<15% of Sales)'
            WHEN f.total_freight / NULLIF(f.total_price, 0) BETWEEN 0.15 AND 0.35 THEN '2. Moderate Freight (15%-35%)'
            ELSE '3. High Freight (>35% of Sales)'
        END AS freight_band
    FROM DeliveredOrdersBase d
    JOIN ValidOrderReviews v ON d.order_id = v.order_id
    JOIN OrderFinancials f ON d.order_id = f.order_id
)

SELECT 
    'Freight-to-Sales Band' AS dimension_type,
    freight_band AS segment_name,
    COUNT(order_id) AS sample_size,
    CAST(AVG(CAST(review_score AS FLOAT)) AS DECIMAL(4,2)) AS mean_score,
    CAST(SUM(CASE WHEN review_score IN (1, 2) THEN 1.0 ELSE 0.0 END) * 100.0 / COUNT(order_id) AS DECIMAL(5,2)) AS low_rating_rate_pct
FROM FreightBands
GROUP BY freight_band
ORDER BY freight_band ASC;