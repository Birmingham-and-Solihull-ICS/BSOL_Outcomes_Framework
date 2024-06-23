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

sql1 <- "Select ReferenceID from [OF].[IndicatorList]"

inds <- dbGetQuery(con, sql1) %>%  pull()


md <- indicator_metadata(
  IndicatorID = inds
)


# Pivot
md_piv <-
  md %>% 
  #select(.) %>% # This is where we need to agree the values going in.
  pivot_longer(cols =  c(-IndicatorID))


# MetadataItems table
MetadataItems <-
  md_piv %>% 
  select(ItemLabel = name) %>% 
  distinct()


# Write the table back
# We have to use ID function to explain the schema 'OF' to dbWriteTable, else it
# writes to 'dbo', the default schema.
out_tbl_metadataitems <- Id("OF","MetadataItems")  
DBI::dbWriteTable(con, out_tbl_metadataitems, MetadataItems, append = TRUE)


# Read back IDs from table on server to replace key in metadata list
sql2 <- "Select * from [OF].[MetadataItems]"

md_items_server <- dbGetQuery(con, sql2) 

# Join on to table, and add this to the 
IndicatorMetadata <-
  md_piv %>% 
  inner_join(md_items_server, by=c("name"="ItemLabel")) %>% 
  select(IndicatorID, ItemID, MetaValue = value)


# Add ID back in properly, as currently it is the external ID (Fingertips)

# Read back IDs from table on server to replace key in metadata list
sql3 <- "Select distinct IndicatorID, ReferenceID from [OF].[IndicatorList]"

ID_items_server <- dbGetQuery(con, sql3) 

# reformat character to integer
ID_items_server <-
  ID_items_server %>% 
  mutate(ReferenceID = as.numeric(ReferenceID))

# There's a one-to-many relationship for indicators 40 and 41 which are both the same fingertips indicatior.
# Row count increases 2480 to 2511, checked for first release.

IndicatorMetadata <- IndicatorMetadata %>% 
  inner_join(ID_items_server, by = c("IndicatorID" = "ReferenceID")) %>% 
  select(-IndicatorID) %>% 
  rename(IndicatorID = IndicatorID.y) %>% 
  select(IndicatorID, ItemID, MetaValue)



 
# Write the table back
# We have to use ID function to explain the schema 'OF' to dbWriteTable, else it
# writes to 'dbo', the default schema.  
out_tbl_metadata <- Id("OF","IndicatorMetadata")  
DBI::dbWriteTable(con, out_tbl_metadata, IndicatorMetadata, overwrite = TRUE)





