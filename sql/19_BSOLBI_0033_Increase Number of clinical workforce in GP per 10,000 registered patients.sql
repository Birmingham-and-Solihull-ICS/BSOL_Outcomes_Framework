  
  DROP TABLE IF EXISTS #PCN_FTE
                      ,#GP_FTE
					  ,#Numerator
					  ,#Denominator


  SELECT TOP 1000 *
    FROM #PCN_FTE
   ORDER BY 3,1

  SELECT TOP 1000 *
    FROM #GP_FTE
   ORDER BY 3,1

  SELECT YYYYMM
        ,PCNCode
        ,PCNName
        ,SUM(FTE) FTE
	INTO #PCN_FTE
    FROM AnalystGlobal.Performance.PCNWorkforce
   WHERE StaffGroup IN ('Direct Patient Care', 'Other Direct Patient Care', 'Other Direct Patient Care staff')
     AND YYYYMM >= '202301'
   GROUP BY YYYYMM
           ,PCNCode
           ,PCNName

  SELECT YearMonth
        ,PCN_Code
		,PCN
		,SUM(Value) FTE
	INTO #GP_FTE
    FROM EAT_Reporting_BSOL.Development.BSOL_GP_Workforce_v2
   WHERE Metric IN ('TOTAL_GP_EXTG_FTE','TOTAL_NURSES_FTE')
    AND  YearMonth >= '202301'
   GROUP BY YearMonth
        ,PCN_Code
		,PCN
		

  -- Numerator 

  SELECT T1.YYYYMM
        ,T1.PCNCode
		,T1.PCNName
		,T1.FTE as PCN_FTE
		,T2.FTE as GP_FTE
	--	,ISNULL(T1.FTE,0) + ISNULL(T2.FTE,0) FTE
	INTO #Numerator
    FROM #PCN_FTE T1
    LEFT JOIN #GP_FTE T2
	  ON T1.PCNCode = T2.PCN_Code
	 AND T1.YYYYMM = T2.YearMonth


  -- Denominator

  SELECT CONVERT(VARCHAR(6),Effective_SnapShot_Date,112) as YYYYMM
        ,[PCN code]
        ,PCN
		,CONVERT(FLOAT,NULL) as GP_Numerator
		,CONVERT(FLOAT,NULL) as PCN_Numerator
        ,SUM([Total_All]) as List_Size
	INTO #Denominator
    FROM [Reference].[Population].[DIM_tbGPPractice_Patient_Pop_SYOA] T1
   INNER JOIN EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T2
      ON T1.PRACTICE_CODE = T2.GPPracticeCode_Original
   WHERE T2.ICS_2223 = 'BSOL'
   GROUP BY CONVERT(VARCHAR(6),Effective_SnapShot_Date,112) 
           ,[PCN code]
           ,PCN

  UPDATE #Denominator
     SET GP_Numerator = T2.GP_FTE
    FROM #Denominator T1
   INNER JOIN #Numerator T2
      ON T1.[PCN code] = T2.PCNCode
	 AND T1.YYYYMM = T2.YYYYMM

 UPDATE #Denominator
     SET PCN_Numerator = T2.PCN_FTE
    FROM #Denominator T1
   INNER JOIN #Numerator T2
      ON T1.[PCN code] = T2.PCNCode
	 AND T1.YYYYMM = T2.YYYYMM
    
  SELECT *
    FROM #Denominator
   ORDER BY 2,1


/*=================================================================================================
 Derived from FT instead			
=================================================================================================*/

SELECT [Indicator ID]
      ,[Indicator Name]
      ,[Parent Code]
      ,[Parent Name]
      ,[Area Code]
      ,[Area Name]
      ,[Area Type]
      ,[Sex]
      ,[Age]
      ,[Category Type]
      ,[Category]
      ,[Time period]
      ,[Value]
      ,[Lower CI 95.0 limit]
      ,[Upper CI 95.0 limit]
      ,[Lower CI 99.8 limit]
      ,[Upper CI 99.8 limit]
      ,[Count]
      ,[Denominator]
      ,[Value note]
      ,[Recent Trend]
      ,[Compared to England value or percentiles]
      ,[Column not used]
      ,[Time period Sortable]
      ,[New data]
      ,[Compared to goal]
      ,[Time period range]
   INTO [EAT_Reporting_BSOL].[Development].[BSOL_0033_OF_93966_GP_Workforce]
   FROM [Working].[dbo].[BSOL_0033_OF_93966_GP_Workforce] T1
  INNER JOIN EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T2
     ON T1.[Area Code] = T2.[GPPracticeCode_Original]
  WHERE T2.ICS_2223 = 'BSOL'

  /* SELECT TOP 1000 *
     FROM Working.dbo.BSOL_0033_OF_93966_GP_Workforce */


