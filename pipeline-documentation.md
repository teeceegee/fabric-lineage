# Fabric Pipeline Documentation
**Workspace**: dev-prescriptions-process
**Generated**: 2026-07-14 10:11:54
**Total Pipelines**: 45

---

# Orchestrator Pipelines
Master pipelines that coordinate multiple sub-pipelines


## eps_process_all
**Schedule**: Daily at 08:00 (Enabled)

**Total Activities**: 3

### Activities

#### 1. eps_process_bronze
- **Type**: ExecutePipeline
- **Target Pipeline ID**: `72fcba30-0e7e-4000-abca-e2e00d332f95`
- **Wait for Completion**: True

#### 2. eps_process_silver
- **Type**: ExecutePipeline
- **Depends On**: eps_process_bronze (Succeeded)
- **Target Pipeline ID**: `be6e1f3e-6128-4467-a068-ca9d787462a7`
- **Wait for Completion**: True

#### 3. eps_process_gold
- **Type**: ExecutePipeline
- **Depends On**: eps_process_silver (Succeeded)
- **Target Pipeline ID**: `0311bc10-d8e8-48d5-be2c-71d493dd90b6`
- **Wait for Completion**: True

---


## pl_epact_monthly_master
**Schedule**: None (manual trigger only)

**Total Activities**: 7

### Activities

#### 1. NotebookStart
- **Type**: TridentNotebook

#### 2. Invoke llf silver pipeline
- **Type**: InvokePipeline
- **Depends On**: Invoke llf bronze pipeline (Succeeded)

#### 3. Invoke llf gold pipeline
- **Type**: InvokePipeline
- **Depends On**: Invoke llf silver pipeline (Succeeded)

#### 4. Office 365 Outlook monthly completion
- **Type**: Office365Outlook
- **Depends On**: NotebookEnd (Succeeded)

#### 5. Invoke llf bronze pipeline
- **Type**: InvokePipeline
- **Depends On**: NotebookStart (Succeeded)

#### 6. Invoke Sow4 pipeline
- **Type**: InvokePipeline
- **Depends On**: Invoke llf gold pipeline (Succeeded)

#### 7. NotebookEnd
- **Type**: TridentNotebook
- **Depends On**: Invoke Sow4 pipeline (Succeeded)

---


## pl_finance_daily_master
**Schedule**: None (manual trigger only)

**Total Activities**: 4

### Activities

#### 1. NotebookStart
- **Type**: TridentNotebook

#### 2. Invoke finance bronze pipeline
- **Type**: InvokePipeline
- **Depends On**: NotebookStart (Succeeded)

#### 3. If monthly runnable Yes No
- **Type**: IfCondition
- **Depends On**: Invoke finance bronze pipeline (Succeeded)

#### 4. Office 365 Outlook daily completion
- **Type**: Office365Outlook
- **Depends On**: Invoke finance bronze pipeline (Succeeded)

---


## pl_finance_monthly_master
**Schedule**: None (manual trigger only)

**Total Activities**: 4

### Activities

#### 1. NotebookStart
- **Type**: TridentNotebook

#### 2. Invoke silver pipeline
- **Type**: InvokePipeline
- **Depends On**: NotebookStart (Succeeded)

#### 3. Invoke gold pipeline
- **Type**: InvokePipeline
- **Depends On**: Invoke silver pipeline (Succeeded)

#### 4. Office 365 Outlook monthly completion
- **Type**: Office365Outlook
- **Depends On**: Invoke gold pipeline (Succeeded)

---


# Bronze Layer Pipelines
Raw data ingestion and initial processing


## eps_process_bronze
**Schedule**: Daily at 08:00 (Disabled)

**Total Activities**: 17

### Activities

#### 1. Create or amend all tables
- **Type**: TridentNotebook
- **Depends On**: Start Email (Succeeded)

#### 2. List Serial_Load_1 Job Names
- **Type**: TridentNotebook
- **Depends On**: Create or amend all tables (Succeeded)

#### 3. Serial_Load_1
- **Type**: ForEach
- **Depends On**: List Serial_Load_1 Job Names (Succeeded)

#### 4. List Parallel_Load_1 Job Names
- **Type**: TridentNotebook
- **Depends On**: Serial_Load_1 (Succeeded)

#### 5. Parallel_Load_1
- **Type**: ForEach
- **Depends On**: List Parallel_Load_1 Job Names (Succeeded)

#### 6. List Serial_Load_2 Job Names
- **Type**: TridentNotebook
- **Depends On**: If Parallel_Load_1 (Succeeded)

#### 7. If Parallel_Load_1
- **Type**: IfCondition
- **Depends On**: Parallel_Load_1 (Succeeded)

#### 8. End of Pipeline Verification checks
- **Type**: TridentNotebook
- **Depends On**: Serial_Load_2 (Succeeded); If Parallel_Load_1 (Succeeded)

#### 9. End of Pipeline Verification checks email
- **Type**: IfCondition
- **Depends On**: End of Pipeline Verification checks (Succeeded)

#### 10. LFIS1 Veri fail email
- **Type**: Office365Outlook
- **Depends On**: Serial_Load_1 (Failed)

#### 11. LFIS1 Fail
- **Type**: Fail
- **Depends On**: LFIS1 Veri fail email (Succeeded)

#### 12. Serial_Load_2
- **Type**: ForEach
- **Depends On**: List Serial_Load_2 Job Names (Succeeded)

#### 13. LFIS3 Veri fail email
- **Type**: Office365Outlook
- **Depends On**: Serial_Load_2 (Failed)

#### 14. LFIS2 Fail
- **Type**: Fail
- **Depends On**: LFIS3 Veri fail email (Succeeded)

#### 15. Start Email
- **Type**: Office365Outlook

#### 16. pl1_fail
- **Type**: Fail
- **Depends On**: If Parallel_Load_1 (Failed)

#### 17. pipe_fail
- **Type**: Fail
- **Depends On**: End of Pipeline Verification checks email (Failed)

---


## eps_process_bronze_copy2
**Schedule**: Daily at 08:00 (Disabled)

**Total Activities**: 17

### Activities

#### 1. Create or amend all tables
- **Type**: TridentNotebook
- **Depends On**: Start Email (Succeeded)

#### 2. List Serial_Load_1 Job Names
- **Type**: TridentNotebook
- **Depends On**: Create or amend all tables (Succeeded)

#### 3. Serial_Load_1
- **Type**: ForEach
- **Depends On**: List Serial_Load_1 Job Names (Succeeded)

