# Requires NetMotion

library(dplyr)
library(fingertipsR)
library(lubridate)

# List Practice Codes to be removed from data
problem_GPs <- c(
  "M85753",  # Closed
  "M85159",  # Closed
  "V9Y6R",   # Closed
  "M88015",  # Sandwell
  "M88006",  # Sandwell
  "M85782",  # University Southgate
  "M85801"   # No record in FT
  )  



################################################################
###              Get total eligible estimates                ###
################################################################

# Automatically load data from FingerTips
eligibility_pre2425 = fingertips_data(AreaTypeID = 402, 
                                 IndicatorID = 91041) %>%
  filter(
    AreaName %in% c("Birmingham", "Solihull"),
    Timeperiodrange == "3m",
  ) %>%
  rowwise() %>%
  mutate(
    year = strsplit(Timeperiod, split = " ")[[1]][[1]],
    Local_Authority = AreaName
  ) %>%
  group_by(year, Local_Authority) %>%
  summarise(
    total_eligible = mean(Denominator)
  ) %>% 
  # Get 3 most recent years
  arrange(desc(year)) %>%
  head(4)

# Hard-code eligibility for 2024/25
# since the figures haven't been released yet
eligibility_2425 <- data.frame(
  year = c("2024/25", "2024/25"),
  Local_Authority = c("Birmingham", "Solihull"),
  total_eligible = c(286569, 62403)
)

eligibility <- rbind(eligibility_pre2425, eligibility_2425)

#################################################################
###                  Load Birmingham data                    ###
#################################################################

path_prefix <- "Z:/3.0 POPULATION & PROTECTION/3.10 ADULTS/3.103 MASTER SPREADSHEETS"

# Can't include more BCC data until matching Solihull data received due to
# mixing of localities
bcc_files <- c(
  "/2023-24/MAKRO Copy of Correct - GP Master Spreadsheet 2023-24 - Live.xlsm"#,
  #"/2024 - 25/MAKRO Copy of Correct - GP Master Spreadsheet 2024-25 - Live.xlsm"
  )

all_bcc_files <- list()

for (file_i in bcc_files) {
  
  file_path_i <- paste(path_prefix, file_i, sep = "")
  
  # Load all sheet names
  all_sheets <- readxl::excel_sheets(file_path_i)
  # Filter to sheets containing required data
  load_sheets <- all_sheets[grepl("Q\\d.*HC & SMK*", all_sheets)]

  # Load all sheets
  for (sheet_j in load_sheets) {
    data_ij <- readxl::read_excel(
      file_path_i,
      sheet = sheet_j, 
      # Suppress warning about column names
      .name_repair = "unique_quiet"
      ) %>% 
      mutate(
        HC_invite = Invited,
        HC_complete = `Screened £25`,
        # Get year from file name
        year = stringr::str_extract(file_i, "(\\d{4}-\\d{2})"),
        # Get quarter from sheet name
        quarter = as.numeric(stringr::str_extract(sheet_j, "(\\d)")),
        Local_Authority = "Birmingham"
      ) %>%
      select(
        c(`Practice Code`, Local_Authority, year, quarter, HC_invite, HC_complete)
        ) %>%
      # Remove rows with empty practice code entry
      filter(!is.na(`Practice Code`)) 
    
    # replace NA with zero
    data_ij[is.na(data_ij)] <- 0
    
    # If sheet contains data => store new sheet in list
    if (sum(data_ij$HC_invite) != 0) {
      all_bcc_files[[length(all_bcc_files) + 1]] <- data_ij
    }
  }
}

# Combine all data
bcc_data <- data.table::rbindlist(all_bcc_files) %>%
  filter(!(`Practice Code` %in% problem_GPs)) 

#################################################################
###                   Load Solihull data                      ###
#################################################################

# Currently only one file, but want to write future-proof code

solihull_prefix <- "../../data/health-checks"
solihull_files <- c(
  "/Solihull_health_checks_2023-24.xlsx"
)

all_solihull_files <- list()

for (file_i in solihull_files) {
  file_path_i <- paste(solihull_prefix, file_i, sep = "")
  
  # Load all sheet names
  all_sheets <- readxl::excel_sheets(file_path_i)
  
  # Filter to sheets containing required data
  load_sheets <- all_sheets[grepl("^Q\\d", all_sheets)]
  
  for (sheet_j in load_sheets) {
    data_ij <- readxl::read_excel(
    paste(solihull_prefix, solihull_files, sep = ""),
    sheet = sheet_j
    ) %>%
    mutate(
      HC_invite = `Eligible Patients who have been offered an NHS Health Check`,
      HC_complete = `Number of patients who have taken up a NHS HC`,
      # Get year from file name
      year = stringr::str_extract(file_i, "(\\d{4}-\\d{2})"),
      # Get quarter from sheet name
      quarter = as.numeric(stringr::str_extract(sheet_j, "(\\d)")),
      Local_Authority = "Solihull"
    ) %>%
      select(
        c(`Practice Code`, Local_Authority, year, quarter, HC_invite, HC_complete)
      )
    
    # replace NA with zero
    data_ij[is.na(data_ij)] <- 0
    
    # If sheet contains data => store new sheet in list
    if (sum(data_ij$HC_invite) != 0) {
      all_solihull_files[[length(all_solihull_files) + 1]] <- data_ij
    }
  }
}

