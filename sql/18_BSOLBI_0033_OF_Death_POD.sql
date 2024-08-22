   
  -- Increase % of deaths that occur at home 

  -- Numerator = deaths at home
  -- Denominator = All deaths

  -- Split data by BSOL Practice

  DROP TABLE IF EXISTS #PatientCohort
                      ,#Numerator_Home
					  ,#Numerator_Hospice
					  ,#Denominator

  SELECT PatientId
        ,POD_CODE
		,T4.YearMonth as YYYYMM
		,T1.POD_ESTABLISHMENT_TYPE
		,T3.DeathLocationTypeDescription
		,CONVERT(VARCHAR(5),NULL) as Ethnicity_Code
		,T1.LSOA_OF_RESIDENCE_CODE as LSOA_2011
		,CONVERT(VARCHAR(10),NULL) as LSOA_2021
	INTO #PatientCohort
    FROM LocalFeeds.[Reporting].[Deaths_Register] T1
   INNER JOIN EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T2
      ON T1.GP_PRACTICE_CODE = T2.GPPracticeCode_Original
	LEFT JOIN Reference.Community.DIM_tbDeathLocationType T3
	  ON T1.POD_NHS_ESTABLISHMENT = T3.DeathLocationTypeCode
	LEFT JOIN Reference.dbo.DIM_tbDate T4								    
	  ON T1.REG_DATE = T4.Date
   WHERE T2.ICS_2223 = 'BSOL'

  UPDATE #PatientCohort
     SET LSOA_2021 = T2.LSOA21CD
    FROM #PatientCohort T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2011_to_LSOA_2021] T2
      ON T1.LSOA_2011 = T2.LSOA11CD

  UPDATE #PatientCohort
     SET DeathLocationTypeDescription = 'Home'
   WHERE POD_CODE = 'H'

  UPDATE #PatientCohort
     SET DeathLocationTypeDescription = 'Elsewhere'
   WHERE POD_CODE = 'E'

  UPDATE #PatientCohort
     SET Ethnicity_Code = T2.Ethnic_Code
	FROM #PatientCohort T1
   INNER JOIN EAT_Reporting_BSOL.Demographic.Ethnicity T2
      ON T1.PatientId = T2.Pseudo_NHS_Number



  SELECT T1.GP_PRACTICE_CODE
        ,T2.Ethnicity_Code
		,T2.YYYYMM
		,T2.LSOA_2011
		,T2.LSOA_2021
		,SUM(1) as Numerator
	INTO #Numerator_Home
    FROM LocalFeeds.[Reporting].[Deaths_Register] T1
   INNER JOIN #PatientCohort T2
      ON T1.PatientId = T2.PatientId
   WHERE T2.DeathLocationTypeDescription = 'Home'
   GROUP BY T1.GP_PRACTICE_CODE
           ,T2.Ethnicity_Code
		   ,T2.YYYYMM
		   ,T2.LSOA_2011
		   ,T2.LSOA_2021



  SELECT T1.GP_PRACTICE_CODE
        ,T2.Ethnicity_Code
		,T2.YYYYMM
		,T2.LSOA_2011
		,T2.LSOA_2021
		,SUM(1) as Numerator
	INTO #Numerator_Hospice
    FROM LocalFeeds.[Reporting].[Deaths_Register] T1
   INNER JOIN #PatientCohort T2
      ON T1.PatientId = T2.PatientId
   WHERE T2.POD_ESTABLISHMENT_TYPE = '83'
   GROUP BY T1.GP_PRACTICE_CODE
           ,T2.Ethnicity_Code
		   ,T2.YYYYMM
		   ,T2.LSOA_2011
		   ,T2.LSOA_2021


  SELECT T2.YYYYMM 
        ,T1.GP_PRACTICE_CODE
        ,CONVERT(VARCHAR(75),NULL) as PCN
		,CONVERT(VARCHAR(50),NULL) as Locality_Reg
        ,T2.Ethnicity_Code
		,T2.LSOA_2011
		,T2.LSOA_2021
		,CONVERT(INT,NULL) as Numerator_Home
		,CONVERT(INT,NULL) as Numerator_Hospice
		,SUM(1) as Denominator
	INTO #Denominator
    FROM LocalFeeds.[Reporting].[Deaths_Register] T1
   INNER JOIN #PatientCohort T2
      ON T1.PatientId = T2.PatientId
   GROUP BY T1.GP_PRACTICE_CODE
           ,T2.Ethnicity_Code
		   ,T2.YYYYMM
		   ,T2.LSOA_2011
		   ,T2.LSOA_2021


  UPDATE #Denominator
     SET Numerator_Home = T2.Numerator
    FROM #Denominator T1
   INNER JOIN #Numerator_Home T2
      ON T1.Ethnicity_Code = T2.Ethnicity_Code
	 AND T1.YYYYMM = T2.YYYYMM
	 AND T1.GP_PRACTICE_CODE = T2.GP_PRACTICE_CODE
	 AND T1.LSOA_2011 = T2.LSOA_2011
	 AND T1.LSOA_2021 = T2.LSOA_2021

  UPDATE #Denominator
     SET Numerator_Hospice = T2.Numerator
    FROM #Denominator T1
   INNER JOIN #Numerator_Hospice T2
      ON T1.Ethnicity_Code = T2.Ethnicity_Code
	 AND T1.YYYYMM = T2.YYYYMM
	 AND T1.GP_PRACTICE_CODE = T2.GP_PRACTICE_CODE
	 AND T1.LSOA_2011 = T2.LSOA_2011
	 AND T1.LSOA_2021 = T2.LSOA_2021

  UPDATE #Denominator
     SET PCN = T2.PCN
	    ,Locality_Reg = T2.Locality
	FROM #Denominator T1
   INNER JOIN EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T2
      ON T1.GP_PRACTICE_CODE = T2.GPPracticeCode_Original
   WHERE T2.ICS_2223 = 'BSOL'