#### 4. List Parallel_Load_1 Job Names
- **Type**: TridentNotebook
- **Depends On**: Serial_Load_1 (Succeeded)

#### 5. Parallel_Load_1
- **Type**: ForEach
- **Depends On**: List Parallel_Load_1 Job Names (Succeeded)

#### 6. List Serial_Load_2 Job Names
- **Type**: TridentNotebook
- **Depends On**: If Parallel_Load_1 (Succeeded)

#### 7. If Parallel_Load_1
- **Type**: IfCondition
- **Depends On**: Parallel_Load_1 (Succeeded)

#### 8. End of Pipeline Verification checks
- **Type**: TridentNotebook
- **Depends On**: Serial_Load_2 (Succeeded); If Parallel_Load_1 (Succeeded)

#### 9. End of Pipeline Verification checks email
- **Type**: IfCondition
- **Depends On**: End of Pipeline Verification checks (Succeeded)

#### 10. LFIS1 Veri fail email
- **Type**: Office365Outlook
- **Depends On**: Serial_Load_1 (Failed)

#### 11. LFIS1 Fail
- **Type**: Fail
- **Depends On**: LFIS1 Veri fail email (Succeeded)

#### 12. Serial_Load_2
- **Type**: ForEach
- **Depends On**: List Serial_Load_2 Job Names (Succeeded)

#### 13. LFIS3 Veri fail email
- **Type**: Office365Outlook
- **Depends On**: Serial_Load_2 (Failed)

#### 14. LFIS2 Fail
- **Type**: Fail
- **Depends On**: LFIS3 Veri fail email (Succeeded)

#### 15. Start Email
- **Type**: Office365Outlook

#### 16. pl1_fail
- **Type**: Fail
- **Depends On**: If Parallel_Load_1 (Failed)

#### 17. pipe_fail
- **Type**: Fail
- **Depends On**: End of Pipeline Verification checks email (Failed)

---


## pl_cip_bronze_monthly
**Schedule**: None (manual trigger only)

**Total Activities**: 6

### Activities

#### 1. Notebook_Start
- **Type**: TridentNotebook

#### 2. LookupBronzeJobs
- **Type**: Lookup
- **Depends On**: Notebook_Start (Succeeded)

#### 3. ForEachBronzeJobs
- **Type**: ForEach
- **Depends On**: LookupBronzeJobs (Succeeded)

#### 4. NotebookEnd
- **Type**: TridentNotebook
- **Depends On**: ForEachBronzeJobs (Succeeded)

#### 5. NotebookBronzeFailure
- **Type**: TridentNotebook
- **Depends On**: ForEachBronzeJobs (Failed)

#### 6. SetMessageFromBronzeFailure
- **Type**: SetVariable
- **Depends On**: NotebookBronzeFailure (Succeeded)

---


## Pl_Cip_Bronze_Monthly_Loader
**Schedule**: None (manual trigger only)

**Total Activities**: 0

### Activities

---


## pl_etp_bronze_daily
**Schedule**: Daily at 08:31 (Disabled)

**Total Activities**: 6

### Activities

#### 1. Notebook_Start
- **Type**: TridentNotebook

#### 2. LookupBronzeJobs
- **Type**: Lookup
- **Depends On**: Notebook_Start (Succeeded)

#### 3. ForEachBronzeJobs
- **Type**: ForEach
- **Depends On**: LookupBronzeJobs (Succeeded)

#### 4. NotebookEnd
- **Type**: TridentNotebook
- **Depends On**: ForEachBronzeJobs (Succeeded)

#### 5. NotebookBronzeFailure
- **Type**: TridentNotebook
- **Depends On**: ForEachBronzeJobs (Failed)

#### 6. SetMessageFromBronzeFailure
- **Type**: SetVariable
- **Depends On**: NotebookBronzeFailure (Succeeded)

---


## pl_etp_bronze_daily_load
**Schedule**: None (manual trigger only)

**Total Activities**: 6

### Activities

#### 1. Notebook_Start
- **Type**: TridentNotebook

#### 2. LookupBronzeJobs
- **Type**: Lookup
- **Depends On**: Notebook_Start (Succeeded)

#### 3. ForEachBronzeJobs
- **Type**: ForEach
- **Depends On**: LookupBronzeJobs (Succeeded)

#### 4. NotebookEnd
- **Type**: TridentNotebook
- **Depends On**: ForEachBronzeJobs (Succeeded)

#### 5. NotebookBronzeFailure
- **Type**: TridentNotebook
- **Depends On**: ForEachBronzeJobs (Failed)

#### 6. SetMessageFromBronzeFailure
- **Type**: SetVariable
- **Depends On**: NotebookBronzeFailure (Succeeded)

---


## pl_finance_bronze_load
**Schedule**: None (manual trigger only)

**Total Activities**: 7

### Activities

#### 1. LookupBronzeJobs
- **Type**: Lookup

#### 2. ForEachBronzeJobs
- **Type**: ForEach
- **Depends On**: LookupBronzeJobs (Succeeded)

#### 3. NotebookBronzeFailure
- **Type**: TridentNotebook
- **Depends On**: ForEachBronzeJobs (Failed)

#### 4. Office 365 Outlook Bronze failed message
- **Type**: Office365Outlook
- **Depends On**: SetMessageFromBronzeFailure (Succeeded)

#### 5. SetMessageFromBronzeFailure
- **Type**: SetVariable
- **Depends On**: NotebookBronzeFailure (Succeeded)

#### 6. NotebookEnd
- **Type**: TridentNotebook
- **Depends On**: ForEachBronzeJobs (Succeeded)

#### 7. Set bronze return variable
- **Type**: SetVariable
- **Depends On**: NotebookEnd (Succeeded)

---


## pl_finance_bronze_load_test
**Schedule**: None (manual trigger only)

**Total Activities**: 2

### Activities

#### 1. NotebookStart
- **Type**: TridentNotebook

#### 2. NotebookEnd
- **Type**: TridentNotebook
- **Depends On**: NotebookStart (Succeeded)

---


## pl_llf_bronze_load
**Schedule**: None (manual trigger only)

**Total Activities**: 5

### Activities

#### 1. LookupBronzeJobs
- **Type**: Lookup

#### 2. ForEachBronzeJobs
- **Type**: ForEach
- **Depends On**: LookupBronzeJobs (Succeeded)

#### 3. NotebookBronzeFailure
- **Type**: TridentNotebook
- **Depends On**: ForEachBronzeJobs (Failed)

