

 
  DROP TABLE IF EXISTS #Practice_Level
                      ,#Underlying_Prevalence
					  ,#ICB_Actuals
					  ,#Practice_Level_Final

/*=================================================================================================
 Practice Level - Dementia Diagnosis			
=================================================================================================*/

  SELECT T1.YYYYMM
        ,T1.PracticeCode as 'Practice Code'
		,T1.Value as 'Actuals'
		,CONVERT(INT,NULL) as 'Underlying Prevalence'
		,CONVERT(DECIMAL(19,4),NULL) as 'Dementia Diagnosis Rate'
		,CONVERT(INT,NULL) as 'Underlying Prevalence_LL'
		,CONVERT(DECIMAL(19,4),NULL) as 'Dementia Diagnosis Rate_LL'
		,CONVERT(INT,NULL) as 'Underlying Prevalence_UL'
		,CONVERT(DECIMAL(19,4),NULL) as 'Dementia Diagnosis Rate_UL'
	INTO #Practice_Level	
    FROM [AnalystGlobal].[Performance].[PrimaryCareDementia] T1
   WHERE Measure = 'DEMENTIA_REGISTER_65_PLUS'
	 AND ICB_ODSCode = 'QHL'
	 AND T1.PracticeCode NOT IN ('Y01057') -- Dementia Register is 0 so causing divide by 0 error
   ORDER BY 1,2  
 
 

  -- Calculate Underlying Prevalence / Denominator
  
  SELECT CONVERT(VARCHAR(6),Effective_SnapShot_Date,112) as YYYYMM
        ,T2.GPPracticeCode_Original
        ,T2.GPPracticeCode_Current
		, CONVERT(DECIMAL(19,4),[MALE_65-69] * 0.012)
        + CONVERT(DECIMAL(19,4),[MALE_70-74] * 0.03)
        + CONVERT(DECIMAL(19,4),[MALE_75-79] * 0.052)
        + CONVERT(DECIMAL(19,4),[MALE_80-84] * 0.106)
        + CONVERT(DECIMAL(19,4),[MALE_85-89] * 0.128)
        + CONVERT(DECIMAL(19,4),SUM ([MALE_90-94] + [MALE_95+]) * 0.171 )
        + CONVERT(DECIMAL(19,4),[FEMALE_65-69] * 0.018)
        + CONVERT(DECIMAL(19,4),[FEMALE_70-74] * 0.025)
        + CONVERT(DECIMAL(19,4),[FEMALE_75-79] * 0.062)
        + CONVERT(DECIMAL(19,4),[FEMALE_80-84] * 0.095)
        + CONVERT(DECIMAL(19,4),[FEMALE_85-89] * 0.181)
        + CONVERT(DECIMAL(19,4),SUM([FEMALE_90-94] + [FEMALE_95+]) * 0.35)  as 'Underlying_Prevalence'

		, CONVERT(DECIMAL(19,4),[MALE_65-69] * 0.006)
        + CONVERT(DECIMAL(19,4),[MALE_70-74] * 0.020)
        + CONVERT(DECIMAL(19,4),[MALE_75-79] * 0.038)
        + CONVERT(DECIMAL(19,4),[MALE_80-84] * 0.082)
        + CONVERT(DECIMAL(19,4),[MALE_85-89] * 0.090)
        + CONVERT(DECIMAL(19,4),SUM ([MALE_90-94] + [MALE_95+]) * 0.106)
        + CONVERT(DECIMAL(19,4),[FEMALE_65-69] * 0.009)
        + CONVERT(DECIMAL(19,4),[FEMALE_70-74] * 0.016)
        + CONVERT(DECIMAL(19,4),[FEMALE_75-79] * 0.045)
        + CONVERT(DECIMAL(19,4),[FEMALE_80-84] * 0.073)
        + CONVERT(DECIMAL(19,4),[FEMALE_85-89] * 0.145)
        + CONVERT(DECIMAL(19,4),SUM([FEMALE_90-94] + [FEMALE_95+]) * 0.284)  as 'Underlying_Prevalence_LL'

		, CONVERT(DECIMAL(19,4),[MALE_65-69] * 0.023)
        + CONVERT(DECIMAL(19,4),[MALE_70-74] * 0.044)
        + CONVERT(DECIMAL(19,4),[MALE_75-79] * 0.070)
        + CONVERT(DECIMAL(19,4),[MALE_80-84] * 0.137)
        + CONVERT(DECIMAL(19,4),[MALE_85-89] * 0.180)
        + CONVERT(DECIMAL(19,4),SUM ([MALE_90-94] + [MALE_95+]) * 0.264)
        + CONVERT(DECIMAL(19,4),[FEMALE_65-69] * 0.036)
        + CONVERT(DECIMAL(19,4),[FEMALE_70-74] * 0.039)
        + CONVERT(DECIMAL(19,4),[FEMALE_75-79] * 0.084)
        + CONVERT(DECIMAL(19,4),[FEMALE_80-84] * 0.123)
        + CONVERT(DECIMAL(19,4),[FEMALE_85-89] * 0.222)
        + CONVERT(DECIMAL(19,4),SUM([FEMALE_90-94] + [FEMALE_95+]) * 0.423)  as 'Underlying_Prevalence_UL'
	INTO #Underlying_Prevalence
	FROM Reference.[Population].DIM_tbGPPractice_Patient_Population_5Yr_Age_Bands T1
   INNER JOIN EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T2
      ON T1.PRACTICE_CODE = T2.GPPracticeCode_Original
   WHERE ICS_2223 = 'BSOL'
     AND GPPracticeCode_Original NOT IN ('Y01057') -- Dementia Register is 0 so causing divide by 0 error
   GROUP BY  CONVERT(VARCHAR(6),Effective_SnapShot_Date,112)
            ,T2.GPPracticeCode_Original
            ,T2.GPPracticeCode_Current
            ,T2.GPPracticeName_Current
		    ,[MALE_65-69]
            ,[MALE_70-74]
            ,[MALE_75-79]
            ,[MALE_80-84]
            ,[MALE_85-89]
            ,[MALE_95+]
            ,[FEMALE_65-69]
            ,[FEMALE_70-74]
            ,[FEMALE_75-79]
            ,[FEMALE_80-84]
            ,[FEMALE_85-89]


