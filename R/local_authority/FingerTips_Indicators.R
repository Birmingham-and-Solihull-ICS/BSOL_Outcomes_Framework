library(fingertipsR)
library(dplyr)
library(data.table)
library(readxl)

# Load indicator list
ids <- read.csv("../../data/LA_FingerTips_Indicators.csv")

# Load GP-PCN-Locality-LA lookup data
GP_lookup <- read.csv("../../data/better-GP-lookup-march-2024.csv") %>%
  select(-c(Type, PCN, Locality, LA))

#################################################################
##                        Functions                            ##
#################################################################

## Data collection functions ##

fetch_data <- function(FingerTips_id, AreaTypeID) {
  # Fetch data from FingerTips using API
  data <- fingertips_data(
    AreaTypeID = AreaTypeID, 
    IndicatorID = FingerTips_id
  )
  
  meta_data <- indicator_metadata(
    IndicatorID = FingerTips_id
  ) %>%
    mutate(
      `Source of numerator` = `Source of numerator...10`,
      `Source of denominator`  = `Source of denominator...12`,
      `External Reference` = Links,
      `Rate Type` = `Value type`,
    ) %>%
    select(
      c(Caveats, `Definition of denominator`, `Definition of numerator`,
        `External Reference`, Polarity, `Simple Definition`,
        `Source of numerator`, `Source of denominator`, Unit, Methodology)
    )
  
  return(
    list("data" = data,"meta" = meta_data)
    )
}

get_magnitude <- function(meta) {
  # Extract the numerical value of the magnitude
  unit = meta %>% pull("Unit")
  magnitude = list(
    "%"           = 1e2,
    "per 100"     = 1e2,
    "per 1,000"   = 1e3,
    "per 10,000"  = 1e4,
    "per 100,000" = 1e5
  )
  return(magnitude[[unit]])
}

get_CI_method <- function(meta) {
  # Estimate the confidence interval method based on the methodology
  #   - Rates -> Byar's Method
  #   - Otherwise -> Wilson's
  methodology = meta %>% pull("Methodology")
  if (grepl("rate", tolower(methodology))) {
    return("Byar's Method")
  } else{
    return("Wilson's Method")
  }
}

