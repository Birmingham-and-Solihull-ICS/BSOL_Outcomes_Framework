
/*=================================================================================================
 IndicatorID 16-ReferenceID  90360 - Excess Winter Death Index			
=================================================================================================*/


  DROP TABLE IF EXISTS #Dataset
  
  SELECT top 1000 T2.YearMonth
		--,T1.GP_PRACTICE_CODE	as GP_Practice
		--,T3.PCN
		--,T3.Locality as Locality_Reg
		--,T1.LSOA_OF_RESIDENCE_CODE LSOA_2011
		--,T5.LSOA21CD
		--,case
			--	when ULA_OF_RESIDENCE_CODE = 'E08000025' then 'Birmingham'
			--	when ULA_OF_RESIDENCE_CODE = 'E08000029' then 'Solihull'
		--end
		--,T4.Ethnic_Code
        ,SUM(1) as Deaths
		,CONVERT(TINYINT,NULL) as Winter
		,CONVERT(TINYINT,NULL) as NonWinter
		,CONVERT(VARCHAR(8),NULL) as TimePeriod 
	INTO #Dataset
    FROM LocalFeeds.[Reporting].[Deaths_Register] T1
   INNER JOIN Reference.dbo.DIM_tbDate T2								    ON T1.REG_DATE = T2.Date
   INNER JOIN  EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T3		ON		T1.GP_PRACTICE_CODE = T3.GPPracticeCode_Original--BSOL Registered
   INNER JOIN  EAT_Reporting_BSOL.Demographic.Ethnicity T4					ON  T1.PatientId=T4.Pseudo_NHS_Number 
    LEFT JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2011_to_LSOA_2021] T5  ON T1.LSOA_OF_RESIDENCE_CODE = T5.LSOA11CD
	
   WHERE REG_DATE >= '01-AUG-2013' and ULA_OF_RESIDENCE_CODE in ('E08000025','E08000029')
     AND T3.ICS_2223 = 'BSOL'
   GROUP BY T2.YearMonth
		--,T1.GP_PRACTICE_CODE
		--,T3.PCN
		--,T3.Locality 
		--,T1.LSOA_OF_RESIDENCE_CODE
		--,T5.LSOA21CD
		--,T4.Ethnic_Code


  UPDATE #Dataset
     SET Winter = 1
    FROM #Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[vwYear_Month] T2
      ON T1.YearMonth = T2.YYYYMM
   WHERE T2.CalendarMonth IN (1,2,3,12)

  UPDATE #Dataset
     SET NonWinter = 1
   WHERE Winter IS NULL

  UPDATE #Dataset
     SET Winter = 0 
   WHERE Winter IS NULL

  UPDATE #Dataset
     SET NonWinter = 0 
   WHERE NonWinter IS NULL


  UPDATE #Dataset
     SET TimePeriod = '2013-14'
   WHERE YearMonth BETWEEN 201308 AND 201407

  UPDATE #Dataset
     SET TimePeriod = '2014-15'
   WHERE YearMonth BETWEEN 201408 AND 201507

  UPDATE #Dataset
     SET TimePeriod = '2015-16'
   WHERE YearMonth BETWEEN 201508 AND 201607

  UPDATE #Dataset
     SET TimePeriod = '2016-17'
   WHERE YearMonth BETWEEN 201608 AND 201707

  UPDATE #Dataset
     SET TimePeriod = '2017-18'
   WHERE YearMonth BETWEEN 201708 AND 201807

  UPDATE #Dataset
     SET TimePeriod = '2018-19'
   WHERE YearMonth BETWEEN 201808 AND 201907

  UPDATE #Dataset
     SET TimePeriod = '2019-20'
   WHERE YearMonth BETWEEN 201908 AND 202007

  UPDATE #Dataset
     SET TimePeriod = '2020-21'
   WHERE YearMonth BETWEEN 202008 AND 202107

  UPDATE #Dataset
     SET TimePeriod = '2021-22'
   WHERE YearMonth BETWEEN 202108 AND 202207

  UPDATE #Dataset
     SET TimePeriod = '2022-23'
   WHERE YearMonth BETWEEN 202208 AND 202307

  UPDATE #Dataset
     SET TimePeriod = '2023-24'
   WHERE YearMonth BETWEEN 202308 AND 202407

   select * from #Dataset

  SELECT TimePeriod
        ,SUM(Deaths) as WinterDeaths
	INTO #NumeratorStep1
    FROM #Dataset
   WHERE Winter = 1
   GROUP BY TimePeriod
   

  SELECT TimePeriod
        ,(SUM(Deaths)) / 2 as NonWinterDeaths
	INTO #NumeratorStep2
    FROM #Dataset
   WHERE NonWinter = 1
   GROUP BY TimePeriod


  SELECT T1.TimePeriod
        ,T1.WinterDeaths - T2.NonWinterDeaths as Numerator
	INTO #Numerator
	FROM #NumeratorStep1 T1
   INNER JOIN #NumeratorStep2 T2
      ON T1.TimePeriod = T2.TimePeriod

drop table if exists #NumerDeno
  SELECT 'August ' + left(T1.TimePeriod,4)+'-July 20' + right(T1.TimePeriod,2)	TimePeriod 
		--,T1.TimePeriod
        ,T1.Numerator
		,T2.NonWinterDeaths as Denominator
		--,CONVERT(NUMERIC,T1.Numerator) / CONVERT(NUMERIC,T2.NonWinterDeaths) as Rate
INTO #NumerDeno
	FROM #Numerator T1
   INNER JOIN #NumeratorStep2 T2
      ON T1.TimePeriod = T2.TimePeriod




/*=================================================================================================
 ID 90360 - Excess Winter Death		
=================================================================================================*/
/*
  INSERT INTO [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator] (
		 [IndicatorID]		
        ,[ReferenceID] 
        ,[TimePeriod] 
	    ,[TimePeriodDesc]
        ,[Numerator] 
	    ,[Denominator] 
		,[Indicator_Level]
	    )
		(
  SELECT '16'
		,'90360'
        ,[TimePeriod]
		,'Other'
        ,[Numerator]
        ,[Denominator]
		,'ICB Level'

   FROM  #NumerDeno T1
           )
  
  */



  








  