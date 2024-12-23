#################################################################
# INdicatorID:  128
# Fingertips ID: 93966
# Created on: 30/09/2024

# Author: Chris Mainey <c.mainey1@nhs.net>
# Summary:  Download indicaotr 93966 from fingertips API at all relevant
#           BSOL geographies, union /bind together, and export

################################################################
library(fingertipsR)

england<- fingertips_data(IndicatorID = 93966
                          , AreaCode = c('E92000001')
                          , AreaTypeID = "All"#2
                          #                        #             , 221 # ICB
                          #                         #            , 204 # PCN
                          #                  )
)

bsol<- fingertips_data(IndicatorID = 93966
                       #
                       , AreaCode = c('nE54000055')
                       , AreaTypeID = 221
                       #221 # ICB
                       #                         #            , 204 # PCN
                       #                  )
)



pcn<- fingertips_data(IndicatorID = 93966
                      #
                      , AreaCode = c("U47609", "U54948", "U79433", "U46437", "U27366"
                                     , "U25587", "U27129", "U82305", "U67607", "U46454"
                                     , "U65968", "U18195", "U74554", "U44537", "U69625"
                                     , "U79003", "U43660", "U93165", "U25240", "U88190"
                                     , "U54554", "U79381", "U72309", "U15552", "U22471"
                                     , "U45528", "U41928", "U00351", "U13655", "U91268"
                                     , "U65039", "U48923", "U76419", "U51153", "U44365" )
                      , AreaTypeID = "204"
                      #221 # ICB
                      #                         #            , 204 # PCN
                      #                  )
)


library(dplyr)

out <- 
  england %>% 
  bind_rows(bsol, pcn)


library(DBI)
con <- dbConnect(odbc::odbc(), .connection_string = "Driver={SQL Server};server=MLCSU-BI-SQL;database=EAT_Reporting_BSOL", 
                 timeout = 10)


out_gp_wrk <- Id("OF","128_GPworkforce")  
DBI::dbWriteTable(con, out_gp_wrk, out, overwrite = TRUE)
