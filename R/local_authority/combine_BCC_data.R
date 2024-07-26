# Combine BCC data

# Get paths to all BCC data files
path <- "../data/output/birmingham-source/"
file_paths <- paste(path, list.files(path), sep = "")

# Get ids
ids <- unlist(lapply(list.files(path), substr, 1, 4))

# Load data
dfs <- lapply(file_paths, readxl::read_excel)

# OF Aggregation look-up
OF_aggs <- readxl::read_excel(
  "../data/OF-Other-Tables.xlsx", sheet = "Aggregation"
)

for (i in 1:length(ids)) {
  print(ids[[i]])
  
  # Join aggregation IDs to Health Check data
  if (ids[[i]] == "0071") {
    dfs[[i]] <- dfs[[i]] %>%
      mutate(index = row_number()) %>%
      fuzzyjoin::stringdist_join(
        OF_aggs %>%
          filter(AggregationType %in% c("PCN","Locality (resident)", "Local Authority")), 
        by = join_by("AggregationLabel"),
        method = "jw", #use jw distance metric
        max_dist=0.1, 
        distance_col='dist'
      )%>%
      group_by(index) %>%
      slice_min(order_by=dist, n=1) %>%
      ungroup()
  }
  
  # select and reorder columns so they match
  dfs[[i]] <- dfs[[i]] %>%
    select(c("ValueID", "IndicatorID", "InsertDate", "Numerator", "Denominator",       
             "IndicatorValue", "LowerCI95", "UpperCI95", "AggregationID", 
             "DemographicID", "DataQualityID", "IndicatorStartDate", "IndicatorEndDate" ))
  }

# Combine dfs
OF_values <- bind_rows(dfs)

# Save output
writexl::write_xlsx(OF_values, "../data/output/birmingham-OF-values-24-05-24.xlsx")



