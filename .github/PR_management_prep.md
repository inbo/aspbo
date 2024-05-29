## Brief description

This is an **automatically generated PR**. 
The following steps are all automatically performed:

- download bullfrog management scripts from gbif 
- cleanup, map & combine both datasets
- extract necessary data from datasets
- export necessary files 

All the steps above are triggered by `./.github/workflows/management-prep.yaml`<sup>1</sup>
and executed by `./src/management_prep.rmd`. 
This script is wrapped by `./src/run_management_prep.R` and assisted by 
`./src/install_packages_management.R`. 

Changes to the PR description can be made at `./.github/PR_management_prep.md`

<sup>1</sup>set to trigger every 30th of the month between March & November or 
when changes are pushed to `./darwincore/processed/` on the `main` branch.