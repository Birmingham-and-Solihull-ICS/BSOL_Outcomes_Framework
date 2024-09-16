
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

#2. Get data from database -------------------------------------------------------

# Insert which indicator IDs to extract
indicator_ids <- c(1, 2, 3, 4, 16, 20, 25, 35, 36, 37, 38, 42, 46,
                   58, 68, 70, 74, 76, 77, 78, 85, 86, 93, 105, 107, 110, 112, 116, 120, 121, 122, 123, 125, 127)

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


#4. Functions to transform  time periods ---------------------------------------
##4.1 Function to convert time period in YYYYMM format to its Fiscal Year ------
## E.g., 202204 to 2022/2023

convert_yearmonth_period<- function(yyyymm) {
  # Extract the year and month from the input
  year <- as.integer(substr(yyyymm, 1, 4))
  month <- as.integer(substr(yyyymm, 5, 6))
  
  # Determine the fiscal year
  start_year <- ifelse(month >= 4, year, year - 1)
  end_year <- start_year + 1
  
  # Format the fiscal year as YYYY/YYYY
  fiscal_year <- paste0(start_year, "/", end_year)
  return(fiscal_year)
}

# Vectorize the function for use with dplyr
convert_yearmonth_period <- Vectorize(convert_yearmonth_period)

# Example usage
months <- c(202203, 202204, 202205, 202206, 202301, 202303, 202304, 202407)
fiscal_years <- sapply(months, convert_yearmonth_period)
print(fiscal_years) # Output: "2021/2022" "2022/2023" "2022/2023" 
                    #         "2022/2023" "2022/2023" "2022/2023" "2023/2024" "2024/2025"

##4.2 Function to convert time period in MM YYYY - MM YYYY format --------------
##E.g., August 2014-July 2015 to 08/2014-07/2015

convert_fixed_period <- function(date_range) {
  # Create a named vector for month conversion
  month_conversion <- c(
    "January" = "01", "February" = "02", "March" = "03", 
    "April" = "04", "May" = "05", "June" = "06", 
    "July" = "07", "August" = "08", "September" = "09", 
    "October" = "10", "November" = "11", "December" = "12"
  )
  
  # Split the input string into start and end dates
  dates <- strsplit(date_range, "-")[[1]]
  
  # Extract the start and end components
  start_date <- strsplit(trimws(dates[1]), " ")[[1]]
  end_date <- strsplit(trimws(dates[2]), " ")[[1]]
  
  # Convert the month name to MM format
  start_month <- month_conversion[start_date[1]]
  end_month <- month_conversion[end_date[1]]
  
  # Extract the year part
  start_year <- start_date[2]
  end_year <- end_date[2]
  
  # Format the result as "MM/YYYY-MM/YYYY"
  formatted_date <- paste0(start_month, "/", start_year, "-", end_month, "/", end_year)
  
  return(formatted_date)
}

# Vectorize the function for use with dplyr
convert_fixed_period <- Vectorize(convert_fixed_period)

# Example usage
dates <- c("April 2022-June 2023",  "August 2013-July 2014", "August 2014-July 2015", "August 2015-July 2016")
formatted_dates <- sapply(dates, convert_fixed_period)
print(formatted_dates) 

##4.3 Function to convert time period in 'To MM YYYY' format to its Fiscal Year -------
##E.g., To December 2022 to 2022/2023

convert_quarterly_period <- function(time_period) {
    # Extract the month and year from the input
    parts <- strsplit(time_period, " ")[[1]]
    month <- parts[2]
    year <- as.numeric(parts[3])
    
    # Determine the fiscal year based on the month
    fiscal_year_start <- ifelse(month %in% c("January", "February", "March"), year - 1, year)
    fiscal_year_end <- fiscal_year_start + 1
    
    # Format the fiscal year as "YYYY/YYYY"
    fiscal_year_label <- paste0(fiscal_year_start, "/", fiscal_year_end)
    
    return(fiscal_year_label)
  }
  
# Vectorize the function for use with dplyr
convert_quarterly_period <- Vectorize(convert_quarterly_period)
  
# Example usage
time_periods <- c("To December 2022", "To December 2023", "To June 2022",
                    "To June 2023", "To March 2022", "To March 2023", "To March 2024",
                    "To September 2022", "To September 2023")

