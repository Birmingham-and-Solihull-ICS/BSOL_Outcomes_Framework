########################################################################################################
#
# Program : REQ3273_20602_LocalData.R
#
# 26-04-2024
#
#    
# PURPOSE :- This .R script is used to extract the latest year Birmingham original NCMP Obesity data
#            and calculate the BMI scores by Localities, Districts and the '2018 Wards' in Birmingham
#            for the fingertips indicator '20602 : Year 6 prevalence of overweight (including obesity)'.
# 
#
#
# Note :- 1. The value of the 20602 indicator on fingertips is a "crude rate" (ie 'crude rate per 100', a percentage).
#
#         2. This R-script creates the following csv data file :-
#
#                 S:\Intelligence\2. Requests\REQ3273 - Indicator development group with BSOL ICB\REQ3273_20602_LocalData.csv
#
#                 - which gets loaded onto the following sql table on the CSU SQL Server :-
#
#                                                                                            IndicatorsValue
#         3. This R script takes approximately 2 minutes to run.
#
#
#
########################################################################################################


########################################################################################################
#
# Step 1 : Load in Libraries we will be using.
#
#
########################################################################################################

library(PHEindicatormethods)
library(openxlsx)
library(tmap)         
library(readxl)
library(sqldf)
library(pool)
library(odbc)
library(dplyr)
library(stringr)
library(sf)
library(leaflet)
library(mapview)     
library(htmlwidgets)
library(htmltools)
library(webshot)

########################################################################################################


########################################################################################################
#
# Step 2 : Read in the original LAs NCMP data for latest year.
#          Calculate the BMI scores. Note the following :-
#
#           (i)  Formula to calculate BMI depends on two fields only (ie Height and Weight).
#                The BMI calculation does not depend on fields Age and Sex.
#           (ii) When extracting/calculating BMI scores we normally extract the fields Age and Sex
#                also. This is due to the classification of BMI scores that determine whether a child
#                is overweight or not. These "BMI cutoffs" as they are known do depend on the Age and Sex 
#                of the child. So to determine if the BMI score for a child is overweight or not we need 
#                to extract the fields Age and Sex also.
#
#
########################################################################################################

########################################################################################################
#
# Step 2a : Need to read in the relevant table to calculate the BMI scores.
#
#           Table : tblTemp1  (on SQL Server)
#
#
########################################################################################################

conpool <- pool::dbPool(drv = odbc::odbc(), Driver="SQL Server", Server="Redacted", Database="PH_Requests", Trusted_Connection="True")           # ie setting up an ODBC connection to SQL Server.

# ie Create a string variable containing our SQL string (NB As R does not like spaces in column names we need to remove them)
str_SQL_Code <- "SELECT '         ' AS [Period],
       T1.[SchoolYear],
       T1.[DoH_URN],
       T1.[School_Year],
       T1.[ClassofPupil],
       T1.[PupilFirstname],
       T1.[PupilSurname],
       T1.[Gender],
       T1.[DateofBirth],
       T1.[Ethnic_Group],
       T1.[PostcodeofPupil],
       T1.[ConsentofPupil],
       T1.[DateofMeasurement],
       T1.[Height],
       T1.[Weight],
       [Age] =
         CASE
         -- scenario when we have valid dates
            WHEN ((ISDATE(T1.[DateofBirth]) = 1) AND (ISDATE(T1.[DateofMeasurement]) = 1)) THEN CONVERT(DECIMAL(6,1), DATEDIFF(dd, T1.[DateofBirth], T1.[DateofMeasurement])/CONVERT(DECIMAL(6,0), 365))
         END,
       CONVERT(DECIMAL(6,2), CONVERT(DECIMAL(15,8), T1.[Weight])/(CONVERT(DECIMAL(15,8), T1.[Height])/100*CONVERT(DECIMAL(15,8), T1.[Height]/100))) AS 'BMI score',
       T1.[BMI_p]
  INTO tblTemp1
  FROM PH_Obesity.dbo.[tblMainTable] T1
    WHERE (((CONVERT(INTEGER, SUBSTRING(T1.[SchoolYear],1,4)) = (SELECT MAX(CONVERT(INTEGER, SUBSTRING(T2.[SchoolYear],1,4)))
                                                                   FROM [PH_Obesity].dbo.[tblMainTable] T2))) AND
           (T1.[School_Year] = 'Year 6'))"

