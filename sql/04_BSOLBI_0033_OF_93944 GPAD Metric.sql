/*==================================================================================================================================================================
OUTCOMES FRAMEWORK: GPAD

	93944	Increase % of appointments taking place within 2 days of booking

==================================================================================================================================================================*/



  SELECT YYYYMM
        ,GPCode
        ,SUM(CountOfAppointments) as Numerator
		,CONVERT(INT,NULL) as Denominator
	INTO #GPAD_Dataset
    FROM [AnalystGlobal].[Performance].[ApptsInGeneralPracticeGPLevel] T1
   WHERE CCGCode = '15E'
     AND TimeBetweenBookAndAppt IN ('Same Day','1 Day')
   GROUP BY YYYYMM
           ,GPCode

  SELECT YYYYMM
        ,GPCode
		,SUM(CountOfAppointments) as Denominator
	INTO #GPAD_Denominator
    FROM [AnalystGlobal].[Performance].[ApptsInGeneralPracticeGPLevel] T1
   WHERE CCGCode = '15E'
   GROUP BY YYYYMM
           ,GPCode

  UPDATE #GPAD_Dataset
     SET Denominator = T2.Denominator
	FROM #GPAD_Dataset T1
   INNER JOIN #GPAD_Denominator T2
      ON T1.GPCode = T2.GPCode
	 AND T1.YYYYMM = T2.YYYYMM 


/*=================================================================================================
  Insert into OF Static Table and updates		
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
  SELECT '93944'
         ,YYYYMM
		 ,'Month'
         ,GPCode
		 ,Numerator
		 ,Denominator
    FROM #GPAD_Dataset
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
   