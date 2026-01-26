/* 
   Goal: Segment customers based on Recency, Frequency, and Monetary value.
   Workflow:
   1. Calculate raw metrics and score customers.
   2. Store results in a Temporary Table for performance.
   3. Generate specific business reports from that table.
*/

-------------------------------------------------------------------------
-- STEP 1: Calculate Scores and Create Temp Table
-------------------------------------------------------------------------
-- Clean up: Drop the temp table if it exists from a previous run
DROP TABLE IF EXISTS rfm_results;

-- Create a temporary table to store the scored data.
-- This avoids recalculating the heavy aggregations for every subsequent query.
CREATE TEMP TABLE rfm_results AS
WITH CustomerMetrics AS (
    -- Sub-query: Aggregate data to get one row per customer
    SELECT 
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(p.payment_value) AS monetary
    FROM 
        olist_customers_dataset c
    JOIN 
        olist_orders_dataset o ON c.customer_id = o.customer_id
    JOIN 
        olist_order_payments_dataset p ON o.order_id = p.order_id
    WHERE 
        o.order_status = 'delivered' -- Focus on completed orders only
    GROUP BY 
        c.customer_unique_id
)
SELECT 
    customer_unique_id,
    last_purchase_date,
    frequency,
    monetary,
    
    -- Scoring Logic:
    
    -- 1. Recency: Relative Scoring (NTILE)
    -- Divide customers into 5 equal groups based on how recently they bought.
    -- 5 = Most recent, 1 = Least recent.
    NTILE(5) OVER (ORDER BY last_purchase_date ASC) AS r_score, 
    
    -- 2. Monetary: Relative Scoring (NTILE)
    -- Divide customers into 5 equal groups based on spend.
    -- 5 = Highest spenders, 1 = Lowest spenders.
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score,

    -- 3. Frequency: Absolute Scoring (Business Rules)
    -- Since most customers buy only once, NTILE would be misleading here.
    -- We use hard thresholds to identify true loyalty.
    CASE 
        WHEN frequency >= 5 THEN 5  -- Super Loyal (The "Whales")
        WHEN frequency = 4 THEN 4
        WHEN frequency = 3 THEN 3
        WHEN frequency = 2 THEN 2   -- Returning Customers
        ELSE 1                      -- One-time buyers (The majority)
    END AS f_score
FROM 
    CustomerMetrics;

-------------------------------------------------------------------------
-- STEP 2: Business Report - Identify "Champions"
-------------------------------------------------------------------------
-- Fetch the top-tier customers for marketing campaigns
SELECT 
    customer_unique_id,
    r_score, f_score, m_score,
    -- Create a readable segment ID (e.g., '555')
    CONCAT(r_score, f_score, m_score) as rfm_segment
FROM 
    rfm_results
WHERE 
    r_score = 5 AND f_score >= 4 AND m_score = 5
ORDER BY 
    monetary DESC;

-------------------------------------------------------------------------
-- STEP 3: Quality Control - Distribution Check
-------------------------------------------------------------------------
-- Validate that the frequency logic isn't skewed. 
-- We expect a "Long Tail" distribution (most users in score 1).
SELECT 
    f_score, 
    COUNT(*) as customer_count,
    -- Calculate percentage share for each score
    CONCAT(
        CAST(
            (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM rfm_results)) 
        AS DECIMAL(10, 2)),
        '%'
    ) as percentage
FROM 
    rfm_results 
GROUP BY 
    f_score
ORDER BY 
    f_score DESC;
