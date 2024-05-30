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

#2. Reference tables -----------------------------------------------------------

##2.1 LSOA 2021 to Ward 2022 to LAD 2022 Lookup --------------------------------
lsoa_ward_lad_map<-read.csv("data/Lower_Layer_Super_Output_Area_(2021)_to_Ward_(2022)_to_LAD_(2022)_Lookup_in_England_and_Wales_v3.csv")
lsoa_ward_lad_map <- lsoa_ward_lad_map %>% 
  filter(LAD22CD %in% c('E08000025', 'E08000029'))

##2.2 Ward to Locality Lookup --------------------------------------------------
ward_locality_map <- read.csv("data/ward_to_locality.csv", header = TRUE, check.names = FALSE)
ward_locality_map <- ward_locality_map %>% 
  rename(LA = ParentCode,
         WardCode = AreaCode,
         WardName = AreaName)

##2.3 Ethnicity Code Translator ------------------------------------------------
ethnic_codes <- read.csv("data/nhs_ethnic_categories.csv", header = TRUE, check.names = FALSE)
ethnic_codes <- ethnic_codes %>%
  select(NHSCode, CensusEthnicGroup, NHSCodeDefinition)

##2.4 Population Estimates by Ward ---------------------------------------------
popfile_ward <- read.csv("data/C21_a86_e20_ward.csv", header = TRUE, check.names = FALSE) %>% 
  clean_names()

#3. Get numerator data ---------------------------------------------------------
#3.1 Load the indicator data from the warehouse --------------------------------

indicator_data <- dbGetQuery(
  con,
  "SELECT *
  FROM [EAT_Reporting_BSOL].[OF].[IndicatorData]"
) %>% as_tibble()

#4. Data Preparation -----------------------------------------------------------
##4.1 Parameters ----------------------------------------------------------------
# Potentially, vector data type

age_min <- 65
age_max <- NA
indicator_id <- 11
reference_id <- 22401

age_category <- '65+ yrs'
gender_category <- 'Persons'

  
##4.2 Function 1: Process Numerator Data ---------------------------------------

# Parameters:
# indicator_data: main indicator dataset
# indicator_id: indicator ID
# reference_id: (optional) Fingertips ID if available
# min_age: (Optional) To accept indicator with specific min age 
# max_age: (Optional) To accept indicator with specific max age


get_numerator <- function(indicator_data, indicator_id, reference_id = NA, min_age = NA, max_age = NA) {
  
  # Debug: Print input parameters
  print(paste("get_numerator called with:", 
              "indicator_id =", indicator_id, 
              "reference_id =", reference_id, 
              "min_age =", min_age, 
              "max_age =", max_age))
  
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
    group_by(Ethnicity_Code, LSOA_2021, Age, Financial_Year) %>% 
    summarise(Numerator = sum(Numerator, na.rm = TRUE), .groups = 'drop') %>% 
    rename(Fiscal_Year = Financial_Year) %>% 
    mutate(Fiscal_Year = str_replace(Fiscal_Year, "-", "/20"))
  
  # Enrich the data with the geographies lookups
  output <- output %>%
    left_join(lsoa_ward_lad_map, by = c("LSOA_2021" = "LSOA21CD")) %>% 
    left_join(ward_locality_map, by = c("WD22NM" = "WardName")) %>% 
    group_by(Ethnicity_Code, Fiscal_Year, LAD22CD, WD22CD, WD22NM, Locality) %>%  
    summarise(Numerator = as.numeric(sum(Numerator, na.rm = TRUE)), .groups = 'drop') %>% 
    select(Numerator, Ethnicity_Code, Fiscal_Year, LAD22CD, WD22CD, WD22NM, Locality) %>% 
    clean_names(case = "upper_camel", abbreviations = c("WD", "LAD", "CD", "NM"))
  
  return(output)
}

# Call the function 
numerator_data <- get_numerator(
  indicator_data = indicator_data,
  indicator_id = indicator_id,
  reference_id = reference_id,
  min_age = age_min,
  max_age = age_max
) 

##4.3 Function 2: Process Denominator Data  ------------------------------------

# Parameters:
# min_age: (Optional) To accept indicator with specific min age
# max_age: (Optional) To accept indicator with specific max
# pop_estimates: Population file by Ward
# numerator_data: The filtered numerator dataset to get the available periods

