  
 -- 40701 -- Reduce the under 75 mortality rate from respiratory disease
 -- 40401 -- Under 75 mortality rate from all cardiovascular diseases 
 -- CV6	-- Reduce the under 75 mortality rate from Heart Failure	
 -- 91167 -- Reduce the under 75 mortality rate from Stroke		
 -- 40501 -- Under 75 mortality rate from cancer
 -- 90801 -- Child mortality rate (1-17 years)	
 -- CV7 -- Reduce under 75yrs mortality from acute myocardial infarction
 -- 41001 -- Suicide rate (Persons)



/*=================================================================================================
  Code to unpivot ICD 10 codes in all positions into one column if we want to check any position instead of 
  the column which uses the most dominant underlying position

 Note - GK 18/06/2024 - Been asked to update indicators to only look at main underlying code ([S_UNDERLYING_COD_ICD10])
                        instead of ICD code in any postion. Hence commenting out columns from pivot below.
=================================================================================================*/

  DROP TABLE IF EXISTS #Dataset
                      ,#Unpivotted_Dataset
					  ,#CV6_Dataset

  -- ALL BSOL residents under 75 within Death Register
  
  SELECT T1.PatientId
        ,CONVERT(DATE,REG_DATE) as REG_DATE
		,DEC_SEX
        ,DEC_AGEC
	    ,T1.LSOA_OF_RESIDENCE_CODE
		,GP_PRACTICE_CODE
        ,[S_UNDERLYING_COD_ICD10]
		,CONVERT(VARCHAR(5),NULL) as Ethnicity_Code
        --,[S_COD_CODE_1]
        --,[S_COD_CODE_2]
        --,[S_COD_CODE_3]
        --,[S_COD_CODE_4]
        --,[S_COD_CODE_5]
        --,[S_COD_CODE_6]
        --,[S_COD_CODE_7]
        --,[S_COD_CODE_8]
        --,[S_COD_CODE_9]
        --,[S_COD_CODE_10]
        --,[S_COD_CODE_11]
        --,[S_COD_CODE_12]
        --,[S_COD_CODE_13]
        --,[S_COD_CODE_14]
        --,[S_COD_CODE_15]
	INTO #Dataset
    FROM LocalFeeds.[Reporting].[Deaths_Register] T1
   INNER JOIN [Reference].[Ref].[LSOA_WARD_LAD] T2
      ON T1.LSOA_OF_RESIDENCE_CODE = T2.LSOA11CD
   WHERE T2.LAD19NM IN ('Birmingham', 'Solihull')
     AND DEC_AGEC < 75


  UPDATE #Dataset  
     SET Ethnicity_Code = T2.Ethnic_Code
	FROM #Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Demographic].[Ethnicity] T2
      ON T1.PatientId = T2.Pseudo_NHS_Number

  SELECT PatientId
        ,REG_DATE
		,DEC_SEX
        ,DEC_AGEC
	    ,LSOA_OF_RESIDENCE_CODE
		,Ethnicity_Code
		,GP_PRACTICE_CODE
		,ICD_CODE
		,ICD_CODE_POSITION
	INTO #Unpivotted_Dataset
    FROM #Dataset
 UNPIVOT (
       ICD_CODE FOR ICD_CODE_POSITION IN 
	   (
         [S_UNDERLYING_COD_ICD10]
        --,[S_COD_CODE_1]
        --,[S_COD_CODE_2]
        --,[S_COD_CODE_3]
        --,[S_COD_CODE_4]
        --,[S_COD_CODE_5]
        --,[S_COD_CODE_6]
        --,[S_COD_CODE_7]
        --,[S_COD_CODE_8]
        --,[S_COD_CODE_9]
        --,[S_COD_CODE_10]
        --,[S_COD_CODE_11]
        --,[S_COD_CODE_12]
        --,[S_COD_CODE_13]
        --,[S_COD_CODE_14]
        --,[S_COD_CODE_15]        
		)
	) UNPVT
  


/*=================================================================================================
  40701 -- Reduce the under 75 mortality rate from respiratory disease			
=================================================================================================*/

  SELECT CONVERT(INT,NULL) as IndicatorID
        ,'40701' as ReferenceID
        ,CONVERT(VARCHAR(6),REG_DATE,112) as TimePeriod
		,CONVERT(VARCHAR(8),NULL) as Financial_Year
		,Ethnicity_Code
		,CONVERT(VARCHAR,DEC_SEX) as Gender
        ,DEC_AGEC as Age
		,LSOA_OF_RESIDENCE_CODE    as LSOA_2011
		,CONVERT(VARCHAR(9),NULL)  as LSOA_2021
		,CONVERT(VARCHAR(9),NULL)  as Ward_Code
		,CONVERT(VARCHAR(53),NULL) as Ward_Name		
		,CONVERT(VARCHAR(9),NULL)  as LAD_Code
		,CONVERT(VARCHAR(10),NULL) as LAD_Name
		,CONVERT(VARCHAR(10),NULL) as Locality_Res	
		,GP_PRACTICE_CODE          as GP_Practice
		,SUM(1)					   as Numerator
	INTO #40701_Dataset
    FROM #Unpivotted_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Development].[BSOL_1252_SUS_LTC_ICD10] T2
      ON T1.ICD_CODE = T2.ICD10_Code
   WHERE T2.LTC_Condition = 'Respiratory'
   GROUP BY 
         CONVERT(VARCHAR(6),REG_DATE,112) 
		,Ethnicity_Code
		,CONVERT(VARCHAR,DEC_SEX) 
        ,DEC_AGEC 
		,LSOA_OF_RESIDENCE_CODE    
		,GP_PRACTICE_CODE


  UPDATE #40701_Dataset
     SET Gender = 'Male'
   WHERE Gender = '1'

  UPDATE #40701_Dataset
     SET Gender = 'Female'
   WHERE Gender  = '2'

  UPDATE T1
     SET T1.[Financial_Year] = T2.[HCSFinancialYearName]
    FROM #40701_Dataset T1
   INNER JOIN [Reference].[dbo].[DIM_tbDate] T2
      ON T1.[TimePeriod] = T2.[HCCSReconciliationPoint]

  UPDATE T1
     SET T1.LSOA_2021 = T2.[LSOA21CD]
	FROM #40701_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2011_to_LSOA_2021] T2
      ON T1.LSOA_2011 = T2.LSOA11CD

  UPDATE T1
     SET T1.[Ward_Code]	= T2.[WD22CD]
        ,T1.[Ward_Name]	= T2.[WD22NM]
        ,T1.[LAD_Code]	= T2.LAD22CD
        ,T1.[LAD_Name]  = T2.LAD22NM
    FROM #40701_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_WARD_LAD] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]

  UPDATE T1
     SET T1.[Locality_Res]	= T2.[Locality]
    FROM #40701_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_BSOL_to_Constituency_2025_Locality] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]
 
  UPDATE T1
     SET IndicatorID = T2.IndicatorID
	FROM #40701_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[OF].[IndicatorList] T2
      ON T1.ReferenceID = T2.ReferenceID


  SELECT TOP 1000 *
    FROM #40701_Dataset


  -- Insert Data
