/* 
Question 1: Customer Acquisition & 30-Day Conversion
This query identifies the top 5 states with the most new customer sign-ups in 2024 
and calculates the 30-day conversion rate for each of those states.
*/

WITH new_customers_2024 AS (
    -- Get all customers who signed up in 2024
    SELECT 
        customer_id, 
        state, 
        signup_date
    FROM public.customers
    WHERE EXTRACT(YEAR FROM signup_date) = 2024
),
conversions AS (
    -- Identify which of these customers made a purchase within 30 days
    SELECT 
        nc.customer_id,
        nc.state,
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM public.orders o 
                WHERE o.customer_id = nc.customer_id 
                  AND o.order_date <= nc.signup_date + INTERVAL '30 days'
            ) THEN 1 
            ELSE 0 
        END as converted_30d
    FROM new_customers_2024 nc
),
state_stats AS (
    -- Aggregate by state
    SELECT 
        state,
        COUNT(*) as total_new_customers,
        SUM(converted_30d) as converted_customers
    FROM conversions
    GROUP BY state
)
SELECT 
    state,
    total_new_customers,
    ROUND((converted_customers::numeric / total_new_customers) * 100, 2) as conversion_percentage
FROM state_stats
ORDER BY total_new_customers DESC
LIMIT 5;