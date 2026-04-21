/* 
Question 2: Product Performance
This query identifies the top 10 products by revenue in 2024, 
including their category and the count of unique orders they appeared in.
*/

SELECT 
    p.product_name,
    p.category,
    SUM(oi.line_total) as total_revenue,
    COUNT(DISTINCT oi.order_id) as total_orders
FROM public.products p
JOIN public.order_items oi ON p.product_id = oi.product_id
JOIN public.orders o ON oi.order_id = o.order_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2024
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC
LIMIT 10;