/*

  INSERT INTO [EAT_Reporting_BSOL].[OF].[IndicatorData] 
        (				
		 [IndicatorID]
        ,[ReferenceID]
        ,[TimePeriod] 
        ,[Financial_Year]
        ,[Ethnicity_Code]
        ,[Gender]	
        ,[Age]		
        ,[LSOA_2011] 
        ,[LSOA_2021] 
        ,[Ward_Code] 
        ,[Ward_Name] 
        ,[LAD_Code]
        ,[LAD_Name]
        ,[Locality_Res]
        ,[GP_Practice]	
        ,[Numerator]		
        )
		(
  SELECT [IndicatorID]
        ,[ReferenceID]
        ,[TimePeriod] 
        ,[Financial_Year]
        ,[Ethnicity_Code]
        ,[Gender]	
        ,[Age]		
        ,[LSOA_2011] 
        ,[LSOA_2021] 
        ,[Ward_Code] 
        ,[Ward_Name] 
        ,[LAD_Code]
        ,[LAD_Name]
        ,[Locality_Res]
        ,[GP_Practice]	
        ,[Numerator]	
    FROM #40701_Dataset
	    )

*/	


    
/*=================================================================================================
  40401 -- Under 75 mortality rate from all cardiovascular diseases			
=================================================================================================*/


 SELECT CONVERT(INT,NULL) as IndicatorID
        ,'40401' as ReferenceID
        ,CONVERT(VARCHAR(6),REG_DATE,112) as TimePeriod
		,CONVERT(VARCHAR(8),NULL) as Financial_Year
		,Ethnicity_Code
		,CONVERT(VARCHAR,DEC_SEX) as Gender
        ,DEC_AGEC as Age
		,LSOA_OF_RESIDENCE_CODE    as LSOA_2011
		,CONVERT(VARCHAR(9),NULL)  as LSOA_2021
		,CONVERT(VARCHAR(9),NULL)  as Ward_Code
		,CONVERT(VARCHAR(53),NULL) as Ward_Name		
		,CONVERT(VARCHAR(9),NULL)  as LAD_Code
		,CONVERT(VARCHAR(10),NULL) as LAD_Name
		,CONVERT(VARCHAR(10),NULL) as Locality_Res	
		,GP_PRACTICE_CODE          as GP_Practice
		,SUM(1)					   as Numerator
	INTO #40401_Dataset
    FROM #Unpivotted_Dataset T1
   WHERE left(ICD_CODE ,1) ='I'	
   GROUP BY 
         CONVERT(VARCHAR(6),REG_DATE,112) 
		,Ethnicity_Code
		,CONVERT(VARCHAR,DEC_SEX) 
        ,DEC_AGEC 
		,LSOA_OF_RESIDENCE_CODE    
		,GP_PRACTICE_CODE


  UPDATE #40401_Dataset
     SET Gender = 'Male'
   WHERE Gender = '1'

  UPDATE #40401_Dataset
     SET Gender = 'Female'
   WHERE Gender  = '2'

  UPDATE T1
     SET T1.[Financial_Year] = T2.[HCSFinancialYearName]
    FROM #40401_Dataset T1
   INNER JOIN [Reference].[dbo].[DIM_tbDate] T2
      ON T1.[TimePeriod] = T2.[HCCSReconciliationPoint]

  UPDATE T1
     SET T1.LSOA_2021 = T2.[LSOA21CD]
	FROM #40401_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2011_to_LSOA_2021] T2
      ON T1.LSOA_2011 = T2.LSOA11CD

  UPDATE T1
     SET T1.[Ward_Code]	= T2.[WD22CD]
        ,T1.[Ward_Name]	= T2.[WD22NM]
        ,T1.[LAD_Code]	= T2.LAD22CD
        ,T1.[LAD_Name]  = T2.LAD22NM
    FROM #40401_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_WARD_LAD] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]

  UPDATE T1
     SET T1.[Locality_Res]	= T2.[Locality]
    FROM #40401_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_BSOL_to_Constituency_2025_Locality] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]
 
  UPDATE T1
     SET IndicatorID = T2.IndicatorID
	FROM #40401_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[OF].[IndicatorList] T2
      ON T1.ReferenceID = T2.ReferenceID


  --  SELECT TOP 1000 *    FROM #40401_Dataset

  -- Insert Data