/*=================================================================================================
  Inserts into OF Staging Table		
=================================================================================================*/

  INSERT INTO [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator] (
        [IndicatorID]
       ,[ReferenceID]
       ,[TimePeriod]
       ,[TimePeriodDesc]
       ,[GP_Practice]
       ,[PCN]
       ,[Locality_Reg]
       ,[Numerator]
       ,[Denominator]
       ,[Indicator_Level]
       ,[LSOA_2011]
       ,[LSOA_2021]
       ,[Ethnicity_Code]
	   )
	   (
  SELECT '122'
        ,'93476'
		,YYYYMM as TimePeriod
		,'Month' as TimePeriodDesc
		,GP_PRACTICE_CODE as GP_Practice
		,PCN
		,Locality_Reg
		,Numerator_Home
		,Denominator
		,'Practice Level' as Indicator_Level
		,LSOA_2011
		,LSOA_2021
		,Ethnicity_Code
    FROM #Denominator
	    )

  INSERT INTO [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator] (
        [IndicatorID]
       ,[ReferenceID]
       ,[TimePeriod]
       ,[TimePeriodDesc]
       ,[GP_Practice]
       ,[PCN]
       ,[Locality_Reg]
       ,[Numerator]
       ,[Denominator]
       ,[Indicator_Level]
       ,[LSOA_2011]
       ,[LSOA_2021]
       ,[Ethnicity_Code]
	   )
	   (
  SELECT '123'
        ,'93478'
		,YYYYMM as TimePeriod
		,'Month' as TimePeriodDesc
		,GP_PRACTICE_CODE as GP_Practice
		,PCN
		,Locality_Reg
		,Numerator_Hospice
		,Denominator
		,'Practice Level' as Indicator_Level
		,LSOA_2011
		,LSOA_2021
		,Ethnicity_Code
    FROM #Denominator
	    )
 
  