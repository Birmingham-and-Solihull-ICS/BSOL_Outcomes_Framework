
  DROP TABLE IF EXISTS #Max_Date              
                      ,#Numerator
					  ,#Dataset


   -- Get the latest PeriodEndingDate for each practice for each financial year

  SELECT OrgCode
        ,YearNumber
        ,MAX(PeriodEndingDate) as PeriodEndingDate
	INTO #Max_Date
    FROM [AnalystGlobal].[Performance].[FluVaccineUptakeAll] T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[BSOL_ICS_PracticeMapped] T2
      ON T1.OrgCode = T2.GPPracticeCode_Original
   WHERE T2.ICS_2223 = 'BSOL'
     AND Dataset = 'All children'
     AND [Group] = 'Aged 2 years to under 4 years'
   GROUP BY  OrgCode
            ,YearNumber


  -- Numerator

  SELECT T1.YearNumber as TimePeriod
        ,T1.Orgcode as GP_Practice
		,[Value] as Numerator
	INTO #Numerator
    FROM [AnalystGlobal].[Performance].[FluVaccineUptakeAll] T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[BSOL_ICS_PracticeMapped] T2
      ON T1.OrgCode = T2.GPPracticeCode_Original
   INNER JOIN #Max_Date T3
      ON T1.OrgCode = T3.OrgCode
     AND T1.PeriodEndingDate = T3.PeriodEndingDate
   WHERE T2.ICS_2223 = 'BSOL'
     AND Indicator = 'No. vaccinated'
     AND Dataset = 'All children'
     AND [Group] = 'Aged 2 years to under 4 years'
--	 AND T1.OrgCode = 'M85149'
	

  -- Dataset with Denominator

  SELECT CONVERT(INT,NULL) as IndicatorID
		,'93386' as ReferenceID
        ,T1.YearNumber as TimePeriod
        ,CONVERT(VARCHAR(50),NULL) as TimePeriodDesc
        ,T1.Orgcode as GP_Practice
		,CONVERT(VARCHAR(100),NULL) as PCN
		,CONVERT(VARCHAR(20),NULL) as Locality_Reg
		,CONVERT(INT,NULL) as Numerator
		,Value as Denominator
		,'Practice Level' as Indicator_Level
		,NULL as LSOA_2011
		,NULL as LSOA_2021
		,NULL as Ethnicity_Code
	INTO #Dataset
    FROM [AnalystGlobal].[Performance].[FluVaccineUptakeAll] T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[BSOL_ICS_PracticeMapped] T2
      ON T1.OrgCode = T2.GPPracticeCode_Original
   INNER JOIN #Max_Date T3
      ON T1.OrgCode = T3.OrgCode
     AND T1.PeriodEndingDate = T3.PeriodEndingDate
   WHERE T2.ICS_2223 = 'BSOL'
     AND Indicator = 'Patients registered'
     AND Dataset = 'All children'
     AND [Group] = 'Aged 2 years to under 4 years'



  -- Updates

  UPDATE #Dataset
     SET Numerator = T2.Numerator
    FROM #Dataset T1
   INNER JOIN #Numerator T2
      ON T1.GP_Practice = T2.GP_Practice
	 AND T1.TimePeriod = T2.TimePeriod


  UPDATE #Dataset
     SET PCN = T2.PCN
	    ,Locality_Reg = T2.Locality
    FROM #Dataset T1
   INNER JOIN EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T2
      ON T1.GP_Practice = T2.GPPracticeCode_Original
   WHERE T2.ICS_2223 = 'BSOL'

  UPDATE #Dataset
     SET TimePeriodDesc = 'Financial Year'

  UPDATE #Dataset
     SET IndicatorID = T2.IndicatorID
	FROM #Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[OF].[IndicatorList] T2
      ON T1.ReferenceID = T2.ReferenceID

  


 SELECT *
   FROM #Dataset

  -- Insert into static table

  INSERT INTO [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator] 
        (
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
   SELECT [IndicatorID]
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
	 FROM #Dataset
	    )