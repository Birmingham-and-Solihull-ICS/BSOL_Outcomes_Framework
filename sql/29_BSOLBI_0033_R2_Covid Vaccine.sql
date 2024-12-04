  
  DROP TABLE IF EXISTS #Latest_Date
                      ,#Dataset1
					  ,#Dataset
					  ,#Numerator


  SELECT [Org Code]
        ,MAX([End Date]) as Max_Date
    INTO #Latest_Date
    FROM EAT_Reporting_BSOL.Development.CovidVaccine_Ethnicity_Age_23_24
  GROUP BY [Org Code]

  SELECT CONVERT(INT,NULL) as IndicatorID
		 ,'R2'  as ReferenceID
		,T1.[Org Code] as GP_Practice
		,[Start Date]
        ,[End Date]
		,'April ' + cast(Datepart(yyyy,[Start Date]) as Varchar(10)) +'-June ' +cast(Datepart(yyyy,[End Date]) as Varchar(10)) as TimePeriod
		,Attribute
		 ,CONVERT(VARCHAR(50),NULL) as TimePeriodDesc
		,CONVERT(VARCHAR(10),NULL) as Ethnicity_Code
		,CONVERT(VARCHAR(20),NULL) as Age_Band
		,T3.PCN
		,T3.Locality as Locality_Reg
		,'Practice Level' as Indicator_Level
		,NULL as LSOA_2011
		,NULL as LSOA_2021
		,CONVERT(INT,NULL) as Numerator
		,T1.Value as Denominator
	INTO #Dataset1
    FROM EAT_Reporting_BSOL.Development.CovidVaccine_Ethnicity_Age_23_24 T1
   INNER JOIN #Latest_Date T2
      ON T1.[End Date] = T2.Max_Date
	 AND T1.[Org Code] = T2.[Org Code]
	 INNER JOIN [EAT_Reporting_BSOL].[Reference].[BSOL_ICS_PracticeMapped] T3
      ON T1.[Org Code] = T3.GPPracticeCode_Original

    WHERE  T3.ICS_2223 = 'BSOL'
     AND Attribute LIKE '%registered%'
     AND Attribute NOT LIKE '%At risk%'

