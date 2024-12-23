
##########################INSTRUCTIONS##########################################################
# 1. Go to Step 2: Get data from database                                                     ##
# 2. Insert the indicator ID that you wish to extract data from database                      ##  
# 3. If you want to process one indicator at a time:                                          ## 
#     - Run the code from the beginning until Step 9.1                                        ## 
#     - Ensure that you specify the parameters for that indicator                             ## 
#     - And the clean_data contains the indicator ID that you wish to process                 ## 
#     - If necessary, filter the indicator_data to include the relevant indicator ID          ## 
# 4. If you want to process multiple indicators at the same time:                             ## 
#    - Ensure that you've filled in the parameter_combinations.xlsx file with the indicators  ## 
#    - Run the code from the beginning until Step 9.2 (skip Step 9.1)                         ## 
################################################################################################

library(tidyverse)
library(janitor)
library(DBI)
library(odbc)
library(PHEindicatormethods)
library(clipr)
library(readxl)
library(lubridate)

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

#2. Get data from database -------------------------------------------------------

# Insert which indicator IDs to extract
indicator_ids <- c(1, 2, 3, 4, 16, 20, 25, 35, 36, 37, 38, 42, 46, 47, 57, 58, 68, 70, 74, 76, 77,
                   78, 85, 86, 90, 93, 103, 105, 107, 110, 112, 113, 116, 120, 121, 122, 123, 125, 127)

# Convert the indicator IDs to a comma-separated string
indicator_ids_string <- paste(indicator_ids, collapse = ", ")

