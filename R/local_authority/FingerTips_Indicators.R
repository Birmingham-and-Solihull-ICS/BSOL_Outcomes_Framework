library(fingertipsR)
library(dplyr)
library(data.table)
library(readxl)
library(lubridate)
# Load indicator list
ids <- read_excel(
  "../../data/LA_FingerTips_Indicators.xlsx",
  sheet = "FT_indicators")

# Load GP-PCN-Locality-LA lookup data
GP_lookup <- read.csv("../../data/better-GP-lookup-march-2024.csv") %>%
  select(-c(Type, PCN, Locality, LA))

PCN_lookup <- readxl::read_excel(
  "../../data/OF-Other-Tables.xlsx",
  sheet = "PCN-Locality-Lookup"
)

#################################################################
##                        Functions                            ##
#################################################################

## Data collection functions ##

fetch_meta <- function(FingerTips_id) {
  meta_data <- indicator_metadata(
    IndicatorID = FingerTips_id
  ) %>%
    mutate(
      `Source of numerator` = `Source of numerator`,
      `Source of denominator`  = `Source of denominator`,
      `External Reference` = Links,
      `Rate Type` = case_when(
        `Unit` == "%" ~ "Percentage",
        `Value type` == "Proportion" ~ `Value type`,
        grepl("rate", tolower(`Value type`)) ~ paste(`Value type`, "per", Unit)
        ),
      `Simple Definition` = case_when(
        is.na(`Simple Definition`) ~ Definition,
        TRUE ~ `Simple Definition`
      ),
    ) %>%
    select(
      c(Caveats, `Definition of denominator`, `Definition of numerator`,
        `External Reference`, Polarity, `Simple Definition`,
        `Source of numerator`, `Source of denominator`, Unit, Methodology,
        `Rate Type`)
    )
  return(meta_data)
}

fetch_data <- function(FingerTips_id, AreaTypeID) {
  # Fetch data from FingerTips using API
  data <- fingertips_data(
    AreaTypeID = AreaTypeID, 
    IndicatorID = FingerTips_id
  ) 
  
  if (FingerTips_id == 93183) {
    data <- data %>%
      filter(
        Age == "14+ yrs"
      )
  }
  
  meta_data <- fetch_meta(FingerTips_id)
  
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
  Value_type = meta %>% pull("Rate Type")
  if (grepl("rate", tolower(Value_type))) {
    return("Byar's Method")
  } else if (grepl("proportion|percentage", tolower(Value_type))){
    return("Wilson's Method")
  } else {
    stop(sprintf("Unexpected Value Type: %s",Value_type))
  }
}

select_final_cols <- function(df) {
  df <- df %>%
    select(
      AreaCode, Timeperiod, Sex, Age, Count, Denominator, Value, 
      LowerCI95, UpperCI95, magnitude, CI_method
    ) %>% 
    select(
      -c(magnitude, CI_method)
      )
  return (df)
}