process_LA_data <- function(FingerTips_id) {
  
  data_and_meta <- fetch_data(FingerTips_id, AreaTypeID = 402)
  data <- data_and_meta[["data"]]
  meta <- data_and_meta[["meta"]]
  # delete list to save space
  rm(data_and_meta)
  
  # restrict to needed columns
  data <- data %>%
    mutate(
      LowerCI95 = LowerCI95.0limit, 
      UpperCI95 = UpperCI95.0limit
      ) %>%
    select(
      AreaCode, Timeperiod, Sex, Age, Count, Denominator, Value, 
      LowerCI95, UpperCI95
    ) %>%
    mutate(
      magnitude = get_magnitude(meta),
      CI_method = get_CI_method(meta)
    )
  
  # England data
  df_eng <- data %>% 
    filter(AreaCode == "E92000001")
  
  # Filter for Birmingham and Solihull
  df_LA <- data %>%
    filter(AreaCode %in% c("E08000029", "E08000025"))
  
  # Filter for Birmingham and Solihull
  df_ICB <- df_LA %>%
    group_by(Timeperiod,  Sex, Age, magnitude, CI_method) %>%
    summarise(
      Count = sum(Count),
      Denominator = sum(Denominator),
      .groups = 'keep'
    ) %>%
    mutate(
      AreaCode = "E38000258",
      p_hat = Count / Denominator,
      Value = magnitude * p_hat,
      # for use in Byar's method
      a_prime = p_hat + 0.5,
      # Calculate errors
      Z = qnorm(0.975),
      LowerCI95 = case_when(
        CI_method == "Wilson's Method" ~ magnitude * (p_hat + Z^2/(2*Denominator) - Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
        CI_method == "Byar's Method" ~ magnitude * a_prime * (1 - 1/(9*a_prime) + Z/3 * sqrt(1/a_prime))**3/Denominator
      ),
      UpperCI95 = case_when(
        CI_method == "Wilson's Method" ~ magnitude * (p_hat + Z^2/(2*Denominator) + Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
        CI_method == "Byar's Method" ~ magnitude * a_prime * (1 - 1/(9*a_prime) - Z/3 * sqrt(1/a_prime))**3/Denominator
      )
    ) %>% 
    ungroup() %>%
    select(
      AreaCode, Timeperiod, Sex, Age, Count, Denominator, Value, 
      LowerCI95, UpperCI95, magnitude, CI_method
    )
  
  # 
  combined_data <- rbindlist(
    list(
      df_LA, df_ICB, df_eng
    )
  ) %>% 
    select(-c(magnitude, CI_method))
  
  output <- list(
    "data" = combined_data,
    "meta" = meta
  )
  
  return(output)
}

process_GP_data <- function(FingerTips_id) {
  
  data_and_meta <- fetch_data(FingerTips_id, AreaTypeID = 7)
  data <- data_and_meta[["data"]]
  meta <- data_and_meta[["meta"]]
  # delete list to save space
  rm(data_and_meta)
  
  # restrict to needed columns
  data <- data %>%
    mutate(
      LowerCI95 = LowerCI95.0limit, 
      UpperCI95 = UpperCI95.0limit
    ) %>%
    select(
      AreaCode, Timeperiod, Sex, Age, Count, Denominator, Value, 
      LowerCI95, UpperCI95
    ) %>%
    mutate(
      magnitude = get_magnitude(meta),
      CI_method = get_CI_method(meta)
    )
  
  # England data
  df_eng <- data %>% 
    filter(AreaCode == "E92000001") %>%
    select(
      AreaCode, Timeperiod, Sex, Age, Count, Denominator, Value, 
      LowerCI95, UpperCI95, magnitude, CI_method
    )
  
  # Aggregate for PCNs
  df_PCN <- data %>%
    inner_join(GP_lookup, 
               join_by(AreaCode == "Practice_Code")) %>%
    group_by(PCN_Code, Timeperiod,  Sex, Age, magnitude, CI_method) %>%
    summarise(
      Count = sum(Count),
      Denominator = sum(Denominator),
      .groups = 'keep'
    ) %>%
    mutate(
      AreaCode = PCN_Code,
      p_hat = Count / Denominator,
      Value = magnitude * p_hat,
      # for use in Byar's method
      a_prime = p_hat + 0.5,
      # Calculate errors
      Z = qnorm(0.975),
      LowerCI95 = case_when(
        CI_method == "Wilson's Method" ~ magnitude * (p_hat + Z^2/(2*Denominator) - Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
        CI_method == "Byar's Method" ~ magnitude * a_prime * (1 - 1/(9*a_prime) + Z/3 * sqrt(1/a_prime))**3/Denominator
      ),
      UpperCI95 = case_when(
        CI_method == "Wilson's Method" ~ magnitude * (p_hat + Z^2/(2*Denominator) + Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
        CI_method == "Byar's Method" ~ magnitude * a_prime * (1 - 1/(9*a_prime) - Z/3 * sqrt(1/a_prime))**3/Denominator
      )
    ) %>% 
    ungroup() %>%
    select(
      AreaCode, Timeperiod, Sex, Age, Count, Denominator, Value, 
      LowerCI95, UpperCI95, magnitude, CI_method
    )
      
  # Aggregate for Localities
  df_Locality <- data %>%
    inner_join(GP_lookup, 
               join_by(AreaCode == "Practice_Code")) %>%
    group_by(LA_Code, Timeperiod, Sex, Age,  magnitude, CI_method) %>%
    summarise(
      Count = sum(Count),
      Denominator = sum(Denominator),
      .groups = 'keep'
    ) %>%
    mutate(
      AreaCode = LA_Code,
      p_hat = Count / Denominator,
      Value = magnitude * p_hat,
      # for use in Byar's method
      a_prime = p_hat + 0.5,
      # Calculate errors
      Z = qnorm(0.975),
      LowerCI95 = case_when(
        CI_method == "Wilson's Method" ~ magnitude * (p_hat + Z^2/(2*Denominator) - Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
        CI_method == "Byar's Method" ~ magnitude * a_prime * (1 - 1/(9*a_prime) + Z/3 * sqrt(1/a_prime))**3/Denominator
      ),
      UpperCI95 = case_when(
        CI_method == "Wilson's Method" ~ magnitude * (p_hat + Z^2/(2*Denominator) + Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
        CI_method == "Byar's Method" ~ magnitude * a_prime * (1 - 1/(9*a_prime) - Z/3 * sqrt(1/a_prime))**3/Denominator
      )
    ) %>% 
    ungroup() %>%
    select(
      AreaCode, Timeperiod, Sex, Age, Count, Denominator, Value, 
      LowerCI95, UpperCI95, magnitude, CI_method
    )

  # Aggregate for local authorities
  df_LA <- data %>%
    inner_join(GP_lookup, 
               join_by(AreaCode == "Practice_Code")) %>%
    group_by(LA_Code, Timeperiod, Sex, Age, magnitude, CI_method) %>%
    summarise(
      Count = sum(Count),
      Denominator = sum(Denominator),
      .groups = 'keep'
    ) %>%
    mutate(
      AreaCode = LA_Code,
      p_hat = Count / Denominator,
      Value = magnitude * p_hat,
      # for use in Byar's method
      a_prime = p_hat + 0.5,
      # Calculate errors
      Z = qnorm(0.975),
      LowerCI95 = case_when(
        CI_method == "Wilson's Method" ~ magnitude * (p_hat + Z^2/(2*Denominator) - Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
        CI_method == "Byar's Method" ~ magnitude * a_prime * (1 - 1/(9*a_prime) + Z/3 * sqrt(1/a_prime))**3/Denominator
      ),
      UpperCI95 = case_when(
        CI_method == "Wilson's Method" ~ magnitude * (p_hat + Z^2/(2*Denominator) + Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
        CI_method == "Byar's Method" ~ magnitude * a_prime * (1 - 1/(9*a_prime) - Z/3 * sqrt(1/a_prime))**3/Denominator
      )
    ) %>% 
    ungroup() %>%
    select(
      AreaCode, Timeperiod, Sex, Age, Count, Denominator, Value, 
      LowerCI95, UpperCI95, magnitude, CI_method
    )
  
  # Aggregate for BSol ICB
  df_ICB <- data %>%
    inner_join(GP_lookup, 
               join_by(AreaCode == "Practice_Code")) %>%
    group_by(Timeperiod, Sex, Age,  magnitude, CI_method) %>%
    summarise(
      Count = sum(Count),
      Denominator = sum(Denominator),
      .groups = 'keep'
    ) %>%
    mutate(
      AreaCode = "E38000258",
      p_hat = Count / Denominator,
      Value = magnitude * p_hat,
      # for use in Byar's method
      a_prime = p_hat + 0.5,
      # Calculate errors
      Z = qnorm(0.975),
      LowerCI95 = case_when(
        CI_method == "Wilson's Method" ~ magnitude * (p_hat + Z^2/(2*Denominator) - Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
        CI_method == "Byar's Method" ~ magnitude * a_prime * (1 - 1/(9*a_prime) + Z/3 * sqrt(1/a_prime))**3/Denominator
      ),
      UpperCI95 = case_when(
        CI_method == "Wilson's Method" ~ magnitude * (p_hat + Z^2/(2*Denominator) + Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
        CI_method == "Byar's Method" ~ magnitude * a_prime * (1 - 1/(9*a_prime) - Z/3 * sqrt(1/a_prime))**3/Denominator
      )
    ) %>% 
    ungroup() %>%
    select(
      AreaCode, Timeperiod, Sex, Age, Count, Denominator, Value, 
      LowerCI95, UpperCI95, magnitude, CI_method
    )
  
  # 
  combined_data <- rbindlist(
    list(
      df_PCN, df_Locality, df_LA, df_ICB, df_eng
    )
  ) %>% 
    select(-c(magnitude, CI_method))
  
  output <- list(
    "data" = combined_data,
    "meta" = meta
  )
  
  return(output)
}

## Data processing functions ##

start_date <- function(date) {
  
  # If financial year e.g. 2021/22
  if (grepl("^\\d{4}/\\d{2}$",date)) {
    Year_Start = stringr::str_extract(date,"^\\d{4}")
    start_date <- as.Date(sprintf("%s/04/01", Year_Start))
  } 
  # If calendar year e.g. 2021
  else if (grepl("^\\d{4}$",date)) {
    start_date <- as.Date(sprintf("%s/01/01", date))
  }
  # Otherwise raise error
  else{
    stop(error = "Can't convert date. Unexpected format for TimePeriod.")
  }
  return(start_date)
}

end_date <- function(date) {
  
  # If financial year e.g. 2021/22
  if (grepl("^\\d{4}/\\d{2}$",date)) {
    Year_Start = stringr::str_extract(date,"^\\d{4}")
    start_date <- as.Date(sprintf("%i/03/31", as.numeric(Year_Start) + 1 ))
  } 
  # If calendar year e.g. 2021
  else if (grepl("^\\d{4}$",date)) {
    start_date <- as.Date(sprintf("%s/12/31", date))
  }
  # Otherwise raise error
  else{
    stop(error = "Can't convert date. Unexpected format for TimePeriod.")
  }
  return(start_date)
}

#################################################################
##                Collect Data from FingerTips                 ##
#################################################################


all_data <- list()
all_meta <- list()

for (i in 1:nrow(ids)){
  
  if (ids$AreaType[i] == "GP") {
    data_i <- process_GP_data(ids$FingerTips_id[[i]])
  } 
  else if (ids$AreaType[i] == "LA") {
    data_i <- process_LA_data(ids$FingerTips_id[[i]])
  }
  else {
    stop(error = "Unexpected AreaTypeID. Only GP (7) and LA (402) implemented.")
  }
  # Add in our indicator ID
  data_i[["data"]]$IndicatorID <- ids$IndicatorID[[i]]
  data_i[["meta"]]$IndicatorID <- ids$IndicatorID[[i]]  

  # Store data for ID in list
  all_data[[i]] <- data_i[["data"]]
  all_meta[[i]] <- data_i[["meta"]] 
}

# Combine all indicator data and meta data
collected_data <- rbindlist(all_data)
collected_meta <- rbindlist(all_meta)

#################################################################
##                Mutate into Staging Table                    ##
#################################################################

# Load ID lookup tables

demographics <- readxl::read_excel(
  "../../data/OF-Other-Tables.xlsx",
  sheet = "Demographic"
) %>% 
  select(c(DemographicID, DemographicLabel))

aggregations <- readxl::read_excel(
  "../../data/OF-Other-Tables.xlsx",
  sheet = "Aggregation"
) %>% 
  select(c(AggregationID,	AggregationCode))

meta <- readxl::read_excel(
  "../../data/OF-Other-Tables.xlsx",
  sheet = "Meta"
)

# Process value data

output_data <- collected_data %>%
  filter(
    # Remove rows with no data
    !is.na(Value)
  ) %>%
  mutate(
    ValueID = "",
    # Calculate start and end dates
    IndicatorStartDate = as.Date(sapply(Timeperiod, start_date)),
    IndicatorEndDate = as.Date(sapply(Timeperiod, end_date)),
    # Set insert date to today
    InsertDate = Sys.Date(),
    # No data quality issues since all FingerTips data
    DataQualityID = 1,
    # Stitch together demographics
    DemographicLabel = paste(Sex, ": ", Age, sep = ""),
    # Change column names
    Numerator = Count,
    IndicatorValue = Value
  ) %>%
  left_join(
    demographics,
    join_by(DemographicLabel),
    relationship = "many-to-one"
  ) %>%
  left_join(
    aggregations,
    join_by(AreaCode == "AggregationCode"),
    relationship = "many-to-one"
  ) %>%
  select(
    c("ValueID", "IndicatorID", "InsertDate", 
      "Numerator", "Denominator", "IndicatorValue","LowerCI95", "UpperCI95", 
      "AggregationID", "DemographicID", "DataQualityID",
      "IndicatorStartDate","IndicatorEndDate"
    )
  )

# Process meta data

output_meta <- collected_meta %>%
  select(-c(Unit, Methodology)) %>%
  tidyr::pivot_longer(
    cols=-IndicatorID,
    names_to='ItemLabel',
    values_to='MetaValue') %>%
  left_join(
    meta,
    join_by(ItemLabel)) %>%
  select(c(IndicatorID,ItemID,MetaValue))

#################################################################
##                     Save final output                       ##
#################################################################

# Save data
write.csv(
  output_data, 
  "../../data/output/birmingham-source/LA_FingerTips_data.csv"
  )

# Save meta

write.csv(
  output_meta, 
  "../../data/output/birmingham-source/LA_FingerTips_meta.csv"
)


