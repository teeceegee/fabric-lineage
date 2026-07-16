# Pipeline Summary - dev-prescriptions-process

## Quick Overview

### 🎯 Orchestrator Pipelines (4)
Master pipelines that coordinate end-to-end data processing:

1. **eps_process_all** (Daily 08:00)
   - Orchestrates EPS data flow: Bronze → Silver → Gold
   - 3 activities: Sequential pipeline execution
   
2. **pl_finance_daily_master** (Manual)
   - Daily finance data processing
   - 4 activities: Notebook start, Bronze load, conditional monthly check, email notification
   
3. **pl_finance_monthly_master** (Manual)
   - Monthly finance aggregation
   - 4 activities: Notebook start, Silver load, Gold load, email notification
   
4. **pl_epact_monthly_master** (Manual)
   - Monthly ePACT processing
   - 7 activities: Notebook orchestration, LLF bronze/silver/gold pipelines, SOW4 pipeline, email notification

### 🟤 Bronze Layer (9 pipelines)
Raw data ingestion with complex loading patterns:

- **eps_process_bronze** (17 activities): Multi-stage EPS data loading with serial/parallel processing, verification, error handling
- **eps_process_bronze_copy2** (17 activities): Backup/variant of EPS bronze loading
- **pl_finance_bronze_load** (18 activities): Finance data ingestion with parallel loading and verification
- **pl_finance_bronze_load_test** (5 activities): Test version of finance bronze pipeline
- **pl_cip_bronze_monthly** (12 activities): CIP monthly data extraction and loading
- **Pl_Cip_Bronze_Monthly_Loader** (6 activities): Alternative CIP monthly loader
- **pl_llf_bronze_load** (9 activities): LLF data bronze layer processing
- **pl_etp_bronze_daily** (8 activities): ETP daily bronze ingestion
- **pl_etp_bronze_daily_load** (7 activities): Alternative ETP bronze loader

### ⚪ Silver Layer (5 pipelines)
Data cleansing and transformation:

- **eps_process_silver** (8 activities): EPS silver layer processing
- **mys_process_silver** (6 activities): MYS data silver transformation
- **pl_finance_silver_load** (10 activities): Finance silver layer with copy/notebook activities
- **pl_llf_silver_load** (9 activities): LLF silver layer processing
- **pl_cip_silver_layer_monthly** (9 activities): CIP monthly silver transformation

### 🟡 Gold Layer (5 pipelines)
Business-ready aggregates and analytics:

- **eps_process_gold** (8 activities): EPS gold layer analytics
- **mys_process_gold** (8 activities): MYS gold layer processing
- **pl_finance_gold_load** (11 activities): Finance gold layer with ForEach loops and verification
- **pl_llf_gold_load** (9 activities): LLF gold layer aggregates
- **pl_sow4_gold_load** (6 activities): SOW4 gold layer processing

### 🔵 Extract Pipelines (9)
BAU extracts from source systems:

- **BAU CIP daily schema extract** (9 activities, Weekly): CIP daily data extraction
- **BAU CIP monthly schema extract** (9 activities): CIP monthly extraction
- **BAU DPC daily schema extract** (9 activities, Weekly): DPC daily extraction
- **BAU DPC monthly schema extract** (9 activities): DPC monthly extraction
- **BAU HOT monthly schema extract** (8 activities): HOT monthly extraction
- **BAU PCD monthly schema extract** (9 activities): PCD monthly extraction
- **BAU PHA daily schema extract** (9 activities, Weekly): PHA daily extraction
- **Data Gateway extract pipeline ETP** (6 activities): ETP gateway extraction
- **BAU CIP monthly schema extract OLD** (4 activities, Disabled): Legacy CIP extractor

### ⚙️ Utility Pipelines (13)
Support and maintenance operations:

- **Table maintenance** (3 activities): Database table maintenance operations
- **Refresh semantic model** (1 activity): Power BI semantic model refresh
- **sow11_pipeline** (10 activities, Weekly): SOW11 processing workflow
- **sow11_create_semantic_model** (3 activities): SOW11 semantic model creation
- **pl_csv_to_parquet** (4 activities): File format conversion utility
- Plus 8 test/variant pipelines for finance and other processes

## Common Activity Patterns

### 📓 Notebook Execution (TridentNotebook)
Most pipelines use Fabric notebooks for data processing:
- Table creation/schema management
- Data transformation logic
- Verification checks
- Job list generation for loops

### 🔁 ForEach Loops
Parallel and serial data loading:
- Serial_Load_1/2: Sequential processing of job lists
- Parallel_Load_1: Concurrent data loading for performance

### ✅ Verification & Error Handling
Robust data quality checks:
- End-of-pipeline verification notebooks
- Conditional email notifications on failure
- Fail activities to stop execution on errors

### 📧 Email Notifications (Office365Outlook)
Status updates sent to stakeholders:
- Pipeline start notifications
- Completion confirmations
- Error alerts with details

### 🔀 Conditional Logic (IfCondition)
Dynamic execution paths:
- Monthly vs daily processing decisions
- Verification pass/fail routing
- Error handling branches

## Key Insights

1. **Medallion Architecture**: Clear bronze → silver → gold layer separation
2. **Orchestrated Workflows**: Master pipelines coordinate multi-stage processing
3. **Error Resilience**: Email notifications and fail activities ensure visibility
4. **Scheduled Automation**: Daily (08:00) and weekly schedules for regular extracts
5. **Parallel Processing**: ForEach loops optimize data loading performance
6. **Verification-Driven**: End-of-pipeline checks ensure data quality

---

**For detailed activity-level documentation**, see [pipeline-documentation.md](pipeline-documentation.md)
