
/*==================================================================================================================================================================
OUTCOMES FRAMEWORK: QOF
	
	93183	Proportion of eligible adults with a learning disability having a GP health check (%)

==================================================================================================================================================================*/

  DROP TABLE IF EXISTS #LD_Dataset

  SELECT * 
    INTO #LD_Dataset
	FROM (
                  SELECT DISTINCT PRACTICE_CODE
		                ,PRACTICE_NAME
		                ,yyyymm
		                ,DATASET
						,QTY
                    FROM [EAT_Reporting_BSOL].[dbo].[BSOL_0966_LD_NHSD_SUMMARY_2223]
                 ) Pivot_Test



 PIVOT (
         SUM(QTY)
         FOR DATASET
          IN ([01 - PRACTICE LD HEALTHCHECKS 14+]
             ,[02 - PRACTICE LD REG 14+]
              )
         ) AS PivotTable


   UNION ALL        
    
  SELECT * 
	FROM (
                  SELECT DISTINCT PRACTICE_CODE
		                ,PRACTICE_NAME
		                ,yyyymm
		                ,DATASET
						,QTY
                    FROM [EAT_Reporting_BSOL].[dbo].[BSOL_0966_LD_NHSD_SUMMARY_2324]
                 ) Pivot_Test

 PIVOT (
         SUM(QTY)
         FOR DATASET
          IN ([01 - PRACTICE LD HEALTHCHECKS 14+]
             ,[02 - PRACTICE LD REG 14+]
              )
         ) AS PivotTable


   UNION ALL        
    
  SELECT * 
	FROM (
                  SELECT DISTINCT PRACTICE_CODE
		                ,PRACTICE_NAME
		                ,yyyymm
		                ,DATASET
						,QTY
                    FROM [EAT_Reporting_BSOL].[dbo].[BSOL_0966_LD_NHSD_SUMMARY_2425]
                 ) Pivot_Test

 PIVOT (
         SUM(QTY)
         FOR DATASET
          IN ([01 - PRACTICE LD HEALTHCHECKS 14+]
             ,[02 - PRACTICE LD REG 14+]
              )
         ) AS PivotTable
 

/*=================================================================================================
  Insert into static table			
=================================================================================================*/   

  ALTER TABLE #LD_Dataset
    ADD PCN VARCHAR(75)
	   ,Locality_Reg VARCHAR(20)
	   

  UPDATE #LD_Dataset
     SET PCN = T2.PCN
	    ,Locality_Reg = T2.Locality
	FROM #LD_Dataset T1
   INNER JOIN EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T2
      ON T1.PRACTICE_CODE = T2.GPPracticeCode_Original
   WHERE T2.ICS_2223 = 'BSOL'
	   





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
  SELECT  '85'
         ,'93183'
         ,YYYYMM
		 ,'Month'
         ,PRACTICE_CODE
		 ,PCN
		 ,Locality_Reg
         ,[01 - PRACTICE LD HEALTHCHECKS 14+]
		 ,[02 - PRACTICE LD REG 14+]
		 ,'Practice Level'
		 ,NULL
		 ,NULL
		 ,NULL
    FROM #LD_Dataset
      )