DBI::dbExecute(conpool, str_SQL_Code)   # ie running a data manipulation query


# ie update the [Period]
str_SQL_Code <- "UPDATE tblTemp1
  SET [Period] = (SELECT CONVERT(VARCHAR(4), MAX(CONVERT(INTEGER, SUBSTRING(T1.[SchoolYear],1,4)))) FROM tblTemp1 T1) + '/' + (SELECT CONVERT(VARCHAR(4), MAX(CONVERT(INTEGER, SUBSTRING(T1.[SchoolYear],1,4))+1)) FROM tblTemp1 T1)"

DBI::dbExecute(conpool, str_SQL_Code)   # ie running a data manipulation query


str_SQL_Code <- "DELETE 
                   FROM tblTemp1
                     WHERE ([BMI score] IS NULL)"

DBI::dbExecute(conpool, str_SQL_Code)   # ie running a data manipulation query


str_SQL_Code <- "DELETE 
                   FROM tblTemp1
                     WHERE ([BMI_p] IS NULL)"

DBI::dbExecute(conpool, str_SQL_Code)   # ie running a data manipulation query


########################################################################################################



########################################################################################################
#
# Step 2b  : Determine if a child is overweight or not. To do this we need to round the childs Age to the value as
#            specified in our lookup table.
#
#
########################################################################################################

########################################################################################################
#
# Step 2b1 : Obtain the Age value from our lookup table, which will be a "rounded" Age and be the Age used to
#            determine whether a child is overweight or not.
#
#            Table : tblTemp2  (on SQL Server)
#
#
########################################################################################################

str_SQL_Code <- "SELECT T1.[Period],
       T1.[SchoolYear],
       T1.[DoH_URN],
       T1.[School_Year],
       T1.[ClassofPupil],
       T1.[PupilFirstname],
       T1.[PupilSurname],
       T1.[Gender],
       T1.[DateofBirth],
       T1.[Ethnic_Group],
       T1.[PostcodeofPupil],
       T1.[ConsentofPupil],
       T1.[DateofMeasurement],
       T1.[Height],
       T1.[Weight],
       T1.[Age],
       T1.[BMI score],
       T1.[BMI_p],
       T2.[Age at Test]
  INTO tblTemp2
  FROM tblTemp1 T1 LEFT OUTER JOIN
       PH_Obesity.dbo.[tlkpAgeattestValues] T2 ON
         T1.[Age] = T2.[Age]"

DBI::dbExecute(conpool, str_SQL_Code)   # ie running a data manipulation query


########################################################################################################


########################################################################################################
#
# Step 2c : Obtain the BMI percentile scores which enable us to determine whether a child is overweight or not.
#
#           Table : tblTemp3  (on SQL Server)
#
#
########################################################################################################

str_SQL_Code <- "SELECT T1.[Period],
       T1.[SchoolYear],
       T1.[DoH_URN],
       T1.[School_Year],
       T1.[ClassofPupil],
       T1.[PupilFirstname],
       T1.[PupilSurname],
       T1.[Gender],
       T1.[DateofBirth],
       T1.[Ethnic_Group],
       T1.[PostcodeofPupil],
       T1.[ConsentofPupil],
       T1.[DateofMeasurement],
       T1.[Height],
       T1.[Weight],
       T1.[Age],
       T1.[BMI score],
       T1.[BMI_p],
       T1.[Age at Test],
       T2.[Overweight (85th centile)],
       T2.[Obese (95th centile)],
