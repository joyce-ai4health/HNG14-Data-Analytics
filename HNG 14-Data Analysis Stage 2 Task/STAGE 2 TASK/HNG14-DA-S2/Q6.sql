/* 
Question 6: Payment Method Preferences by State
This query analyzes payment method popularity and revenue contribution per state, 
ranking methods to identify the most popular one for each location.
*/

WITH state_payments AS (
    -- Join payments with orders and customers to get state information
    SELECT 
        c.state,
        p.payment_method,
        COUNT(p.payment_id) as transaction_count,
        SUM(p.amount) as total_amount
    FROM public.payments p
    JOIN public.orders o ON p.order_id = o.order_id
    JOIN public.customers c ON o.customer_id = c.customer_id
    GROUP BY c.state, p.payment_method
),
ranked_methods AS (
    -- Rank payment methods within each state by transaction count
    SELECT 
        *,
        RANK() OVER (PARTITION BY state ORDER BY transaction_count DESC) as popularity_rank
    FROM state_payments
)
SELECT 
    state,
    payment_method,
    transaction_count,
    total_amount,
    CASE WHEN popularity_rank = 1 THEN 'Yes' ELSE 'No' END as is_most_popular
FROM ranked_methods
ORDER BY state, transaction_count DESC;