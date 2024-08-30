
##########################INSTRUCTIONS##########################################################
# 1. Go to Step 3: Get numerator data                                                         ##
# 2. Insert the indicator ID that you wish to extract data from database                      ##  
# 3. If you want to process one indicator at a time:                                          ## 
#     - Run the code from the beginning until Step 6.1                                        ## 
#     - Ensure that you specify the parameters for that indicator                             ## 
#     - And the indicator_data contains the indicator ID that you wish to process             ## 
#     - If necessary, filter the indicator_data to include the relevant indicator ID          ## 
# 4. If you want to process multiple indicators at the same time:                             ## 
#    - Ensure that you've filled in the parameter_combinations.xlsx file with the indicators  ## 
#    - Run the code from the beginning until Step 6.2 (skip Step 6.1)                         ## 
################################################################################################



library(tidyverse)
library(janitor)
library(DBI)
library(odbc)
library(IMD)
library(PHEindicatormethods)
library(readxl)

rm(list = ls())

# Start the timer
start_time <- Sys.time()

#1. DB Connection --------------------------------------------------------------

con <-
  dbConnect(
    odbc(),
    Driver = "SQL Server",
    Server = "MLCSU-BI-SQL",
    Database = "EAT_Reporting_BSOL",
    Trusted_Connection = "True"
  )

#2. Reference tables -----------------------------------------------------------

##2.1 LSOA 2021 to Ward 2022 to LAD 2022 lookup --------------------------------
lsoa_ward_lad_map<-read.csv("data/Lower_Layer_Super_Output_Area_(2021)_to_Ward_(2022)_to_LAD_(2022)_Lookup_in_England_and_Wales_v3.csv")
lsoa_ward_lad_map <- lsoa_ward_lad_map %>% 
  filter(LAD22CD %in% c('E08000025', 'E08000029'))

# Get unique pairs of WD22CD and LAD22CD
Ward_LAD_unique <- lsoa_ward_lad_map %>% 
  select(WD22CD, LAD22CD) %>% 
  distinct()

##2.2 Ward to Locality lookup --------------------------------------------------
ward_locality_map <- read.csv("data/ward_to_locality.csv", header = TRUE, check.names = FALSE)

ward_locality_map <- ward_locality_map %>% 
  rename(LA = ParentCode,
         WardCode = AreaCode,
         WardName = AreaName)

# Get unique pairs of Ward and Locality
ward_locality_unique <- ward_locality_map %>% 
  rename(WD22CD = WardCode,
         WD22NM = WardName) %>% 
  select(WD22CD, WD22NM, Locality) %>% 
  distinct()

