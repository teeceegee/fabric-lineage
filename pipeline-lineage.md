# Pipeline Layer Lineage

Generated: 2026-07-20 10:10:32

This report shows pipeline-level lineage across the medallion layers using exported Fabric pipeline definitions. It is reliable for pipeline-to-pipeline movement, but notebook-internal and table-level lineage remains partially hidden where pipelines dispatch metadata-driven notebook jobs.

## Coverage

- Pipelines parsed: 45
- Inter-pipeline links found: 10
- Cross-layer links found: 10

### Pipelines by category

- bronze: 9
- extract: 9
- gold: 5
- orchestrator: 4
- silver: 5
- utility: 13

## Layer transition matrix

- orchestrator -> bronze: 3 link(s) | pl_epact_monthly_master -> pl_llf_bronze_load; eps_process_all -> eps_process_bronze_copy2; pl_finance_daily_master -> pl_finance_bronze_load
- orchestrator -> gold: 4 link(s) | pl_epact_monthly_master -> pl_llf_gold_load; pl_epact_monthly_master -> pl_sow4_gold_load; eps_process_all -> eps_process_gold
- orchestrator -> silver: 3 link(s) | pl_epact_monthly_master -> pl_llf_silver_load; eps_process_all -> eps_process_silver; pl_finance_monthly_master -> pl_finance_silver_load

## Domain flows

### BAU Extracts

Pipelines:
- BAU DPC daily schema extract [extract]
- BAU DPC monthly schema extract [extract]
- BAU HOT monthly schema extract [extract]
- BAU PCD monthly schema extract [extract]
- BAU PHA daily schema extract [extract]

No explicit child-pipeline links were found for this domain in the exported definitions. Any movement here is likely inside notebooks or metadata-driven foreach jobs.

### CIP

Pipelines:
- pl_cip_bronze_monthly [bronze]
- Pl_Cip_Bronze_Monthly_Loader [bronze]
- BAU CIP daily schema extract [extract]
- BAU CIP monthly schema extract [extract]
- BAU CIP monthly schema extract OLD [extract]
- pl_cip_silver_layer_monthly [silver]

Inferred layer path:
- extract -> bronze -> silver

No explicit child-pipeline links were found for this domain in the exported definitions. Any movement here is likely inside notebooks or metadata-driven foreach jobs.

### CSV Utility

Pipelines:
- pl_csv_to_parquet [utility]

No explicit child-pipeline links were found for this domain in the exported definitions. Any movement here is likely inside notebooks or metadata-driven foreach jobs.

### ePACT

Pipelines:
- pl_epact_monthly_master [orchestrator]
- sow11_epact_sm_creation_pipeline [utility]

Mermaid view:

```mermaid
flowchart LR
    pl_epact_monthly_master[pl_epact_monthly_master [orchestrator]]
    pl_llf_bronze_load[pl_llf_bronze_load [bronze]]
    pl_llf_silver_load[pl_llf_silver_load [silver]]
    pl_llf_gold_load[pl_llf_gold_load [gold]]
    pl_sow4_gold_load[pl_sow4_gold_load [gold]]
    sow11_epact_sm_creation_pipeline[sow11_epact_sm_creation_pipeline [utility]]
    pl_epact_monthly_master -->|Invoke llf silver pipeline| pl_llf_silver_load
    pl_epact_monthly_master -->|Invoke llf gold pipeline| pl_llf_gold_load
    pl_epact_monthly_master -->|Invoke llf bronze pipeline| pl_llf_bronze_load
    pl_epact_monthly_master -->|Invoke Sow4 pipeline| pl_sow4_gold_load
```

Pipeline transitions:
- pl_epact_monthly_master [orchestrator] -> pl_llf_silver_load [silver] via Invoke llf silver pipeline
- pl_epact_monthly_master [orchestrator] -> pl_llf_gold_load [gold] via Invoke llf gold pipeline
- pl_epact_monthly_master [orchestrator] -> pl_llf_bronze_load [bronze] via Invoke llf bronze pipeline
- pl_epact_monthly_master [orchestrator] -> pl_sow4_gold_load [gold] via Invoke Sow4 pipeline

### EPS

Pipelines:
- eps_process_bronze [bronze]
- eps_process_bronze_copy2 [bronze]
- eps_process_gold [gold]
- eps_process_all [orchestrator]
- eps_process_silver [silver]

