---------------------------------------------
-- IndicatorID 43 - Percentage of physically inactive adults
---------------------------------------------

-- ANALYST: Chris Mainey
-- DATE: 2024.08.29



/*
Data extracted for Birmingham and Solihull LAs from Fingertips and inserted into database as: [EAT_Reporting_BSOL].[OF].[43_inactivity]
This script is the linking and inserting into final table.

*/

  
INSERT INTO [OF].[IndicatorValue]
           ([IndicatorID]
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
           ,[IndicatorEndDate])

  Select '43' as [IndicatorID]
  , getdate() as InsertDate
  , NULL as Numerator
  , Denominator as Denominator
  , [Value] as [IndicatorValue]
  , [Lower CI 95#0 limit] as LowerCI95
  , [Upper CI 95#0 limit] as UpperCI95
  , b.AggregationID as AggregationID
  , (select DemographicID from [OF].Demographic 	Where AgeGrp = '19+ yrs' and Gender = 'Persons' and Ethnicity is NULL and IMD is NULL) as [DemographicID]
  , 1 as DataQualityID
  , convert(datetime, substring([Time period],1,4)+'0401',112) as  IndicatorStartDate
  ,  convert(datetime, convert(char(4),convert(int,(substring([Time period],1,4)))+1)+'0331',112) as IndicatorEndDate
    FROM [EAT_Reporting_BSOL].[OF].[43_inactivity] a
	left join (select * from [OF].Aggregation where AggregationType = 'Local Authority') b on a.AreaName = b.AggregationLabel
