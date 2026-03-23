-- ============================================================
-- Part 3: Star Schema Design — Retail Data Warehouse
-- Source: retail_transactions.csv (300 rows, 9 columns)
-- Data issues found and fixed before loading:
--   1. Three mixed date formats → standardized to YYYY-MM-DD
--   2. Category casing mess (electronics/Electronics/Grocery) → Title Case
--   3. 19 NULL store_city values → derived from store_name lookup
-- ============================================================

DROP TABLE IF EXISTS fact_sales;
DROP TABLE IF EXISTS dim_date;
DROP TABLE IF EXISTS dim_store;
DROP TABLE IF EXISTS dim_product;

-- ------------------------------------------------------------
-- Dimension: dim_date
-- Surrogate key format: YYYYMMDD integer
-- Enables fast time-based slicing without string parsing at query time
-- ------------------------------------------------------------
CREATE TABLE dim_date (
    date_id         INT             PRIMARY KEY,
    full_date       DATE            NOT NULL,
    day             INT             NOT NULL,
    month           INT             NOT NULL,
    month_name      VARCHAR(20)     NOT NULL,
    quarter         INT             NOT NULL,
    year            INT             NOT NULL,
    day_of_week     VARCHAR(15)     NOT NULL,
    is_weekend      BOOLEAN         NOT NULL DEFAULT FALSE
);

INSERT INTO dim_date (date_id, full_date, day, month, month_name, quarter, year, day_of_week, is_weekend) VALUES
(20230115, '2023-01-15', 15,  1, 'January',  1, 2023, 'Sunday',    TRUE),
(20230205, '2023-02-05',  5,  2, 'February', 1, 2023, 'Sunday',    TRUE),
(20230220, '2023-02-20', 20,  2, 'February', 1, 2023, 'Monday',    FALSE),
(20230331, '2023-03-31', 31,  3, 'March',    1, 2023, 'Friday',    FALSE),
(20230428, '2023-04-28', 28,  4, 'April',    2, 2023, 'Friday',    FALSE),
(20230521, '2023-05-21', 21,  5, 'May',      2, 2023, 'Sunday',    TRUE),
(20230604, '2023-06-04',  4,  6, 'June',     2, 2023, 'Sunday',    TRUE),
(20230809, '2023-08-09',  9,  8, 'August',   3, 2023, 'Wednesday', FALSE),
(20230815, '2023-08-15', 15,  8, 'August',   3, 2023, 'Tuesday',   FALSE),
(20230829, '2023-08-29', 29,  8, 'August',   3, 2023, 'Tuesday',   FALSE),
(20231020, '2023-10-20', 20, 10, 'October',  4, 2023, 'Friday',    FALSE),
(20231026, '2023-10-26', 26, 10, 'October',  4, 2023, 'Thursday',  FALSE),
(20231118, '2023-11-18', 18, 11, 'November', 4, 2023, 'Saturday',  TRUE),
(20231208, '2023-12-08',  8, 12, 'December', 4, 2023, 'Friday',    FALSE),
(20231212, '2023-12-12', 12, 12, 'December', 4, 2023, 'Tuesday',   FALSE);

-- ------------------------------------------------------------
-- Dimension: dim_store
-- 5 unique stores from retail_transactions.csv
-- store_city: 19 NULLs in source resolved by mapping store_name → city
-- ------------------------------------------------------------
CREATE TABLE dim_store (
    store_id        INT             PRIMARY KEY,
    store_name      VARCHAR(150)    NOT NULL,
    store_city      VARCHAR(100)    NOT NULL
);

INSERT INTO dim_store (store_id, store_name, store_city) VALUES
(1, 'Bangalore MG',   'Bangalore'),
(2, 'Chennai Anna',   'Chennai'),
(3, 'Delhi South',    'Delhi'),
(4, 'Mumbai Central', 'Mumbai'),
(5, 'Pune FC Road',   'Pune');