Inferred layer path:
- orchestrator -> bronze -> silver -> gold

Mermaid view:

```mermaid
flowchart LR
    eps_process_all[eps_process_all [orchestrator]]
    eps_process_bronze[eps_process_bronze [bronze]]
    eps_process_bronze_copy2[eps_process_bronze_copy2 [bronze]]
    eps_process_silver[eps_process_silver [silver]]
    eps_process_gold[eps_process_gold [gold]]
    eps_process_all -->|eps_process_bronze| eps_process_bronze_copy2
    eps_process_all -->|eps_process_silver| eps_process_silver
    eps_process_all -->|eps_process_gold| eps_process_gold
```

Pipeline transitions:
- eps_process_all [orchestrator] -> eps_process_bronze_copy2 [bronze] via eps_process_bronze
- eps_process_all [orchestrator] -> eps_process_silver [silver] via eps_process_silver
- eps_process_all [orchestrator] -> eps_process_gold [gold] via eps_process_gold

### ETP

Pipelines:
- pl_etp_bronze_daily [bronze]
- pl_etp_bronze_daily_load [bronze]
- Data Gateway extract pipeline ETP [extract]

Inferred layer path:
- extract -> bronze

No explicit child-pipeline links were found for this domain in the exported definitions. Any movement here is likely inside notebooks or metadata-driven foreach jobs.

### Finance

Pipelines:
- pl_finance_bronze_load [bronze]
- pl_finance_bronze_load_test [bronze]
- pl_finance_gold_load [gold]
- pl_finance_daily_master [orchestrator]
- pl_finance_monthly_master [orchestrator]
- pl_finance_silver_load [silver]
- pl_finance_daily [utility]
- pl_finance_end_to_end [utility]
- pl_finance_monthly [utility]
- pl_finance_test [utility]
- pl_finance_test2 [utility]

Inferred layer path:
- orchestrator -> bronze -> silver -> gold

Mermaid view:

```mermaid
flowchart LR
    pl_finance_daily_master[pl_finance_daily_master [orchestrator]]
    pl_finance_monthly_master[pl_finance_monthly_master [orchestrator]]
    pl_finance_bronze_load[pl_finance_bronze_load [bronze]]
    pl_finance_bronze_load_test[pl_finance_bronze_load_test [bronze]]
    pl_finance_silver_load[pl_finance_silver_load [silver]]
    pl_finance_gold_load[pl_finance_gold_load [gold]]
    pl_finance_daily[pl_finance_daily [utility]]
    pl_finance_end_to_end[pl_finance_end_to_end [utility]]
    pl_finance_monthly[pl_finance_monthly [utility]]
    pl_finance_test[pl_finance_test [utility]]
    pl_finance_test2[pl_finance_test2 [utility]]
    pl_finance_daily_master -->|Invoke finance bronze pipeline| pl_finance_bronze_load
    pl_finance_monthly_master -->|Invoke silver pipeline| pl_finance_silver_load
    pl_finance_monthly_master -->|Invoke gold pipeline| pl_finance_gold_load
```

Pipeline transitions:
- pl_finance_daily_master [orchestrator] -> pl_finance_bronze_load [bronze] via Invoke finance bronze pipeline
- pl_finance_monthly_master [orchestrator] -> pl_finance_silver_load [silver] via Invoke silver pipeline
- pl_finance_monthly_master [orchestrator] -> pl_finance_gold_load [gold] via Invoke gold pipeline

### LLF

Pipelines:
- pl_llf_bronze_load [bronze]
- pl_llf_gold_load [gold]
- pl_llf_silver_load [silver]

Inferred layer path:
- bronze -> silver -> gold

Mermaid view:

```mermaid
flowchart LR
    pl_epact_monthly_master[pl_epact_monthly_master [orchestrator]]
    pl_llf_bronze_load[pl_llf_bronze_load [bronze]]
    pl_llf_silver_load[pl_llf_silver_load [silver]]
    pl_llf_gold_load[pl_llf_gold_load [gold]]
    pl_epact_monthly_master -->|Invoke llf silver pipeline| pl_llf_silver_load
    pl_epact_monthly_master -->|Invoke llf gold pipeline| pl_llf_gold_load
    pl_epact_monthly_master -->|Invoke llf bronze pipeline| pl_llf_bronze_load
```

