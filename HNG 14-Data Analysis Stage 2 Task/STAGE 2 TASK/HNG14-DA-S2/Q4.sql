/* 
Question 4: Quarterly Revenue Trends
This query compares revenue metrics by quarter for 2023 and 2024.
*/

WITH quarterly_metrics AS (
    SELECT 
        EXTRACT(YEAR FROM order_date) as yr,
        EXTRACT(QUARTER FROM order_date) as qtr,
        SUM(total_amount) as total_revenue,
        COUNT(order_id) as order_count,
        AVG(total_amount) as avg_order_value
    FROM public.orders
    WHERE EXTRACT(YEAR FROM order_date) IN (2023, 2024)
    GROUP BY yr, qtr
),
growth_calc AS (
    -- Calculate year-over-year growth per quarter
    SELECT 
        q1.qtr,
        q1.total_revenue as revenue_2023,
        q2.total_revenue as revenue_2024,
        q2.total_revenue - q1.total_revenue as revenue_growth,
        q2.order_count as orders_2024,
        q2.avg_order_value as aov_2024
    FROM quarterly_metrics q1
    JOIN quarterly_metrics q2 ON q1.qtr = q2.qtr AND q1.yr = 2023 AND q2.yr = 2024
)
SELECT 
    qtr as quarter,
    revenue_2023,
    revenue_2024,
    revenue_growth,
    orders_2024,
    ROUND(aov_2024::numeric, 2) as avg_order_value_2024
FROM growth_calc
ORDER BY revenue_growth DESC;