/*

  INSERT INTO [EAT_Reporting_BSOL].[OF].[IndicatorData] 
        (				
		 [IndicatorID]
        ,[ReferenceID]
        ,[TimePeriod] 
        ,[Financial_Year]
        ,[Ethnicity_Code]
        ,[Gender]	
        ,[Age]		
        ,[LSOA_2011] 
        ,[LSOA_2021] 
        ,[Ward_Code] 
        ,[Ward_Name] 
        ,[LAD_Code]
        ,[LAD_Name]
        ,[Locality_Res]
        ,[GP_Practice]	
        ,[Numerator]		
        )
		(
  SELECT [IndicatorID]
        ,[ReferenceID]
        ,[TimePeriod] 
        ,[Financial_Year]
        ,[Ethnicity_Code]
        ,[Gender]	
        ,[Age]		
        ,[LSOA_2011] 
        ,[LSOA_2021] 
        ,[Ward_Code] 
        ,[Ward_Name] 
        ,[LAD_Code]
        ,[LAD_Name]
        ,[Locality_Res]
        ,[GP_Practice]	
        ,[Numerator]	
    FROM #40401_Dataset
	    )

*/	  




/*=================================================================================================
  CV6 -- Reduce the under 75 mortality rate from Heart Failure			
=================================================================================================*/


  SELECT CONVERT(INT,NULL) as IndicatorID
        ,'CV6' as ReferenceID
        ,CONVERT(VARCHAR(6),REG_DATE,112) as TimePeriod
		,CONVERT(VARCHAR(8),NULL) as Financial_Year
		,Ethnicity_Code
		,CONVERT(VARCHAR,DEC_SEX) as Gender
        ,DEC_AGEC as Age
		,LSOA_OF_RESIDENCE_CODE    as LSOA_2011
		,CONVERT(VARCHAR(9),NULL)  as LSOA_2021
		,CONVERT(VARCHAR(9),NULL)  as Ward_Code
		,CONVERT(VARCHAR(53),NULL) as Ward_Name		
		,CONVERT(VARCHAR(9),NULL)  as LAD_Code
		,CONVERT(VARCHAR(10),NULL) as LAD_Name
		,CONVERT(VARCHAR(10),NULL) as Locality_Res	
		,GP_PRACTICE_CODE          as GP_Practice
		,SUM(1)					   as Numerator
	INTO #CV6_Dataset
    FROM #Unpivotted_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Development].[BSOL_1252_SUS_LTC_ICD10] T2
      ON T1.ICD_CODE = T2.ICD10_Code
   WHERE T2.LTC_Condition = 'Heart Failure'
   GROUP BY 
         CONVERT(VARCHAR(6),REG_DATE,112) 
		,Ethnicity_Code
		,CONVERT(VARCHAR,DEC_SEX) 
        ,DEC_AGEC 
		,LSOA_OF_RESIDENCE_CODE    
		,GP_PRACTICE_CODE


  UPDATE #CV6_Dataset
     SET Gender = 'Male'
   WHERE Gender = '1'

  UPDATE #CV6_Dataset
     SET Gender = 'Female'
   WHERE Gender  = '2'

  UPDATE T1
     SET T1.[Financial_Year] = T2.[HCSFinancialYearName]
    FROM #CV6_Dataset T1
   INNER JOIN [Reference].[dbo].[DIM_tbDate] T2
      ON T1.[TimePeriod] = T2.[HCCSReconciliationPoint]

  UPDATE T1
     SET T1.LSOA_2021 = T2.[LSOA21CD]
	FROM #CV6_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2011_to_LSOA_2021] T2
      ON T1.LSOA_2011 = T2.LSOA11CD

  UPDATE T1
     SET T1.[Ward_Code]	= T2.[WD22CD]
        ,T1.[Ward_Name]	= T2.[WD22NM]
        ,T1.[LAD_Code]	= T2.LAD22CD
        ,T1.[LAD_Name]  = T2.LAD22NM
    FROM #CV6_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_WARD_LAD] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]

  UPDATE T1
     SET T1.[Locality_Res]	= T2.[Locality]
    FROM #CV6_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_BSOL_to_Constituency_2025_Locality] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]
 
  UPDATE T1
     SET IndicatorID = T2.IndicatorID
	FROM #CV6_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[OF].[IndicatorList] T2
      ON T1.ReferenceID = T2.ReferenceID


  SELECT TOP 1000 *
    FROM #CV6_Dataset

  -- Insert Data
/*

  INSERT INTO [EAT_Reporting_BSOL].[OF].[IndicatorData] 
        (				
		 [IndicatorID]
        ,[ReferenceID]
        ,[TimePeriod] 
        ,[Financial_Year]
        ,[Ethnicity_Code]
        ,[Gender]	
        ,[Age]		
        ,[LSOA_2011] 
        ,[LSOA_2021] 
        ,[Ward_Code] 
        ,[Ward_Name] 
        ,[LAD_Code]
        ,[LAD_Name]
        ,[Locality_Res]
        ,[GP_Practice]	
        ,[Numerator]		
        )
		(
  SELECT [IndicatorID]
        ,[ReferenceID]
        ,[TimePeriod] 
        ,[Financial_Year]
        ,[Ethnicity_Code]
        ,[Gender]	
        ,[Age]		
        ,[LSOA_2011] 
        ,[LSOA_2021] 
        ,[Ward_Code] 
        ,[Ward_Name] 
        ,[LAD_Code]
        ,[LAD_Name]
        ,[Locality_Res]
        ,[GP_Practice]	
        ,[Numerator]	
    FROM #CV6_Dataset
	    )

*/	
  


