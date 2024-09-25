#1. Date functions -------------------------------------------------------------
#' Convert a Date in YYYYMM Format into Its Corresponding Fiscal Period
#'
#' This function converts a date in the format "YYYYMM" (e.g., "202204") into a fiscal period
#' formatted as "YYYY/YYYY" (e.g., "2022/2023"). The fiscal year starts in April, so any month from
#' April to December belongs to the current year, and months from January to March belong to the previous year.
#'
#' @param yyyymm A string representing the date in "YYYYMM" format, where the first 4 digits represent the year and
#' the last 2 digits represent the month.
#' @return A string representing the fiscal year, formatted as "YYYY/YYYY".
#' @examples
#' convert_yearmonth_period("202204") # Returns "2022/2023"
#' convert_yearmonth_period("202201") # Returns "2021/2022"
#' @export
convert_yearmonth_period <- function(yyyymm) {
  
  # Convert the input to a string to ensure it is always treated as a string
  yyyymm <- as.character(yyyymm)
  
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


#' Convert a Date Range in "Month Year - Month Year" Format to "MM/YYYY-MM/YYYY"
#'
#' This function converts a date range provided in the format "Month Year - Month Year"
#' (e.g., "August 2014-July 2015") into a more standardized format "MM/YYYY-MM/YYYY"
#' (e.g., "08/2014-07/2015").
#'
#' @param date_range A character string representing a date range in the format
#' "Month Year - Month Year". The month should be a full month name (e.g., "January").
#'
#' @return A character string in the format "MM/YYYY-MM/YYYY".
#'
#' @examples
#' # Example of converting a date range
#' convert_fixed_period("August 2014 - July 2015")
#' # Returns: "08/2014-07/2015"
#' convert_fixed_period("August 2013-July 2014")
#' # Returns: "08/2013-07/2014"
#' @export
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

#' Convert a Quarterly Time Period in "To MM YYYY" Format into Its Corresponding Fiscal Year
#'
#' This function converts a time period provided in the format "To MM YYYY"
#' (e.g., "To December 2022") into a fiscal year formatted as "YYYY/YYYY"
#' (e.g., "2022/2023"). The fiscal year runs from April to March, so months
#' from January to March belong to the previous fiscal year, and months from April to December
#' belong to the current fiscal year.
#'
#' @param time_period A string representing a time period in the format "To Month Year"
#' (e.g., "To December 2022"), where "Month" is the full name of the month and "Year" is the 4-digit year.
#' @return A string representing the fiscal year, formatted as "YYYY/YYYY".
#' @examples
#' convert_quarterly_period("To December 2022") # Returns "2022/2023"
#' convert_quarterly_period("To March 2023")    # Returns "2022/2023"
#' @export
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


#' Convert a Fiscal Time Period in "YYYY-MM" or "YYYY/MM" Format into a Standard Fiscal Year Format
#'
#' This function converts a time period in the format "YYYY-MM" or "YYYY/MM"
#' (e.g., "2022-23" or "2022/23") into a standardized fiscal year format "YYYY/YYYY"
#' (e.g., "2022/2023"). The input must have two parts, where the second part is a 2-digit year,
#' and the function will append "20" to the 2-digit year to create a valid fiscal year.
#'
#' @param time_period A string representing the time period in either "YYYY-MM" or "YYYY/MM" format,
#' where "YYYY" is the 4-digit start year and "MM" is the 2-digit end year.
#' @return A string representing the fiscal year, formatted as "YYYY/YYYY". If the input is not in the expected format,
#' a message is printed to indicate the correct format, and the function returns NULL.
#' @examples
#' parse_fiscal_year("2020-21")  # Returns "2020/2021"
#' parse_fiscal_year("2024/25")  # Returns "2024/2025"
#' parse_fiscal_year("2023-24")  # Returns "2023/2024"
#' @export
parse_fiscal_year <- function(time_period) {
  # Convert input to a string
  time_period <- as.character(time_period)
  
  # Split the string on either "-" or "/"
  years <- unlist(strsplit(time_period, "[-/]"))
  
  # Ensure we have exactly two parts and that both parts are valid
  if (length(years) == 2 && nchar(years[2]) == 2) {
    start_year <- years[1]
    end_year <- paste0("20", years[2])
    
    # Return the fiscal year in "YYYY/YYYY" format
    return(paste0(start_year, "/", end_year))
  } else {
    # Print an error message and return NULL if the format is incorrect
    message('Incorrect input. Please enter the input in the format "YYYY-MM" or "YYYY/MM".')
    
    return(NULL)
  }
}

# Ensure the function is vectorized for use with dplyr
parse_fiscal_year <- Vectorize(parse_fiscal_year)


#' Process Time Periods in a Dataset to Convert Them into Corresponding Fiscal Years
#'
#' This function processes a dataset and converts different time period formats
#' (e.g., "Month", "Other", "Financial Year") into corresponding fiscal years using
#' different helper functions. It handles various time period descriptions, applies the appropriate
#' conversions, and returns the processed dataset with a new "FiscalYear" column.
#'
#' @param data A data frame containing time periods to be processed. The data frame must have
#' a column that describes the type of time period (e.g., "Month", "Other", "Financial Year") and
#' a column that contains the time period data.
#' @param time_period_desc_col A string representing the name of the column that describes the type of time period
#' (e.g., "Month", "Other", "Financial Year").
#' @return A data frame with an additional column `FiscalYear` that contains the fiscal year
#' corresponding to each time period.
#' @examples
#' # Example dataset
#' data <- data.frame(
#'   TimePeriodDesc = c("Month", "Other", "Financial Year"),
#'   TimePeriod = c("202204", "To December 2022", "2022-23")
#' )
#'
#' # Process time periods
#' processed_data <- process_time_periods_with_denominators(data, "TimePeriodDesc")
#' print(processed_data)
#' @export
process_time_periods_with_denominators <- function(data, time_period_desc_col) {
  
  # Use sym() to treat the column name as a symbol
  time_period_desc_col <- rlang::sym(time_period_desc_col)
  
  # Process the 'Month' data
  month_data <- data %>%
    filter(!!time_period_desc_col == "Month") %>%
    mutate(FiscalYear = as.character(convert_yearmonth_period(TimePeriod)))
  
  # Process the 'Other' data
  other_data <- data %>%
    filter(!!time_period_desc_col == "Other") %>%
    mutate(FiscalYear = case_when(
      grepl("-", TimePeriod) ~ as.character(convert_fixed_period(TimePeriod)),
      grepl("To", TimePeriod) ~ as.character(convert_quarterly_period(TimePeriod)),
      TRUE ~ as.character(TimePeriod)
    ))
  
  # Process the 'Financial Year' data
  fy_data <- data %>%
    filter(!!time_period_desc_col == "Financial Year") %>%
    mutate(FiscalYear = as.character(parse_fiscal_year(TimePeriod)))
  
  # Combine the processed data back together
  combined_data <- bind_rows(month_data, other_data, fy_data)
  
  return(combined_data)
}


#' Extract Start Date from a Fixed Period String (MM/YYYY-MM/YYYY)
#'
#' This function extracts the start date from a fixed period string in the format
#' "MM/YYYY-MM/YYYY" and returns the start date in "DD-MM-YYYY" format.
#'
#' @param date_string A string representing a fixed period in the format "MM/YYYY-MM/YYYY".
#' @return A string representing the start date in "DD-MM-YYYY" format. Returns NA if the format is invalid.
#' @examples
#' get_start_date_from_fixed_period("08/2023-07/2024") # Returns "01-08-2023"
#' @export
get_start_date_from_fixed_period <- function(date_string) {
  # Remove any spaces and ensure format is consistent
  date_string <- gsub("\\s+", "", date_string)
  
  # Regular expression to check the format "MM/YYYY-MM/YYYY"
  if (!grepl("^[0-9]{2}/[0-9]{4}-[0-9]{2}/[0-9]{4}$", date_string)) {
    message('Incorrect input format. Please enter the date in the format "MM/YYYY-MM/YYYY".')
    return(NA_character_)
  }
  
  # Split the string by "-"
  date_parts <- strsplit(date_string, "-")[[1]]
  
  # Ensure date_parts has two components (MM/YYYY)
  if (length(date_parts) != 2) {
    return(NA_character_)
  }
  
  start_date_string <- date_parts[1]  # Extract the start part ("MM/YYYY")
  
  # Convert to a Date object, assuming the first day of the month
  start_date <- suppressWarnings(lubridate::dmy(paste0("01/", start_date_string)))  # Suppress warnings for failed parsing
  
  # Return the start date in "DD-MM-YYYY" format or NA if parsing fails
  return(ifelse(!is.na(start_date), format(start_date, "%d-%m-%Y"), NA_character_))
}

# Vectorize the custom functions
get_start_date_from_fixed_period <- Vectorize(get_start_date_from_fixed_period)


#' Extract End Date from a Fixed Period String (MM/YYYY-MM/YYYY)
#'
#' This function extracts the end date from a fixed period string in the format
#' "MM/YYYY-MM/YYYY" and returns the end date in "DD-MM-YYYY" format.
#'
#' @param date_string A string representing a fixed period in the format "MM/YYYY-MM/YYYY".
#' @return A string representing the end date in "DD-MM-YYYY" format. Returns NA if the format is invalid.
#' @examples
#' get_end_date_from_fixed_period("08/2023-07/2024") # Returns "31-07-2024"
#' @export
get_end_date_from_fixed_period <- function(date_string) {
  # Remove any spaces and ensure format is consistent
  date_string <- gsub("\\s+", "", date_string)
  
  # Regular expression to check the format "MM/YYYY-MM/YYYY"
  if (!grepl("^[0-9]{2}/[0-9]{4}-[0-9]{2}/[0-9]{4}$", date_string)) {
    message('Incorrect input format. Please enter the date in the format "MM/YYYY-MM/YYYY".')
    return(NA_character_)
  }
  
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
get_end_date_from_fixed_period <- Vectorize(get_end_date_from_fixed_period)


#' Extract Start Date from a Fiscal Year (YYYY/YYYY)
#'
#' This function extracts the start date from a fiscal year string in the format
#' "YYYY/YYYY" and returns the start date as April 1st of the start year.
#'
#' @param fiscal_year A string representing a fiscal year in the format "YYYY/YYYY".
#' @return A string representing the start date in "DD-MM-YYYY" format (April 1st of the start year).
#' Returns NA if the input format is invalid.
#' @examples
#' get_start_date_from_fiscal_year("2023/2024") # Returns "01-04-2023"
#' @export
get_start_date_from_fiscal_year <- function(fiscal_year) {
  # Remove any spaces
  fiscal_year <- gsub("\\s+", "", fiscal_year)
  
  # Regular expression to validate "YYYY/YYYY" format
  if (!grepl("^[0-9]{4}/[0-9]{4}$", fiscal_year)) {
    message('Incorrect input format. Please enter the fiscal year in the format "YYYY/YYYY".')
    return(NA_character_)
  }
  
  # Split the fiscal year string by "/"
  years <- strsplit(fiscal_year, "/")[[1]]
  start_year <- years[1]  # Start year (e.g., "2023")
  
  # Create the start date string for 01-04 (April 1st)
  start_date_string <- paste0("01-04-", start_year)
  
  # Convert to Date object
  start_date <- as.Date(start_date_string, format = "%d-%m-%Y")
  
  # Return the formatted date or NA if parsing failed
  return(ifelse(!is.na(start_date), format(start_date, "%d-%m-%Y"), NA_character_))
}

# Vectorize the custom functions
get_start_date_from_fiscal_year <- Vectorize(get_start_date_from_fiscal_year)


#' Extract End Date from a Fiscal Year (YYYY/YYYY)
#'
#' This function extracts the end date from a fiscal year string in the format
#' "YYYY/YYYY" and returns the end date as March 31st of the end year.
#'
#' @param fiscal_year A string representing a fiscal year in the format "YYYY/YYYY".
#' @return A string representing the end date in "DD-MM-YYYY" format (March 31st of the end year).
#' Returns NA if the input format is invalid.
#' @examples
#' get_end_date_from_fiscal_year("2023/2024") # Returns "31-03-2024"
#' @export
get_end_date_from_fiscal_year <- function(fiscal_year) {
  # Remove any spaces
  fiscal_year <- gsub("\\s+", "", fiscal_year)
  
  # Regular expression to validate "YYYY/YYYY" format
  if (!grepl("^[0-9]{4}/[0-9]{4}$", fiscal_year)) {
    message('Incorrect input format. Please enter the fiscal year in the format "YYYY/YYYY".')
    return(NA_character_)
  }
  
  # Split the fiscal year string by "/"
  years <- strsplit(fiscal_year, "/")[[1]]
  end_year <- years[2]  # End year (e.g., "2024")
  
  # Create the end date string for 31-03 (March 31st)
  end_date_string <- paste0("31-03-", end_year)
  
  # Convert to Date object
  end_date <- as.Date(end_date_string, format = "%d-%m-%Y")
  
  return(ifelse(!is.na(end_date), format(end_date, "%d-%m-%Y"), NA_character_))
}

# Vectorize custom functions
get_end_date_from_fiscal_year<- Vectorize(get_end_date_from_fiscal_year)

#' Extract Start Date from a Calendar Year (YYYY)
#'
#' This function extracts the start date from a calendar year string in the format
#' "YYYY" and returns the start date as January 1st of the given year.
#'
#' @param calendar_year A string representing a calendar year in the format "YYYY".
#' @return A string representing the start date in "DD-MM-YYYY" format (January 1st of the given year).
#' Returns NA if the input format is invalid.
#' @examples
#' get_start_date_from_calendar_year("2023") # Returns "01-01-2023"
#' @export
# Function for calendar years (YYYY)
get_start_date_from_calendar_year <- function(calendar_year) {
  
  # Remove any spaces
  calendar_year <- gsub("\\s+", "", calendar_year)
  
  # Regular expression to validate "YYYY/YYYY" format
  if (!grepl("^[0-9]{4}$", calendar_year)) {
    message('Incorrect input format. Please enter the calendar year in the format "YYYY".')
    return(NA_character_)
  }
  
  # Construct start date
  start_date <- as.Date(paste0("01-01-", calendar_year), format = "%d-%m-%Y")
  
  # Return formatted string in DD-MM-YYYY format
  return(ifelse(!is.na(start_date), format(start_date, "%d-%m-%Y"), NA_character_))
}

# Vectorize the custom functions
get_start_date_from_calendar_year <- Vectorize(get_start_date_from_calendar_year)


#' Extract End Date from a Calendar Year (YYYY)
#'
#' This function extracts the end date from a calendar year string in the format
#' "YYYY" and returns the end date as December 31st of the given year.
#'
#' @param calendar_year A string representing a calendar year in the format "YYYY".
#' @return A string representing the end date in "DD-MM-YYYY" format (December 31st of the given year).
#' Returns NA if the input format is invalid.
#' @examples
#' get_end_date_from_calendar_year("2023") # Returns "31-12-2023"
#' @export
get_end_date_from_calendar_year <- function(calendar_year) {
  # Remove any spaces
  calendar_year <- gsub("\\s+", "", calendar_year)
  
  # Regular expression to validate "YYYY/YYYY" format
  if (!grepl("^[0-9]{4}$", calendar_year)) {
    message('Incorrect input format. Please enter the calendar year in the format "YYYY".')
    return(NA_character_)
  }
  
  # Construct end date
  end_date <- as.Date(paste0("31-12-", calendar_year), format = "%d-%m-%Y")
  
  # Return formatted string in DD-MM-YYYY format
  return(ifelse(!is.na(end_date), format(end_date, "%d-%m-%Y"), NA_character_))
}

# Vectorize the custom function
get_end_date_from_calendar_year<- Vectorize(get_end_date_from_calendar_year)


#2. Data cleaning function -----------------------------------------------------

#' Clean the Dataset by Excluding Specific Values and Adding New Columns
#'
#' This function cleans the input dataset (with predefined denominators) by excluding rows where certain values
#' are present in the `PCN` and `GP_Practice` columns, adds a new column `AggYear`
#' with a value of 1, and updates the `Locality_Reg` column based on the value of
#' the `Indicator_Level` column.
#'
#' @param data A data frame that has been processed using the `process_time_periods_with_denominators()` function.
#' The dataset should contain the columns `PCN`, `GP_Practice`, `Indicator_Level`, and `Locality_Reg`.
#' @return A cleaned data frame with the following modifications:
#' \itemize{
#'   \item Rows where `PCN` is "Closed practice" or "Not applicable" are excluded.
#'   \item Rows where `GP_Practice` is 'M88006' are excluded.
#'   \item A new column `AggYear` is added with a value of 1 for all rows.
#'   \item The `Locality_Reg` column is updated: If `Indicator_Level` is "Birmingham Local Authority",
#'   `Locality_Reg` is set to "Birmingham". If `Indicator_Level` is "Solihull Local Authority",
#'   `Locality_Reg` is set to "Solihull". For other values, `Locality_Reg` remains unchanged.
#' }
#' Returns an empty object if the input data does not have the required columns `PCN`, `GP_Practice`, `Indicator_Level`, and `Locality_Reg`.
#' @examples
#' # Assuming `updated_dt` is a data frame processed using `process_time_periods_with_denominators()`
#' clean_dt <- clean_dataset_with_denominators(updated_dt)
#' @export
clean_dataset_with_denominators <- function(data) {
  
  # Required columns
  required_columns <- c("PCN", "GP_Practice", "Indicator_Level", "Locality_Reg")
  
  # Check if all required columns are present
  missing_columns <- setdiff(required_columns, colnames(data))
  
  if(length(missing_columns) > 0){
    message("The following required columns are missing from the input data: ",
            paste(missing_columns, collapse = ", "))
    return(NULL)
  }
  
  # Exclude rows where PCN is "Closed practice" or "Not applicable"
  data <- data %>%
    filter(!(PCN %in% c("Closed practice", "Not applicable"))) %>%
    
    # Exclude rows where GP_Practice is 'M88006'
    filter(!(GP_Practice %in% c('M88006'))) %>%
    
    # Add a new column AggYear with a value of 1
    mutate(AggYear = 1) %>%
    
    # Update Locality_Reg based on Indicator_Level
    mutate(Locality_Reg = case_when(
      Indicator_Level == 'Birmingham Local Authority' ~ "Birmingham",
      Indicator_Level == 'Solihull Local Authority' ~ "Solihull",
      TRUE ~ Locality_Reg
    ))
  
  return(data)
}

#3. Create agregated data functions --------------------------------------------

#' Create Aggregated Data for Rolling Years (1, 3, 5 Years) with Predefined Denominators
#'
#' This function creates aggregated data (with predefined denominators) for different rolling periods,
#' such as 1, 3, and 5 years, where the time period is already in the correct fiscal year format ("YYYY/YYYY").
#' It summarizes the `Numerator` and `Denominator` for the specified rolling periods and outputs the aggregated data.
#'
#' The input data must contain the following columns to perform the required grouping:
#' \itemize{
#'   \item `IndicatorID`
#'   \item `ReferenceID`
#'   \item `GP_Practice`
#'   \item `PCN`
#'   \item `Locality_Reg`
#'   \item `LSOA_2011`
#'   \item `LSOA_2021`
#'   \item `Ethnicity_Code`
#'   \item `Indicator_Level`
#'   \item `FiscalYear`
#'   \item `Numerator`
#'   \item `Denominator`
#' }
#' If any of these columns are missing, the function will print a message and return `NULL`.
#'
#' @param data A data frame that contains time periods in the "YYYY/YYYY" fiscal year format, along with
#' `Numerator` and `Denominator` columns to be aggregated.
#' @param agg_years A vector of integers specifying the rolling periods to be aggregated.
#' Defaults to c(1, 3, 5), representing 1-year, 3-year, and 5-year aggregations.
#' @return A data frame with the aggregated data for each specified rolling period. For `agg_year = 1`,
#' the original data is used. For `agg_year = 3` or `agg_year = 5`, the data is aggregated over those periods.
#' Returns `NULL` if the required columns are missing from the input data.
#' @examples
#' # Example usage
#' agg_dt_default <- clean_dt %>%
#'   filter(nchar(FiscalYear) == 9) %>%
#'   create_agg_data_default_with_denominators()
#' @export
create_agg_data_default_with_denominators <- function(data, agg_years = c(1, 3, 5)) {
  
  # Required columns for the grouping and aggregation
  required_columns <- c(
    "IndicatorID", "ReferenceID", "GP_Practice", "PCN", "Locality_Reg",
    "LSOA_2011", "LSOA_2021", "Ethnicity_Code", "Indicator_Level",
    "FiscalYear", "Numerator", "Denominator"
  )
  
  # Check if all required columns are present
  missing_columns <- setdiff(required_columns, colnames(data))
  
  if (length(missing_columns) > 0) {
    message("The following required columns are missing from the input data: ",
            paste(missing_columns, collapse = ", "))
    return(NULL)
  }
  
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


#' Create Aggregated Data for Fixed Periods (e.g., August 2017 - July 2018) with Predefined Denominators
#'
#' This function handles cases where the time period is in a fixed format, such as
#' "August 2017 - July 2018", and creates aggregated data for different rolling periods,
#' such as 1, 3, and 5 years. The function recalculates the `FiscalYear` and aggregates
#' the `Numerator` and `Denominator` based on the specified rolling periods.
#'
#' The input data must contain the following columns to perform the required grouping:
#' \itemize{
#'   \item `IndicatorID`
#'   \item `ReferenceID`
#'   \item `GP_Practice`
#'   \item `PCN`
#'   \item `Locality_Reg`
#'   \item `LSOA_2011`
#'   \item `LSOA_2021`
#'   \item `Ethnicity_Code`
#'   \item `Indicator_Level`
#'   \item `FiscalYear`
#'   \item `Numerator`
#'   \item `Denominator`
#' }
#' If any of these columns are missing, the function will print a message and return `NULL`.
#'
#' @param data A data frame that contains fixed periods in the `FiscalYear` column, where the
#' time period format is longer than 9 characters (e.g., "August 2017 - July 2018").
#' @param agg_years A vector of integers specifying the rolling periods to be aggregated.
#' Defaults to c(1, 3, 5), representing 1-year, 3-year, and 5-year aggregations.
#' @return A data frame with the aggregated data for each specified rolling period. For `agg_year = 1`,
#' the original data is used with `StartYear` and `EndYear` extracted from the original `FiscalYear`.
#' For `agg_year = 3` or `agg_year = 5`, the data is aggregated over those periods.
#' Returns `NULL` if the required columns are missing from the input data.
#' @examples
#' # Example usage
#' agg_dt_fixed_period <- clean_dt %>%
#'   filter(nchar(FiscalYear) > 9) %>%
#'   create_agg_data_for_fixed_period_with_denominators()
#' @export
create_agg_data_for_fixed_period_with_denominators <- function(data, agg_years = c(1, 3, 5)) {
  
  # Required columns for the grouping and aggregation
  required_columns <- c(
    "IndicatorID", "ReferenceID", "GP_Practice", "PCN", "Locality_Reg",
    "LSOA_2011", "LSOA_2021", "Ethnicity_Code", "Indicator_Level",
    "FiscalYear", "Numerator", "Denominator"
  )
  
  # Check if all required columns are present
  missing_columns <- setdiff(required_columns, colnames(data))
  
  if (length(missing_columns) > 0) {
    message("The following required columns are missing from the input data: ",
            paste(missing_columns, collapse = ", "))
    return(NULL)
  }
  
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

#' Create Aggregated Data for Calendar Years (YYYY Format) with Predefined Denominators
#'
#' This function handles cases where the `FiscalYear` is in a calendar year format (e.g., "2023")
#' and creates aggregated data for different rolling periods, such as 1, 3, and 5 years. The function
#' recalculates the `FiscalYear` by adding start and end dates for the calendar year and aggregates
#' the `Numerator` and `Denominator` based on the specified rolling periods.
#'
#' The input data must contain the following columns to perform the required grouping:
#' \itemize{
#'   \item `IndicatorID`
#'   \item `ReferenceID`
#'   \item `GP_Practice`
#'   \item `PCN`
#'   \item `Locality_Reg`
#'   \item `LSOA_2011`
#'   \item `LSOA_2021`
#'   \item `Ethnicity_Code`
#'   \item `Indicator_Level`
#'   \item `FiscalYear`
#'   \item `Numerator`
#'   \item `Denominator`
#' }
#' If any of these columns are missing, the function will print a message and return `NULL`.
#'
#' @param data A data frame that contains calendar years in the `FiscalYear` column, where the
#' time period is exactly 4 characters (e.g., "2023").
#' @param agg_years A vector of integers specifying the rolling periods to be aggregated.
#' Defaults to c(1, 3, 5), representing 1-year, 3-year, and 5-year aggregations.
#' @return A data frame with the aggregated data for each specified rolling period. For `agg_year = 1`,
#' the original data is used, with start and end dates added to the calendar year. For `agg_year = 3`
#' or `agg_year = 5`, the data is aggregated over those periods.
#' Returns `NULL` if the required columns are missing from the input data.
#' @examples
#' # Example usage
#' agg_dt_calendar_yr <- clean_dt %>%
#'   filter(nchar(FiscalYear) == 4) %>%
#'   create_agg_data_for_calendar_yr_with_denominators()
#' @export
create_agg_data_for_calendar_yr_with_denominators<- function(data, agg_years = c(1, 3, 5)) {
  
  # Required columns for the grouping and aggregation
  required_columns <- c(
    "IndicatorID", "ReferenceID", "GP_Practice", "PCN", "Locality_Reg",
    "LSOA_2011", "LSOA_2021", "Ethnicity_Code", "Indicator_Level",
    "FiscalYear", "Numerator", "Denominator"
  )
  
  # Check if all required columns are present
  missing_columns <- setdiff(required_columns, colnames(data))
  
  if (length(missing_columns) > 0) {
    message("The following required columns are missing from the input data: ",
            paste(missing_columns, collapse = ", "))
    return(NULL)
  }
  
  
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


#' Combine Aggregated Data Based on Fiscal Year Length with Predefined Denominators
#'
#' This function determines the format of the `FiscalYear` column (e.g., calendar year, fiscal year, or fixed period)
#' in the dataset and applies the appropriate aggregation function. It uses helper functions like
#' `create_agg_data_for_calendar_yr_with_denominators()`, `create_agg_data_default_with_denominators()`, and
#' `create_agg_data_for_fixed_period_with_denominators()` to create aggregated data for different fiscal year formats.
#'
#' The input data must contain the following columns to perform the required grouping:
#' \itemize{
#'   \item `IndicatorID`
#'   \item `ReferenceID`
#'   \item `GP_Practice`
#'   \item `PCN`
#'   \item `Locality_Reg`
#'   \item `LSOA_2011`
#'   \item `LSOA_2021`
#'   \item `Ethnicity_Code`
#'   \item `Indicator_Level`
#'   \item `FiscalYear`
#'   \item `Numerator`
#'   \item `Denominator`
#' }
#' If any of these columns are missing, the function will print a message and return `NULL`.
#'
#' @param data A data frame that contains a `FiscalYear` column. The `FiscalYear` can be in three possible formats:
#' \itemize{
#'   \item Calendar year (e.g., "2023" - 4 characters long)
#'   \item Fiscal year (e.g., "2022/2023" - 9 characters long)
#'   \item Fixed period (e.g., "August 2017 - July 2018" - more than 9 characters long)
#' }
#' @return A data frame with the aggregated data for each fiscal year format. The function combines the results
#' from applying the appropriate aggregation function for each fiscal year length.
#' Returns `NULL` if the required columns are missing from the input data.
#' @examples
#' # Example usage:
#' agg_data <- create_agg_data_combined_with_denominators(clean_dt)
#' @export
create_agg_data_combined_with_denominators <- function(data) {
  
  # Required columns for the grouping and aggregation
  required_columns <- c(
    "IndicatorID", "ReferenceID", "GP_Practice", "PCN", "Locality_Reg",
    "LSOA_2011", "LSOA_2021", "Ethnicity_Code", "Indicator_Level",
    "FiscalYear", "Numerator", "Denominator"
  )
  
  # Check if all required columns are present
  missing_columns <- setdiff(required_columns, colnames(data))
  
  if (length(missing_columns) > 0) {
    message("The following required columns are missing from the input data: ",
            paste(missing_columns, collapse = ", "))
    return(NULL)
  }
  
  # Determine the unique lengths of FiscalYear in the dataset
  fiscal_year_lengths <- unique(nchar(data$FiscalYear))
  
  # Initialize an empty list to store the aggregated data
  aggregated_data <- list()
  
  # Loop over each unique fiscal year length and apply the appropriate function
  for (length in fiscal_year_lengths) {
    if (length == 4) {
      agg_dt <- data %>%
        filter(nchar(FiscalYear) == 4) %>%
        create_agg_data_for_calendar_yr_with_denominators()
    } else if (length == 9) {
      agg_dt <- data %>%
        filter(nchar(FiscalYear) == 9) %>%
        create_agg_data_default_with_denominators()
    } else if (length > 9){
      agg_dt <- data %>%
        filter(nchar(FiscalYear) > 9) %>%
        create_agg_data_for_fixed_period_with_denominators()
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

#4. Calculate crude rates with predefined denominators functions ---------------

#' Get Grouping Columns for Calculating Crude Rates with Predefined Denominators
#'
#' This function returns a set of columns used for grouping data when calculating crude rates using predefined denominators.
#' It allows for calculating either overall crude rates or rates split by ethnicity, and adjusts the grouping columns based
#' on the specified geographic level (e.g., "PCN", "Local Authority", "Locality", or "ICB" level).
#'
#' @param rate_type A string specifying the type of rate to calculate. Options are:
#' \itemize{
#'   \item "overall" - for calculating overall crude rates.
#'   \item "ethnicity" - for calculating rates by ethnicity, adding "ONSGroup" as a grouping variable.
#' }
#' @param rate_level A string specifying the geographic level for calculating the rates. Options are:
#' \itemize{
#'   \item "PCN" - for Primary Care Network level.
#'   \item "Local Authority" or "Locality" - for Local Authority or Locality level, using "Locality_Reg" as a grouping column.
#'   \item "ICB" level - no additional grouping column is added.
#' }
#' @return A character vector containing the columns to be used for grouping the data, based on the specified rate_type and rate_level.
#' @examples
#' # Example usage for calculating overall rates at the locality level:
#' get_crude_rate_grouping_with_denominators(rate_type = "overall", rate_level = "Locality")
#'
#' # Example usage for calculating rates by ethnicity at the PCN level:
#' get_crude_rate_grouping_with_denominators(rate_type = "ethnicity", rate_level = "PCN")
#' @export
get_crude_rate_grouping_with_denominators <- function(rate_type, rate_level) {
  
  # Convert rate_type to lowercase to ensure consistent comparison
  rate_type <- tolower(rate_type)
  rate_level <- tolower(rate_level)
  
  # Ensure the rate_type is either "overall" or "ethnicity"
  valid_rate_types <- c("overall", "ethnicity")
  if (!(rate_type %in% valid_rate_types)) {
    stop('Invalid rate type specified. Please use "overall" or "ethnicity".')
  }
  
  # Ensure the rate_level is one of the valid options
  valid_rate_levels <- c("pcn", "local authority", "locality", "icb")
  if (!(rate_level %in% valid_rate_levels)) {
    stop('Invalid rate level specified. Please use "PCN", "Local Authority", "Locality", or "ICB".')
  }
  
  base_group_vars <- c("IndicatorID", "ReferenceID", "FiscalYear", "AggYear")
  
  # Add additional grouping columns based on rate_level
  if (rate_level == "pcn") {
    additional_group_var <- "PCN"
  } else if (any(rate_level == c("local authority", "locality"))) {
    additional_group_var <- "Locality_Reg"
  } else {
    additional_group_var <- NULL # For calculating rates at ICB level, no additional column
  }
  
  # Add the rate_type specific grouping columns
  group_vars <- switch(rate_type,
                       "overall" = base_group_vars,
                       "ethnicity" = c(base_group_vars, "ONSGroup")
  )
  
  # Append the additional grouping column if any
  if (!is.null(additional_group_var)) {
    group_vars <- c(group_vars, additional_group_var)
  }
  
  return(group_vars)
}


#' Calculate Crude Rates for Data with Predefined Denominators
#'
#' This function calculates crude rates for the specified aggregation years (e.g., 1, 3, or 5 years)
#' using predefined denominators. It calculates the crude rates either overall or by ethnicity, and it
#' adjusts the grouping and output based on the specified rate level (e.g., "PCN", "Local Authority",
#' "Locality", or "ICB").
#'
#' @param data A data frame containing the necessary columns for calculating crude rates,
#' including `Numerator`, `Denominator`, `FiscalYear`, and `AggYear`. This should be a cleaned dataset
#' which has been processed using `clean_dataset_with_denominators()`.
#' The input data must contain the following columns to perform the required grouping:
#' \itemize{
#'   \item `IndicatorID`
#'   \item `ReferenceID`
#'   \item `GP_Practice`
#'   \item `PCN`
#'   \item `Locality_Reg`
#'   \item `LSOA_2011`
#'   \item `LSOA_2021`
#'   \item `Ethnicity_Code`
#'   \item `Indicator_Level`
#'   \item `FiscalYear`
#'   \item `AggYear`
#'   \item `Numerator`
#'   \item `Denominator`
#' }
#' If any of these columns are missing, the function will print an error message.
#' @param group_vars A vector of column names to group the data by, for calculating crude rates, which can be obtained using
#' `get_crude_rate_grouping_with_denominators()` function
#' @param agg_year A vector specifying the aggregation years to be calculated (defaults to c(1, 3, 5)).
#' @param rate_level A string indicating the geographic level for calculating the rates (e.g., "PCN", "Local Authority", "Locality", or "ICB").
#' @param rate_type A string specifying the type of rate to calculate ("overall" or "ethnicity").
#' @param age_group A string representing the age group to be included in the output. (e.g., "All ages", "0-18 yrs", or "<75 yrs")
#' @param gender_group A string representing the gender group to be included in the output. (e.g., "Persons")
#' @param multiplier A numeric value for scaling the calculated rates (defaults to 100,000).
#' @return A data frame with the calculated crude rates, including confidence intervals, aggregation details, and demographics.
#' @examples
#' # Example usage:
#' calculate_crude_rate_with_denominators(data, group_vars = c("IndicatorID", "ReferenceID", "FiscalYear", "AggYear"),
#'                      agg_year = c(1, 3, 5), rate_level = "ICB", rate_type = "overall",
#'                      age_group = "All ages", gender_group = "Persons")
#' @export
calculate_crude_rate_with_denominators <- function(data, group_vars, agg_year = c(1, 3, 5), rate_level, rate_type, age_group, gender_group, multiplier = 100000) {
  
  # Convert rate_type and rate_level to lowercase to ensure consistent comparison
  rate_type <- tolower(rate_type)
  rate_level <- tolower(rate_level)
  
  # Ensure the rate_type is either "overall" or "ethnicity"
  valid_rate_types <- c("overall", "ethnicity")
  if (!(rate_type %in% valid_rate_types)) {
    stop('Invalid rate type specified. Please use "overall" or "ethnicity".')
  }
  
  # Ensure the rate_level is one of the valid options
  valid_rate_levels <- c("pcn", "local authority", "locality", "icb")
  if (!(rate_level %in% valid_rate_levels)) {
    stop('Invalid rate level specified. Please use "PCN", "Local Authority", "Locality", or "ICB".')
  }
  
  # Required columns for the grouping and aggregation
  required_columns <- c(
    "IndicatorID", "ReferenceID", "GP_Practice", "PCN", "Locality_Reg",
    "LSOA_2011", "LSOA_2021", "Ethnicity_Code", "Indicator_Level",
    "FiscalYear", "AggYear", "Numerator", "Denominator"
  )
  
  # Check if all required columns are present
  missing_columns <- setdiff(required_columns, colnames(data))
  
  if (length(missing_columns) > 0) {
    stop(paste("The following required columns are missing from the input data:",
               paste(missing_columns, collapse = ", ")))
  }
  
  all_results <- list()  # Initialize a list to store results for each year
  
  for (year in agg_year) {
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
        Numerator = abs(Numerator)       # Get the absolute number to handle negative numerators (e.g., Excess Winter death index)
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
      mutate(
        InsertDate = Sys.Date(),
        AggYear = year,
        DataQualityID = 1,
        StatusID = 1,
        AggregationLabel = if (rate_level == "pcn") {
          PCN
        } else if (rate_level == "local authority" || rate_level == "locality") {
          Locality_Reg
        } else if (rate_level == "icb") {
          "BSOL ICB"
        } else {
          NA_character_
        },
        AggregationType = if (rate_level == "pcn") {
          "PCN"
        } else if (rate_level == "locality") {
          "Locality (Registered)"
        } else if (rate_level == "local authority") {
          "Local Authority"
        } else if (rate_level == "icb") {
          "ICB"
        } else {
          NA_character_
        },
        Gender = gender_group,
        AgeGroup = age_group,
        IMD = NA_character_,
        EthnicityCode = if (rate_type == "ethnicity") ONSGroup else NA_character_
      ) %>%
      # Ensure that only the correct function is run based on the format of FiscalYear
      mutate(
        IndicatorStartDate = ifelse(grepl("^[0-9]{4}/[0-9]{4}$", FiscalYear),
                                    get_start_date_from_fiscal_year(FiscalYear),
                                    ifelse(grepl("^[0-9]{2}/[0-9]{4}-[0-9]{2}/[0-9]{4}$", FiscalYear),
                                           get_start_date_from_fixed_period(FiscalYear),
                                           NA_character_)),
        IndicatorEndDate = ifelse(grepl("^[0-9]{4}/[0-9]{4}$", FiscalYear),
                                  get_end_date_from_fiscal_year(FiscalYear),
                                  ifelse(grepl("^[0-9]{2}/[0-9]{4}-[0-9]{2}/[0-9]{4}$", FiscalYear),
                                         get_end_date_from_fixed_period(FiscalYear),
                                         NA_character_)),
        IndicatorValueType = case_when(
          rate_type == "ethnicity" ~ paste0(year, "-year Ethnicity Crude Rate"),
          rate_type == "overall" ~ paste0(year, "-year Overall Crude Rate"),
          TRUE ~ NA_character_
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



#' Process a Single Indicator to Calculate Crude Rates with Predefined Denominators
#'
#' This function processes a cleaned dataset for a single indicator and calculates crude rates (overall and by ethnicity)
#' across various geographic levels (e.g., "PCN", "Local Authority", "Locality", or "ICB"). It first aggregates the data
#' using predefined denominators and then calculates crude rates for 1-, 3-, and 5-year periods.
#'
#' @param clean_data A data frame containing cleaned data for calculating crude rates,
#' including the necessary columns like `Numerator`, `Denominator`, `FiscalYear`, and `AggYear`.
#' The input data must contain the following columns to perform the required grouping:
#' \itemize{
#'   \item `IndicatorID`
#'   \item `ReferenceID`
#'   \item `GP_Practice`
#'   \item `PCN`
#'   \item `Locality_Reg`
#'   \item `LSOA_2011`
#'   \item `LSOA_2021`
#'   \item `Ethnicity_Code`
#'   \item `Indicator_Level`
#'   \item `FiscalYear`
#'   \item `AggYear`
#'   \item `Numerator`
#'   \item `Denominator`
#' }
#' If any of these columns are missing, the function will print an error message.
#' @param age_group A string representing the age group to be included in the output (e.g., "All ages", "0-18 yrs", or "<75 yrs").
#' @param gender_group A string representing the gender group to be included in the output (e.g., "Persons").
#' @param multiplier A numeric value to scale the crude rates (defaults to 100,000).
#' @return A data frame with the calculated crude rates, including overall rates and ethnicity-specific rates,
#' across different geographic levels and time periods.
#' @examples
#' # Example usage:
#' processed_dataset <- process_single_indicator_with_denominators(
#'   clean_data = clean_data %>% filter(IndicatorID == 103),
#'   age_group = "35+ yrs",
#'   gender_group = "Persons"
#' )
#' @export
process_single_indicator_with_denominators <- function(clean_data, age_group, gender_group, multiplier = 100000) {
  
  # Required columns for the grouping and aggregation
  required_columns <- c(
    "IndicatorID", "ReferenceID", "GP_Practice", "PCN", "Locality_Reg",
    "LSOA_2011", "LSOA_2021", "Ethnicity_Code", "Indicator_Level",
    "FiscalYear", "AggYear", "Numerator", "Denominator"
  )
  
  # Check if all required columns are present
  missing_columns <- setdiff(required_columns, colnames(clean_data))
  
  if (length(missing_columns) > 0) {
    stop(paste("The following required columns are missing from the input data:",
               paste(missing_columns, collapse = ", ")))
  }
  
  # Step 1: Aggregate the data
  aggregated_data <- create_agg_data_combined_with_denominators(clean_data)
  
  # Step 2: Define a helper function to calculate rates based on indicator and rate levels
  calculate_rates <- function(rate_level) {
    # Overall rate
    rate_overall <- calculate_crude_rate_with_denominators(
      data = aggregated_data,
      group_vars = get_crude_rate_grouping_with_denominators(rate_type = "overall", rate_level = rate_level),
      agg_year = c(1, 3, 5),
      rate_level = rate_level,
      rate_type = "overall",
      age_group = age_group,
      gender_group = gender_group,
      multiplier = multiplier
    )
    
    # Ethnicity rate
    rate_ethnicity <- calculate_crude_rate_with_denominators(
      data = aggregated_data,
      group_vars = get_crude_rate_grouping_with_denominators(rate_type = "ethnicity", rate_level = rate_level),
      agg_year = c(1, 3, 5),
      rate_level = rate_level,
      rate_type = "ethnicity",
      age_group = age_group,
      gender_group = gender_group,
      multiplier = multiplier
    )
    
    return(list(rate_overall = rate_overall, rate_ethnicity = rate_ethnicity))
  }
  
  # Step 3: Process rates by unique Indicator Levels
  unique_indicator_levels <- tolower(unique(aggregated_data$Indicator_Level))
  combined_rates <- list()
  
  for (indicator_level in unique_indicator_levels) {
    if (indicator_level == 'practice level') {
      # Calculate rates for PCN, Locality (Registered), and ICB levels
      rates_pcn <- calculate_rates("pcn")
      rates_locality <- calculate_rates("locality")
      rates_icb <- calculate_rates("icb")
      
      # Store the results in the combined_rates list
      combined_rates <- append(combined_rates, list(rates_pcn$rate_overall, rates_pcn$rate_ethnicity))
      combined_rates <- append(combined_rates, list(rates_locality$rate_overall, rates_locality$rate_ethnicity))
      combined_rates <- append(combined_rates, list(rates_icb$rate_overall, rates_icb$rate_ethnicity))
      
    } else if (indicator_level %in% c("birmingham local authority", "solihull local authority")) {
      # Calculate rates for Local Authority and ICB levels
      rates_locality <- calculate_rates("local authority")
      rates_icb <- calculate_rates("icb")
      
      # Store the results in the combined_rates list
      combined_rates <- append(combined_rates, list(rates_locality$rate_overall, rates_locality$rate_ethnicity))
      combined_rates <- append(combined_rates, list(rates_icb$rate_overall, rates_icb$rate_ethnicity))
      
    } else if (indicator_level == "icb level") {
      # Calculate rates only for ICB level
      rates_icb <- calculate_rates("icb")
      
      # Store the results in the combined_rates list
      combined_rates <- append(combined_rates, list(rates_icb$rate_overall, rates_icb$rate_ethnicity))
    }
  }
  
  # Step 4: Combine all dataframes into one final dataframe
  final_output <- bind_rows(combined_rates)
  
  # Step 5: Filter out rows where Ethnicity Crude Rates are present but EthnicityCode is missing
  final_output <- final_output %>%
    filter(
      !(IndicatorValueType %in% c("1-year Ethnicity Crude Rate", "3-year Ethnicity Crude Rate", "5-year Ethnicity Crude Rate") &
          is.na(EthnicityCode))
    )
  
  return(final_output)
}


#' Process Multiple Indicators to Calculate Crude Rates with Predefined Denominators
#'
#' This function processes multiple indicators at once, calculating crude rates for each indicator
#' based on predefined denominators and the parameters specified in an external data frame.
#' It applies the `process_single_indicator_with_denominators` function to each combination of parameters
#' (e.g., `IndicatorID`, `ReferenceID`, `AgeCategory`, and `GenderCategory`), ensuring that crude rates
#' are calculated for the specified indicators.
#' @param clean_data A data frame containing cleaned data for calculating crude rates,
#' including the necessary columns like `Numerator`, `Denominator`, `FiscalYear`, and `AggYear`.
#' The input data must contain the following columns to perform the required grouping:
#' \itemize{
#'   \item `IndicatorID`
#'   \item `ReferenceID`
#'   \item `GP_Practice`
#'   \item `PCN`
#'   \item `Locality_Reg`
#'   \item `LSOA_2011`
#'   \item `LSOA_2021`
#'   \item `Ethnicity_Code`
#'   \item `Indicator_Level`
#'   \item `FiscalYear`
#'   \item `AggYear`
#'   \item `Numerator`
#'   \item `Denominator`
#' }
#' If any of these columns are missing, the function will print an error message.
#' @param indicator_params A data frame containing the parameter combinations for the indicators,
#' including `IndicatorID`, `ReferenceID`, `AgeCategory`, and `GenderCategory`.
#' @return A data frame with the calculated crude rates for each row of `indicator_params`. The results include
#' distinct calculations for each parameter combination.
#' @examples
#' # Example usage:
#' results <- process_multiple_indicators_with_denominators(
#'   clean_data= clean_data,
#'   indicator_params = parameter_combinations
#' )
#' @export
process_multiple_indicators_with_denominators <- function(clean_data, indicator_params) {
  
  # Required columns for the grouping and aggregation
  required_columns <- c(
    "IndicatorID", "ReferenceID", "GP_Practice", "PCN", "Locality_Reg",
    "LSOA_2011", "LSOA_2021", "Ethnicity_Code", "Indicator_Level",
    "FiscalYear", "AggYear", "Numerator", "Denominator"
  )
  
  # Check if all required columns are present in the clean data
  missing_columns <- setdiff(required_columns, colnames(clean_data))
  
  if (length(missing_columns) > 0) {
    stop(paste("The following required columns are missing from the input data:",
               paste(missing_columns, collapse = ", ")))
  }
  
  # Helper function to process each row of parameters
  process_parameters <- function(row) {
    tryCatch(
      {
        message(paste("Processing data for IndicatorID:", row$IndicatorID, "and ReferenceID:", row$ReferenceID))
        
        # Step 1: Filter clean_data for the current row's parameters
        filtered_data <- clean_data %>%
          filter(IndicatorID == row$IndicatorID, ReferenceID == row$ReferenceID)
        
        # Step 2: Calculate crude rates using process_single_indicator_with_denominators()
        output <- process_single_indicator_with_denominators(
          clean_data = filtered_data,
          age_group = row$AgeCategory,
          gender_group = row$GenderCategory
        ) %>%
          distinct()  # Ensure unique results
        
        message(paste("Completed processing for IndicatorID:", row$IndicatorID, "and ReferenceID:", row$ReferenceID))
        
        return(output)
      },
      error = function(e) {
        # Log the error message and return an empty tibble if an error occurs
        message(
          paste0(
            "Error occurred for IndicatorID: ", row$IndicatorID,
            ", ReferenceID: ", row$ReferenceID,
            "\nDetails: ", e
          )
        )
        return(tibble())  # Return an empty tibble if there's an error
      }
    )
  }
  
  # Apply process_parameters to each row of indicator_params
  results <- indicator_params %>%
    rowwise() %>%
    do(process_parameters(.)) %>%
    ungroup()  # Remove the rowwise grouping to return a simple tibble
  
  return(results)
}
