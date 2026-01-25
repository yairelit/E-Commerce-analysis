/*
   RFM Segmentation Analysis
   -------------------------
   Goal: Segment customers based on Recency, Frequency, and Monetary value.
   Method: 
   1. Recency & Monetary: Relative scoring using NTILE (comparing customers to each other).
   2. Frequency: Absolute scoring using CASE WHEN (to handle the "Long Tail" issue where most customers only buy once).
*/

WITH CustomerMetrics AS (
    -- Step 1: Calculate raw metrics per unique customer
    SELECT 
        c.customer_unique_id,
        -- Get the most recent order date
        MAX(o.order_purchase_timestamp) AS last_purchase_date,
        -- Count unique orders (Frequency)
        COUNT(DISTINCT o.order_id) AS frequency,
        -- Sum total spend (Monetary)
        SUM(p.payment_value) AS monetary
    FROM 
        olist_customers_dataset c
    JOIN 
        olist_orders_dataset o ON c.customer_id = o.customer_id
    JOIN 
        olist_order_payments_dataset p ON o.order_id = p.order_id
    WHERE 
        o.order_status = 'delivered' -- Filter for completed orders only
    GROUP BY 
        c.customer_unique_id
),
RFM_Scores AS (
    -- Step 2: Assign scores (1 to 5)
    SELECT 
        customer_unique_id,
        last_purchase_date,
        frequency,
        monetary,
        
        -- Recency Score: 5 = Most recent, 1 = Oldest
        -- We use NTILE to split customers into 5 equal groups (20% each)
        NTILE(5) OVER (ORDER BY last_purchase_date ASC) AS r_score, 
        
        -- Monetary Score: 5 = Highest spenders, 1 = Lowest spenders
        -- We use NTILE to split customers into 5 equal groups
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score,

        -- Frequency Score: Custom Business Logic (Absolute Scoring)
        -- Since most customers only buy once, NTILE would be inaccurate here.
        -- We define hard thresholds for loyalty.
        CASE 
            WHEN frequency >= 5 THEN 5  -- Super Loyal
            WHEN frequency = 4 THEN 4   -- Very Loyal
            WHEN frequency = 3 THEN 3   -- Returning
            WHEN frequency = 2 THEN 2   -- Repeat Buyer
            ELSE 1                      -- One-time Buyer (The majority)
        END AS f_score
    FROM 
        CustomerMetrics
)
-- Step 3: Select final data and identify "Champions"
SELECT 
    customer_unique_id,
    r_score,
    f_score,
    m_score,
    -- Create a segment identifier (e.g., "555") for easy filtering
    CONCAT(r_score, f_score, m_score) as rfm_segment
FROM 
    RFM_Scores
WHERE 
    -- Optional: Filter to see only the best customers
    r_score = 5 AND f_score >= 4 AND m_score = 5
ORDER BY 
    monetary DESC;






/* Logical Sanity Check & Fairness Validation
   ------------------------------------------
   Goal: Verify that our scoring method (CASE WHEN) reflects reality and does not distort it.
   
   The Problem with NTILE (Relative Scoring): 
   NTILE forces data into equal buckets (e.g., exactly 20% of customers in each score).
   In a dataset where 96% of customers only buy once, NTILE would arbitrarily assign 
   a "Loyalty Score" of 5 to a one-time buyer just to fill the quota. 
   This creates a false narrative for the business owner.
   
   The Solution (This Query): 
   We use "Absolute Scoring." A high score is earned by hitting specific milestones.
   This approach reveals the uncomfortable truth about customer retention (The Long Tail).
*/

WITH CustomerMetrics AS (
    -- Step 1: Gather Ground Truth (Actual purchase counts per customer)
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS frequency
    FROM 
        olist_customers_dataset c
    JOIN 
        olist_orders_dataset o ON c.customer_id = o.customer_id
    WHERE 
        o.order_status = 'delivered'
    GROUP BY 
        c.customer_unique_id
),
FrequencyScores AS (
    SELECT 
        -- Step 2: Apply Hard Thresholds (Fair Business Logic)
        -- Fairness means the score is based on performance, not relative position.
        CASE 
            WHEN frequency >= 5 THEN 5  -- Only true "Power Users" get a 5
            WHEN frequency = 4 THEN 4
            WHEN frequency = 3 THEN 3
            WHEN frequency = 2 THEN 2   -- Returning customers
            ELSE 1                      -- The vast majority will honestly fall here
        END AS f_score
    FROM CustomerMetrics
)
SELECT 
    f_score, 
    COUNT(*) as customer_count,
    
    -- Step 3: Calculate Distribution Percentage
    -- We expect a skewed distribution ("Long Tail"). 
    -- If 90%+ of customers are in Score 1, our logic is sound and realistic.
    CAST(
        CAST(
            (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM FrequencyScores)) 
        AS DECIMAL(10, 2)) 
    AS VARCHAR(20)) || '%'  
    as percentage

FROM 
    FrequencyScores
GROUP BY 
    f_score
ORDER BY 
    f_score DESC;
