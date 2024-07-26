library(dplyr)


#################################################################
###                  Load Birmingham data                    ###
#################################################################

path_prefix <- "Z:/3.0 POPULATION & PROTECTION/3.10 ADULTS/3.103 MASTER SPREADSHEETS"

bcc_files <- c(
  "/2023-24/MAKRO Copy of Correct - GP Master Spreadsheet 2023-24 - Live.xlsm",
  "/2024 - 25/MAKRO Copy of Correct - GP Master Spreadsheet 2024-25 - Live.xlsm"
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
        quarter = stringr::str_extract(sheet_j, "(Q\\d)")
      ) %>%
      select(
        c(`Practice Code`, year, quarter, HC_invite, HC_complete)
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
bcc_data <- data.table::rbindlist(all_bcc_files)

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
      quarter = stringr::str_extract(sheet_j, "(Q\\d)")
    ) %>%
      select(
        c(`Practice`, year, quarter, HC_invite, HC_complete)
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