fiscal_years <- sapply(time_periods, convert_quarterly_period)
print(fiscal_years) # Output: "2022/2023", "2023/2024", "2022/2023", "2023/2024", "2021/2022", "2022/2023", "2023/2024", "2022/2023", "2023/2024"
  
##4.4 Function to convert time period in "YYYY-MM" or "YYYY/MM" to its Fiscal Year --------------
## E.g., 2022-23 to 2022/2023 or 2022/23 to 2022/2023

parse_fiscal_year <- function(time_period) {
  # Split the string on either "-" or "/"
  years <- unlist(strsplit(time_period, "[-/]"))
  
  # Ensure we have exactly two parts and that both parts are valid
  if (length(years) == 2 && nchar(years[2]) == 2) {
    start_year <- years[1]
    end_year <- paste0("20", years[2])
    
    # Return the fiscal year in "YYYY/YYYY" format
    return(paste0(start_year, "/", end_year))
  } else {
    # In case of an unexpected format, return the input unchanged
    return(time_period)
  }
}

# Ensure the function is vectorized for use with dplyr
parse_fiscal_year <- Vectorize(parse_fiscal_year)

# Example usage
parse_fiscal_year("2020-21") # Output: "2020/2021"
parse_fiscal_year("2024/25") # Output: "2024/2025"

##4.5 Process time periods altogether in the dataset -------------------------------

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
  filter(TimePeriodDesc == "Financial Year") %>% 
  group_by(IndicatorID, TimePeriod, FiscalYear) %>% 
  select(IndicatorID, TimePeriod, FiscalYear) %>% 
  distinct() %>% 
  View()

updated_dt %>% 
  filter(TimePeriodDesc == "Month") %>% 
  select(TimePeriod, FiscalYear) %>% 
  distinct() %>% 
  View()

updated_dt %>% 
  filter(TimePeriodDesc == "Other") %>% 
  select(TimePeriod, FiscalYear) %>% 
  distinct() %>% 
  View()

##4.6 Function to extract start and end dates separated by "/" -----------------
# This is used to get the start date and end date from the Fiscal Year in this format:
# E.g., 08/2023-07/2024


# Custom functions for start and end dates with validation
get_start_date_from_fixed_period <- function(date_string) {
  # Remove any spaces and ensure format is consistent
  date_string <- gsub("\\s+", "", date_string)
  
  # Split the string by "-"
  date_parts <- strsplit(date_string, "-")[[1]]
  
  # Ensure date_parts has two components (MM/YYYY)
  if (length(date_parts) != 2) {
    return(NA_character_)
  }
  
  start_date_string <- date_parts[1]  # Extract the start part ("MM/YYYY")
  
  # Convert to a Date object, assuming the first day of the month
  start_date <- suppressWarnings(dmy(paste0("01-", start_date_string)))  # Suppress warnings for failed parsing
  
  return(ifelse(!is.na(start_date), format(start_date, "%d-%m-%Y"), NA_character_))
}

get_end_date_from_fixed_period <- function(date_string) {
  # Remove any spaces and ensure format is consistent
  date_string <- gsub("\\s+", "", date_string)
  
  # Split the string by "-"
  date_parts <- strsplit(date_string, "-")[[1]]
  
  # Ensure date_parts has two components (MM/YYYY)
  if (length(date_parts) != 2) {
    return(NA_character_)
  }
  
  end_date_string <- date_parts[2]  # Extract the end part ("MM/YYYY")
  
  # Convert to a Date object, assuming the last day of the month
  end_date <- suppressWarnings(ceiling_date(dmy(paste0("01-", end_date_string)), "month") - days(1))
  
  return(ifelse(!is.na(end_date), format(end_date, "%d-%m-%Y"), NA_character_))
}

# Vectorize the custom functions
get_start_date_from_fixed_period <- Vectorize(get_start_date_from_fixed_period)
get_end_date_from_fixed_period <- Vectorize(get_end_date_from_fixed_period)