# Combine all data
solihull_data <- data.table::rbindlist(all_solihull_files)

#################################################################
###              Estimate Eligible Population                 ###
#################################################################


# Combine GP population files and calculate 40-74 populations
GP_pops40to74 <- readxl::read_excel(
  '../../data/BSOL GP Population List.xlsx',
  sheet = "Dataset"
  ) %>%
  filter(
    ProxyAgeAtEOM >= 40 & 
      ProxyAgeAtEOM <= 74
  ) %>%
  mutate(`Practice Code` = GP_Code) %>%
  group_by(`Practice Code`) %>%
  summarise(
    GP_Pop_40to74 = sum(Count)
  ) %>%
  # Join GP Info
  left_join(
    readxl::read_excel(
      "../../data/gp-mega-map-march-2024.xlsx"
    ) %>% 
      select(c(`Practice Code`, `PRAC NAME`, PCN, Locality)) %>%
      mutate(
        Local_Authority = case_when(
          Locality %in% c("South","North","West","East","Central") ~ "Birmingham",
          Locality == "Solihull" ~ "Solihull",
          TRUE ~ "Error: Unidentified Local Authority"
        ),
        PCN = stringr::str_replace(PCN, "&", "and")
      ),
    join_by(`Practice Code`)
  ) 

# Total population for each Local Authority
LA_total_GP_pops <- GP_pops40to74 %>%
  group_by(Local_Authority) %>%
  summarise(
    total_LA_GP_pop = sum(GP_Pop_40to74)
  )

BSol_data <- rbind(bcc_data, solihull_data) %>%
  mutate(
    year = stringr::str_replace(year, "-", "/")
  ) %>%
  left_join(
    eligibility, join_by(Local_Authority, year)
  ) %>%
  left_join(
    GP_pops40to74 %>% 
      select(-Local_Authority)
      , join_by(`Practice Code`)
  ) %>%
  left_join(
    LA_total_GP_pops, join_by(Local_Authority)
    ) %>%
  mutate(
    fraction_eligible = total_eligible / total_LA_GP_pop,
    estimated_number_eligible = fraction_eligible * GP_Pop_40to74
  )

#################################################################
###                  Calculate PCN values                     ###
#################################################################