/*=================================================================================================
  91167 -- Reduce the under 75 mortality rate from Stroke			
=================================================================================================*/

  SELECT CONVERT(INT,NULL) as IndicatorID
        ,'91167' as ReferenceID
        ,CONVERT(VARCHAR(6),REG_DATE,112) as TimePeriod
		,CONVERT(VARCHAR(8),NULL) as Financial_Year
		,Ethnicity_Code
		,CONVERT(VARCHAR,DEC_SEX) as Gender
        ,DEC_AGEC as Age
		,LSOA_OF_RESIDENCE_CODE    as LSOA_2011
		,CONVERT(VARCHAR(9),NULL)  as LSOA_2021
		,CONVERT(VARCHAR(9),NULL)  as Ward_Code
		,CONVERT(VARCHAR(53),NULL) as Ward_Name		
		,CONVERT(VARCHAR(9),NULL)  as LAD_Code
		,CONVERT(VARCHAR(10),NULL) as LAD_Name
		,CONVERT(VARCHAR(10),NULL) as Locality_Res	
		,GP_PRACTICE_CODE          as GP_Practice
		,SUM(1)					   as Numerator
	INTO #91167_Dataset
    FROM #Unpivotted_Dataset T1
  /* INNER JOIN [EAT_Reporting_BSOL].[Development].[BSOL_1252_SUS_LTC_ICD10] T2
      ON T1.ICD_CODE = T2.ICD10_Code
   WHERE T2.LTC_Condition = 'Stroke' */
   WHERE ICD_CODE LIKE 'I6%'
   GROUP BY 
         CONVERT(VARCHAR(6),REG_DATE,112) 
		,Ethnicity_Code
		,CONVERT(VARCHAR,DEC_SEX) 
        ,DEC_AGEC 
		,LSOA_OF_RESIDENCE_CODE    
		,GP_PRACTICE_CODE


  UPDATE #91167_Dataset
     SET Gender = 'Male'
   WHERE Gender = '1'

  UPDATE #91167_Dataset
     SET Gender = 'Female'
   WHERE Gender  = '2'

  UPDATE T1
     SET T1.[Financial_Year] = T2.[HCSFinancialYearName]
    FROM #91167_Dataset T1
   INNER JOIN [Reference].[dbo].[DIM_tbDate] T2
      ON T1.[TimePeriod] = T2.[HCCSReconciliationPoint]

  UPDATE T1
     SET T1.LSOA_2021 = T2.[LSOA21CD]
	FROM #91167_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2011_to_LSOA_2021] T2
      ON T1.LSOA_2011 = T2.LSOA11CD

  UPDATE T1
     SET T1.[Ward_Code]	= T2.[WD22CD]
        ,T1.[Ward_Name]	= T2.[WD22NM]
        ,T1.[LAD_Code]	= T2.LAD22CD
        ,T1.[LAD_Name]  = T2.LAD22NM
    FROM #91167_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_WARD_LAD] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]

  UPDATE T1
     SET T1.[Locality_Res]	= T2.[Locality]
    FROM #91167_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_BSOL_to_Constituency_2025_Locality] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]
 
  UPDATE T1
     SET IndicatorID = T2.IndicatorID
	FROM #91167_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[OF].[IndicatorList] T2
      ON T1.ReferenceID = T2.ReferenceID

/*
SELECT CalendarYear
      ,LAD_Name
	  ,SUM(Numerator)
    FROM #91167_Dataset T1
    INNER JOIN [EAT_Reporting_BSOL].[Reference].[vwYear_Month] T2
      ON T1.TimePeriod = T2.YYYYMM
	WHERE LAD_Name = 'Solihull'
  GROUP BY CalendarYear
      ,LAD_Name
  order by 1,2
*/

  -- Insert Data
/*

  INSERT INTO [EAT_Reporting_BSOL].[OF].[IndicatorData] 
        (				
		 [IndicatorID]
        ,[ReferenceID]
        ,[TimePeriod] 
        ,[Financial_Year]
        ,[Ethnicity_Code]
        ,[Gender]	
        ,[Age]		
        ,[LSOA_2011] 
        ,[LSOA_2021] 
        ,[Ward_Code] 
        ,[Ward_Name] 
        ,[LAD_Code]
        ,[LAD_Name]
        ,[Locality_Res]
        ,[GP_Practice]	
        ,[Numerator]		
        )
		(
  SELECT [IndicatorID]
        ,[ReferenceID]
        ,[TimePeriod] 
        ,[Financial_Year]
        ,[Ethnicity_Code]
        ,[Gender]	
        ,[Age]		
        ,[LSOA_2011] 
        ,[LSOA_2021] 
        ,[Ward_Code] 
        ,[Ward_Name] 
        ,[LAD_Code]
        ,[LAD_Name]
        ,[Locality_Res]
        ,[GP_Practice]	
        ,[Numerator]	
    FROM #91167_Dataset
	    )

*/	
  


/*=================================================================================================
  CV3  -- Mortality rate from diabetic complications			
=================================================================================================*/