# Function for fiscal years (YYYY/YYYY)
get_start_date_from_fiscal_year <- function(fiscal_year) {
  # Split the fiscal year string by "/"
  years <- strsplit(fiscal_year, "/")[[1]]
  start_year <- years[1]  # Start year (e.g., "2023")
  
  # Create the start date string for 01-04 (April 1st)
  start_date_string <- paste0("01-04-", start_year)
  
  # Convert to Date object
  start_date <- as.Date(start_date_string, format = "%d-%m-%Y")
  
  return(ifelse(!is.na(start_date), format(start_date, "%d-%m-%Y"), NA_character_))
}

get_end_date_from_fiscal_year <- function(fiscal_year) {
  # Split the fiscal year string by "/"
  years <- strsplit(fiscal_year, "/")[[1]]
  end_year <- years[2]  # End year (e.g., "2024")
  
  # Create the end date string for 31-03 (March 31st)
  end_date_string <- paste0("31-03-", end_year)
  
  # Convert to Date object
  end_date <- as.Date(end_date_string, format = "%d-%m-%Y")
  
  return(ifelse(!is.na(end_date), format(end_date, "%d-%m-%Y"), NA_character_))
}

# Vectorize the custom functions
get_start_date_from_fiscal_year <- Vectorize(get_start_date_from_fiscal_year)
get_end_date_from_fiscal_year<- Vectorize(get_end_date_from_fiscal_year)


# Apply the functions row-wise using mutate
# updated_dt_v2 <- updated_dt %>%
#   mutate(
#     IndicatorStartDate = case_when(
#       nchar(FiscalYear) == 15 ~ get_start_date_from_fixed_period(FiscalYear),  # Fixed period (MM/YYYY-MM/YYYY)
#       nchar(FiscalYear) == 9 ~ get_start_date_from_fiscal_year(FiscalYear),      # Fiscal year (YYYY/YYYY)
#       TRUE ~ NA_character_  # Return NA for invalid formats
#     ),
#     IndicatorEndDate = case_when(
#       nchar(FiscalYear) == 15 ~ get_end_date_from_fixed_period(FiscalYear),    # Fixed period (MM/YYYY-MM/YYYY)
#       nchar(FiscalYear) == 9 ~ get_end_date_from_fiscal_year(FiscalYear),        # Fiscal year (YYYY/YYYY)
#       TRUE ~ NA_character_  # Return NA for invalid formats
#     )
#   ) %>%
#   select(FiscalYear, IndicatorStartDate, IndicatorEndDate) %>%
#   distinct()


#5. Clean datasets ----------------------------------------- -------------------
## Exclude Closed practice and Not applicable in PCN column
## Add column AggYear = 1

clean_dataset <- function(data){
  
  data <- data %>% 
    filter(!(PCN %in% c("Closed practice", "Not applicable"))) %>% 
    filter(!(GP_Practice %in% c('M88006'))) %>% 
    mutate(AggYear = 1) %>% 
    mutate(Locality_Reg = case_when(
      Indicator_Level == 'Birmingham Local Authority' ~ "Birmingham", 
      Indicator_Level == 'Solihull Local Authority' ~ "Solihull",
      TRUE ~ Locality_Reg
    ))
    
  
  return(data)
}

clean_dt <- updated_dt %>% 
  clean_dataset()

#6. Function to create aggregated data for 3, 5 rolling years ------------------
#6.1 Default -------------------------------------------------------------------
## for cases where time period already in correct fiscal year format

