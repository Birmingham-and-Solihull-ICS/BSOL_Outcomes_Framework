# Combine BCC data

# Get paths to all BCC data files
path <- "../../data/output/birmingham-source/"
file_paths <- paste(path, list.files(path), sep = "")

# Get ids
ids <- unlist(lapply(list.files(path), substr, 1, 4))

# Load data
dfs <- lapply(file_paths, read.csv)

# OF Aggregation look-up
OF_aggs <- readxl::read_excel(
  "../../data/OF-Other-Tables.xlsx", sheet = "Aggregation"
)

for (i in 1:length(ids)) {
  print(ids[[i]])
  
  # Fix demographicID for NDTMS indicators
  if (ids[[i]] %in% c("0118", "0119")) {
    dfs[[i]] <- dfs[[i]] %>%
      mutate(
        DemographicID = case_when(
          DemographicID == "Male" ~ 3,
          DemographicID == "Female" ~ 2,
          DemographicID == "Persons" ~ 1,     
          # NAs will be replaced with ID values later
          DemographicID == "18-29" ~ NA,
          DemographicID == "30-49" ~ NA,
          DemographicID == "50+" ~ NA,
          TRUE ~ NA
        ),
        DataQualityID = 1
      )
  }

  # select and reorder columns so they match
  dfs[[i]] <- dfs[[i]] %>%
    select(c("ValueID", "IndicatorID", "InsertDate", "Numerator", "Denominator",       
             "IndicatorValue", "LowerCI95", "UpperCI95", "AggregationID", 
             "DemographicID", "DataQualityID", "IndicatorStartDate", "IndicatorEndDate" ))
  }

# Combine dfs
OF_values <- bind_rows(dfs)
# Remove any value IDs
OF_values$ValueID = ""

# Save output
write.csv(OF_values, "../../data/output/birmingham-OF-values-28-07-24.csv",
          row.names = FALSE)



