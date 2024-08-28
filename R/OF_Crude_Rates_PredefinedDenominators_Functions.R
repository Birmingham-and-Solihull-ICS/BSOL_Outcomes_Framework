library(tidyverse)
library(janitor)
library(DBI)
library(odbc)
library(IMD)
library(PHEindicatormethods)
library(clipr)
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

#2. Get data from database -------------------------------------------------------

# Insert which indicator IDs to extract
indicator_ids <- c(1, 2, 3, 4, 16)

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

#4. Functions to transform  time periods -----------------------------------------
##4.1 Function to convert time period in YYYYMM format to its Fiscal Year -----------

convert_yyyymm_to_fiscal_yr <- function(yyyymm) {
  # Extract the year and month from the input
  year <- as.integer(substr(yyyymm, 1, 4))
  month <- as.integer(substr(yyyymm, 5, 6))
  
  # Determine the fiscal year
  start_year <- ifelse(month >= 4, year, year - 1)
  end_year <- start_year + 1
  
  # Format the fiscal year as YYYY/YYYY
  fiscal_year <- paste0(start_year, "/", "20", substr(end_year, 3, 4))
  return(fiscal_year)
}

# Example usage
months <- c(202204, 202205, 202206, 202208, 202301, 202303, 202304, 202407)
fiscal_years <- sapply(months, convert_yyyymm_to_fiscal_yr)
print(fiscal_years)

##4.2 Function to convert time period in MM YYYY - MM YYYY format --------------