create_agg_data_default <- function(data, agg_years = c(1, 3, 5)) {
  aggregated_data <- list()
  
  for (year in agg_years) {
    if (year == 1) {
      # For AggYear = 1, use the original data
      data_agg <- data %>%
        filter(nchar(FiscalYear) == 9) %>%
        mutate(
          AggYear = 1
        ) %>%
        group_by(
          IndicatorID,
          ReferenceID,
          GP_Practice,
          PCN,
          Locality_Reg,
          LSOA_2011,
          LSOA_2021,
          Ethnicity_Code,
          Indicator_Level,
          FiscalYear,
          AggYear
        ) %>%
        summarise(
          Numerator = sum(Numerator, na.rm = TRUE),
          Denominator = sum(Denominator, na.rm = TRUE),
          .groups = 'drop'
        )
    } else {
      # For rolling AggYear = 3 or 5
      data_agg <- data %>%
        filter(nchar(FiscalYear) == 9) %>%
        mutate(
          FiscalYearStart = as.numeric(substr(FiscalYear, 1, 4)),
          PeriodStart = FiscalYearStart - (FiscalYearStart %% year),
          AggYear = year
        ) %>%
        group_by(
          IndicatorID,
          ReferenceID,
          GP_Practice,
          PCN,
          Locality_Reg,
          LSOA_2011,
          LSOA_2021,
          Ethnicity_Code,
          Indicator_Level,
          FiscalYear = paste0(PeriodStart, "/", PeriodStart + year - 1),
          AggYear
        ) %>%
        summarise(
          Numerator = sum(Numerator, na.rm = TRUE),
          Denominator = sum(Denominator, na.rm = TRUE) / n_distinct(FiscalYearStart),
          .groups = 'drop'
        )
    }
    
    aggregated_data[[paste0(year, "YR_data")]] <- data_agg
  }
  
  # Combine the original data with the 3- and 5-year aggregated data
  output <- bind_rows(aggregated_data)
  
  return(output)
}

# Example usage
# agg_dt_default <- clean_dt %>% 
#   filter(nchar(FiscalYear) == 9) %>% 
#   create_agg_data_default()


#6.2 Case 2: August 2017-July 2018 ---------------------------------------------
## To handle cases where time period is in this format: August 2017-July 2018

create_agg_data_for_fixed_period <- function(data, agg_years = c(1, 3, 5)) {
  aggregated_data <- list()
  
  for (year in agg_years) {
    if (year == 1) {
      # For AggYear = 1, use the original data with StartYear and EndYear from the original FiscalYear
      data_agg <- data %>%
        filter(nchar(FiscalYear) > 9) %>%
        mutate(
          StartYear = as.numeric(substr(FiscalYear, 4, 7)),
          EndYear = as.numeric(substr(FiscalYear, 12, 15)),
          FiscalYear2 = paste0(substr(FiscalYear, 1, 2),"/", StartYear, "-",
                               substr(FiscalYear, 9, 10), "/", EndYear),
          # FiscalYear2 = paste0("08-", StartYear, "/", "07-", EndYear),
          AggYear = 1
        ) %>%
        group_by(
          IndicatorID,
          ReferenceID, 
          GP_Practice, 
          PCN, 
          Locality_Reg, 
          LSOA_2011, 
          LSOA_2021, 
          Ethnicity_Code,
          Indicator_Level,
          FiscalYear = FiscalYear2, # Use FiscalYear2 calculated from original StartYear and EndYear
          AggYear
        ) %>%
        summarise(
          Numerator = sum(Numerator, na.rm = TRUE),
          Denominator = sum(Denominator, na.rm = TRUE),
          .groups = 'drop'
        )
    } else {
      # For rolling AggYear = 3 or 5
      data_agg <- data %>%
        filter(nchar(FiscalYear) > 9) %>%
        arrange(desc(FiscalYear)) %>% # Order data in descending order of FiscalYear
        mutate(
          Order = row_number(), # Re-create the Order column based on the new order
          StartYear = as.numeric(substr(FiscalYear, 4, 7)),
          EndYear = as.numeric(substr(FiscalYear, 12, 15)),
          Group = ceiling(Order / year) # Group the data for rolling periods (3 or 5 years)
        ) %>%
        group_by(Group) %>%
        mutate(
          PeriodEnd = max(EndYear), # Assign the same PeriodEnd for the entire group
          PeriodStart = PeriodEnd - year, # Calculate PeriodStart for rolling years
          FiscalYear2 = paste0(substr(FiscalYear, 1, 2),"/", PeriodStart, "-",
                               substr(FiscalYear, 9, 10), "/", PeriodEnd),
          # FiscalYear2 = paste0("08-", PeriodStart, "/",  "07-", PeriodEnd), # Correctly calculate the FiscalYear2 for the group
          AggYear = year
        ) %>%
        ungroup() %>%
        select(-Group) %>%
        group_by(
          IndicatorID,
          ReferenceID, 
          GP_Practice, 
          PCN, 
          Locality_Reg, 
          LSOA_2011, 
          LSOA_2021, 
          Ethnicity_Code,
          Indicator_Level,
          FiscalYear = FiscalYear2, # Use the newly calculated FiscalYear2
          AggYear
        ) %>%
        summarise(
          Numerator = sum(Numerator, na.rm = TRUE),
          Denominator = mean(Denominator, na.rm = TRUE),
          .groups = 'drop'
        )
    }
    
    aggregated_data[[paste0(year, "YR_data")]] <- data_agg
  }
  
  # Combine the original data with the 3- and 5-year aggregated data
  output <- bind_rows(aggregated_data)
  
  return(output)
}