/*=================================================================================================
-- 40501 -- Under 75 mortality rate from cancer			
=================================================================================================*/
 

 SELECT CONVERT(INT,NULL) as IndicatorID
        ,'40501' as ReferenceID
        ,CONVERT(VARCHAR(6),REG_DATE,112) as TimePeriod
		,CONVERT(VARCHAR(8),NULL) as Financial_Year
		,Ethnicity_Code
		,CONVERT(VARCHAR,DEC_SEX) as Gender
        ,DEC_AGEC as Age
		,LSOA_OF_RESIDENCE_CODE    as LSOA_2011
		,CONVERT(VARCHAR(9),NULL)  as LSOA_2021
		,CONVERT(VARCHAR(9),NULL)  as Ward_Code
		,CONVERT(VARCHAR(53),NULL) as Ward_Name		
		,CONVERT(VARCHAR(9),NULL)  as LAD_Code
		,CONVERT(VARCHAR(10),NULL) as LAD_Name
		,CONVERT(VARCHAR(10),NULL) as Locality_Res	
		,GP_PRACTICE_CODE          as GP_Practice
		,SUM(1)					   as Numerator
	INTO #40501_Dataset
    FROM #Unpivotted_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Development].[BSOL_1252_SUS_LTC_ICD10] T2
      ON T1.ICD_CODE = T2.ICD10_Code
   WHERE T2.LTC_Condition = 'Cancer'
   GROUP BY 
         CONVERT(VARCHAR(6),REG_DATE,112) 
		,Ethnicity_Code
		,CONVERT(VARCHAR,DEC_SEX) 
        ,DEC_AGEC 
		,LSOA_OF_RESIDENCE_CODE    
		,GP_PRACTICE_CODE


  UPDATE #40501_Dataset
     SET Gender = 'Male'
   WHERE Gender = '1'

  UPDATE #40501_Dataset
     SET Gender = 'Female'
   WHERE Gender  = '2'

  UPDATE T1
     SET T1.[Financial_Year] = T2.[HCSFinancialYearName]
    FROM #40501_Dataset T1
   INNER JOIN [Reference].[dbo].[DIM_tbDate] T2
      ON T1.[TimePeriod] = T2.[HCCSReconciliationPoint]

  UPDATE T1
     SET T1.LSOA_2021 = T2.[LSOA21CD]
	FROM #40501_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2011_to_LSOA_2021] T2
      ON T1.LSOA_2011 = T2.LSOA11CD

  UPDATE T1
     SET T1.[Ward_Code]	= T2.[WD22CD]
        ,T1.[Ward_Name]	= T2.[WD22NM]
        ,T1.[LAD_Code]	= T2.LAD22CD
        ,T1.[LAD_Name]  = T2.LAD22NM
    FROM #40501_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_WARD_LAD] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]

  UPDATE T1
     SET T1.[Locality_Res]	= T2.[Locality]
    FROM #40501_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_BSOL_to_Constituency_2025_Locality] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]
 
  UPDATE T1
     SET IndicatorID = T2.IndicatorID
	FROM #40501_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[OF].[IndicatorList] T2
      ON T1.ReferenceID = T2.ReferenceID


  --  SELECT TOP 1000 *    FROM #40501_Dataset

  -- Insert Data
/*

  INSERT INTO [EAT_Reporting_BSOL].[OF].[IndicatorData] 
        (				
		 [IndicatorID]
        ,[ReferenceID]
        ,[TimePeriod] 
        ,[Financial_Year]
        ,[Ethnicity_Code]
        ,[Gender]	
        ,[Age]		
        ,[LSOA_2011] 
        ,[LSOA_2021] 
        ,[Ward_Code] 
        ,[Ward_Name] 
        ,[LAD_Code]
        ,[LAD_Name]
        ,[Locality_Res]
        ,[GP_Practice]	
        ,[Numerator]		
        )
		(
  SELECT [IndicatorID]
        ,[ReferenceID]
        ,[TimePeriod] 
        ,[Financial_Year]
        ,[Ethnicity_Code]
        ,[Gender]	
        ,[Age]		
        ,[LSOA_2011] 
        ,[LSOA_2021] 
        ,[Ward_Code] 
        ,[Ward_Name] 
        ,[LAD_Code]
        ,[LAD_Name]
        ,[Locality_Res]
        ,[GP_Practice]	
        ,[Numerator]	
    FROM #40501_Dataset
	    )

*/	  


/*=================================================================================================
-- 90801 -- Child mortality rate (1-17 years)			
=================================================================================================*/
 

 SELECT CONVERT(INT,NULL) as IndicatorID
        ,'90801' as ReferenceID
        ,CONVERT(VARCHAR(6),REG_DATE,112) as TimePeriod
		,CONVERT(VARCHAR(8),NULL) as Financial_Year
		,Ethnicity_Code
		,CONVERT(VARCHAR,DEC_SEX) as Gender
        ,DEC_AGEC as Age
		,LSOA_OF_RESIDENCE_CODE    as LSOA_2011
		,CONVERT(VARCHAR(9),NULL)  as LSOA_2021
		,CONVERT(VARCHAR(9),NULL)  as Ward_Code
		,CONVERT(VARCHAR(53),NULL) as Ward_Name		
		,CONVERT(VARCHAR(9),NULL)  as LAD_Code
		,CONVERT(VARCHAR(10),NULL) as LAD_Name
		,CONVERT(VARCHAR(10),NULL) as Locality_Res	
		,GP_PRACTICE_CODE          as GP_Practice
		,SUM(1)					   as Numerator
	INTO #90801_Dataset
    FROM #Unpivotted_Dataset T1
   WHERE DEC_AGEC >= 1 
     AND DEC_AGEC <= 17
   GROUP BY 
         CONVERT(VARCHAR(6),REG_DATE,112) 
		,Ethnicity_Code
		,CONVERT(VARCHAR,DEC_SEX) 
        ,DEC_AGEC 
		,LSOA_OF_RESIDENCE_CODE    
		,GP_PRACTICE_CODE


  UPDATE #90801_Dataset
     SET Gender = 'Male'
   WHERE Gender = '1'

  UPDATE #90801_Dataset
     SET Gender = 'Female'
   WHERE Gender  = '2'

  UPDATE T1
     SET T1.[Financial_Year] = T2.[HCSFinancialYearName]
    FROM #90801_Dataset T1
   INNER JOIN [Reference].[dbo].[DIM_tbDate] T2
      ON T1.[TimePeriod] = T2.[HCCSReconciliationPoint]

  UPDATE T1
     SET T1.LSOA_2021 = T2.[LSOA21CD]
	FROM #90801_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2011_to_LSOA_2021] T2
      ON T1.LSOA_2011 = T2.LSOA11CD

  UPDATE T1
     SET T1.[Ward_Code]	= T2.[WD22CD]
        ,T1.[Ward_Name]	= T2.[WD22NM]
        ,T1.[LAD_Code]	= T2.LAD22CD
        ,T1.[LAD_Name]  = T2.LAD22NM
    FROM #90801_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_WARD_LAD] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]

  UPDATE T1
     SET T1.[Locality_Res]	= T2.[Locality]
    FROM #90801_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_BSOL_to_Constituency_2025_Locality] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]
 
  UPDATE T1
     SET IndicatorID = T2.IndicatorID
	FROM #90801_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[OF].[IndicatorList] T2
      ON T1.ReferenceID = T2.ReferenceID


  --  SELECT TOP 1000 *    FROM #90801_Dataset

  -- Insert Data
