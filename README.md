# BSOL Outcomes Framework <img src="https://www.birminghamsolihull.icb.nhs.uk/application/files/1316/5651/5354/logo_full_colour_main_lockup.svg" align="right" width="300px"/>

<!-- badges: start -->
[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
<!-- badges: end -->

This git repository holds the code for our ICS' first collaborative coding effort to bring our Population Health Outcomes Framework together.

# Using this project

## Mechanics of GitHub
1. Fork this repository to make your own copy.
2. Clone your forked repository, and work on your code, pushing changes to your fork.
3. When you are ready to contribute your code to the main repository, please open a 'pull request'.
4. Admin users will then check your pull request, requesting further changes if required before merging them into the main repository.

## Project structure:

This repository has three folders:

### SQL
Folder for SQL files.  Each indicator will, at minimum, have an insert statement to enter into the database tables, but may also require SQL to prepare the data. Please end these scripts with the inset statement to the indicator table.

Please name files as follows, replacing spaces with underscores, in lower case:  IndicatorID_IndicatorName
e.g. 0_example_indicator

### R
Folder for R files.  Each indicator will, at minimum, have an insert statement to enter into the database tables, but may also require SQL to prepare the data. Please end these scripts with the inset statement to the indicator table.

Please name files as follows, replacing spaces with underscores, in lower case:  IndicatorID_IndicatorName
e.g. 0_example_indicator

## docs
Any associated documentation that is required to be shared can be added here.  In general, avoid adding to this unless necessary, as the meta data will take care of definitions.

## Database structure

Proposed database will be held on the MLCSU data warehouse.

Proposed data structure can be viewed here:  https://lucid.app/lucidchart/d9cd8fe8-b5c9-4aa4-b5fc-5db5e0098a81/edit?page=0_0&invitationId=inv_cd725744-daea-40f5-99c9-38cbd579e135#

## Safeguards:

This repository is for SQL, R and other associated code to building the indicators, but it is not intended to publish data or contain any data.  By following that workflow, no data will be exposed.

*By contributing to this project, you are taking responsibility for not uploading any data to GitHub*

To help with this, the project is contains a `.gitignore` file.  This file contains file/folder/file extensions that Git will ignore by default.  If you need to import one of these files, you can do so, but you will need to use the `force` command to do so.





This repository is dual licensed under the [Open Government v3]([https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/) & MIT. All code can outputs are subject to Crown Copyright.
