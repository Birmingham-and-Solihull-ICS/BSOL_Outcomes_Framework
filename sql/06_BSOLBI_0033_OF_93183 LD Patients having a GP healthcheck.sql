
/*==================================================================================================================================================================
OUTCOMES FRAMEWORK: QOF
	
	93183	Proportion of eligible adults with a learning disability having a GP health check (%)

==================================================================================================================================================================*/


  SELECT * 
    INTO #LD_Dataset
	FROM (
                  SELECT PRACTICE_CODE
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
                  SELECT PRACTICE_CODE
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
                  SELECT PRACTICE_CODE
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
             ,[01 - PRACTICE LD HEALTHCHECKS 14+]
              )
         ) AS PivotTable
 

/*=================================================================================================
  Insert into static table			
=================================================================================================*/   

 INSERT INTO [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator] (
       [IndicatorID] 
      ,[TimePeriod] 
      ,[GP_Practice] 
      ,[Numerator] 
	  ,[Denominator] 
	  )
	  (
  SELECT '93183'
         ,YYYYMM
         ,PRACTICE_CODE
         ,[01 - PRACTICE LD HEALTHCHECKS 14+]
		 ,[01 - PRACTICE LD HEALTHCHECKS 14+]
    FROM #LD_Dataset
      )