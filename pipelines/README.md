# Pipeline Inventory - dev-prescriptions-process

## Workspace Information
- **Workspace ID**: e8c421cf-979f-450a-94b4-e2010e807479
- **Workspace Name**: dev-prescriptions-process
- **Total Pipelines**: 45
- **Retrieved**: 2026-07-14

## Pipeline Categories

### Finance Pipelines (15)
- pl_finance_test
- pl_finance_end_to_end
- pl_finance_test2
- pl_finance_daily
- pl_finance_monthly
- pl_finance_bronze_load_test
- pl_finance_bronze_load
- pl_finance_daily_master
- pl_finance_silver_load
- pl_finance_gold_load
- pl_finance_monthly_master

### EPS (Electronic Prescription Service) Pipelines (5)
- eps_process_all
- eps_process_bronze
- eps_process_bronze_copy2
- eps_process_silver
- eps_process_gold

### MYS Pipelines (2)
- mys_process_silver
- mys_process_gold

### EPACT Pipelines (1)
- pl_epact_monthly_master

### CIP (Community Information Product) Pipelines (6)
- pl_cip_bronze_monthly
- Pl_Cip_Bronze_Monthly_Loader
- BAU CIP monthly schema extract OLD
- BAU CIP monthly schema extract
- BAU CIP daily schema extract
- pl_cip_silver_layer_monthly

### LLF (Latest Level Flat) Pipelines (3)
- pl_llf_bronze_load
- pl_llf_silver_load
- pl_llf_gold_load

### BAU Extract Pipelines (7)
- BAU PHA daily schema extract
- BAU PCD monthly schema extract
- BAU DPC monthly schema extract
- BAU DPC daily schema extract
- BAU HOT monthly schema extract
- Data Gateway extract pipeline ETP

### ETP Pipelines (2)
- pl_etp_bronze_daily
- pl_etp_bronze_daily_load

### SOW11 Pipelines (4)
- sow11_pipeline
- sow11_pipeline_copy1
- sow11_epact_sm_creation_pipeline
- sow11_create_semantic_model

### Utility Pipelines (4)
- pl_csv_to_parquet
- Table maintenance
- Refresh semantic model
- Suture Run for 1.3
- pl_sow4_gold_load

## Limitation Notice

**Note**: The Fabric API tools currently available do not support exporting the full pipeline definition JSON. This inventory provides the pipeline metadata (ID, name, type) but not the complete pipeline structure including:
- Activities and their configuration
- Dependencies and scheduling
- Parameters and variables
- Linked services and connections

To export full pipeline definitions, you would need to:
1. Use the Fabric Portal's export functionality
2. Use PowerShell with the Fabric REST API directly
3. Request enhanced MCP tools that support pipeline definition export

## Exporting Pipeline Definitions

A PowerShell script has been created to automate the export of all pipeline definitions:

**Script**: `../Export-FabricPipelines.ps1`

### Usage

```powershell
# Run from the mapping directory
.\Export-FabricPipelines.ps1
```

### What the script does:
1. Authenticates to Microsoft Fabric using browser-based SSO
2. Reads the pipeline inventory from `pipeline_inventory.json`
3. Calls the Fabric REST API for each pipeline to get its full definition
4. Saves each pipeline definition to `pipelines/[pipeline-name].json`
5. Creates an export summary with success/failure counts

### Requirements:
- PowerShell 7.0 or later
- Az.Accounts module (auto-installed if missing)
- Azure account with access to the dev-prescriptions-process workspace

### Output:
- Individual pipeline JSON files: `pipelines/[pipeline-name].json`
- Export summary: `pipelines/export_summary.json`

## Next Steps

After running the export script, you can:
- Review individual pipeline definitions for dependencies and schedules
- Document pipeline orchestration patterns
- Version control the pipeline definitions
- Compare pipeline configurations across environments