#### 4. Office 365 Outlook Bronze failed message
- **Type**: Office365Outlook
- **Depends On**: SetMessageFromBronzeFailure (Succeeded)

#### 5. SetMessageFromBronzeFailure
- **Type**: SetVariable
- **Depends On**: NotebookBronzeFailure (Succeeded)

---


# Silver Layer Pipelines
Cleansed and conformed data


## eps_process_silver
**Schedule**: None (manual trigger only)

**Total Activities**: 30

### Activities

#### 1. Create or amend all tables
- **Type**: TridentNotebook
- **Depends On**: Start Email (Succeeded)

#### 2. List Serial_Load_1 Job Names
- **Type**: TridentNotebook
- **Depends On**: Create or amend all tables (Succeeded)

#### 3. Serial_Load_1
- **Type**: ForEach
- **Depends On**: List Serial_Load_1 Job Names (Succeeded)

#### 4. List Parallel_Load_1 Job Names
- **Type**: TridentNotebook
- **Depends On**: Serial_Load_1 (Succeeded)

#### 5. Parallel_Load_1
- **Type**: ForEach
- **Depends On**: List Parallel_Load_1 Job Names (Succeeded)

#### 6. List Serial_Load_2 Job Names
- **Type**: TridentNotebook
- **Depends On**: If Parallel_Load_2 (Succeeded)

#### 7. If Parallel_Load_1
- **Type**: IfCondition
- **Depends On**: Parallel_Load_1 (Succeeded)

#### 8. End of Pipeline Verification checks
- **Type**: TridentNotebook
- **Depends On**: If Parallel_Load_3 (Succeeded); ERD Top 10 Monthly Fact (Succeeded)

#### 9. End of Pipeline Verification checks email
- **Type**: IfCondition
- **Depends On**: End of Pipeline Verification checks (Succeeded)

#### 10. LFIS1 Veri fail email
- **Type**: Office365Outlook
- **Depends On**: Serial_Load_1 (Failed)

#### 11. LFIS1 Fail
- **Type**: Fail
- **Depends On**: LFIS1 Veri fail email (Succeeded)

#### 12. Serial_Load_2
- **Type**: ForEach
- **Depends On**: List Serial_Load_2 Job Names (Succeeded)

#### 13. LFIS3 Veri fail email
- **Type**: Office365Outlook
- **Depends On**: Serial_Load_2 (Failed)

#### 14. LFIS2 Fail
- **Type**: Fail
- **Depends On**: LFIS3 Veri fail email (Succeeded)

#### 15. Start Email
- **Type**: Office365Outlook

#### 16. pipe_fail
- **Type**: Fail
- **Depends On**: End of Pipeline Verification checks email (Failed)

#### 17. pl1_fail
- **Type**: Fail
- **Depends On**: If Parallel_Load_1 (Failed)

#### 18. List Parallel_Load_2 Job Names
- **Type**: TridentNotebook
- **Depends On**: If Individual_Load_1 (Succeeded)

#### 19. Parallel_Load_2
- **Type**: ForEach
- **Depends On**: List Parallel_Load_2 Job Names (Succeeded)

#### 20. If Parallel_Load_2
- **Type**: IfCondition
- **Depends On**: Parallel_Load_2 (Succeeded)

#### 21. pl2_fail
- **Type**: Fail
- **Depends On**: If Parallel_Load_2 (Failed)

#### 22. List Individual_Load_1 Job Names
- **Type**: TridentNotebook
- **Depends On**: If Parallel_Load_1 (Succeeded)

#### 23. Load Files in Sequence IL1
- **Type**: TridentNotebook
- **Depends On**: List Individual_Load_1 Job Names (Succeeded)

#### 24. If Individual_Load_1
- **Type**: IfCondition
- **Depends On**: Load Files in Sequence IL1 (Succeeded)

#### 25. il1_fail
- **Type**: Fail
- **Depends On**: If Individual_Load_1 (Failed)

#### 26. List Parallel_Load_3 Job Names
- **Type**: TridentNotebook
- **Depends On**: Serial_Load_2 (Succeeded)

#### 27. Parallel_Load_3
- **Type**: ForEach
- **Depends On**: List Parallel_Load_3 Job Names (Succeeded)

#### 28. If Parallel_Load_3
- **Type**: IfCondition
- **Depends On**: Parallel_Load_3 (Succeeded)

#### 29. pl3_fail
- **Type**: Fail
- **Depends On**: If Parallel_Load_3 (Failed)

#### 30. ERD Top 10 Monthly Fact
- **Type**: TridentNotebook
- **Depends On**: Serial_Load_2 (Succeeded)

---


## mys_process_silver
**Schedule**: None (manual trigger only)

**Total Activities**: 17

### Activities

#### 1. Create or amend all tables
- **Type**: TridentNotebook
- **Depends On**: Start Email (Succeeded)

#### 2. List Serial_Load_1 Job Names
- **Type**: TridentNotebook
- **Depends On**: Create or amend all tables (Succeeded)

#### 3. Serial_Load_1
- **Type**: ForEach
- **Depends On**: List Serial_Load_1 Job Names (Succeeded)

#### 4. List Parallel_Load_1 Job Names
- **Type**: TridentNotebook
- **Depends On**: Serial_Load_1 (Succeeded)

#### 5. Parallel_Load_1
- **Type**: ForEach
- **Depends On**: List Parallel_Load_1 Job Names (Succeeded)

#### 6. List Serial_Load_2 Job Names
- **Type**: TridentNotebook
- **Depends On**: If Parallel_Load_1 (Succeeded)

#### 7. If Parallel_Load_1
- **Type**: IfCondition
- **Depends On**: Parallel_Load_1 (Succeeded)

#### 8. End of Pipeline Verification checks
- **Type**: TridentNotebook
- **Depends On**: Serial_Load_2 (Succeeded); If Parallel_Load_1 (Succeeded)

#### 9. End of Pipeline Verification checks email
- **Type**: IfCondition
- **Depends On**: End of Pipeline Verification checks (Succeeded)

#### 10. LFIS1 Veri fail email
- **Type**: Office365Outlook
- **Depends On**: Serial_Load_1 (Failed)

#### 11. LFIS1 Fail
- **Type**: Fail
- **Depends On**: LFIS1 Veri fail email (Succeeded)

#### 12. Serial_Load_2
- **Type**: ForEach
- **Depends On**: List Serial_Load_2 Job Names (Succeeded)

#### 13. LFIS3 Veri fail email
- **Type**: Office365Outlook
- **Depends On**: Serial_Load_2 (Failed)

