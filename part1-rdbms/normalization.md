## Anomaly Analysis

### Insert Anomaly
In `orders_flat.csv`, all information about a sales representative is stored only within order rows. The dataset contains only three reps: SR01 (Deepak Joshi), SR02 (Anita Desai), and SR03 (Ravi Kumar). If the company hires a new sales representative — say SR04 — there is no way to record their name, email, or `office_address` in the flat file without first creating a fake or placeholder order row. The representative's existence is entirely dependent on having at least one associated order. This means legitimate business operations (onboarding new staff, configuring territory assignments) are blocked by the database design itself.

### Update Anomaly
Sales rep SR01 (Deepak Joshi) appears in over 80 rows in `orders_flat.csv`. His `office_address` is stored redundantly across every one of these rows — and the inconsistency has already materialized in the actual dataset: rows ORD1114, ORD1083, ORD1091 store `"Mumbai HQ, Nariman Point, Mumbai - 400021"`, while rows ORD1180, ORD1170, ORD1182, ORD1175, ORD1176 store the abbreviated `"Mumbai HQ, Nariman Pt, Mumbai - 400021"` — the same fact recorded in two different forms. If the address needs to be officially updated, all 80+ rows must be changed simultaneously and perfectly. Missing even one creates a data contradiction. This is not a hypothetical — the inconsistency is already present in the provided file.

### Delete Anomaly
Product P008 (Webcam, Electronics, ₹2,100) appears in exactly **one** order in the entire dataset: `ORD1185`, placed by customer C003 (Amit Verma). If this order row is deleted — for example because the order was cancelled and removed from records — all information about the Webcam product is permanently lost: its name, category, and unit price vanish with the row. There is no separate product table to preserve its existence. The product cannot be re-listed, reported on, or priced without being recreated from memory or external records.

---

## Normalization Justification

A manager who argues that one flat table is simpler has not yet encountered the cost of that simplicity at scale. The `orders_flat.csv` dataset is a textbook demonstration of why normalization exists — not as academic over-engineering, but as a practical response to real failures that already appear in this very file.

Consider SR01 (Deepak Joshi). His office address appears in over 80 rows, and already within this single dataset it exists in two contradictory forms — "Nariman Point" in most rows, "Nariman Pt" in several others. This is not a hypothetical future risk: it is an existing data inconsistency in the file we were given. In a normalized `sales_reps` table, Deepak Joshi has one row. His address is updated once. The flat design failed to maintain consistency even at 186 rows — at 186,000 rows, the damage would be unquantifiable.

The delete anomaly for P008 (Webcam) is equally concrete. It appears in exactly one order, ORD1185. If that order is removed, the Webcam product disappears from the system entirely — its existence is not preserved anywhere. A normalized `products` table stores the product independently of whether it has ever been ordered, allowing it to be managed, reported on, and queried at any time.

The insert anomaly creates a hard operational constraint: no new sales rep can be added to the system until they process their first order. This means the company cannot onboard staff in the system, pre-assign accounts, or grant system access before the first sale — a nonsensical restriction imposed purely by the flat table design.

Normalization's cost is a few extra `CREATE TABLE` statements and `JOIN` clauses in queries. Its benefit is a system where every fact is stored once, changed once, and cannot accidentally erase itself. The manager's "simplicity" is an illusion — it is complexity deferred until it becomes a crisis.
