-- get the data from IndicatorData table for r script
--Indicator ID=49
--Reference ID=93229

---Extraction of the data-used in r script
  --select IndicatorID, ReferenceID
  --,Trim(' ' from Ethnicity_Code) as Ethnicity_Code
  --,LSOA_2021
  --,Age
  --,Financial_Year
  --,sum(Numerator) as Numerator
  --into #Group1
  --from [EAT_Reporting_BSOL].[OF].IndicatorData
  --where indicatorID=49
  --Group by IndicatorID
  --,ReferenceID
  --,Ethnicity_Code,LSOA_2021,
  --Age,
  --Financial_Year
  --select * from #Group1

 
  --demographic ID table
--SELECT  *
  --FROM [EAT_Reporting_BSOL].[OF].[Demographic]
  --order by DemographicLabel


-- Area type aggregation ID
--select  * from EAT_Reporting_BSOL.[OF].[Aggregation]



/****************************************STANDARDISED RATES***********************************************************/
-- run this script to organise the columns similar to indicator value table and get the Agg ID and demographic ID
--for standardised rates
drop table if exists #sr
select sr.IndicatorID
		,sr.InsertDate
		,sr.Numerator
		,sr.Denominator
		,sr.IndicatorValue
		,sr.LowerCI95 
		,sr.UpperCI95
		,ag.AggregationID
		,d.DemographicID
		,sr.DataQualityID
		,sr.IndicatorStartDate
		,sr.IndicatorEndDate
		--,sr.IMD,sr.EthnicityCode,sr.Gender
		--,d.IMD, d.Ethnicity
		--,ag.AggregationLabel, ag.AggregationType,ag.AggregationCode
		--,sr.AggregationLabel,sr.AggregationType
		--,sr.AgeGroup,d.AgeGrp
into #sr
from  Working.dbo.BSOL_0033_OF_Age_Standardised_Rates sr --Working.[dbo].[BSOL_0033_OF_93229_CHD_StandardisedRate] sr
left join EAT_Reporting_BSOL.[OF].[Aggregation] ag on (sr.AggregationLabel=ag.AggregationLabel and sr.AggregationType=ag.AggregationType ) or  (sr.AggregationLabel=ag.AggregationCode and sr.AggregationType=ag.AggregationType )
left join [EAT_Reporting_BSOL].[OF].[Demographic] d on ((sr.IMD=d.IMD) or (sr.IMD is null and d.IMD is null))--	and not (sr.IMD is not null and d.IMD is null)	and not (sr.IMD is null and d.IMD is not null))
													and ((sr.EthnicityCode=d.Ethnicity) or (sr.EthnicityCode is null and d.Ethnicity is null))-- and not (sr.Ethnicity is not null and d.Ethnicity is null)	and not (sr.Ethnicity is null and d.Ethnicity is not null))
													and sr.Gender=d.Gender
													and d.AgeGrp=sr.AgeGroup


--select count(*) from Working.dbo.BSOL_0033_OF_Age_Standardised_Rates  --318200

--select count(*) from #sr



drop table  EAT_Reporting_BSOL.[OF].[BSOL_0033_OF_sr]
select * 
into EAT_Reporting_BSOL.[OF].[BSOL_0033_OF_sr]
from #sr

select distinct IndicatorID from  EAT_Reporting_BSOL.[OF].[BSOL_0033_OF_sr]
order by IndicatorID

/**********************************************************************************************************/



/*********************************************CRUDE RATES*******************************************************/
-- run this script to organise the columns similar to indicator value table and get the Agg ID and demographic ID
--for crude rates
drop table if exists #cr
select distinct 
		cr.IndicatorID
		,cr.InsertDate
		,cr.Numerator as Numerator
		,cr.Denominator as Denominator
		,cr.IndicatorValue
		,cr.LowerCI95 
		,cr.UpperCI95
		,ag.AggregationID
		,d.DemographicID
		,cr.DataQualityID
		,cr.IndicatorStartDate
		,cr.IndicatorEndDate
		--,cr.IMD,cr.EthnicityCode,cr.Gender
		--,d.IMD, d.Ethnicity
		--,ag.AggregationLabel, ag.AggregationType,ag.AggregationCode
		--,cr.AggregationLabel,cr.AggregationType
		--,cr.AgeGroup,d.AgeGrp
into #cr
from  Working.[dbo].[BSOL_0033_OF_Crude_Rates] cr  -- dbo.BSOL_0033_OF_Crude_Rates
left join EAT_Reporting_BSOL.[OF].[Aggregation] ag on (cr.AggregationLabel=ag.AggregationLabel and cr.AggregationType=ag.AggregationType ) or  (cr.AggregationLabel=ag.AggregationCode and cr.AggregationType=ag.AggregationType )
left join [EAT_Reporting_BSOL].[OF].[Demographic] d on ((cr.IMD=d.IMD) or (cr.IMD is null and d.IMD is null))
													and ((cr.EthnicityCode=d.Ethnicity) or (cr.EthnicityCode is null and d.Ethnicity is null))
													and cr.Gender=d.Gender
													and cr.AgeGroup=d.AgeGrp


