-- ============================================================
-- Part 1: SQL Queries
-- Run after executing schema_design.sql
-- Dataset: orders_flat.csv — 186 orders, 8 customers, 8 products
-- ============================================================

-- Q1: List all customers from Mumbai along with their total order value
--     Mumbai customers from dataset: C001 (Rohan Mehta), C005 (Vikram Singh)
--     Real totals from flat file: Rohan Mehta ₹3,26,390 | Vikram Singh ₹8,54,280
SELECT
    c.customer_id,
    c.customer_name,
    c.customer_city,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_order_value
FROM customers c
LEFT JOIN orders o       ON o.customer_id  = c.customer_id
LEFT JOIN order_items oi ON oi.order_id    = o.order_id
WHERE c.customer_city = 'Mumbai'
GROUP BY
    c.customer_id,
    c.customer_name,
    c.customer_city
ORDER BY total_order_value DESC;

-- Q2: Find the top 3 products by total quantity sold
--     Real results from flat file:
--       P004 Notebook 91 units | P002 Mouse 89 units | P007 Pen Set 80 units
SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(oi.quantity) AS total_quantity_sold
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY
    p.product_id,
    p.product_name,
    p.category
ORDER BY total_quantity_sold DESC
LIMIT 3;

-- Q3: List all sales representatives and the number of unique customers they have handled
--     Real results: SR01 Deepak Joshi — 8 | SR02 Anita Desai — 8 | SR03 Ravi Kumar — 8
SELECT
    sr.rep_id,
    sr.rep_name,
    sr.rep_email,
    COUNT(DISTINCT o.customer_id) AS unique_customers_handled
FROM sales_reps sr
LEFT JOIN orders o ON o.rep_id = sr.rep_id
GROUP BY
    sr.rep_id,
    sr.rep_name,
    sr.rep_email
ORDER BY unique_customers_handled DESC;

-- Q4: Find all orders where the total value exceeds 10,000, sorted by value descending
--     Many orders in the dataset exceed ₹10,000 (e.g. Standing Desk x5 = ₹1,10,000)
SELECT
    o.order_id,
    c.customer_name,
    c.customer_city,
    sr.rep_name,
    o.order_date,
    SUM(oi.quantity * oi.unit_price) AS order_total
FROM orders o
JOIN customers  c  ON c.customer_id  = o.customer_id
JOIN sales_reps sr ON sr.rep_id      = o.rep_id
JOIN order_items oi ON oi.order_id   = o.order_id
GROUP BY
    o.order_id,
    c.customer_name,
    c.customer_city,
    sr.rep_name,
    o.order_date
HAVING SUM(oi.quantity * oi.unit_price) > 10000
ORDER BY order_total DESC;

-- Q5: Identify any products that have never been ordered
--     In the full dataset all 8 products (P001–P008) appear at least once.
--     P008 (Webcam) appears in only 1 order (ORD1185) — shown for reference.
--     This query will return rows if new products are added but not yet ordered.
SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.unit_price
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.product_id
WHERE oi.product_id IS NULL
ORDER BY p.product_id;
