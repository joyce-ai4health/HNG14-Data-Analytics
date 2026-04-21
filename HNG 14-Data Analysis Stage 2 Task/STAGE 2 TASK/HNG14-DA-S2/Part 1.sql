
/*
====================================================================
TRADEZONE DATA CLEANING PIPELINE 
====================================================================
*/

--------------------------------------------------------------------------
-- STEP 0: REMOVE GRANDCHILD RECORDS FIRST (order_items)
--------------------------------------------------------------------------

DELETE FROM order_items
WHERE order_id NOT IN (SELECT order_id FROM orders)
   OR product_id NOT IN (SELECT product_id FROM products);

-- Reason: order_items depend on BOTH orders and products

--------------------------------------------------------------------------
-- STEP 1: REMOVE ORDERS (AFTER CLEANING CHILD TABLE)
--------------------------------------------------------------------------

DELETE FROM orders
WHERE customer_id NOT IN (SELECT customer_id FROM customers)
   OR order_date IS NULL;

-- Reason: orders cannot exist without valid customers or dates

--------------------------------------------------------------------------
-- STEP 2: CLEAN CUSTOMERS (NOW SAFE)
--------------------------------------------------------------------------

-- DELETE POLICY:
-- Removing customers who have no valid email address (NULL or empty after trim)
-- AND who have no associated orders.
-- Reason: Customers without email cannot be identified or contacted,
-- and records with no order history are not needed for business retention.

DELETE FROM customers c
WHERE (c.email IS NULL OR TRIM(c.email) = '')
AND NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
);
--------------------------------------------------------------------------
-- STEP 3: CLEAN PRODUCTS + SELLERS
--------------------------------------------------------------------------

DELETE FROM products
WHERE seller_id NOT IN (SELECT seller_id FROM sellers);

-- Reason: products must belong to valid sellers

UPDATE products
SET category = 'Uncategorized'
WHERE category IS NULL OR TRIM(category) = '';

-- Reason: ensures category consistency

UPDATE products
SET unit_price = NULL
WHERE unit_price < 0;

-- Reason: negative pricing is invalid

--------------------------------------------------------------------------
-- STEP 4: DUPLICATE REMOVAL (SAFE ORDER)

-- order_items duplicates
WITH cte AS (
    SELECT ctid,
           ROW_NUMBER() OVER (PARTITION BY order_id, product_id ORDER BY ctid) rn
    FROM order_items
)
DELETE FROM order_items
WHERE ctid IN (SELECT ctid FROM cte WHERE rn > 1);

-- orders duplicates
WITH cte AS (
    SELECT ctid,
           ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY ctid) rn
    FROM orders
)
DELETE FROM orders
WHERE ctid IN (SELECT ctid FROM cte WHERE rn > 1);

-- customers duplicates
WITH cte AS (
    SELECT ctid,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY ctid) rn
    FROM customers
)
DELETE FROM customers
WHERE ctid IN (SELECT ctid FROM cte WHERE rn > 1);

-- sellers duplicates
WITH cte AS (
    SELECT ctid,
           ROW_NUMBER() OVER (PARTITION BY seller_id ORDER BY ctid) rn
    FROM sellers
)
DELETE FROM sellers
WHERE ctid IN (SELECT ctid FROM cte WHERE rn > 1);

--------------------------------------------------------------------------
-- STEP 5: FORMATTING STANDARDIZATION
--------------------------------------------------------------------------

UPDATE customers SET city = INITCAP(TRIM(city));
UPDATE sellers SET city = INITCAP(TRIM(city));

UPDATE products
SET category = INITCAP(LOWER(TRIM(category)));

UPDATE customers
SET email = LOWER(TRIM(email))
WHERE email IS NOT NULL;

UPDATE orders
SET order_date = order_date::DATE;

--------------------------------------------------------------------------
-- STEP 6: DATA VALIDATION RULES
--------------------------------------------------------------------------

-- Review validation
DELETE FROM reviews
WHERE rating IS NULL OR rating < 1 OR rating > 5;

--------------------------------------------------------------------------
-- STEP 7: FINANCIAL INTEGRITY AUDIT (NO DELETES)
--------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS flagged_orders AS
SELECT
    o.order_id,
    o.total_amount AS reported_total,
    COALESCE(SUM(oi.unit_price * oi.quantity), 0) AS calculated_total,
    ABS(
        COALESCE(o.total_amount, 0)
        - COALESCE(SUM(oi.unit_price * oi.quantity), 0)
    ) AS variance
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.total_amount
HAVING ABS(
    COALESCE(o.total_amount, 0)
    - COALESCE(SUM(oi.unit_price * oi.quantity), 0)
) > 10;

--------------------------------------------------------------------------
-- END OF PIPELINE
--------------------------------------------------------------------------