-- ------------------------------------------------------------
-- Dimension: dim_product
-- 16 unique products across 3 standardized categories
-- Raw category variants → cleaned mapping applied during ETL:
--   'electronics' | 'Electronics' → 'Electronics'
--   'Grocery' | 'Groceries'       → 'Groceries'
--   'Clothing'                    → 'Clothing'
-- ------------------------------------------------------------
CREATE TABLE dim_product (
    product_id      INT             PRIMARY KEY,
    product_name    VARCHAR(200)    NOT NULL,
    category        VARCHAR(100)    NOT NULL
);

INSERT INTO dim_product (product_id, product_name, category) VALUES
(1,  'Atta 10kg',  'Groceries'),
(2,  'Biscuits',   'Groceries'),
(3,  'Headphones', 'Electronics'),
(4,  'Jacket',     'Clothing'),
(5,  'Jeans',      'Clothing'),
(6,  'Laptop',     'Electronics'),
(7,  'Milk 1L',    'Groceries'),
(8,  'Oil 1L',     'Groceries'),
(9,  'Phone',      'Electronics'),
(10, 'Pulses 1kg', 'Groceries'),
(11, 'Rice 5kg',   'Groceries'),
(12, 'Saree',      'Clothing'),
(13, 'Smartwatch', 'Electronics'),
(14, 'Speaker',    'Electronics'),
(15, 'T-Shirt',    'Clothing'),
(16, 'Tablet',     'Electronics');

-- ------------------------------------------------------------
-- Fact Table: fact_sales
-- Grain: one row per transaction line (product sold at a store on a date)
-- Measures: units_sold, unit_price, total_revenue
-- total_revenue = units_sold * unit_price (pre-computed for query speed)
-- Full dataset totals by store: Pune FC Road ₹2.81Cr | Chennai ₹2.79Cr
--                               Bangalore ₹2.66Cr | Delhi ₹2.19Cr | Mumbai ₹1.71Cr
-- ------------------------------------------------------------
CREATE TABLE fact_sales (
    transaction_id  VARCHAR(15)     PRIMARY KEY,
    date_id         INT             NOT NULL,
    store_id        INT             NOT NULL,
    product_id      INT             NOT NULL,
    units_sold      INT             NOT NULL,
    unit_price      DECIMAL(12,2)   NOT NULL,
    total_revenue   DECIMAL(14,2)   NOT NULL,
    CONSTRAINT chk_units CHECK (units_sold > 0),
    CONSTRAINT chk_rev   CHECK (total_revenue >= 0),
    FOREIGN KEY (date_id)    REFERENCES dim_date(date_id),
    FOREIGN KEY (store_id)   REFERENCES dim_store(store_id),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id)
);

-- 15 real transactions from retail_transactions.csv (post-ETL cleaning)
INSERT INTO fact_sales (transaction_id, date_id, store_id, product_id, units_sold, unit_price, total_revenue) VALUES
('TXN5000', 20230829, 2, 14,  3, 49262.78,  147788.34),
('TXN5001', 20231212, 2, 16, 11, 23226.12,  255487.32),
('TXN5002', 20230205, 2,  9, 20, 48703.39,  974067.80),
('TXN5003', 20230220, 3, 16, 14, 23226.12,  325165.68),
('TXN5004', 20230115, 2, 13, 10, 58851.01,  588510.10),
('TXN5005', 20230809, 1,  1, 12, 52464.00,  629568.00),
('TXN5006', 20230331, 5, 13,  6, 58851.01,  353106.06),
('TXN5007', 20231026, 5,  5, 16,  2317.47,   37079.52),
('TXN5008', 20231208, 1,  2,  9, 27469.99,  247229.91),
('TXN5009', 20230815, 1, 13,  3, 58851.01,  176553.03),
('TXN5010', 20230604, 2,  4, 15, 30187.24,  452808.60),
('TXN5011', 20231020, 4,  5, 13,  2317.47,   30127.11),
('TXN5012', 20230521, 1,  6, 13, 42343.15,  550460.95),
('TXN5013', 20230428, 4,  7, 10, 43374.39,  433743.90),
('TXN5014', 20231118, 3,  4,  5, 30187.24,  150936.20);
