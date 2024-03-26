################################################################################
## Date: 26/03/2024
## Overview: Master downloader script, as it's easire to donwload and cut that hit API
## too many times due to confusing area Type ID, inconsistent naming etc.
## Author: Chris Mainey, BSOL ICB
## Description: This sript downloads the finger tips data and loads it wholesale 
## into the database for use by all.
################################################################################# 


library(fingertipsR)
library(tidyverse)
library(DBI)



con <- dbConnect(odbc::odbc()
                 , .connection_string = "Driver={SQL Server};server=MLCSU-BI-SQL;database=EAT_Reporting_BSOL"
                 , timeout = 10)

# Select just the indicator IDs we are after
sql_ind_lkp <- "SELECT ReferenceID from [OF].[IndicatorList]"

ftp_inds<- dbGetQuery(con, sql_ind_lkp)[[1]] 


# Download fill indicators table - I know it's big, but easiest way to make sure I've got all permutations
dt <- fingertips_data(IndicatorID = ftp_inds, AreaTypeID = "All")


ft_master_tbl <- Id(schema = "OF", name = "Fingertips_extract_20210326")
dbWriteTable(con, ft_master_tbl, dt)
