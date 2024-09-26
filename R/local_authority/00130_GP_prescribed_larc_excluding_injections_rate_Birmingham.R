IndicatorID = 130 
DataQualityID = 2
# DomainID =	3	
# ReferenceID = 91819 
# ICBIndicatorTitle = Increase uptake of Long-acting reversible contraception	
# IndicatorLabel = GP prescribed LARC excluding injections rate / 1,000
# (Birmingham GP data only)

library(dplyr)
library(tidyr)
library(lubridate)

## Paths for data stored on BCC shared drive ##

# larc data base path
larc_path <- "//SVWCCG111/PublicHealth$/.Birmingham City Council/Contracts/1.New Filing System/Finance/"
# BSol GP patient data base path
GP_path <- "//SVWCCG111/PublicHealth$/2.0 KNOWLEDGE EVIDENCE & GOVERNANCE - KEG/2.12 PHM AND RESEARCH/Data/Primary Care/"

# file prefixes and locations
file_info <- data.frame(
  quarter = c(
    "Qtr2 22-23", "Qtr3 22-23", "Qtr4 22-23",
    "Qtr1 23-24", "Qtr2 23-24", "Qtr3 23-24",
    "Qtr4 23-24"),
  location = c(
    "22-23/FP10 Folder/Qtr 2/",
    "22-23/FP10 Folder/Qtr 3/",
    "22-23/FP10 Folder/Qtr 4/",
    "23-24/FP10 Folder/Qtr 1/", 
    "23-24/FP10 Folder/Qtr 2/",
    "23-24/FP10 Folder/Qtr 3/",
    "23-24/FP10 Folder/Qtr 4/")
)

# Prepare empty dataframe to append data to
all_larc_data <- data.frame(
  `Practice Code` = character(),
  quarter = character(),
  total_prescriptions = numeric()
)

# columns to be selected from each spreadsheet
select_cols <- c("Practice Code", "Quantity", "Items")

# loop over all quarters
for (i in 1:nrow(file_info)) {
  quarter_i <- file_info$quarter[i]
  location_i <- file_info$location[i]
  print(quarter_i)
  
  # make file paths
  path_i <- paste(larc_path, location_i, sep = "")
  
  #   Need to glue west and Bsol together
  file_name_both <- paste(path_i, "Sexual Health FP10 BSol ICS ", quarter_i, " - Actual.xlsx", sep = "")
  #print(file_name_both)
  
  # Load implant data 
  implant_i <- readxl::read_excel(file_name_both, sheet = "Implants", skip = 2) %>%
    drop_na(Month) %>%
    select(all_of(select_cols))
  
  # Load IUD data
  IUD_i <- readxl::read_excel(file_name_both, sheet = "IUD", skip = 2)%>%
    drop_na(Month) %>%
    select(all_of(select_cols))
  
  # Combine data and sum for each GP
  this_quarters_data <- rbind(
    implant_i,
    IUD_i
    ) %>% mutate(
      Quantity = as.numeric(Quantity),
      Items = as.numeric(Items),
      total_prescriptions = Quantity * Items
    ) %>%
    group_by(
      `Practice Code`
    ) %>%
    summarise(
      Numerator = sum(total_prescriptions)
    ) %>%
    mutate(
      quarter = quarter_i
    )
    
  # Append to output dataframe
  all_larc_data = rbind(
     all_larc_data, 
     this_quarters_data
     )
  
} # <<<---- Loop ended here

# Load GP patient data
# Group by GP
# Sum all female patients in age range
larc_eligible <- readxl::read_excel(
  paste(GP_path, "BSOL GP Population List - Sept 2023.xlsx", sep =""),
  sheet = "Dataset"
) %>%
  filter(
    Gender_Desc == "Female" &
      ProxyAgeAtEOM >= 15 &
      ProxyAgeAtEOM <= 44 
  ) %>%
  mutate(
    `Practice Code` = GP_Code
  ) %>%
  group_by(`Practice Code`) %>%
  summarize(
    Denominator = sum(Count)
  )

LARC_GP <- all_larc_data %>%
  left_join(
    larc_eligible, by = "Practice Code"
  ) %>%
  mutate(
    IndicatorValue = 1000 * Numerator/Denominator 
  ) %>%
  select(
    c("quarter", "Practice Code", "IndicatorValue", "Numerator", "Denominator")
  ) %>%
  left_join(
    file_info,
    by = "quarter"
  ) %>%
  select(-c("location"))

# Lookup table for GP PCNs and Localities
GP_lookup <- readxl::read_excel("../../data/gp-mega-map-march-2024.xlsx") %>%
  select(c("Practice Code", "Locality", "PCN"))