query <- paste0("SELECT * FROM EAT_Reporting_BSOL.[OF].IndicatorDataPredefinedDenominator
          where IndicatorID IN (", indicator_ids_string, ")")

data <- dbGetQuery(con, query)


#3. Ethnicity mapping ------------------------------------------------------------

ethnicity_map <- dbGetQuery(
  con,
  "SELECT [NHSCode]
  ,       [NHSCodeDefinition]
  ,       [LocalGrouping]
  ,       [CensusEthnicGroup]
  ,       [ONSGroup]
  FROM [EAT_Reporting_BSOL].[OF].[lkp_ethnic_categories]") %>%
  as_tibble()

# Clean Ethnicity coding
data <- data %>%
  mutate(Ethnicity_Code = trimws(Ethnicity_Code),
         Ethnicity_Code = case_when(
           Ethnicity_Code == "" ~ NA_character_, # Replace empty with NA
           Ethnicity_Code == "99" ~ "Z", # Replace '99' with 'Z' (Not Stated)
           TRUE ~ Ethnicity_Code
         ))

# Create a copy of data to work with
dt <- data

##4. Process time periods altogether in the dataset -------------------------------

process_time_periods <- function(data) {
  # Process the 'Month' data
  month_data <- data %>%
    filter(TimePeriodDesc == "Month") %>%
    mutate(FiscalYear = as.character(convert_yearmonth_period(TimePeriod)))
  
  # Process the 'Other' data
  other_data <- data %>%
    filter(TimePeriodDesc == "Other") %>%
    mutate(FiscalYear = case_when(
      grepl("-", TimePeriod) ~ as.character(convert_fixed_period(TimePeriod)),
      grepl("To", TimePeriod) ~ as.character(convert_quarterly_period(TimePeriod)),
      TRUE ~ as.character(TimePeriod)
    ))
  
  # Process the 'Financial Year' data
  fy_data <- data %>%
    filter(TimePeriodDesc == "Financial Year") %>%
    mutate(FiscalYear = as.character(parse_fiscal_year(TimePeriod)))
  
  # Combine the processed data back together
  combined_data <- bind_rows(month_data, other_data, fy_data)
  
  return(combined_data)
}


updated_dt <- process_time_periods(dt)


# Check unique fiscal year for each time period desc
updated_dt %>% 
  group_by(IndicatorID, TimePeriodDesc, TimePeriod, FiscalYear) %>% 
  select(IndicatorID, TimePeriodDesc, TimePeriod, FiscalYear) %>% 
  distinct() %>% 
  View()

#5. Clean datasets ----------------------------------------- -------------------
## Exclude Closed practice and Not applicable in PCN column
## Exclude 
## Add column AggYear = 1

clean_dataset <- function(data){
  
  data <- data %>% 
    filter(!(PCN %in% c("Closed practice", "Not applicable"))) %>% 
    filter(!(GP_Practice %in% c('M88006'))) %>% 
    filter(!(FiscalYear  == "2024/2025")) %>% # Filters out 2024/25 
    mutate(AggYear = 1) 

  return(data)
}

clean_dt <- updated_dt %>% 
  clean_dataset()


#7. Function to create grouping columns ----------------------------------------
# Columns to group the data by, for calculating Only overall crude rates and rates by ethnicity

get_grouping_columns <- function(rate_type, rate_level) {
  base_group_vars <- c("IndicatorID", "ReferenceID", "FiscalYear", "AggYear")
  
  # Add additional grouping columns based on rate_level
  if (rate_level == "PCN") {
    additional_group_var <- "PCN"
  } else if (rate_level == "Locality") { 
    additional_group_var <- "Locality_Reg"
  } else if (rate_level == "Local Authority"){ # Adds Local_Authority
    additional_group_var <- "Local_Authority"
  } else {
    additional_group_var <- NULL # For calculating rates at ICB level, no additional column
  }
  
  # Add the rate_type specific grouping columns
  group_vars <- switch(rate_type,
                       "overall" = base_group_vars,
                       "ethnicity" = c(base_group_vars, "ONSGroup"),
                       "IMD" = c(base_group_vars, "IMD_Quintile"),
                       stop("Invalid rate type specified.")
  )
  
  # Append the additional grouping column if any
  if (!is.null(additional_group_var)) {
    group_vars <- c(group_vars, additional_group_var)
  }
  
  return(group_vars)
}

# Example of usage
get_grouping_columns(rate_type = "overall", rate_level = "ICB")  

# 8. Function to calculate crude rate ------------------------------------------
##8.1 Helper base function to calculate crude rate -----------------------------

calculate_crude_rate <- function(data, group_vars, aggYear = c(1, 3, 5), rate_level, rate_type, ageGrp, genderGrp, multiplier = 100000) {
  
  all_results <- list()  # Initialize a list to store results for each year
  
  for (year in aggYear) {
    # Filter data for the specified aggregation year
    filtered_data <- data %>% filter(AggYear == year)
    
    # Perform the join and grouping based on the type
    grouped_data <- if (rate_type == "ethnicity") {
      filtered_data %>%
        left_join(ethnicity_map, by = c("Ethnicity_Code" = "NHSCode")) %>%
        group_by(across(all_of(group_vars)))
    } else {
      filtered_data %>%
        group_by(across(all_of(group_vars)))
    }
    
    # Summarize data
    result <- grouped_data %>%
      summarise(Numerator = sum(Numerator, na.rm = TRUE),
                Denominator = sum(Denominator, na.rm = TRUE),
                .groups = 'drop') %>%
      mutate(
        OriginalSign = sign(Numerator),  # Capture the original sign of Numerator
        Numerator = abs(Numerator)       # Get the absolute number to handle negative numerators (such as Excess Winter death index)
      ) %>%
      mutate(
        Numerator = ifelse(is.na(Numerator) | Denominator == 0, 0, Numerator),
        Denominator = ifelse(Denominator == 0, 1, Denominator)  # Prevent division by zero
      ) %>%
      phe_rate(Numerator, Denominator, type = "standard", multiplier = multiplier) %>%
      rename(
        IndicatorValue = value,
        LowerCI95 = lowercl,
        UpperCI95 = uppercl
      ) %>%
      mutate(
        Numerator = Numerator * OriginalSign,  # Reapply the original sign to the numerator
        IndicatorValue = IndicatorValue * OriginalSign,  # Reapply the original sign to the calculated rate
        LowerCI95 = LowerCI95 * OriginalSign,  # Reapply the original sign to the lower CI
        UpperCI95 = UpperCI95 * OriginalSign   # Reapply the original sign to the upper CI
      ) %>%
      # Use if_else to handle different rate levels and conditions
      mutate(
        InsertDate = today(),
        AggYear = year,
        DataQualityID = 1,
        StatusID = 1,
        AggregationLabel = if (rate_level == "PCN") {
          PCN
        } else if (rate_level ==  "Locality") {
          Locality_Reg
        } else if (rate_level == "Local Authority"){ # Adds Local_Authority
          Local_Authority 
        } else if (rate_level == "ICB") {
          "BSOL ICB"
        } else {
          NA_character_
        },
        AggregationType = if (rate_level == "PCN") {
          "PCN"
        } else if (rate_level == "Locality") {
          "Locality (Registered)"
        } else if (rate_level == "Local Authority") {
          "Local Authority"
        } else if (rate_level == "ICB") {
          "ICB"
        } else {
          NA_character_
        },
        Gender = genderGrp,
        AgeGroup = ageGrp,
        IMD = if (rate_type == "IMD") paste0("Q", IMD_Quintile) else NA_character_, # Adds IMD
        EthnicityCode = if (rate_type == "ethnicity") ONSGroup else NA_character_) %>%   # Directly assign ONSGroup
      ungroup() %>% 
      mutate(
        IndicatorStartDate = case_when(
          nchar(FiscalYear) == 15 ~ as.character(get_start_date_from_fixed_period(FiscalYear)),
          nchar(FiscalYear) == 9 ~ as.character(get_start_date_from_fiscal_year(FiscalYear)),
          TRUE ~ NA_character_
        ),
        IndicatorEndDate = case_when(
          nchar(FiscalYear) == 15 ~ as.character(get_end_date_from_fixed_period(FiscalYear)),
          nchar(FiscalYear) == 9 ~ as.character(get_end_date_from_fiscal_year(FiscalYear)),
          TRUE ~ NA_character_
        ),
        IndicatorValueType = case_when(
          rate_type == "ethnicity" ~ paste0(year, "-year Ethnicity Crude Rate"),
          rate_type == "overall" ~ paste0(year, "-year Overall Crude Rate"),
          rate_type == "IMD" ~ paste0(year, "-year IMD Crude Rate") # Adds IMD
        )
      ) %>%
      select(IndicatorID, InsertDate, Numerator, Denominator, IndicatorValue, IndicatorValueType,
             LowerCI95, UpperCI95, AggregationType, AggregationLabel, FiscalYear, Gender, AgeGroup, IMD, EthnicityCode,
             StatusID, DataQualityID, IndicatorStartDate, IndicatorEndDate, AggYear)
    
    # Store result in list
    all_results[[paste0(year, "YR_data")]] <- result
  }
  
  # Combine results for all years
  output <- bind_rows(all_results)
  
  return(output)
}




# #8.2 Final function to calculate crude rate depending on the rate level ---------

# Function to identify unique indicator levels for each indicator
identify_indicator_levels <- function(data) {
  data %>%
    group_by(IndicatorID) %>%
    summarise(Levels = list(unique(Indicator_Level))) %>%
    ungroup()
}


process_dataset <- function(clean_data, ageGrp, genderGrp, multiplier = 100000) {
  
  # Step 1: Preprocess indicator levels
  indicator_levels <- identify_indicator_levels(clean_data)
  
  # Step 2: Aggregate the data
  aggregated_data <- create_aggregate_data(clean_data)
  
  # Step 3: Define a helper function to calculate rates
  calculate_rates <- function(data, rate_level) {
    # Overall rate
    rate_overall <- calculate_crude_rate(
      data = data,
      group_vars = get_grouping_columns(rate_type = "overall", rate_level = rate_level),
      aggYear = c(1, 3, 5),
      rate_level = rate_level,
      rate_type = "overall",
      ageGrp = ageGrp,
      genderGrp = genderGrp,
      multiplier = multiplier
    )
    
    # Ethnicity rate
    rate_ethnicity <- calculate_crude_rate(
      data = data,
      group_vars = get_grouping_columns(rate_type = "ethnicity", rate_level = rate_level),
      aggYear = c(1, 3, 5),
      rate_level = rate_level,
      rate_type = "ethnicity",
      ageGrp = ageGrp,
      genderGrp = genderGrp,
      multiplier = multiplier
    )
    
    # IMD rate
    rate_IMD <- calculate_crude_rate(
      data = data %>% filter(!is.na(IMD_Quintile)), # Filter out NULL IMD values
      group_vars = get_grouping_columns(rate_type = "IMD", rate_level = rate_level),
      aggYear = c(1, 3, 5),
      rate_level = rate_level,
      rate_type = "IMD",
      ageGrp = ageGrp,
      genderGrp = genderGrp,
      multiplier = multiplier
    )
    
    return(list(rate_overall = rate_overall, rate_ethnicity = rate_ethnicity, rate_IMD = rate_IMD))
  }
  
  # Step 4: Loop through unique Indicator Levels and calculate rates accordingly
  combined_rates <- list()
  
  for (indicator_id in unique(aggregated_data$IndicatorID)) {
    levels <- indicator_levels$Levels[indicator_levels$IndicatorID == indicator_id][[1]]
    
    print(paste("Processing IndicatorID:", indicator_id, "with levels:", paste(levels, collapse = ", ")))
    
    
    if ("Practice Level" %in% levels && "ICB Level" %in% levels) {
      # For "Practice Level", calculate rates for PCN, Locality, Local Authority, and ICB (Overall crude rate only)
      practice_data <- aggregated_data %>% filter(Indicator_Level == "Practice Level", IndicatorID == indicator_id)
      
      rates_pcn <- calculate_rates(practice_data, "PCN")
      rates_locality <- calculate_rates(practice_data, "Locality")
      rates_local_authority <- calculate_rates(practice_data, "Local Authority")
      rates_icb <- calculate_rates(practice_data, "ICB")
      
      combined_rates <- append(combined_rates, list(rates_pcn$rate_overall, rates_pcn$rate_ethnicity, rates_pcn$rate_IMD))
      combined_rates <- append(combined_rates, list(rates_locality$rate_overall, rates_locality$rate_ethnicity, rates_locality$rate_IMD))
      combined_rates <- append(combined_rates, list(rates_local_authority$rate_overall, rates_local_authority$rate_ethnicity, rates_local_authority$rate_IMD))
      combined_rates <- append(combined_rates, list(rates_icb$rate_overall)) # Calculate only overall crude rate using practice-level data
      
      # For "ICB Level", calculate rates only where IMD_Quintile is not NULL
      icb_data <- aggregated_data %>% filter(Indicator_Level == "ICB Level", IndicatorID == indicator_id,
                                             !is.na(IMD_Quintile)
      )
      if (nrow(icb_data) > 0) {
        rates_icb <- calculate_rates(icb_data, "ICB")
        combined_rates <- append(combined_rates, list(rates_icb$rate_IMD)) # Calculate only IMD crude rate using ICB-level data
      }
      
    } else if ("Practice Level" %in% levels) {
      # Calculate rates for PCN, Locality, Local Authority, and ICB from "Practice Level"
      practice_data <- aggregated_data %>% filter(Indicator_Level == "Practice Level", IndicatorID == indicator_id)
      
      rates_pcn <- calculate_rates(practice_data, "PCN")
      rates_locality <- calculate_rates(practice_data, "Locality")
      rates_local_authority <- calculate_rates(practice_data, "Local Authority")
      rates_icb <- calculate_rates(practice_data, "ICB")
      
      combined_rates <- append(combined_rates, list(rates_pcn$rate_overall, rates_pcn$rate_ethnicity, rates_pcn$rate_IMD))
      combined_rates <- append(combined_rates, list(rates_locality$rate_overall, rates_locality$rate_ethnicity, rates_locality$rate_IMD))
      combined_rates <- append(combined_rates, list(rates_local_authority$rate_overall, rates_local_authority$rate_ethnicity, rates_local_authority$rate_IMD))
      combined_rates <- append(combined_rates, list(rates_icb$rate_overall, rates_icb$rate_ethnicity, rates_icb$rate_IMD))
      
    } else if ("ICB Level" %in% levels) {
      # Calculate rates only for ICB Level where IMD_Quintile is not NULL
      icb_data <- aggregated_data %>% filter(Indicator_Level == "ICB Level", IndicatorID == indicator_id)
      
      rates_icb <- calculate_rates(icb_data, "ICB")
      combined_rates <- append(combined_rates, list(rates_icb$rate_overall, rates_icb$rate_ethnicity, rates_icb$rate_IMD))
      
    } else if ("Birmingham Local Authority"  %in% levels | "Solihull Local Authority" %in% levels) {
      # Calculate rates for Local Authority and ICB levels
      local_authority_data <- aggregated_data %>% filter((Indicator_Level == "Birmingham Local Authority" | Indicator_Level == "Solihull Local Authority"), IndicatorID == indicator_id)
      rates_local_authority <- calculate_rates(local_authority_data, "Local Authority")
      rates_icb <- calculate_rates(local_authority_data, "ICB")
      
      combined_rates <- append(combined_rates, list(rates_local_authority$rate_overall, rates_local_authority$rate_ethnicity, rates_local_authority$rate_IMD))
      combined_rates <- append(combined_rates, list(rates_icb$rate_overall, rates_icb$rate_ethnicity, rates_icb$rate_IMD))
      
    } else {
      warning(paste("Unknown indicator level for IndicatorID:", indicator_id))
    }
  }
  
  # Step 5: Combine all results into a single dataframe
  final_output <- bind_rows(combined_rates)
  
  # Step 6: Filter out rows where IndicatorValueType is 1-, 3-, or 5-year ethnicity crude rate AND EthnicityCode is NA
  final_output <- final_output %>%
    filter(
      !(IndicatorValueType %in% c("1-year Ethnicity Crude Rate", "3-year Ethnicity Crude Rate", "5-year Ethnicity Crude Rate") &
          is.na(EthnicityCode))
    ) %>%
    # Filter out rows where IndicatorValueType is 1-, 3-, or 5-year IMD crude rate AND IMD is NA
    filter(
      !(IndicatorValueType %in% c("1-year IMD Crude Rate", "3-year IMD Crude Rate", "5-year IMD Crude Rate") &
          is.na(IMD))
    )
  
  return(final_output)
}

#9. Process each row of parameter combinations ---------------------------------
##9.1 Process one indicator at a time ------------------------------------------
# Can use the following process_dataset directly if you already know which indicator
# you want to process, and the parameters for age group and gender group for that indicator

# Requirements:
#1. Must use cleansed data (see Step 5), containing the indicator you want to process
#2. Specify the age group parameter
#3. Specify the gender group parameter
#4. Use the 'processed_dataset' variable to write the data into database (Step 10)

# processed_dataset <- process_dataset(clean_data = clean_dt %>% filter(IndicatorID == 76),
#                                      ageGrp = "All ages",
#                                      genderGrp = "Persons")

##9.2 Process multiple indicators at the same time -----------------------------

# Read the Excel file to get the available indicators
parameter_combinations <- readxl::read_excel("data/parameter_combinations.xlsx", 
                                   sheet = "predetermined_denominators")

indicator_params <- parameter_combinations %>% 
  filter(StandardizedIndicator == 'N' & PreDeterminedDenominator == "Y") %>% # Ensure we're taking the correct indicators
  filter(IndicatorID %in% indicator_ids) # Ensure we're extracting parameters ONLY for indicators we've specified in the beginning, otherwise, error will occur.


# Define the process_parameters function

process_parameters <- function(row) {
  tryCatch(
    {
      message(paste("Processing numerator data for IndicatorID:", row$IndicatorID, "and ReferenceID:", row$ReferenceID))
      
      # Filter clean_data based on the current row's parameters
      filtered_data <- clean_dt %>%
        filter(IndicatorID == row$IndicatorID,
               ReferenceID == row$ReferenceID)
      
      # Process the filtered data
      output <- process_dataset(clean_data = filtered_data,
                                ageGrp = row$AgeCategory, 
                                genderGrp = row$GenderCategory) %>% 
        distinct()
      
      message(paste("Processing completed for IndicatorID:", row$IndicatorID, "and ReferenceID:", row$ReferenceID))
      
      return(output)
    },
    error = function(e) {
      message(
        paste0(
          "Error occurred for IndicatorID: ", row$IndicatorID,
          ", ReferenceID: ", row$ReferenceID,
          "\nDetails: ", e
        )
      )
      
      # Return an empty tibble with the expected structure
      return(tibble())
    }
  )
}

# Apply the function to each row of the indicator parameters
results <- indicator_params %>%
  rowwise() %>%
  do(process_parameters(.)) %>%
  ungroup() # Remove the rowwise grouping, so the output is a simple tibble

# Remove the 3- and 5-rolling years data from the final output
results <- results %>% 
  filter(AggYear == 1) %>% 
  select(-AggYear) # Remove AggYear column from the final output

  

#10. Write into database ----------------------------------------------------------

sql_connection <-
  dbConnect(
    odbc(),
    Driver = "SQL Server",
    Server = "MLCSU-BI-SQL",
    Database = "Working",
    Trusted_Connection = "True"
  )

# Overwrite / append the data to the existing table
# Only overwrite if you re-process ALL indicators
# Only append if you want to add new indicators to the existing table without dropping the
# rest of the already processed indicators from this table

dbWriteTable(
  sql_connection,
  Id(schema = "dbo", table = "BSOL_0033_OF_Crude_Rates_Predefined_Denominators"),
  results,
  append = TRUE
  # overwrite = TRUE
)

# End the timer
end_time <- Sys.time()

# Calculate the time difference
time_taken <- end_time - start_time

# Print the time taken
print(paste("Time taken to run the script", time_taken)) 




