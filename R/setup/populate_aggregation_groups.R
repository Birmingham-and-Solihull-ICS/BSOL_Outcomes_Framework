################################################################################
## Date: 05/03/2024
## Overview: Populating geographical and PCN data using Fingertips
## Author: Chris Mainey, BSOL ICB
## Description: Looking up al possible geographies that mention Birmingham and Solihull
##              , such as England, ICB, LA, PCN types from Fingertips.
##               Manual addition of PCNs as correct at the time, reconciled to Fingertips
################################################################################# 


library(fingertipsR)

# Download fill indicators table - I know it's big, but easiest way to make sure I've got all permutations
dt <- fingertips_data(IndicatorID = ftp_inds, AreaTypeID = "All")

# Save down as serialised data - Maybe we should just do this once and reuse?
saveRDS(dt, "./data./big_indicator_file.RDS")

# Load the RDS file up
dt <- readRDS("./data./big_indicator_file.RDS")


# Possible BSOL geographies, unique with name Birmingham or Solihull
geogs <- unique(dt[grepl("Birmingham|Solihull|England", dt$AreaName, ignore.case = FALSE, perl = TRUE)
                    , c("AreaCode","AreaName", "AreaType", "ParentCode", "ParentName")
                    ]
                )


# PCN - this is a weirder one, data sourced from BSOL/MLCSU
PCN_BSOL <-
  tibble::tribble(
                             ~AreaName,      ~AreaCode,
          "Alliance of Sutton Practices", "U47609",
  "Balsall Heath, Sparkhill and Moseley", "U54948",
               "Birmingham East Central", "U79433",
                        "Bordesley East", "U46437",
             "Bournville and Northfield", "U27366",
             "Community Care Hall Green", "U25587",
                             "Edgbaston", "U27129",
                                  "GOSK", "U82305",
                        "GPS Healthcare", "U67607",
                              "Harborne", "U46454",
                                    "I3", "U65968",
  "Kingstanding, Erdington and Nechells", "U18195",
                 "MMP Central and North", "U74554",
                              "Modality", "U44537",
   "Moseley, Billesley and Yardley Wood", "U69625",
       "Nechells, Saltley and Alum Rock", "U79003",
                      "North Birmingham", "U43660",
                        "North Solihull", "U93165",
            "Peoples Health Partnership", "U25240",
                              "Pershore", "U88190",
        "Pioneer Integrated Partnership", "U54554",
                  "Quinton and Harborne", "U79381",
             "Shard End and Kitts Green", "U72309",
                           "Small Heath", "U15552",
                     "Smartcare Central", "U22471",
       "Solihull Healthcare Partnership", "U45528",
                        "Solihull Rural", "U41928",
                "Solihull South Central", "U00351",
             "South Birmingham Alliance", "U13655",
                 "South West Birmingham", "U91268",
                 "Sutton Group Practice", "U65039",
                          "Urban Health", "U48923",
                        "Washwood Heath", "U76419",
                     "Weoley and Rubery", "U51153",
                       "West Birmingham", "U44365"
  )


library(dplyr)

PCN_matching <-
  dt3 %>% 
  select(AreaCode, AreaName, AreaType, ParentCode, ParentName) %>% 
  right_join(PCN_BSOL, by = c("AreaCode" = "AreaCode")) %>% 
  distinct()


# Table fields are AggregationID(auto), AggregationType, AggregationCode, AggregationLable

out <- geogs %>% 
  filter(AreaType != "PCNs (v. 27/10/23)") %>% 
  select(AreaType, AreaCode, AreaName) %>% 
  mutate(AreaCode = case_when(
                      AreaCode == "nE38000258" ~ "E38000258",
                      AreaCode == "nE54000055" ~ "E54000055",
                      .default = AreaCode
                      )) %>% 
  union_all(
    bind_cols(AreaType="PCNs (v. 27/10/23)", select(PCN_BSOL, AreaCode, AreaName))
  )


write.csv(out, file = "./data/aggregation.csv", )
