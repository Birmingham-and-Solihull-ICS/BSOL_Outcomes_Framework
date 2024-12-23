USE PH_Requests

/*
   Program : REQ3273_20601_FingertipsData.sql 
 
==========
01-05-2024
==========
 PURPOSE : This .SQL program is used to extract all available data on fingertips for the following 
           fingertips indicator :-
                                   '20601 : Reception prevalence of overweight (including obesity)'

           for the following geographies :-
                                            England                        - E92000001
                                            Birmingham and Solihull ICB    - E54000055
                                            Birmingham LA                  - E08000025
                                            Solihull LA                    - E08000029


    Note :  1. The value of the 20601 indicator on fingertips is a "crude rate" (ie 'crude rate per 100', a percentage).

            2. The data has been extracted from the fingertips website by running the following API :-

                                 https://fingertips.phe.org.uk/api/all_data/csv/for_one_indicator?indicator_id=20601


            3. This sql script creates the following csv data file :-

                 S:\Intelligence\2. Requests\REQ3273 - Indicator development group with BSOL ICB\REQ3273_20601_FingertipData.csv

                 - which gets loaded onto the following sql table on the CSU SQL Server :-

                                                                                            IndicatorsValue
            4. This sql script works on our SQL Server Agent.

            5. This sql script takes approximately 2 minutes to run.

*/
   
  /* NB  In stored procedures we can pass a parameter as a value but not as a table name      
          - ie due to SQL compiling the stored procedure
  */


/***************************************************************************************************************/


/* Step 0 : set the Required System options (NB This Stored Procedure cannot be created without setting these options)
*/

/*
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
*/

/***************************************************************************************************************/


/* Step 1 : Import the data into our main table by loading in all the data in the API for the indicator.

            IMPORTANT NOTE :-  For this API, fingertips has a maximum limit of 100 indicators we can run.


            Table : tblTemp1
*/

DECLARE @strAPICall VARCHAR(8000)             
  SET @strAPICall = CHAR(34) + 'https://fingertips.phe.org.uk/api/all_data/csv/for_one_indicator?indicator_id=20601' + CHAR(34)

DECLARE @intReturnCode INTEGER
EXECUTE @intReturnCode = [PH_Data].dbo.usp_Run_API_CSVFormat_FastUpload @strInputGlobalAPICall                 = @strAPICall,
                                                                        @strInputGlobalSQLDatabaseName         = 'PH_Requests',   -- ie SQL database we want the API data uploaded to
                                                                        @strInputGlobalSQLTablename            = 'tblTemp1',      -- ie SQL table we are creating with the API data in 
                                                                        @strInputGlobalChangeColumnTypeinTable = 'Y',             -- ie if we need to change our field column types
                                                                        @strInputGlobalChangeColumnTypesValue  = 'VARCHAR(500)',  -- ie new value for our field column types
                                                                        @strInputGlobalPauseExecution          = 'Y'              -- ie defaults to 'N' set to 'Y' to pause execution for 10 seconds (which is sometimes needed for large API downloads)

PRINT @intReturnCode

DECLARE @intTotalNumberofRecordsUploaded INTEGER
SELECT @intTotalNumberofRecordsUploaded = COUNT(*)
  FROM tblTemp1

PRINT 'The API call is :- ' + @strAPICall
PRINT 'The number of records loaded into our sql table (ie tblTemp1) from our API call is :- ' + CONVERT(VARCHAR(20),  @intTotalNumberofRecordsUploaded)

GO


-- ie correction for 'Birmingham and Solihull ICB' code
UPDATE tblTemp1
  SET [Area Code] = 'E54000055'
    FROM tblTemp1 T1
      WHERE (T1.[Area Code] = 'nE54000055')

GO

/***************************************************************************************************************/

/* Step 2 : Extract the data for our geographies.

            Table : tblTemp2
*/