--where AggregationID is null
--order by AggregationID

--select count(*) from Working.[dbo].[BSOL_0033_OF_Crude_Rates]  --251340

--select count(*) from #cr

drop table if exists EAT_Reporting_BSOL.[OF].[BSOL_0033_OF_cr]
select * 
into EAT_Reporting_BSOL.[OF].[BSOL_0033_OF_cr]
from #cr

--select distinct IndicatorID from EAT_Reporting_BSOL.[OF].[BSOL_0033_OF_cr]
--order by IndicatorID


--select distinct (AgeGrp)  from [EAT_Reporting_BSOL].[OF].[Demographic]
--order by AgeGrp

/**********************************************************************************************************/



/*********************************************CRUDE RATES Pre-defined denominator*******************************************************/
-- run this script to organise the columns similar to indicator value table and get the Agg ID and demographic ID
--for crude rates
drop table if exists #cr_denom
select distinct 
		cr.IndicatorID
		,cr.InsertDate
		,cr.Numerator as Numerator
		,cr.Denominator as Denominator
		,cr.IndicatorValue
		,cr.LowerCI95 
		,cr.UpperCI95
		,ag.AggregationID
		,d.DemographicID
		,cr.DataQualityID
		,cr.IndicatorStartDate
		,cr.IndicatorEndDate
		--,cr.IMD,cr.EthnicityCode,cr.Gender
		--,d.IMD, d.Ethnicity
		--,ag.AggregationLabel, ag.AggregationType,ag.AggregationCode
		--,cr.AggregationLabel,cr.AggregationType
		--,cr.AgeGroup,d.AgeGrp
into #cr_denom
from  Working.[dbo].[BSOL_0033_OF_Crude_Rates_Predefined_Denominators] cr  -- dbo.BSOL_0033_OF_Crude_Rates
left join EAT_Reporting_BSOL.[OF].[Aggregation] ag on (cr.AggregationLabel=ag.AggregationLabel and cr.AggregationType=ag.AggregationType ) or  (cr.AggregationLabel=ag.AggregationCode and cr.AggregationType=ag.AggregationType )
left join [EAT_Reporting_BSOL].[OF].[Demographic] d on ((cr.IMD=d.IMD) or (cr.IMD is null and d.IMD is null))
													and ((cr.EthnicityCode=d.Ethnicity) or (cr.EthnicityCode is null and d.Ethnicity is null))
													and cr.Gender=d.Gender
													and cr.AgeGroup=d.AgeGrp
--where IndicatorID=20
--where --ethnicityCode is not null
-- AgeGroup='5-17 yrs'

--select count(*) from Working.[dbo].[BSOL_0033_OF_Crude_Rates_Predefined_Denominators]  --32076

--select count(*) from #cr_denom


--select distinct IndicatorID
--from #cr_denom
--where DemographicID is null
--order by IndicatorID

drop table if exists  EAT_Reporting_BSOL.[OF].[BSOL_0033_OF_cr_denom]
select * 
into EAT_Reporting_BSOL.[OF].[BSOL_0033_OF_cr_denom]
from #cr_denom

--select * 
-- from EAT_Reporting_BSOL.[OF].[BSOL_0033_OF_cr_denom]
-- where IndicatorID=16
--select distinct IndicatorID
--from  EAT_Reporting_BSOL.[OF].[BSOL_0033_OF_cr_denom]
--order by IndicatorID


--select * from 
--[EAT_Reporting_BSOL].[OF].[Demographic]
--where AgeGrp='50-70 yrs'

--drop table if exists EAT_Reporting_BSOL.[OF].[BSOL_0033_OF_22401_Falls_CrudeRate]
--select * 
--into EAT_Reporting_BSOL.[OF].[BSOL_0033_OF_CrudeRate]
--from [Working].[dbo].[BSOL_0033_Falls_Resp_dataset]

 -- select distinct IndicatorID
 --from  EAT_Reporting_BSOL.[OF].[BSOL_0033_OF_22401_Falls_CrudeRate]
 --order by AggregationType,IndicatorStartDate,IMD, EthnicityCode
 --where AggregationType<>'Ward'
 -- where IMD is not null and EthnicityCode is not null


 -- select * from EAT_Reporting_BSOL.[OF].[IndicatorValue]
---populating the IndicatorValue table

--select * from EAT_Reporting_BSOL.[OF].[BSOL_0033_OF_cr] (IndicatorID
--		,InsertDate
--		, Numerator
--		,Denominator
--		,IndicatorValue
--		,LowerCI95 
--		,UpperCI95
--		,AggregationID
--		,DemographicID
--		,DataQualityID
--		,IndicatorStartDate
--		,IndicatorEndDate)

