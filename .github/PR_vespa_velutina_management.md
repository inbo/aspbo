## Brief description

This is an **automatically generated PR**. The following steps are all automatically performed weekly:

1. download data from gbif by `get_data_from_gbif.Rmd` run by `run_get_data_from_gbif.R`. 

2. download data from iAsset by `get_data_from_iasset.Rmd` run by `run_get_data_from_iasset.R`. 

3.  data from all sources<sup>1</sup> are cleaned, mapped & combined into the files<sup>2</sup> needed for the alien species portal by `update_inputs.Rmd` run by `run_update_inputs.R`. This script calls upon `bereken_actieve_haarden.R`.

These steps are supported by `install_packages_vespa_velutina_general.R`

<sup>1</sup> *data is sourced from [gbif](https://www.gbif.org/occurrence/search?country=BE&taxon_key=1311477) (updated by step 1 using [rgbif](https://github.com/ropensci/rgbif)), [iAsset](https://iasset.nl/en/) (updated by step 2 using [iassetR](https://github.com/inbo/iassetR)) & the [old vespawatch.be database](https://docs.google.com/spreadsheets/d/1AGgMQvJUfQGaKP02jFo-MRP4SKWhq3Cbc2_nmZUcgnw). [VespaR_Duplicaten_Check.gsheet](https://docs.google.com/spreadsheets/d/1dswABoQnpQhle5UO2xHts_ikzkd562sGugQxlyGpJWs) is used to remove records, orginating from iAsset, which are flagged as duplicate.*

<sup>2</sup> *export files are saved to `./data/output/UAT_processing/Vespa_velutina_shape/`*

Changes to the PR description can be made at `./.github/PR_vespa_velutina_management.md`
Changes to the overall workflow can be made at `./.github/get_vespa_velutina_management.yaml`
