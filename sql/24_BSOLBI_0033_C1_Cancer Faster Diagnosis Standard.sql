 
 -- Cancer faster diagnosis standard (75% of patients urgently referred by GP for suspected cancer are diagnosed or cancer ruled out within 28 days)


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
  SELECT '70'
        ,'C1'
		,YYYYMM
		,'Month'
		,NULL
		,NULL
		,NULL
		,WithinStandard
		,TotalTreated
		,'ICB Level'
		,NULL
		,NULL
		,NULL
    FROM [AnalystGlobal].[Performance].[NHSEnglandCancerWaitsSubICB]
   WHERE Standard = '28-day FDS'
     AND ICBSubLocationOrgCode = '15E' 
	     )
 