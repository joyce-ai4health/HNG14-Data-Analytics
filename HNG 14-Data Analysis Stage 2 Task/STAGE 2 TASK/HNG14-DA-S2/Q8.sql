/* 
Question 8: Top Seller Bonus Qualification
This query identifies high-performing sellers in 2024 who meet 
specific volume and quality criteria for bonus consideration.
*/

WITH seller_stats_2024 AS (
    -- Calculate revenue and order count for 2024
    SELECT 
        o.seller_id,
        SUM(o.total_amount) as total_revenue,
        COUNT(o.order_id) as completed_orders
    FROM public.orders o
    WHERE EXTRACT(YEAR FROM o.order_date) = 2024
      AND o.order_status = 'Completed'
    GROUP BY o.seller_id
    HAVING COUNT(o.order_id) >= 10
),
seller_ratings AS (
    -- Calculate average rating per seller
    SELECT 
        p.seller_id,
        AVG(r.rating) as avg_rating
    FROM public.reviews r
    JOIN public.products p ON r.product_id = p.product_id
    GROUP BY p.seller_id
)
SELECT 
    s.seller_name,
    ss.completed_orders,
    ROUND(sr.avg_rating::numeric, 2) as average_rating,
    ss.total_revenue
FROM seller_stats_2024 ss
JOIN public.sellers s ON ss.seller_id = s.seller_id
JOIN seller_ratings sr ON ss.seller_id = sr.seller_id
WHERE sr.avg_rating >= 4.0
ORDER BY ss.total_revenue DESC
LIMIT 10;