# Example usage
# Will return 0 obs if the original data doesn't have fixed time period
# agg_dt_fixed_period <- clean_dt %>% 
#   filter(nchar(FiscalYear) > 9) %>% 
#   create_agg_data_for_fixed_period() 


## Case 3: YYYY format ---------------------------------------------------------
## Handle cases where Fiscal Year is calendar year format

create_agg_data_for_calendar_yr<- function(data, agg_years = c(1, 3, 5)) {
  aggregated_data <- list()
  
  for (year in agg_years) {
    if (year == 1) {
      # For AggYear = 1, use the original data with StartYear and EndYear from the original FiscalYear
      data_agg <- data %>%
        filter(nchar(FiscalYear) == 4) %>%
        mutate(
          StartYear = paste0("01/", FiscalYear),
          EndYear = paste0("12/", FiscalYear),
          FiscalYear2 = paste0(StartYear, "-", EndYear), 
          AggYear = 1
        ) %>%
        group_by(
          IndicatorID,
          ReferenceID, 
          GP_Practice, 
          PCN, 
          Locality_Reg, 
          LSOA_2011, 
          LSOA_2021, 
          Ethnicity_Code,
          Indicator_Level,
          FiscalYear = FiscalYear2, # Use FiscalYear2 calculated from original StartYear and EndYear
          AggYear
        ) %>%
        summarise(
          Numerator = sum(Numerator, na.rm = TRUE),
          Denominator = sum(Denominator, na.rm = TRUE),
          .groups = 'drop'
        )
    } else {
      # For rolling AggYear = 3 or 5
      data_agg <- data %>%
        filter(nchar(FiscalYear) == 4) %>%
        arrange(desc(FiscalYear)) %>% # Order data in descending order of FiscalYear
        mutate(
          Order = row_number(), # Re-create the Order column based on the new order
          StartYear = paste0("01/", FiscalYear),
          EndYear = paste0("01/", FiscalYear),
          Group = ceiling(Order / year) # Group the data for rolling periods (3 or 5 years)
        ) %>%
        group_by(Group) %>%
        mutate(
          PeriodEnd = max(as.numeric(FiscalYear)), # Assign the same PeriodEnd for the entire group
          PeriodStart = PeriodEnd - (year -1), # Calculate PeriodStart for rolling years
          FiscalYear2 = paste0("01/", PeriodStart, "-",  "12/", PeriodEnd), # Correctly calculate the FiscalYear2 for the group
          AggYear = year
        ) %>%
        ungroup() %>%
        select(-Group) %>%
        group_by(
          IndicatorID,
          ReferenceID, 
          GP_Practice, 
          PCN, 
          Locality_Reg, 
          LSOA_2011, 
          LSOA_2021, 
          Ethnicity_Code,
          Indicator_Level,
          FiscalYear = FiscalYear2, # Use the newly calculated FiscalYear2
          AggYear
        ) %>%
        summarise(
          Numerator = sum(Numerator, na.rm = TRUE),
          Denominator = mean(Denominator, na.rm = TRUE),
          .groups = 'drop'
        )
    }
    
    aggregated_data[[paste0(year, "YR_data")]] <- data_agg
  }
  
  # Combine the original data with the 3- and 5-year aggregated data
  output <- bind_rows(aggregated_data)
  
  return(output)
}

# Example Usage
# Will return 0 obs if the original data doesn't have calendar year
# agg_dt_calendar_yr<- clean_dt %>% 
#   filter(nchar(TimePeriod) == 4) %>% 
#   create_agg_data_for_calendar_yr() 

# 6.3 Combine aggregate functions ----------------------------------------------

