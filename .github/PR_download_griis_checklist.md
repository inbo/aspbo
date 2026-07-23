## Brief description

This is an **automatically generated PR**. 
The following steps are all automatically performed:

- [01_get_data_input_checklist_indicators.Rmd](https://raw.githubusercontent.com/trias-project/indicators/main/src/01_get_data_input_checklist_indicators.Rmd) from [trias-project/indicators](https://github.com/trias-project/indicators) is triggered<sup>1</sup>
- the resulting file (`data_input_checklist_indicators.tsv`) containing the GRIIS checklist is moved to `./data/output/UAT_processing/` triggering the upload_files_processing - workflow after approval of this PR. 

All the steps above are triggered by `./.github/workflows/get_griis_checklist.yaml`<sup>1</sup>
and executed by `./src/download_griis_checklist.R`. 
This script is assisted by `./src/install_packages_get_griis.R`. 

Changes to the PR description can be made at `./.github/PR_download_griis_checklist.md`

<sup>1</sup>At 00:00 on day-of-month 1 in every month from January through December.