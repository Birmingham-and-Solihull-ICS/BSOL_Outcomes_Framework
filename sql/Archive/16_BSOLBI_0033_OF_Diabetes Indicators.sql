 

   DROP TABLE IF EXISTS #Dataset
                       ,#Dataset_Final

/*=================================================================================================
  93209 -- Percentage of people with type 2 diabetes aged 40 to 64		
=================================================================================================*/
 
  SELECT CONVERT(INT,NULL) as IndicatorID
        ,'93209' as ReferenceID
		,NULL as TimePeriod
		,AUDIT_YEAR as Financial_Year
		,DERIVED_CLEAN_ETHNICITY as Ethnicity_Code 
		,CONVERT(VARCHAR(20),DERIVED_CLEAN_SEX) as Gender
		,AGE
		,DERIVED_LSOA as LSOA_2011
		,CONVERT(VARCHAR(10),NULL) as LSOA_2021
		,CONVERT(VARCHAR(9),NULL)  as Ward_Code
		,CONVERT(VARCHAR(53),NULL) as Ward_Name		
		,CONVERT(VARCHAR(9),NULL)  as LAD_Code
		,CONVERT(VARCHAR(10),NULL) as LAD_Name
		,CONVERT(VARCHAR(10),NULL) as Locality_Res		
        ,DERIVED_GP_PRACTICE_CODE  as GP_Practice
		,PatientId
	INTO #Dataset
    FROM localfeeds.[Reporting].[NationalDiabetesAudit_NDA_Core_Data] T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2011_BSOL_Codes] T2  
      ON T1.DERIVED_LSOA = T2.CODE  -- BSOL Residents
   WHERE T1.DERIVED_CLEAN_DIABETES_TYPE = 2 
     AND age >= 40 AND age <=64
     AND AUDIT_YEAR in ('201415','201516','201617','201718','201819'
	                   ,'201920','202021','202122E4','202223','202324E1')

  UPDATE #Dataset
     SET Ethnicity_Code = T2.Ethnic_Code
    FROM #Dataset T1
   INNER JOIN EAT_Reporting_BSOL.Demographic.Ethnicity T2
      ON T1.PatientId = T2.Pseudo_NHS_Number

  UPDATE #Dataset
     SET Financial_Year = '2021-22'
   WHERE Financial_Year = '202122E4'

  UPDATE #Dataset
     SET Financial_Year = '2023-24'
   WHERE Financial_Year = '202324E1'

  UPDATE #Dataset
     SET Financial_Year = '2018-19'
   WHERE Financial_Year = '201819'

  UPDATE #Dataset
     SET Financial_Year = '2014-15'
   WHERE Financial_Year = '201415'

  UPDATE #Dataset
     SET Financial_Year = '2022-23'
   WHERE Financial_Year = '202223'

  UPDATE #Dataset
     SET Financial_Year = '2016-17'
   WHERE Financial_Year = '201617'

  UPDATE #Dataset
     SET Financial_Year = '2015-16'
   WHERE Financial_Year = '201516'

  UPDATE #Dataset
     SET Financial_Year = '2019-20'
   WHERE Financial_Year = '201920'

  UPDATE #Dataset
     SET Financial_Year = '2023-24'
   WHERE Financial_Year = '202324'

  UPDATE #Dataset
     SET Financial_Year = '2020-21'
   WHERE Financial_Year = '202021'

  UPDATE #Dataset
     SET Financial_Year = '2017-18'
   WHERE Financial_Year = '201718'

  UPDATE #Dataset
     SET Financial_Year = '2021-22'
   WHERE Financial_Year = '202122'

  UPDATE #Dataset
     SET Gender = 'Not Known'
   WHERE Gender = '0'

  UPDATE #Dataset
     SET Gender = 'Male'
   WHERE Gender = '1'

  UPDATE #Dataset
     SET Gender = 'Female'
   WHERE Gender = '2'

  UPDATE #Dataset
     SET Gender = 'Not Specified'
   WHERE Gender = '9'

  UPDATE T1
     SET T1.LSOA_2021 = T2.[LSOA21CD]
	FROM #Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2011_to_LSOA_2021] T2
      ON T1.LSOA_2011 = T2.LSOA11CD

  UPDATE T1
     SET T1.[Ward_Code]	= T2.[WD22CD]
        ,T1.[Ward_Name]	= T2.[WD22NM]
        ,T1.[LAD_Code]	= T2.LAD22CD
        ,T1.[LAD_Name]  = T2.LAD22NM
    FROM #Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_WARD_LAD] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]

  UPDATE T1
     SET T1.[Locality_Res]	= T2.[Locality]
    FROM #Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_BSOL_to_Constituency_2025_Locality] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]
 
  UPDATE T1
     SET IndicatorID = T2.IndicatorID
	FROM #Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[OF].[IndicatorList] T2
      ON T1.ReferenceID = T2.ReferenceID

  UPDATE T1 
     SET IndicatorID = 48
	FROM #Dataset T1

  SELECT IndicatorID
        ,ReferenceID
		,TimePeriod
		,Financial_Year
		,Ethnicity_Code
		,Gender
		,Age
		,LSOA_2011
		,LSOA_2021
		,Ward_Code
		,Ward_Name
		,LAD_Code
		,LAD_Name
		,Locality_Res
		,GP_Practice 
		,SUM(1) as Numerator
	INTO #Dataset_Final
    FROM #Dataset
   GROUP BY IndicatorID
           ,ReferenceID
		   ,TimePeriod
		   ,Financial_Year
		   ,Ethnicity_Code
		   ,Gender
		   ,Age
		   ,LSOA_2011
		   ,LSOA_2021
		   ,Ward_Code
		   ,Ward_Name
		   ,LAD_Code
		   ,LAD_Name
		   ,Locality_Res
		   ,GP_Practice


  SELECT TOP 1000 *
    FROM #Dataset_Final

  INSERT INTO [EAT_Reporting_BSOL].[OF].[IndicatorData] 
        (				
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
  SELECT [IndicatorID]
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
    FROM #Dataset_Final
	    )




  