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
DeliveredOrders AS (
    SELECT 
        o.order_id,
        o.customer_id,
        c.customer_unique_id
    FROM [Olist_DB].[dbo].[orders] o
    JOIN [Olist_DB].[dbo].[customers] c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
),
OrderPayments AS (
    SELECT order_id, SUM(payment_value) AS total_payment
    FROM [Olist_DB].[dbo].[order_payments]
    GROUP BY order_id
),
CustomerMetrics AS (
    SELECT 
        d.customer_unique_id,
        COUNT(DISTINCT d.order_id) AS total_orders,
        SUM(COALESCE(p.total_payment, 0)) AS total_spend,
        MAX(CASE WHEN v.review_score IN (1, 2) THEN 1 ELSE 0 END) AS has_low_rating,
        MAX(CASE WHEN v.review_score IS NOT NULL THEN 1 ELSE 0 END) AS has_valid_review
    FROM DeliveredOrders d
    LEFT JOIN ValidOrderReviews v ON d.order_id = v.order_id
    LEFT JOIN OrderPayments p ON d.order_id = p.order_id
    GROUP BY d.customer_unique_id
),
CustomerClassified AS (
    SELECT 
        customer_unique_id,
        total_orders,
        total_spend,
        CASE 
            WHEN has_low_rating = 1 THEN '1. Customers with Low Rating'
            WHEN has_valid_review = 1 AND has_low_rating = 0 THEN '2. Customers with Valid Reviews (No Low Rating)'
            ELSE '3. Customers with No Valid Reviews'
        END AS customer_segment
    FROM CustomerMetrics
)
SELECT 
    customer_segment AS Customer_Segment,
    COUNT(customer_unique_id) AS customer_count,
    SUM(total_orders) AS total_orders_sum,
    CAST(SUM(total_spend) AS DECIMAL(12,2)) AS total_spend_sum,
    CAST(AVG(total_spend) AS DECIMAL(10,2)) AS avg_spend_per_customer
FROM CustomerClassified
GROUP BY customer_segment
ORDER BY customer_segment ASC;