/* 
Question 3: Seller Fulfilment Efficiency
This query calculates the average fulfillment time (in hours) for sellers 
with at least 20 completed orders and includes their average rating.
*/

WITH seller_fulfillment AS (
    -- Calculate fulfillment time per order
    SELECT 
        seller_id,
        AVG(EXTRACT(EPOCH FROM (delivery_date::timestamp - order_date::timestamp)) / 3600) as avg_fulfillment_hours,
        COUNT(order_id) as completed_orders
    FROM public.orders
    WHERE order_status = 'Completed' 
      AND delivery_date IS NOT NULL
    GROUP BY seller_id
    HAVING COUNT(order_id) >= 20
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
    sf.completed_orders,
    ROUND(sf.avg_fulfillment_hours::numeric, 2) as avg_fulfillment_hours,
    ROUND(sr.avg_rating::numeric, 2) as avg_customer_rating
FROM seller_fulfillment sf
JOIN public.sellers s ON sf.seller_id = s.seller_id
LEFT JOIN seller_ratings sr ON sf.seller_id = sr.seller_id
ORDER BY avg_fulfillment_hours ASC
LIMIT 20;