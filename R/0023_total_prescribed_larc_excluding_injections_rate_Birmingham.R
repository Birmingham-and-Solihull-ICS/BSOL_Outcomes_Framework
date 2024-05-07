IndicatorID = 23 
# DomainID =	3	
# ReferenceID = 92254 (Actually 91819 since GP prescribed only)
# ICBIndicatorTitle = Increase uptake of Long-acting reversible contraception	
# IndicatorLabel Total prescribed LARC excluding injections rate / 1,000
# (Birmingham GP data only)

library(dplyr)
library(tidyr)

## Paths for data stored on BCC shared drive ##

# larc data base path
larc_path <- "//SVWCCG111/PublicHealth$/.Birmingham City Council/Contracts/1.New Filing System/Finance/"
# BSol GP patient data base path
GP_path <- "//SVWCCG111/PublicHealth$/2.0 KNOWLEDGE EVIDENCE & GOVERNANCE - KEG/2.12 PHM AND RESEARCH/Data/Primary Care/"

# file prefixes and locations
file_info <- data.frame(
  quarter = c("Qtr1 23-24", "Qtr2 23-24", "Qtr3 23-24"),
  location = c("23-24/FP10 Folder/Qtr 1/", "23-24/FP10 Folder/Qtr 2/",
               "23-24/FP10 Folder/Qtr 3/"),
  IndicatorStartDate = as.Date(c("01/04/2023", "01/07/2023", "01/10/2023"), 
                               format = "%d/%m/%Y"),
  IndicatorEndDate = as.Date(c("30/06/2023", "30/09/2023", "31/01/2024"), 
                               format = "%d/%m/%Y")
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
  #print(paste("Sexual Health FP10 BSol ICS ", quarter_i, " - Actual", sep = ""))
  
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
GP_lookup <- readxl::read_excel("../data/gp-mega-map-march-2024.xlsx") %>%
  select(c("Practice Code", "Locality", "PCN"))

# OF Aggregation look-up
OF_aggs <- readxl::read_excel(
  "../data/OF-Other-Tables.xlsx", sheet = "Aggregation"
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
  ungroup() %>%
  select(
    c("quarter", "PCN", "IndicatorValue", "Numerator", "Denominator")
  ) %>%
  left_join(
    file_info,
    by = "quarter"
  ) %>%
  select(-c("location", "quarter"))%>%
  drop_na(PCN) %>%
  # Join aggregation ID
  fuzzyjoin::stringdist_join(
    OF_aggs %>%
      filter(AggregationType=="PCN"), 
    by = c("PCN" = "AggregationLabel"),
    method = "jw", #use jw distance metric
    max_dist=0.1, 
    distance_col='dist'
  )%>%
  group_by(PCN) %>%
  slice_min(order_by=dist, n=1) %>%
  ungroup() %>% select(
    c("Numerator", "Denominator", "IndicatorValue",
      "AggregationID", "IndicatorStartDate","IndicatorEndDate")
  )

# Group by Locality
LARC_Locality <- LARC_GP %>%
  left_join(
    GP_lookup,
    by = "Practice Code"
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
  left_join(
    file_info,
    by = "quarter"
  ) %>%
  select(-c("location", "quarter")) %>%
  drop_na(Locality) %>%
  # Join aggregation ID
  left_join(
    OF_aggs %>%
      filter(AggregationType=="Locality"), 
    by = c("Locality" = "AggregationLabel"),
  ) %>% select(
    c("Numerator", "Denominator", "IndicatorValue",
      "AggregationID", "IndicatorStartDate","IndicatorEndDate")
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
  left_join(
    file_info,
    by = "quarter"
  ) %>%
  select(-c("location", "quarter")) %>%
  mutate(
    AggregationID = 135
  ) %>% select(
    c("Numerator", "Denominator", "IndicatorValue",
      "AggregationID", "IndicatorStartDate","IndicatorEndDate")
  )
  
# Combine PCN, locality, and LA parts
output_df <- rbind(
  LARC_PCN,
  LARC_Locality,
  LARC_Birmingham
) %>%
  mutate(
    # Create empty columns for unknown values/IDs
    ValueID = "",
    InsertDate = "",
    DemographicID = "",
    DataQualityID = "",
    IndicatorID = IndicatorID,
    # Calculate 95% Wilson confidence interval
    Z = qnorm(0.975),
    p_hat = IndicatorValue / 1000,
    LowerCl95 = 1000 * (p_hat + Z^2/(2*Denominator) - Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
    UpperCl95 = 1000 * (p_hat + Z^2/(2*Denominator) + Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
  ) %>%
  select(
    c("ValueID", "IndicatorID", "InsertDate", 
      "Numerator", "Denominator", "IndicatorValue","LowerCl95", "UpperCl95", 
      "AggregationID", "DemographicID", "DataQualityID",
      "IndicatorStartDate","IndicatorEndDate")
  )

# Save output
writexl::write_xlsx(output_df, "../data/output/0023_total_prescribed_larc_excluding_injections_rate.xlsx")