/*
       [BMI Category (centiles)] =
         CASE
         -- scenario when child is normal
            WHEN ((T1.[BMI score] IS NOT NULL) AND
                  (T2.[Overweight (85th centile)] IS NOT NULL) AND
                  (T2.[Obese (95th centile)] IS NOT NULL) AND
                  (T1.[BMI score] < T2.[Overweight (85th centile)])) THEN 'Normal'
         -- scenario when child is overweight
            WHEN ((T1.[BMI score] IS NOT NULL) AND
                  (T2.[Overweight (85th centile)] IS NOT NULL) AND
                  (T2.[Obese (95th centile)] IS NOT NULL) AND
                  (T1.[BMI score] >= T2.[Overweight (85th centile)]) AND
                  (T1.[BMI score] < T2.[Obese (95th centile)])) THEN 'Overweight'
         -- scenario when child is obese
            WHEN ((T1.[BMI score] IS NOT NULL) AND
                  (T2.[Overweight (85th centile)] IS NOT NULL) AND
                  (T2.[Obese (95th centile)] IS NOT NULL) AND
                  (T1.[BMI score] >= T2.[Obese (95th centile)])) THEN 'Obese'
         END
*/
       [BMI Category (centiles)] =
         CASE
         -- scenario when child is 'Underweight'
            WHEN (T1.[BMI_p] <= 0.02) THEN 'Underweight'
         -- scenario when child is 'Healthy Weight'
            WHEN (T1.[BMI_p] > 0.02) AND
                 (T1.[BMI_p] < 0.85)  THEN 'Healthy Weight'
         -- scenario when child is 'Overweight'
            WHEN (T1.[BMI_p] >= 0.85) AND
                 (T1.[BMI_p] < 0.95)  THEN 'Overweight'
         -- scenario when child is 'Obese'
            WHEN (T1.[BMI_p] >= 0.95) THEN 'Obese'
         END
  INTO tblTemp3
  FROM tblTemp2 T1 LEFT OUTER JOIN
       PH_Obesity.dbo.[tlkpBMI_cutoffs] T2 ON
         T1.[Gender] = T2.[Gender] AND
         T1.[Age at Test] = T2.[Age at Test]"

DBI::dbExecute(conpool, str_SQL_Code)   # ie running a data manipulation query


########################################################################################################


########################################################################################################
#
# Step 3 : Add the Districts and the '2018 Wards' to our NCMP dataset.
#
#          Table : tblTemp4  (on SQL Server)
#
#
########################################################################################################

str_SQL_Code <- "SELECT T1.[Period],
       T1.[SchoolYear],
       T1.[DoH_URN],
       T1.[School_Year],
       T1.[ClassofPupil],
       T1.[PupilFirstname],
       T1.[PupilSurname],
       T1.[Gender],
       T1.[DateofBirth],
       T1.[Ethnic_Group],
       T1.[PostcodeofPupil],
       T1.[ConsentofPupil],
       T1.[DateofMeasurement],
       T1.[Height],
       T1.[Weight],
       T1.[Age],
       T1.[BMI score],
       T1.[BMI_p],
       T1.[Age at Test],
       T1.[Overweight (85th centile)],
       T1.[Obese (95th centile)],
       T1.[BMI Category (centiles)],
       T2.[Westminster Parliamentary constituency],
       T2.[2018 Ward Code],
       T3.[2018 Ward Name]
  INTO tblTemp4
  FROM tblTemp3 T1 INNER JOIN
       PH_LookUps.dbo.[vw_tblNWWMClusterFullPostcodeFile] T2 ON
         T1.[PostcodeofPupil] = T2.[Postcod8] COLLATE SQL_Latin1_General_CP1_CI_AS INNER JOIN 
           PH_LookUps.dbo.[tlkpWardNames2018byBham] T3 ON
             T2.[2018 Ward Code] = T3.[2018 Ward Code]"

DBI::dbExecute(conpool, str_SQL_Code)   # ie running a data manipulation query


# ie add field to the dataset
str_SQL_Code <- "ALTER TABLE tblTemp4 ADD [2006 (10) Districts] NVARCHAR(20)"

