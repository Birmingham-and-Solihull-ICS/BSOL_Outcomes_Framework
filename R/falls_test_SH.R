library(tidyverse)
library(janitor)
library(DBI)
library(odbc)
library(IMD)
library(PHEindicatormethods)

rm(list = ls())

#1. DB Connection --------------------------------------------------------------

con <-
  dbConnect(
    odbc(),
    Driver = "SQL Server",
    Server = "MLCSU-BI-SQL",
    Database = "EAT_Reporting_BSOL",
    Trusted_Connection = "True"
  )

#2. Get numerator data ---------------------------------------------------------
#2.1 Load the indicator data from the warehouse --------------------------------

indicator_dt <- dbGetQuery(
  con,
  "SELECT *
  FROM [EAT_Reporting_BSOL].[OF].[IndicatorData]"
) %>% as_tibble()

#3. Data Preparation -----------------------------------------------------------
#3.1 Parameters ----------------------------------------------------------------
# Potentially, vector data type

age_min <- 65
age_max <- NULL
indicator_id <- 11
reference_id <- 22401


age_category <- '65+'
gender_category <- 'Persons'
  
#3.2 Function 1: Process numerator data ----------------------------------------
# Parameters:
# indicator_dt: main numerator dataset
# indicator_id: indicator id
# reference_id: (optional) fingertips id if available
# age_min: (optional) to accept indicator for specific min age & ALL ages
# age_max: (optional) to accept indicator for specific max & ALL ages

get_numerator <- function(indicator_dt, indicator_id, reference_id = NULL, age_min = NULL, age_max = NULL){
  
  
  
  if(missing(age_min) & missing(age_max) & missing(reference_id)){
    indicator_dt <- indicator_dt %>% 
      filter(IndicatorID == indicator_id)
  }
  else if(missing(age_max) | missing(reference_id)){
    indicator_dt <- indicator_dt %>% 
      filter(Age >= age_min &
               IndicatorID == indicator_id)
  }
  else{
    indicator_dt <- indicator_dt %>% 
      filter(Age >= age_min & Age <= age_max) %>% 
      filter(IndicatorID == indicator_id & 
             ReferenceID == reference_id)
  }
  
  output <- indicator_dt %>%
    mutate(Financial_Year = str_replace(Financial_Year, "-", "/20")) %>%
    rename(
           FiscalYear = Financial_Year,
           LSOA21CD = LSOA_2021,
           WD22CD = Ward_Code,
           WD22NM = Ward_Name,
           LAD22CD = LAD_Code,
           LAD22NM = LAD_Name,
           Locality = Locality_Res,
           EthnicityCode = Ethnicity_Code) %>% 
    group_by(EthnicityCode, FiscalYear, LSOA21CD, WD22CD, WD22NM, 
             LAD22CD, LAD22NM, Locality) %>% 
    summarise(Numerator = sum(Numerator, na.rm = TRUE), .groups = "keep")
  
  return(output)
  
}

#3.3 Call function -------------------------------------------------------------
numerator_data <- get_numerator(indicator_dt = indicator_dt,
              indicator_id = indicator_id,
              reference_id = reference_id,
              age_min = age_min)

#4. Get denominator data -------------------------------------------------------

#4.1 Read Census population estimates ------------------------------------------
pop_estimates <- read.csv("data/C21_a86_e20_ward.csv",header = TRUE, check.names = FALSE) %>% 
  clean_names()

#4.2 Read ethnicity code translation -------------------------------------------
ethnic_codes <- read.csv("data/nhs_ethnic_categories.csv", header = TRUE, check.names = FALSE) %>%
  select(NHSCode, CensusEthnicGroup, NHSCodeDefinition)

#4.3 Function 2: Process denominator data --------------------------------------
# Parameters:
# age_min: (optional) to get population estimates for specific min age & ALL ages
# age_max: (optional) to get population estimates for specific max age & ALL ages
# indicator_dt: numerator data set with which the population estimates will be joined

get_denominator <- function(age_min = NULL, age_max = NULL, indicator_dt){


  # Filter Census population estimates by min & max age (default: no filter)
  if (missing(age_min) & missing(age_max)){
    pop_estimates <- pop_estimates
  }
  else if(missing(age_max)){
    pop_estimates <- pop_estimates %>%
      filter(age_86_categories_code >= age_min)
  }
  else{

    pop_estimates <- pop_estimates %>%
      filter(age_86_categories_code >= age_min & age_86_categories_code <= age_max)
  }
  

  # Create deprivation quintiles by Ward
  imd_england_ward <- IMD::imd_england_ward %>%
    select(ward_code, Score) %>%
    phe_quantile(Score, nquantiles = 5L, invert = TRUE) %>%
    select(ward_code, quantile) %>%
    mutate(quantile = paste0("Q", quantile))

  # Get unique periods
  periods <- unique(indicator_dt$FiscalYear[!is.na(indicator_dt$FiscalYear)]) %>%
    tibble() %>%
    rename(FiscalYear = ".")

  # Enrich the population estimates with the deprivation quintiles & ethnicity
  # description
  output <- pop_estimates %>%
    left_join(imd_england_ward,
              by = c("electoral_wards_and_divisions_code" = "ward_code")) %>%
    left_join(ethnic_codes,
              by = c("ethnic_group_20_categories_code" = "CensusEthnicGroup" )) %>%
    group_by(electoral_wards_and_divisions_code, electoral_wards_and_divisions,
             ethnic_group_20_categories, NHSCode, NHSCodeDefinition, quantile) %>%
    summarise(Denominator = sum(observation, na.rm = TRUE), .groups = "keep") %>%
    cross_join(periods) %>%
    clean_names(case = "upper_camel", abbreviations = c("NHS"))
  
  return(output)
}