--select top 100 * from EAT_Reporting_BSOL.Development.CovidVaccine_Ethnicity_Age_23_24
--where [Org Code]='M81062' AND Attribute like '%vaccinated%'  
--	  AND Attribute like '%1 dose%' --Numerator: only get the at least 1 dose which should include all other patients
--	  AND Attribute not like '%At risk%'


  UPDATE #Dataset1
     SET Age_Band = '5-15'
    FROM #Dataset1
   WHERE Attribute LIKE '%aged 5%'

  UPDATE #Dataset1
     SET Age_Band = '16-50'
    FROM #Dataset1
   WHERE Attribute LIKE '%under 50%'

  UPDATE #Dataset1
     SET Age_Band = '50-64'
    FROM #Dataset1
   WHERE Attribute LIKE '%under 65%'

  UPDATE #Dataset1
     SET Age_Band = '65+'
    FROM #Dataset1
   WHERE Attribute LIKE '%65 plus%'

  UPDATE #Dataset1
     SET Ethnicity_Code = 'K'
   WHERE Attribute LIKE '%Bangladeshi%'
     
  UPDATE #Dataset1
     SET Ethnicity_Code = 'H'
   WHERE Attribute LIKE '%Indian%'

  UPDATE #Dataset1
     SET Ethnicity_Code = 'L'
   WHERE Attribute LIKE '%Asian - Other%'

  UPDATE #Dataset1
     SET Ethnicity_Code = 'J'
   WHERE Attribute LIKE '%Pakistani%'

  UPDATE #Dataset1
     SET Ethnicity_Code = 'N'
   WHERE Attribute LIKE '%Black - African%'

  UPDATE #Dataset1
     SET Ethnicity_Code = 'M'
   WHERE Attribute LIKE '%Black - Caribbean%'

  UPDATE #Dataset1
     SET Ethnicity_Code = 'P'
   WHERE Attribute LIKE '%Black - Other%'
  
  UPDATE #Dataset1
     SET Ethnicity_Code = 'Z'
   WHERE Attribute LIKE '%not%'

  UPDATE #Dataset1
     SET Ethnicity_Code = 'F'
   WHERE Attribute LIKE '%White / Asian%'

  UPDATE #Dataset1
     SET Ethnicity_Code = 'E'
   WHERE Attribute LIKE '%White / Black African%'

  UPDATE #Dataset1
     SET Ethnicity_Code = 'D'
   WHERE Attribute LIKE '%White / Black Caribbean%'

  UPDATE #Dataset1
     SET Ethnicity_Code = 'G'
   WHERE Attribute LIKE '%Mixed Other%'

  UPDATE #Dataset1
     SET Ethnicity_Code = 'S'
   WHERE Attribute LIKE '%Other Ethnic - Any Other%'

  UPDATE #Dataset1
     SET Ethnicity_Code = 'R'
   WHERE Attribute LIKE '%Chinese%'

  UPDATE #Dataset1
     SET Ethnicity_Code = 'A'
   WHERE Attribute LIKE '%White - British%'

  UPDATE #Dataset1
     SET Ethnicity_Code = 'B'
   WHERE Attribute LIKE '%White - Irish%'

  UPDATE #Dataset1
     SET Ethnicity_Code = 'C'
   WHERE Attribute LIKE '%White - Other%'

  UPDATE #Dataset1
     SET Ethnicity_Code = 'S'
   WHERE Attribute = '%Any Other ethnicity%'

  UPDATE #Dataset1
     SET Ethnicity_Code = 'S'
   WHERE Attribute IN ( 'Any Other ethnicity code aged 16 to under 50 registered'
                       ,'Any Other ethnicity code aged 5 to under 16 registered'
                       ,'Any Other ethnicity code aged 50 to under 65 registered'
                       ,'Any Other ethnicity code aged 65 plus registered'
					  )

  -- Numerator

  SELECT T1.[Org Code]
        ,[End Date]
		,Attribute
		,CONVERT(VARCHAR(10),NULL) as Ethnicity_Code
		,CONVERT(VARCHAR(20),NULL) as Age_Band
		,T1.Value as Numerator
	INTO #Numerator
    FROM EAT_Reporting_BSOL.Development.CovidVaccine_Ethnicity_Age_23_24 T1
   INNER JOIN #Latest_Date T2
     ON T1.[End Date] = t2.Max_Date
	 AND T1.[Org Code] = T2.[Org Code]
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[BSOL_ICS_PracticeMapped] T3
      ON T1.[Org Code] = T3.GPPracticeCode_Original

    WHERE  T3.ICS_2223 = 'BSOL'
	 AND Attribute like '%vaccinated%'  
	  AND Attribute like '%1 dose%' --Numerator: only get the at least 1 dose which should include all other patients
	  AND Attribute not like '%At risk%'
  
  UPDATE #Numerator
     SET Age_Band = '5-15'
    FROM #Numerator
   WHERE Attribute LIKE '%aged 5%'

  UPDATE #Numerator
     SET Age_Band = '16-50'
    FROM #Numerator
   WHERE Attribute LIKE '%under 50%'

  UPDATE #Numerator
     SET Age_Band = '50-64'
    FROM #Numerator
   WHERE Attribute LIKE '%under 65%'

  UPDATE #Numerator
     SET Age_Band = '65+'
    FROM #Numerator
   WHERE Attribute LIKE '%65 plus%'


  UPDATE #Numerator
     SET Ethnicity_Code = 'K'
   WHERE Attribute LIKE '%Bangladeshi%'
     

  UPDATE #Numerator
     SET Ethnicity_Code = 'H'
   WHERE Attribute LIKE '%Indian%'

  UPDATE #Numerator
     SET Ethnicity_Code = 'L'
   WHERE Attribute LIKE '%Asian - Other%'

  UPDATE #Numerator
     SET Ethnicity_Code = 'J'
   WHERE Attribute LIKE '%Pakistani%'

  UPDATE #Numerator
     SET Ethnicity_Code = 'N'
   WHERE Attribute LIKE '%Black - African%'

  UPDATE #Numerator
     SET Ethnicity_Code = 'M'
   WHERE Attribute LIKE '%Black - Caribbean%'

  UPDATE #Numerator
     SET Ethnicity_Code = 'P'
   WHERE Attribute LIKE '%Black - Other%'
  
  UPDATE #Numerator
     SET Ethnicity_Code = 'Z'
   WHERE Attribute LIKE '%not%'

  UPDATE #Numerator
     SET Ethnicity_Code = 'F'
   WHERE Attribute LIKE '%White / Asian%'

  UPDATE #Numerator
     SET Ethnicity_Code = 'E'
   WHERE Attribute LIKE '%White / Black African%'

  UPDATE #Numerator
     SET Ethnicity_Code = 'D'
   WHERE Attribute LIKE '%White / Black Caribbean%'

  UPDATE #Numerator
     SET Ethnicity_Code = 'G'
   WHERE Attribute LIKE '%Mixed Other%'

  UPDATE #Numerator
     SET Ethnicity_Code = 'S'
   WHERE Attribute LIKE '%Other Ethnic - Any Other%'

  UPDATE #Numerator
     SET Ethnicity_Code = 'R'
   WHERE Attribute LIKE '%Chinese%'

  UPDATE #Numerator
     SET Ethnicity_Code = 'A'
   WHERE Attribute LIKE '%White - British%'

  UPDATE #Numerator
     SET Ethnicity_Code = 'B'
   WHERE Attribute LIKE '%White - Irish%'

  UPDATE #Numerator
     SET Ethnicity_Code = 'C'
   WHERE Attribute LIKE '%White - Other%'

  UPDATE #Numerator
     SET Ethnicity_Code = 'S'
   WHERE Attribute = '%Any Other ethnicity%'

  UPDATE #Numerator
     SET Ethnicity_Code = 'S'
   WHERE Attribute IN (  'Any Other ethnicity code aged 16 to under 50 vaccinated with at least 1 dose'
                        ,'Any Other ethnicity code aged 5 to under 16 vaccinated with at least 1 dose'
                        ,'Any Other ethnicity code aged 50 to under 65 vaccinated with at least 1 dose'
                        ,'Any Other ethnicity code aged 65 plus vaccinated with at least 1 dose'
					  )

