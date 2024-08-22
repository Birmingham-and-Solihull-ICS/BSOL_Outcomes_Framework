-- A&E attendance rate per 1,000 population aged 0-4 years.
USE EAT_Reporting_BSOL

INSERT INTO [EAT_Reporting_BSOL].[OF].[IndicatorData] (
        [IndicatorID]
       ,[ReferenceID]
       ,[TimePeriod]
       ,[Financial_Year]
       ,[Ethnicity_Code]
       ,[Gender]
       ,[Age]
       ,[LSOA_2011]
       ,[LSOA_2021]
       ,[Ward_Code]
       ,[Ward_Name]
       ,[LAD_Code]
       ,[LAD_Name]
       ,[Locality_Res]
       ,[GP_Practice]
       ,[Numerator]
	   )
	   (
  SELECT 108 AS IndicatorID
	    ,93930 AS ReferenceID
	/*,CONCAT (
		DatePart(Year, [ArrivalDate])
		,DatePart(MM, [ArrivalDate])
		) AS TimePeriod*/

	,[ActivityYearMonth] AS TimePeriod
	,CASE 
		WHEN DatePart(Month, [ArrivalDate]) >= 4
			THEN CONCAT (
					DatePart(Year, [ArrivalDate])
					,'-'
					,DatePart(yy, [ArrivalDate]) - 1999
					)
		ELSE CONCAT (
				DatePart(Year, [ArrivalDate]) - 1
				,'-'
				,DatePart(yy, [ArrivalDate]) - 2000
				)
		END AS FinancialYear
	--Replace with GP lookup?
	,CASE 
		WHEN EthnicityTable.Ethnic_Code IS NOT NULL
			THEN EthnicityTable.Ethnic_Code
		ELSE EthnicCategoryCode 
		END AS EthnicityCode
	,[GenderDescription] AS Gender
	,[AgeAtActivityDate] AS Age
	,[LSOA11] AS [LSOA2011]
	,LSOA2011to2022.[LSOA11CD] AS [LSAO21]
	,[WD22CD] AS Ward_Code
	,[WD22NM] AS Ward_Name
	,[LocalAuthorityDistrict] AS LAD_Code
	,[LocalAuthorityDistrictName] AS LAD_NAme
	,[Locality]
	,[GPPracticeCode]
	,COUNT(*) AS count
FROM [ECDSV2].[VwECDSAll] AS ECDSdata
LEFT JOIN (
	SELECT [LSOA11CD]
		,[LSOA21CD]
	FROM [EAT_Reporting_BSOL].[Reference].[LSOA_2011_to_LSOA_2021]
	) AS LSOA2011to2022 ON ECDSdata.[LSOA11] = LSOA2011to2022.[LSOA11CD]
LEFT JOIN (
	SELECT [LSOA21CD]
		,[WD22CD]
		,[WD22NM]
		,[LAD22NM]
	FROM [EAT_Reporting_BSOL].[Reference].[LSOA_2021_WARD_LAD]
	) AS WardTranslation ON LSOA2011to2022.LSOA21CD = WardTranslation.[LSOA21CD]
LEFT JOIN (
	SELECT DISTINCT [LSOA21CD]
		,[LSOA21NM]
		,[Locality]
	FROM [EAT_Reporting_BSOL].[Reference].[LSOA_2021_BSOL_to_Constituency_2025_Locality]
	WHERE [Load_Date] = (
			SELECT MAX([Load_Date])
			FROM [EAT_Reporting_BSOL].[Reference].[LSOA_2021_BSOL_to_Constituency_2025_Locality]
			)
	) AS LSOAtoLocality ON LSOA2011to2022.[LSOA21CD] = LSOAtoLocality.[LSOA21CD]
Left JOIN (
	SELECT [Pseudo_NHS_Number]
      ,[Ethnic_Code]
	FROM [EAT_Reporting_BSOL].[Demographic].[Ethnicity]
	) AS EthnicityTable ON EthnicityTable.Pseudo_NHS_Number = ECDSdata.PseudoNHSNumber

WHERE (
		[LocalAuthorityDistrict] = 'E08000025'
		OR [LocalAuthorityDistrict] = 'E08000029'
		)
	AND [AgeAtActivityDate] BETWEEN 0
		AND 4
	AND (validationErrors is null
	OR ValidationErrors not like '1A%')

GROUP BY CASE 
		WHEN DatePart(Month, [ArrivalDate]) >= 4
			THEN CONCAT (
					DatePart(Year, [ArrivalDate])
					,'-'
					,DatePart(yy, [ArrivalDate]) - 1999
					)
		ELSE CONCAT (
				DatePart(Year, [ArrivalDate]) - 1
				,'-'
				,DatePart(yy, [ArrivalDate]) - 2000
				)
		END
	/*,CONCAT (
		DatePart(Year, [ArrivalDate])
		,DatePart(MM, [ArrivalDate])
		)*/
	,[ActivityYearMonth]
	,[GenderDescription]
	,[AgeAtActivityDate]
	,CASE 
		WHEN EthnicityTable.Ethnic_Code IS NOT NULL
			THEN EthnicityTable.Ethnic_Code
		ELSE EthnicCategoryCode 
		END
	,[LSOA11]
	,LSOA2011to2022.[LSOA11CD]
	,[WD22CD]
	,[WD22NM]
	,[LocalAuthorityDistrict]
	,[LocalAuthorityDistrictName]
	,[Locality]
	,GPPracticeCode
	)