#### 14. LFIS2 Fail
- **Type**: Fail
- **Depends On**: LFIS3 Veri fail email (Succeeded)

#### 15. Start Email
- **Type**: Office365Outlook

#### 16. pl1_fail
- **Type**: Fail
- **Depends On**: If Parallel_Load_1 (Failed)

#### 17. pipe_fail
- **Type**: Fail
- **Depends On**: End of Pipeline Verification checks email (Failed)

---


## pl_cip_silver_layer_monthly
**Schedule**: None (manual trigger only)

**Total Activities**: 6

### Activities

#### 1. Notebook_Start
- **Type**: TridentNotebook

#### 2. LookupSilverJobs
- **Type**: Lookup
- **Depends On**: Notebook_Start (Succeeded)

#### 3. ForEachSilverJobs
- **Type**: ForEach
- **Depends On**: LookupSilverJobs (Succeeded)

#### 4. NotebookEnd
- **Type**: TridentNotebook
- **Depends On**: ForEachSilverJobs (Succeeded)

#### 5. NotebookSilverFailure
- **Type**: TridentNotebook
- **Depends On**: ForEachSilverJobs (Failed)

#### 6. SetMessageFromSilverFailure
- **Type**: SetVariable
- **Depends On**: NotebookSilverFailure (Succeeded)

---


## pl_finance_silver_load
**Schedule**: None (manual trigger only)

**Total Activities**: 5

### Activities

#### 1. LookupSilverJobs
- **Type**: Lookup

#### 2. ForEachSilverJobs
- **Type**: ForEach
- **Depends On**: LookupSilverJobs (Succeeded)

#### 3. NotebookSilverFailure
- **Type**: TridentNotebook
- **Depends On**: ForEachSilverJobs (Failed)

#### 4. SetMessageFromSilverFailure
- **Type**: SetVariable
- **Depends On**: NotebookSilverFailure (Succeeded)

#### 5. Office 365 Outlook Silver failed message
- **Type**: Office365Outlook
- **Depends On**: SetMessageFromSilverFailure (Succeeded)

---


## pl_llf_silver_load
**Schedule**: None (manual trigger only)

**Total Activities**: 5

### Activities

#### 1. LookupSilverJobs
- **Type**: Lookup

#### 2. ForEachSilverJobs
- **Type**: ForEach
- **Depends On**: LookupSilverJobs (Succeeded)

#### 3. NotebookSilverFailure
- **Type**: TridentNotebook
- **Depends On**: ForEachSilverJobs (Failed)

#### 4. SetMessageFromSilverFailure
- **Type**: SetVariable
- **Depends On**: NotebookSilverFailure (Succeeded)

#### 5. Office 365 Outlook Silver failed message
- **Type**: Office365Outlook
- **Depends On**: SetMessageFromSilverFailure (Succeeded)

---


# Gold Layer Pipelines
Business-level aggregates and analytics


## eps_process_gold
**Schedule**: None (manual trigger only)

**Total Activities**: 17

### Activities

#### 1. Create or amend all tables
- **Type**: TridentNotebook
- **Depends On**: Start Email (Succeeded)

#### 2. List Serial_Load_1 Job Names
- **Type**: TridentNotebook
- **Depends On**: Create or amend all tables (Succeeded)

#### 3. Serial_Load_1
- **Type**: ForEach
- **Depends On**: List Serial_Load_1 Job Names (Succeeded)

#### 4. List Parallel_Load_1 Job Names
- **Type**: TridentNotebook
- **Depends On**: Serial_Load_1 (Succeeded)

#### 5. Parallel_Load_1
- **Type**: ForEach
- **Depends On**: List Parallel_Load_1 Job Names (Succeeded)

#### 6. List Serial_Load_2 Job Names
- **Type**: TridentNotebook
- **Depends On**: If Parallel_Load_1 (Succeeded)

#### 7. If Parallel_Load_1
- **Type**: IfCondition
- **Depends On**: Parallel_Load_1 (Succeeded)

#### 8. End of Pipeline Verification checks
- **Type**: TridentNotebook
- **Depends On**: Serial_Load_2 (Succeeded); If Parallel_Load_1 (Succeeded)

#### 9. End of Pipeline Verification checks email
- **Type**: IfCondition
- **Depends On**: End of Pipeline Verification checks (Succeeded)

#### 10. LFIS1 Veri fail email
- **Type**: Office365Outlook
- **Depends On**: Serial_Load_1 (Failed)

#### 11. LFIS1 Fail
- **Type**: Fail
- **Depends On**: LFIS1 Veri fail email (Succeeded)

#### 12. Serial_Load_2
- **Type**: ForEach
- **Depends On**: List Serial_Load_2 Job Names (Succeeded)

#### 13. LFIS3 Veri fail email
- **Type**: Office365Outlook
- **Depends On**: Serial_Load_2 (Failed)

#### 14. LFIS2 Fail
- **Type**: Fail
- **Depends On**: LFIS3 Veri fail email (Succeeded)

#### 15. Start Email
- **Type**: Office365Outlook

#### 16. pl1_fail
- **Type**: Fail
- **Depends On**: If Parallel_Load_1 (Failed)

#### 17. pipe_fail
- **Type**: Fail
- **Depends On**: End of Pipeline Verification checks email (Failed)

---


## mys_process_gold
**Schedule**: None (manual trigger only)

**Total Activities**: 17

### Activities

#### 1. Create or amend all tables
- **Type**: TridentNotebook
- **Depends On**: Start Email (Succeeded)

#### 2. List Serial_Load_1 Job Names
- **Type**: TridentNotebook
- **Depends On**: Create or amend all tables (Succeeded)

#### 3. Serial_Load_1
- **Type**: ForEach
- **Depends On**: List Serial_Load_1 Job Names (Succeeded)

#### 4. List Parallel_Load_1 Job Names
- **Type**: TridentNotebook
- **Depends On**: Serial_Load_1 (Succeeded)

#### 5. Parallel_Load_1
- **Type**: ForEach
- **Depends On**: List Parallel_Load_1 Job Names (Succeeded)

#### 6. List Serial_Load_2 Job Names
- **Type**: TridentNotebook
- **Depends On**: If Parallel_Load_1 (Succeeded)

#### 7. If Parallel_Load_1
- **Type**: IfCondition
- **Depends On**: Parallel_Load_1 (Succeeded)

#### 8. End of Pipeline Verification checks
- **Type**: TridentNotebook
- **Depends On**: Serial_Load_2 (Succeeded); If Parallel_Load_1 (Succeeded)