PCN_HC_received <- BSol_data %>%
  group_by(PCN, year, quarter) %>%
  summarise(
    Numerator = sum(HC_complete),
    Denominator = sum(estimated_number_eligible)
  ) %>% 
  mutate(
    ValueID = "",
    IndicatorID = 71,
    InsertDate = Sys.Date(),
    IndicatorValue = 100 * Numerator / Denominator,
    Z = qnorm(0.975),
    p_hat = IndicatorValue / 100,
    LowerCI95 = 100 * (p_hat + Z^2/(2*Denominator) - Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
    UpperCI95 = 1000 * (p_hat + Z^2/(2*Denominator) + Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
    DemographicID = 82,
    DataQualityID = 1,
    # Calculate indicator start and end dates
    Year_Start = stringr::str_extract(year,"^(\\d{4})"),
    IndicatorStartDate = as.Date(sprintf("%s/04/01", Year_Start)) %m+% 
      months(3 * (quarter - 1)),
    IndicatorEndDate = as.Date(sprintf("%s/06/30", Year_Start)) %m+% 
      months(3 * (quarter - 1)),
  ) %>%
  fuzzyjoin::stringdist_join(
    readxl::read_excel(
      "../../data/OF-Other-Tables.xlsx",
      sheet = "Aggregation") %>%
      filter(AggregationType == "PCN") %>%
      select(c(AggregationID, AggregationLabel)),
    by = c(PCN = "AggregationLabel"),
    mode='left',
    method = "jw", #use jw distance metric
    max_dist=0.1, 
    distance_col='dist'
  ) %>%
  ungroup() %>%
  select(
    c(ValueID, IndicatorID, InsertDate, Numerator, Denominator, IndicatorValue, 
      LowerCI95, UpperCI95, AggregationID, DemographicID, DataQualityID, 
      IndicatorStartDate ,IndicatorEndDate
    )
  )

#################################################################
###                Calculate Locality values                  ###
#################################################################

locality_HC_received <- BSol_data %>%
  group_by(Locality, year, quarter) %>%
  summarise(
    Numerator = sum(HC_complete),
    Denominator = sum(estimated_number_eligible)
  ) %>% 
  mutate(
    ValueID = "",
    IndicatorID = 71,
    InsertDate = Sys.Date(),
    IndicatorValue = 100 * Numerator / Denominator,
    Z = qnorm(0.975),
    p_hat = IndicatorValue / 100,
    LowerCI95 = 100 * (p_hat + Z^2/(2*Denominator) - Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
    UpperCI95 = 1000 * (p_hat + Z^2/(2*Denominator) + Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
    DemographicID = 82,
    DataQualityID = 1,
    # Calculate indicator start and end dates
    Year_Start = stringr::str_extract(year,"^(\\d{4})"),
    IndicatorStartDate = as.Date(sprintf("%s/04/01", Year_Start)) %m+% 
      months(3 * (quarter - 1)),
    IndicatorEndDate = as.Date(sprintf("%s/06/30", Year_Start)) %m+% 
      months(3 * (quarter - 1)),
  ) %>%
  fuzzyjoin::stringdist_join(
    readxl::read_excel(
      "../../data/OF-Other-Tables.xlsx",
      sheet = "Aggregation") %>%
      filter(AggregationType == "Locality (registered)") %>%
      select(c(AggregationID, AggregationLabel)),
    by = c(Locality = "AggregationLabel"),
    mode='left',
    method = "jw", #use jw distance metric
    max_dist=0.1, 
    distance_col='dist'
  ) %>%
  ungroup() %>%
  select(
    c(ValueID, IndicatorID, InsertDate, Numerator, Denominator, IndicatorValue, 
      LowerCI95, UpperCI95, AggregationID, DemographicID, DataQualityID, 
      IndicatorStartDate, IndicatorEndDate
    )
  )


#################################################################
###             Calculate Local Authority values              ###
#################################################################

LA_HC_received <- BSol_data %>%
  group_by(Local_Authority, year, quarter) %>%
  summarise(
    Numerator = sum(HC_complete),
    Denominator = sum(estimated_number_eligible)
  ) %>% 
  mutate(
    ValueID = "",
    IndicatorID = 71,
    InsertDate = Sys.Date(),
    IndicatorValue = 100 * Numerator / Denominator,
    Z = qnorm(0.975),
    p_hat = IndicatorValue / 100,
    LowerCI95 = 100 * (p_hat + Z^2/(2*Denominator) - Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
    UpperCI95 = 1000 * (p_hat + Z^2/(2*Denominator) + Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
    DemographicID = 82,
    DataQualityID = 1,
    # Calculate indicator start and end dates
    Year_Start = stringr::str_extract(year,"^(\\d{4})"),
    IndicatorStartDate = as.Date(sprintf("%s/04/01", Year_Start)) %m+% 
      months(3 * (quarter - 1)),
    IndicatorEndDate = as.Date(sprintf("%s/06/30", Year_Start)) %m+% 
      months(3 * (quarter - 1)),
  ) %>%
  fuzzyjoin::stringdist_join(
    readxl::read_excel(
      "../../data/OF-Other-Tables.xlsx",
      sheet = "Aggregation") %>%
      filter(AggregationType == "Local Authority") %>%
      select(c(AggregationID, AggregationLabel)),
    by = c(Local_Authority = "AggregationLabel"),
    mode='left',
    method = "jw", #use jw distance metric
    max_dist=0.1, 
    distance_col='dist'
  ) %>%
  ungroup() %>%
  select(
    c(ValueID, IndicatorID, InsertDate, Numerator, Denominator, IndicatorValue, 
      LowerCI95, UpperCI95, AggregationID, DemographicID, DataQualityID, 
      IndicatorStartDate, IndicatorEndDate
    )
  )


#################################################################
###                   Calculate ICB values                    ###
#################################################################

ICB_HC_received <- BSol_data %>%
  group_by(year, quarter) %>%
  summarise(
    Numerator = sum(HC_complete),
    Denominator = sum(estimated_number_eligible)
  ) %>% 
  mutate(
    ValueID = "",
    IndicatorID = 71,
    InsertDate = Sys.Date(),
    IndicatorValue = 100 * Numerator / Denominator,
    Z = qnorm(0.975),
    p_hat = IndicatorValue / 100,
    LowerCI95 = 100 * (p_hat + Z^2/(2*Denominator) - Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
    UpperCI95 = 1000 * (p_hat + Z^2/(2*Denominator) + Z * sqrt((p_hat*(1-p_hat)/Denominator) + Z^2/(4*Denominator^2))) / (1 + Z^2/Denominator),
    DemographicID = 82,
    DataQualityID = 2,
    # Calculate indicator start and end dates
    Year_Start = stringr::str_extract(year,"^(\\d{4})"),
    IndicatorStartDate = as.Date(sprintf("%s/04/01", Year_Start)) %m+% 
      months(3 * (quarter - 1)),
    IndicatorEndDate = as.Date(sprintf("%s/06/30", Year_Start)) %m+% 
      months(3 * (quarter - 1)),
    # BSol ICB
    AggregationID = 148
  ) %>%
  ungroup() %>%
  select(
    c(ValueID, IndicatorID, InsertDate, Numerator, Denominator, IndicatorValue, 
      LowerCI95, UpperCI95, AggregationID, DemographicID, DataQualityID, 
      IndicatorStartDate, IndicatorEndDate
    )
  )


#################################################################
###              Bind all aggregation levels                  ###
#################################################################

# Bind aggregation levels
HC_output <- rbind(
  PCN_HC_received, 
  locality_HC_received, 
  LA_HC_received, 
  ICB_HC_received
  )

# save as csv
write.csv(HC_output, "../../data/output/birmingham-source/0071_eligible_patients_receiving_an_NHS_health_check.csv")