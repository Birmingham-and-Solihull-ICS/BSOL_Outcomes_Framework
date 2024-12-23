
/*=================================================================================================
 IndicatorID 53 -ReferenceID  93454 - Smoking Long term mental health			
=================================================================================================*/

--select * 
--into EAT_Reporting_BSOL.[OF].[BSOL_0033_OF_93454_SmokingLongTermMentalHealth]
--from Working.[dbo].[BSOL_0033_OF_93454_SmokingLongTermMentalHealth]

drop table if exists  #Dataset
select distinct    null					as IndicatorID
		,'93454'				as ReferenceID
		,GETDATE ()				as InsertDate
        ,i.[Time period]		as TimePeriod  --fiscal years
		,null					as Numerator	--Numerator does not exist
		,Denominator 
		,Value					as IndicatorValue
		,[Lower CI 95.0 limit]  as LowerCI95
		,[Upper CI 95.0 limit]  as UpperCI95
		,a.AggregationID
		--,[Area Code]
		,d.DemographicID
		--,d.*
		,1						as DataQualityID 
		,da.HCSStartOfYearDate  as IndicatorStartDate
		,da.HCSEndOfYearDate	as IndicatorEndDate
into #Dataset
from Working.[dbo].[BSOL_0033_OF_93454_SmokingLongTermMentalHealth] i
left join EAT_Reporting_BSOL.[OF].[Aggregation] a on i.[Area Code]=a.AggregationCode
left join EAT_Reporting_BSOL.[OF].[Demographic] d on i.Age=d.AgeGrp and d.Ethnicity is null and d.IMD is null and d.Gender='Persons'
inner join Reference.dbo.DIM_tbDate da on left(i.[Time Period],4)=da.HCSFinancialYearId
where Age='18+ yrs' and Sex ='Persons' and [Area Type]='UA'
and ([Area Name] like '%Birmingham%' or [Area Name] like '%Solihull%')



UPDATE #Dataset
     SET IndicatorID = T2.IndicatorID
	FROM #Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[OF].[IndicatorList] T2
      ON T1.ReferenceID = T2.ReferenceID

--SELECT top 1000 * FROM EAT_Reporting_BSOL.[OF].IndicatorValue
--select * from #Dataset
  
/*=================================================================================================
IndicatorID 53 -ReferenceID  93454 - Smoking Long term mental health			
=================================================================================================*/
/*
  INSERT INTO EAT_Reporting_BSOL.[OF].IndicatorValue (
		 [IndicatorID]		
        ,[InsertDate] 
        ,[Numerator] 
	    ,[Denominator] 
		,[IndicatorValue]
		,[LowerCI95]
		,[UpperCI95]
		,[AggregationID]
		,[DemographicID]
		,[DataQualityID]
		,[IndicatorStartDate]
		,[IndicatorEndDate]
	    )
		(
  SELECT [IndicatorID]		
        ,[InsertDate] 
        ,[Numerator] 
	    ,[Denominator] 
		,[IndicatorValue]
		,[LowerCI95]
		,[UpperCI95]
		,[AggregationID]
		,[DemographicID]
		,[DataQualityID]
		,[IndicatorStartDate]
		,[IndicatorEndDate]
   FROM  #Dataset T1
           )
  
  */



  








  