Pipeline transitions:
- pl_epact_monthly_master [orchestrator] -> pl_llf_silver_load [silver] via Invoke llf silver pipeline
- pl_epact_monthly_master [orchestrator] -> pl_llf_gold_load [gold] via Invoke llf gold pipeline
- pl_epact_monthly_master [orchestrator] -> pl_llf_bronze_load [bronze] via Invoke llf bronze pipeline

### Maintenance

Pipelines:
- Table maintenance [utility]

No explicit child-pipeline links were found for this domain in the exported definitions. Any movement here is likely inside notebooks or metadata-driven foreach jobs.

### MYS

Pipelines:
- mys_process_gold [gold]
- mys_process_silver [silver]

Inferred layer path:
- silver -> gold

No explicit child-pipeline links were found for this domain in the exported definitions. Any movement here is likely inside notebooks or metadata-driven foreach jobs.

### Semantic Model

Pipelines:
- Refresh semantic model [utility]

No explicit child-pipeline links were found for this domain in the exported definitions. Any movement here is likely inside notebooks or metadata-driven foreach jobs.

### Shared or Utility

Pipelines:
- Suture Run for 1.3 [utility]

No explicit child-pipeline links were found for this domain in the exported definitions. Any movement here is likely inside notebooks or metadata-driven foreach jobs.

### SOW11

Pipelines:
- sow11_create_semantic_model [utility]
- sow11_pipeline [utility]
- sow11_pipeline_copy1 [utility]

No explicit child-pipeline links were found for this domain in the exported definitions. Any movement here is likely inside notebooks or metadata-driven foreach jobs.

### SOW4

Pipelines:
- pl_sow4_gold_load [gold]

No explicit child-pipeline links were found for this domain in the exported definitions. Any movement here is likely inside notebooks or metadata-driven foreach jobs.

## Gaps

The following layer pipelines appear to move data internally through lookup-driven notebook execution rather than explicit child-pipeline calls:

- pl_cip_bronze_monthly [bronze] - activity types: TridentNotebook, Lookup, ForEach, SetVariable
- pl_cip_silver_layer_monthly [silver] - activity types: TridentNotebook, Lookup, ForEach, SetVariable
- eps_process_bronze [bronze] - activity types: TridentNotebook, ForEach, IfCondition, Office365Outlook, Fail
- eps_process_bronze_copy2 [bronze] - activity types: TridentNotebook, ForEach, IfCondition, Office365Outlook, Fail
- eps_process_gold [gold] - activity types: TridentNotebook, ForEach, IfCondition, Office365Outlook, Fail
- eps_process_silver [silver] - activity types: TridentNotebook, ForEach, IfCondition, Office365Outlook, Fail
- pl_etp_bronze_daily [bronze] - activity types: TridentNotebook, Lookup, ForEach, SetVariable
- pl_etp_bronze_daily_load [bronze] - activity types: TridentNotebook, Lookup, ForEach, SetVariable
- pl_finance_bronze_load [bronze] - activity types: Lookup, ForEach, TridentNotebook, Office365Outlook, SetVariable
- pl_finance_bronze_load_test [bronze] - activity types: TridentNotebook
- pl_finance_gold_load [gold] - activity types: Lookup, ForEach, TridentNotebook, SetVariable, Office365Outlook
- pl_finance_silver_load [silver] - activity types: Lookup, ForEach, TridentNotebook, SetVariable, Office365Outlook
- pl_llf_bronze_load [bronze] - activity types: Lookup, ForEach, TridentNotebook, Office365Outlook, SetVariable
- pl_llf_gold_load [gold] - activity types: Lookup, ForEach, TridentNotebook, SetVariable, Office365Outlook
- pl_llf_silver_load [silver] - activity types: Lookup, ForEach, TridentNotebook, SetVariable, Office365Outlook
- mys_process_gold [gold] - activity types: TridentNotebook, ForEach, IfCondition, Office365Outlook, Fail
- mys_process_silver [silver] - activity types: TridentNotebook, ForEach, IfCondition, Office365Outlook, Fail
- pl_sow4_gold_load [gold] - activity types: Lookup, ForEach, TridentNotebook, SetVariable, Office365Outlook

## Interpretation

Use this report to answer which pipeline hands off to which next layer. Use notebook code or the metadata files read by the Lookup activities when you need exact source-table to target-table lineage.
