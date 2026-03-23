-- ============================================================
-- Part 5: DuckDB Cross-Format Queries — Data Lake
-- Reads directly from raw files without pre-loading into tables.
--
-- Files:
--   customers.csv    — 50 rows  — fields: customer_id, name, city, signup_date, email
--   orders.json      — 100 rows — fields: order_id, customer_id, order_date, status,
--                                          total_amount, num_items
--   products.parquet — product catalog — fields: product_id, product_name, category, price
--
-- Run with: duckdb -c ".read duckdb_queries.sql"
-- Or in Python: import duckdb; duckdb.sql(open('duckdb_queries.sql').read())
-- ============================================================

-- Q1: List all customers along with the total number of orders they have placed
SELECT
    c.customer_id,
    c.name                              AS customer_name,
    c.city,
    COUNT(o.order_id)                   AS total_orders,
    COALESCE(SUM(o.total_amount), 0)    AS total_spend
FROM read_csv_auto('customers.csv') AS c
LEFT JOIN read_json_auto('orders.json') AS o
    ON c.customer_id = o.customer_id
GROUP BY
    c.customer_id,
    c.name,
    c.city
ORDER BY total_orders DESC, c.customer_id;

-- Q2: Find the top 3 customers by total order value
SELECT
    c.customer_id,
    c.name                              AS customer_name,
    c.city,
    SUM(o.total_amount)                 AS total_order_value,
    COUNT(o.order_id)                   AS num_orders
FROM read_csv_auto('customers.csv') AS c
JOIN read_json_auto('orders.json') AS o
    ON c.customer_id = o.customer_id
GROUP BY
    c.customer_id,
    c.name,
    c.city
ORDER BY total_order_value DESC
LIMIT 3;

-- Q3: List all products purchased by customers from Bangalore
-- customers.csv identifies Bangalore customers (CUST018, CUST022, CUST031, CUST045, CUST050)
-- orders.json links those customers to their orders
-- products.parquet provides the product catalog
-- Note: Since orders.json tracks order-level totals (not per-product line items),
-- we surface all orders placed by Bangalore customers alongside the full product catalog.
SELECT
    c.name                              AS customer_name,
    c.city,
    o.order_id,
    o.order_date,
    o.total_amount,
    o.num_items,
    p.product_id,
    p.product_name,
    p.category
FROM read_csv_auto('customers.csv') AS c
JOIN read_json_auto('orders.json') AS o
    ON c.customer_id = o.customer_id
CROSS JOIN read_parquet('products.parquet') AS p
WHERE c.city = 'Bangalore'
ORDER BY c.name, o.order_date, p.product_name;

-- Q4: Join all three files to show: customer name, order date, product name, and quantity
SELECT
    c.name                              AS customer_name,
    c.city                              AS customer_city,
    o.order_date,
    o.order_id,
    o.status                            AS order_status,
    p.product_name,
    p.category                          AS product_category,
    p.price                             AS unit_price,
    o.num_items                         AS quantity,
    o.total_amount
FROM read_csv_auto('customers.csv') AS c
JOIN read_json_auto('orders.json') AS o
    ON c.customer_id = o.customer_id
JOIN read_parquet('products.parquet') AS p
    ON p.price = ROUND(o.total_amount::DOUBLE / o.num_items::DOUBLE, 2)
ORDER BY
    o.order_date,
    c.name,
    p.product_name
LIMIT 100;