DBI::dbExecute(conpool, str_SQL_Code)   # ie running a data manipulation query

# ie add field to the dataset
str_SQL_Code <- "ALTER TABLE tblTemp4 ADD [Localities] VARCHAR(20)"

DBI::dbExecute(conpool, str_SQL_Code)   # ie running a data manipulation query

str_SQL_Code <- "UPDATE tblTemp4
  SET [2006 (10) Districts] = T3.[2006 (10) Districts],
      [Localities]          = T3.[Localities]
    FROM tblTemp4 T1 INNER JOIN
         (SELECT T2.[2006 (10) Districts Code],
                 T2.[2006 (10) Districts],
                 T2.[Localities]
            FROM [PH_LookUps].dbo.[tlkpWardNames2004byBhamPCTs] T2
              GROUP BY T2.[2006 (10) Districts Code],
                       T2.[2006 (10) Districts],
                       T2.[Localities]) T3 ON
           T1.[Westminster Parliamentary constituency] = T3.[2006 (10) Districts Code]"

DBI::dbExecute(conpool, str_SQL_Code)   # ie running a data manipulation query


########################################################################################################


########################################################################################################
#
# Step 4 : Read in Excel worksheet 'Aggregation' from our workbook "OF-Other-Tables.xlsx" so that we can
#          identify the relevant geographies.
#
#          Table : tblTemp5  (on SQL Server)
#
#
########################################################################################################

# IMPORTANT NOTE :- This part will produce an error due to the backslash '\' being a special character in R 
#                   so we need to make it allowances for it, essentially we need to repeat the '\' character
#                   to get it to work. See this website for the solution :-  https://stackoverflow.com/questions/11806501/how-to-escape-backslashes-in-r-string
#
# str_SQL_Code <- "SELECT T1.[AggregationID],
#       T1.[AggregationType],
#       T1.[AggregationCode],
#       T1.[AggregationLabel]
#  INTO tblTemp5
#  FROM OPENROWSET('Microsoft.ACE.OLEDB.16.0','Excel 12.0;HDR=YES;Database=\\Redacted\Intelligence\2. Requests\REQ3273 - Indicator development group with BSOL ICB\OF-Other-Tables.xlsx', 'SELECT * FROM [Aggregation$A1:D]') T1"

# DBI::dbExecute(conpool, str_SQL_Code)   # ie running a data manipulation query


