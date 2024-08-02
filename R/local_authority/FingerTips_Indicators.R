library(fingertipsR)
library(dplyr)
library(data.table)

fetch_data <- function(FingerTips_id, AreaTypeID) {
  # Fetch data from FingerTips using API
  data <- fingertips_data(
    AreaTypeID = AreaTypeID, 
    IndicatorID = FingerTips_id
  )
  
  meta_data <- indicator_metadata(
    IndicatorID = FingerTips_id
  )
  
  return(
    list("data" = data,"meta" = meta_data)
    )
}

get_magnitude <- function(meta) {
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
  methodology = meta %>% pull("Methodology")
  if (grepl("rate", tolower(methodology))) {
    return("Byar's Method")
  } else{
    return("Wilson's Method")
  }
}

process_LA_data <- function(FingerTips_id, AreaTypeID) {
  
  data_and_meta <- fetch_data(FingerTips_id, AreaTypeID)
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
      AreaName, Timeperiod, Count, Denominator, Value, LowerCI95, UpperCI95
    ) %>%
    mutate(
      magnitude = get_magnitude(meta),
      CI_method = get_CI_method(meta)
    )
  
  # England data
  df_eng <- data %>% 
    filter(AreaName == "England")
  
  # Filter for Birmingham and Solihull
  df_LA <- data %>%
    filter(AreaName %in% c("Solihull", "Birmingham"))
  
  # Filter for Birmingham and Solihull
  df_ICB <- df_LA %>%
    group_by(AreaName, Timeperiod, magnitude, CI_method) %>%
    summarise(
      Count = sum(Count),
      Denominator = sum(Denominator),
      .groups = 'keep'
    ) %>%
    mutate(
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
      AreaName, Timeperiod, Count, Denominator, Value, LowerCI95, UpperCI95, 
      magnitude, CI_method
    )
  
  # 
  combined_data <- rbindlist(
    list(
      df_LA, df_ICB, df_eng
    )
  ) %>% 
    select(-c(magnitude, CI_method))
  
  return(combined_data)
}

# Load data
ids <- read.csv("../../data/LA_FingerTips_Indicators.csv")

for (i in 1:nrow(ids)){
  
  if (ids$AreaType[i] == "GP") {
    print("Process like GP")
  } 
  else if (ids$AreaType[i] == "LA") {
    data_i <- process_LA_data(
      ids$FingerTips_id[[i]], 
      ids$AreaTypeID[[i]]
    )
  }
  else {
    stop(error = "Unexpected AreaTypeID. Only GP (7) and LA (402) implemented.")
  }
  data_i$IndicatorID <- ids$IndicatorID[[i]]
}
