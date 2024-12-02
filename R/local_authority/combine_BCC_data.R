# Combine BCC data
library(dplyr)
library(readr)

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
        IndicatorValue = 1000 * Numerator / Denominator,
        a_prime = Numerator + 1,
        Z = qnorm(0.975),
        LowerCI95 = 1000 * Numerator * (1 - 1/(9*Numerator) - Z/3 * sqrt(1/Numerator))**3/Denominator,
        UpperCI95 = 1000 * a_prime * (1 - 1/(9*a_prime) + Z/3 * sqrt(1/a_prime))**3/Denominator,
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
        InsertDate = as.Date("30/04/2024", format  = "%d/%m/%Y") 
      ) %>%
      select(-c(a_prime, Z))
  }
  
  # select and reorder columns so they match
  dfs[[i]] <- dfs[[i]] %>%
    mutate(
      # Standardise insert date formats
      InsertDate = case_when(
        grepl("\\d{2}/\\d{2}/\\d{4}", InsertDate) ~ as.Date(InsertDate, format  = "%d/%m/%Y"),
        grepl("\\d{4}-\\d{2}-\\d{2}", InsertDate) ~ as.Date(InsertDate, format  = "%Y-%m-%d"),
        TRUE ~ NA
      ),
      IndicatorStartDate = case_when(
        grepl("\\d{2}/\\d{2}/\\d{4}", IndicatorStartDate) ~ as.Date(IndicatorStartDate, format  = "%d/%m/%Y"),
        grepl("\\d{4}-\\d{2}-\\d{2}", IndicatorStartDate) ~ as.Date(IndicatorStartDate, format  = "%Y-%m-%d"),
        TRUE ~ NA
      ),
      IndicatorEndDate = case_when(
        grepl("\\d{2}/\\d{2}/\\d{4}", IndicatorEndDate) ~ as.Date(IndicatorEndDate, format  = "%d/%m/%Y"),
        grepl("\\d{4}-\\d{2}-\\d{2}", IndicatorEndDate) ~ as.Date(IndicatorEndDate, format  = "%Y-%m-%d"),
        TRUE ~ NA
      )
      ) %>%
    select(c("ValueID", "IndicatorID", "InsertDate", "Numerator", "Denominator",       
             "IndicatorValue", "LowerCI95", "UpperCI95", "AggregationID", 
             "DemographicID", "DataQualityID", "IndicatorStartDate", "IndicatorEndDate" ))
  
}
bind_rows(dfs)
# Combine dfs
OF_values <- bind_rows(dfs) %>%
  # Work around the Byar's 0 count problem
  mutate(
    LowerCI95 = case_when(
      is.na(LowerCI95) ~ 0,
      TRUE ~ LowerCI95
    )
  )
# Remove any value IDs
OF_values$ValueID = NA


#################################################################
###                Solihull as a Locality                     ###
#################################################################

solihull_as_LA <- OF_values %>%
  filter(
    IndicatorID %in% c(8,9) &
      AggregationID == 146
  ) %>%
  mutate(
    AggregationID = 134
  )

OF_values <- rbind(OF_values, solihull_as_LA) %>%
  arrange(IndicatorID)

#################################################################
###                   Combine meta Data                       ###
#################################################################

# Get paths to all BCC data files
meta_path <- "../../data/output/birmingham-source/meta/"
meta_file_paths <- paste(meta_path, list.files(meta_path), sep = "")

# Load data
meta_dfs <- lapply(meta_file_paths, read.csv)

# Combine dfs
OF_meta <- bind_rows(meta_dfs) %>%
  select(-c("X"))

# Remove all HTML tags
OF_meta$MetaValue <- gsub("<.*?>", "", OF_meta$MetaValue)

#################################################################
###                      Data Checks                          ###
#################################################################

# look at level of missing data
missing_data_check <- OF_values %>% 
  summarise(
    across(everything(), ~ sum(is.na(.)))
    )
cat("Value missing data check:\n")
print(missing_data_check)

# Print any problem IDs
for (col in colnames(missing_data_check)[2:13]) {
  if (missing_data_check[col] > 0) {
    problemIDs <- OF_values %>%
      select(c(IndicatorID, !!as.symbol(col))) %>%
      filter(is.na(!!as.symbol(col))) %>%
      distinct() %>%
      pull(IndicatorID)
    print(sprintf("%s missing for IndicatorIDs: %s", col, list(problemIDs)))
  }
}

