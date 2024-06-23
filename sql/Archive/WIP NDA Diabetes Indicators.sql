

  DROP TABLE IF EXISTS #Dataset_92875

/*=================================================================================================
  92875 -- People with type 2 diabetes who achieved all three treatment targets	
=================================================================================================*/
 
  SELECT CONVERT(INT,NULL) as IndicatorID
        ,'92875' as ReferenceID
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
		,[ALL_3_TREATMENT_TARGETS]
	INTO #Dataset_92875
    FROM localfeeds.[Reporting].[NationalDiabetesAudit_NDA_Core_Data] T1
   INNER JOIN EAT_Reporting_BSOL.[Reference].[BSOL_ICS_PracticeMapped] T2
      ON T1.DERIVED_GP_PRACTICE_CODE = T2.GPPracticeCode_Original
   WHERE T2.ICS_2223 = 'BSOL'
     AND T1.DERIVED_CLEAN_DIABETES_TYPE = 2 
     AND AUDIT_YEAR in ('201415','201516','201617','201718','201819'
	                   ,'201920','202021','202122E4','202223','202324E1')


  UPDATE #Dataset_92875
     SET Ethnicity_Code = T2.Ethnic_Code
    FROM #Dataset_92875 T1
   INNER JOIN EAT_Reporting_BSOL.Demographic.Ethnicity T2
      ON T1.PatientId = T2.Pseudo_NHS_Number

  UPDATE #Dataset_92875
     SET Financial_Year = '2021-22'
   WHERE Financial_Year = '202122E4'

  UPDATE #Dataset_92875
     SET Financial_Year = '2023-24'
   WHERE Financial_Year = '202324E1'

  UPDATE #Dataset_92875
     SET Financial_Year = '2018-19'
   WHERE Financial_Year = '201819'

  UPDATE #Dataset_92875
     SET Financial_Year = '2014-15'
   WHERE Financial_Year = '201415'

  UPDATE #Dataset_92875
     SET Financial_Year = '2022-23'
   WHERE Financial_Year = '202223'

  UPDATE #Dataset_92875
     SET Financial_Year = '2016-17'
   WHERE Financial_Year = '201617'

  UPDATE #Dataset_92875
     SET Financial_Year = '2015-16'
   WHERE Financial_Year = '201516'

  UPDATE #Dataset_92875
     SET Financial_Year = '2019-20'
   WHERE Financial_Year = '201920'

  UPDATE #Dataset_92875
     SET Financial_Year = '2023-24'
   WHERE Financial_Year = '202324'

  UPDATE #Dataset_92875
     SET Financial_Year = '2020-21'
   WHERE Financial_Year = '202021'

  UPDATE #Dataset_92875
     SET Financial_Year = '2017-18'
   WHERE Financial_Year = '201718'

  UPDATE #Dataset_92875
     SET Financial_Year = '2021-22'
   WHERE Financial_Year = '202122'

  UPDATE #Dataset_92875
     SET Gender = 'Not Known'
   WHERE Gender = '0'

  UPDATE #Dataset_92875
     SET Gender = 'Male'
   WHERE Gender = '1'

  UPDATE #Dataset_92875
     SET Gender = 'Female'
   WHERE Gender = '2'

  UPDATE #Dataset_92875
     SET Gender = 'Not Specified'
   WHERE Gender = '9'

  UPDATE T1
     SET T1.LSOA_2021 = T2.[LSOA21CD]
	FROM #Dataset_92875 T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2011_to_LSOA_2021] T2
      ON T1.LSOA_2011 = T2.LSOA11CD

  UPDATE T1
     SET T1.[Ward_Code]	= T2.[WD22CD]
        ,T1.[Ward_Name]	= T2.[WD22NM]
        ,T1.[LAD_Code]	= T2.LAD22CD
        ,T1.[LAD_Name]  = T2.LAD22NM
    FROM #Dataset_92875 T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_WARD_LAD] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]

  UPDATE T1
     SET T1.[Locality_Res]	= T2.[Locality]
    FROM #Dataset_92875 T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_BSOL_to_Constituency_2025_Locality] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]
 
  UPDATE T1
     SET IndicatorID = T2.IndicatorID
	FROM #Dataset_92875 T1
   INNER JOIN [EAT_Reporting_BSOL].[OF].[IndicatorList] T2
      ON T1.ReferenceID = T2.ReferenceID


  SELECT TOP 1000 *
    FROM #Dataset_92875


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
		,SUM(ALL_3_TREATMENT_TARGETS) as Numerator
		,COUNT(DISTINCT PatientId) as Denominator
    FROM #Dataset_92875
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
	

  
 
 
   

  DROP TABLE IF EXISTS #Dataset_92874