--insert into EAT_Reporting_BSOL.[OF].[IndicatorValue] (IndicatorID
--		,InsertDate
--		, Numerator
--		,Denominator
--		,IndicatorValue
--		,LowerCI95 
--		,UpperCI95
--		,AggregationID
--		,DemographicID
--		,DataQualityID
--		,IndicatorStartDate
--		,IndicatorEndDate)
--select  * from EAT_Reporting_BSOL.[OF].[BSOL_0033_OF_sr]

--select top 10 * from EAT_Reporting_BSOL.[OF].[IndicatorValue] 

--select top 100 * from EAT_Reporting_BSOL.[OF].[IndicatorValue] 

--select distinct(IndicatorID) from EAT_Reporting_BSOL.[OF].[BSOL_0033_OF_cr]


--select *
--,DateDiff(year, IndicatorStartDate,IndicatorEndDate) ReportingFrequecy_y
-- from EAT_Reporting_BSOL.[OF].[BSOL_0033_OF_cr]   
-- where DateDiff(year, IndicatorStartDate,IndicatorEndDate)=1

-- select* from  EAT_Reporting_BSOL.[OF].[BSOL_0033_OF_sr]   


-----------------------------------------------------------------
	
--  select IndicatorID, ReferenceID
--  ,Trim(' ' from Ethnicity_Code) as Ethnicity_Code
--  ,LSOA_2021
--  ,Age
--  ,Financial_Year
--  ,sum(Numerator) as Numerator
--  into #Group1
--  from [EAT_Reporting_BSOL].[OF].IndicatorData
--  where indicatorID=49
--  Group by IndicatorID
--  ,ReferenceID
--  ,Ethnicity_Code,LSOA_2021,
--  Age,
--  Financial_Year
--  select * from #Group1

--  select Financial_Year,LSOA_2021,sum(Numerator) 

--  from #Group1
--  group by Financial_Year,LSOA_2021 
--  order by Financial_Year,LSOA_2021
 
-- drop table #Group2
--    select  count(*) as Numerator
--		,null Denominator
-- 		,g.EthnicCategoryCode
-- 		,g.LowerLayerSuperOutputArea
-- 		,AgeOnAdmission
-- 		, CASE WHEN DatePart(Month, AdmissionDate) >= 4
--             THEN concat(DatePart(Year, AdmissionDate), '/', DatePart(Year, AdmissionDate) + 1)
--             ELSE concat(DatePart(Year, AdmissionDate) - 1, '/', DatePart(Year, AdmissionDate) )
--        END AS Fiscal_Year
-- into #Group2
-- from [SUS].[VwInpatientEpisodesPatientGeography] g
--inner join [EAT_Reporting].[dbo].[tbIpDiagnosisRelational] d  on g.EpisodeId=d.EpisodeId
-- --inner join EAT_Reporting.dbo.tbInpatientEpisodes e on d.EpisodeId=e.EpisodeId
-- inner join [EAT_Reporting_BSOL].[Development].[BSOL_1252_SUS_LTC_ICD10] i on i.ICD10_Code=d.DiagnosisCode  --has the different ICD10 codes for most LTCs
-- where LTC_Condition='CHD' --the diagnoses
-- and g.OrderInSpell='1'
-- --and ReconcilliationPoint between  '201901' and '202403'
-- --and ReconcilliataionPoint between '202101' and '202403'
-- and left(admissionmethodcode,1)='2' --emergency admissions
-- and NHSNumber is not null
--   and (OSLAUA = 'E08000025' or OSLAUA = 'E08000029')
--   and DiagnosisOrder=1
--   group by EthnicCategoryCode
-- 		,LowerLayerSuperOutputArea
-- 		,AgeOnAdmission
-- 		, CASE WHEN DatePart(Month, AdmissionDate) >= 4
--             THEN concat(DatePart(Year, AdmissionDate), '/', DatePart(Year, AdmissionDate) + 1)
--             ELSE concat(DatePart(Year, AdmissionDate) - 1, '/', DatePart(Year, AdmissionDate) )
--        END


--  select Fiscal_Year,LowerLayerSuperOutputArea,sum(Numerator) 

--  from #Group2
--  group by Fiscal_Year,LowerLayerSuperOutputArea 
--  order by Fiscal_Year,LowerLayerSuperOutputArea


--    select Financial_Year,LSOA_2021,sum(Numerator) 

--  from #Group1
--  group by Financial_Year,LSOA_2021 
--  order by Financial_Year,LSOA_2021

--SELECT	distinct IndicatorID
 
--FROM	[EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]
--where	GP_Practice ='M88006'
--order by IndicatorID

--SELECT top 1000 * --	Distinct IndicatorID
--FROM	[EAT_Reporting_BSOL].[OF].[IndicatorData]
--WHERE	GP_Practice ='M88006'
--Order by IndicatorID

