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

### !!Before approving this PR please check the following graphs!!
_They can be found in `./data/interim/Xenopus_laevis_management`_

- catch_per_year: the total number of indiviuals caught per year per lifestage
- svl_cm_v_biomass: the relation between svl and biomass per lifestage
- trend_svl: a boxplot graph displaying the trend in svl
- trend_svl_points_smooth: the trend in svl obv een trendlijn
- trend_biomass: a boxplot graph displaying the trend in biomass
- trend_biomass_points_smooth: the trend in biomass obv een trendlijn

Changes to the PR description can be made at `./.github/PR_Xenopus_laevis_management.md`

<sup>1</sup>Set to trigger every 30th of the month between March & November or 
when triggered manually using workflow_dispatch.

