SELECT 
    order_status,
    COUNT(order_id) AS total_orders,
    CAST(COUNT(order_id) * 100.0 / (
        SELECT COUNT(*) 
        FROM [Olist_DB].[dbo].[orders]
        WHERE order_purchase_timestamp >= '2017-01-01' 
          AND order_purchase_timestamp < '2018-09-01'
    ) AS DECIMAL(5,2)) AS order_percentage,
    
    CASE WHEN order_status = 'delivered' THEN (
        SELECT COUNT(DISTINCT c.customer_unique_id) 
        FROM [Olist_DB].[dbo].[orders] o2
        JOIN [Olist_DB].[dbo].[customers] c ON o2.customer_id = c.customer_id
        WHERE o2.order_status = 'delivered'
          AND o2.order_purchase_timestamp >= '2017-01-01' 
          AND o2.order_purchase_timestamp < '2018-09-01'
    ) ELSE NULL END AS distinct_delivered_customers,
    
    CASE WHEN order_status = 'delivered' THEN (
        SELECT SUM(oi.price) 
        FROM [Olist_DB].[dbo].[order_items] oi
        JOIN [Olist_DB].[dbo].[orders] o2 ON oi.order_id = o2.order_id
        WHERE o2.order_status = 'delivered'
          AND o2.order_purchase_timestamp >= '2017-01-01' 
          AND o2.order_purchase_timestamp < '2018-09-01'
    ) ELSE NULL END AS delivered_merchandise_sales,
    
    CASE WHEN order_status = 'delivered' THEN (
        SELECT SUM(oi.price) * 1.0 / COUNT(DISTINCT o2.order_id)
        FROM [Olist_DB].[dbo].[order_items] oi
        JOIN [Olist_DB].[dbo].[orders] o2 ON oi.order_id = o2.order_id
        WHERE o2.order_status = 'delivered'
          AND o2.order_purchase_timestamp >= '2017-01-01' 
          AND o2.order_purchase_timestamp < '2018-09-01'
    ) ELSE NULL END AS average_order_value_AOV

FROM [Olist_DB].[dbo].[orders]
WHERE order_purchase_timestamp >= '2017-01-01' 
  AND order_purchase_timestamp < '2018-09-01'
GROUP BY order_status
ORDER BY total_orders DESC;