process_LA_data <- function(FingerTips_id) {
  
  data_and_meta <- fetch_data(FingerTips_id, AreaTypeID = 502)
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
      CI_method = get_CI_method(meta),
      Count = case_when(
        !is.na(Count) ~ Count,
        # If count isn't given but there is Denominator and Value data
        #  then estimate the count from these
        !is.na(Denominator) & !is.na(Value) ~ Denominator * Value / magnitude
      )
    ) 
  
  # England data
  df_eng <- data %>% 
    filter(AreaCode == "E92000001")
  
  # Filter for Birmingham and Solihull
  df_LA <- data %>%
    filter(
      AreaCode %in% c("E08000029", "E08000025")
      ) 
  
  df_ICB <- df_LA %>%
    group_by(Timeperiod, Sex, Age,  magnitude, CI_method) %>%
    summarise(
      n = n(),
      Value_not_na = sum(!is.na(Value)),
      Count = sum(Count),
      Denominator = sum(Denominator),
      .groups = 'keep'
    ) %>%
    # Don't calculate ICB value if it doesn't include both Birmingham and Solihull
    filter(n == 2 & Value_not_na == 2) %>%
    mutate(
      AreaCode = "E38000258",
      p_hat = Count / Denominator,
      Value = magnitude * p_hat,
      # for use in Byar's method
      a_prime = Count + 1,
      # Calculate errors
      Z = qnorm(0.975),
      LowerCI95 = case_when(
        CI_method == "Wilson's Method" ~ magnitude * (p_hat + Z^2/(2*Denominator) - Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
        CI_method == "Byar's Method" ~ magnitude * Count * (1 - 1/(9*Count) - Z/3 * sqrt(1/a_prime))**3/Denominator
      ),
      UpperCI95 = case_when(
        CI_method == "Wilson's Method" ~ magnitude * (p_hat + Z^2/(2*Denominator) + Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
        CI_method == "Byar's Method" ~ magnitude * a_prime * (1 - 1/(9*a_prime) + Z/3 * sqrt(1/a_prime))**3/Denominator
      )
    ) %>% 
    ungroup() 

  combined_data <- rbindlist(
    list(
      select_final_cols(df_LA), 
      select_final_cols(df_ICB), 
      select_final_cols(df_eng)
    )
  ) 
  
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
      )%>%
    select(
      AreaCode, Timeperiod, Sex, Age, Count, Denominator, Value, 
      LowerCI95, UpperCI95
    ) %>%
    mutate(
      magnitude = get_magnitude(meta),
      CI_method = get_CI_method(meta),
      missing = is.na(Count) | is.na(Denominator)
    ) 
  
  GP_data  <- data %>%
    inner_join(
      GP_lookup, 
      join_by(AreaCode == "Practice_Code")
    )
  
  # Check for any missing values and print percentage missing before these 
  # rows are removed
  missing_check <- GP_data %>%
    group_by(
      Timeperiod
    ) %>%
    summarise(
      num_missing = sum(missing),
      perc_missing = round(100*num_missing/n(), 2)
    )  %>%
    filter(
      num_missing > 0
    )
  
  # Report any missing data
  if (nrow(missing_check) > 0) {
    print(
      paste("Missing GP data for FT ID:", FingerTips_id)
      )
    print(missing_check)
  }
  
  
  # England data
  df_eng <- data %>% 
    filter(AreaCode == "E92000001")
  
  # Aggregate for PCNs
  df_PCN <- GP_data %>%
    # Remove rows with missing Numerator or Denominator
    filter(
      !missing
    )  %>%
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
      a_prime = Count + 1,
      # Calculate errors
      Z = qnorm(0.975),
      LowerCI95 = case_when(
        CI_method == "Wilson's Method" ~ magnitude * (p_hat + Z^2/(2*Denominator) - Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
        CI_method == "Byar's Method" ~ magnitude * Count * (1 - 1/(9*Count) - Z/3 * sqrt(1/a_prime))**3/Denominator
      ),
      UpperCI95 = case_when(
        CI_method == "Wilson's Method" ~ magnitude * (p_hat + Z^2/(2*Denominator) + Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
        CI_method == "Byar's Method" ~ magnitude * a_prime * (1 - 1/(9*a_prime) + Z/3 * sqrt(1/a_prime))**3/Denominator
      )
    ) %>% 
    ungroup() 
  
  # Aggregate for Localities
  df_Locality <- df_PCN %>%
    inner_join(PCN_lookup, 
               join_by(AreaCode == "PCN_Code")) %>%
    group_by(Locality_Code, LA_Code, Timeperiod, Sex, Age,  magnitude, CI_method) %>%
    summarise(
      Count = sum(Count),
      Denominator = sum(Denominator),
      .groups = 'keep'
    ) %>%
    mutate(
      AreaCode = Locality_Code,
      p_hat = Count / Denominator,
      Value = magnitude * p_hat,
      # for use in Byar's method
      a_prime = Count + 1,
      # Calculate errors
      Z = qnorm(0.975),
      LowerCI95 = case_when(
        CI_method == "Wilson's Method" ~ magnitude * (p_hat + Z^2/(2*Denominator) - Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
        CI_method == "Byar's Method" ~ magnitude * Count * (1 - 1/(9*Count) - Z/3 * sqrt(1/a_prime))**3/Denominator
      ),
      UpperCI95 = case_when(
        CI_method == "Wilson's Method" ~ magnitude * (p_hat + Z^2/(2*Denominator) + Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
        CI_method == "Byar's Method" ~ magnitude * a_prime * (1 - 1/(9*a_prime) + Z/3 * sqrt(1/a_prime))**3/Denominator
      )
    ) %>% 
    ungroup() 

  # Aggregate for local authorities
  df_LA <- df_Locality %>%
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
      a_prime = Count + 1,
      # Calculate errors
      Z = qnorm(0.975),
      LowerCI95 = case_when(
        CI_method == "Wilson's Method" ~ magnitude * (p_hat + Z^2/(2*Denominator) - Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
        CI_method == "Byar's Method" ~ magnitude * Count * (1 - 1/(9*Count) - Z/3 * sqrt(1/a_prime))**3/Denominator
      ),
      UpperCI95 = case_when(
        CI_method == "Wilson's Method" ~ magnitude * (p_hat + Z^2/(2*Denominator) + Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
        CI_method == "Byar's Method" ~ magnitude * a_prime * (1 - 1/(9*a_prime) + Z/3 * sqrt(1/a_prime))**3/Denominator
      )
    ) %>% 
    ungroup() 
  
  # Aggregate for BSol ICB
  df_ICB <- df_LA %>%
    group_by(Timeperiod, Sex, Age,  magnitude, CI_method) %>%
    summarise(
      n = n(),
      Count = sum(Count),
      Denominator = sum(Denominator),
      .groups = 'keep'
    )  %>%
    # Don't calculate ICB value if it doesn't include both Birmingham and Solihull
    filter(n==2) %>%
    mutate(
      AreaCode = "E38000258",
      p_hat = Count / Denominator,
      Value = magnitude * p_hat,
      # for use in Byar's method
      a_prime = Count + 1,
      # Calculate errors
      Z = qnorm(0.975),
      LowerCI95 = case_when(
        CI_method == "Wilson's Method" ~ magnitude * (p_hat + Z^2/(2*Denominator) - Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
        CI_method == "Byar's Method" ~ magnitude * Count * (1 - 1/(9*Count) - Z/3 * sqrt(1/a_prime))**3/Denominator
      ),
      UpperCI95 = case_when(
        CI_method == "Wilson's Method" ~ magnitude * (p_hat + Z^2/(2*Denominator) + Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
        CI_method == "Byar's Method" ~ magnitude * a_prime * (1 - 1/(9*a_prime) + Z/3 * sqrt(1/a_prime))**3/Denominator
      )
    ) %>% 
    ungroup() 

  # 
  combined_data <- rbindlist(
    list(
      select_final_cols(df_PCN), 
      select_final_cols(df_Locality), 
      select_final_cols(df_LA), 
      select_final_cols(df_ICB), 
      select_final_cols(df_eng)
    )
  ) 
  
  output <- list(
    "data" = combined_data,
    "meta" = meta
  )
  
  return(output)
}

process_Eng_data <- function(FingerTips_id) {
  # Fetch data
  data_and_meta <- fetch_data(FingerTips_id, AreaTypeID = 15)
  data <- data_and_meta[["data"]]
  meta <- data_and_meta[["meta"]]
  # delete list to save space
  rm(data_and_meta)
  
  data <- data %>%
    mutate(
      LowerCI95 = LowerCI95.0limit, 
      UpperCI95 = UpperCI95.0limit
    )%>%
    select(
      AreaCode, Timeperiod, Sex, Age, Count, Denominator, Value, 
      LowerCI95, UpperCI95
    )
  
  output <- list(
    "data" = data,
    "meta" = meta
  )
  
}

## Data processing functions ##

start_date <- function(date) {
  
  # If financial year e.g. 2021/22
  if (grepl("^\\d{4}/\\d{2}$",date)) {
    Year_Start = stringr::str_extract(date,"^\\d{4}")
    start_date <- as.Date(
      sprintf("%s/04/01", Year_Start),
      format = "%Y/%m/%d")
  } 
  # If calendar year e.g. 2021
  else if (grepl("^\\d{4}$",date)) {
    start_date <- as.Date(
      sprintf("%s/01/01", date),
      format = "%Y/%m/%d")
  }
  # if multi year e.g. 2012 - 2014
  else if (grepl("^\\d{4} - \\d{2}$",date)) {
    Year_Start <-  stringr::str_extract(date,"^\\d{4}")
    start_date <- as.Date(
      sprintf("%s/01/01", Year_Start),
      format = "%Y/%m/%d")
  }
  # Quarterly data e.g. 2013/14 Q1
  else if (grepl("^\\d{4}/\\d{2} Q\\d{1}$",date)) {
    Year_Start <- as.numeric(stringr::str_extract(date,"^\\d{4}"))
    Quarter <-  as.numeric(stringr::str_extract(date,"\\d{1}$"))
    
    start_date <- as.Date(
      case_when(
      Quarter == "1" ~ sprintf("%s/04/01", Year_Start),
      Quarter == "2" ~ sprintf("%s/07/01", Year_Start),
      Quarter == "3" ~ sprintf("%s/10/01", Year_Start),
      Quarter == "4" ~ sprintf("%s/01/01", Year_Start+1),
      ),
    format = "%Y/%m/%d"
    )
    
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
    start_date <- as.Date(
      sprintf("%i/03/31", as.numeric(Year_Start) + 1 ),
      format = "%Y/%m/%d")
  } 
  # If calendar year e.g. 2021
  else if (grepl("^\\d{4}$",date)) {
    start_date <- as.Date(
      sprintf("%s/12/31", date), 
      format = "%Y/%m/%d")
  }
  else if (grepl("^\\d{4} - \\d{2}$",date)) {
    Year_End = stringr::str_extract(date,"\\d{2}$")
    start_date <- as.Date(
      sprintf("20%s/01/01", Year_End),
      format = "%Y/%m/%d")
  }  
  # Quarterly data e.g. 2013/14 Q1
  else if (grepl("^\\d{4}/\\d{2} Q\\d{1}$",date)) {
    Year_Start <- as.numeric(stringr::str_extract(date,"^\\d{4}"))
    Quarter <-  as.numeric(stringr::str_extract(date,"\\d{1}$"))
    
    start_date <- as.Date(
      case_when(
        Quarter == "1" ~ sprintf("%s/06/30", Year_Start),
        Quarter == "2" ~ sprintf("%s/09/30", Year_Start),
        Quarter == "3" ~ sprintf("%s/12/31", Year_Start),
        Quarter == "4" ~ sprintf("%s/03/31", Year_Start+1),
      ),
      format = "%Y/%m/%d"
    )
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

print("------------- Collecting FingerTips data --------------")
all_data <- list()
all_meta <- list()

for (i in 1:nrow(ids)){
  print(ids$FingerTips_id[[i]])
  if (ids$AreaType[i] == "GP") {
    data_i <- process_GP_data(ids$FingerTips_id[[i]])
  } 
  else if (ids$AreaType[i] == "LA") {
    data_i <- process_LA_data(ids$FingerTips_id[[i]])
  }
  else if (ids$AreaType[i] == "England") {
    data_i <- process_Eng_data(ids$FingerTips_id[[i]])   
  }
  else {
    stop(error = "Unexpected AreaTypeID. Only GP (7) and LA (502) implemented.")
  }
  
  # Check that FingerTips provided at least one row of data
  if (nrow(data_i[["data"]]) == 0) {
    stop(error = paste("No data collected for FT ID:", ids$FingerTips_id[[i]]))
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
##               Collect Additional Meta Data                  ##
#################################################################
print("------------- Collecting additional meta data --------------")
meta_ids <- read_excel(
  "../../data/LA_FingerTips_Indicators.xlsx",
  sheet = "meta_only")
# Get additional meta data
additional_meta_list <- list()

for (i in 1:nrow(meta_ids)) {
  meta_data_i <- fetch_meta(meta_ids$FingerTips_ID[[i]])
  meta_data_i$IndicatorID <- meta_ids$IndicatorID[[i]]
  additional_meta_list[[i]] <- meta_data_i
}

collected_additional_meta <- rbindlist(additional_meta_list)

#################################################################
##                Mutate into Staging Table                    ##
#################################################################
print("------------- Mutate into Staging Table --------------")
# Load ID lookup tables

meta <- readxl::read_excel(
  "../../data/OF-Other-Tables.xlsx",
  sheet = "Meta"
)

demographics <- readxl::read_excel(
  "../../data/OF-Other-Tables.xlsx",
  sheet = "Demographic"
) %>% 
  # Remove repeated entry for "Persons: <18 yrs"
  filter(DemographicID != 7623) %>%
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
  filter(
    # Remove rows with no DemographicID
    !is.na(DemographicID)
  ) %>%
  select(
    c("ValueID", "IndicatorID", "InsertDate", 
      "Numerator", "Denominator", "IndicatorValue", "LowerCI95", "UpperCI95", 
      "AggregationID", "DemographicID", "DataQualityID",
      "IndicatorStartDate","IndicatorEndDate"
    )
  )


# Load simple definition write-ups
simple_defs <- readxl::read_excel(
  "../../data/OF-Other-Tables.xlsx",
  sheet = "Definitions"
) %>%
  filter(Definition != "Duplicate") %>%
  mutate(WrittenDefinition = SimpleDefinition) %>%
  select(c(IndicatorID, WrittenDefinition))

# Process meta data
output_meta <- collected_meta %>% 
  rbind(collected_additional_meta) %>%
  left_join(
    simple_defs, 
    join_by(IndicatorID),
    relationship = "one-to-one"
    ) %>%
  mutate(
    `Simple Definition` = case_when(
      is.na(WrittenDefinition) ~ `Simple Definition`,
      TRUE ~ `Simple Definition`,
    ),
    # Update LARC caveats text
    Caveats = case_when(
      IndicatorID == 15 ~ paste(
        "Solihull data not available for some years due to small numbers.", 
        Caveats
      ),
      IndicatorID == 17 ~ paste(
        "One GP in 2012/13 missing due to missing source data. This GP has therefore been omitted from the 2012/13 value calculation.", 
        Caveats
      ),
      IndicatorID == 20 ~ paste(
        "Data for between 1 (0.55%) and 14 (7.7%) of GPs missing each year from 2009/10 to 2021/22 except 2015/16. These GPs have therefore been omitted from the 2012/13 value calculation.", 
        Caveats
      ),
      IndicatorID == 27 ~ paste(
        "Birmingham values from 2016/17 to 23/24 and Solihul value for 2016/17 not published due to data quality reasons.", 
        Caveats
      ),
      IndicatorID == 34 ~ paste(
        "Source data not available for 1 GP (0.55%) in 2019/20 and 2020/21. This GP has therefore been omitted from the 2012/13 value calculation for these years.", 
        Caveats
      ),
      IndicatorID == 57 ~ paste(
        "Solihull value not published in 2019/20 due for data quality reasons.", 
        Caveats
      ),
      IndicatorID == 130 ~ paste(
        "Solihull data currently unavailable.", 
        Caveats
      ),
      IndicatorID %in% c(118,119) ~ "Indicator presented as the mortality rate per 1,000. This is different to FingerTips which gives the equivalenct indicator as a mortality ratio.",
      TRUE ~ Caveats
    ),
    # Update NDTMS denominator Definition
    `Definition of denominator` = case_when(
      IndicatorID == 118 ~ "The number of adults in drug treatment in the local authority.",
      IndicatorID == 119 ~ "The number of adults in alcohol treatment in the local authority.",
      IndicatorID == 130 ~ "GP-registered female population aged 15-44 years.",
      TRUE ~ `Definition of numerator`
    ),
    `Rate Type` = case_when(
      IndicatorID %in% c(118,119) ~ "Crute rate per 1,000",
      TRUE ~ `Rate Type`
    ),
    `Definition of numerator` = case_when(
      IndicatorID == 130 ~ "GP prescribed long acting reversible contraception excluding injections",
      TRUE ~ `Simple Definition`
    ),
    `Simple Definition` = case_when(
      IndicatorID == 130 ~ "Crude rate of GP prescribed long acting reversible contraception excluding injections per 1,000 GP-registered female population aged 15-44 years",
      TRUE ~ `Simple Definition`
    ),
    `Source of denominator` =  case_when(
      IndicatorID == 130 ~ "Birmingham and Solihull GP registration data.",
      TRUE ~ `Source of denominator`
    ),
    `Source of numerator`=  case_when(
      IndicatorID == 130 ~ "Birmingham City Council LARC contract data.",
      TRUE ~ `Source of numerator`
    )
    
  ) %>%
  select(-c(Unit, Methodology, WrittenDefinition)) %>%
  tidyr::pivot_longer(
    cols=-IndicatorID,
    names_to='ItemLabel',
    values_to='MetaValue') %>%
  left_join(
    meta,
    join_by(ItemLabel)) %>%
  select(c(IndicatorID, ItemID, MetaValue)) %>%
  arrange(IndicatorID, ItemID)

#################################################################
##                     Save final output                       ##
#################################################################
print("------------- Save final output  --------------")

# Save data
write.csv(
  output_data, 
  "../../data/output/birmingham-source/data/LA_FingerTips_data.csv"
  )

# Save meta
write.csv(
  output_meta, 
  "../../data/output/birmingham-source/meta/LA_FingerTips_meta.csv"
)


