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
        CASE 
            WHEN o.order_purchase_timestamp >= '2017-01-01' AND o.order_purchase_timestamp < '2017-07-01' THEN 'H1_2017'
            WHEN o.order_purchase_timestamp >= '2018-01-01' AND o.order_purchase_timestamp < '2018-07-01' THEN 'H1_2018'
        END AS period_name
    FROM [Olist_DB].[dbo].[orders] o
    WHERE o.order_status = 'delivered'
      AND (
          (o.order_purchase_timestamp >= '2017-01-01' AND o.order_purchase_timestamp < '2017-07-01')
          OR 
          (o.order_purchase_timestamp >= '2018-01-01' AND o.order_purchase_timestamp < '2018-07-01')
      )
),
ProductCategories AS (
    SELECT 
        p.product_id,
        COALESCE(t.product_category_name_english, p.product_category_name, 'Unknown') AS category_name
    FROM [Olist_DB].[dbo].[products] p
    LEFT JOIN [Olist_DB].[dbo].[category_translation] t ON p.product_category_name = t.product_category_name
),
OrderCategoriesSummary AS (
    SELECT 
        oi.order_id,
        MAX(pc.category_name) AS category_name,
        COUNT(DISTINCT pc.category_name) AS distinct_categories_count
    FROM [Olist_DB].[dbo].[order_items] oi
    JOIN ProductCategories pc ON oi.product_id = pc.product_id
    GROUP BY oi.order_id
),
SingleCategoryOrders AS (
    SELECT 
        d.period_name,
        ocs.category_name,
        d.order_id,
        v.review_score
    FROM OrderCategoriesSummary ocs
    JOIN DeliveredOrdersBase d ON ocs.order_id = d.order_id
    LEFT JOIN ValidOrderReviews v ON ocs.order_id = v.order_id
    WHERE ocs.distinct_categories_count = 1
),

H1_2017_Metrics AS (
    SELECT 
        category_name,
        COUNT(order_id) AS total_orders_17,
        SUM(CASE WHEN review_score IS NOT NULL THEN 1 ELSE 0 END) AS reviewed_orders_17,
        CAST(SUM(CASE WHEN review_score IS NOT NULL THEN 1.0 ELSE 0.0 END) * 100.0 / COUNT(order_id) AS DECIMAL(5,2)) AS coverage_17,
        SUM(CASE WHEN review_score IN (1, 2) THEN 1 ELSE 0 END) AS low_rated_17,
        CAST(SUM(CASE WHEN review_score IN (1, 2) THEN 1.0 ELSE 0.0 END) * 100.0 / NULLIF(SUM(CASE WHEN review_score IS NOT NULL THEN 1 ELSE 0 END), 0) AS DECIMAL(5,2)) AS low_rating_rate_17
    FROM SingleCategoryOrders
    WHERE period_name = 'H1_2017'
    GROUP BY category_name
),

H1_2018_Metrics AS (
    SELECT 
        category_name,
        COUNT(order_id) AS total_orders_18,
        SUM(CASE WHEN review_score IS NOT NULL THEN 1 ELSE 0 END) AS reviewed_orders_18,
        CAST(SUM(CASE WHEN review_score IS NOT NULL THEN 1.0 ELSE 0.0 END) * 100.0 / COUNT(order_id) AS DECIMAL(5,2)) AS coverage_18,
        SUM(CASE WHEN review_score IN (1, 2) THEN 1 ELSE 0 END) AS low_rated_18,
        CAST(SUM(CASE WHEN review_score IS NOT NULL THEN 1.0 ELSE 0.0 END) * 100.0 / NULLIF(SUM(CASE WHEN review_score IS NOT NULL THEN 1 ELSE 0 END), 0) AS DECIMAL(5,2)) AS low_rating_rate_18
    FROM SingleCategoryOrders
    WHERE period_name = 'H1_2018'
    GROUP BY category_name
)

SELECT 
    COALESCE(t17.category_name, t18.category_name) AS Category,
    
    t17.total_orders_17 AS total_orders_denominator_17,
    t18.total_orders_18 AS total_orders_denominator_18,
    
    t17.coverage_17 AS review_coverage_h1_2017,
    t18.coverage_18 AS review_coverage_h1_2018,
    
    t17.low_rating_rate_17 AS low_rating_rate_h1_2017,
    t18.low_rating_rate_18 AS low_rating_rate_h1_2018,
    
    CAST(COALESCE(t18.coverage_18, 0) - COALESCE(t17.coverage_17, 0) AS DECIMAL(5,2)) AS coverage_change_pp,
    CAST(COALESCE(t18.low_rating_rate_18, 0) - COALESCE(t17.low_rating_rate_17, 0) AS DECIMAL(5,2)) AS low_rating_rate_change_pp,
    
    CASE 
        WHEN t17.category_name IS NULL THEN 'Missing in H1 2017'
        WHEN t18.category_name IS NULL THEN 'Missing in H1 2018'
        ELSE 'Present in Both'
    END AS period_presence_flag

FROM H1_2017_Metrics t17
FULL OUTER JOIN H1_2018_Metrics t18 ON t17.category_name = t18.category_name
ORDER BY Category ASC;