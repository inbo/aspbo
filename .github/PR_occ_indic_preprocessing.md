## Brief Description

This is an **automatically generated PR** created by the `cube preprocessing` GitHub Actions workflow. The following pipeline steps were executed automatically:

1. **Cube Processing:** Downloads the latest `be_alientaxa_cube.csv` artifact from the `download occurrence cube` - workflow, processes it using `src/process_cubes/run_cube_processing.R`, and pushes the intermediate updates to the `automatic-update-occ_indic_preprocessing` branch. 
2. **Decadal Timeseries Generation:** Fetches the `be_classes_cube.csv` and the newly processed alien taxa cube, then calculates the timeseries data in parallel for each decade from 1950 to 2029 using `src/process_cubes/create_timeseries_decade.Rmd`.
3. **Compilation & Upload:** Gathers all the decadal timeseries artifacts, compiles them into a final dataset via `src/process_cubes/run_compile_upload_timeseries.R`, uploads the results to the S3 bucket, and opens this PR against the `uat` branch.

> **Note to the reviewer:** The workflow automation is still in a development phase. Please check the final compiled output thoroughly before merging to `uat`.

---

## Checklist
- [x] This PR was generated automatically by GitHub Actions.
- [ ] The latest run of `download occurrence cube` was completed succesfully ?
- [ ] The workflow run completed successfully without silent errors in the R scripts ?
- [ ] The compiled outputs in the UAT S3 bucket have been verified. Go to [exoten-uat.inbo.be](https://exoten-uat.inbo.be/app/01_exotenportaal/) ?
- [ ] The species information page of at least 3 species works without a flaw ?
- [ ] The GAMs were generated for at least 1 of the test species ? 

Every question is answered with `yes` => approve & merge
At least one question is answered with `no` => request changes 
