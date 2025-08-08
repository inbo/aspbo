## Brief description

This is an **automatically generated PR**. 
The following steps are all automatically performed:

- get management data from [Veldwerkdata_verwerkt voor R](https://docs.google.com/spreadsheets/d/1w8iYS-8l9bdpzAQFqpRw0r8RL7TPQyFDqiZh2-S4Im0/edit?gid=942138056#gid=942138056)
- cleanup & map the data
- extract necessary data from dataset
- export necessary files & plots to enhance reviewing

All the steps above are triggered by `./.github/workflows/Xenopus_laevis_management.yaml`<sup>1</sup>
and executed by `./src/update_xenopus_laevis_management.rmd`. 
This script is wrapped by `./src/run_xenopus_laevis_management.R` and assisted by 
`./src/install_packages_xenopus.R`. 

```{r}
base_image_url <- paste0('https://github.com/inbo/aspbo/blob/', Sys.getenv("GITHUB_HEAD_REF"), '/data/interim/Xenopus_laevis_management/')

cat(paste0(
"The following information is present in the data that will be uploaded when this \n",
"PR is approved, using ./.github/workflows/upload_files_direct.yaml\n\n",
"The catch per year split per lifeStage:\n",
"![catch_per_year](", base_image_url, "catch_per_year.png)\n\n",
"The relationship between svl & biomass per sex & lifeStage: \n",
"![svl_cm_v_biomass](", base_image_url, "svl_cm_v_biomass.png)\n\n",
"The trend in svl "
))
```

Changes to the PR description can be made at `./.github/PR_Xenopus_laevis_management.md`

<sup>1</sup>Set to trigger every 30th of the month between March & November or 
when triggered manually using workflow_dispatch.

