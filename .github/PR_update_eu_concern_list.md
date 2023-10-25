---
editor_options: 
  markdown: 
    wrap: 80
---

## Brief description

This is an **automatically generated PR**. The following steps are all
automatically performed<sup>1</sup>:

-   Compares the eu concern list on the UAT bucket with the main version of
    [trias-project/indicators](https://github.com/trias-project/indicators/blob/main/data/input/eu_concern_species.tsv)
-   Some known issues are fixed when relevant<sup>2</sup>
-   When the list was expanded the new list is exported to `./data/output/`.
-   When the list was changed<sup>3</sup> the modified list is exported to
    `./data/output/`.

All the steps above are triggered by
`./.github/workflows/update_eu_concern_list.yaml` and executed by
`./script/update_eu_concern_list.R`. This script is assisted by
`./script/install_eu_concern_list.R`.

Changes to the PR description can be made at `./.github/PR_management_prep.md`

<sup>1</sup> Set to trigger \"At 00:00 on day-of-month 1 in every month from
January through December.\"

<sup>2</sup> A list of known issues:

1.  *Vespa velutina* is listed on the eu concern list from Trias as *Vespa
    velutina nigrithorax* a subspecies of *Vespa velutina* however on the
    checklist the species-level is used. This script changes the Taxonkey of
    *Vespa velutina nigrithorax* into that of *Vespa velutina* whenever it is
    listed as such. Any changes to `checklist_scientificName` or
    `backbone_taxonKey` annuls this fix.

<sup>3</sup> Checks for the following changes:

1.  New taxonKeys

2.  Changed taxonKeys

3.  Omited taxonKeys

If any changes have occured to `./data/output/` the upload to buckets flow will
be triggered after merging this PR.
