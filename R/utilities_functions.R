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
  start_date <- suppressWarnings(dmy(paste0("01/", start_date_string)))  # Suppress warnings for failed parsing
  
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
  end_date <- suppressWarnings(ceiling_date(dmy(paste0("01/", end_date_string)), "month") - days(1))
  
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

# Function for calendar years (YYYY)
get_start_date_from_calendar_year <- function(calendar_year) {
  
  # Construct start date
  start_date <- as.Date(paste0("01-01-", calendar_year), format = "%d-%m-%Y")
  
  # Return formatted string in DD-MM-YYYY format
  return(ifelse(!is.na(start_date), format(start_date, "%d-%m-%Y"), NA_character_))
}

get_end_date_from_calendar_year <- function(calendar_year) {
  
  # Construct end date
  end_date <- as.Date(paste0("31-12-", calendar_year), format = "%d-%m-%Y")
  
  # Return formatted string in DD-MM-YYYY format
  return(ifelse(!is.na(end_date), format(end_date, "%d-%m-%Y"), NA_character_))
}

# Vectorize the custom functions
get_start_date_from_calendar_year <- Vectorize(get_start_date_from_calendar_year)
get_end_date_from_calendar_year<- Vectorize(get_end_date_from_calendar_year)

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
          Local_Authority, # Adds Local_Authority column
          LSOA_2011,
          LSOA_2021,
          Ethnicity_Code,
          IMD_Quintile,
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
          Local_Authority, # Adds Local_Authority column
          LSOA_2011,
          LSOA_2021,
          Ethnicity_Code,
          IMD_Quintile,
          Indicator_Level,
          FiscalYear = paste0(PeriodStart, "/", PeriodStart + year - 1),
          AggYear
        ) %>%
        summarise(
          Numerator = sum(Numerator, na.rm = TRUE),
          Denominator = sum(Denominator, na.rm = TRUE), # Taking sum 
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
          Local_Authority, # Adds Local_Authority column
          LSOA_2011, 
          LSOA_2021, 
          Ethnicity_Code,
          IMD_Quintile,
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
          Local_Authority, # Adds Local_Authority column
          LSOA_2011, 
          LSOA_2021, 
          Ethnicity_Code,
          IMD_Quintile,
          Indicator_Level,
          FiscalYear = FiscalYear2, # Use the newly calculated FiscalYear2
          AggYear
        ) %>%
        summarise(
          Numerator = sum(Numerator, na.rm = TRUE),
          Denominator = sum(Denominator, na.rm = TRUE), # Taking sum of denominator
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
          Local_Authority, # Adds Local_Authority column
          LSOA_2011, 
          LSOA_2021, 
          Ethnicity_Code,
          IMD_Quintile,
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
          Local_Authority, # Adds Local_Authority column
          LSOA_2011, 
          LSOA_2021, 
          Ethnicity_Code,
          IMD_Quintile,
          Indicator_Level,
          FiscalYear = FiscalYear2, # Use the newly calculated FiscalYear2
          AggYear
        ) %>%
        summarise(
          Numerator = sum(Numerator, na.rm = TRUE),
          Denominator = sum(Denominator, na.rm = TRUE), # Taking sum of denominator
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

# 6.4 Calculate directly standardised rates ------------------------------------

calculate_dsr2 <-
  function (data, x, n, stdpop = NULL, type = "full", confidence = 0.95, 
            multiplier = 1e+05, independent_events = TRUE, eventfreq = NULL, 
            ageband = NULL) {
    if (missing(data) | missing(x) | missing(n) | missing(stdpop)) {
      stop("function calculate_dsr requires at least 4 arguments: data, x, n, stdpop")
    }
    if (!is.data.frame(data)) {
      stop("data must be a data frame object")
    }
    if (!deparse(substitute(x)) %in% colnames(data)) {
      stop("x is not a field name from data")
    }
    if (!deparse(substitute(n)) %in% colnames(data)) {
      stop("n is not a field name from data")
    }
    if (!deparse(substitute(stdpop)) %in% colnames(data)) {
      stop("stdpop is not a field name from data")
    }
    data <- data %>% rename(x = {
      {
        x
      }
    }, n = {
      {
        n
      }
    }, stdpop = {
      {
        stdpop
      }
    })
    if (!is.numeric(data$x)) {
      stop("field x must be numeric")
    }
    else if (!is.numeric(data$n)) {
      stop("field n must be numeric")
    }
    else if (!is.numeric(data$stdpop)) {
      stop("field stdpop must be numeric")
    }
    else if (anyNA(data$n)) {
      stop("field n cannot have missing values")
    }
    else if (anyNA(data$stdpop)) {
      stop("field stdpop cannot have missing values")
    }
    else if (any(pull(data, x) < 0, na.rm = TRUE)) {
      stop("numerators must all be greater than or equal to zero")
    }
    else if (any(pull(data, n) <= 0)) {
      stop("denominators must all be greater than zero")
    }
    else if (any(pull(data, stdpop) < 0)) {
      stop("stdpop must all be greater than or equal to zero")
    }
    else if (!(type %in% c("value", "lower", "upper", 
                           "standard", "full"))) {
      stop("type must be one of value, lower, upper, standard or full")
    }
    else if (!is.numeric(confidence)) {
      stop("confidence must be numeric")
    }
    else if (length(confidence) > 2) {
      stop("a maximum of two confidence levels can be provided")
    }
    else if (length(confidence) == 2) {
      if (!(confidence[1] == 0.95 & confidence[2] == 0.998)) {
        stop("two confidence levels can only be produced if they are specified as 0.95 and 0.998")
      }
    }
    else if ((confidence < 0.9) | (confidence > 1 & confidence < 
                                   90) | (confidence > 100)) {
      stop("confidence level must be between 90 and 100 or between 0.9 and 1")
    }
    else if (!is.numeric(multiplier)) {
      stop("multiplier must be numeric")
    }
    else if (multiplier <= 0) {
      stop("multiplier must be greater than 0")
    }
    else if (!rlang::is_bool(independent_events)) {
      stop("independent_events must be TRUE or FALSE")
    }
    if (!independent_events) {
      if (missing(eventfreq)) {
        stop(paste0("function calculate_dsr requires an eventfreq column ", 
                    "to be specified when independent_events is FALSE"))
      }
      else if (!deparse(substitute(eventfreq)) %in% colnames(data)) {
        stop("eventfreq is not a field name from data")
      }
      else if (!is.numeric(data[[deparse(substitute(eventfreq))]])) {
        stop("eventfreq field must be numeric")
      }
      else if (anyNA(data[[deparse(substitute(eventfreq))]])) {
        stop("eventfreq field must not have any missing values")
      }
      if (missing(ageband)) {
        stop(paste0("function calculate_dsr requires an ageband column ", 
                    "to be specified when independent_events is FALSE"))
      }
      else if (!deparse(substitute(ageband)) %in% colnames(data)) {
        stop("ageband is not a field name from data")
      }
      else if (anyNA(data[[deparse(substitute(ageband))]])) {
        stop("ageband field must not have any missing values")
      }
    }
    if (independent_events) {
      dsrs <- dsr_inner2(data = data, x = x, n = n, stdpop = stdpop, 
                         type = type, confidence = confidence, multiplier = multiplier)
    }
    else {
      data <- data %>% rename(eventfreq = {
        {
          eventfreq
        }
      }, ageband = {
        {
          ageband
        }
      }) %>% group_by(eventfreq, .add = TRUE)
      grps <- group_vars(data)[!group_vars(data) %in% "eventfreq"]
      check_groups <- filter(summarise(group_by(data, pick(all_of(c(grps, 
                                                                    "ageband")))), num_n = n_distinct(.data$n), 
                                       num_stdpop = n_distinct(.data$stdpop), .groups = "drop"), 
                             .data$num_n > 1 | .data$num_stdpop > 1)
      if (nrow(check_groups) > 0) {
        stop(paste0("There are rows with the same grouping variables and ageband", 
                    " but with different populations (n) or standard populations", 
                    "(stdpop)"))
      }
      freq_var <- data %>% dsr_inner2(x = x, n = n, stdpop = stdpop, 
                                      type = type, confidence = confidence, multiplier = multiplier, 
                                      rtn_nonindependent_vardsr = TRUE) %>% mutate(freqvars = .data$vardsr * 
                                                                                     .data$eventfreq^2) %>% group_by(pick(all_of(grps))) %>% 
        summarise(custom_vardsr = sum(.data$freqvars), .groups = "drop")
      event_data <- data %>% mutate(events = .data$eventfreq * 
                                      .data$x) %>% group_by(pick(all_of(c(grps, "ageband", 
                                                                          "n", "stdpop")))) %>% summarise(x = sum(.data$events, 
                                                                                                                  na.rm = TRUE), .groups = "drop")
      dsrs <- event_data %>% left_join(freq_var, by = grps) %>% 
        group_by(pick(all_of(grps))) %>% dsr_inner2(x = x, 
                                                    n = n, stdpop = stdpop, type = type, confidence = confidence, 
                                                    multiplier = multiplier, use_nonindependent_vardsr = TRUE)
    }
    return(dsrs)
  }



dsr_inner2 <-
  function (data, x, n, stdpop, type, confidence, multiplier, rtn_nonindependent_vardsr = FALSE, 
            use_nonindependent_vardsr = FALSE) {
    if (isTRUE(rtn_nonindependent_vardsr) && ("custom_vardsr" %in% 
                                              names(data) || isTRUE(use_nonindependent_vardsr))) {
      stop("cannot get nonindependent vardsr and use nonindependent vardsr in the same execution")
    }
    confidence[confidence >= 90] <- confidence[confidence >= 
                                                 90]/100
    conf1 <- confidence[1]
    conf2 <- confidence[2]
    if (!use_nonindependent_vardsr) {
      method = "Dobson"
      data <- data %>% mutate(custom_vardsr = NA_real_)
    }
    else {
      method = "Dobson, with confidence adjusted for non-independent events"
    }
    dsrs <- data %>% mutate(wt_rate = PHEindicatormethods:::na.zero(.data$x) * .data$stdpop/.data$n, 
                            sq_rate = PHEindicatormethods:::na.zero(.data$x) * (.data$stdpop/(.data$n))^2, 
    ) %>% summarise(total_count = sum(.data$x, na.rm = TRUE), 
                    total_pop = sum(.data$n), value = sum(.data$wt_rate)/sum(.data$stdpop) * 
                      multiplier, vardsr = case_when(isTRUE(use_nonindependent_vardsr) ~ 
                                                       unique(.data$custom_vardsr), .default = 1/sum(.data$stdpop)^2 * 
                                                       sum(.data$sq_rate)), .groups = "keep")
    if (!rtn_nonindependent_vardsr) {
      dsrs <- mutate(ungroup(dsrs), lowercl = .data$value + 
                       sqrt(.data$vardsr/.data$total_count) * (PHEindicatormethods:::byars_lower(.data$total_count, 
                                                                                                 conf1) - .data$total_count) * multiplier, uppercl = .data$value + 
                       sqrt(.data$vardsr/.data$total_count) * (PHEindicatormethods:::byars_upper(.data$total_count, 
                                                                                                 conf1) - .data$total_count) * multiplier, lower99_8cl = .data$value + 
                       sqrt(.data$vardsr/.data$total_count) * (PHEindicatormethods:::byars_lower(.data$total_count, 
                                                                                                 0.998) - .data$total_count) * multiplier, upper99_8cl = .data$value + 
                       sqrt(.data$vardsr/.data$total_count) * (PHEindicatormethods:::byars_upper(.data$total_count, 
                                                                                                 0.998) - .data$total_count) * multiplier) %>% 
        mutate(confidence = paste0(confidence * 100, "%", 
                                   collapse = ", "), statistic = paste("dsr per", 
                                                                       format(multiplier, scientific = FALSE)), method = method)
      if (!is.na(conf2)) {
        names(dsrs)[names(dsrs) == "lowercl"] <- "lower95_0cl"
        names(dsrs)[names(dsrs) == "uppercl"] <- "upper95_0cl"
      }
      else {
        dsrs <- dsrs %>% select(!c("lower99_8cl", "upper99_8cl"))
      }
      # dsrs <- dsrs %>% mutate(across(c("value", starts_with("upper"), 
      #                                  starts_with("lower")), function(x) if_else(.data$total_count < 
      #                                                                               10, NA_real_, x))
      #                         , statistic = if_else(.data$total_count < 10, "dsr NA for total count < 10", .data$statistic))
    }
    if (rtn_nonindependent_vardsr) {
      dsrs <- dsrs %>% select(group_cols(), "vardsr")
    }
    else if (type == "lower") {
      dsrs <- dsrs %>% select(!c("total_count", "total_pop", 
                                 "value", starts_with("upper"), "vardsr", 
                                 "confidence", "statistic", "method"))
    }
    else if (type == "upper") {
      dsrs <- dsrs %>% select(!c("total_count", "total_pop", 
                                 "value", starts_with("lower"), "vardsr", 
                                 "confidence", "statistic", "method"))
    }
    else if (type == "value") {
      dsrs <- dsrs %>% select(!c("total_count", "total_pop", 
                                 starts_with("lower"), starts_with("upper"), 
                                 "vardsr", "confidence", "statistic", 
                                 "method"))
    }
    else if (type == "standard") {
      dsrs <- dsrs %>% select(!c("vardsr", "confidence", 
                                 "statistic", "method"))
    }
    else if (type == "full") {
      dsrs <- dsrs %>% select(!c("vardsr"))
    }
    return(dsrs)
  }


