library(tidyverse)
library(DBI)        #database connection library

## create connection

con <- dbConnect(odbc::odbc(), .connection_string = "Driver={SQL Server};server=MLCSU-BI-SQL;database=EAT_Reporting_BSOL", timeout = 10)

##extraction query

query <- paste0(
  "select count(*) as Numerator
, 'admissions' as measure
,  '90810' as IndicatorID
, EthnicCategoryCode
, [MiddleLayerSuperOutputArea]
,locality
, [OSLAUA]
,CASE WHEN DatePart(Month, AdmissionDate) >= 4
            THEN concat(DatePart(Year, AdmissionDate),'/',DatePart(Year, AdmissionDate) + 1)
            ELSE  concat(DatePart(Year, AdmissionDate)-1,'/',DatePart(Year, AdmissionDate) )
       END AS Fiscal_Year
from [SUS].[VwInpatientEpisodesPatientGeography]  e
inner join (SELECT  [EpisodeId]
			FROM [EAT_Reporting_BSOL].[SUS].[VwInpatientEpisodesDiagnosisRelational]
			where left([DiagnosisCode],3) like 'J4[56]' 
			and DiagnosisOrder = 1 ) D
on D.EpisodeId  = e.EpisodeId
left join (select [Age], [AgeBand_5YRS] from 
			[Reference].[tbAge]) a
			on a.[Age] = e.AgeOnAdmission
left join (SELECT MSOA21CD, locality
FROM [EAT_Reporting_BSOL].[Reference].[MSOA_2021_BSOL_to_Constituency_2025_Locality]) l
on l.MSOA21CD = [MiddleLayerSuperOutputArea]
where   
OrderInSpell = 1
and AgeOnAdmission <=19
and AdmissionMethodCode  like '2%'
group by 
CASE WHEN DatePart(Month, AdmissionDate) >= 4
            THEN concat(DatePart(Year, AdmissionDate),'/',DatePart(Year, AdmissionDate) + 1)
            ELSE  concat(DatePart(Year, AdmissionDate)-1,'/',DatePart(Year, AdmissionDate) )
       END 
, EthnicCategoryCode
, [MiddleLayerSuperOutputArea]
,locality
, [OSLAUA]

")

#query db for data
asthma <- dbGetQuery(con, query)

#read in ethnic code translator
ethnic_codes <- read.csv("nhs_ethnic_categories.csv", header=TRUE, check.names=FALSE)
ethnic_codes <- ethnic_codes %>% 
  select(NHSCode, CensusEthnicGroup)

#read in population file
popfile <- read.csv("C21pop_msoa_e20_a18.csv", header=TRUE, check.names=FALSE)
#correct column names to be R friendly
names(popfile)<-str_replace_all(names(popfile), c(" " = "_" ,
                                                  "/" = "_", 
                                                  "\\(" = ""  , 
                                                  "\\)" = "" ))

#get periods so that geographies with 0 numerators will be populated
periods <- asthma %>%
  group_by(Fiscal_Year) %>%
  summarise(count = n()) %>%
  select(-count)

#create list of localities from asthma file - this should come from reference file in future
localities <- asthma %>%
  group_by(locality, MiddleLayerSuperOutputArea) %>%
  summarise(count = n()) %>%
  select(-count)

#create population file for each year and each geography
pop_msoa<- popfile %>%
  filter(Age_B_18_categories_Code <= 4) %>%
  group_by(Middle_layer_Super_Output_Areas_Code, Ethnic_group_20_categories_Code) %>%
  summarise(Denominator = sum(Observation, na.rm = TRUE))  %>%
  left_join(ethnic_codes, by = c("Ethnic_group_20_categories_Code" = "CensusEthnicGroup" )) %>%
  cross_join(periods)

pop_locality<- pop_msoa %>%  
  left_join(localities, by = c("Middle_layer_Super_Output_Areas_Code" = "MiddleLayerSuperOutputArea" )) %>%
  group_by(locality, NHSCode,Fiscal_Year) %>%
  summarise(Denominator = sum(Denominator, na.rm = TRUE)) 

pop_LA<- popfile %>%
  filter(Age_B_18_categories_Code <= 4) %>%
  mutate(LA = 
           case_when(
             substring(Middle_layer_Super_Output_Areas,1,4) == 'Birm' ~ 'E08000025',
             substring(Middle_layer_Super_Output_Areas,1,4) == 'Soli' ~ 'E08000029',
            )
          ) %>%
  group_by(LA, Ethnic_group_20_categories_Code) %>%
  summarise(Denominator = sum(Observation, na.rm = TRUE))  %>%
  left_join(ethnic_codes, by = c("Ethnic_group_20_categories_Code" = "CensusEthnicGroup" )) %>%
  cross_join(periods)

#rates for MSOA
asthma_rate_msoa<- pop_msoa %>%
  left_join(asthma, by= c("Middle_layer_Super_Output_Areas_Code" = "MiddleLayerSuperOutputArea",
                          "NHSCode" = "EthnicCategoryCode",
                          "Fiscal_Year" = "Fiscal_Year")) %>%
  mutate(Numerator = ifelse(is.na(Numerator),0, Numerator),
  IndicatorValue =  ifelse(Denominator >0 & Numerator >=0, Numerator / Denominator * 100000,NA),
  IndicatorStartDate = ifelse(is.na(Fiscal_Year), NA, paste0(substring(Fiscal_Year,1,4),'-04-01')),
  IndicatorEndDate = ifelse(is.na(Fiscal_Year), NA,paste0('20',substring(Fiscal_Year,8,9),'-03-31')),
   ) %>%
  rename("AggID" = Middle_layer_Super_Output_Areas_Code) %>%
  rename("DemographicID" = NHSCode) %>%
  select(-Ethnic_group_20_categories_Code, - measure, -OSLAUA)

#rates for LA
asthma_rate_LA<- pop_LA %>%
  left_join(asthma, by= c("LA" = "OSLAUA",
                          "NHSCode" = "EthnicCategoryCode",
                          "Fiscal_Year" = "Fiscal_Year")) %>%
  filter(LA == 'E08000025' | LA == 'E08000029'  ) %>%
  group_by(LA, NHSCode, Fiscal_Year) %>%
  summarise(Numerator = sum(Numerator, na.rm = TRUE),
            Denominator = sum(Denominator, na.rm = TRUE))  %>%
  mutate(Numerator = ifelse(is.na(Numerator),0, Numerator),
         IndicatorValue =  ifelse(Denominator >0 & Numerator >=0, Numerator / Denominator * 100000,NA),
         IndicatorStartDate = ifelse(is.na(Fiscal_Year), NA, paste0(substring(Fiscal_Year,1,4),'-04-01')),
         IndicatorEndDate = ifelse(is.na(Fiscal_Year), NA,paste0('20',substring(Fiscal_Year,8,9),'-03-31')),
  ) %>%
  rename("AggID" = LA) %>%
  rename("DemographicID" = NHSCode)

#Rates for localities
asthma_rate_Locality<- pop_locality %>%
  left_join(asthma, by= c("locality" = "locality",
                          "NHSCode" = "EthnicCategoryCode",
                          "Fiscal_Year" = "Fiscal_Year")) %>%
  filter(!is.na(locality)) %>%
  group_by(locality, NHSCode, Fiscal_Year) %>%
  summarise(Numerator = sum(Numerator, na.rm = TRUE),
            Denominator = sum(Denominator, na.rm = TRUE))  %>%
  mutate(Numerator = ifelse(is.na(Numerator),0, Numerator),
         IndicatorValue =  ifelse(Denominator >0 & Numerator >=0, Numerator / Denominator * 100000,NA),
         IndicatorStartDate = ifelse(is.na(Fiscal_Year), NA, paste0(substring(Fiscal_Year,1,4),'-04-01')),
         IndicatorEndDate = ifelse(is.na(Fiscal_Year), NA,paste0('20',substring(Fiscal_Year,8,9),'-03-31')),
  ) %>%
  rename("AggID" = locality) %>%
  rename("DemographicID" = NHSCode)

#bind into one
asthma_out <-rbind(asthma_rate_msoa, asthma_rate_LA, asthma_rate_Locality)

#set metadata
asthma_out <- asthma_out %>% 
  mutate(IndicatorID = 90810,
         valueID = 1,
         insertdate = today())

#try to write to warehouse
#dbWriteTable(con,"OF.IndicatorValue", asthma_out)

sqlAppendTable(con, "OF.IndicatorValue", asthma_out, row.names = NA)