create_aggregate_data <- function(data) {
  # Determine the unique lengths of FiscalYear in the dataset
  fiscal_year_lengths <- unique(nchar(data$FiscalYear))
  
  # Initialize an empty list to store the aggregated data
  aggregated_data <- list()
  
  # Loop over each unique fiscal year length and apply the appropriate function
  for (length in fiscal_year_lengths) {
    if (length == 4) { 
      agg_dt <- data %>%
        filter(nchar(FiscalYear) == 4) %>%
        create_agg_data_for_calendar_yr()
    } else if (length == 9) { 
      agg_dt <- data %>%
        filter(nchar(FiscalYear) == 9) %>%
        create_agg_data_default()
    } else if (length > 9){
      agg_dt <- data %>%
        filter(nchar(FiscalYear) > 9) %>%
        create_agg_data_for_fixed_period()
    } else {
      stop("Invalid FiscalYear format detected.")
    }
    
    # Append the result to the list
    aggregated_data[[paste0("Length_", length)]] <- agg_dt
  }
  
  # Combine all the aggregated data into a single data frame
  output <- bind_rows(aggregated_data)
  
  return(output)
}


#7. Function to create grouping columns ----------------------------------------
# Columns to group the data by, for calculating Only overall crude rates and rates by ethnicity

get_grouping_columns <- function(rate_type, rate_level) {
  base_group_vars <- c("IndicatorID", "ReferenceID", "FiscalYear", "AggYear")
  
  # Add additional grouping columns based on rate_level
  if (rate_level == "PCN") {
    additional_group_var <- "PCN"
  } else if (rate_level == "Local Authority" | rate_level == "Locality") {
    additional_group_var <- "Locality_Reg"
  } else {
    additional_group_var <- NULL # For calculating rates at ICB level, no additional column
  }
  
  # Add the rate_type specific grouping columns
  group_vars <- switch(rate_type,
                       "overall" = base_group_vars,
                       "ethnicity" = c(base_group_vars, "ONSGroup"),
                       stop("Invalid rate type specified.")
  )
  
  # Append the additional grouping column if any
  if (!is.null(additional_group_var)) {
    group_vars <- c(group_vars, additional_group_var)
  }
  
  return(group_vars)
}

