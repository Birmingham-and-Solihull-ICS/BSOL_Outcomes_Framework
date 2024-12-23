DROP TABLE IF EXISTS ##OF_InfantDeaths

USE EAT_Reporting_BSOL
select 
CONCAT (
		Left([DATE_OF_DEATH], 4)
		,Right([DATE_OF_DEATH], 2)
		) AS [TimePeriod]
	
,Demo.Ethnic_Code as [Ethnicity_Code]
,[LSOA_OF_RESIDENCE_CODE] as [LSOA2011]
,count(*) as Numerator

Into ##OF_InfantDeaths 

from [Other].[VwDeathsRegister] as DeathsReg
left join (select [Pseudo_NHS_Number], [Ethnic_Code],[GP_Code] from 
			[Demographic].[Ethnicity]
			--where Is_Deceased = 1
			) Demo
			on Demo.[Pseudo_NHS_Number] = DeathsReg.[PatientId]

where [DEC_AGECUNIT] != 1
and left([DATE_OF_DEATH],3) like '20[12]'
and [PatientId] is not NULL
group by  
CONCAT (		
		Left([DATE_OF_DEATH], 4)
		,Right([DATE_OF_DEATH], 2)
		) 
,Demo.Ethnic_Code
,[LSOA_OF_RESIDENCE_CODE]


DROP TABLE IF EXISTS ##OF_NeonatalDeaths
select 
CONCAT (
		Left([DATE_OF_DEATH], 4)
		,Right([DATE_OF_DEATH], 2)
		) AS [TimePeriod]
,Demo.Ethnic_Code as [Ethnicity_Code]
,[LSOA_OF_RESIDENCE_CODE] as [LSOA2011]
,count(*) as Numerator

Into ##OF_NeonatalDeaths

from [Other].[VwDeathsRegister]  as DeathsReg
left join (select [Pseudo_NHS_Number], [Ethnic_Code],[GP_Code] from 
			[Demographic].[Ethnicity]
			--where Is_Deceased = 1
			) Demo
			on Demo.[Pseudo_NHS_Number] = DeathsReg.[PatientId]

where [DEC_AGECUNIT] != 1
AND [NEO_NATE_FLAG] = 1
and left([DATE_OF_DEATH],3) like '20[12]'
and [PatientId] is not NULL
group by  
CONCAT (		
		Left([DATE_OF_DEATH], 4)
		,Right([DATE_OF_DEATH], 2)
		) 
,Demo.Ethnic_Code
,[LSOA_OF_RESIDENCE_CODE]


--Live Births for denominator
DROP TABLE IF EXISTS ##OF_LiveBirths

select 
count(*) as Denominator
,CONCAT (
		Left([Partial_Baby_DOB], 4)
		,Right([Partial_Baby_DOB], 2)
		) AS [TimePeriod]
,[LSOA_MOTHER] as [LSOA2011]
,[Ethnic_Code] as [Ethnicity_Code] 

Into ##OF_LiveBirths

from [Other].[vwBirths_Date_Of_Birth_Registration] act
-- imput ethnicity
left join (select [Pseudo_NHS_Number], [Ethnic_Code] from 
			[Demographic].[Ethnicity]
			) d
			on d.[Pseudo_NHS_Number] = act.[Baby_NHSNumber]

where left([Partial_Baby_DOB],3) like '20[12]'
-- check death lab
and Death_lab is null
and CANCELLED_FLAG='N'
group by  
CONCAT (
		Left([Partial_Baby_DOB], 4)
		,Right([Partial_Baby_DOB], 2)
		) 
,[LSOA_MOTHER]
,[Ethnic_Code]


Select * from ##OF_LiveBirths

--/*=================================================================================================
-- 92196 -Infant mortality rate - --Final data for Infant Deaths
--=================================================================================================*/

--INSERT INTO		[EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator] 

--(				[IndicatorID]
--,				[ReferenceID]
--,				[TimePeriod]
--,				[TimePeriodDesc]
----,				[GP_Practice]
----,				[PCN]
----,				[Locality_Reg]
--,				[Numerator]
--,				[Denominator]
--,				[Indicator_Level]
--,				[LSOA_2011]
--,				[LSOA_2021]
--,				[Ethnicity_Code]
--)
DROP TABLE IF EXISTS #22_staging
			SELECT
				22													As [IndicatorID]
