

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
  SELECT '58'
        ,'93753'
		,[Time period]
		,'Financial Year'
		,NULL
		,NULL
		,NULL
		,[Count]
		,[Denominator]
		,'Birmingham Local Authority'
		,NULL
		,NULL
		,NULL
    FROM [Working].[dbo].[BSOL_0033_OF_93753_SmokingAdmissions]
   WHERE [Area Name] = 'Birmingham'
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
  SELECT '58'
        ,'93753'
		,[Time period]
		,'Financial Year'
		,NULL
		,NULL
		,NULL
		,[Count]
		,[Denominator]
		,'Solihull Local Authority'
		,NULL
		,NULL
		,NULL
    FROM [Working].[dbo].[BSOL_0033_OF_93753_SmokingAdmissions]
   WHERE [Area Name] = 'Solihull'
       )