# Example usage
get_grouping_columns(rate_type = "overall", rate_level = "Locality") # Output: "IndicatorID"  "ReferenceID"  "FiscalYear"  "AggYear" "Locality_Reg"

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
        IndicatorValue = IndicatorValue * OriginalSign  # Reapply the original sign to the calculated rate
      ) %>%
      # Use if_else to handle different rate levels and conditions
      mutate(
        InsertDate = today(),
        AggYear = year,
        DataQualityID = 1,
        StatusID = 1,
        AggregationLabel = if (rate_level == "PCN") {
          PCN
        } else if (rate_level == "Local Authority" || rate_level == "Locality") {
          Locality_Reg
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
        IMD = NA_character_,
        EthnicityCode = if (rate_type == "ethnicity") ONSGroup else NA_character_) %>%   # Directly assign ONSGroup
      ungroup() %>% 
      mutate(
        IndicatorStartDate = case_when(
          nchar(FiscalYear) == 15 ~ get_start_date_from_fixed_period(FiscalYear),
          nchar(FiscalYear) == 9 ~ get_start_date_from_fiscal_year(FiscalYear),
          TRUE ~ NA_character_
        ),
        IndicatorEndDate = case_when(
          nchar(FiscalYear) == 15 ~ get_end_date_from_fixed_period(FiscalYear),
          nchar(FiscalYear) == 9 ~ get_end_date_from_fiscal_year(FiscalYear),
          TRUE ~ NA_character_
        ),
        IndicatorValueType = case_when(
          rate_type == "ethnicity" ~ paste0(year, "-year Ethnicity Crude Rate"),
          rate_type == "overall" ~ paste0(year, "-year Overall Crude Rate")
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

#8.2 Final function to calculate crude rate depending on the rate level ---------
process_dataset <- function(clean_data, ageGrp, genderGrp, multiplier = 100000) {
  
  # Step 1: Aggregate the data
  aggregated_data <- create_aggregate_data(clean_data)
  
  # Step 2: Define a helper function to calculate rates
  calculate_rates <- function(indicator_level, rate_level) {
    # Overall rate
    rate_overall <- calculate_crude_rate(
      data = aggregated_data,
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
      data = aggregated_data,
      group_vars = get_grouping_columns(rate_type = "ethnicity", rate_level = rate_level), 
      aggYear = c(1, 3, 5), 
      rate_level = rate_level, 
      rate_type = "ethnicity", 
      ageGrp = ageGrp, 
      genderGrp = genderGrp,
      multiplier = multiplier
    )
    
    return(list(rate_overall = rate_overall, rate_ethnicity = rate_ethnicity))
  }
  
  # Step 3: Loop through unique Indicator Levels and calculate rates accordingly
  unique_indicator_levels <- unique(aggregated_data$Indicator_Level)
  
  # Initialize a list to store all dataframes
  combined_rates <- list()
  
  for (indicator_level in unique_indicator_levels) {
    if (indicator_level == 'Practice Level') {
      # Calculate rates for PCN, Locality (Registered), and ICB levels
      rates_pcn <- calculate_rates(indicator_level, "PCN")
      rates_locality <- calculate_rates(indicator_level, "Locality")
      rates_icb <- calculate_rates(indicator_level, "ICB")
      
      # Combine the results and store them in the combined_rates list
      combined_rates <- append(combined_rates, list(rates_pcn$rate_overall, rates_pcn$rate_ethnicity))
      combined_rates <- append(combined_rates, list(rates_locality$rate_overall, rates_locality$rate_ethnicity))
      combined_rates <- append(combined_rates, list(rates_icb$rate_overall, rates_icb$rate_ethnicity))
      
    } else if (indicator_level %in% c("Birmingham Local Authority", "Solihull Local Authority")) {
      # Calculate rates for Local Authority and ICB levels
      rates_locality <- calculate_rates(indicator_level, "Local Authority")
      rates_icb <- calculate_rates(indicator_level, "ICB")
      
      # Combine the results and store them in the combined_rates list
      combined_rates <- append(combined_rates, list(rates_locality$rate_overall, rates_locality$rate_ethnicity))
      combined_rates <- append(combined_rates, list(rates_icb$rate_overall, rates_icb$rate_ethnicity))
      
    } else if (indicator_level == "ICB Level") {
      # Calculate rates only for ICB level
      rates_icb <- calculate_rates(indicator_level, "ICB")
      
      # Combine the results and store them in the combined_rates list
      combined_rates <- append(combined_rates, list(rates_icb$rate_overall, rates_icb$rate_ethnicity))
    }
  }
  
  # Combine all the dataframes in combined_rates into one final dataframe
  final_output <- bind_rows(combined_rates)
  
  # Step 4: Filter out rows where IndicatorValueType is 1-, 3-, or 5-year ethnicity crude rate AND EthnicityCode is NA
  final_output <- final_output %>%
    filter(
      !(IndicatorValueType %in% c("1-year Ethnicity Crude Rate", "3-year Ethnicity Crude Rate", "5-year Ethnicity Crude Rate") &
          is.na(EthnicityCode))
    )
  
  return(final_output)
}

# Example usage
# Ensure you've extracted this indicator data from the database first
# processed_dt <- process_dataset(clean_data = clean_dt %>%
#                                   filter(IndicatorID == 103),
#                                 ageGrp = "35+ yrs",
#                                 genderGrp = "Persons")



#9. Process each row of parameter combinations ---------------------------------
##9.1 Process one indicator at a time ------------------------------------------
# Can use the following process_dataset directly if you already know which indicator
# you want to process, and the parameters for age group and gender group for that indicator

# Requirements:
#1. Must use cleansed data (see Step 5), containing the indicator you want to process
#2. Specify the age group parameter
#3. Specify the gender group parameter
#4. Use the 'processed_dataset' variable to write the data into database (Step 10)

# processed_dataset <- process_dataset(clean_data = clean_dt %>% filter(IndicatorID == 90),
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
  filter(AggYear == 1)


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
  Id(schema = "dbo", table = "BSOL_0033_OF_Crude_Rates_Predefined_Denominators_v2"),
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
