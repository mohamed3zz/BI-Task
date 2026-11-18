WITH MonthlySales AS (
    SELECT 
        FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS purchase_month,
        SUM(oi.price) AS merchandise_sales,
        COUNT(DISTINCT o.order_id) AS delivered_orders,
        SUM(oi.price) * 1.0 / COUNT(DISTINCT o.order_id) AS aov
    FROM [Olist_DB].[dbo].[orders] o
    JOIN [Olist_DB].[dbo].[order_items] oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01' 
      AND o.order_purchase_timestamp < '2018-09-01'
    GROUP BY FORMAT(o.order_purchase_timestamp, 'yyyy-MM')
)
SELECT 
    purchase_month,
    merchandise_sales,
    delivered_orders,
    aov,
    
    LAG(merchandise_sales, 1) OVER (ORDER BY purchase_month) AS prev_month_sales,
    CAST((merchandise_sales - LAG(merchandise_sales, 1) OVER (ORDER BY purchase_month)) * 100.0 / 
          NULLIF(LAG(merchandise_sales, 1) OVER (ORDER BY purchase_month), 0) AS DECIMAL(5,2)) AS mom_growth_percentage,
    
    SUM(merchandise_sales) OVER (ORDER BY purchase_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sales_total
FROM MonthlySales
ORDER BY purchase_month;