# nb_silver_maintenance

## Overview
This notebook is a maintenance and schema-management notebook for the Silver layer in the Prescriptions Fabric environment. It contains ad hoc and repeatable SQL/PySpark operations used to inspect, create, alter, and correct Silver tables, with a strong focus on finance and organisation datasets.

## Primary Purpose
- Validate current Silver table structures and sample data.
- Apply one-off schema fixes (add/drop columns, datatype alignment, metadata columns).
- Rebuild or reshape selected Silver tables used by downstream reporting and Gold models.
- Reconcile record counts and values between Silver and source/reference datasets.

## Main Data Domains
- `silver_fin` and `finance` tables (for remuneration, expense, and payment data).
- `organisation` flat dimensions (current and historic views).
- `epact`/`drug` data used in Silver transformations.

## What The Notebook Does
The notebook includes many maintenance operations across hundreds of cells. Typical operations include:

1. Environment setup and Spark config
- Sets Spark/Delta options for schema merge and partition overwrite behavior.

2. Structure inspection and validation
- Uses `DESC` and `SELECT` queries to inspect table schemas and sample data.
- Compares counts and values for specific periods (commonly by `year_month`).

3. Table creation and recreation
- Creates or recreates Delta tables, often partitioned by `year_month`.
- Creates staging and reshaped tables for downstream use.

4. Schema evolution and correction
- Adds metadata columns (for example current-record and timestamp columns).
- Adds/removes business key and surrogate key columns.

5. Data correction and maintenance actions
- Runs targeted `UPDATE`, `DELETE`, and occasional `DROP TABLE` / `CREATE TABLE` flows.
- Performs corrective data loads for finance and organisation dimensions/facts.

6. Reconciliation and QA checks
- Compares Silver results against source or reference datasets.
- Runs period-specific checks and row-count validations before/after changes.

## Notable Objects Touched
Examples seen in the notebook include:
- `silver_fin.fin_remuneration_fact`
- `silver_fin.fin_expense_head_dim`
- `silver_fin.fin_dpc_schedule_fact`
- `silver_fin.slr_unmapped_pharm_pay_fact`
- `silver_fin.slr_hs_dy_level_5_flat_dim`
- `silver_fin.slr_mdr_dy_level_4_dim`
- `epact.px_form_item_element_combined_fact` and related staging/temporary tables

## Operational Characteristics
- The notebook is long and iterative, with many experimental and validation cells.
- Several cells are one-off fixes rather than a strict linear pipeline.
- It should be treated as a maintenance workbook, not a clean production orchestration notebook.

## Risks and Review Notes
- Contains destructive operations (`DROP TABLE`, `DELETE`) mixed with validation queries.
- Re-running end-to-end without guardrails could overwrite or remove data.
- Best used with clear run scope (specific sections/cells) and environment checks.

## Suggested Next Documentation Enhancements
- Tag cells into logical sections (setup, schema fixes, finance maintenance, QA).
- Add a change log (date, author, purpose) for each maintenance block.
- Identify which cells are safe to rerun vs one-time corrective operations.
