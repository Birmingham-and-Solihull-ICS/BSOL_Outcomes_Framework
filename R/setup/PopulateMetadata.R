################################################################################
## Date: 12/03/2024
## Overview: Load metadata from Fingertips
## Author: Chris Mainey, BSOL ICB
## Description: Pulling Metadata from Fingertips for indicator IDs from SQL 
##              server table, deciding on items of metdata required and populating
##              from Fingertips.
##
################################################################################

library(fingertipsR)
library(tidyverse)
library(DBI)        #database connection library

## create connection

con <- dbConnect(odbc::odbc()
                 , .connection_string = "Driver={SQL Server};server=MLCSU-BI-SQL;database=EAT_Reporting_BSOL"
                 , timeout = 10)

sql1 <- "Select * from [OF].[IndicatorList]"

inds <- dbGetQuery(con, sql1)