-- ============================================================
-- Part 3: Data Warehouse Analytical Queries
-- Run after executing star_schema.sql
-- ============================================================

-- Q1: Total sales revenue by product category for each month
SELECT
    dd.year,
    dd.month,
    dd.month_name,
    dp.category,
    SUM(fs.total_revenue)           AS total_revenue,
    SUM(fs.units_sold)              AS total_units_sold,
    COUNT(fs.transaction_id)        AS num_transactions
FROM fact_sales fs
JOIN dim_date    dd ON fs.date_id    = dd.date_id
JOIN dim_product dp ON fs.product_id = dp.product_id
GROUP BY
    dd.year,
    dd.month,
    dd.month_name,
    dp.category
ORDER BY
    dd.year,
    dd.month,
    total_revenue DESC;

-- Q2: Top 2 performing stores by total revenue
SELECT
    ds.store_name,
    ds.store_city,
    SUM(fs.total_revenue)           AS total_revenue,
    SUM(fs.units_sold)              AS total_units_sold,
    COUNT(fs.transaction_id)        AS total_transactions
FROM fact_sales fs
JOIN dim_store ds ON fs.store_id = ds.store_id
GROUP BY
    ds.store_id,
    ds.store_name,
    ds.store_city
ORDER BY total_revenue DESC
LIMIT 2;

-- Q3: Month-over-month sales trend across all stores
-- Uses LAG() window function to compute previous month revenue
-- and derive month-over-month growth percentage
SELECT
    dd.year,
    dd.month,
    dd.month_name,
    SUM(fs.total_revenue)                                           AS monthly_revenue,
    SUM(fs.units_sold)                                              AS monthly_units,
    LAG(SUM(fs.total_revenue)) OVER (
        ORDER BY dd.year, dd.month
    )                                                               AS prev_month_revenue,
    ROUND(
        100.0 * (
            SUM(fs.total_revenue)
            - LAG(SUM(fs.total_revenue)) OVER (ORDER BY dd.year, dd.month)
        )
        / NULLIF(
            LAG(SUM(fs.total_revenue)) OVER (ORDER BY dd.year, dd.month),
        0),
    2)                                                              AS mom_growth_percent
FROM fact_sales fs
JOIN dim_date dd ON fs.date_id = dd.date_id
GROUP BY
    dd.year,
    dd.month,
    dd.month_name
ORDER BY
    dd.year,
    dd.month;
