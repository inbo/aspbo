## Brief description

This is an **automatically generated PR**. 
The following steps are all automatically performed:

- rerun occurrence_indicators_preprocessing to create the `df_timeseries.csv`
- rerun createTimeseries to create full_timeseries.csv and moving this file to
`../alien-species-portal/alienSpecies/inst/extdata/full_timeseries.csv`

Note to the reviewer: the workflow automation is still in a development phase. 
Please, check the output thoroughly before merging to `main`. 
run_occurrence_indicators_preprocessing.r downloads 
`./data/interim/intersect_EEA_ref_grid_protected_areas.tsv` from 
`trias-project/indicators` then it runs 
`./src/05_occurrence_indicators_preprocessing.Rmd` based on the script from [trias-project/indicators/](https://github.com/trias-project/indicators/blob/main/src/05_occurrence_indicators_preprocessing.Rmd).
Next the output, `df_timeseries.csv`, is modified by the alienSpecies function
`createTimeseries()`and moved to `../alien-species-portal/alienSpecies/inst/extdata/full_timeseries.csv`
prior to building the app. When the switch to AWS S3 bucket is completed 
`./data/output/full_timeseries.csv` should be copied/uploaded to the UAT bucket 
instead.