#### 9. End of Pipeline Verification checks email
- **Type**: IfCondition
- **Depends On**: End of Pipeline Verification checks (Succeeded)

#### 10. LFIS1 Veri fail email
- **Type**: Office365Outlook
- **Depends On**: Serial_Load_1 (Failed)

#### 11. LFIS1 Fail
- **Type**: Fail
- **Depends On**: LFIS1 Veri fail email (Succeeded)

#### 12. Serial_Load_2
- **Type**: ForEach
- **Depends On**: List Serial_Load_2 Job Names (Succeeded)

#### 13. LFIS3 Veri fail email
- **Type**: Office365Outlook
- **Depends On**: Serial_Load_2 (Failed)

#### 14. LFIS2 Fail
- **Type**: Fail
- **Depends On**: LFIS3 Veri fail email (Succeeded)

#### 15. Start Email
- **Type**: Office365Outlook

#### 16. pl1_fail
- **Type**: Fail
- **Depends On**: If Parallel_Load_1 (Failed)

#### 17. pipe_fail
- **Type**: Fail
- **Depends On**: End of Pipeline Verification checks email (Failed)

---


## pl_finance_gold_load
**Schedule**: None (manual trigger only)

**Total Activities**: 7

### Activities

#### 1. LookupGoldJobs
- **Type**: Lookup

#### 2. ForEachGoldJobs
- **Type**: ForEach
- **Depends On**: LookupGoldJobs (Succeeded)

#### 3. NotebookGoldFailure
- **Type**: TridentNotebook
- **Depends On**: ForEachGoldJobs (Failed)

#### 4. SetMessageFromGoldFailure
- **Type**: SetVariable
- **Depends On**: NotebookGoldFailure (Succeeded)

#### 5. NotebookEnd
- **Type**: TridentNotebook
- **Depends On**: ForEachGoldJobs (Succeeded)

#### 6. Office 365 Outlook Gold failed message
- **Type**: Office365Outlook
- **Depends On**: SetMessageFromGoldFailure (Succeeded)

#### 7. Set goldl return variable
- **Type**: SetVariable
- **Depends On**: NotebookEnd (Succeeded)

---


## pl_llf_gold_load
**Schedule**: None (manual trigger only)

**Total Activities**: 5

### Activities

#### 1. LookupGoldJobs
- **Type**: Lookup

#### 2. ForEachGoldJobs
- **Type**: ForEach
- **Depends On**: LookupGoldJobs (Succeeded)

#### 3. NotebookGoldFailure
- **Type**: TridentNotebook
- **Depends On**: ForEachGoldJobs (Failed)

#### 4. SetMessageFromGoldFailure
- **Type**: SetVariable
- **Depends On**: NotebookGoldFailure (Succeeded)

#### 5. Office 365 Outlook Gold failed message
- **Type**: Office365Outlook
- **Depends On**: SetMessageFromGoldFailure (Succeeded)

---


## pl_sow4_gold_load
**Schedule**: None (manual trigger only)

**Total Activities**: 5

### Activities

#### 1. LookupSow4Jobs
- **Type**: Lookup

#### 2. ForEachSow4Jobs
- **Type**: ForEach
- **Depends On**: LookupSow4Jobs (Succeeded)

#### 3. NotebookSow4Failure
- **Type**: TridentNotebook
- **Depends On**: ForEachSow4Jobs (Failed)

#### 4. SetMessageFromSow4Failure
- **Type**: SetVariable
- **Depends On**: NotebookSow4Failure (Succeeded)

#### 5. Office 365 Outlook Sow4 failed message
- **Type**: Office365Outlook
- **Depends On**: SetMessageFromSow4Failure (Succeeded)

---


# Extract Pipelines
BAU extracts and data gateway operations


## BAU CIP daily schema extract
**Schedule**: Weekly at 04:00 on Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday (Enabled)

**Total Activities**: 9

### Activities

#### 1. get_table_list
- **Type**: TridentNotebook
- **Depends On**: Transfer all_tab_columns from lakehouse to SQL db (Succeeded)

#### 2. Copy_tables_over_gateway
- **Type**: ForEach
- **Depends On**: get_table_list (Succeeded)

#### 3. transfer_all_tab_columns_from_oracle
- **Type**: Copy
- **Source**: OracleSource
- **Sink**: LakehouseTableSink

#### 4. Transfer all_tab_columns from lakehouse to SQL db
- **Type**: Copy
- **Depends On**: Truncate all_tab_columns (Succeeded)
- **Source**: LakehouseTableSource
- **Sink**: FabricSqlDatabaseSink

#### 5. Log whole run complete_retries
- **Type**: Script
- **Depends On**: Copy_tables_over_gateway_pick_up_errors (Succeeded)

#### 6. Truncate all_tab_columns
- **Type**: Script
- **Depends On**: transfer_all_tab_columns_from_oracle (Succeeded)

#### 7. get_table_list_pick_up_errors
- **Type**: TridentNotebook
- **Depends On**: Copy_tables_over_gateway (Failed)

#### 8. Copy_tables_over_gateway_pick_up_errors
- **Type**: ForEach
- **Depends On**: get_table_list_pick_up_errors (Succeeded)

#### 9. Log whole run complete
- **Type**: Script
- **Depends On**: Copy_tables_over_gateway (Succeeded)

---


## BAU CIP monthly schema extract OLD
**Schedule**: Weekly at 01:00 on Thursday (Disabled)

**Total Activities**: 4

### Activities

#### 1. get_table_list
- **Type**: TridentNotebook
- **Depends On**: transfer_all_tab_columns_from_oracle (Succeeded)

#### 2. Copy_tables_over_gateway
- **Type**: ForEach
- **Depends On**: get_table_list (Succeeded)

#### 3. transfer_all_tab_columns_from_oracle
- **Type**: Copy
- **Source**: OracleSource
- **Sink**: LakehouseTableSink

#### 4. Log table transfer run complete
- **Type**: TridentNotebook
- **Depends On**: Copy_tables_over_gateway (Succeeded)

---


## BAU CIP monthly schema extract
**Schedule**: None (manual trigger only)

**Total Activities**: 9

### Activities

#### 1. get_table_list
- **Type**: TridentNotebook
- **Depends On**: Transfer all_tab_columns from lakehouse to SQL db (Succeeded)

#### 2. Copy_tables_over_gateway
- **Type**: ForEach
- **Depends On**: get_table_list (Succeeded)

#### 3. transfer_all_tab_columns_from_oracle
- **Type**: Copy
- **Source**: OracleSource
- **Sink**: LakehouseTableSink

