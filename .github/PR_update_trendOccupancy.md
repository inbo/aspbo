## Brief description

This is an **automatically generated PR**. 
The following steps are all automatically performed:

- download tx - files from zenodo
- cleanup, map & combine all tx files into 1 dataframe
- export as `./data/output/UAT_processing/trendOccupancy/trendOccupancy_belgium.csv`

All the steps above are triggered by `./.github/workflows/update_trendOccupancy.yaml`<sup>1</sup>
and executed by `./src/update_trendOccupancy.rmd`. 
This script is wrapped by `./src/run_update_trendOccupancy.R` and assisted by 
`./src/install_packages_trendOccupancy.R`. 

Changes to the PR description can be made at `./.github/PR_update_trendOccupancy.md`

<sup>1</sup>set to trigger once per year at the first of may, 
when changes are pushed to `./data/output/UAT_processing/data_input_checklist_indicators.tsv` on the `uat` branch 
or by workflow dispatch.