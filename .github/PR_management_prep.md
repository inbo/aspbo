## Brief description

This is an **automatically generated PR**. 
The following steps are all automatically performed:

- download bullfrog management scripts from gbif 
- cleanup, map & combine both datasets
- extract neccessary data from datasets
- export neccessary files 

All the steps above are triggered by `./.github/workflows/management-prep.yaml`<sup>1</sup>
and executed by `./script/management_prep.rmd`. 
This script is wrapped by `./script/run_management_prep.R` and assisted by 
`./script/install_packages_management.R`. 

Changes to the PR description can be made at `./.github/PR_management_prep.md`

<sup>1</sup>set to trigger every 30th of the month between March & November or 
when changes are pushed to `./darwincore/processed/` on the `main` branch.