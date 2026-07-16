# Prescriptions Notebooks Documentation

## Overview
This directory contains documentation for notebooks in the Microsoft Fabric dev-prescriptions-process and related workspaces.

## Documentation Status

### Fully Documented
- ✅ **nb_silver_maintenance** - Detailed analysis complete

### Pending Full Documentation (10 notebooks from dev-prescriptions-process)
The following notebooks have placeholder documentation based on naming analysis. Full documentation will be generated when each notebook is opened in VS Code:

1. **nb_prescriptions_master_austen** - Master orchestration notebook
2. **Create measures tables - prescriptions_gold lakehouse** - Gold layer measures
3. **Rename organisation tables and columns for Prescriptions using metadata** - Base org renaming
4. **Rename organisation tables and columns for Prescriptions using metadata - AMS** - AMS variant
5. **Rename organisation tables and columns for Prescriptions using metadata - AMS - UTI** - UTI variant
6. **Rename organisation tables and columns for Prescriptions using metadata - opioid prescribing comparators (trend)** - Opioid analysis
7. **Rename organisation tables and columns for Prescriptions using metadata - oversupply (mock data)** - Oversupply testing
8. **Rename organisation tables and columns for Prescriptions using metadata - potential generic savings (mock data)** - Savings testing
9. **Rename organisation tables and columns for Prescriptions using metadata - Valproate** - Valproate monitoring
10. **Rename organisation tables and columns for Prescriptions using metadata(1)** - Alternate/backup version

## Organization Renaming Notebook Family
Seven notebooks share a common pattern for metadata-driven organization table renaming:
- Base template for general use
- Specialized variants for specific programs (AMS, UTI, Opioids, Valproate)
- Testing variants with mock data (Oversupply, Generic Savings)
- Backup/alternate version

## How to Enhance Documentation
To generate full documentation for any notebook:
1. Open the notebook in VS Code (this downloads it locally)
2. The documentation can then be enhanced with:
   - Cell-by-cell analysis
   - Input/output tables
   - Dependencies and orchestration
   - Spark configurations
   - Business logic details

## Workspace Information
- **Primary Workspace**: dev-prescriptions-process (ID: e8c421cf-979f-450a-94b4-e2010e807479)
- **Related Workspace**: dev-prescriptions-silver (ID: fd69ffc7-af08-44c8-848d-4039c47162d7)
- **Lakehouse**: prescriptions_process
- **Total Notebooks Documented**: 11 (1 detailed, 10 placeholder)
