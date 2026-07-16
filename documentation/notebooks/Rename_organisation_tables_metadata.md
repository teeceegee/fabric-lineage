# Rename organisation tables and columns for Prescriptions using metadata

## Overview
Base notebook for renaming organization tables and columns in the prescriptions data model using a metadata-driven approach. This appears to be the primary/template version with several specialized variants for different use cases.

## Primary Purpose
- Apply standardized naming conventions to organization dimension tables
- Use metadata tables to drive column renaming operations
- Ensure consistency across organization hierarchies (levels 1-5)
- Support both current and historic organization views

## Expected Data Domains
- Organization dimension tables (level_4, level_5, flat dimensions)
- Organization hierarchy metadata
- Current and historic organization snapshots
- Geographic organization structures (country, region, area team)

## Related Notebooks
This is the base version. Specialized variants exist for:
- AMS (presumably Area Management System)
- AMS - UTI (UTI-specific variant)
- Opioid prescribing comparators (trend)
- Oversupply (mock data)
- Potential generic savings (mock data)
- Valproate

## Status
**Documentation pending**: This notebook has not been opened locally yet. Full documentation will be generated once the notebook is accessed in VS Code.

## Next Steps
Open this notebook in VS Code to generate detailed documentation including:
- Metadata table structure and usage
- Renaming logic and transformation rules
- Tables affected by the renaming process
- Dependencies on other notebooks or metadata sources