#4.4 Call function -------------------------------------------------------------
denominator_data <- get_denominator(age_min = age_min,  indicator_dt = numerator_data)


#5. Crude Rates Calculation ----------------------------------------------------
#5.1 Function 3: Calculate crude rates -----------------------------------------
# Parameters:
# indicator_id: Indicator ID for which the rates are calculated
# numerator_dt: Numerator data set
# denominator_dt: Denominator data set
# aggID: Geographic levels, e.g., c('BSOL', 'LAD22CD', 'Locality', 'WD22NM', 'PCN')
# genderGrp: The gender for which the indicator was measured, e.g., c('Persons', 'Male', 'Female')
# ageGrp: The age group for which the indicator was measured, e.g., c('65+', 'All ages', '0-18')


calculate_crude_rate <- function(indicator_id, denominator_dt, numerator_dt, aggID, genderGrp, ageGrp, multiplier = 100000) {
  
  calculate_rate <- function(pop_data, id, group_vars) {
    pop_data %>%
      left_join(numerator_dt, by = c("ElectoralWardsAndDivisionsCode" = "WD22CD",
                                     "NHSCode" = "EthnicityCode",
                                     "FiscalYear" = "FiscalYear")) %>%
      filter(LAD22CD %in% c('E08000025', 'E08000029')) %>%
      group_by(
        if(id == "BSOL"){
          across(all_of(group_vars))
        }else{
          across(all_of(c(id, group_vars)))
        }
      ) %>%
      summarise(Numerator = sum(Numerator, na.rm = TRUE),
                Denominator = sum(Denominator, na.rm = TRUE),
                .groups = "keep") %>%
      mutate(Gender = genderGrp,
             AgeGroup = ageGrp,
             IMD = ifelse("Quantile" %in% group_vars, Quantile, NA),  
             EthnicityCode = ifelse("NHSCode" %in% group_vars, NHSCode, NA),
             AggID = ifelse(id == "BSOL", id, !!sym(id)),
             AreaType = case_when(
               id == "BSOL" ~ "ICB",
               id == "WD22NM" ~ "Ward",
               id == "LAD22CD" ~ "Local Authority District",
               TRUE ~ "Locality"
             ))%>%
      filter(Denominator > 0 ) %>%
      group_by(AreaType, AggID, Gender, AgeGroup, IMD, EthnicityCode, FiscalYear) %>%
      phe_rate(Numerator, Denominator, type = "standard", multiplier = multiplier) %>%
      rename("IndicatorValue" = value,
             "LowerCI95" = lowercl,
             "UpperCI95" = uppercl)
  }
  
  results <- list()
  
  for (id in aggID) {
    
    
    # Overall indicator rate
    overall_rate <- calculate_rate(pop_data = denominator_dt, 
                                   id = id, 
                                   group_vars = c("FiscalYear")) %>%
      mutate(IndicatorValueType = "Overall Crude Rate")
    
    # Ethnicity indicator rate
    ethnicity_rate <- calculate_rate(pop_data = denominator_dt, 
                                     id = id, 
                                     group_vars = c("FiscalYear", "NHSCode"))%>%
      mutate(IndicatorValueType = "Ethnicity Crude Rate")
    
    # IMD indicator rate
    imd_rate <- calculate_rate(pop_data = denominator_dt, 
                               id = id, 
                               group_vars = c("FiscalYear", "Quantile")) %>%
      mutate(IndicatorValueType = "IMD Crude Rate")

    # Ethnicity by IMD indicator rate
    ethnicity_imd_rate <- calculate_rate(pop_data = denominator_dt,
                                         id = id, 
                                         group_vars = c("FiscalYear", "NHSCode", "Quantile")) %>%
      mutate(IndicatorValueType = "Ethnicity-IMD Crude Rate")
    
    # Combine all rates into a single data frame
    results[[id]] <- bind_rows(
      overall_rate,
      ethnicity_rate,
      imd_rate,
      ethnicity_imd_rate
    )
    
    
    
  }
  
  # Bind all results together into a single data frame
  final_results <- bind_rows(results)
  
  # # Add the rest of the variables as per the OF data model
  output <- final_results %>%
    filter(FiscalYear!= '2013/2014') %>%
    mutate(IndicatorID = indicator_id,
           # valueID = 1, # TO DO: Need to clarify what is this for
           InsertDate = today(),
           IndicatorStartDate = ifelse(is.na(FiscalYear), NA, paste0(substring(FiscalYear, 1, 4),'-04-01')),
           IndicatorEndDate = ifelse(is.na(FiscalYear), NA, paste0('20', substring(FiscalYear, 8, 9),'-03-31')),
           StatusID = 1, #current
           DataQualityID = NA
    ) %>%
    left_join(ethnic_codes, by = c ("EthnicityCode"  = "NHSCode")) %>%
    clean_names(case = "upper_camel", abbreviations = c("ID", "NHS", "IMD", "CI"))  %>% 
    select(
    IndicatorID, AreaType, AggID, FiscalYear, Gender, AgeGroup, IMD, EthnicityCode, NHSCodeDefinition,
     Numerator, Denominator,  IndicatorValue,   LowerCI95, UpperCI95,IndicatorValueType,
     DataQualityID, IndicatorStartDate, IndicatorEndDate, InsertDate)
  return(output)
}