#### 4. Transfer all_tab_columns from lakehouse to SQL db
- **Type**: Copy
- **Depends On**: Truncate all_tab_columns (Succeeded)
- **Source**: LakehouseTableSource
- **Sink**: FabricSqlDatabaseSink

#### 5. Log whole run complete_retries
- **Type**: Script
- **Depends On**: Copy_tables_over_gateway_pick_up_errors (Succeeded)

#### 6. Truncate all_tab_columns
- **Type**: Script
- **Depends On**: transfer_all_tab_columns_from_oracle (Succeeded)

#### 7. get_table_list_pick_up_errors
- **Type**: TridentNotebook
- **Depends On**: Copy_tables_over_gateway (Failed)

#### 8. Copy_tables_over_gateway_pick_up_errors
- **Type**: ForEach
- **Depends On**: get_table_list_pick_up_errors (Succeeded)

#### 9. Log whole run complete
- **Type**: Script
- **Depends On**: Copy_tables_over_gateway (Succeeded)

---


## BAU DPC daily schema extract
**Schedule**: Weekly at 04:30 on Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday (Enabled)

**Total Activities**: 9

### Activities

#### 1. get_table_list
- **Type**: TridentNotebook
- **Depends On**: Transfer all_tab_columns from lakehouse to SQL db (Succeeded)

#### 2. Copy_tables_over_gateway
- **Type**: ForEach
- **Depends On**: get_table_list (Succeeded)

#### 3. transfer_all_tab_columns_from_oracle
- **Type**: Copy
- **Source**: OracleSource
- **Sink**: LakehouseTableSink

#### 4. Transfer all_tab_columns from lakehouse to SQL db
- **Type**: Copy
- **Depends On**: Truncate all_tab_columns (Succeeded)
- **Source**: LakehouseTableSource
- **Sink**: FabricSqlDatabaseSink

#### 5. Log whole run complete_retries
- **Type**: Script
- **Depends On**: Copy_tables_over_gateway_pick_up_errors (Succeeded)

#### 6. Truncate all_tab_columns
- **Type**: Script
- **Depends On**: transfer_all_tab_columns_from_oracle (Succeeded)

#### 7. get_table_list_pick_up_errors
- **Type**: TridentNotebook
- **Depends On**: Copy_tables_over_gateway (Failed)

#### 8. Copy_tables_over_gateway_pick_up_errors
- **Type**: ForEach
- **Depends On**: get_table_list_pick_up_errors (Succeeded)

#### 9. Log whole run complete
- **Type**: Script
- **Depends On**: Copy_tables_over_gateway (Succeeded)

---


## BAU DPC monthly schema extract
**Schedule**: None (manual trigger only)

**Total Activities**: 9

### Activities

#### 1. get_table_list
- **Type**: TridentNotebook
- **Depends On**: Transfer all_tab_columns from lakehouse to SQL db (Succeeded)

#### 2. Copy_tables_over_gateway
- **Type**: ForEach
- **Depends On**: get_table_list (Succeeded)

#### 3. transfer_all_tab_columns_from_oracle
- **Type**: Copy
- **Source**: OracleSource
- **Sink**: LakehouseTableSink

#### 4. Transfer all_tab_columns from lakehouse to SQL db
- **Type**: Copy
- **Depends On**: Truncate all_tab_columns (Succeeded)
- **Source**: LakehouseTableSource
- **Sink**: FabricSqlDatabaseSink

#### 5. Log whole run complete_retries
- **Type**: Script
- **Depends On**: Copy_tables_over_gateway_pick_up_errors (Succeeded)

#### 6. Truncate all_tab_columns
- **Type**: Script
- **Depends On**: transfer_all_tab_columns_from_oracle (Succeeded)

#### 7. get_table_list_pick_up_errors
- **Type**: TridentNotebook
- **Depends On**: Copy_tables_over_gateway (Failed)

#### 8. Copy_tables_over_gateway_pick_up_errors
- **Type**: ForEach
- **Depends On**: get_table_list_pick_up_errors (Succeeded)

#### 9. Log whole run complete
- **Type**: Script
- **Depends On**: Copy_tables_over_gateway (Succeeded)

---


## BAU HOT monthly schema extract
**Schedule**: None (manual trigger only)

**Total Activities**: 8

### Activities

#### 1. get_table_list
- **Type**: TridentNotebook
- **Depends On**: Transfer all_tab_columns from lakehouse to SQL db (Succeeded)

#### 2. Copy_tables_over_gateway
- **Type**: ForEach
- **Depends On**: get_table_list (Succeeded)

#### 3. transfer_all_tab_columns_from_oracle
- **Type**: Copy
- **Source**: OracleSource
- **Sink**: LakehouseTableSink

#### 4. Transfer all_tab_columns from lakehouse to SQL db
- **Type**: Copy
- **Depends On**: Truncate all_tab_columns (Succeeded)
- **Source**: LakehouseTableSource
- **Sink**: FabricSqlDatabaseSink

#### 5. Log whole run complete
- **Type**: Script
- **Depends On**: Copy_tables_over_gateway_pick_up_errors (Succeeded)

#### 6. Truncate all_tab_columns
- **Type**: Script
- **Depends On**: transfer_all_tab_columns_from_oracle (Succeeded)

#### 7. get_table_list_pick_up_errors
- **Type**: TridentNotebook
- **Depends On**: Copy_tables_over_gateway (Succeeded)

#### 8. Copy_tables_over_gateway_pick_up_errors
- **Type**: ForEach
- **Depends On**: get_table_list_pick_up_errors (Succeeded)

---


## BAU PCD monthly schema extract
**Schedule**: None (manual trigger only)

**Total Activities**: 9

### Activities

#### 1. get_table_list
- **Type**: TridentNotebook
- **Depends On**: Transfer all_tab_columns from lakehouse to SQL db (Succeeded)

#### 2. Copy_tables_over_gateway
- **Type**: ForEach
- **Depends On**: get_table_list (Succeeded)

#### 3. transfer_all_tab_columns_from_oracle
- **Type**: Copy
- **Source**: OracleSource
- **Sink**: LakehouseTableSink

#### 4. Transfer all_tab_columns from lakehouse to SQL db
- **Type**: Copy
- **Depends On**: Truncate all_tab_columns (Succeeded)
- **Source**: LakehouseTableSource
- **Sink**: FabricSqlDatabaseSink

#### 5. Log whole run complete_retries
- **Type**: Script
- **Depends On**: Copy_tables_over_gateway_pick_up_errors (Succeeded)

