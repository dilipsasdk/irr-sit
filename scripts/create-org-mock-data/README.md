# Importing and exporting data

We're using the [SFDMU plugin](https://github.com/forcedotcom/SFDX-Data-Move-Utility)
for SFDX to import data into scratch orgs. This folder contains the data files,
and export definition file for doing the import.

The .csv files in this folder contain the data to be imported and export.json
details how the export and import processes should work.

## Import

sfdx sfdmu:run --sourceusername csvfile --targetusername $userName

## Export

sfdx sfdmu:run --sourceusername $userName --targetusername csvfile