convert_to_mm_yyyy <- function(date_range) {
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
convert_to_mm_yyyy <- Vectorize(convert_to_mm_yyyy)

# Example usage
dates <- c("August 2014-July 2015", "August 2015-July 2016", "August 2016-July 2017")
formatted_dates <- sapply(dates, convert_to_mm_yyyy)
print(formatted_dates)

##4.3 Function to convert time period in 'To MM YYYY' format to its Fiscal Year -------

convert_to_fiscal_year <- function(time_period) {
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
convert_to_fiscal_year <- Vectorize(convert_to_fiscal_year)
  
# Example usage
time_periods <- c("To December 2022", "To December 2023", "To June 2022",
                    "To June 2023", "To March 2022", "To March 2023", "To March 2024",
                    "To September 2022", "To September 2023")

fiscal_years <- sapply(time_periods, convert_to_fiscal_year)
print(fiscal_years)
  
##4.4 Function to convert time period in "YYYY-MM" or "YYYY/MM" to its Fiscal Year --------------
  
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
      mutate(FiscalYear = convert_yyyymm_to_fiscal_yr(TimePeriod))
    
    # Process the 'Other' data
    other_data <- data %>%
      filter(TimePeriodDesc == "Other") %>%
      mutate(FiscalYear = case_when(
        grepl("-", TimePeriod) ~ convert_to_mm_yyyy(TimePeriod),
        grepl("To", TimePeriod) ~ convert_to_fiscal_year(TimePeriod),
        TRUE ~ TimePeriod
      ))
    
    # Process the 'Financial Year' data
    fy_data <- data %>%
      filter(TimePeriodDesc == "Financial Year") %>%
      mutate(FiscalYear = parse_fiscal_year(TimePeriod))
    
    # Combine the processed data back together
    combined_data <- bind_rows(month_data, other_data, fy_data)
    
    return(combined_data)
  }
  

updated_dt <- process_time_periods(dt)


# Check unique fiscal year for each time period desc
updated_dt %>% 
  filter(TimePeriodDesc == "Financial Year") %>% 
  select(TimePeriod, FiscalYear) %>% 
  distinct()

updated_dt %>% 
  filter(TimePeriodDesc == "Month") %>% 
  select(TimePeriod, FiscalYear) %>% 
  distinct()

updated_dt %>% 
  filter(TimePeriodDesc == "Other") %>% 
  select(TimePeriod, FiscalYear) %>% 
  distinct()

##4.6 Function to extract start and end dates separated by "/" -----------------
# This is used to get the start date and end date from the Fiscal Year in this format:
# 01-2021/12-2022 or 08-2022/07-2023

extract_and_format_dates <- function(date_string) {
  # Split the string by "/" to get start and end parts
  date_parts <- strsplit(date_string, "/")[[1]]
  
  # Extract the start and end dates
  start_date_string <- date_parts[1]  # "MM-YYYY"
  end_date_string <- date_parts[2]    # "MM-YYYY"
  
  # Convert to Date objects (assuming the day is the first day of the month)
  start_date <- as.Date(paste0("01-", start_date_string), format = "%d-%m-%Y")
  end_date <- as.Date(paste0("31-", end_date_string), format = "%d-%m-%Y")
  
  # Format the dates to DD-MM-YYYY
  start_date_formatted <- format(start_date, "%d-%m-%Y")
  end_date_formatted <- format(end_date, "%d-%m-%Y")
  
  # Return a list with the formatted dates
  return(list(start_date = start_date_formatted, end_date = end_date_formatted))
}

# Example usage
date_string <- "08-2012/07-2013"

extract_and_format_dates(date_string)$start_date # start_date
extract_and_format_dates(date_string)$end_date # end_date

# This is used to extract start date and end date from Fiscal Year in this format
# 2023/2024 where the start is 1st April and end is 31st March

extract_start_and_end_date_from_fiscal_year <- function(fiscal_year) {
  # Split the fiscal year string by "/"
  years <- strsplit(fiscal_year, "/")[[1]]
  start_year <- years[1]  # Start year (e.g., "2023")
  end_year <- years[2]    # End year (e.g., "2024")
  
  # Create the start date string for 01-04 (April 1st)
  start_date_string <- paste0("01-04-", start_year)
  
  # Create the end date string for 31-03 (March 31st)
  end_date_string <- paste0("31-03-", end_year)
  
  # Convert to Date objects
  start_date <- as.Date(start_date_string, format = "%d-%m-%Y")
  end_date <- as.Date(end_date_string, format = "%d-%m-%Y")
  
  # Format the dates to DD-MM-YYYY
  start_date_formatted <- format(start_date, "%d-%m-%Y")
  end_date_formatted <- format(end_date, "%d-%m-%Y")
  
  # Return the formatted start and end dates
  return(list(start_date = start_date_formatted, end_date = end_date_formatted))
}

# Example usage
extract_start_and_end_date_from_fiscal_year("2023/2024")$start_date
extract_start_and_end_date_from_fiscal_year("2023/2024")$end_date


#5. Clean datasets ----------------------------------------- -------------------
## Exclude Closed practice and Not applicable in PCN column
## Add column AggYear = 1

clean_dataset <- function(data){
  
  data <- data %>% 
    filter(!PCN %in% c("Closed practice", "Not applicable")) %>% 
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
agg_dt_default <- clean_dt %>% 
  filter(nchar(FiscalYear) == 9) %>% 
  create_agg_data_default()


#6.2 Case 2: August 2017-July 2018 ---------------------------------------------
## To handle cases where time period is in this format: August 2017-July 2018

create_agg_data_for_mmyyyy_dt <- function(data, agg_years = c(1, 3, 5)) {
  aggregated_data <- list()
  
  for (year in agg_years) {
    if (year == 1) {
      # For AggYear = 1, use the original data with StartYear and EndYear from the original FiscalYear
      data_agg <- data %>%
        filter(nchar(FiscalYear) > 9) %>%
        mutate(
          StartYear = as.numeric(substr(FiscalYear, 4, 7)),
          EndYear = as.numeric(substr(FiscalYear, 12, 15)),
          FiscalYear2 = paste0(substr(FiscalYear, 1, 2),"-", StartYear, "/",
                               substr(FiscalYear, 9, 10), "-", EndYear),
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
          FiscalYear2 = paste0(substr(FiscalYear, 1, 2),"-", PeriodStart, "/",
                               substr(FiscalYear, 9, 10), "-", PeriodEnd),
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
agg_dt_mmyyyy <- clean_dt %>% 
  filter(nchar(FiscalYear) > 9) %>% 
  create_agg_data_for_mmyyyy_dt() 


## Case 3: YYYY format ---------------------------------------------------------
## Handle cases where Fiscal Year is calendar year format

create_agg_data_for_yyyy <- function(data, agg_years = c(1, 3, 5)) {
  aggregated_data <- list()
  
  for (year in agg_years) {
    if (year == 1) {
      # For AggYear = 1, use the original data with StartYear and EndYear from the original FiscalYear
      data_agg <- data %>%
        filter(nchar(FiscalYear) == 4) %>%
        mutate(
          StartYear = paste0("01-", FiscalYear),
          EndYear = paste0("12-", FiscalYear),
          FiscalYear2 = paste0(StartYear, "/", EndYear), 
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
          StartYear = paste0("01-", FiscalYear),
          EndYear = paste0("01-", FiscalYear),
          Group = ceiling(Order / year) # Group the data for rolling periods (3 or 5 years)
        ) %>%
        group_by(Group) %>%
        mutate(
          PeriodEnd = max(as.numeric(FiscalYear)), # Assign the same PeriodEnd for the entire group
          PeriodStart = PeriodEnd - (year -1), # Calculate PeriodStart for rolling years
          FiscalYear2 = paste0("01-", PeriodStart, "/",  "12-", PeriodEnd), # Correctly calculate the FiscalYear2 for the group
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
agg_dt_yyyy <- clean_dt %>% 
  filter(nchar(TimePeriod) == 4) %>% 
  create_agg_data_for_yyyy() 

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
        create_agg_data_for_yyyy()
    } else if (length == 9) {
      agg_dt <- data %>%
        filter(nchar(FiscalYear) == 9) %>%
        create_agg_data_default()
    } else if (length > 9) {
      agg_dt <- data %>%
        filter(nchar(FiscalYear) > 9) %>%
        create_agg_data_for_mmyyyy_dt()
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
# Columns to group data by for calculating Only overall crude rates and rates by ethnicity

get_grouping_columns <- function(rate_type, rate_level) {
  base_group_vars <- c("IndicatorID", "ReferenceID", "FiscalYear")
  
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
get_grouping_columns(rate_type = "overall", rate_level = "Locality")

# 8. Function to calculate crude rate ------------------------------------------

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
          Numerator = abs(Numerator) # Get the absolute number to handle negative numerators
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
          Numerator = Numerator * OriginalSign, # Reapply the original sign to the numerator
          IndicatorValue = IndicatorValue * OriginalSign  # Reapply the original sign to the calculated rate
        ) %>% 
        # Use if...else statements to handle different rate levels
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
          EthnicityCode = if (rate_type == "ethnicity") ONSGroup else NA_character_,  # Directly assign ONSGroup
          IndicatorStartDate = case_when(
            nchar(FiscalYear) == 15 ~ extract_and_format_dates(FiscalYear)$start_date,
            nchar(FiscalYear) == 9 ~ extract_start_and_end_date_from_fiscal_year(FiscalYear)$start_date,
            TRUE ~ NA
          ),
          IndicatorEndDate = case_when(
            nchar(FiscalYear) == 15 ~ extract_and_format_dates(FiscalYear)$end_date,
            nchar(FiscalYear) == 9 ~ extract_start_and_end_date_from_fiscal_year(FiscalYear)$end_date,
            TRUE ~ NA
          ),
          IndicatorValueType = case_when(
            rate_type == "ethnicity" ~ paste0(year, "-year Ethnicity Crude Rate"),
            rate_type == "overall" ~ paste0(year, "-year Overall Crude Rate")
          )) %>%
        select(IndicatorID, InsertDate, Numerator, Denominator, IndicatorValue, IndicatorValueType,
               LowerCI95, UpperCI95, AggregationType, AggregationLabel, FiscalYear, Gender, AgeGroup, IMD, EthnicityCode,
               StatusID, DataQualityID, IndicatorStartDate, IndicatorEndDate)
      
      # Store result in list
      all_results[[paste0(year, "YR_data")]] <- result
    }
    
    # Combine results for all years
    output <- bind_rows(all_results)
    
    return(output)
  }

# This is to calculate rates for indicators depending on the indicator level
process_dataset <- function(clean_data, ageGrp, genderGrp) {
  
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
      multiplier = 100000
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
      multiplier = 100000
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
process_dataset(clean_data = clean_dt %>% 
                                  filter(IndicatorID == 1), # Ensure you've extracted this indicator data from the database first
                                ageGrp = "35+ yrs", 
                                genderGrp = "Persons") 



#9. Process each row of parameter combinations ---------------------------------

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
