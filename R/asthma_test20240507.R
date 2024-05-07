library(tidyverse)
library(DBI)        #database connection library
library(IMD)
library(PHEindicatormethods)

########################################################################################################
# Predefined variables
#Set age range which is used to return relevant population
########################################################################################################

IndicatorID = 90810
AgeMin = 0     # age >= AgeMin
AgeMax = 18    # age <= AgeMax

Demo_age = '0-18 yrs'
Demo_Gender = 'Persons'

########################################################################################################
# create connection
#
########################################################################################################

con <- dbConnect(odbc::odbc(), .connection_string = "Driver={SQL Server};server=MLCSU-BI-SQL;database=EAT_Reporting_BSOL", timeout = 10)

########################################################################################################
# Get OF model tables
#
########################################################################################################

query <- paste0(
  "SELECT [IndicatorID]
      ,[DomainID]
      ,[ReferenceID]
      ,[ICBIndicatorTitle]
      ,[IndicatorLabel]
      ,[StatusID]
  FROM [EAT_Reporting_BSOL].[OF].[IndicatorList]
")

#query db for data
table_indicatorID <- dbGetQuery(con, query)

query <- paste0(
  "SELECT  [DemographicID]
      ,[DemographicType]
      ,[DemographicCode]
      ,[DemographicLabel]
  FROM [EAT_Reporting_BSOL].[OF].[Demographic]
")

#query db for data
table_DemogrpahicID <- dbGetQuery(con, query)

query <- paste0(
  "SELECT [AggregationID]
      ,[AggregationType]
      ,[AggregationCode]
      ,[AggregationLabel]
  FROM [EAT_Reporting_BSOL].[OF].[Aggregation]
")

#query db for data
table_AggregationID <- dbGetQuery(con, query)

########################################################################################################
# Get data for indicator from warehouse
# Aggregation is LSOA to map to Wards and to IMD
# Grouped into financial years
# by Ethnic category using NHS 20 groups as letters
########################################################################################################
##extraction query
query <- paste0("
    select 
      count(*) as Numerator
    , null as Denominator  -- set to null for ward for qof it is the Denominator
    , EthnicCategoryCode
    , [LowerLayerSuperOutputArea]
    , CASE WHEN DatePart(Month, AdmissionDate) >= 4
            THEN concat(DatePart(Year, AdmissionDate), '/', DatePart(Year, AdmissionDate) + 1)
            ELSE concat(DatePart(Year, AdmissionDate) - 1, '/', DatePart(Year, AdmissionDate) )
       END AS Fiscal_Year
from [SUS].[VwInpatientEpisodesPatientGeography]  e
inner join (SELECT  [EpisodeId]
			FROM [EAT_Reporting_BSOL].[SUS].[VwInpatientEpisodesDiagnosisRelational]
			where left([DiagnosisCode], 3) like 'J4[56]' 
			      and DiagnosisOrder = 1 ) d
on d.EpisodeId  = e.EpisodeId
where   
    OrderInSpell = 1
    and AgeOnAdmission <= 18
    and AdmissionMethodCode  like '2%'
    and (OSLAUA = 'E08000025' or OSLAUA = 'E08000029')
group by 
  CASE WHEN DatePart(Month, AdmissionDate) >= 4
            THEN concat(DatePart(Year, AdmissionDate), '/', DatePart(Year, AdmissionDate) + 1)
            ELSE  concat(DatePart(Year, AdmissionDate) - 1,'/', DatePart(Year, AdmissionDate) )
       END 
  , EthnicCategoryCode
  , [LowerLayerSuperOutputArea]
")

#query db for data
indicator_data <- dbGetQuery(con, query)

########################################################################################################
# Read in reference tables
#
#Lower_Layer_Super_Output_Area_(2021)_to_Ward_(2022)_to_LAD_(2022)_Lookup_in_England_and_Wales_v3.csv
##
#ward_to_locality.csv
#
#nhs_ethnic_categories.csv
#
#C21_a86_e20_ward.csv
########################################################################################################

#read in lsoa ward LAD lookup
## https://geoportal.statistics.gov.uk/datasets/fc3bf6fe8ea949869af0a018205ac952_0/explore

lsoa_ward_lad_map <- read.csv("C:/Users/Richard.Wilson/Downloads/Lower_Layer_Super_Output_Area_(2021)_to_Ward_(2022)_to_LAD_(2022)_Lookup_in_England_and_Wales_v3.csv", header=TRUE, check.names=FALSE)
#correct column names to be R friendly
names(lsoa_ward_lad_map) <- str_replace_all(names(lsoa_ward_lad_map), c(" " = "_" ,
                                                              "/" = "_", 
                                                              "\\(" = ""  , 
                                                              "\\)" = "" ))
colnames(lsoa_ward_lad_map)[1] <- 'LSOA21CD'

lsoa_ward_lad_map <-  lsoa_ward_lad_map %>%
  filter(LAD22CD == 'E08000025' | LAD22CD == 'E08000029')

#read in ward lookup
ward_locality_map <- read.csv("ward_to_locality.csv", header = TRUE, check.names = FALSE)
#correct column names to be R friendly
names(ward_locality_map) <- str_replace_all(names(ward_locality_map), c(" " = "_" ,
                                                              "/" = "_", 
                                                              "\\(" = ""  , 
                                                              "\\)" = "" ))
colnames(ward_locality_map)[1] <- 'LA'
colnames(ward_locality_map)[3] <- 'WardCode'
colnames(ward_locality_map)[4] <- 'WardName'

indicator <- indicator_data %>%
  left_join(lsoa_ward_lad_map, by = c("LowerLayerSuperOutputArea" = "LSOA21CD")) %>%
  left_join(ward_locality_map, by = c("WD22NM" = "WardName")) %>%
  group_by(EthnicCategoryCode, Fiscal_Year, OSLAUA,
           WD22CD, WD22NM, Locality) %>%
  summarise(Numerator = sum(Numerator, na.rm = TRUE)) %>%
  select(Numerator, EthnicCategoryCode, Fiscal_Year, OSLAUA,
         WD22CD, WD22NM, Locality)

#get periods so that geographies with 0 numerators will be populated
periods <- indicator %>%
  group_by(Fiscal_Year) %>%
  summarise(count = n()) %>%
  select(-count)

#create list of localities from indicator file - this should come from reference file in future
localities <- indicator %>%
  group_by(Locality) %>%
  summarise(count = n()) %>%
  filter(!is.na(Locality)) %>%
  select(-count)

#read in ethnic code translator
ethnic_codes <- read.csv("nhs_ethnic_categories.csv", header = TRUE, check.names = FALSE)
ethnic_codes <- ethnic_codes %>% 
  select(NHSCode, CensusEthnicGroup, NHSCodeDefinition)

#read in population file for wards
popfile_ward <- read.csv("C21_a86_e20_ward.csv", header = TRUE, check.names = FALSE)
#correct column names to be R friendly
names(popfile_ward) <- str_replace_all(names(popfile_ward), c(" " = "_" ,
                                                            "/" = "_",
                                                            "\\(" = ""  ,
                                                            "\\)" = "" ))

popfile_ward <- popfile_ward %>%
  filter(Age_86_categories_Code >= AgeMin & Age_86_categories_Code <= AgeMax) %>%
  group_by(Electoral_wards_and_divisions_Code, Electoral_wards_and_divisions,
           Ethnic_group_20_categories_Code, Ethnic_group_20_categories) %>%
  summarise(Observation = sum(Observation))
  
######################################################################################################################
#Add IMD quintiles
# using IMD package
######################################################################################################################

#get IMD score by ward
imd_england_ward <- IMD::imd_england_ward %>%
  select(ward_code, Score) 

#add quintiles to ward
imd_england_ward <- phe_quantile(imd_england_ward, Score, nquantiles = 5L, invert=TRUE)

imd_england_ward <- imd_england_ward %>%
  select(-Score, -nquantiles, -groupvars, -qinverted) 

#add quintile to popfile
popfile_ward <- popfile_ward %>%
  left_join(imd_england_ward, by = c("Electoral_wards_and_divisions_Code" = "ward_code")) %>%
  left_join(ethnic_codes, by = c("Ethnic_group_20_categories_Code" = "CensusEthnicGroup" ))

######################################################################################################################
#create population file for each year and each geography
######################################################################################################################
#ward by ethnicity, <=19 years, IMD quintile
pop_ward<- popfile_ward %>%
  group_by(Electoral_wards_and_divisions_Code,Electoral_wards_and_divisions,  Ethnic_group_20_categories_Code, 
           NHSCode, NHSCodeDefinition, quantile) %>%
  summarise(Denominator = sum(Observation, na.rm = TRUE))  %>%
  cross_join(periods)

######################################################################################################################
#rates for BSOL
######################################################################################################################
#overall indicator rate for BSol
indicator_rate_BSol <- pop_ward %>%
  left_join(indicator, by = c("Electoral_wards_and_divisions_Code" = "WD22CD",
                          "NHSCode" = "EthnicCategoryCode",
                          "Fiscal_Year" = "Fiscal_Year"
                          )) %>%
  filter((OSLAUA == 'E08000025' | OSLAUA == 'E08000029') ) %>%
  group_by(Fiscal_Year) %>%
  summarise(Numerator = sum(Numerator, na.rm = TRUE),
            Denominator = sum(Denominator)) %>% 
  mutate(Gender = Demo_Gender,
         AgeGrp = Demo_age,
         IMD = NA,
         Ethnicity = NA,
         AggID = 'BSol'
  )  %>%
  group_by(AggID, Gender, AgeGrp, IMD, Ethnicity, Fiscal_Year)   %>%
  phe_rate(Numerator, Denominator, type = "standard", multiplier = 100000) %>%
  rename("IndicatorValue" = value)

#ethnicity indicator rate for BSol
indicator_rate_BSol_by_ethnicity <- pop_ward %>%
  left_join(indicator, by = c("Electoral_wards_and_divisions_Code" = "WD22CD",
                             "NHSCode" = "EthnicCategoryCode",
                             "Fiscal_Year" = "Fiscal_Year"
  )) %>%
  filter((OSLAUA == 'E08000025' | OSLAUA == 'E08000029') ) %>%
  group_by(Fiscal_Year, NHSCode) %>%
  summarise(Numerator = sum(Numerator, na.rm = TRUE),
            Denominator = sum(Denominator)) %>% 
  mutate(Numerator = ifelse(is.na(Numerator), 0, Numerator),
         Gender = Demo_Gender,
         AgeGrp = Demo_age,
         IMD = NA,
         Ethnicity = NHSCode,
         AggID = 'BSol'
  )  %>%
  filter(Denominator > 0 ) %>%
  group_by(AggID, Gender, AgeGrp, IMD, Ethnicity, Fiscal_Year) %>% 
  phe_rate(Numerator, Denominator, type = "standard", multiplier = 100000) %>%
  rename("IndicatorValue" = value)


#IMD indicator rate for BSol
indicator_rate_BSol_by_IMD <- pop_ward %>%
  left_join(indicator, by = c("Electoral_wards_and_divisions_Code" = "WD22CD",
                             "NHSCode" = "EthnicCategoryCode",
                             "Fiscal_Year" = "Fiscal_Year"
  )) %>%
  filter((OSLAUA == 'E08000025' | OSLAUA == 'E08000029') ) %>%
  group_by(quantile, Fiscal_Year) %>% 
  summarise(Numerator = sum(Numerator, na.rm = TRUE),
            Denominator = sum(Denominator)) %>% 
  mutate(Numerator = ifelse(is.na(Numerator), 0, Numerator),
         Gender = Demo_Gender,
         AgeGrp = Demo_age,
         IMD = paste0('Q', quantile),
         Ethnicity = NA,
         AggID = 'BSol'
  ) %>%
  filter(!is.na(quantile) & Denominator > 0) %>%
  group_by(AggID, Gender, AgeGrp, IMD, Ethnicity, Fiscal_Year) %>%
  phe_rate(Numerator, Denominator, type = "standard", multiplier = 100000) %>%
  rename("IndicatorValue" = value)


#ethnicity by IMD indicator rate for BSol
indicator_rate_BSol_by_ethnicityXIMD <- pop_ward %>%
  left_join(indicator, by= c("Electoral_wards_and_divisions_Code" = "WD22CD",
                             "NHSCode" = "EthnicCategoryCode",
                             "Fiscal_Year" = "Fiscal_Year"
  )) %>%
  filter((OSLAUA == 'E08000025' | OSLAUA == 'E08000029') ) %>%
  group_by(quantile, NHSCode, Fiscal_Year) %>% 
  summarise(Numerator = sum(Numerator, na.rm = TRUE),
            Denominator = sum(Denominator)) %>% 
  mutate(Numerator = ifelse(is.na(Numerator), 0, Numerator),
         Gender = Demo_Gender,
         AgeGrp = Demo_age,
         IMD = paste0('Q', quantile),
         Ethnicity = NHSCode,
         AggID = 'BSol'
  ) %>%
  filter(!is.na(quantile) & Denominator >0) %>%
  group_by(AggID, Gender, AgeGrp, IMD, Ethnicity, Fiscal_Year) %>%
  phe_rate(Numerator, Denominator, type= "standard", multiplier = 100000) %>%
  rename("IndicatorValue" = value)

######################################################################################################################
#rates for LA
######################################################################################################################

#overall indicator rate for local authority
indicator_rate_LA <- pop_ward %>%
  left_join(indicator, by = c("Electoral_wards_and_divisions_Code" = "WD22CD",
                             "NHSCode" = "EthnicCategoryCode",
                             "Fiscal_Year" = "Fiscal_Year"
  )) %>%
  filter((OSLAUA == 'E08000025' | OSLAUA == 'E08000029') ) %>%
  group_by(OSLAUA, Fiscal_Year) %>%
  summarise(Numerator = sum(Numerator, na.rm = TRUE),
            Denominator = sum(Denominator)) %>% 
  mutate(Numerator = ifelse(is.na(Numerator), 0, Numerator),
         Gender = Demo_Gender,
         AgeGrp = Demo_age,
         IMD = NA,
         Ethnicity = NA,
         AggID = OSLAUA
  )  %>%
  group_by(AggID, Gender, AgeGrp, IMD, Ethnicity,  Fiscal_Year)   %>%
  phe_rate(Numerator, Denominator, type = "standard", multiplier = 100000) %>%
  rename("IndicatorValue" = value)

#rates for LA by ethnicity
indicator_rate_LA_by_ethnicity <- pop_ward %>%
  left_join(indicator, by = c("Electoral_wards_and_divisions_Code" = "WD22CD",
                             "NHSCode" = "EthnicCategoryCode",
                             "Fiscal_Year" = "Fiscal_Year"
  )) %>%
  filter((OSLAUA == 'E08000025' | OSLAUA == 'E08000029') ) %>%
  group_by(Fiscal_Year,OSLAUA, NHSCode) %>%
  summarise(Numerator = sum(Numerator, na.rm = TRUE),
            Denominator = sum(Denominator)) %>% 
  mutate(Numerator = ifelse(is.na(Numerator), 0, Numerator),
         Gender = Demo_Gender,
         AgeGrp = Demo_age,
         IMD = NA,
         Ethnicity = NHSCode,
         AggID = OSLAUA
  )  %>%
  filter(Denominator > 0 ) %>%
  group_by(AggID, Gender, AgeGrp, IMD, Ethnicity, Fiscal_Year) %>% 
  phe_rate(Numerator, Denominator, type = "standard", multiplier = 100000) %>%
  rename("IndicatorValue" = value)

#IMD indicator rate for local authority
  indicator_rate_LA_by_IMD <- pop_ward %>%
    left_join(indicator, by = c("Electoral_wards_and_divisions_Code" = "WD22CD",
                               "NHSCode" = "EthnicCategoryCode",
                               "Fiscal_Year" = "Fiscal_Year"
    )) %>%
    filter((OSLAUA == 'E08000025' | OSLAUA == 'E08000029') ) %>%
    group_by(OSLAUA,quantile, Fiscal_Year) %>% 
    summarise(Numerator = sum(Numerator, na.rm = TRUE),
              Denominator = sum(Denominator)) %>% 
  mutate(Numerator = ifelse(is.na(Numerator), 1, Numerator),  #fix to eliminate blank numerators that causes phe_rate to stop
         Gender = Demo_Gender,
         AgeGrp = Demo_age,
         IMD = paste0('Q', quantile),
         Ethnicity = NA,
         AggID = OSLAUA  ) %>%
  group_by(AggID, Gender, AgeGrp, IMD, Ethnicity, Fiscal_Year) %>%
  phe_rate(Numerator, Denominator, type = "standard", multiplier = 100000) %>%
  rename("IndicatorValue" = value)


######################################################################################################################
#rates for localities
######################################################################################################################

#Rates for localities
  indicator_rate_Locality <- pop_ward %>%
    left_join(indicator, by = c("Electoral_wards_and_divisions_Code" = "WD22CD",
                               "NHSCode" = "EthnicCategoryCode",
                               "Fiscal_Year" = "Fiscal_Year"
    )) %>%
    filter((OSLAUA == 'E08000025' | OSLAUA == 'E08000029') ) %>%
    group_by(Locality, Fiscal_Year) %>%
    summarise(Numerator = sum(Numerator, na.rm = TRUE),
              Denominator = sum(Denominator)) %>% 
    mutate(Numerator = ifelse(is.na(Numerator), 0, Numerator),         
           Gender = Demo_Gender,
           AgeGrp = Demo_age,
           IMD = NA,
           Ethnicity = NA,
           AggID = Locality
    )  %>%
    group_by(AggID, Gender, AgeGrp, IMD, Ethnicity, Fiscal_Year)   %>%
    phe_rate(Numerator, Denominator, type = "standard", multiplier = 100000) %>%
    rename("IndicatorValue" = value)
  
#rates for Locality by ethnicity
indicator_rate_Locality_by_ethnicity <- pop_ward %>%
    left_join(indicator, by= c("Electoral_wards_and_divisions_Code" = "WD22CD",
                               "NHSCode" = "EthnicCategoryCode",
                               "Fiscal_Year" = "Fiscal_Year"
    )) %>%
    filter((OSLAUA == 'E08000025' | OSLAUA == 'E08000029') ) %>%
    group_by(Fiscal_Year, Locality, NHSCode) %>%
    summarise(Numerator = sum(Numerator, na.rm = TRUE),
              Denominator = sum(Denominator)) %>% 
    mutate(Numerator = ifelse(is.na(Numerator), 0, Numerator),
           Gender = Demo_Gender,
           AgeGrp = Demo_age,
           IMD = NA,
           Ethnicity = NHSCode,
           AggID = Locality
    )  %>%
    filter(Denominator > 0 ) %>%
    group_by(AggID, Gender, AgeGrp, IMD, Ethnicity,  Fiscal_Year) %>% 
    phe_rate(Numerator, Denominator, type = "standard", multiplier = 100000) %>%
    rename("IndicatorValue" = value)

#IMD indicator rate for Locality
  indicator_rate_Locality_by_IMD <- pop_ward %>%
    left_join(indicator, by= c("Electoral_wards_and_divisions_Code" = "WD22CD",
                               "NHSCode" = "EthnicCategoryCode",
                               "Fiscal_Year" = "Fiscal_Year"
    )) %>%
    filter((OSLAUA == 'E08000025' | OSLAUA == 'E08000029') ) %>%
    group_by(Locality, quantile, Fiscal_Year) %>% 
    summarise(Numerator = sum(Numerator, na.rm = TRUE),
              Denominator = sum(Denominator)) %>% 
    mutate(Numerator = ifelse(is.na(Numerator), 1, Numerator), #fix to eliminate blank numerators that causes phe_rate to stop
           Denominator = ifelse(is.na(Denominator) | Denominator == 0 , 1, Denominator), #fix to eliminate blank Denominator that causes phe_rate to stop
           Gender = Demo_Gender,
           AgeGrp = Demo_age,
           IMD = paste0('Q',quantile),
           Ethnicity = NA,
           AggID = Locality) %>%
    group_by(AggID, Gender, AgeGrp, IMD, Ethnicity,  Fiscal_Year) %>%
    phe_rate(Numerator, Denominator, type = "standard", multiplier = 100000) %>%
    rename("IndicatorValue" = value) %>%
# error capture for 0 denominator
    mutate(IndicatorValue = ifelse(Denominator == 1, NA, IndicatorValue),
           lowercl = ifelse(Denominator == 1, NA, lowercl),
           uppercl = ifelse(Denominator == 1, NA, uppercl),
           Numerator = ifelse(Denominator == 1, NA, Numerator),
           Denominator = ifelse(Denominator == 1, NA, Denominator))


######################################################################################################################
#rates for wards
######################################################################################################################
#overall
indicator_rate_ward <- pop_ward %>%
    left_join(indicator, by = c("Electoral_wards_and_divisions_Code" = "WD22CD",
                               "NHSCode" = "EthnicCategoryCode",
                               "Fiscal_Year" = "Fiscal_Year"
    )) %>%
    filter((OSLAUA == 'E08000025' | OSLAUA == 'E08000029') ) %>%
  group_by(WD22NM,  Fiscal_Year) %>%
  summarise(Numerator = sum(Numerator, na.rm = TRUE),
            Denominator = sum(Denominator, na.rm = TRUE))  %>%
  mutate(Numerator = ifelse(is.na(Numerator), 0, Numerator),
         Gender = Demo_Gender,
         AgeGrp = Demo_age,
         IMD = NA,
         Ethnicity = NA,
         AggID = WD22NM) %>%
  filter(Denominator > 0 ) %>%
  group_by(AggID, Gender, AgeGrp, IMD, Ethnicity, Fiscal_Year) %>% 
  phe_rate(Numerator, Denominator, type= "standard", multiplier = 100000) %>%
  rename("IndicatorValue" = value) 


######################################################################################################################
#3 and 5 year rates for ward
######################################################################################################################

#3 year
indicator_3yr_ward  <- pop_ward %>%
    left_join(indicator, by = c("Electoral_wards_and_divisions_Code" = "WD22CD",
                               "NHSCode" = "EthnicCategoryCode",
                               "Fiscal_Year" = "Fiscal_Year"    )) %>%
    mutate(three_years = "NA")
  
  indicator_3yrrate_ward <- indicator_3yr_ward[FALSE,]
  
  for(year in periods){
    husk <- indicator_3yrrate_ward[FALSE,]

    husk <-  indicator_3yr_ward %>%
        filter(as.integer(substr(Fiscal_Year,1,4)) >= as.integer(substr(year,1,4)) &
               as.integer(substr(Fiscal_Year,1,4)) <= as.integer(substr(year,1,4))+2) %>%
         mutate(three_years = paste0(as.integer(substr(Fiscal_Year,1,4)),'/',  as.integer(substr(year,1,4))+2))
            
    indicator_3yrrate_ward <- rbind(indicator_3yrrate_ward,husk)
    }
  
 indicator_3yrrate_ward <-   indicator_3yrrate_ward %>%
   group_by(Electoral_wards_and_divisions,  three_years) %>%
   summarise(Numerator = sum(Numerator, na.rm = TRUE),
             Denominator = sum(Denominator, na.rm = TRUE))  %>%
    mutate(Numerator = ifelse(is.na(Numerator), 0, Numerator),         
         Gender = Demo_Gender,
         AgeGrp = Demo_age,
         IMD = NA,
         Ethnicity = NA,
         AggID = Electoral_wards_and_divisions
  ) %>%
  filter(Denominator > 0 & !is.na(three_years) ) %>%
  group_by(AggID, Gender, AgeGrp, IMD, Ethnicity,  three_years) %>% 
  phe_rate(Numerator, Denominator, type = "standard", multiplier = 100000) %>%
  rename("IndicatorValue" = value) %>%
  rename("Fiscal_Year" = three_years) 

#5 year
 
 indicator_5yr_ward  <- pop_ward %>%
   left_join(indicator, by = c("Electoral_wards_and_divisions_Code" = "WD22CD",
                               "NHSCode" = "EthnicCategoryCode",
                               "Fiscal_Year" = "Fiscal_Year"    )) %>%
   mutate(five_years = "NA")
 
 indicator_5yrrate_ward <- indicator_3yr_ward[FALSE,]
 
 for(year in periods){
   husk <- indicator_5yrrate_ward[FALSE,]
   
   husk <-  indicator_5yr_ward %>%
     filter(as.integer(substr(Fiscal_Year,1,4)) >= as.integer(substr(year,1,4)) &
              as.integer(substr(Fiscal_Year,1,4)) <= as.integer(substr(year,1,4))+4) %>%
     mutate(three_years = paste0(as.integer(substr(Fiscal_Year,1,4)),'/',  as.integer(substr(year,1,4))+4))
   
   indicator_5yrrate_ward <- rbind(indicator_5yrrate_ward,husk)
 }
 
 indicator_5yrrate_ward <-   indicator_5yrrate_ward %>%
   group_by(Electoral_wards_and_divisions,  five_years) %>%
   summarise(Numerator = sum(Numerator, na.rm = TRUE),
             Denominator = sum(Denominator, na.rm = TRUE))  %>%
   mutate(Numerator = ifelse(is.na(Numerator), 0, Numerator),         
          Gender = Demo_Gender,
          AgeGrp = Demo_age,
          IMD = NA,
          Ethnicity = NA,
          AggID = Electoral_wards_and_divisions
   ) %>%
   filter(Denominator > 0 & !is.na(five_years) ) %>%
   group_by(AggID, Gender, AgeGrp, IMD, Ethnicity,  five_years) %>% 
   phe_rate(Numerator, Denominator, type = "standard", multiplier = 100000) %>%
   rename("IndicatorValue" = value) %>%
   rename("Fiscal_Year" = five_years) 
######################################################################################################################
#output
######################################################################################################################

#bind into one
indicator_all_output <-rbind(indicator_rate_ward, 
                      indicator_5yrrate_ward,
                      indicator_3yrrate_ward,
                   indicator_rate_LA, 
                   indicator_rate_Locality,
                   indicator_rate_BSol,
                   indicator_rate_LA_by_ethnicity, 
                   indicator_rate_Locality_by_ethnicity,
                   indicator_rate_BSol_by_ethnicity,
                   indicator_rate_LA_by_IMD, 
                  # indicator_rate_Locality_by_IMD, 
                   indicator_rate_BSol_by_IMD,
                   indicator_rate_BSol_by_ethnicityXIMD)

#set metadata
indicator_out <- indicator_all_output %>% 
  filter(Fiscal_Year!= '2013/2014') %>%
  mutate(IndicatorID = 90810,
         valueID = 1,
         insertdate = today(), 
         IndicatorStartDate = ifelse(is.na(Fiscal_Year), NA, paste0(substring(Fiscal_Year, 1, 4),'-04-01')),
         IndicatorEndDate = ifelse(is.na(Fiscal_Year), NA, paste0('20', substring(Fiscal_Year, 8, 9),'-03-31')),
         StatusID = 1 #current
         ) %>%
  left_join(ethnic_codes, by = c ("Ethnicity"  = "NHSCode")) %>%
  left_join(demo_table, by = c('Gender' = 'Gender'
                               ,'AgeGrp' = 'AgeGrp'
                               ,'IMD' = 'IMD'
                               ,'NHSCodeDefinition' = 'Ethnicity'
  )) %>%
  ungroup() %>%
  select(AggID, Numerator, Denominator, IndicatorValue, lowercl, uppercl, IndicatorID, valueID, IndicatorStartDate,
         IndicatorEndDate, DemographicID)

write.csv(indicator_out, 'asthma_test_full.csv')

#try to write to warehouse
#dbWriteTable(con,"OF.IndicatorValue", indicator_out, append = TRUE)

#sqlAppendTable(con, "OF.IndicatorValue", indicator_out, row.names = NA)