/*

  INSERT INTO [EAT_Reporting_BSOL].[OF].[IndicatorData] 
        (				
		 [IndicatorID]
        ,[ReferenceID]
        ,[TimePeriod] 
        ,[Financial_Year]
        ,[Ethnicity_Code]
        ,[Gender]	
        ,[Age]		
        ,[LSOA_2011] 
        ,[LSOA_2021] 
        ,[Ward_Code] 
        ,[Ward_Name] 
        ,[LAD_Code]
        ,[LAD_Name]
        ,[Locality_Res]
        ,[GP_Practice]	
        ,[Numerator]		
        )
		(
  SELECT [IndicatorID]
        ,[ReferenceID]
        ,[TimePeriod] 
        ,[Financial_Year]
        ,[Ethnicity_Code]
        ,[Gender]	
        ,[Age]		
        ,[LSOA_2011] 
        ,[LSOA_2021] 
        ,[Ward_Code] 
        ,[Ward_Name] 
        ,[LAD_Code]
        ,[LAD_Name]
        ,[Locality_Res]
        ,[GP_Practice]	
        ,[Numerator]	
    FROM #90801_Dataset
	    )

*/	  



 /*=================================================================================================
 -- CV7 -- Reduce under 75yrs mortality from acute myocardial infarction		
=================================================================================================*/
 

 SELECT CONVERT(INT,NULL) as IndicatorID
        ,'CV7' as ReferenceID
        ,CONVERT(VARCHAR(6),REG_DATE,112) as TimePeriod
		,CONVERT(VARCHAR(8),NULL) as Financial_Year
		,Ethnicity_Code
		,CONVERT(VARCHAR,DEC_SEX) as Gender
        ,DEC_AGEC as Age
		,LSOA_OF_RESIDENCE_CODE    as LSOA_2011
		,CONVERT(VARCHAR(9),NULL)  as LSOA_2021
		,CONVERT(VARCHAR(9),NULL)  as Ward_Code
		,CONVERT(VARCHAR(53),NULL) as Ward_Name		
		,CONVERT(VARCHAR(9),NULL)  as LAD_Code
		,CONVERT(VARCHAR(10),NULL) as LAD_Name
		,CONVERT(VARCHAR(10),NULL) as Locality_Res	
		,GP_PRACTICE_CODE          as GP_Practice
		,SUM(1)					   as Numerator
	INTO #CV7_Dataset
    FROM #Unpivotted_Dataset T1
   WHERE LEFT(ICD_CODE,3) LIKE 'I2[1-2]'
   GROUP BY 
         CONVERT(VARCHAR(6),REG_DATE,112) 
		,Ethnicity_Code
		,CONVERT(VARCHAR,DEC_SEX) 
        ,DEC_AGEC 
		,LSOA_OF_RESIDENCE_CODE    
		,GP_PRACTICE_CODE


  UPDATE #CV7_Dataset
     SET Gender = 'Male'
   WHERE Gender = '1'

  UPDATE #CV7_Dataset
     SET Gender = 'Female'
   WHERE Gender  = '2'

  UPDATE T1
     SET T1.[Financial_Year] = T2.[HCSFinancialYearName]
    FROM #CV7_Dataset T1
   INNER JOIN [Reference].[dbo].[DIM_tbDate] T2
      ON T1.[TimePeriod] = T2.[HCCSReconciliationPoint]

  UPDATE T1
     SET T1.LSOA_2021 = T2.[LSOA21CD]
	FROM #CV7_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2011_to_LSOA_2021] T2
      ON T1.LSOA_2011 = T2.LSOA11CD

  UPDATE T1
     SET T1.[Ward_Code]	= T2.[WD22CD]
        ,T1.[Ward_Name]	= T2.[WD22NM]
        ,T1.[LAD_Code]	= T2.LAD22CD
        ,T1.[LAD_Name]  = T2.LAD22NM
    FROM #CV7_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_WARD_LAD] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]

  UPDATE T1
     SET T1.[Locality_Res]	= T2.[Locality]
    FROM #CV7_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_BSOL_to_Constituency_2025_Locality] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]
 
  UPDATE T1
     SET IndicatorID = T2.IndicatorID
	FROM #CV7_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[OF].[IndicatorList] T2
      ON T1.ReferenceID = T2.ReferenceID


  --  SELECT TOP 1000 *    FROM #CV7_Dataset

  -- Insert Data
