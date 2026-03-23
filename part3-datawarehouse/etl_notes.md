## ETL Decisions

### Decision 1 — Standardizing Three Mixed Date Formats
**Problem:** The `date` column in `retail_transactions.csv` contained dates written in at least three different formats within the same column: ISO format (`2023-02-05`), slash-separated day-first (`29/08/2023`), and hyphen-separated day-first (`12-12-2023`, `20-02-2023`). This made direct loading into a DATE column impossible — a naive load would either fail or silently misinterpret day and month (e.g., `12-12-2023` could be parsed as December 12th or the 12th of December depending on locale, but `20-02-2023` can only mean Feb 20th, confirming day-first ordering).

**Resolution:** A multi-format date parser was applied during transformation. Each date string was attempted against three format patterns in order: `%Y-%m-%d`, `%d/%m/%Y`, and `%d-%m-%Y`. The first matching pattern was used to produce a standardized `YYYY-MM-DD` string. A surrogate `date_id` in `YYYYMMDD` integer format was then derived (e.g., `2023-08-29` → `20230829`) for efficient foreign key joining with `dim_date`. All 300 rows were successfully parsed with no data loss.

---

### Decision 2 — Normalizing Inconsistent Category Casing
**Problem:** The `category` column contained five distinct string variants for what are actually three categories: `'electronics'`, `'Electronics'`, `'Grocery'`, `'Groceries'`, and `'Clothing'`. The two electronics variants and two grocery variants each represented the same business category but would be treated as separate groups in any `GROUP BY` query — causing revenue totals to be silently fragmented and incomplete. For example, a query for total Electronics revenue would miss all rows labelled `'electronics'`.

**Resolution:** A canonical mapping dictionary was applied: `{'electronics': 'Electronics', 'Electronics': 'Electronics', 'Grocery': 'Groceries', 'Groceries': 'Groceries', 'Clothing': 'Clothing'}`. All category values were trimmed of whitespace before mapping. The cleaned value was stored in `dim_product.category`. This ensures all downstream `GROUP BY category` aggregations produce complete, correct totals across all 300 transactions.

---

### Decision 3 — Imputing NULL Values in store_city
**Problem:** 19 out of 300 rows had a NULL value in the `store_city` column, despite a valid `store_name` being present in every row. The affected store names included `'Mumbai Central'`, `'Chennai Anna'`, `'Delhi South'`, and `'Pune FC Road'`. Loading these rows without a city value would make city-level analysis incomplete — store-level queries would work, but any geographic aggregation (e.g., revenue by city) would drop or miscount those 19 transactions.

**Resolution:** Since `store_name` is a deterministic identifier for a physical location, a lookup dictionary was used to derive `store_city` from `store_name`: `{'Chennai Anna': 'Chennai', 'Delhi South': 'Delhi', 'Bangalore MG': 'Bangalore', 'Pune FC Road': 'Pune', 'Mumbai Central': 'Mumbai'}`. This mapping was applied to all rows where `store_city` was NULL. All 19 affected rows were successfully enriched, and the derived city was stored in `dim_store.store_city`. No rows were dropped.