SELECT T1.[Indicator ID],
       T1.[Indicator Name],
       T1.[Parent Code],
       T1.[Parent Name],
       T1.[Area Code],
       T1.[Area Name],
       T1.[Area Type],
       T1.[Sex],
       T1.[Age],
       T1.[Category Type],
       T1.[Category],
       T1.[Time period],
       T1.[Value],
       T1.[Lower CI 95#0 limit],
       T1.[Upper CI 95#0 limit],
       T1.[Lower CI 99#8 limit],
       T1.[Upper CI 99#8 limit],
       T1.[Count],
       T1.[Denominator],
       T1.[Value note],
       T1.[Recent Trend],
       T1.[Compared to England value or percentiles],
       T1.[Column not used],
       T1.[Time period Sortable],
       T1.[New data],
       T1.[Compared to goal],
       T1.[Time period range]
  INTO tblTemp2
  FROM tblTemp1 T1
    WHERE ((T1.[Sex] = 'Persons') AND
           (T1.[Category] IS NULL) AND
           (T1.[Area Code] IN ('E92000001', 'E54000055', 'E08000025', 'E08000029')))            -- ie England, Birmingham and Solihull ICB, Birmingham LA and Solihull LA 
GO

/***************************************************************************************************************/


/* Step 3 : Read in Excel worksheet 'Aggregation' from our workbook "OF-Other-Tables.xlsx" so that we can
            identify the relevant geographies.

            Table : tblTemp3
*/

SELECT T1.[AggregationID],
       T1.[AggregationType],
       T1.[AggregationCode],
       T1.[AggregationLabel]
  INTO tblTemp3
  FROM OPENROWSET('Microsoft.ACE.OLEDB.16.0','Excel 12.0;HDR=YES;Database=\\Redacted\Intelligence\2. Requests\REQ3273 - Indicator development group with BSOL ICB\OF-Other-Tables.xlsx', 'SELECT * FROM [Aggregation$A1:D]') T1

GO

/***************************************************************************************************************/


/* Step 4 : Extract the relevant data for our geographies.

            Table : tblTemp4
*/

SELECT T1.[Indicator ID] AS [IndicatorID],
       FORMAT(GetDate(), 'dd/MM/yyyy') AS [InsertDate],
       T1.[Indicator Name],
       T1.[Parent Code],
       T1.[Parent Name],
       T1.[Area Code],
       (SELECT T2.[AggregationID]
          FROM tblTemp3 T2
            WHERE (T2.[AggregationCode] = T1.[Area Code])) AS [AggID],
       T1.[Area Name],
       T1.[Area Type],
       T1.[Sex],
       T1.[Age],
       T1.[Category Type],
       T1.[Category],
       T1.[Time period],
       T1.[Value],
       T1.[Lower CI 95#0 limit],
       T1.[Upper CI 95#0 limit],
       T1.[Lower CI 99#8 limit],
       T1.[Upper CI 99#8 limit],
       T1.[Count],
       T1.[Denominator],
       T1.[Value note],
       T1.[Recent Trend],
       T1.[Compared to England value or percentiles],
       T1.[Column not used],
       T1.[Time period Sortable],
       '01/09/' + SUBSTRING(T1.[Time period Sortable],1,4) AS [IndicatorStartDate],
       '31/08/' + CONVERT(VARCHAR(4), (CONVERT(INTEGER, SUBSTRING(T1.[Time period Sortable],1,4)) + 1)) AS [IndicatorEndDate],
       T1.[New data],
       T1.[Compared to goal],
       T1.[Time period range],
       NULL AS [DemographicID],  
       1 AS [DataQualityID]
  INTO tblTemp4
  FROM tblTemp2 T1

GO

-- ie From our workbook "OF-Other-Tables.xlsx", worksheet 'IndicatorList', the 20601 fingertips indicator has the IndicatorID value of 8.
UPDATE tblTemp4
  SET [IndicatorID] = '8'
    WHERE [IndicatorID] = '20601'
GO

-- ie From our workbook "OF-Other-Tables.xlsx", worksheet 'Aggregation' the BSOL ICB has a different code from the one we are using - so we need to correct this manually.
UPDATE tblTemp4
  SET [AggID] = '148'
    WHERE [Area Code] = 'E54000055'
GO

-- ie From our workbook "OF-Other-Tables.xlsx", worksheet 'Demographic' we are obtaining the values for the field [DemographicID].
UPDATE tblTemp4
  SET [DemographicID] = 28
    WHERE (([Sex] = 'Persons') AND
           ([Age] = '4-5 yrs'))
GO
 
/***************************************************************************************************************/

/* Step 5 : Restrict our fields to the ones of interest.

            Table : tblTemp5
*/

SELECT ROW_NUMBER() OVER (PARTITION BY T1.[AggID] ORDER BY T1.[AggID]) AS [ValueID],        
       T1.[IndicatorID],
       T1.[InsertDate],
       T1.[Count] AS [Numerator],
       T1.[Denominator],
       T1.[Value] AS [IndicatorValue],
       T1.[Lower CI 95#0 limit] AS [LowerCI95],
       T1.[Upper CI 95#0 limit] AS [UpperCI95],
       T1.[AggID],
       T1.[DemographicID],     
       T1.[DataQualityID],
       T1.[IndicatorStartDate],
       T1.[IndicatorEndDate]
  INTO tblTemp5
  FROM tblTemp4 T1
    WHERE (T1.[Value] IS NOT NULL)

GO

/***************************************************************************************************************/


/* Step 6 : Write our data to a *.csv file called "REQ3273_20601_FingertipsData.csv".

            Investigated the following options :-

                                                 (a) bcp    - The "bcp" routine does not require the csv file to exist beforehand and any file created is automatically overwritten,
                                                              however it can't write the column header so is useless !
                                                              See this website :-

                                                              https://stackoverflow.com/questions/1355876/export-table-to-file-with-column-headers-column-names-using-the-bcp-utility-an

                                                              Note, using the MS-DOS command prompt the following bcp commands work but as mentioned above no header row can be written :- 

                                                                bcp PH_Requests.dbo.tblTemp5 out "\\Redacted\odslive$\test\test2\REQ3273_20601_FingertipsData.csv" -n -c -t, -T -S "SVWVSQ016\SVWVSQ016"


                                                 (b) sqlcmd - this writes the column header but has problems writing to the csv format !
                                                              See this website :-

                                                              https://stackoverflow.com/questions/425379/how-to-export-data-as-csv-format-from-sql-server-using-sqlcmd

                                                 (c) Using the 'invoke-sqlcmd' command in a powershell script - this has the problem that the command is from the 'SqlServer' module so
                                                                                                                this module has to be loaded for it to work (which we might not have access to).

                                                              See this website :-

                                                              https://stackoverflow.com/questions/425379/how-to-export-data-as-csv-format-from-sql-server-using-sqlcmd

                                                 (d) OpenDataSource() function  - after reviewing the above methods the OpenDataSource() function was deemed the best method to write our data
                                                                                  to a *.csv file despite its limitations of requiring the following :-                                                                           
                                                                                                                                                        1. csv file to exist.
                                                                                                                                                        2. header row in the first row.

                                                                                  but we can create the required *.csv header file dynamically on the fly with a powershell script.


            Table : tblTemp5
*/

/* Step 6a : Write our data to a .csv file called "REQ3273_20601_FingertipsData.csv" using the OpenDataSource() function.
                              
             Table : tblTemp5
*/

-- ie Delete *.csv file from network if it already exists
DECLARE @strPathFileName VARCHAR(8000)
  SET @strPathFileName = CHAR(39) + '\\Redacted\Intelligence\2. Requests\REQ3273 - Indicator development group with BSOL ICB\REQ3273_20601_FingertipsData.csv' + CHAR(39)

EXECUTE [PH_Data].dbo.usp_Delete_File_on_Network @strInputPathFileName = @strPathFileName

PRINT 'The file we have deleted on the network is :- ' +  @strPathFileName

GO

-- ie want to create a new *.csv file
DECLARE @strPathFileName VARCHAR(500)
SET @strPathFileName = CHAR(39) + '\\Redacted\Intelligence\2. Requests\REQ3273 - Indicator development group with BSOL ICB\REQ3273_20601_FingertipsData.csv' + CHAR(39)
PRINT @strPathFileName


DECLARE @strPowerShellCommand VARCHAR(8000)
SET @strPowerShellCommand = 'PowerShell.exe -Command New-Item ' + @strPathFileName + ' -Force'
PRINT @strPowerShellCommand

DECLARE @intReturnCode INTEGER
EXECUTE @intReturnCode = master..xp_cmdshell @strPowerShellCommand         -- ie create the new powershell Web download script file
PRINT @intReturnCode

-- ie Need to prevent the following SQL statements from running until the powershell commands have finished executing.
WHILE @intReturnCode IS NULL
  BEGIN
    PRINT 'This is a loop'
  END

GO

-- ie Write column header record to empty file 
DECLARE @strPathFileName VARCHAR(500)
  SET @strPathFileName = CHAR(39) + '\\Redacted\Intelligence\2. Requests\REQ3273 - Indicator development group with BSOL ICB\REQ3273_20601_FingertipsData.csv' + CHAR(39)

DECLARE @strText VARCHAR(800)
  SET @strText = 'ValueID, IndicatorID, InsertDate, Numerator, Denominator, IndicatorValue, LowerCI95, UpperCI95, AggID, DemographicID, DataQualityID, IndicatorStartDate, IndicatorEndDate'

DECLARE @strPowerShellCommand VARCHAR(8000)
  SET @strPowerShellCommand = 'PowerShell.exe -Command Add-Content ' + @strPathFileName + ' ' + CHAR(39) + @strText + CHAR(39)    
 
DECLARE @intReturnCode INTEGER
   SET @intReturnCode = NULL

EXECUTE @intReturnCode = master..xp_cmdshell @strPowerShellCommand                   -- ie adding the text to our file.
-- ie Need to wait for external process to finish before continuing.
  WHILE @intReturnCode IS NULL
    BEGIN
      PRINT 'This is a loop'
    END
 
GO

-- Important Note :- These sql commands only work if the 'REQ3273_20601_FingertipsData.csv' file already exists with a header
INSERT INTO OPENDATASOURCE('Microsoft.ACE.OLEDB.16.0','Data Source=\\Redacted\Intelligence\2. Requests\REQ3273 - Indicator development group with BSOL ICB; Extended Properties=Text')...[REQ3273_20601_FingertipsData#csv]
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
  FROM tblTemp5 T1

GO

/***************************************************************************************************************/


/* Step 7 : Delete all the Temporary tables created in the routine.
*/

DROP TABLE IF EXISTS tblTemp1, tblTemp2, tblTemp3, tblTemp4, tblTemp5
GO

/***************************************************************************************************************/



/* Step 8 extra : This part loads our csv datafile into our SQL Server table using sql code only.

                 IMPORTANT NOTE :-  This part has been written to be run on the CSU SQL Server.   


                 Table : [IndicatorsValue]   (ie on CSU SQL Server)
*/

/*
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
                         Extended Properties=Text')...[REQ3273_20601_FingertipsData#csv] T1   

GO
*/

/***************************************************************************************************************/