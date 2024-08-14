library(fingertipsR)
library(dplyr)
library(data.table)

#######################################################################
#####                 Collect from FingerTips                     #####
#######################################################################

ids <- readxl::read_excel("../../data/Birmingham_meta_list.xlsx")
# Get additional meta data
all_meta <- list()

for (i in 1:nrow(ids)) {
  meta_data_i <- indicator_metadata(
    IndicatorID = ids$FingerTips_ID[[i]]
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
        `Source of numerator`, `Source of denominator`)
    )
  meta_data_i$IndicatorID <- ids$IndicatorID[[i]]
  all_meta[[i]] <- meta_data_i
}

collected_meta <- rbindlist(all_meta) %>%
  mutate(
    `Rate Type` = NA
  )

meta <- readxl::read_excel(
  "../../data/OF-Other-Tables.xlsx",
  sheet = "Meta"
)

output_meta <- collected_meta %>%
  tidyr::pivot_longer(
    cols=-IndicatorID,
    names_to='ItemLabel',
    values_to='MetaValue') %>%
  left_join(
    meta,
    join_by(ItemLabel)) %>%
  select(c(IndicatorID,ItemID,MetaValue)) %>%
  arrange(IndicatorID, ItemID)

#######################################################################
#####                     Amend meta data                         #####
#######################################################################

mask = (output_meta$ItemID == 1 & output_meta$IndicatorID == 130)
output_meta$MetaValue[mask] = paste("Solihull data currently unavailable.", output_meta$MetaValue[mask])

# ID 118 numerator definition
mask = (output_meta$ItemID == 2 & output_meta$IndicatorID == 118) 
output_meta$MetaValue[mask] = "The number of deaths among adults in drug treatment in the local authority."
# ID 118 denominator definition
mask = (output_meta$ItemID == 3 & output_meta$IndicatorID == 118) 
output_meta$MetaValue[mask] = "The number of adults in drug treatment in the local authority."
# ID 118 polarity
mask = (output_meta$ItemID == 5 & output_meta$IndicatorID == 118) 
output_meta$MetaValue[mask] = "Low is good."
# ID 118 rate type
mask = (output_meta$ItemID == 6 & output_meta$IndicatorID == 118) 
output_meta$MetaValue[mask] = "Rate per 1,000"

# ID 119 numerator definition
mask = (output_meta$ItemID == 2 & output_meta$IndicatorID == 119) 
output_meta$MetaValue[mask] = "The number of deaths among adults in alcohol treatment in the local authority."
# ID 119 denominator definition
mask = (output_meta$ItemID == 3 & output_meta$IndicatorID == 119) 
output_meta$MetaValue[mask] = "The number of adults in alcohol treatment in the local authority."
# ID 119 polarity
mask = (output_meta$ItemID == 5 & output_meta$IndicatorID == 119) 
output_meta$MetaValue[mask] = "Low is good."
# ID 119 rate type
mask = (output_meta$ItemID == 6 & output_meta$IndicatorID == 119) 
output_meta$MetaValue[mask] = "Rate per 1,000"
#######################################################################
#####                      Save meta data                         #####
#######################################################################

write.csv(
  output_meta, 
  "../../data/output/birmingham-source/meta/LA_Other_meta.csv"
)
