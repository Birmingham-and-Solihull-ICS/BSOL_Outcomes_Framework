-- Indicator 68 % eligible people supported through the NHS Diabetes prevention Programme

--numerator 
--sum of measure = Offered and not declined

--denominator
--sum of  measure = Non-Diabetic Hyperglycaemia

--indicator 
--numerator/denominator * 100

--source 
--https://digital.nhs.uk/data-and-information/publications/statistical/national-diabetes-audit-ndh-dpp

-- Data is available quarterly but reporting annually in first instance due to missing last 2 years of data

DROP TABLE IF EXISTS    #num;

  select Gp_Practices
       , measure_category
       , measure
       , effective_snapshot_date
       , measure_value as numerator into #num
    from [FD_USERDB].[central_midlands_csu_UserDB].[Nat_Diabetes].[DPP_Non_Diabetic_Hyperglycaemia]
   where measure = 'Offered and not declined'

DROP TABLE IF EXISTS    #denom;

  select Gp_Practices
       , measure_category
       , measure 
       , effective_snapshot_date
       , measure_value as denominator into #denom
    from [FD_USERDB].[central_midlands_csu_UserDB].[Nat_Diabetes].[DPP_Non_Diabetic_Hyperglycaemia]
   where measure = 'Non-Diabetic Hyperglycaemia'


  select 
         68 as IndicatorID
       , 'CV2' as ReferenceID
       , year(d.effective_snapshot_date) as Timeperiod
       , 'Other' as TimePeriodDesc
       , d.Gp_Practices as GP_Practice
       , [PCN] as PCN
       , [Locality] as Locality_Reg
       , round(Denominator,1) as Denominator
       , round(Numerator,1) as Numerator
       , 'Practice Level' as Indicator_Level
	into #CV2_Dataset
    from #denom d
    left join (select Gp_Practices, effective_snapshot_date, numerator
			     from #num) n
      on n.gp_practices = d.gp_practices 
	  and n.effective_snapshot_date = d.effective_snapshot_date
    inner join (SELECT [GPPracticeCode_Original]
                      ,[Merge_Flag]
                      ,[GPPracticeCode_Current]
	                  ,[PCN]
                      ,[PCN code]
					  ,[Locality]
                      ,[Is_Current_Practice]
                  FROM [EAT_Reporting_BSOL].[Reference].[BSOL_ICS_PracticeMapped]
				  WHERE ICS_2223 = 'BSOL') p
                    ON (p.GPPracticeCode_Original COLLATE DATABASE_DEFAULT = d.Gp_Practices COLLATE DATABASE_DEFAULT )
  Where month(d.effective_snapshot_date) = 12



  INSERT INTO [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator] (
         IndicatorID
		,ReferenceID
		,TimePeriod
		,TimePeriodDesc
		,GP_Practice
		,PCN
		,Locality_Reg
		,Denominator
		,Numerator
		,Indicator_Level
		)
		(
  SELECT IndicatorID
		,ReferenceID
		,TimePeriod
		,TimePeriodDesc
		,GP_Practice
		,PCN
		,Locality_Reg
		,Denominator
		,Numerator
		,Indicator_Level
	FROM #CV2_Dataset
	     )