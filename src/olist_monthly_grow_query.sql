WITH MonthlyRevenue AS (
    SELECT 
        -- Truncate the timestamp to the beginning of the month (e.g., 2017-05-15 becomes 2017-05-01).
        -- This creates a single 'Date' object which is much better for plotting graphs later.
        DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month, 
        SUM(p.payment_value) as total_revenue
    FROM olist_orders_dataset o
    JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
    WHERE 
        o.order_status = 'delivered' 
        -- Efficient filtering (SARGable): allows the database to use indexes on the timestamp column
        AND o.order_purchase_timestamp >= '2017-02-01'
    GROUP BY 1 -- Group results by the first selected column (order_month)
),

RevenueGrowth AS (
    SELECT 
        order_month, 
        total_revenue, 
        -- Window function to look back at the previous row's revenue
        LAG(total_revenue) OVER (ORDER BY order_month) AS prev_month_revenue
    FROM MonthlyRevenue
)

SELECT 
    order_month, 
    total_revenue, 
    prev_month_revenue, 
    -- Calculate growth percentage. 
    -- We cast the denominator to NUMERIC to ensure we get a decimal result (avoiding integer division).
    ROUND(((total_revenue - prev_month_revenue) / prev_month_revenue::NUMERIC) * 100, 2) AS growth_percent
FROM RevenueGrowth
ORDER BY order_month;