PCN_lookup <- readxl::read_excel(
  "../../data/OF-Other-Tables.xlsx",
  sheet = "PCN-Locality-Lookup"
)

# OF Aggregation look-up
OF_aggs <- readxl::read_excel(
  "../../data/OF-Other-Tables.xlsx", sheet = "Aggregation"
  )

# Group by PCN
LARC_PCN <- LARC_GP %>%
  left_join(
    GP_lookup,
    by = "Practice Code"
  ) %>%
  group_by(quarter, PCN) %>%
  summarise(
    Numerator = sum(Numerator),
    Denominator = sum(Denominator),
    IndicatorValue = 1000 * Numerator / Denominator
  ) %>%
  drop_na(PCN) %>%
  # Join aggregation ID
  fuzzyjoin::stringdist_join(
    OF_aggs %>%
      filter(AggregationType=="PCN"), 
    by = c("PCN" = "AggregationLabel"),
    method = "jw", #use jw distance metric
    max_dist=0.1, 
    distance_col='dist'
  ) %>%
  ungroup() %>% 
  select(
    c("Numerator", "Denominator", "IndicatorValue",
      "AggregationID", "quarter", "AggregationCode")
  )

# Group by Locality
LARC_Locality <- LARC_PCN %>%
  left_join(
    PCN_lookup,
    by = c("AggregationCode"  = "PCN_Code" ) 
  ) %>%
  group_by(quarter, Locality) %>%
  summarise(
    Numerator = sum(Numerator),
    Denominator = sum(Denominator),
    IndicatorValue = 1000 * Numerator / Denominator
  ) %>%
  ungroup() %>%
  select(
    c("quarter", "Locality", "IndicatorValue", "Numerator", "Denominator")
  ) %>%
  drop_na(Locality) %>%
  # Join aggregation ID
  left_join(
    OF_aggs %>%
      filter(AggregationType=="Locality (registered)"), 
    by = c("Locality" = "AggregationLabel"),
  ) %>% select(
    c("Numerator", "Denominator", "IndicatorValue",
      "AggregationID", "quarter")
  )

# Group for all of Birmingham
LARC_Birmingham <- LARC_GP %>%
  group_by(quarter) %>%
  # Remove cases with no denominator
  drop_na(Denominator) %>%
  summarise(
    Numerator = sum(Numerator),
    Denominator = sum(Denominator),
    IndicatorValue = 1000 * Numerator / Denominator
  ) %>%
  ungroup() %>%
  select(
    c("quarter", "IndicatorValue", "Numerator", "Denominator")
  ) %>%
  mutate(
    AggregationID = 147
  ) %>% select(
    c("Numerator", "Denominator", "IndicatorValue",
      "AggregationID", "quarter")
  )
  
# Combine PCN, locality, and LA parts
output_df <- rbind(
  LARC_PCN %>% select(-c(AggregationCode)),
  LARC_Locality,
  LARC_Birmingham
)  %>%
  mutate(
    # Create empty columns for unknown values/IDs
    ValueID = "",
    InsertDate = Sys.Date(),
    DemographicID = 1,
    DataQualityID = DataQualityID,
    IndicatorID = IndicatorID,
    Year_Start = stringr::str_extract(quarter,"\\d{2}"),
    quarter_number = as.numeric(stringr::str_extract(quarter,"\\d{1}")),
    IndicatorStartDate = as.Date(sprintf("%s/04/01", Year_Start), format="%y/%m/%d") %m+% 
      months(3 * (quarter_number - 1)),
    IndicatorEndDate = as.Date(sprintf("%s/06/30", Year_Start), format="%y/%m/%d") %m+% 
      months(3 * (quarter_number - 1)),
    # Calculate 95% Wilson confidence interval
    Z = qnorm(0.975),
    p_hat = IndicatorValue / 1000,
    a_prime = Numerator + 1,
    LowerCI95 = 1000 * Numerator * (1 - 1/(9*Numerator) - Z/3 * sqrt(1/Numerator))**3/Denominator,
    UpperCI95 = 1000 * a_prime * (1 - 1/(9*a_prime) + Z/3 * sqrt(1/a_prime))**3/Denominator
  ) %>%
  select(
    c("ValueID", "IndicatorID", "InsertDate", 
      "Numerator", "Denominator", "IndicatorValue","LowerCI95", "UpperCI95", 
      "AggregationID", "DemographicID", "DataQualityID",
      "IndicatorStartDate","IndicatorEndDate"
      )
  ) 
  

# Save output
write.csv(output_df, "../../data/output/birmingham-source/data/0130_GP_prescribed_larc_excluding_injections_rate.csv")