str_SQL_Code1 <- "SELECT T1.[AggregationID],
       T1.[AggregationType],
       T1.[AggregationCode],
       T1.[AggregationLabel]
  INTO tblTemp5
  FROM OPENROWSET('Microsoft.ACE.OLEDB.16.0','Excel 12.0;HDR=YES;Database="

str_SQL_Code2 <- "Redacted"

str_SQL_Code3 <- "PHSensitive$"

str_SQL_Code4 <- "Intelligence"

str_SQL_Code5 <- "2. Requests"

str_SQL_Code6 <- "REQ3273 - Indicator development group with BSOL ICB"

str_SQL_Code7 <- "OF-Other-Tables.xlsx', 'SELECT * FROM [Aggregation$A1:D]') T1"

str_SQL_Code <- base::paste0(str_SQL_Code1, "\\\\", 
                             str_SQL_Code2, "\\",
                             str_SQL_Code3, "\\",
                             str_SQL_Code4, "\\",
                             str_SQL_Code5, "\\",
                             str_SQL_Code6, "\\",
                             str_SQL_Code7)

DBI::dbExecute(conpool, str_SQL_Code)   # ie running a data manipulation query


########################################################################################################


########################################################################################################
#
# Step 5 : Aggregate the stats.
#
#          Table : tblTemp6  (on SQL Server)
#
#
########################################################################################################

str_SQL_Code <- "

-- ie aggregate the stats for the Wards

SELECT T1.[Period],
        ROW_NUMBER() OVER (PARTITION BY T1.[Period] ORDER BY T1.[2018 Ward Code]) AS [ValueID],        
       20602 AS [IndicatorID],
       FORMAT(GetDate(), 'dd/MM/yyyy') AS [InsertDate],
       'Ward' AS [Area Type],
       T1.[2018 Ward Code] AS [Area Code],
       T1.[2018 Ward Name] AS [Area Name],
       (SELECT T2.[AggregationID]
          FROM tblTemp5 T2
            WHERE ((T2.[AggregationType] = 'Ward') AND 
                   (T2.[AggregationCode] = T1.[2018 Ward Code] COLLATE Latin1_General_CI_AS))) AS [AggID],
       (SELECT COUNT(*)
          FROM tblTemp4 T2
            WHERE ((T2.[Period]         = T1.[Period]) AND
                   (T2.[2018 Ward Code] = T1.[2018 Ward Code]) AND
                   (T2.[BMI Category (centiles)] IN ('Overweight', 'Obese')))) AS [Numerator],
       COUNT(*) AS [Denominator],
       NULL AS [DemographicID],  
       1 AS [DataQualityID],
       '01/09/' + SUBSTRING(T1.[Period],1,4) AS [IndicatorStartDate],
       '31/08/' + SUBSTRING(T1.[Period],6,4) AS [IndicatorEndDate]
  INTO tblTemp6
  FROM tblTemp4 T1
    GROUP BY T1.[Period], 
             T1.[2018 Ward Code],
             T1.[2018 Ward Name]

-- ie aggregate the stats for the Constituencies

UNION ALL SELECT T1.[Period],
        ROW_NUMBER() OVER (PARTITION BY T1.[Period] ORDER BY T1.[Westminster Parliamentary constituency]) AS [ValueID],        
       20602 AS [IndicatorID],
       FORMAT(GetDate(), 'dd/MM/yyyy') AS [InsertDate],
       'Constituency' AS [Area Type],
       T1.[Westminster Parliamentary constituency] AS [Area Code],
       T1.[2006 (10) Districts] COLLATE SQL_Latin1_General_CP1_CI_AS AS [Area Name],
       (SELECT T2.[AggregationID]
          FROM tblTemp5 T2
            WHERE ((T2.[AggregationType] = 'Constituency') AND 
                   (T2.[AggregationCode] = T1.[Westminster Parliamentary constituency] COLLATE Latin1_General_CI_AS))) AS [AggID],
       (SELECT COUNT(*)
          FROM tblTemp4 T2
            WHERE ((T2.[Period]                                 = T1.[Period]) AND
                   (T2.[Westminster Parliamentary constituency] = T1.[Westminster Parliamentary constituency]) AND
                   (T2.[BMI Category (centiles)] IN ('Overweight', 'Obese')))) AS [Numerator],
       COUNT(*) AS [Denominator],
       NULL AS [DemographicID],  
       1 AS [DataQualityID],
       '01/09/' + SUBSTRING(T1.[Period],1,4) AS [IndicatorStartDate],
       '31/08/' + SUBSTRING(T1.[Period],6,4) AS [IndicatorEndDate]
  FROM tblTemp4 T1
    GROUP BY T1.[Period], 
             T1.[Westminster Parliamentary constituency],
             T1.[2006 (10) Districts]

-- ie aggregate the stats for the Localities

UNION ALL SELECT T1.[Period],
        ROW_NUMBER() OVER (PARTITION BY T1.[Period] ORDER BY T1.[Localities]) AS [ValueID],        
       20602 AS [IndicatorID],
       FORMAT(GetDate(), 'dd/MM/yyyy') AS [InsertDate],
       'Localities' AS [Area Type],
       T1.[Localities] COLLATE SQL_Latin1_General_CP1_CI_AS AS [Area Code],
       T1.[Localities] COLLATE SQL_Latin1_General_CP1_CI_AS AS [Area Name],
       (SELECT T2.[AggregationID]
          FROM tblTemp5 T2
            WHERE ((T2.[AggregationType] = 'Locality (resident)') AND 
                   (T2.[AggregationLabel] + ' Locality' = T1.[Localities] COLLATE Latin1_General_CI_AS))) AS [AggID],
       (SELECT COUNT(*)
          FROM tblTemp4 T2
            WHERE ((T2.[Period]     = T1.[Period]) AND
                   (T2.[Localities] = T1.[Localities]) AND
                   (T2.[BMI Category (centiles)] IN ('Overweight', 'Obese')))) AS [Numerator],
       COUNT(*) AS [Denominator],
       NULL AS [DemographicID],  
       1 AS [DataQualityID],
       '01/09/' + SUBSTRING(T1.[Period],1,4) AS [IndicatorStartDate],
       '31/08/' + SUBSTRING(T1.[Period],6,4) AS [IndicatorEndDate]
  FROM tblTemp4 T1
    GROUP BY T1.[Period], 
             T1.[Localities] "

DBI::dbExecute(conpool, str_SQL_Code)   # ie running a data manipulation query


str_SQL_Code <- "

-- ie From our workbook OF-Other-Tables.xlsx, worksheet 'IndicatorList', the 20602 fingertips indicator has the IndicatorID value of 9.
UPDATE tblTemp6
  SET [IndicatorID] = '9'
    WHERE [IndicatorID] = '20602'"

DBI::dbExecute(conpool, str_SQL_Code)   # ie running a data manipulation query


str_SQL_Code <- "

-- ie From our workbook OF-Other-Tables.xlsx, worksheet 'Demographic' we are obtaining the values for the field [DemographicID].
UPDATE tblTemp6
  SET [DemographicID] = 37
--    WHERE (([Sex] = 'Persons') AND
--           ([Age] = '10-11 yrs'))"

DBI::dbExecute(conpool, str_SQL_Code)   # ie running a data manipulation query


########################################################################################################


########################################################################################################
#
# Step 6 : Read our sql table into R.
#
#          Table : df_tblTemp6
#
#
########################################################################################################

conpool <- pool::dbPool(drv = odbc::odbc(), Driver="SQL Server", Server="Redacted", Database="PH_Requests", Trusted_Connection="True")           # ie setting up an ODBC connection to SQL Server.

df_tblTemp6 <- DBI::dbGetQuery(conpool, "SELECT * FROM [tblTemp6]")  # ie import the sql table into R as a dataframe


########################################################################################################


########################################################################################################
#
# Step 7 : Add our Wilson confidence intervals to the dataframe.
#
#          Table : df_tblTemp8
#
#
########################################################################################################

df_tblTemp7 <- PHEindicatormethods::phe_proportion(data = df_tblTemp6, 
                                                      x = `Numerator`,
                                                      n = Denominator,
                                                      type = "full",
                                                      confidence = 0.95,
                                                      multiplier = 100)

# ie Rename some of the columns in our dataframe.
df_tblTemp8 <- plyr::rename(x = df_tblTemp7,
                            replace = c("value" = "IndicatorValue",
                                        "lowercl" = "LowerCI95",
                                        "uppercl" = "UpperCI95"))


########################################################################################################


########################################################################################################
#
# Step 8 : Restrict our fields to the ones of interest.
#
#          Table : df_tblTemp10
#
#
########################################################################################################

# ie select the fields of interest.
df_tblTemp9 <- base::subset(x = df_tblTemp8, 
                            select = c(ValueID,
                                       IndicatorID,
                                       InsertDate,
                                       Numerator,
                                       Denominator,
                                       IndicatorValue,
                                       LowerCI95,
                                       UpperCI95,
                                       AggID,
                                       DemographicID,     
                                       DataQualityID,
                                       IndicatorStartDate,
                                       IndicatorEndDate))


# ie order our dataframe
df_tblTemp10 <- df_tblTemp9[base::order(df_tblTemp9$`IndicatorID`, 
                                        df_tblTemp9$`IndicatorStartDate`,    
                                        df_tblTemp9$AggID, decreasing = c(FALSE, TRUE, FALSE), method="radix"),]                  # ie we are sorting the dataframe by multiple columns (and by ascending or descending).


########################################################################################################


########################################################################################################
#
# Step 9 : Write our dataframe to a .csv file called "REQ3273_20602_LocalData.csv".
#
#          Table : df_tblTemp10
#
#
########################################################################################################

# Write dataframe to external csv file (note file is automatically overwritten if it already exists).
utils::write.table(x    = df_tblTemp10, 
                  file = "//Redacted/PHSensitive$/Intelligence/2. Requests/REQ3273 - Indicator development group with BSOL ICB/REQ3273_20602_LocalData.csv",
                  sep=",",
                  col.names = TRUE,                   # ie write header record
                  append = FALSE,
                  row.names = FALSE)


########################################################################################################



########################################################################################################
#
# Step 10 : Delete all the Temporary tables created in the routine.
#
#           Tables : tblTemp1
#                    tblTemp2
#                    tblTemp3
#                    tblTemp4
#                    tblTemp5
#                    tblTemp6
#
########################################################################################################


# ie data cleansing step : delete our temporary table from our SQL Server.
str_SQL_Code <- "DROP TABLE IF EXISTS tblTemp1"
DBI::dbExecute(conpool, str_SQL_Code)   # ie running a data manipulation query

# ie data cleansing step : delete our temporary table from our SQL Server.
str_SQL_Code <- "DROP TABLE IF EXISTS tblTemp2"
DBI::dbExecute(conpool, str_SQL_Code)   # ie running a data manipulation query

# ie data cleansing step : delete our temporary table from our SQL Server.
str_SQL_Code <- "DROP TABLE IF EXISTS tblTemp3"
DBI::dbExecute(conpool, str_SQL_Code)   # ie running a data manipulation query

# ie data cleansing step : delete our temporary table from our SQL Server.
str_SQL_Code <- "DROP TABLE IF EXISTS tblTemp4"
DBI::dbExecute(conpool, str_SQL_Code)   # ie running a data manipulation query

# ie data cleansing step : delete our temporary table from our SQL Server.
str_SQL_Code <- "DROP TABLE IF EXISTS tblTemp5"
DBI::dbExecute(conpool, str_SQL_Code)   # ie running a data manipulation query

# ie data cleansing step : delete our temporary table from our SQL Server.
str_SQL_Code <- "DROP TABLE IF EXISTS tblTemp6"
DBI::dbExecute(conpool, str_SQL_Code)   # ie running a data manipulation query


########################################################################################################




########################################################################################################
#
# Step 11 extra : This part loads our csv datafile into our SQL Server table using sql code only.
#
#                 IMPORTANT NOTE :-  This part has been written to be run on the CSU SQL Server.   
#
#
#                 Table : [IndicatorsValue]   (ie on CSU SQL Server)
#
#
########################################################################################################

INSERT INTO [IndicatorsValue] ([ValueID],
                               [IndicatorID],
                               [InsertDate],
                               [Numerator],
                               [Denominator],
                               [IndicatorValue],
                               [LowerCI95],
                               [UpperCI95],
                               [AggID],
                               [DemographicID],     
                               [DataQualityID],
                               [IndicatorStartDate],
                               [IndicatorEndDate])
  SELECT T1.[ValueID],
         T1.[IndicatorID],
         T1.[InsertDate],
         T1.[Numerator],
         T1.[Denominator],
         T1.[IndicatorValue],
         T1.[LowerCI95],
         T1.[UpperCI95],
         T1.[AggID],
         T1.[DemographicID],     
         T1.[DataQualityID],
         T1.[IndicatorStartDate],
         T1.[IndicatorEndDate]
    FROM OPENDATASOURCE('Microsoft.ACE.OLEDB.16.0',
                        'Data Source=\\Redacted\Intelligence\2. Requests\REQ3273 - Indicator development group with BSOL ICB;
                         Extended Properties=Text')...[REQ3273_20602_LocalData#csv] T1   

GO

########################################################################################################