/*=================================================================================================
 Updates for Null columns			
=================================================================================================*/


  UPDATE #Practice_Level 
     SET [Underlying Prevalence] = T2.[Underlying_Prevalence]
	    ,[Underlying Prevalence_LL] = T2.Underlying_Prevalence_LL 
		,[Underlying Prevalence_UL] = T2.Underlying_Prevalence_UL
    FROM #Practice_Level T1
   INNER JOIN #Underlying_Prevalence T2
      ON T1.[Practice Code] = T2.GPPracticeCode_Original
	 AND T1.YYYYMM = T2.YYYYMM

  UPDATE #Practice_Level 
     SET [Underlying Prevalence] = T2.[Underlying_Prevalence]
	    ,[Underlying Prevalence_LL] = T2.Underlying_Prevalence_LL 
		,[Underlying Prevalence_UL] = T2.Underlying_Prevalence_UL
    FROM #Practice_Level T1
   INNER JOIN #Underlying_Prevalence T2
      ON T1.[Practice Code] = T2.GPPracticeCode_Current
	 AND T1.YYYYMM = T2.YYYYMM
   WHERE [Underlying Prevalence] IS NULL


  UPDATE #Practice_Level
     SET [Dementia Diagnosis Rate] = Actuals / [Underlying Prevalence]
	    ,[Dementia Diagnosis Rate_LL] = Actuals / [Underlying Prevalence_LL]
		,[Dementia Diagnosis Rate_UL] = Actuals / [Underlying Prevalence_UL]


 -- If Actuals are larger than Underlying Prevalence then we are updating Dementia Rate = 100% and Gap to Target = 0 to match Aristotle Report 

  UPDATE #Practice_Level
     SET [Dementia Diagnosis Rate] = 1
   WHERE Actuals > [Underlying Prevalence]

  UPDATE #Practice_Level
     SET [Dementia Diagnosis Rate_LL] = 1
   WHERE Actuals > [Underlying Prevalence_LL]

  UPDATE #Practice_Level
     SET [Dementia Diagnosis Rate_UL] = 1
   WHERE Actuals > [Underlying Prevalence_UL]

  SELECT *
    INTO #Practice_Level_Final
    FROM #Practice_Level




/*=================================================================================================
  Insert into OF table and Updates		
=================================================================================================*/


  INSERT INTO [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator] (
       [ReferenceID] 
      ,[TimePeriod] 
	  ,[TimePeriodDesc]
      ,[GP_Practice] 
      ,[Numerator] 
	  ,[Denominator] 
	  )
	  (
  SELECT '92949'
         ,YYYYMM
		 ,'Month'
         ,[Practice code]
		 ,Actuals
		 ,[Underlying Prevalence]
    FROM #Practice_Level_Final
      )


  UPDATE [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]
     SET IndicatorID = T2.IndicatorID
	FROM [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator] T1
   INNER JOIN [EAT_Reporting_BSOL].[OF].[IndicatorList] T2
      ON T1.ReferenceID = T2.ReferenceID

  UPDATE [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]
     SET PCN = T2.PCN
	    ,Locality_Reg = T2.Locality
    FROM [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator] T1
   INNER JOIN EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T2
      ON T1.GP_Practice = T2.GPPracticeCode_Original
   WHERE ICS_2223 = 'BSOL'
   
   