/*

  INSERT INTO [EAT_Reporting_BSOL].[OF].[IndicatorData] 
        (				
		 [IndicatorID]
        ,[ReferenceID]
        ,[TimePeriod] 
        ,[Financial_Year]
        ,[Ethnicity_Code]
        ,[Gender]	
        ,[Age]		
        ,[LSOA_2011] 
        ,[LSOA_2021] 
        ,[Ward_Code] 
        ,[Ward_Name] 
        ,[LAD_Code]
        ,[LAD_Name]
        ,[Locality_Res]
        ,[GP_Practice]	
        ,[Numerator]		
        )
		(
  SELECT [IndicatorID]
        ,[ReferenceID]
        ,[TimePeriod] 
        ,[Financial_Year]
        ,[Ethnicity_Code]
        ,[Gender]	
        ,[Age]		
        ,[LSOA_2011] 
        ,[LSOA_2021] 
        ,[Ward_Code] 
        ,[Ward_Name] 
        ,[LAD_Code]
        ,[LAD_Name]
        ,[Locality_Res]
        ,[GP_Practice]	
        ,[Numerator]	
    FROM #CV7_Dataset
	    )

*/	


 /*=================================================================================================
 -- CV7 -- Reduce under 75yrs mortality from acute myocardial infarction		
=================================================================================================*/
 

 SELECT CONVERT(INT,NULL) as IndicatorID
        ,'CV7' as ReferenceID
        ,CONVERT(VARCHAR(6),REG_DATE,112) as TimePeriod
		,CONVERT(VARCHAR(8),NULL) as Financial_Year
		,Ethnicity_Code
		,CONVERT(VARCHAR,DEC_SEX) as Gender
        ,DEC_AGEC as Age
		,LSOA_OF_RESIDENCE_CODE    as LSOA_2011
		,CONVERT(VARCHAR(9),NULL)  as LSOA_2021
		,CONVERT(VARCHAR(9),NULL)  as Ward_Code
		,CONVERT(VARCHAR(53),NULL) as Ward_Name		
		,CONVERT(VARCHAR(9),NULL)  as LAD_Code
		,CONVERT(VARCHAR(10),NULL) as LAD_Name
		,CONVERT(VARCHAR(10),NULL) as Locality_Res	
		,GP_PRACTICE_CODE          as GP_Practice
		,SUM(1)					   as Numerator
	INTO #CV7_Dataset
    FROM #Unpivotted_Dataset T1
   WHERE LEFT(ICD_CODE,3) LIKE 'I2[1-2]'
   GROUP BY 
         CONVERT(VARCHAR(6),REG_DATE,112) 
		,Ethnicity_Code
		,CONVERT(VARCHAR,DEC_SEX) 
        ,DEC_AGEC 
		,LSOA_OF_RESIDENCE_CODE    
		,GP_PRACTICE_CODE


  UPDATE #CV7_Dataset
     SET Gender = 'Male'
   WHERE Gender = '1'

  UPDATE #CV7_Dataset
     SET Gender = 'Female'
   WHERE Gender  = '2'

  UPDATE T1
     SET T1.[Financial_Year] = T2.[HCSFinancialYearName]
    FROM #CV7_Dataset T1
   INNER JOIN [Reference].[dbo].[DIM_tbDate] T2
      ON T1.[TimePeriod] = T2.[HCCSReconciliationPoint]

  UPDATE T1
     SET T1.LSOA_2021 = T2.[LSOA21CD]
	FROM #CV7_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2011_to_LSOA_2021] T2
      ON T1.LSOA_2011 = T2.LSOA11CD

  UPDATE T1
     SET T1.[Ward_Code]	= T2.[WD22CD]
        ,T1.[Ward_Name]	= T2.[WD22NM]
        ,T1.[LAD_Code]	= T2.LAD22CD
        ,T1.[LAD_Name]  = T2.LAD22NM
    FROM #CV7_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_WARD_LAD] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]

  UPDATE T1
     SET T1.[Locality_Res]	= T2.[Locality]
    FROM #CV7_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_BSOL_to_Constituency_2025_Locality] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]
 
  UPDATE T1
     SET IndicatorID = T2.IndicatorID
	FROM #CV7_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[OF].[IndicatorList] T2
      ON T1.ReferenceID = T2.ReferenceID


  --  SELECT TOP 1000 *    FROM #CV7_Dataset

  -- Insert Data