get_denominator <- function(min_age = NA, max_age = NA, pop_estimates, numerator_data){
  
  # Debug: Print input parameters
  print(paste("get_denominator called with:", 
              "min_age =", min_age, 
              "max_age =", max_age))
  
  # Get unique pairs of WD22CD and LAD22CD
  LSOA_LAD_unique <- lsoa_ward_lad_map %>% 
    select(WD22CD, LAD22CD) %>% 
    distinct()
  
  # Map the population estimates to the unique Wards and LADs
  pop_estimates <- pop_estimates %>% 
    inner_join(LSOA_LAD_unique, 
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
  periods <- unique(numerator_data$FiscalYear[!is.na(numerator_data$FiscalYear)]) %>%
    tibble() %>%
    rename(FiscalYear = ".")

  # Enrich the population estimates with quintiles and ethnicity descriptions
  output <- pop_estimates %>%
    left_join(imd_england_ward,
              by = c("electoral_wards_and_divisions_code" = "ward_code")) %>%
    left_join(ethnic_codes,
              by = c("ethnic_group_20_categories_code" = "CensusEthnicGroup" )) %>%
    group_by(electoral_wards_and_divisions_code, electoral_wards_and_divisions,
             ethnic_group_20_categories_code, NHSCode, NHSCodeDefinition, quantile) %>%
    summarise(Denominator = as.numeric(sum(observation, na.rm = TRUE)), .groups = 'drop') %>%
    cross_join(periods) %>%
    clean_names(case = "upper_camel", abbreviations = c("NHS"))
  
  return(output)
}

# Call the function 
denominator_data <- get_denominator(min_age = age_min,
                                    max_age = age_max,
                                    pop_estimates = popfile_ward, 
                                    numerator_data = numerator_data
                                    )

#5. Crude Rates Calculation ----------------------------------------------------
#5.1 Function 3: Calculate crude rates -----------------------------------------
# Parameters:
# indicator_id: Indicator ID for which the rates are calculated
# numerator_data: Numerator data set
# denominator_data: Denominator data set
# aggID: Geographic levels, e.g., c('BSOL', 'LAD22CD', 'Locality', 'WD22NM')
# genderGrp: The gender for which the indicator was measured, e.g., c('Persons', 'Male', 'Female')
# ageGrp: The age group for which the indicator was measured, e.g., c('65+', 'All ages', '0-18')

calculate_crude_rate <- function(indicator_id, denominator_data, numerator_data, aggID, genderGrp, ageGrp, multiplier = 100000) {
  
  # Get unique pairs of Wards and Localities
  Localities_Ward_unique <- numerator_data %>% 
    select(Locality, WD22CD, WD22NM) %>% 
    distinct()
  
  # Get unique pairs of Wards and LADs
  LSOA_LAD_unique <- lsoa_ward_lad_map %>% 
    select(WD22CD, LAD22CD) %>% 
    distinct()
  
  # Helper function to calculate rates
  calculate_rate <- function(id, group_vars) {
    
    joined_data <- denominator_data %>%
      left_join(numerator_data, by = c("ElectoralWardsAndDivisionsCode" = "WD22CD",
                                       "NHSCode" = "EthnicityCode",
                                       "FiscalYear" = "FiscalYear"))
    
    # Conditional operations for different levels of aggregations
    if (id == "WD22NM") {
      joined_data <- joined_data %>%
        left_join(Localities_Ward_unique, by = c("ElectoralWardsAndDivisionsCode" = "WD22CD")) %>%
        group_by(across(all_of(c(group_vars, "WD22NM.y")))) # Grouping by WD22NM.y
      
    } else if (id == "LAD22CD") {
      joined_data <- joined_data %>%
        left_join(LSOA_LAD_unique, by = c("ElectoralWardsAndDivisionsCode" = "WD22CD")) %>%
        group_by(across(all_of(c(group_vars, "LAD22CD.y")))) # Grouping by LAD22CD.y
      
    } else if (id == "Locality") {
      joined_data <- joined_data %>%
        left_join(Localities_Ward_unique, by = c("ElectoralWardsAndDivisionsCode" = "WD22CD")) %>%
        group_by(across(all_of(c(group_vars, "Locality.y")))) # Grouping by Locality.y
      
    } else if (id == "BSOL ICB") {
      joined_data <- joined_data %>%
        group_by(across(all_of(group_vars))) # No need for left joining when id == BSOL
    }
    
    # Summarize and aggregate data to calculate rates
    summarized_data <- joined_data %>%
      mutate(
        Numerator = ifelse(is.na(Numerator) | Denominator == 0, 0, Numerator),
        Denominator = ifelse(Denominator == 0, 1, Denominator)  # Handle cases where Denominator == 0 to avoid errors
      ) %>%
      summarise(
        Numerator = sum(Numerator, na.rm = TRUE),
        Denominator = sum(Denominator, na.rm = TRUE),
        .groups = 'keep'
      ) %>%
      mutate(
        Gender = genderGrp,
        AgeGroup = ageGrp,
        IMD = ifelse("Quantile" %in% group_vars, Quantile, NA_character_),  
        EthnicityCode = as.character(ifelse("NHSCode" %in% group_vars, NHSCode, NA_character_)),
        AggregationLabel = ifelse(id == "BSOL ICB", id, !!sym(paste0(id, ".y"))),
        AggregationType = case_when(
          id == "BSOL ICB" ~ "ICB",
          id == "WD22NM" ~ "Ward",
          id == "LAD22CD" ~ "Local Authority",
          TRUE ~ "Locality (resident)"
        )
      ) %>%
      group_by(AggregationType, AggregationLabel, Gender, AgeGroup, IMD, EthnicityCode, FiscalYear) %>%
      phe_rate(Numerator, Denominator, type = "standard", multiplier = multiplier) %>%
      rename(
        IndicatorValue = value,
        LowerCI95 = lowercl,
        UpperCI95 = uppercl
      )
    
    return(summarized_data)
  }
  
  results <- list()
  
  for (id in aggID) {
    # Overall indicator rate
    overall_rate <- calculate_rate(id = id, group_vars = c("FiscalYear")) %>%
      mutate(IndicatorValueType = "Overall Crude Rate")
    
    # Ethnicity indicator rate
    ethnicity_rate <- calculate_rate(id = id, group_vars = c("FiscalYear", "NHSCode")) %>%
      mutate(IndicatorValueType = "Ethnicity Crude Rate")
    
    # IMD indicator rate
    imd_rate <- calculate_rate(id = id, group_vars = c("FiscalYear", "Quantile")) %>%
      mutate(IndicatorValueType = "IMD Crude Rate")
    
    # Ethnicity by IMD indicator rate
    ethnicity_imd_rate <- calculate_rate(id = id, group_vars = c("FiscalYear", "NHSCode", "Quantile")) %>%
      mutate(IndicatorValueType = "Ethnicity-IMD Crude Rate")
    
    # Combine all rates into a single data frame
    results[[id]] <- bind_rows(
      overall_rate,
      ethnicity_rate,
      imd_rate,
      ethnicity_imd_rate
    ) %>% mutate(EthnicityCode = as.character(EthnicityCode)) # Ensure EthnicityCode is character before binding
  }
  
  # Bind all results together into a single data frame
  final_results <- bind_rows(results)
  
  # Add the rest of the variables as per the OF data model
  output <- final_results %>%
    filter(FiscalYear != '2013/2014') %>%
    ungroup() %>% # Remove any existing grouping that could affect the row number calculation
    mutate(
      ValueID = row_number(),
      IndicatorID = indicator_id,
      InsertDate = today(),
      IndicatorStartDate = as.Date(ifelse(is.na(FiscalYear), NA, paste0(substring(FiscalYear, 1, 4), '-04-01'))),
      IndicatorEndDate = as.Date(ifelse(is.na(FiscalYear), NA, paste0('20', substring(FiscalYear, 8, 9), '-03-31'))),
      StatusID = as.integer(1), # current
      DataQualityID = as.integer(1) # No issues
    ) %>%
    left_join(ethnic_codes, by = c("EthnicityCode" = "NHSCode")) %>%
    clean_names(case = "upper_camel", abbreviations = c("ID", "NHS", "IMD", "CI")) %>% 
    select(
      ValueID, IndicatorID, InsertDate, Numerator, Denominator, IndicatorValue, IndicatorValueType,
      LowerCI95, UpperCI95, AggregationType, AggregationLabel, FiscalYear, Gender, AgeGroup, IMD, EthnicityCode, NHSCodeDefinition,
      StatusID, DataQualityID, IndicatorStartDate, IndicatorEndDate
    )
  
  return(output)
}


# Call function
crude_rate_result <- calculate_crude_rate(
  indicator_id = indicator_id,
  denominator_data = denominator_data, 
  numerator_data = numerator_data,
  aggID = c("BSOL ICB", "WD22NM", "LAD22CD", "Locality"),
  genderGrp = gender_category, 
  ageGrp = age_category
) 

##5.2 Function 3: Calculate aggregated crude rates -----------------------------

calculate_aggregated_rate <- function(crude_rate_data, aggregated_years = c(3, 5)) {
  aggregated_results <- list() # To store results for each aggregation period
  
  for (year in aggregated_years) {
    aggregated_data <- crude_rate_data %>%
      mutate(
        FiscalYearStart = as.numeric(substr(FiscalYear, 1, 4)),
        EthnicityCode = as.character(EthnicityCode)  # Ensure EthnicityCode is character
      ) %>%
      group_by(
        PeriodStart = (FiscalYearStart %/% year) * year,
        AggregationType, AggregationLabel, Gender, AgeGroup, IMD, EthnicityCode, 
        NHSCodeDefinition, IndicatorID, IndicatorValueType
      ) %>%
      summarize(
        Numerator = sum(Numerator, na.rm = TRUE),
        Denominator = mean(Denominator, na.rm = TRUE), 
        .groups = "keep"
      ) %>%
      mutate(
        FiscalYear = paste0(PeriodStart, "/", PeriodStart + year - 1)
      )
    
    # Recalculate rates
    aggregated_output <- aggregated_data %>%
      group_by(
        AggregationType, AggregationLabel, Gender, AgeGroup, IMD, EthnicityCode, 
        NHSCodeDefinition, FiscalYear, IndicatorID, IndicatorValueType
      ) %>%
      phe_rate(Numerator, Denominator, type = "standard", multiplier = 100000) %>%
      rename(
        IndicatorValue = value, 
        LowerCI95 = lowercl, 
        UpperCI95 = uppercl
      ) %>%
      ungroup() %>%
      mutate(
        ValueID = row_number(),
        IndicatorValueType = paste0(year, "-year ", IndicatorValueType),
        InsertDate = today(),
        IndicatorStartDate = as.Date(ifelse(is.na(FiscalYear), NA, paste0(substring(FiscalYear, 1, 4), '-04-01'))),
        IndicatorEndDate = as.Date(ifelse(is.na(FiscalYear), NA, paste0(substring(FiscalYear, 6, 9), '-03-31'))),  
        StatusID = as.integer(1),
        DataQualityID = as.integer(1)
      ) %>%
      select(names(crude_rate_data))
    
    # Store results for the current aggregation period
    aggregated_results[[as.character(year)]] <- aggregated_output 
  }
  
  # Combine results for all aggregation periods
  return(bind_rows(aggregated_results))
}


# Call function

aggregated_crude_rate_result <- calculate_aggregated_rate(crude_rate_data = crude_rate_result)


#6. Final data set -------------------------------------------------------------

final_output <- bind_rows(crude_rate_result, aggregated_crude_rate_result) %>% 
  mutate(ValueID = row_number())

write.csv(final_output, "data/Falls_dataset.csv")

#7. Process all parameters -------------------------------------------------------

parameter_combinations <- read_csv("data/parameter_combinations.csv", show_col_types = FALSE)

process_parameters <- function(row) {
  # Try to calculate crude rate and aggregated rate
  tryCatch(
    {
      numerator_data <- get_numerator(
        indicator_data = indicator_data,
        indicator_id = row$IndicatorID,
        reference_id = row$ReferenceID,
        min_age = row$MinAge,
        max_age = row$MaxAge
      )

      denominator_data <- get_denominator(
        min_age = row$MinAge,
        max_age = row$MaxAge,
        pop_estimates = popfile_ward,
        numerator_data = numerator_data
      )

      crude_rate_result <- calculate_crude_rate(
        indicator_id = row$IndicatorID,
        denominator_data = denominator_data,
        numerator_data = numerator_data,
        aggID = c("BSOL ICB", "WD22NM", "LAD22CD", "Locality"),
        genderGrp = row$GenderCategory,
        ageGrp = row$AgeCategory
      )

      aggregated_crude_rate_result <- calculate_aggregated_rate(
        crude_rate_data = crude_rate_result
      )

      final_output <- bind_rows(crude_rate_result, aggregated_crude_rate_result) %>%
        mutate(ValueID = row_number())

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
        ValueID = NA_integer_,
        IndicatorID = NA_real_,
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
results <- parameter_combinations %>%
  rowwise() %>% # This ensures each row is treated as a separate set of inputs
  do(process_parameters(.)) %>%  # Apply the function to each row
  ungroup() #Remove the rowwise grouping, so the output is a simple tibble


write.csv(results, "data/OF_dataset.csv")

