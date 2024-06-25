  	
/*=================================================================================================
  Table Creations			
=================================================================================================*/	


  -- Table 1
  
    CREATE TABLE  [EAT_Reporting_BSOL].[OF].[IndicatorData] (
       [IndicatorID] INT
	  ,[ReferenceID] INT
      ,[TimePeriod] INT
	  ,[Financial_Year] VARCHAR(7)
      ,[Ethnicity_Code] VARCHAR(5)
      ,[Gender] VARCHAR(100)
      ,[Age] INT
      ,[LSOA_2011] VARCHAR(9)
	  ,[LSOA_2021] VARCHAR(9)
	  ,[Ward_Code] VARCHAR(9)
	  ,[Ward_Name] VARCHAR(53)
	  ,[LAD_Code] VARCHAR(9)
	  ,[LAD_Name] VARCHAR(10)
	  ,[Locality_Res] VARCHAR(10)
      ,[GP_Practice] VARCHAR(10)
      ,[Numerator] FLOAT
	  )
	
	
  -- Table 2
	
	CREATE TABLE  [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator] (
       [IndicatorID] INT
	  ,[ReferenceID] INT
      ,[TimePeriod] VARCHAR(10)
	  ,[TimePeriodDesc] VARCHAR(20)
      ,[Indicator_Level] VARCHAR(30)	  
      ,[GP_Practice] VARCHAR(10)
	  ,PCN VARCHAR(36)
	  ,Locality_Reg VARCHAR(14)
	  ,[LSOA_2011] VARCHAR(9)
	  ,[LSOA_2021] VARCHAR(9)
	  ,[Ethnicity_Code] VARCHAR(5)
      ,[Numerator] FLOAT
	  ,[Denominator] FLOAT
	  )

	   
		
	  


 