/*

  INSERT INTO [EAT_Reporting_BSOL].[OF].[IndicatorData] 
        (				
		 [IndicatorID]
        ,[ReferenceID]
        ,[TimePeriod] 
        ,[Financial_Year]
        ,[Ethnicity_Code]
        ,[Gender]	
        ,[Age]		
        ,[LSOA_2011] 
        ,[LSOA_2021] 
        ,[Ward_Code] 
        ,[Ward_Name] 
        ,[LAD_Code]
        ,[LAD_Name]
        ,[Locality_Res]
        ,[GP_Practice]	
        ,[Numerator]		
        )
		(
  SELECT [IndicatorID]
        ,[ReferenceID]
        ,[TimePeriod] 
        ,[Financial_Year]
        ,[Ethnicity_Code]
        ,[Gender]	
        ,[Age]		
        ,[LSOA_2011] 
        ,[LSOA_2021] 
        ,[Ward_Code] 
        ,[Ward_Name] 
        ,[LAD_Code]
        ,[LAD_Name]
        ,[Locality_Res]
        ,[GP_Practice]	
        ,[Numerator]	
    FROM #CV7_Dataset
	    )

*/	


  /*=================================================================================================
 -- 41001 -- Suicide rate (Persons)	-- All years so not using 75 and under table	
=================================================================================================*/
 
  -- First, identify relevant ICD10 Codes
  
  SELECT DISTINCT 
         [S_UNDERLYING_COD_ICD10]
	INTO #Suicide_ICD10_Codes
    FROM LocalFeeds.[Reporting].[Deaths_Register]
   WHERE LEFT(S_UNDERLYING_COD_ICD10,2) = 'X6'

  INSERT INTO #Suicide_ICD10_Codes (
        S_UNDERLYING_COD_ICD10
		)
		(
  SELECT DISTINCT 
         [S_UNDERLYING_COD_ICD10]
    FROM LocalFeeds.[Reporting].[Deaths_Register]
   WHERE LEFT(S_UNDERLYING_COD_ICD10,2) = 'X7'
        )

  INSERT INTO #Suicide_ICD10_Codes (
        S_UNDERLYING_COD_ICD10
		)
		(
  SELECT DISTINCT 
         [S_UNDERLYING_COD_ICD10]
    FROM LocalFeeds.[Reporting].[Deaths_Register]
   WHERE LEFT(S_UNDERLYING_COD_ICD10,3) LIKE 'X8[0-4]'
        )

  INSERT INTO #Suicide_ICD10_Codes (
        S_UNDERLYING_COD_ICD10
		)
		(
  SELECT DISTINCT 
         [S_UNDERLYING_COD_ICD10]
    FROM LocalFeeds.[Reporting].[Deaths_Register]
   WHERE LEFT(S_UNDERLYING_COD_ICD10,2) LIKE 'Y[1-2]'
        )

  INSERT INTO #Suicide_ICD10_Codes (
        S_UNDERLYING_COD_ICD10
		)
		(
  SELECT DISTINCT 
         [S_UNDERLYING_COD_ICD10]
    FROM LocalFeeds.[Reporting].[Deaths_Register]
   WHERE LEFT(S_UNDERLYING_COD_ICD10,3) LIKE 'Y3[0-4]'
        )

  -- Second, pull out relevant data from Death Register

  SELECT T1.PatientId
        ,CONVERT(DATE,REG_DATE) as REG_DATE
		,DEC_SEX
        ,DEC_AGEC
	    ,T1.LSOA_OF_RESIDENCE_CODE
		,GP_PRACTICE_CODE
        ,T1.[S_UNDERLYING_COD_ICD10]
		,CONVERT(VARCHAR(5),NULL) as Ethnicity_Code
	INTO #Suicide_Dataset
    FROM LocalFeeds.[Reporting].[Deaths_Register] T1
   INNER JOIN [Reference].[Ref].[LSOA_WARD_LAD] T2
      ON T1.LSOA_OF_RESIDENCE_CODE = T2.LSOA11CD
   INNER JOIN #Suicide_ICD10_Codes T3
      ON T1.S_UNDERLYING_COD_ICD10 = T3.S_UNDERLYING_COD_ICD10
   WHERE T2.LAD19NM IN ('Birmingham', 'Solihull')
     AND DEC_AGEC >= 10

  UPDATE #Suicide_Dataset 
     SET Ethnicity_Code = T2.Ethnic_Code
	FROM #Suicide_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Demographic].[Ethnicity] T2
      ON T1.PatientId = T2.Pseudo_NHS_Number

  DELETE 
    FROM #Suicide_Dataset
   WHERE S_UNDERLYING_COD_ICD10 LIKE 'Y%'
     AND DEC_AGEC < 15 -- According to Fingertips Methodology Y10-Y34 (ages 15+ only) 

  SELECT CONVERT(INT,NULL) as IndicatorID
        ,'41001' as ReferenceID
        ,CONVERT(VARCHAR(6),REG_DATE,112) as TimePeriod
		,CONVERT(VARCHAR(8),NULL) as Financial_Year
		,Ethnicity_Code
		,CONVERT(VARCHAR,DEC_SEX) as Gender
        ,DEC_AGEC as Age
		,LSOA_OF_RESIDENCE_CODE    as LSOA_2011
		,CONVERT(VARCHAR(9),NULL)  as LSOA_2021
		,CONVERT(VARCHAR(9),NULL)  as Ward_Code
		,CONVERT(VARCHAR(53),NULL) as Ward_Name		
		,CONVERT(VARCHAR(9),NULL)  as LAD_Code
		,CONVERT(VARCHAR(10),NULL) as LAD_Name
		,CONVERT(VARCHAR(10),NULL) as Locality_Res	
		,GP_PRACTICE_CODE          as GP_Practice
		,SUM(1)					   as Numerator
	INTO #41001_Dataset
    FROM #Suicide_Dataset  T1
   GROUP BY 
         CONVERT(VARCHAR(6),REG_DATE,112) 
		,Ethnicity_Code
		,CONVERT(VARCHAR,DEC_SEX) 
        ,DEC_AGEC 
		,LSOA_OF_RESIDENCE_CODE    
		,GP_PRACTICE_CODE


  UPDATE #41001_Dataset
     SET Gender = 'Male'
   WHERE Gender = '1'

  UPDATE #41001_Dataset
     SET Gender = 'Female'
   WHERE Gender  = '2'

  UPDATE T1
     SET T1.[Financial_Year] = T2.[HCSFinancialYearName]
    FROM #41001_Dataset T1
   INNER JOIN [Reference].[dbo].[DIM_tbDate] T2
      ON T1.[TimePeriod] = T2.[HCCSReconciliationPoint]

  UPDATE T1
     SET T1.LSOA_2021 = T2.[LSOA21CD]
	FROM #41001_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2011_to_LSOA_2021] T2
      ON T1.LSOA_2011 = T2.LSOA11CD

  UPDATE T1
     SET T1.[Ward_Code]	= T2.[WD22CD]
        ,T1.[Ward_Name]	= T2.[WD22NM]
        ,T1.[LAD_Code]	= T2.LAD22CD
        ,T1.[LAD_Name]  = T2.LAD22NM
    FROM #41001_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_WARD_LAD] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]

  UPDATE T1
     SET T1.[Locality_Res]	= T2.[Locality]
    FROM #41001_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_BSOL_to_Constituency_2025_Locality] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]
 
  UPDATE T1
     SET IndicatorID = T2.IndicatorID
	FROM #41001_Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[OF].[IndicatorList] T2
      ON T1.ReferenceID = T2.ReferenceID


  --  SELECT TOP 1000 *    FROM #41001_Dataset 

  -- Insert Data
/*

  INSERT INTO [EAT_Reporting_BSOL].[OF].[IndicatorData] 
        (				
		 [IndicatorID]
        ,[ReferenceID]
        ,[TimePeriod] 
        ,[Financial_Year]
        ,[Ethnicity_Code]
        ,[Gender]	
        ,[Age]		
        ,[LSOA_2011] 
        ,[LSOA_2021] 
        ,[Ward_Code] 
        ,[Ward_Name] 
        ,[LAD_Code]
        ,[LAD_Name]
        ,[Locality_Res]
        ,[GP_Practice]	
        ,[Numerator]		
        )
		(
  SELECT [IndicatorID]
        ,[ReferenceID]
        ,[TimePeriod] 
        ,[Financial_Year]
        ,[Ethnicity_Code]
        ,[Gender]	
        ,[Age]		
        ,[LSOA_2011] 
        ,[LSOA_2021] 
        ,[Ward_Code] 
        ,[Ward_Name] 
        ,[LAD_Code]
        ,[LAD_Name]
        ,[Locality_Res]
        ,[GP_Practice]	
        ,[Numerator]	
    FROM #41001_Dataset
	    )

*/	


  