##2.3 Ethnicity code mapping ---------------------------------------------------
ethnicity_map <- dbGetQuery(
  con,
  "SELECT [NHSCode]
  ,       [NHSCodeDefinition]
  ,       [LocalGrouping]
  ,       [CensusEthnicGroup]
  ,       [ONSGroup]
  FROM [EAT_Reporting_BSOL].[OF].[lkp_ethnic_categories]") %>% 
  as_tibble()

##2.4 Population estimates by Ward ---------------------------------------------
popfile_ward <- read.csv("data/C21_a86_e20_ward.csv", header = TRUE, check.names = FALSE) %>% 
  clean_names()


#3. Get numerator data ---------------------------------------------------------
#3.1 Load the indicator data from the warehouse --------------------------------

# # Read the Excel file to get the available indicators
# parameter_combinations <- read_excel("data/parameter_combinations.xlsx", 
#                                      sheet = "crude_indicators")
# 
# # Filter based on indicators requiring age-standardization
# indicators_params <- parameter_combinations %>% 
#   filter(StandardizedIndicator == 'N' & PredeterminedDenominator == "N") %>%  # The flag used to choose which indicators 
#   filter(IndicatorID %in% c(32))
# 
# # Get the unique indicator IDs to be used for importing data from database
# indicator_ids <- unique(indicators_params$IndicatorID)
# 
# # Convert the indicator IDs to a comma-separated values
# indicator_ids <- paste(indicator_ids, collapse = ", ")

# Insert which indicator IDs to extract
indicator_ids <- c(87, 88)

# Convert the indicator IDs to a comma-separated string
indicator_ids_string <- paste(indicator_ids, collapse = ", ")


# Construct the SQL query with the indicator IDs
query <- paste0("SELECT *
                FROM [EAT_Reporting_BSOL].[OF].[IndicatorData]
                WHERE IndicatorID IN (", indicator_ids_string, ")")

# Execute the SQL query
indicator_data <- dbGetQuery(con, query) %>% 
  as_tibble() %>% 
  mutate(Ethnicity_Code = trimws(Ethnicity_Code))   # Remove trailing spaces

#4. Data preparation -----------------------------------------------------------
##4.1 Function 1: Create aggregated data ---------------------------------------
# Used to aggregate either numerator or denominator data based on the specified year

# Parameters:
# data: Numerator or denominator data used to create aggregated data
# agg_years: Aggregation years for creating the aggregated data
# type: Specifies which aggregated data needs to be created; default is "numerator"

create_aggregated_data <- function(data, agg_years = c(3, 5), type = "numerator") {
  
  aggregated_data = list()
  
  for (year in agg_years){
    # Initial filter based on the aggregation year
    if(year == 3){
      aggregated_data[[paste0(year, "YR_data")]] <- data %>%
        mutate(
          FiscalYearStart = as.numeric(substr(FiscalYear, 1, 4)),
          PeriodStart = (FiscalYearStart %/% year) * year,
          FiscalYear = paste0(PeriodStart, "/", PeriodStart + 2),
          AggYear = year
        ) 
    }
    else{
      aggregated_data[[paste0(year, "YR_data")]] <- data %>%
        mutate(
          FiscalYearStart = 2019,
          FiscalYear = paste0(FiscalYearStart, "/", FiscalYearStart + 5),
          AggYear = year
        )
    }
    
    # Filter based on the aggregated data type 
    if(type == "numerator"){
      aggregated_data[[paste0(year, "YR_data")]] <- aggregated_data[[paste0(year, "YR_data")]] %>% 
        group_by(
          FiscalYear, AggYear, EthnicityCode, LAD22CD, WD22CD, WD22NM, Locality
        ) %>%
        summarise(
          Numerator = sum(Numerator, na.rm = TRUE), .groups = 'drop'
        ) 
    } else{
      aggregated_data[[paste0(year, "YR_data")]] <- aggregated_data[[paste0(year, "YR_data")]] %>% 
        group_by(
          ElectoralWardsAndDivisionsCode, ElectoralWardsAndDivisions,EthnicGroup20CategoriesCode, NHSCode, 
          NHSCodeDefinition, ONSGroup, Quantile, FiscalYear, AggYear
        ) %>%
        summarise(
          Denominator = mean(Denominator, na.rm = TRUE), # Get the mean of the denominator instead of the sum 
          .groups = 'drop'
        ) 
    }
    
  }
  # Combine both 3- and 5-year aggregated data
  output <- bind_rows(aggregated_data)
  
  return(output)
}


##4.2 Function 2: Create numerator dataset -------------------------------------

# Parameters:
# indicator_data: Main indicator dataset
# indicator_id: Indicator ID
# reference_id: (Optional) Fingertips ID if available
# min_age: (Optional) Minimum age 
# max_age: (Optional) Maximum age


get_numerator <- function(indicator_data, indicator_id, reference_id = NA, min_age = NA, max_age = NA) {
  
  # Initial filter based on Indicator ID and optional Reference ID
  if (!is.na(reference_id)) {
    filtered_data <- indicator_data %>%
      filter(IndicatorID == indicator_id & ReferenceID == reference_id)
  } else {
    filtered_data <- indicator_data %>%
      filter(IndicatorID == indicator_id)
  }
  
  # Apply age filters if provided
  if (!is.na(min_age) & !is.na(max_age)) {
    filtered_data <- filtered_data %>%
      filter(Age >= min_age & Age <= max_age)
  } else if (!is.na(min_age)) {
    filtered_data <- filtered_data %>%
      filter(Age >= min_age)
  } else if (!is.na(max_age)) {
    filtered_data <- filtered_data %>%
      filter(Age <= max_age)
  }
  
  # Process the data to generate the output
  output <- filtered_data %>% 
    group_by(IndicatorID, ReferenceID, Ethnicity_Code, LSOA_2021, Age, Financial_Year) %>% 
    summarise(Numerator = sum(Numerator, na.rm = TRUE), .groups = 'drop') 
  
  # Enrich the data with the geographies lookups
  output <- output %>%
    left_join(ethnicity_map, by = c("Ethnicity_Code" = "NHSCode")) %>%
    left_join(lsoa_ward_lad_map, by = c("LSOA_2021" = "LSOA21CD")) %>% 
    left_join(ward_locality_map, by = c("WD22NM" = "WardName")) %>% 
    group_by(Ethnicity_Code, Financial_Year, LAD22CD, WD22CD, WD22NM, Locality) %>%  
    summarise(Numerator = as.numeric(sum(Numerator, na.rm = TRUE)), .groups = 'drop') %>% 
    rename(Fiscal_Year = Financial_Year) %>% 
    mutate(Fiscal_Year = str_replace(Fiscal_Year, "-", "/20"),
           AggYear = 1) %>% 
    clean_names(case = "upper_camel", abbreviations = c("WD", "LAD", "CD", "NM", "ONS"))
  
  # Get the aggregated numerator data for 3- and 5-year rolling periods
  aggregated_data <- create_aggregated_data(output, agg_years = c(3, 5), type = "numerator")
  
  # Combine all data into one dataframe
  output <- bind_rows(output,aggregated_data)
  
  return(output)
}

# Example
# my_numerator <- get_numerator(indicator_data = indicator_data,
#                                    indicator_id = 87,
#                                    min_age = NA,
#                                    max_age = 74)

##4.3 Function 3: Create denominator dataset  ----------------------------------

# Parameters:
# min_age: (Optional) Minimum age
# max_age: (Optional) Maximum age
# pop_estimates: Population file by Ward
# numerator_data: Numerator dataset to get the available periods

get_denominator <- function(min_age = NA, max_age = NA, pop_estimates, numerator_data){
  
  
  # Map the population estimates to the unique Wards and LADs
  pop_estimates <- pop_estimates %>% 
    inner_join(Ward_LAD_unique, 
               by = c("electoral_wards_and_divisions_code" = "WD22CD"))
  
  # Apply age filters if provided
  if (!is.na(min_age) & !is.na(max_age)) {
    pop_estimates <- pop_estimates %>%
      filter(age_86_categories_code >= min_age & age_86_categories_code <= max_age)
  } else if (!is.na(min_age)) {
    pop_estimates <- pop_estimates %>%
      filter(age_86_categories_code >= min_age)
  } else if (!is.na(max_age)) {
    pop_estimates <- pop_estimates %>%
      filter(age_86_categories_code <= max_age)
  }
  
  pop_estimates <- pop_estimates %>% 
    group_by(electoral_wards_and_divisions_code, electoral_wards_and_divisions,
             ethnic_group_20_categories_code, ethnic_group_20_categories) %>%
    summarise(observation = sum(observation), .groups = 'drop')
  
  # Add the IMD quintiles by Ward
  imd_england_ward <- IMD::imd_england_ward %>%
    select(ward_code, Score) %>%
    phe_quantile(Score, nquantiles = 5L, invert = TRUE) %>%
    select(ward_code, quantile) %>%
    mutate(quantile = paste0("Q", quantile))

  # Get the available unique periods in the numerator dataset
  periods <- numerator_data %>% 
    filter(AggYear == 1) %>% 
    select(FiscalYear) %>% 
    distinct()

  # Enrich the population estimates with quintiles and ethnicity descriptions
  output <- pop_estimates %>%
    left_join(imd_england_ward,
              by = c("electoral_wards_and_divisions_code" = "ward_code")) %>%
    left_join(ethnicity_map,
              by = c("ethnic_group_20_categories_code" = "CensusEthnicGroup" )) %>%
    group_by(electoral_wards_and_divisions_code, electoral_wards_and_divisions,
             ethnic_group_20_categories_code, NHSCode, NHSCodeDefinition, ONSGroup, quantile) %>%
    summarise(Denominator = as.numeric(sum(observation, na.rm = TRUE)), .groups = 'drop') %>%
    cross_join(periods) %>%
    clean_names(case = "upper_camel", abbreviations = c("NHS", "ONS")) %>% 
    mutate(AggYear = 1, DataQualityID = 1) %>% 
    filter(!is.na(ONSGroup))
  
  # Get the aggregated denominator data for 3- and 5-year rolling periods
  aggregated_data <- create_aggregated_data(output, agg_years = c(3, 5), type = "denominator") 
  
  # Combine all data into one dataframe
  output <- bind_rows(output,aggregated_data)
  
  return(output)
}

# Example
# my_denominator <- get_denominator(min_age = NA,
#                                     max_age = 74,
#                                     pop_estimates = popfile_ward, 
#                                     numerator_data = my_numerator)

#5. Crude Rates Calculation ----------------------------------------------------
#5.1 Function 4: Calculate crude rates -----------------------------------------

# Parameters:
# indicator_id: Indicator ID for which the rates are calculated
# numerator_data: Numerator dataset
# denominator_data: Denominator dataset
# aggID: Geographic levels, e.g., c('BSOL', 'LAD22CD', 'Locality', 'WD22NM')
# genderGrp: The gender for which the indicator was measured, e.g., c('Persons', 'Male', 'Female')
# ageGrp: The age group for which the indicator was measured, e.g., c('All ages')
# multiplier: The scale at which the rates are calculated, e.g., 100000 by default

# Helper function to determine grouping columns based on rate type
get_grouping_columns <- function(rate_type) {
  base_group_vars <- c("FiscalYear", "DataQualityID")
  
  switch(rate_type,
         "overall" = base_group_vars,
         "ethnicity" = c(base_group_vars, "ONSGroup"),
         "deprivation" = c(base_group_vars, "Quantile"),
         "ethnicity_deprivation" = c(base_group_vars, "ONSGroup", "Quantile"),
         stop("Invalid rate type specified.")
  )
}


# Helper function to summarize numerator and denominator data with the correct 'DataQualityID'
get_summarized_data <- function(id, group_vars, year, denominator_data, numerator_data) {
  
  summarized_data <- denominator_data %>%
    filter(AggYear == year) %>%
    left_join(numerator_data %>% filter(AggYear == year),
              by = c("ElectoralWardsAndDivisionsCode" = "WD22CD",
                     "NHSCode" = "EthnicityCode",
                     "FiscalYear" = "FiscalYear"))
  
  if (id == "WD22NM") {
    summarized_data <- summarized_data %>%
      left_join(ward_locality_unique, by = c("ElectoralWardsAndDivisionsCode" = "WD22CD")) %>%
      group_by(across(all_of(c(group_vars, "WD22NM.y"))))
  } else if (id == "LAD22CD") {
    summarized_data <- summarized_data %>%
      left_join(Ward_LAD_unique, by = c("ElectoralWardsAndDivisionsCode" = "WD22CD")) %>%
      group_by(across(all_of(c(group_vars, "LAD22CD.y"))))
  } else if (id == "Locality") {
    summarized_data <- summarized_data %>%
      left_join(ward_locality_unique, by = c("ElectoralWardsAndDivisionsCode" = "WD22CD")) %>%
      group_by(across(all_of(c(group_vars, "Locality.y"))))
  } else if (id == "BSOL ICB") {
    summarized_data <- summarized_data %>%
      group_by(across(all_of(group_vars)))
  }
  
  summarized_data <- summarized_data %>%
    summarise(Numerator = sum(Numerator, na.rm = TRUE),
              Denominator = sum(Denominator),
              .groups = 'drop') %>%
    mutate(DataQualityID = ifelse(Denominator == 0, 5, 1))
  
  return(summarized_data)
}


# Main function to calculate crude rate
calculate_crude_rate <- function(indicator_id, denominator_data, numerator_data, aggID, genderGrp, ageGrp, multiplier = 100000) {
  
  
  # Aggregation years to calculate crude rates for 1, 3 and 5 rolling periods
  AggYears <- c(1, 3, 5)
  
  # Initialize an empty list to store results
  results <- list()
  
  for(year in AggYears) {
    
    # Helper function to calculate rates
    calculate_rate <- function(id, group_vars) {
      
      joined_data <- denominator_data %>%
        filter(AggYear == year) %>% 
        left_join(numerator_data %>% 
                    filter(AggYear == year), 
                  by = c("ElectoralWardsAndDivisionsCode" = "WD22CD",
                         "NHSCode" = "EthnicityCode",
                         "FiscalYear" = "FiscalYear"))
      
      # Conditional operations for different levels of aggregations
      if (id == "WD22NM") {
        joined_data <- joined_data %>%
          left_join(ward_locality_unique, by = c("ElectoralWardsAndDivisionsCode" = "WD22CD")) %>%
          group_by(across(all_of(c(group_vars, "WD22NM.y")))) # Grouping by WD22NM.u (complete wards)
        
      } else if (id == "LAD22CD") {
        joined_data <- joined_data %>%
          left_join(Ward_LAD_unique, by = c("ElectoralWardsAndDivisionsCode" = "WD22CD")) %>%
          group_by(across(all_of(c(group_vars, "LAD22CD.y")))) # Grouping by LAD22CD.y (complete LADs)
        
      } else if (id == "Locality") {
        joined_data <- joined_data %>%
          left_join(ward_locality_unique, by = c("ElectoralWardsAndDivisionsCode" = "WD22CD")) %>%
          group_by(across(all_of(c(group_vars, "Locality.y")))) # Grouping by Locality.y (complete localities)
        
      } else if (id == "BSOL ICB") {
        joined_data <- joined_data %>%
          group_by(across(all_of(group_vars))) # No need to left join when id == BSOL
      }
      
      # Summarize and aggregate data to calculate crude rates
      summarized_data <- joined_data %>%
        summarise(
          Numerator = sum(Numerator, na.rm = TRUE),
          Denominator = sum(Denominator),
          .groups = 'keep'
        ) %>%
        mutate(
          Numerator = ifelse(is.na(Numerator) | Denominator == 0, 0, Numerator),
          Denominator = ifelse(Denominator == 0, 1, Denominator)  # Handle cases where Denominator == 0 to avoid errors
        ) %>%
        mutate(
          Gender = genderGrp,
          AgeGroup = ageGrp,
          IMD = ifelse("Quantile" %in% group_vars, Quantile, NA_character_),  
          EthnicityCode = as.character(ifelse("ONSGroup" %in% group_vars, ONSGroup, NA_character_)),
          DataQualityID = 1, # Added DataQualityID
          AggregationLabel = ifelse(id == "BSOL ICB", id, !!sym(paste0(id, ".y"))),
          AggregationType = case_when(
            id == "BSOL ICB" ~ "ICB",
            id == "WD22NM"   ~ "Ward",
            id == "LAD22CD"  ~ "Local Authority",
            TRUE ~ "Locality (resident)"
          )
        ) %>%
        group_by(AggregationType, AggregationLabel, Gender, AgeGroup, IMD, EthnicityCode, FiscalYear, DataQualityID) %>%
        phe_rate(Numerator, Denominator, type = "standard", multiplier = multiplier) %>%
        rename(
          IndicatorValue = value,
          LowerCI95 = lowercl,
          UpperCI95 = uppercl
        )
      
      return(summarized_data)
    }
    
    for (id in aggID) {
      # Overall indicator rate
      overall_rate <- calculate_rate(id = id, group_vars = c("FiscalYear")) %>%
        mutate(IndicatorValueType = paste0(year, "-year Overall Crude Rate")) %>%
        left_join(get_summarized_data(id = id,
                                      group_vars = get_grouping_columns(rate_type = "overall"),
                                      year = year,
                                      denominator_data = denominator_data,
                                      numerator_data = numerator_data),
                  by = if(id == "BSOL ICB"){
                    c("FiscalYear" = "FiscalYear")
                  } else{
                    c("AggregationLabel" = paste0(id, ".y"),
                      "FiscalYear" = "FiscalYear")
                  }) %>%
        select(-Numerator.x, -Denominator.x, -DataQualityID.x) %>%
        rename_with(~ str_replace(., "\\.y$", ""))
      
      # Ethnicity indicator rate
      ethnicity_rate <- calculate_rate(id = id, group_vars = c("FiscalYear", "ONSGroup")) %>%
        mutate(IndicatorValueType = paste0(year, "-year Ethnicity Crude Rate")) %>%
        left_join(get_summarized_data(id = id,
                                      group_vars = get_grouping_columns(rate_type = "ethnicity"),
                                      year = year,
                                      denominator_data = denominator_data,
                                      numerator_data = numerator_data),
                  by = if(id == "BSOL ICB"){
                    c("FiscalYear" = "FiscalYear", 
                      "EthnicityCode" = "ONSGroup")
                  } else{
                    c("AggregationLabel" = paste0(id, ".y"),
                      "FiscalYear" = "FiscalYear",
                      "EthnicityCode" = "ONSGroup")
                  }) %>%
        select(-Numerator.x, -Denominator.x, -DataQualityID.x) %>%
        rename_with(~ str_replace(., "\\.y$", ""))

      # IMD indicator rate
      imd_rate <- calculate_rate(id = id, group_vars = c("FiscalYear", "Quantile")) %>%
        mutate(IndicatorValueType = paste0(year, "-year IMD Crude Rate")) %>% 
        left_join(get_summarized_data(id = id,
                                      group_vars = get_grouping_columns(rate_type = "deprivation"),
                                      year = year,
                                      denominator_data = denominator_data,
                                      numerator_data = numerator_data),
                  by = if(id == "BSOL ICB"){
                    c("FiscalYear" = "FiscalYear", 
                      "IMD" = "Quantile")
                  } else{
                    c("AggregationLabel" = paste0(id, ".y"),
                      "FiscalYear" = "FiscalYear",
                      "IMD" = "Quantile")
                  }) %>%
        select(-Numerator.x, -Denominator.x, -DataQualityID.x) %>%
        rename_with(~ str_replace(., "\\.y$", ""))
      
      # Ethnicity by IMD indicator rate
      ethnicity_imd_rate <- calculate_rate(id = id, group_vars = c("FiscalYear", "ONSGroup", "Quantile")) %>%
        mutate(IndicatorValueType = paste0(year, "-year EthnicityXIMD Crude Rate")) %>% 
        left_join(get_summarized_data(id = id,
                                      group_vars = get_grouping_columns(rate_type = "ethnicity_deprivation"),
                                      year = year,
                                      denominator_data = denominator_data,
                                      numerator_data = numerator_data),
                  by = if(id == "BSOL ICB"){
                    c("FiscalYear" = "FiscalYear",
                      "EthnicityCode" = "ONSGroup",
                      "IMD" = "Quantile")
                  } else{
                    c("AggregationLabel" = paste0(id, ".y"),
                      "FiscalYear" = "FiscalYear",
                      "EthnicityCode" = "ONSGroup",
                      "IMD" = "Quantile")
                  }) %>%
        select(-Numerator.x, -Denominator.x, -DataQualityID.x) %>%
        rename_with(~ str_replace(., "\\.y$", ""))
      
      # Combine all rates into a single data frame
      results[[paste0(id, "_", year, "YR")]] <- bind_rows(
        overall_rate,
        ethnicity_rate,
        imd_rate,
        ethnicity_imd_rate
      ) %>% mutate(EthnicityCode = as.character(EthnicityCode)) # Ensure EthnicityCode is character before binding
    }
  }
  
  # Bind all results together into a single data frame
  final_results <- bind_rows(results)
  
  # Add the rest of the variables as per the OF data model
  output <- final_results %>%
    filter(FiscalYear != '2013/2014') %>%
    mutate(
      IndicatorID = indicator_id,
      InsertDate = today(),
      IndicatorStartDate = as.Date(ifelse(is.na(FiscalYear), NA, paste0(substring(FiscalYear, 1, 4), '-04-01'))),
      IndicatorEndDate = as.Date(ifelse(is.na(FiscalYear), NA, paste0('20', substring(FiscalYear, 8, 9), '-03-31'))),
      StatusID = as.integer(1)) %>%
    clean_names(case = "upper_camel", abbreviations = c("ID", "IMD", "CI")) %>%
    select(
      IndicatorID, InsertDate,Numerator, Denominator, IndicatorValue, IndicatorValueType,
      LowerCI95, UpperCI95, AggregationType, AggregationLabel, FiscalYear, Gender, AgeGroup, IMD, EthnicityCode,
      StatusID, DataQualityID, IndicatorStartDate, IndicatorEndDate)
    
  
  return(output)
}

# Example 
# result <- calculate_crude_rate(
#   indicator_id = 87,
#   denominator_data = my_denominator,
#   numerator_data = my_numerator,
#   aggID = c("BSOL ICB", "WD22NM", "LAD22CD", "Locality"),
#   genderGrp = "Persons",
#   ageGrp = "<75 yrs",
#   multiplier = 100000
# )


#6. Process all parameters -------------------------------------------------------

## 6.1 Optional: Process one indicator at a time -------------------------------
# Can use the following codes directly  if you already know which indicator
# you want to process, and the parameters for that indicator

# Requirements:
#1. Must use indicator_data, containing the indicator you want to process (see Step 3: Get numerator data)
#2. Specify the indicator id parameter
#3. Specify the reference id parameter
#4. Specify the min age group parameter
#5. Specify the max age group parameter

## Use 'result' variable to write the data into database (Step 7)

my_numerator <- get_numerator(indicator_data = indicator_data,
                                   indicator_id = 87,
                                   min_age = NA,
                                   max_age = 74)

my_denominator <- get_denominator(min_age = NA,
                                    max_age = 74,
                                    pop_estimates = popfile_ward,
                                    numerator_data = my_numerator)

result <- calculate_crude_rate(
  indicator_id = 87,
  denominator_data = my_denominator,
  numerator_data = my_numerator,
  aggID = c("BSOL ICB", "WD22NM", "LAD22CD", "Locality"),
  genderGrp = "Persons",
  ageGrp = "<75 yrs",
  multiplier = 100000
)


## 6.2 Process several indicators altogether -----------------------------
# Read the Excel file to get the available indicators
parameter_combinations <- readxl::read_excel("data/parameter_combinations.xlsx", 
                                             sheet = "crude_indicators")

indicators_params <- parameter_combinations %>% 
  filter(StandardizedIndicator == 'N' & PredeterminedDenominator == "N") %>% # Ensure we're taking the correct indicators
  filter(IndicatorID %in% indicator_ids) # Ensure we're extracting parameters ONLY for indicators we've specified in the beginning, otherwise, error will occur.


## Apply functions to specific parameter combinations 

# Parameter:
# row: the row of parameter combinations data

process_parameters <- function(row) {
  # Try to calculate crude rates
  tryCatch(
    {
      print(paste("Processing numerator data for indicator ID:", row$IndicatorID, "& reference ID:", row$ReferenceID))
      
      numerator_data <- get_numerator(
        indicator_data = indicator_data,
        indicator_id = row$IndicatorID,
        reference_id = row$ReferenceID,
        min_age = row$MinAge,
        max_age = row$MaxAge
      )
      
      print(paste("Processing denominator data for indicator ID:", row$IndicatorID, "& reference ID:", row$ReferenceID))
      
      denominator_data <- get_denominator(
        min_age = row$MinAge,
        max_age = row$MaxAge,
        pop_estimates = popfile_ward,
        numerator_data = numerator_data
      )
      
      print(paste("Calculating crude rates for indicator ID:", row$IndicatorID, "& reference ID:", row$ReferenceID))

      final_output <- calculate_crude_rate(
        indicator_id = row$IndicatorID,
        denominator_data = denominator_data,
        numerator_data = numerator_data,
        aggID = c("BSOL ICB", "WD22NM", "LAD22CD", "Locality"),
        genderGrp = row$GenderCategory,
        ageGrp = row$AgeCategory
      )

      print(paste("Process completed!"))

    },
    # Error handling
    error = function(e) {
      message(
        paste0(
          "Error occurred for IndicatorID: ", row$IndicatorID,
          ", ReferenceID: ", row$ReferenceID,
          ", MinAge: ", row$MinAge,
          ", MaxAge: ", row$MaxAge,
          "\nDetails: ", e
        )
      )

      # Create an empty dataframe with the correct column types and NA values
      final_output <- tibble(
        IndicatorID = NA_integer_,
        InsertDate = as.Date(NA),
        Numerator = NA_real_,
        Denominator = NA_real_,
        IndicatorValue = NA_real_,
        LowerCI95 = NA_real_,
        UpperCI95 = NA_real_,
        AggregationType = NA_character_,
        AggregationLabel = NA_character_,
        FiscalYear = NA_character_,
        Gender = NA_character_,
        AgeGroup = NA_character_,
        IMD = NA_character_,
        EthnicityCode = NA_character_,
        NHSCodeDefinition = NA_character_,
        DataQualityID = NA_integer_,
        IndicatorStartDate = as.Date(NA),
        IndicatorEndDate = as.Date(NA),
        IndicatorValueType = NA_character_
      )
    }
  )

  return(final_output)
}

# Apply the function to each row of the parameter combinations
results <- indicators_params %>%
  rowwise() %>% # This ensures each row is treated as a separate set of inputs
  do(process_parameters(.)) %>%  # Apply the function to each row
  ungroup() #Remove the rowwise grouping, so the output is a simple tibble


# Write into database ----------------------------------------------------------

sql_connection <-
  dbConnect(
    odbc(),
    Driver = "SQL Server",
    Server = "MLCSU-BI-SQL",
    Database = "Working",
    Trusted_Connection = "True"
  )

# Overwrite the existing table
dbWriteTable(
  sql_connection,
  Id(schema = "dbo", table = "BSOL_0033_OF_Crude_Rates"),
  results, # Processed dataset
  append = TRUE # Append data to the existing table
  # overwrite = TRUE
)

# End the timer
end_time <- Sys.time()

# Calculate the time difference
time_taken <- end_time - start_time

# Print the time taken
print(paste("Time taken to run the script", time_taken))  