#5.2 Call function -------------------------------------------------------------
crude_rates_data <- calculate_crude_rate(indicator_id = indicator_id,
                              denominator_dt = denominator_data, 
                                numerator_dt = numerator_data,
                                aggID = c("BSOL", "WD22NM", "LAD22CD", "Locality"),
                                genderGrp = 'Persons', 
                                ageGrp = '65+')


#6. Aggregated Crude Rates Calculation -----------------------------------------
#6.1 Function 4: Calculate aggregated crude rates ------------------------------
# Parameters:
# data: The crude rates data set as previously obtained
# aggYears: The aggregation years required to calculate the 3- and 5-year crude rates
# multiplier: The number needed to calculate the rates and CIs (default: 100000)


# Function to calculate the 3- and 5-year crude rate

calculate_agg_crude_rates <- function(data, aggYears = c(3, 5), multiplier = 100000) {
  data <- data %>%
    arrange(IndicatorID, AreaType, AggID, Gender, AgeGroup, IMD, EthnicityCode, NHSCodeDefinition, FiscalYear, IndicatorValueType) %>%
    mutate(StartYear = as.integer(substr(FiscalYear, 1, 4)))
  
  results <- data.frame()
  
  start_years <- unique(data$StartYear)
  
  # Looping over the specified aggregation years (3 and 5)
  for (aggYear in aggYears) {
    # For every start year in a collection of start years:
    for (start_year in start_years) {
      # Dynamically calculating the end year based on the current aggregation year
      end_year <- start_year + aggYear - 1
      
      if (end_year > max(start_years)) next
      
      period_label <- paste0(start_year, "/", end_year)
      # Grouping the data by the required levels of geographies and types of crude rates
      period_data <- data %>%
        filter(StartYear >= start_year & StartYear <= end_year) %>%
        group_by(IndicatorID, AreaType, AggID, Gender, AgeGroup, IMD, EthnicityCode, NHSCodeDefinition, IndicatorValueType) %>%
        # Summing up the numerator and averaging the denominator over the specified aggregation years
        summarise(
          Numerator = sum(Numerator, na.rm = TRUE),
          Denominator = mean(Denominator, na.rm = TRUE),
          .groups = 'drop'
        ) %>%
        # Calculating the rate and confidence intervals
        phe_rate(Numerator, Denominator, type = "standard", multiplier = multiplier) %>% 
        rename("IndicatorValue" = value,
               "LowerCI95" = lowercl,
               "UpperCI95" = uppercl) %>% 
        # Adding the rest of the variables as per the data model
        mutate(
          FiscalYear = period_label,
          # Specifying the types of aggregated crude rates 
          IndicatorValueType = paste0(aggYear, "-year ", IndicatorValueType), 
          InsertDate = today(),
          IndicatorStartDate = ifelse(is.na(FiscalYear), NA, paste0(substring(FiscalYear, 1, 4),'-04-01')),
          IndicatorEndDate = ifelse(is.na(FiscalYear), NA, paste0(substring(FiscalYear, 6, 9),'-03-31')),
          StatusID = 1, #current
          DataQualityID = NA
        ) %>% 
        # Re-arranging the variables
        select(
          IndicatorID, AreaType, AggID, FiscalYear, Gender, AgeGroup, IMD, EthnicityCode, NHSCodeDefinition,
          Numerator, Denominator,  IndicatorValue,   LowerCI95, UpperCI95,IndicatorValueType,
          DataQualityID, IndicatorStartDate, IndicatorEndDate, InsertDate
        )
      # Combining the results for all aggregation years
      results <- bind_rows(results, period_data)
    }
  }
  
  # Ensuring that rows with 'NA' in the denominator are removed
  results %>%
    filter(!is.na(Denominator))
}

#6.2 Call function -------------------------------------------------------------
agg_crude_rates_data <- calculate_agg_crude_rates(crude_rates_data)

#7. Final data set -------------------------------------------------------------

final_output <- bind_rows(crude_rates_data, agg_crude_rates_data)

write.csv(final_output, "data/Outcome_Framework_data.csv")