,				'92196'												as [ReferenceID]
,				COALESCE(LB.[TimePeriod], ID.[TimePeriod])			as [TimePeriod]
,				'Month'												as TimePeriodDesc
--,				NULL												as GP_Code
--,				NULL												as PCN
--,				NULL												as Locality_Reg
,				ID.[Numerator]										as [Numerator]
,				LB.[Denominator]									as [Denominator]
,				'Ward Level'										as IndicatorLevel
,				COALESCE(LB.[LSOA2011], ID.[LSOA2011])				as LSOA2011
				--Sloppy bodge; if counts in numerator but no counts in denominator (likely DQ issue anyway), no LSOA 2021 will map- so just use 2011 as minimal change. ? fix with cross apply?
,				COALESCE(LSOA2011to2022.[LSOA11CD],ID.[LSOA2011])	AS LSOA2021
,				eth.ONSGroup								        as [Ethnicity]
,				wd.WD22CD											as ward_code -- added by CM
,				wd.WD22NM											as ward_name
,				wd.LAD22CD											as LA_code
,				wd.LAD22NM											as LA_name
,				lk.Locality											as Locality -- added by CM


into #22_staging
FROM		##OF_LiveBirths as LB
--Full outer join here as possible to have 0 births and >=1 death in LSOA/ethicity group in 1 year, due to the way this indicator is calculated
full outer join ##OF_InfantDeaths AS ID
on				LB.[LSOA2011]=ID.[LSOA2011]
AND				LB.[TimePeriod]=ID.[TimePeriod]
AND				LB.[Ethnicity_Code]=ID.[Ethnicity_Code] 

LEFT JOIN		[EAT_Reporting_BSOL].[Reference].[LSOA_2011_to_LSOA_2021] LSOA2011to2022 
				ON LB.LSOA2011 = LSOA2011to2022.[LSOA11CD]
--20240927 change from join on LAD to on LSOA21
left join      [EAT_Reporting_BSOL].[Reference].[LSOA_2021_WARD_LAD] wd
			   ON wd.LSOA21CD = LSOA2011to2022.LSOA21CD

left join	   [EAT_Reporting_BSOL].[Reference].[LSOA_2021_BSOL_to_Constituency_2025_Locality] lk
				on wd.LSOA21CD = lk.LSOA21CD

left join      [OF].[lkp_ethnic_categories] eth
				on case when LB.[Ethnicity_Code] is null THEN  'Z' ELSE LB.[Ethnicity_Code] END = eth.NHSCode


--ORDER BY		TimePeriod, Ethnicity_Code 


-- 1 YR
DROP TABLE IF EXISTS #22_working
Select 
		sum(Numerator) as Numerator,
		sum(Denominator) as Denominator,
		dtt.FinYear,
		a.ward_code as agregation_code,
		a.Ethnicity,
		'<1 yr (including <28 days)' as AgeGrp