#### 6. Truncate all_tab_columns
- **Type**: Script
- **Depends On**: transfer_all_tab_columns_from_oracle (Succeeded)

#### 7. get_table_list_pick_up_errors
- **Type**: TridentNotebook
- **Depends On**: Copy_tables_over_gateway (Failed)

#### 8. Copy_tables_over_gateway_pick_up_errors
- **Type**: ForEach
- **Depends On**: get_table_list_pick_up_errors (Succeeded)

#### 9. Log whole run complete
- **Type**: Script
- **Depends On**: Copy_tables_over_gateway (Succeeded)

---


## BAU PHA daily schema extract
**Schedule**: Weekly at 04:45 on Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday (Enabled)

**Total Activities**: 9

### Activities

#### 1. get_table_list
- **Type**: TridentNotebook
- **Depends On**: Transfer all_tab_columns from lakehouse to SQL db (Succeeded)

#### 2. Copy_tables_over_gateway
- **Type**: ForEach
- **Depends On**: get_table_list (Succeeded)

#### 3. transfer_all_tab_columns_from_oracle
- **Type**: Copy
- **Source**: OracleSource
- **Sink**: LakehouseTableSink

#### 4. Transfer all_tab_columns from lakehouse to SQL db
- **Type**: Copy
- **Depends On**: Truncate all_tab_columns (Succeeded)
- **Source**: LakehouseTableSource
- **Sink**: FabricSqlDatabaseSink

#### 5. Log whole run complete_retries
- **Type**: Script
- **Depends On**: Copy_tables_over_gateway_pick_up_errors (Succeeded)

#### 6. Truncate all_tab_columns
- **Type**: Script
- **Depends On**: transfer_all_tab_columns_from_oracle (Succeeded)

#### 7. get_table_list_pick_up_errors
- **Type**: TridentNotebook
- **Depends On**: Copy_tables_over_gateway (Failed)

#### 8. Copy_tables_over_gateway_pick_up_errors
- **Type**: ForEach
- **Depends On**: get_table_list_pick_up_errors (Succeeded)

#### 9. Log whole run complete
- **Type**: Script
- **Depends On**: Copy_tables_over_gateway (Succeeded)

---


## Data Gateway extract pipeline ETP
**Schedule**: Weekly at 01:30 on Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday (Enabled)

**Total Activities**: 9

### Activities

#### 1. get_table_list
- **Type**: TridentNotebook
- **Depends On**: Copy lakehouse all_tab_columns to SQL database (Succeeded)

#### 2. Copy_tables_over_gateway
- **Type**: ForEach
- **Depends On**: get_table_list (Succeeded)

#### 3. transfer_all_tab_columns_from_oracle
- **Type**: Copy
- **Source**: OracleSource
- **Sink**: LakehouseTableSink

#### 4. Truncate SQL database all_tab_columns
- **Type**: Script
- **Depends On**: transfer_all_tab_columns_from_oracle (Succeeded)

#### 5. Copy lakehouse all_tab_columns to SQL database
- **Type**: Copy
- **Depends On**: Truncate SQL database all_tab_columns (Succeeded)
- **Source**: LakehouseTableSource
- **Sink**: FabricSqlDatabaseSink

#### 6. Log whole run complete
- **Type**: Script
- **Depends On**: Copy_tables_over_gateway (Succeeded)

#### 7. get_table_list_retries
- **Type**: TridentNotebook
- **Depends On**: Copy_tables_over_gateway (Failed)

#### 8. Copy_tables_over_gateway_retries
- **Type**: ForEach
- **Depends On**: get_table_list_retries (Succeeded)

#### 9. Log whole run complete_retries
- **Type**: Script
- **Depends On**: Copy_tables_over_gateway_retries (Succeeded)

---


# Utility Pipelines
Maintenance and support operations


## pl_csv_to_parquet
**Schedule**: None (manual trigger only)

**Total Activities**: 0

### Activities

---


## pl_finance_daily
**Schedule**: None (manual trigger only)

**Total Activities**: 8

### Activities

#### 1. LookupBronzeJobs
- **Type**: Lookup
- **Depends On**: NotebookStart (Succeeded)

#### 2. ForEachBronzeJobs
- **Type**: ForEach
- **Depends On**: LookupBronzeJobs (Succeeded)

#### 3. NotebookBronzeFailure
- **Type**: TridentNotebook
- **Depends On**: ForEachBronzeJobs (Failed)

#### 4. Office 365 Outlook Bronze failed message
- **Type**: Office365Outlook
- **Depends On**: SetMessageFromBronzeFailure (Succeeded)

#### 5. SetMessageFromBronzeFailure
- **Type**: SetVariable
- **Depends On**: NotebookBronzeFailure (Succeeded)

#### 6. NotebookStart
- **Type**: TridentNotebook

#### 7. NotebookEnd
- **Type**: TridentNotebook
- **Depends On**: ForEachBronzeJobs (Succeeded)

#### 8. If Monthly Runnable Yes No
- **Type**: IfCondition
- **Depends On**: NotebookEnd (Succeeded)

---


## pl_finance_end_to_end
**Schedule**: None (manual trigger only)

**Total Activities**: 17

### Activities

#### 1. LookupBronzeJobs
- **Type**: Lookup
- **Depends On**: NotebookStart (Succeeded)

#### 2. ForEachBronzeJobs
- **Type**: ForEach
- **Depends On**: LookupBronzeJobs (Succeeded)

#### 3. LookupSilverJobs
- **Type**: Lookup
- **Depends On**: ForEachBronzeJobs (Succeeded)

#### 4. ForEachSilverJobs
- **Type**: ForEach
- **Depends On**: LookupSilverJobs (Succeeded)

#### 5. LookupGoldJobs
- **Type**: Lookup
- **Depends On**: ForEachSilverJobs (Succeeded)

#### 6. ForEachGoldJobs
- **Type**: ForEach
- **Depends On**: LookupGoldJobs (Succeeded)

#### 7. NotebookBronzeFailure
- **Type**: TridentNotebook
- **Depends On**: ForEachBronzeJobs (Failed)

#### 8. Office 365 Outlook Bronze failed message
- **Type**: Office365Outlook
- **Depends On**: SetMessageFromBronzeFailure (Succeeded)

#### 9. NotebookSilverFailure
- **Type**: TridentNotebook
- **Depends On**: ForEachSilverJobs (Failed)

#### 10. NotebookGoldFailure
- **Type**: TridentNotebook
- **Depends On**: ForEachGoldJobs (Failed)

