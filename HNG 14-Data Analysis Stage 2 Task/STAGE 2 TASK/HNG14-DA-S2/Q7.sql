/* 
Question 7: Review Ratings and Sales Performance
This query segments products by their average review ratings 
and analyzes the sales performance of each rating tier.
*/

WITH product_ratings AS (
    -- Calculate average rating for each product
    SELECT 
        product_id,
        AVG(rating) as avg_rating
    FROM public.reviews
    GROUP BY product_id
),
product_performance AS (
    -- Get revenue and unit price for each product
    SELECT 
        p.product_id,
        p.unit_price,
        COALESCE(SUM(oi.line_total), 0) as total_revenue
    FROM public.products p
    LEFT JOIN public.order_items oi ON p.product_id = oi.product_id
    GROUP BY p.product_id, p.unit_price
),
rating_segments AS (
    -- Combine ratings with performance and assign categories
    SELECT 
        pp.product_id,
        pp.total_revenue,
        pp.unit_price,
        CASE 
            WHEN pr.avg_rating >= 4.0 THEN 'High Rated'
            WHEN pr.avg_rating >= 3.0 THEN 'Mid Rated'
            WHEN pr.avg_rating < 3.0 THEN 'Low Rated'
            ELSE 'Unrated'
        END as rating_category
    FROM product_performance pp
    LEFT JOIN product_ratings pr ON pp.product_id = pr.product_id
)
SELECT 
    rating_category,
    COUNT(product_id) as product_count,
    SUM(total_revenue) as total_revenue,
    ROUND(AVG(unit_price)::numeric, 2) as avg_unit_price
FROM rating_segments
WHERE rating_category != 'Unrated'
GROUP BY rating_category
ORDER BY total_revenue DESC;