# Combine BCC data
library(dplyr)

#################################################################
###                   Combine Value Data                      ###
#################################################################

# Get paths to all BCC data files
path <- "../../data/output/birmingham-source/data/"
file_paths <- paste(path, list.files(path), sep = "")

# Load data
dfs <- lapply(file_paths, read.csv)

for (i in 1:length(dfs)) {
  
  id_i <- unique(dfs[[i]]$IndicatorID)
  # Fix demographicID for NDTMS indicators
   if (id_i[[1]] == 118 | id_i[[1]] == 119) {
    dfs[[i]] <- dfs[[i]] %>%
      mutate(
        DemographicID = case_when(
          DemographicID == "Male" ~ 3,
          DemographicID == "Female" ~ 2,
          DemographicID == "Persons" ~ 1,     
          # NAs will be replaced with ID values later
          DemographicID == "18-29" ~ 7404,
          DemographicID == "30-49" ~ 7405,
          DemographicID == "50+" ~ 7406,
          TRUE ~ NA
        ),
        DataQualityID = 1,
        InsertDate = "2024-04-30"
      )
  }
  
  # select and reorder columns so they match
  dfs[[i]] <- dfs[[i]] %>%
    mutate(
      # Standardise insert date formats
      InsertDate = case_when(
        grepl("\\d{2}/\\d{2}/\\d{4}", InsertDate) ~ as.Date(InsertDate, fmt = "%d/%m/%Y"),
        grepl("\\d{4}-\\d{2}-\\d{2}", InsertDate) ~ as.Date(InsertDate),
        TRUE ~ NA
      )
      ) %>%
    select(c("ValueID", "IndicatorID", "InsertDate", "Numerator", "Denominator",       
             "IndicatorValue", "LowerCI95", "UpperCI95", "AggregationID", 
             "DemographicID", "DataQualityID", "IndicatorStartDate", "IndicatorEndDate" ))
  
}

# Combine dfs
OF_values <- bind_rows(dfs)
# Remove any value IDs
OF_values$ValueID = NA

# look at level of missing data
missing_data_check <- OF_values %>% summarise(across(everything(), ~ sum(is.na(.))))
cat("Value missing data check:")
print(missing_data_check)

data_save_name <- sprintf(
  "../../data/output/birmingham-OF-values-%s.csv",
  as.character(Sys.Date())
)

cat(paste("\nSaving data as:", data_save_name))
# Save output
write.csv(OF_values, 
          data_save_name,
          row.names = FALSE)


#################################################################
###                   Combine meta Data                       ###
#################################################################

# Get paths to all BCC data files
meta_path <- "../../data/output/birmingham-source/meta/"
meta_file_paths <- paste(meta_path, list.files(meta_path), sep = "")

# Load data
meta_dfs <- lapply(meta_file_paths, read.csv)

# Combine dfs
OF_meta <- bind_rows(meta_dfs)

# Remove all HTML tags
OF_meta$MetaValue <- gsub("<.*?>", "", OF_meta$MetaValue)

# look at level of missing data
cat("\nMeta missing data check:")
missing_meta_check <- OF_meta %>% summarise(across(everything(), ~ sum(is.na(.))))
print(missing_meta_check)

meta_save_name <- sprintf(
  "../../data/output/birmingham-OF-meta-%s.csv",
  as.character(Sys.Date())
)

cat(paste("\nSaving meta as:", data_save_name))
# Save OF_meta
write.csv(OF_meta, 
          meta_save_name,
          row.names = FALSE)

#################################################################
###                    Additional Checks                      ###
#################################################################

# Check that we have meta for all values
value_IndicatorIDs <- sort(unique(OF_values$IndicatorID))
meta_IndicatorIDs <- sort(unique(OF_meta$IndicatorID))

ID_match_check1 <- all(meta_IndicatorIDs %in% value_IndicatorIDs)
ID_match_check2 <- all(value_IndicatorIDs %in% meta_IndicatorIDs)
if (!(ID_match_check1 & ID_match_check2)) {
  stop("Value and meta IDs do not match!")
} else{
  cat("\nValue and meta IDs match: True")
  cat("Indicator IDs in final output:")
  cat(value_IndicatorIDs)
}