into #22_working
FROM 
		(Select * 
		, convert(datetime, TimePeriod + '01', 112) AS dt
		from #22_staging) a
		inner join reference.[dbo].[DIM_tbDate] dtt ON a.dt = dtt.[Date]
Where	a.Locality is not null
group by dtt.FinYear,
		a.ward_code,
		a.Ethnicity

UNION ALL 
-- Locality
Select 
		sum(Numerator) as Numerator,
		sum(Denominator) as Denominator,
		dtt.FinYear,
		lcl.AggregationCode as Locality,
		a.Ethnicity,
		'<1 yr (including <28 days)' as AgeGrp
FROM 
		(Select * 
		, convert(datetime, TimePeriod + '01', 112) AS dt
		from #22_staging) a
		inner join reference.[dbo].[DIM_tbDate] dtt ON a.dt = dtt.[Date]
		inner join (Select * FROM [OF].[Aggregation] Where AggregationType = 'Locality (resident)') lcl ON a.Locality = lcl.AggregationLabel
Where	a.Locality is not null
group by dtt.FinYear,
		lcl.AggregationCode,
		a.Ethnicity
UNION ALL 
-- LA
Select 
		sum(Numerator) as Numerator,
		sum(Denominator) as Denominator,
		dtt.FinYear,
		a.LA_code,
		a.Ethnicity,
		'<1 yr (including <28 days)' as AgeGrp
FROM 
		(Select * 
		, convert(datetime, TimePeriod + '01', 112) AS dt
		from #22_staging) a
		inner join reference.[dbo].[DIM_tbDate] dtt ON a.dt = dtt.[Date]
Where	a.Locality is not null
group by dtt.FinYear,
		a.LA_code,
		a.Ethnicity
UNION ALL 
-- BSOL
Select 
		sum(Numerator) as Numerator,
		sum(Denominator) as Denominator,
		dtt.FinYear,
		'E38000258',
		a.Ethnicity,
		'<1 yr (including <28 days)' as AgeGrp

FROM 
		(Select * 
		, convert(datetime, TimePeriod + '01', 112) AS dt
		from #22_staging) a
		inner join reference.[dbo].[DIM_tbDate] dtt ON a.dt = dtt.[Date]

Where	a.Locality is not null
group by dtt.FinYear,
		--a.ward_code,
		a.Ethnicity		

-- Repeat without ethnicity groups
Insert into #22_working

Select 
		sum(Numerator) as Numerator,
		sum(Denominator) as Denominator,
		dtt.FinYear,
		a.ward_code as agregation_code,
		NULL as Ethnicity,
		'<1 yr (including <28 days)' as AgeGrp

--into #22_working
FROM 
		(Select * 
		, convert(datetime, TimePeriod + '01', 112) AS dt
		from #22_staging) a
		inner join reference.[dbo].[DIM_tbDate] dtt ON a.dt = dtt.[Date]
Where	a.Locality is not null
group by dtt.FinYear,
		a.ward_code
		--a.Ethnicity

UNION ALL 
-- Locality
Select 
		sum(Numerator) as Numerator,
		sum(Denominator) as Denominator,
		dtt.FinYear,
		lcl.AggregationCode as Locality,
		NULL as Ethnicity,
		'<1 yr (including <28 days)' as AgeGrp
FROM 
		(Select * 
		, convert(datetime, TimePeriod + '01', 112) AS dt
		from #22_staging) a
		inner join reference.[dbo].[DIM_tbDate] dtt ON a.dt = dtt.[Date]
		inner join (Select * FROM [OF].[Aggregation] Where AggregationType = 'Locality (resident)') lcl ON a.Locality = lcl.AggregationLabel
Where	a.Locality is not null
group by dtt.FinYear,
		lcl.AggregationCode
		--1a.Ethnicity
UNION ALL 
-- LA
Select 
		sum(Numerator) as Numerator,
		sum(Denominator) as Denominator,
		dtt.FinYear,
		a.LA_code,
		NULL as Ethnicity,
		'<1 yr (including <28 days)' as AgeGrp
FROM 
		(Select * 
		, convert(datetime, TimePeriod + '01', 112) AS dt
		from #22_staging) a
		inner join reference.[dbo].[DIM_tbDate] dtt ON a.dt = dtt.[Date]
Where	a.Locality is not null
group by dtt.FinYear,
		a.LA_code
		--a.Ethnicity
UNION ALL 
-- BSOL
Select 
		sum(Numerator) as Numerator,
		sum(Denominator) as Denominator,
		dtt.FinYear,
		'E38000258',
		NULL as Ethnicity,
		'<1 yr (including <28 days)' as AgeGrp
FROM 
		(Select * 
		, convert(datetime, TimePeriod + '01', 112) AS dt
		from #22_staging) a
		inner join reference.[dbo].[DIM_tbDate] dtt ON a.dt = dtt.[Date]

Where	a.Locality is not null
group by dtt.FinYear
		--a.ward_code,
		--a.Ethnicity		


Delete from [OF].[IndicatorValue]
Where IndicatorID = 22

-- Wrap into output format
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
Select 22 as IndicatorID
, getdate()
, coalesce(Numerator,0) as Numerator
, case when coalesce(Denominator,0) = 0 THEN 1 ELSE Denominator END as Denominator
, 1000 * (cast(coalesce(Numerator,0) as float) / cast((case when coalesce(Denominator,0) = 0 THEN 1 ELSE Denominator END)as float)) as IndicatorValue
, 1000 * ([OF].byars_lower_95(Numerator) / cast(denominator as float)) as LowerCI95
, 1000 * ([OF].byars_upper_95(Numerator) / cast(denominator as float)) as UpperCI95
, b.AggregationID
, c.DemographicID
, 1 as DataQualityID
, convert(datetime, CONCAT('20', substring(FinYear,1,2), '0401'), 112) as IndicatorStartDate
, convert(datetime, CONCAT('20', substring(FinYear,3,2), '0331'), 112) as IndicatorEndDate
--, FinYear

from #22_working a
left join  [OF].Aggregation b on a.agregation_code = b.AggregationCode
left join  [OF].Demographic c on a.Ethnicity = c.Ethnicity and a.AgeGrp = c.AgeGrp and c.IMD is NULL and c.Gender = 'Persons'
WHERE a.Ethnicity is not null

UNION ALL 

Select 22 as IndicatorID
, getdate()
, coalesce(Numerator,0) as Numerator
, case when coalesce(Denominator,0) = 0 THEN 1 ELSE Denominator END as Denominator
, 1000 * (cast(coalesce(Numerator,0) as float) / cast((case when coalesce(Denominator,0) = 0 THEN 1 ELSE Denominator END)as float)) as IndicatorValue
, 1000 * ([OF].byars_lower_95(Numerator) / cast(denominator as float)) as LowerCI95
, 1000 * ([OF].byars_upper_95(Numerator) / cast(denominator as float)) as UpperCI95
, b.AggregationID
, c.DemographicID
, 1 as DataQualityID
, convert(datetime, CONCAT('20', substring(FinYear,1,2), '0401'), 112) as IndicatorStartDate
, convert(datetime, CONCAT('20', substring(FinYear,3,2), '0331'), 112) as IndicatorEndDate
--, FinYear

from #22_working a
left join  [OF].Aggregation b on a.agregation_code = b.AggregationCode
left join  [OF].Demographic c on c.Ethnicity is NULL and a.AgeGrp = c.AgeGrp and c.IMD is NULL and c.Gender = 'Persons'
WHERE a.Ethnicity is null







--/*=================================================================================================
-- 92705 - Neonatal mortality rate --Final Data for Neonatal Deaths
--=================================================================================================*/

--INSERT INTO		[EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator] 

--(				[IndicatorID]
--,				[ReferenceID]
--,				[TimePeriod]
--,				[TimePeriodDesc]
----,				[GP_Practice]
----,				[PCN]
----,				[Locality_Reg]
--,				[Numerator]
--,				[Denominator]
--,				[Indicator_Level]
--,				[LSOA_2011]
--,				[LSOA_2021]
--,				[Ethnicity_Code]
--)

--(
SELECT			33													As [IndicatorID]
,				'92705'												as [ReferenceID]
,				COALESCE(LB.[TimePeriod], ND.[TimePeriod])			as [TimePeriod]
,				'Month'												as TimePeriodDesc
--,				NULL												as GP_Code
--,				NULL												as PCN
--,				NULL												as Locality_Reg
,				ND.[Numerator]										as [Numerator]
,				LB.[Denominator]									as [Denominator]
,				'Ward Level'										as IndicatorLevel
,				COALESCE(LB.[LSOA2011], ND.[LSOA2011])				as LSOA2011
--Sloppy bodge; if counts in numerator but no counts in denominator (likely DQ issue anyway), no LSOA 2021 will map- so just use 2011 as minimal change. ? fix with cross apply?
,				COALESCE(LSOA2011to2022.[LSOA11CD],ND.[LSOA2011])	AS LSOA2021
--,				COALESCE(LB.[Ethnicity_Code], ND.[Ethnicity_Code])	as [Ethnicity_Code]
,				eth.ONSGroup								        as [Ethnicity]
,				wd.WD22CD											as ward_code -- added by CM
,				wd.WD22NM											as ward_name
,				wd.LAD22CD											as LA_code
,				wd.LAD22NM											as LA_name
,				lk.Locality											as Locality -- added by CM
into #33_staging
FROM			##OF_LiveBirths as LB
--Full outer join here as possible to have 0 births and >=1 death in LSOA/ethicity group in 1 year, due to the way this indicator is calculated
FULL OUTER JOIN ##OF_NeonatalDeaths AS ND
on				LB.[LSOA2011]=ND.[LSOA2011]
AND				LB.[TimePeriod]=ND.[TimePeriod]
AND				LB.[Ethnicity_Code]=ND.[Ethnicity_Code]
--LEFT JOIN		(SELECT [LSOA11CD]
--				,		[LSOA21CD]
--				FROM	[EAT_Reporting_BSOL].[Reference].[LSOA_2011_to_LSOA_2021]
--				) AS LSOA2011to2022 ON LB.LSOA2011 = LSOA2011to2022.[LSOA11CD]

LEFT JOIN		[EAT_Reporting_BSOL].[Reference].[LSOA_2011_to_LSOA_2021] LSOA2011to2022 
				ON LB.LSOA2011 = LSOA2011to2022.[LSOA11CD]
--20240927 change from join on LAD to on LSOA21
left join      [EAT_Reporting_BSOL].[Reference].[LSOA_2021_WARD_LAD] wd
			   ON wd.LSOA21CD = LSOA2011to2022.LSOA21CD

left join	   [EAT_Reporting_BSOL].[Reference].[LSOA_2021_BSOL_to_Constituency_2025_Locality] lk
				on wd.LSOA21CD = lk.LSOA21CD

left join      [OF].[lkp_ethnic_categories] eth
				on case when COALESCE(LB.[Ethnicity_Code], ND.[Ethnicity_Code]) is null THEN  'Z' ELSE COALESCE(LB.[Ethnicity_Code], ND.[Ethnicity_Code]) END = eth.NHSCode


				
-- 1 YR
DROP TABLE IF EXISTS #33_working
Select 
		sum(Numerator) as Numerator,
		sum(Denominator) as Denominator,
		dtt.FinYear,
		a.ward_code as agregation_code,
		a.Ethnicity,
		'<28 days' as AgeGrp

into #33_working
FROM 
		(Select * 
		, convert(datetime, TimePeriod + '01', 112) AS dt
		from #33_staging) a
		inner join reference.[dbo].[DIM_tbDate] dtt ON a.dt = dtt.[Date]
Where	a.Locality is not null
group by dtt.FinYear,
		a.ward_code,
		a.Ethnicity
UNION ALL 
-- Locality
Select 
		sum(Numerator) as Numerator,
		sum(Denominator) as Denominator,
		dtt.FinYear,
		lcl.AggregationCode,
		a.Ethnicity,
		'<28 days' as AgeGrp
FROM 
		(Select * 
		, convert(datetime, TimePeriod + '01', 112) AS dt
		from #33_staging) a
		inner join reference.[dbo].[DIM_tbDate] dtt ON a.dt = dtt.[Date]
		inner join (Select * FROM [OF].[Aggregation] Where AggregationType = 'Locality (resident)') lcl ON a.Locality = lcl.AggregationLabel
Where	a.Locality is not null
group by dtt.FinYear,
		lcl.AggregationCode,
		a.Ethnicity
UNION ALL 
-- LA
Select 
		sum(Numerator) as Numerator,
		sum(Denominator) as Denominator,
		dtt.FinYear,
		a.LA_code,
		a.Ethnicity,
		'<28 days' as AgeGrp
FROM 
		(Select * 
		, convert(datetime, TimePeriod + '01', 112) AS dt
		from #33_staging) a
		inner join reference.[dbo].[DIM_tbDate] dtt ON a.dt = dtt.[Date]
Where	a.Locality is not null
group by dtt.FinYear,
		a.LA_code,
		a.Ethnicity
UNION ALL 
-- BSOL
Select 
		sum(Numerator) as Numerator,
		sum(Denominator) as Denominator,
		dtt.FinYear,
		'E38000258',
		a.Ethnicity,
		'<28 days' as AgeGrp
FROM 
		(Select * 
		, convert(datetime, TimePeriod + '01', 112) AS dt
		from #33_staging) a
		inner join reference.[dbo].[DIM_tbDate] dtt ON a.dt = dtt.[Date]
Where	a.Locality is not null
group by dtt.FinYear,
		--a.ward_code,
		a.Ethnicity		

INsert into #33_working
Select 
		sum(Numerator) as Numerator,
		sum(Denominator) as Denominator,
		dtt.FinYear,
		a.ward_code as agregation_code,
		NULL as Ethnicity,
		'<28 days' as AgeGrp

--into #33_working
FROM 
		(Select * 
		, convert(datetime, TimePeriod + '01', 112) AS dt
		from #33_staging) a
		inner join reference.[dbo].[DIM_tbDate] dtt ON a.dt = dtt.[Date]
Where	a.Locality is not null
group by dtt.FinYear,
		a.ward_code
		--a.Ethnicity
UNION ALL 
-- Locality
Select 
		sum(Numerator) as Numerator,
		sum(Denominator) as Denominator,
		dtt.FinYear,
		lcl.AggregationCode,
		NULL as Ethnicity,
		'<28 days' as AgeGrp
FROM 
		(Select * 
		, convert(datetime, TimePeriod + '01', 112) AS dt
		from #33_staging) a
		inner join reference.[dbo].[DIM_tbDate] dtt ON a.dt = dtt.[Date]
		inner join (Select * FROM [OF].[Aggregation] Where AggregationType = 'Locality (resident)') lcl ON a.Locality = lcl.AggregationLabel
Where	a.Locality is not null
group by dtt.FinYear,
		lcl.AggregationCode
		--a.Ethnicity
UNION ALL 
-- LA
Select 
		sum(Numerator) as Numerator,
		sum(Denominator) as Denominator,
		dtt.FinYear,
		a.LA_code,
		NULL as Ethnicity,
		'<28 days' as AgeGrp
FROM 
		(Select * 
		, convert(datetime, TimePeriod + '01', 112) AS dt
		from #33_staging) a
		inner join reference.[dbo].[DIM_tbDate] dtt ON a.dt = dtt.[Date]
Where	a.Locality is not null
group by dtt.FinYear,
		a.LA_code
		--a.Ethnicity
UNION ALL 
-- BSOL
Select 
		sum(Numerator) as Numerator,
		sum(Denominator) as Denominator,
		dtt.FinYear,
		'E38000258',
		NULL as Ethnicity,
		'<28 days' as AgeGrp
FROM 
		(Select * 
		, convert(datetime, TimePeriod + '01', 112) AS dt
		from #33_staging) a
		inner join reference.[dbo].[DIM_tbDate] dtt ON a.dt = dtt.[Date]
Where	a.Locality is not null
group by dtt.FinYear
		--a.ward_code,
		--a.Ethnicity		



-- Delte from output
Delete from [OF].[IndicatorValue]
Where IndicatorID = 33

-- Wrap into output format
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
Select 33 as IndicatorID
, getdate()
, coalesce(Numerator,0) as Numerator
, case when coalesce(Denominator,0) = 0 THEN 1 ELSE Denominator END as Denominator
, 1000 * (cast(coalesce(Numerator,0) as float) / cast((case when coalesce(Denominator,0) = 0 THEN 1 ELSE Denominator END)as float)) as IndicatorValue
, 1000 * ([OF].byars_lower_95(Numerator) / cast(denominator as float)) as LowerCI95
, 1000 * ([OF].byars_upper_95(Numerator) / cast(denominator as float)) as UpperCI95
, b.AggregationID
, c.DemographicID
, 1 as DataQualityID
, convert(datetime, CONCAT('20', substring(FinYear,1,2), '0401'), 112) as IndicatorStartDate
, convert(datetime, CONCAT('20', substring(FinYear,3,2), '0331'), 112) as IndicatorEndDate
--, FinYear

from #33_working a
left join  [OF].Aggregation b on a.agregation_code = b.AggregationCode
left join  [OF].Demographic c on a.Ethnicity = c.Ethnicity and a.AgeGrp = c.AgeGrp and c.IMD is NULL and c.Gender = 'Persons'
WHERE a.Ethnicity is not null

UNION ALL

Select 33 as IndicatorID
, getdate()
, coalesce(Numerator,0) as Numerator
, case when coalesce(Denominator,0) = 0 THEN 1 ELSE Denominator END as Denominator
, 1000 * (cast(coalesce(Numerator,0) as float) / cast((case when coalesce(Denominator,0) = 0 THEN 1 ELSE Denominator END)as float)) as IndicatorValue
, 1000 * ([OF].byars_lower_95(Numerator) / cast(denominator as float)) as LowerCI95
, 1000 * ([OF].byars_upper_95(Numerator) / cast(denominator as float)) as UpperCI95
, b.AggregationID
, c.DemographicID
, 1 as DataQualityID
, convert(datetime, CONCAT('20', substring(FinYear,1,2), '0401'), 112) as IndicatorStartDate
, convert(datetime, CONCAT('20', substring(FinYear,3,2), '0331'), 112) as IndicatorEndDate
--, FinYear

from #33_working a
left join  [OF].Aggregation b on a.agregation_code = b.AggregationCode
left join  [OF].Demographic c on c.Ethnicity is NULL and a.AgeGrp = c.AgeGrp and c.IMD is NULL and c.Gender = 'Persons'
WHERE a.Ethnicity is null


