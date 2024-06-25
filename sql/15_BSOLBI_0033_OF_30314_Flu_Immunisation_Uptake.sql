
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
     AND Dataset = 'All patients aged 65 plus years'
   GROUP BY  OrgCode
            ,YearNumber


  -- Numerator

  SELECT T1.YearNumber as TimePeriod
        ,T1.Orgcode as GP_Practice
		,[Group] as Ethnicity_Code
		,[Value] as Numerator
	INTO #Numerator
    FROM [AnalystGlobal].[Performance].[FluVaccineUptakeAll] T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[BSOL_ICS_PracticeMapped] T2
      ON T1.OrgCode = T2.GPPracticeCode_Original
   INNER JOIN #Max_Date T3
      ON T1.OrgCode = T3.OrgCode
     AND T1.PeriodEndingDate = T3.PeriodEndingDate
   WHERE T2.ICS_2223 = 'BSOL'
     AND Dataset = 'All patients aged 65 plus years'
     AND Indicator = 'No. vaccinated'
	 AND [Group] <> 'Total ethnicity '
--	 AND T1.OrgCode = 'M85149'
	

  -- Dataset with Denominator

  SELECT CONVERT(INT,NULL) as IndicatorID
		,'30314' as ReferenceID
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
		,[Group] as Ethnicity_Code
	INTO #Dataset
    FROM [AnalystGlobal].[Performance].[FluVaccineUptakeAll] T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[BSOL_ICS_PracticeMapped] T2
      ON T1.OrgCode = T2.GPPracticeCode_Original
   INNER JOIN #Max_Date T3
      ON T1.OrgCode = T3.OrgCode
     AND T1.PeriodEndingDate = T3.PeriodEndingDate
   WHERE T2.ICS_2223 = 'BSOL'
     AND Dataset = 'All patients aged 65 plus years'
     AND Indicator = 'Patients registered'
	 AND [Group] <> 'Total ethnicity '


  -- Updates

  UPDATE #Dataset
     SET Numerator = T2.Numerator
    FROM #Dataset T1
   INNER JOIN #Numerator T2
      ON T1.GP_Practice = T2.GP_Practice
	 AND T1.Ethnicity_Code = T2.[Ethnicity_Code]
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

  -- Updating Ethnicity Descriptions to best fit Ethnicity Code

  UPDATE #Dataset
     SET Ethnicity_Code = 'S'
   WHERE Ethnicity_Code = 'Any other ethnic group '

  UPDATE #Dataset
     SET Ethnicity_Code = 'S'
   WHERE Ethnicity_Code = 'Any other ethnicity code '

  UPDATE #Dataset
     SET Ethnicity_Code = 'K'
   WHERE Ethnicity_Code = 'Asian Bangladeshi '

  UPDATE #Dataset
     SET Ethnicity_Code = 'H'
   WHERE Ethnicity_Code = 'Asian Indian '

  UPDATE #Dataset
     SET Ethnicity_Code = 'L'
   WHERE Ethnicity_Code = 'Asian other '

  UPDATE #Dataset
     SET Ethnicity_Code = 'J'
   WHERE Ethnicity_Code = 'Asian Pakistani '

  UPDATE #Dataset
     SET Ethnicity_Code = 'N'
   WHERE Ethnicity_Code = 'Black African '

  UPDATE #Dataset
     SET Ethnicity_Code = 'M'
   WHERE Ethnicity_Code = 'Black Caribbean '

  UPDATE #Dataset
     SET Ethnicity_Code = 'P'
   WHERE Ethnicity_Code = 'Black other '

  UPDATE #Dataset
     SET Ethnicity_Code = 'Z'
   WHERE Ethnicity_Code IN ('Ethnicity not given/refused ','Ethnicity not recorded ','Ethnicity not stated ')

  UPDATE #Dataset
     SET Ethnicity_Code = 'G'
   WHERE Ethnicity_Code = 'Mixed other '

  UPDATE #Dataset
     SET Ethnicity_Code = 'F'
   WHERE Ethnicity_Code = 'Mixed white/Asian '

  UPDATE #Dataset
     SET Ethnicity_Code = 'E'
   WHERE Ethnicity_Code = 'Mixed white/black African '

  UPDATE #Dataset
     SET Ethnicity_Code = 'D'
   WHERE Ethnicity_Code = 'Mixed white/black Caribbean '

  UPDATE #Dataset
     SET Ethnicity_Code = 'R'
   WHERE Ethnicity_Code = 'Other ethnic: Chinese '

  UPDATE #Dataset
     SET Ethnicity_Code = 'A'
   WHERE Ethnicity_Code = 'White British '

  UPDATE #Dataset
     SET Ethnicity_Code = 'B'
   WHERE Ethnicity_Code = 'White Irish '

  UPDATE #Dataset
     SET Ethnicity_Code = 'C'
   WHERE Ethnicity_Code = 'White other '



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