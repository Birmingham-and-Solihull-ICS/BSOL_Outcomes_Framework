library(dplyr)
library(tidyr)

# base path
path <- "//SVWCCG111/PublicHealth$/.Birmingham City Council/Contracts/1.New Filing System/Finance/"

file_prefex = list(
  "Qtr1 23-24" = "23-24/FP10 Folder/Qtr 1/",
  "Qtr2 23-24" = "23-24/FP10 Folder/Qtr 2/",
  "Qtr3 23-24" = "23-24/FP10 Folder/Qtr 3/"
)

all_larc_data <- data.frame(
  `Practice Code` = character(),
  Quarter = character(),
  total_prescriptions = numeric()
)

select_cols <- c("Quarter", "Practice Code", "Quantity", "Items")

for (quarter_i in names(file_prefex)) {
  cat("\n")
  print(quarter_i)
  
  # make file paths
  path_i <- paste(path, file_prefex[quarter_i], sep = "")
  
  #   Need to glue west and Bsol together
  file_name_both <- paste(path_i, "Sexual Health FP10 BSol ICS ", quarter_i, " - Actual.xlsx", sep = "")
  print(paste("Sexual Health FP10 BSol ICS ", quarter_i, " - Actual", sep = ""))
  
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
      total_prescriptions = sum(total_prescriptions)
    ) %>%
    mutate(
      Quarter = quarter_i
    )
    
  # Append to output dataframe
  all_larc_data = rbind(
     all_larc_data, 
     this_quarters_data
     )
  
} # <<<---- Loop ended here


# Load patient data

# Group by GP and sum all female patients in age range

# Join those data frames

# Normalise prescriptions by patient numbers

# Group by PCN

# Group by Locality


# Combined for IDG (Includes PCN and Locality)

# Save ([AggID,] Date, Value, Numerator, Denominator, [Confidence Intervals])

# Combined for community services dashboard

#dataset_names <- list('GP' = by_GP, 'PCN' = by_PCN, 'Locality' = by_Locality)
#write.xlsx(dataset_names, file = 'save-name.xlsx')

