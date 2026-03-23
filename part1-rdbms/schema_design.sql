-- ============================================================
-- Part 1: Schema Design — Normalized to 3NF
-- Source: orders_flat.csv (186 rows, 15 columns)
-- Entities identified: customers, products, sales_reps, orders
-- ============================================================

-- Drop tables in reverse dependency order (safe re-run)
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS sales_reps;

-- ------------------------------------------------------------
-- Table: sales_reps
-- Eliminates repeated rep data across 186 order rows.
-- office_address is a rep-level attribute, not an order attribute.
-- Fixes: insert anomaly (can add reps independently),
--        update anomaly (address stored once, not 80+ times).
-- ------------------------------------------------------------
CREATE TABLE sales_reps (
    rep_id          VARCHAR(10)     PRIMARY KEY,
    rep_name        VARCHAR(150)    NOT NULL,
    rep_email       VARCHAR(150)    NOT NULL UNIQUE,
    office_address  VARCHAR(300)    NOT NULL
);

INSERT INTO sales_reps (rep_id, rep_name, rep_email, office_address) VALUES
('SR01', 'Deepak Joshi', 'deepak@corp.com', 'Mumbai HQ, Nariman Point, Mumbai - 400021'),
('SR02', 'Anita Desai',  'anita@corp.com',  'Delhi Office, Connaught Place, New Delhi - 110001'),
('SR03', 'Ravi Kumar',   'ravi@corp.com',   'South Zone, MG Road, Bangalore - 560001');

-- ------------------------------------------------------------
-- Table: customers
-- 8 unique customers from orders_flat.csv (C001–C008).
-- Each customer's city and email stored exactly once.
-- Fixes: update anomaly (one row per customer to update).
-- ------------------------------------------------------------
CREATE TABLE customers (
    customer_id     VARCHAR(10)     PRIMARY KEY,
    customer_name   VARCHAR(150)    NOT NULL,
    customer_email  VARCHAR(150)    NOT NULL UNIQUE,
    customer_city   VARCHAR(100)    NOT NULL
);

INSERT INTO customers (customer_id, customer_name, customer_email, customer_city) VALUES
('C001', 'Rohan Mehta',  'rohan@gmail.com',  'Mumbai'),
('C002', 'Priya Sharma', 'priya@gmail.com',  'Delhi'),
('C003', 'Amit Verma',   'amit@gmail.com',   'Bangalore'),
('C004', 'Sneha Iyer',   'sneha@gmail.com',  'Chennai'),
('C005', 'Vikram Singh', 'vikram@gmail.com', 'Mumbai'),
('C006', 'Neha Gupta',   'neha@gmail.com',   'Delhi'),
('C007', 'Arjun Nair',   'arjun@gmail.com',  'Bangalore'),
('C008', 'Kavya Rao',    'kavya@gmail.com',  'Hyderabad');

-- ------------------------------------------------------------
-- Table: products
-- 8 unique products from orders_flat.csv (P001–P008).
-- Fixes: delete anomaly (P008 Webcam survives even if its
--        only order ORD1185 is deleted).
-- ------------------------------------------------------------
CREATE TABLE products (
    product_id      VARCHAR(10)     PRIMARY KEY,
    product_name    VARCHAR(200)    NOT NULL,
    category        VARCHAR(100)    NOT NULL,
    unit_price      DECIMAL(10,2)   NOT NULL,
    CONSTRAINT chk_price CHECK (unit_price >= 0)
);

INSERT INTO products (product_id, product_name, category, unit_price) VALUES
('P001', 'Laptop',        'Electronics', 55000.00),
('P002', 'Mouse',         'Electronics',   800.00),
('P003', 'Desk Chair',    'Furniture',    8500.00),
('P004', 'Notebook',      'Stationery',    120.00),
('P005', 'Headphones',    'Electronics',  3200.00),
('P006', 'Standing Desk', 'Furniture',   22000.00),
('P007', 'Pen Set',       'Stationery',    250.00),
('P008', 'Webcam',        'Electronics',  2100.00);

-- ------------------------------------------------------------
-- Table: orders
-- One row per order. Links customer and sales rep.
-- 186 unique order_ids in source data.
-- ------------------------------------------------------------
CREATE TABLE orders (
    order_id        VARCHAR(15)     PRIMARY KEY,
    customer_id     VARCHAR(10)     NOT NULL,
    rep_id          VARCHAR(10)     NOT NULL,
    order_date      DATE            NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (rep_id)      REFERENCES sales_reps(rep_id)
);

-- Sample of 10 real orders from the dataset
INSERT INTO orders (order_id, customer_id, rep_id, order_date) VALUES
('ORD1002', 'C002', 'SR02', '2023-01-17'),
('ORD1003', 'C001', 'SR01', '2023-01-21'),
('ORD1004', 'C002', 'SR01', '2023-04-09'),
('ORD1022', 'C005', 'SR01', '2023-10-15'),
('ORD1027', 'C002', 'SR02', '2023-11-02'),
('ORD1037', 'C002', 'SR03', '2023-03-06'),
('ORD1075', 'C005', 'SR03', '2023-04-18'),
('ORD1083', 'C006', 'SR01', '2023-07-03'),
('ORD1091', 'C001', 'SR01', '2023-07-24'),
('ORD1185', 'C003', 'SR03', '2023-06-15');

-- ------------------------------------------------------------
-- Table: order_items
-- Grain: one product line per order.
-- unit_price captured at time of order (price may change later).
-- In the source flat file each row = one order+product combo.
-- ------------------------------------------------------------
CREATE TABLE order_items (
    item_id         INT             PRIMARY KEY AUTO_INCREMENT,
    order_id        VARCHAR(15)     NOT NULL,
    product_id      VARCHAR(10)     NOT NULL,
    quantity        INT             NOT NULL,
    unit_price      DECIMAL(10,2)   NOT NULL,
    CONSTRAINT chk_qty   CHECK (quantity > 0),
    CONSTRAINT chk_uprice CHECK (unit_price >= 0),
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Real line items from orders_flat.csv
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
('ORD1002', 'P005',  1,  3200.00),   -- Headphones x1
('ORD1003', 'P004',  3,   120.00),   -- Notebook x3
('ORD1004', 'P001',  2, 55000.00),   -- Laptop x2
('ORD1022', 'P002',  5,   800.00),   -- Mouse x5
('ORD1027', 'P004',  4,   120.00),   -- Notebook x4
('ORD1037', 'P007',  2,   250.00),   -- Pen Set x2
('ORD1075', 'P003',  3,  8500.00),   -- Desk Chair x3
('ORD1083', 'P007',  2,   250.00),   -- Pen Set x2
('ORD1091', 'P006',  3, 22000.00),   -- Standing Desk x3
('ORD1185', 'P008',  1,  2100.00);   -- Webcam x1 (only order for this product)
