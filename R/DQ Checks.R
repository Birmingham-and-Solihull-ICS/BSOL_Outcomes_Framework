
#1. Check all of the retrieved indicators have been processed ------------------


check_processed_indicators <- function(indicator_ids, results) {
  # Extract unique IndicatorIDs from the results dataframe
  processed_ids <- unique(results$IndicatorID)
  
  # Find missing IndicatorIDs by checking which are in indicator_ids but not in processed_ids
  missing_ids <- setdiff(indicator_ids, processed_ids)
  
  # Print the result
  if (length(missing_ids) == 0) {
    print("All IndicatorIDs have been processed.")
  } else {
    print("Missing Indicator IDs that have not been processed:")
    print(missing_ids)
  }
}


# Run the function to check missing IndicatorIDs
check_processed_indicators(indicator_ids, results)

#2. Check the format of the indicator start and end dates ----------------------

check_date_format <- function(data) {
  # Check if IndicatorStartDate and IndicatorEndDate have 10 characters and match the expected date format
  incorrect_start_date <- data %>%
    filter(nchar(IndicatorStartDate) != 10 | !grepl("^\\d{2}-\\d{2}-\\d{4}$", IndicatorStartDate))
  
  incorrect_end_date <- data %>%
    filter(nchar(IndicatorEndDate) != 10 | !grepl("^\\d{2}-\\d{2}-\\d{4}$", IndicatorEndDate))
  
  # Print the results
  if (nrow(incorrect_start_date) == 0 && nrow(incorrect_end_date) == 0) {
    print("All dates are correctly formatted.")
  } else {
    if (nrow(incorrect_start_date) > 0) {
      print("Incorrect format or length in IndicatorStartDate:")
      print(incorrect_start_date)
    }
    if (nrow(incorrect_end_date) > 0) {
      print("Incorrect format or length in IndicatorEndDate:")
      print(incorrect_end_date)
    }
  }
}

# Run the function to check the date format (Expecting DD-MM-YYYYY)
check_date_format(results)

# Example to check the indicators with incorrect date formats
# results %>%
#   filter(IndicatorID %in% c(25, 68, 121)) %>%
#   select(IndicatorID, FiscalYear, IndicatorStartDate, IndicatorEndDate) %>%
#   distinct() %>%
#   View()


#3. Check any missing date/timepoints ------------------------------------------

# To check any missing dates in FiscalYear, IndicatorStartDate, or IndicatorEndDate columns
check_missing_dates <- function(data) {
  # Add row number column dynamically
  data_with_row_numbers <- data %>%
    mutate(row_number = row_number())  # Add row number column
  
  # Check for rows where FiscalYear, IndicatorStartDate, or IndicatorEndDate are missing
  missing_data <- data_with_row_numbers %>%
    filter(is.na(FiscalYear) | is.na(IndicatorStartDate) | is.na(IndicatorEndDate)) %>%
    select(row_number, IndicatorID, FiscalYear, IndicatorStartDate, IndicatorEndDate)
  
  # Return the result
  if (nrow(missing_data) == 0) {
    print("No missing data found in FiscalYear, IndicatorStartDate, or IndicatorEndDate.")
  } else {
    print("Missing data found in the following rows:")
    print(missing_data)
  }
}

# Example
check_missing_dates(results)

# To check any missing unique combinations of fiscal year, indicator start and end dates
check_time_point_combinations <- function(original_data, processed_data) {
  # Step 1: Process original data to calculate IndicatorStartDate and IndicatorEndDate
  original_check <- original_data %>%
    mutate(
      IndicatorStartDate = case_when(
        nchar(FiscalYear) == 15 ~ get_start_date_from_fixed_period(FiscalYear),  # Fixed period (MM/YYYY-MM/YYYY)
        nchar(FiscalYear) == 9 ~ get_start_date_from_fiscal_year(FiscalYear),    # Fiscal year (YYYY/YYYY)
        nchar(FiscalYear) == 4 ~ get_start_date_from_calendar_year(FiscalYear),                   # Calendar year (YYYY)
        TRUE ~ NA_character_  # Return NA for invalid formats
      ),
      IndicatorEndDate = case_when(
        nchar(FiscalYear) == 15 ~ get_end_date_from_fixed_period(FiscalYear),    # Fixed period (MM/YYYY-MM/YYYY)
        nchar(FiscalYear) == 9 ~ get_end_date_from_fiscal_year(FiscalYear),      # Fiscal year (YYYY/YYYY)
        nchar(FiscalYear) == 4 ~ get_end_date_from_calendar_year(FiscalYear),                   # Calendar year (YYYY)
        TRUE ~ NA_character_  # Return NA for invalid formats
      )
    ) %>%
    select(IndicatorID, FiscalYear, IndicatorStartDate, IndicatorEndDate) %>%
    distinct()
  
  # Step 2: Get distinct combinations from the processed data
  processed_check <- processed_data %>%
    select(IndicatorID, FiscalYear, IndicatorStartDate, IndicatorEndDate) %>%
    distinct()
  
  # Step 3: Find IndicatorIDs where combinations do not match
  # Inner join to find mismatches
  comparison <- original_check %>%
    full_join(processed_check, by = c("IndicatorID", "FiscalYear", "IndicatorStartDate", "IndicatorEndDate"), suffix = c("_orig", "_proc")) %>%
    filter(is.na(IndicatorID))
  
  # Find the indicator IDs with issues
  problematic_indicators <- comparison %>%
    pull(IndicatorID)
  
  # Step 4: Return the result
  if (length(problematic_indicators) == 0) {
    print("All time point combinations match between original and processed data.")
  } else {
    print("Mismatching time point combinations found for the following IndicatorID(s):")
    return(problematic_indicators)
  }
}

# Example
check_time_point_combinations(original_data = updated_dt, processed_data = results)