--select count(*) from #Numerator
  -- Update denominator Dataset with numerator
  
  UPDATE #Dataset1
     SET Numerator = T2.Numerator
    FROM #Dataset1 T1
   INNER JOIN #Numerator T2
      ON T1.[GP_Practice] = T2.[Org Code]
	 AND T2.[End Date] = T2.[End Date]
	 AND T1.Age_Band = T2.Age_Band
	 AND T1.Ethnicity_Code = T2.Ethnicity_Code

 UPDATE #Dataset1
     SET TimePeriodDesc = 'Other'

	 --select * from #Dataset1

  UPDATE #Dataset1
     SET IndicatorID = T2.IndicatorID
	FROM #Dataset1 T1
   INNER JOIN [EAT_Reporting_BSOL].[OF].[IndicatorList] T2
      ON T1.ReferenceID = T2.ReferenceID


  SELECT [IndicatorID]
        ,[ReferenceID]
        ,[TimePeriod]
        ,[TimePeriodDesc]
        ,[GP_Practice]
        ,[PCN]
        ,[Locality_Reg]
		,[Indicator_Level]
        ,[LSOA_2011]
        ,[LSOA_2021]
        ,[Ethnicity_Code]
		,SUM(Numerator) as Numerator
		,SUM(Denominator) as Denominator
	into #Dataset
    FROM #Dataset1
	
   GROUP BY [IndicatorID]
        ,[ReferenceID]
        ,[TimePeriod]
        ,[TimePeriodDesc]
        ,[GP_Practice]
        ,[PCN]
        ,[Locality_Reg]
		,[Indicator_Level]
        ,[LSOA_2011]
        ,[LSOA_2021]
        ,[Ethnicity_Code]
  
  --select * from #Dataset
  --select * from [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator] 

  -- Insert into static table

  --INSERT INTO [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator] 
  --      (
  --       [IndicatorID]
  --      ,[ReferenceID]
  --      ,[TimePeriod]
  --      ,[TimePeriodDesc]
  --      ,[GP_Practice]
  --      ,[PCN]
  --      ,[Locality_Reg]
  --      ,[Numerator]
  --      ,[Denominator]
  --      ,[Indicator_Level]
  --      ,[LSOA_2011]
  --      ,[LSOA_2021]
  --      ,[Ethnicity_Code]
	 --   )
		--(
  -- SELECT [IndicatorID]
  --       ,[ReferenceID]
  --       ,[TimePeriod]
  --       ,[TimePeriodDesc]
  --       ,[GP_Practice]
  --       ,[PCN]
  --       ,[Locality_Reg]
  --       ,[Numerator]
  --       ,[Denominator]
  --       ,[Indicator_Level]
  --       ,[LSOA_2011]
  --       ,[LSOA_2021]
  --       ,[Ethnicity_Code]
 --FROM #Dataset
	 --   )
		

		
		