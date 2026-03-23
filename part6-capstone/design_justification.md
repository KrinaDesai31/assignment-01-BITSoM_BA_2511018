## Storage Systems

The hospital network's four goals require four distinct storage layers, each chosen for a specific data access pattern:

**Goal 1 — Predict patient readmission risk (ML on historical treatment data):** The primary store is a **columnar data warehouse** (e.g., Google BigQuery or Amazon Redshift). Historical treatment records — diagnoses, medications, lab results, length of stay, discharge summaries — are structured, schema-stable, and need to be aggregated over large time windows for feature engineering. A columnar format dramatically accelerates the analytical scans (e.g., "all patients with diabetes readmitted within 30 days over the past 5 years") that produce training data. Processed feature sets are stored in **object storage** (S3/GCS) as Parquet files for model training pipelines.

**Goal 2 — Plain-English queries over patient history:** This goal requires a **vector database** (e.g., Pinecone, Weaviate, or pgvector on PostgreSQL) alongside a large language model in a Retrieval-Augmented Generation (RAG) pipeline. Patient history documents — discharge summaries, clinical notes, diagnostic reports — are chunked, embedded using a biomedical language model (e.g., BioBERT or ClinicalBERT), and stored as vector embeddings. When a doctor asks "Has this patient had a cardiac event before?", the query is embedded and the vector DB retrieves the most semantically relevant passages from the patient's history. The LLM then synthesizes a cited, readable answer. Keyword search alone cannot handle the lexical variation in clinical language.

**Goal 3 — Monthly management reports (bed occupancy, department costs):** A **star-schema data warehouse** (same BigQuery/Redshift instance as Goal 1, separate dataset) powers OLAP reporting. A `fact_occupancy` table records daily bed utilization per ward; a `fact_costs` table tracks department-level expenditures. Dimension tables for `dim_date`, `dim_department`, and `dim_ward` enable standard BI slicing. Reports are generated via a BI tool (e.g., Looker, Tableau) querying the warehouse directly on a scheduled basis.

**Goal 4 — Real-time ICU vitals streaming and storage:** A **time-series database** (e.g., InfluxDB or TimescaleDB) is the primary store for high-frequency sensor readings (heart rate, SpO2, blood pressure sampled every few seconds per patient). An **Apache Kafka** streaming pipeline ingests raw device data, applies threshold alerting in real time (triggering alarms if vitals cross danger thresholds), and writes cleaned, downsampled data to the time-series DB for trend visualization. Raw high-frequency data older than 90 days is archived to cold object storage.

---

## OLTP vs OLAP Boundary

The transactional system (OLTP) ends at the **point of care** — it encompasses the EMR/EHR system where doctors record diagnoses, nurses log medication administrations, and front-desk staff manage admissions and discharges. This system (e.g., running on a relational OLTP database like PostgreSQL or Oracle) is optimized for low-latency reads and writes with strict ACID guarantees: a prescription update must be immediately consistent, a new allergy recorded must never be partially visible.

The analytical system (OLAP) begins at the **ETL/ELT boundary** — a nightly or near-real-time pipeline (e.g., Apache Airflow orchestrating dbt transformations) extracts data from the OLTP EMR, cleans and standardizes it, and loads it into the data warehouse. The warehouse is never written to by clinical applications — it is a read-optimized copy of truth. ICU streaming data bypasses the OLTP layer entirely: it goes directly from Kafka into the time-series DB, with aggregated summaries flowing into the warehouse for reporting. The vector database is populated from a separate pipeline that processes clinical notes from the EMR — also outside the OLTP transaction boundary.

---

## Trade-offs

**Trade-off: Data consistency lag between OLTP and analytical layers.** The most significant trade-off in this design is that the data warehouse and vector database are not real-time mirrors of the EMR. ETL pipelines introduce a lag — typically 15 minutes to 24 hours depending on pipeline frequency. This means the readmission risk model and management reports may be based on data that is slightly stale. In a healthcare context, this is acceptable for retrospective analytics (monthly reports, ML training) but would be dangerous if the readmission prediction were used for real-time clinical decisions on a patient currently in care.

**Mitigation:** Two strategies reduce this risk. First, clearly label all analytical outputs with a "data as of" timestamp so clinicians and managers know the recency of what they are viewing. Second, for time-sensitive predictions (e.g., flagging a patient currently in ICU as high-risk for readmission), use the streaming Kafka pipeline to trigger near-real-time model inference using the patient's latest vitals from the time-series DB — bypassing the warehouse batch lag entirely. The batch warehouse remains the source of truth for model training and reporting; the streaming path handles real-time inference for active patients.
