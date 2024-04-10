## Brief description

This is an **automatically generated PR**. 
The following steps are all automatically performed:

- download muskrat management data from gbif 
- cleanup and link data with provinces & communes 
- export neccessary files 

All the steps above are triggered by `./.github/workflows/get_muskrat_data.yaml`<sup>1</sup>
and executed by `./src/get_muskrat_data.R` and assisted by 
`./src/install_packages_muskrat.R`. 

Changes to the PR description can be made at `./.github/PR_get_muskrat_data.md`

<sup>1</sup>set to trigger every monday between January & December.