/*=================================================================================================
  92874 People with type 1 diabetes who achieved all three treatment targets
=================================================================================================*/
 
  SELECT CONVERT(INT,NULL) as IndicatorID
        ,'92874' as ReferenceID
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
		,[ALL_3_TREATMENT_TARGETS]
	INTO #Dataset_92874
    FROM localfeeds.[Reporting].[NationalDiabetesAudit_NDA_Core_Data] T1
   INNER JOIN EAT_Reporting_BSOL.[Reference].[BSOL_ICS_PracticeMapped] T2
      ON T1.DERIVED_GP_PRACTICE_CODE = T2.GPPracticeCode_Original
   WHERE T2.ICS_2223 = 'BSOL'
     AND T1.DERIVED_CLEAN_DIABETES_TYPE = 1
     AND AUDIT_YEAR in ('201415','201516','201617','201718','201819'
	                   ,'201920','202021','202122E4','202223','202324E1')

  UPDATE #Dataset_92874
     SET Ethnicity_Code = T2.Ethnic_Code
    FROM #Dataset_92874 T1
   INNER JOIN EAT_Reporting_BSOL.Demographic.Ethnicity T2
      ON T1.PatientId = T2.Pseudo_NHS_Number

  UPDATE #Dataset_92874
     SET Financial_Year = '2021-22'
   WHERE Financial_Year = '202122E4'

  UPDATE #Dataset_92874
     SET Financial_Year = '2023-24'
   WHERE Financial_Year = '202324E1'

  UPDATE #Dataset_92874
     SET Financial_Year = '2018-19'
   WHERE Financial_Year = '201819'

  UPDATE #Dataset_92874
     SET Financial_Year = '2014-15'
   WHERE Financial_Year = '201415'

  UPDATE #Dataset_92874
     SET Financial_Year = '2022-23'
   WHERE Financial_Year = '202223'

  UPDATE #Dataset_92874
     SET Financial_Year = '2016-17'
   WHERE Financial_Year = '201617'

  UPDATE #Dataset_92874
     SET Financial_Year = '2015-16'
   WHERE Financial_Year = '201516'

  UPDATE #Dataset_92874
     SET Financial_Year = '2019-20'
   WHERE Financial_Year = '201920'

  UPDATE #Dataset_92874
     SET Financial_Year = '2023-24'
   WHERE Financial_Year = '202324'

  UPDATE #Dataset_92874
     SET Financial_Year = '2020-21'
   WHERE Financial_Year = '202021'

  UPDATE #Dataset_92874
     SET Financial_Year = '2017-18'
   WHERE Financial_Year = '201718'

  UPDATE #Dataset_92874
     SET Financial_Year = '2021-22'
   WHERE Financial_Year = '202122'

  UPDATE #Dataset_92874
     SET Gender = 'Not Known'
   WHERE Gender = '0'

  UPDATE #Dataset_92874
     SET Gender = 'Male'
   WHERE Gender = '1'

  UPDATE #Dataset_92874
     SET Gender = 'Female'
   WHERE Gender = '2'

  UPDATE #Dataset_92874
     SET Gender = 'Not Specified'
   WHERE Gender = '9'

  UPDATE T1
     SET T1.LSOA_2021 = T2.[LSOA21CD]
	FROM #Dataset_92874 T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2011_to_LSOA_2021] T2
      ON T1.LSOA_2011 = T2.LSOA11CD

  UPDATE T1
     SET T1.[Ward_Code]	= T2.[WD22CD]
        ,T1.[Ward_Name]	= T2.[WD22NM]
        ,T1.[LAD_Code]	= T2.LAD22CD
        ,T1.[LAD_Name]  = T2.LAD22NM
    FROM #Dataset_92874 T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_WARD_LAD] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]

  UPDATE T1
     SET T1.[Locality_Res]	= T2.[Locality]
    FROM #Dataset_92874 T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_BSOL_to_Constituency_2025_Locality] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]
 
  UPDATE T1
     SET IndicatorID = T2.IndicatorID
	FROM #Dataset_92874 T1
   INNER JOIN [EAT_Reporting_BSOL].[OF].[IndicatorList] T2
      ON T1.ReferenceID = T2.ReferenceID




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
		,SUM(ALL_3_TREATMENT_TARGETS) as Numerator
		,COUNT(DISTINCT PatientId) as Denominator
    FROM #Dataset_92874
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
	

  
 
 
     