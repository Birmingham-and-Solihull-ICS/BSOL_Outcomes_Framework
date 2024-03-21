################################################################################
## Date: 07/02/2024
## Overview: Current 
## Author: Chris Mainey, BSOL ICB
## Description: Check for and install R packages required
##
################################################################################

library(fingertipsR)
library(DBI)
library(dplyr)
library(lubridate)

ind <- 110
aggregations<- c(c(1,12), seq(44,78,1))

con <- dbConnect(odbc::odbc()
                 , .connection_string = "Driver={SQL Server};server=MLCSU-BI-SQL;database=EAT_Reporting_BSOL"
                 , timeout = 10)


sql_agg_lkp <- paste0("SELECT AggregationCode from [OF].[Aggregation] WHERE AggregationID in ("
                     , toString(sQuote(aggregations, q = F))
                     ,")")


sql_ind_lkp <- paste0("SELECT ReferenceID from [OF].[IndicatorList] WHERE IndicatorID = "
                     , toString(sQuote(ind, q = F))
                     )

#print(sql_agg_lkp)
#print(sql_ind_lkp)

AreaCodes <- dbGetQuery(con, sql_agg_lkp)[[1]]
FTPIndicator <- dbGetQuery(con, sql_ind_lkp)[[1]]

area_types()

# ICB  + England parent 'E92000001'
a<-fingertips_data(FTPIndicator, AreaTypeID = c(501,502, 401,402, 301,302,201,202,101,102)
                   , AreaCode = AreaCodes[])

z<-fingertips_data(FTPIndicator, AreaTypeID = "301", AreaTypeID == "E08000025")
                   
# Possible BSOL geographies, unique with name Birmingham or Solihull
cvd_geogs <- unique(z[grepl("Birmingham|Solihull|England", z$AreaName, ignore.case = FALSE, perl = TRUE)
                   , c("AreaCode","AreaName", "AreaType", "ParentCode", "ParentName")
]
)


# LA
b<-fingertips_data(FTPIndicator, AreaTypeID = 221
                   , AreaCode = AreaCodes[1:2])

# PCN
c<-fingertips_data(FTPIndicator, AreaTypeID = 204, AreaCode = AreaCodes[3:37])








# Build output

# SQL lookups

sql_agg_lkps2 <- paste0("SELECT * from [OF].[Aggregation]")
sql_dq_lkps <- paste0("SELECT * from [OF].[DataQuality]")
sql_demo_lkps <- paste0("SELECT * from [OF].[Demographic]")



AreaCodes2 <- dbGetQuery(con, sql_agg_lkps2)
DQIndicator <- dbGetQuery(con, sql_dq_lkps)
DemoIndicator <- dbGetQuery(con, sql_demo_lkps)


out_dt <-
  a %>% 
  bind_rows(c) %>% 
  left_join(AreaCodes2, by=c("AreaCode" = "AggregationCode")) %>% 
  mutate(
    IndicatorID = ind
    , InsertDate = Sys.Date()
    , Numerator = Count
    , Denominator = Denominator
    , IndicatorValue = Value
    , LowerCI95 = LowerCI95.0limit
    , UpperCI95 = UpperCI95.0limit
    , AggregationID = as.numeric(AggregationID)
    , DemographicID = as.numeric(NA)
    , DataQualityID = 1
    , IndicatorStartDate = as.Date(paste0(substr(Timeperiod, 1, 4), "-04-01"), format = "%Y-%m-%d")
  , .keep =  "none", ) %>%
    mutate(IndicatorEndDate = (IndicatorStartDate + years(1)) - days(1)) %>% 
  select(IndicatorID, InsertDate, Numerator, Denominator, IndicatorValue, LowerCI95, UpperCI95
         , AggregationID, DemographicID, DataQualityID, IndicatorStartDate, IndicatorEndDate)
    

# Write back to database table
# First bit is to identify the schema OF and present trying to write to default dbo
out_tbl_IndicatorValue <- Id("OF","IndicatorValue")  
dbWriteTable(con, out_tbl_IndicatorValue, out_dt, append=TRUE)


write.csv(out_dt, "out_dt.csv")
         