#### 11. SetMessageFromBronzeFailure
- **Type**: SetVariable
- **Depends On**: NotebookBronzeFailure (Succeeded)

#### 12. SetMessageFromSilverFailure
- **Type**: SetVariable
- **Depends On**: NotebookSilverFailure (Succeeded)

#### 13. SetMessageFromGoldFailure
- **Type**: SetVariable
- **Depends On**: NotebookGoldFailure (Succeeded)

#### 14. NotebookStart
- **Type**: TridentNotebook

#### 15. NotebookEnd
- **Type**: TridentNotebook
- **Depends On**: ForEachGoldJobs (Succeeded)

#### 16. Office 365 Outlook Silver failed message
- **Type**: Office365Outlook
- **Depends On**: SetMessageFromSilverFailure (Succeeded)

#### 17. Office 365 Outlook Gold failed message
- **Type**: Office365Outlook
- **Depends On**: SetMessageFromGoldFailure (Succeeded)

---


## pl_finance_monthly
**Schedule**: None (manual trigger only)

**Total Activities**: 12

### Activities

#### 1. LookupSilverJobs
- **Type**: Lookup
- **Depends On**: NotebookStart (Succeeded)

#### 2. ForEachSilverJobs
- **Type**: ForEach
- **Depends On**: LookupSilverJobs (Succeeded)

#### 3. LookupGoldJobs
- **Type**: Lookup
- **Depends On**: ForEachSilverJobs (Succeeded)

#### 4. ForEachGoldJobs
- **Type**: ForEach
- **Depends On**: LookupGoldJobs (Succeeded)

#### 5. NotebookSilverFailure
- **Type**: TridentNotebook
- **Depends On**: ForEachSilverJobs (Failed)

#### 6. NotebookGoldFailure
- **Type**: TridentNotebook
- **Depends On**: ForEachGoldJobs (Failed)

#### 7. SetMessageFromSilverFailure
- **Type**: SetVariable
- **Depends On**: NotebookSilverFailure (Succeeded)

#### 8. SetMessageFromGoldFailure
- **Type**: SetVariable
- **Depends On**: NotebookGoldFailure (Succeeded)

#### 9. NotebookStart
- **Type**: TridentNotebook

#### 10. NotebookEnd
- **Type**: TridentNotebook
- **Depends On**: ForEachGoldJobs (Succeeded)

#### 11. Office 365 Outlook Silver failed message
- **Type**: Office365Outlook
- **Depends On**: SetMessageFromSilverFailure (Succeeded)

#### 12. Office 365 Outlook Gold failed message
- **Type**: Office365Outlook
- **Depends On**: SetMessageFromGoldFailure (Succeeded)

---


## pl_finance_test
**Schedule**: None (manual trigger only)

**Total Activities**: 6

### Activities

#### 1. LookupBronzeJobs
- **Type**: Lookup

#### 2. ForEachBronzeJobs
- **Type**: ForEach
- **Depends On**: LookupBronzeJobs (Succeeded)

#### 3. LookupSilverJobs
- **Type**: Lookup
- **Depends On**: ForEachBronzeJobs (Succeeded)

#### 4. ForEachSilverJobs
- **Type**: ForEach
- **Depends On**: LookupSilverJobs (Succeeded)

#### 5. LookupGoldJobs
- **Type**: Lookup
- **Depends On**: ForEachSilverJobs (Succeeded)

#### 6. ForEachGoldJobs
- **Type**: ForEach
- **Depends On**: LookupGoldJobs (Succeeded)

---


## pl_finance_test2
**Schedule**: None (manual trigger only)

**Total Activities**: 7

### Activities

#### 1. LookupBronzeJobs
- **Type**: Lookup

#### 2. ForEachBronzeJobs
- **Type**: ForEach
- **Depends On**: LookupBronzeJobs (Succeeded)

#### 3. NotebookBronzeVerificationCheck
- **Type**: TridentNotebook
- **Depends On**: ForEachBronzeJobs (Succeeded)

#### 4. NotebookBronzeFailure
- **Type**: TridentNotebook
- **Depends On**: ForEachBronzeJobs (Failed)

#### 5. SetMessageFromBronzeFailure
- **Type**: SetVariable
- **Depends On**: NotebookBronzeFailure (Succeeded)

#### 6. Office 365 Outlook1
- **Type**: Office365Outlook
- **Depends On**: SetMessageFromBronzeFailure (Succeeded)

#### 7. SetMessageFromBronzeVercheck
- **Type**: SetVariable
- **Depends On**: NotebookBronzeVerificationCheck (Failed)

---


## Refresh semantic model
**Schedule**: None (manual trigger only)

**Total Activities**: 1

### Activities

#### 1. Semantic model refresh - Epact form item element
- **Type**: PBISemanticModelRefresh

---


## sow11_create_semantic_model
**Schedule**: None (manual trigger only)

**Total Activities**: 1

### Activities

#### 1. disable attribute hierachies
- **Type**: TridentNotebook

---


## sow11_epact_sm_creation_pipeline
**Schedule**: None (manual trigger only)

**Total Activities**: 3

### Activities

#### 1. sm_creation
- **Type**: TridentNotebook

#### 2. apply_standard_properties
- **Type**: TridentNotebook
- **Depends On**: sm_creation (Succeeded)

#### 3. apply_measures
- **Type**: TridentNotebook
- **Depends On**: apply_standard_properties (Succeeded)

---


## sow11_pipeline
**Schedule**: None (manual trigger only)

**Total Activities**: 3

### Activities

#### 1. Create Models
- **Type**: TridentNotebook

#### 2. Rename Models
- **Type**: TridentNotebook
- **Depends On**: Create Models (Succeeded)

#### 3. Add Measures to Models
- **Type**: ForEach
- **Depends On**: Rename Models (Succeeded)

---


## sow11_pipeline_copy1
**Schedule**: None (manual trigger only)

**Total Activities**: 3

### Activities

#### 1. Create Models
- **Type**: TridentNotebook

#### 2. Rename Models
- **Type**: TridentNotebook
- **Depends On**: Create Models (Succeeded)

#### 3. Add Measures to Models
- **Type**: ForEach
- **Depends On**: Rename Models (Succeeded)

---


## Suture Run for 1.3
**Schedule**: None (manual trigger only)

**Total Activities**: 1

### Activities

#### 1. Suture_Pipeline_Run
- **Type**: TridentNotebook

---


## Table maintenance
**Schedule**: None (manual trigger only)

**Total Activities**: 1

### Activities

#### 1. Run table maintenance
- **Type**: TridentNotebook

---

