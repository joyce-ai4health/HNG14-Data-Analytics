/* 
Question 5: Customer Spend Segmentation
This query segments customers based on their 2024 spending behavior 
and provides summary statistics for each segment.
*/

WITH customer_spend AS (
    -- Calculate total spend per customer in 2024
    SELECT 
        customer_id,
        SUM(total_amount) as total_spend
    FROM public.orders
    WHERE EXTRACT(YEAR FROM order_date) = 2024
    GROUP BY customer_id
),
segments AS (
    -- Assign segments
    SELECT 
        customer_id,
        total_spend,
        CASE 
            WHEN total_spend >= 100000 THEN 'High Spenders'
            WHEN total_spend >= 50000 THEN 'Medium Spenders'
            ELSE 'Low Spenders'
        END as spend_segment
    FROM customer_spend
)
SELECT 
    spend_segment,
    COUNT(customer_id) as customer_count,
    ROUND(AVG(total_spend)::numeric, 2) as avg_spend_per_customer,
    SUM(total_spend) as total_revenue_contribution
FROM segments
GROUP BY spend_segment
ORDER BY total_revenue_contribution DESC;