# look at level of missing data
cat("\nMeta missing data check:\n")
missing_meta_check <- OF_meta %>% summarise(across(everything(), ~ sum(is.na(.))))
print(missing_meta_check)

# Check that we have meta for all values
value_IndicatorIDs <- sort(unique(OF_values$IndicatorID))
meta_IndicatorIDs <- sort(unique(OF_meta$IndicatorID))

ID_match_check1 <- all(meta_IndicatorIDs %in% value_IndicatorIDs)
ID_match_check2 <- all(value_IndicatorIDs %in% meta_IndicatorIDs)
if (!(ID_match_check1 & ID_match_check2)) {
  stop("Value and meta IDs do not match!")
} else{
  cat("\nValue and meta IDs match: True")
  cat("Indicator IDs in final output:\n")
  print(value_IndicatorIDs)
}

# Sense check on confidence intervals
if ((any(OF_values$LowerCI95 > OF_values$IndicatorValue))) {
  stop("One or more LowerCI95 > IndicatorValue")
} else if ((any(OF_values$UpperCI95 < OF_values$IndicatorValue))) {
  stop("One or more UpperCI95 < IndicatorValue")
} 

# Check that dates make sense
if (min(OF_values$IndicatorStartDate) < as.Date("01/01/1997",format = "%d/%m/%Y")) {
  stop("Minimum date out before 01/01/1997.")
} else if (max(OF_values$IndicatorStartDate) > Sys.Date()) {
  stop("Maximum dates is in the future.")
}

# Check geographies available for each indicator
aggregation_types <- readxl::read_excel(
  "../../data/OF-Other-Tables.xlsx",
  sheet = "Aggregation"
) %>%
  mutate(
    AggregationType = case_when(
      AggregationID == 146 ~ "LA-Solihull",
      AggregationID == 147 ~ "LA-Birmingham",
      TRUE ~ AggregationType
    )
  ) %>%
  select(
    AggregationID, 
    AggregationType
  )

geography_check <- OF_values %>%
  left_join(
    aggregation_types,
    by = join_by(AggregationID)
  ) %>%
  count(IndicatorID, AggregationType) %>%
  tidyr::pivot_wider(
    id_cols = IndicatorID,
    names_from = AggregationType,
    values_from = n
  ) %>%
  select(
    IndicatorID, PCN, `Locality (registered)`, 
    Ward, `Constituency`,`Locality (resident)`,
    `LA-Solihull`, `LA-Birmingham`, ICB, England
  )
write.csv(
  geography_check,
  "../../data/LA-indicator-geog-checks.csv",
  row.names = FALSE,
  na = ""
  )

# Check that each indicator has a definition 
missing_definition <- OF_meta %>%
  filter(ItemID==7 & is.na(MetaValue)) %>%
  select(
    c(IndicatorID)
  ) %>% 
  arrange(IndicatorID) %>%
  distinct() %>%
  pull(IndicatorID)

if (length(missing_definition) > 0) {
  print(
    sprintf("Definition missing for IndicatorIDs: %s", list(missing_definition))
  )
}

# Find any outliers
outlier_checks <- OF_values %>%
  group_by(IndicatorID) %>%
  summarise(
    median = mean(IndicatorValue),
    iqr = IQR(IndicatorValue),
    Q3 = quantile(IndicatorValue, 0.75),
    Q1 = quantile(IndicatorValue, 0.25),
    nvals = n(),
    min = min(IndicatorValue),
    max = max(IndicatorValue),
    outliers = sum(
      IndicatorValue < Q1 - 1.5*iqr |
        IndicatorValue > Q3 + 1.5*iqr   
    )
  ) %>%
  select(
    -c(Q1, Q3)
  ) %>%
  filter(
    outliers > 0
  )

cat("\nPotential outlier check:\n")
print(outlier_checks)

#################################################################
###                      Save Data                            ###
#################################################################

data_save_name <- sprintf(
  "../../data/output/birmingham-OF-values-%s.csv",
  as.character(Sys.Date())
)

cat(paste("\nSaving data as:", data_save_name))
# Save output
write_csv(OF_values, 
          data_save_name)

meta_save_name <- sprintf(
  "../../data/output/birmingham-OF-meta-%s.csv",
  as.character(Sys.Date())
)

cat(paste("\nSaving meta as:", meta_save_name))
# Save OF_meta
write_csv(OF_meta, 
          meta_save_name)


print("Done.")