## Brief description

This is an **automatically generated PR**. 
The following steps are all automatically performed:

- rerun occurrence_indicators_preprocessing to create and upload 
`df_timeseries.rData` to the UAT bucket.
- `df_timeseries.rData` is combined with `grid.RData` from the UAT bucket using 
`alienSpecies::createTimeseries()`. The result is also stored on the UAT bucket.

Note to the reviewer: the workflow automation is still in a development phase. 
Please, check the output thoroughly before merging to `main`. 
run_occurrence_indicators_preprocessing.r downloads 
`./data/interim/intersect_EEA_ref_grid_protected_areas.tsv` from 
`trias-project/indicators` then it runs 
`./src/05_occurrence_indicators_preprocessing.Rmd` based on the script from [trias-project/indicators/](https://github.com/trias-project/indicators/blob/main/src/05_occurrence_indicators_preprocessing.Rmd).

