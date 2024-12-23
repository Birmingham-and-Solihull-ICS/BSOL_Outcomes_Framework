

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
  SELECT '20'
        ,'91340'
		,time_period
		,'Financial Year'
		,area_code
		,PCN as PCN
		,Locality as Locality_Reg
		,[count] as numerator
		,denominator as denominator
		,'Practice Level' as Indicator_Level
		,NULL
		,NULL
		,NULL
    FROM EAT_Reporting_BSOL.Development.OF_91340_FT_Data T1
   INNER JOIN EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T2
      ON T1.area_code = T2.GPPracticeCode_Original
   WHERE ICS_2223 = 'BSOL'
        )

 