
/*==================================================================================================================================================================
OUTCOMES FRAMEWORK: 
	
	103		Increase uptake of immunisations (C20+5) covid-19 
==================================================================================================================================================================*/




----indicator value %uptake 

----Sorting out Ethnicity Numerator
--drop table if exists #CovVacNumerator
--select IndicatorID,InsertDate,AreaType, Org_Code, Org_Name,AggID, DemographicID,IndicatorEndDate, sum([Value]) Numerator
--into #CovVacNumerator
--from (
--SELECT --top 10000 *,
--'Cov_Vac_1_Uptake' IndicatorID
-- ,GETDATE() as InsertDate
-- ,'Practice' as AreaType
-- ,[Org Code] as Org_Code
-- ,[Org Name] as Org_Name
--,[Value]
--,'Ethnicity' AggID
--,case when Attribute like 'White%' then 'White'
--		when Attribute like 'Mixed%' then 'Mixed or Multiple ethnic groups'
--		when Attribute like 'Asian%' then 'Asian or Asian British'
--		when Attribute like 'Black%' then 'Black, African, Caribbean or Black British'
--		when Attribute like '%Other%' then 'Other Ethnicity'
--		when Attribute like '%not%' then 'Unknown'
--		end DemographicID
--,[Date] as IndicatorEndDate
--  FROM [Working].[dbo].[COVID_Vac_Mar_24]
--  where Attribute like '%vaccinated%'  and Attribute like '%1%' --Numerator: only get the at least 1 dose which should include all other patients
--  and [Org Code] <>'Total'
--)a
--group by IndicatorID,InsertDate,AreaType, Org_Code, Org_Name,AggID, DemographicID,IndicatorEndDate
--order by IndicatorID,InsertDate,AreaType, Org_Code, Org_Name,AggID, DemographicID,IndicatorEndDate




----Sorting out Ethnicity denominator
--drop table if exists #CovVacDenominator
--select IndicatorID,InsertDate,AreaType, Org_Code, Org_Name,AggID, DemographicID,IndicatorEndDate, sum([Value]) Denominator
--into #CovVacDenominator
--from (
--SELECT --top 10000 *,
--'Cov_Vac_1_Uptake' IndicatorID
-- ,GETDATE() as InsertDate
-- ,'Practice' as AreaType
-- ,[Org Code] as Org_Code
-- ,[Org Name] as Org_Name
--,[Value]
--,'Ethnicity' AggID
--,case when Attribute like 'White%' then 'White'
--		when Attribute like 'Mixed%' then 'Mixed or Multiple ethnic groups'
--		when Attribute like 'Asian%' then 'Asian or Asian British'
--		when Attribute like 'Black%' then 'Black, African, Caribbean or Black British'
--		when Attribute like '%Other%' then 'Other Ethnicity'
--		when Attribute like '%not%' then 'Unknown'
--		end DemographicID
--,[Date] as IndicatorEndDate

--  FROM [Working].[dbo].[COVID_Vac_Mar_24]
--   where Attribute like '%registered%'  --Denominator: registered patients
--  and [Org Code] <>'Total'
--)a
--group by IndicatorID,InsertDate,AreaType, Org_Code, Org_Name,AggID, DemographicID,IndicatorEndDate
--order by IndicatorID,InsertDate,AreaType, Org_Code, Org_Name,AggID, DemographicID,IndicatorEndDate




--  select n.*
-- , d.Denominator
-- ,case when Denominator<>0 then	round(Numerator/Denominator *100,2) else 0  end	as IndicatorValue
-- into #Ethnicity
--from #CovVacNumerator n

--  join #CovVacDenominator d on  n.IndicatorID=d.IndicatorID
--								and n.Org_Code=d.Org_Code
--								and n.DemographicID=d.DemographicID
--								and n.IndicatorEndDate=d.IndicatorEndDate


/*88888888888888888888888888888888888888888888*/

--IndicatorID		DomainID		ReferenceID		ICBIndicatorTitle										IndicatorLabel												StatusID
--103				7				NULL			Increase uptake of immunisations (C20+5) covid-19		Increase uptake of immunisations (C20+5) covid-19			1

--sorting out ethnicity 

drop table if exists #CovVacNumerator
select IndicatorID,InsertDate,AreaType, Org_Code, Org_Name,AggID, DemographicID,IndicatorStartDate,IndicatorEndDate,[Quarter], sum([Value]) Numerator
into #CovVacNumerator
from (
SELECT --top 10000 *,
 103 IndicatorID
 ,GETDATE() as InsertDate
 ,'Practice' as AreaType
 ,[Org Code] as Org_Code
 ,[Org Name] as Org_Name
,[Value]
,Attribute
,'Ethnicity' AggID
,case when Attribute like 'White%' then 'White'
		when Attribute like 'Mixed%' then 'Mixed or Multiple ethnic groups'
		when Attribute like 'Asian%' then 'Asian or Asian British'
		when Attribute like 'Black%' then 'Black, African, Caribbean or Black British'
		when Attribute like '%Other%' then 'Other Ethnicity'
		when Attribute like '%not%' then 'Unknown'
		end DemographicID
,[Start Date] as IndicatorStartDate
,[End Date] as IndicatorEndDate
,[Quarter]
 -- FROM [Working].[dbo].[CovidVaccine2324]
  From  EAT_Reporting_BSOL.Development.CovidVaccine_Ethnicity_Age_23_24
  where Attribute like '%vaccinated%'  and Attribute like '%1 dose%' --Numerator: only get the at least 1 dose which should include all other patients
  and [Org Code] <>'Total' 
)a
group by IndicatorID,InsertDate,AreaType, Org_Code, Org_Name,AggID, DemographicID,IndicatorStartDate,IndicatorEndDate,[Quarter]
order by IndicatorID,InsertDate,AreaType, Org_Code, Org_Name,AggID, DemographicID,IndicatorStartDate,IndicatorEndDate,[Quarter]


--Sorting out Ethnicity denominator
drop table if exists #CovVacDenominator
select IndicatorID,InsertDate,AreaType, Org_Code, Org_Name,AggID, DemographicID,IndicatorStartDate,IndicatorEndDate,[Quarter], sum([Value]) Denominator
into #CovVacDenominator
from (
SELECT --top 10000 *,
103 IndicatorID
 ,GETDATE() as InsertDate
 ,'Practice' as AreaType
 ,[Org Code] as Org_Code
 ,[Org Name] as Org_Name
,[Value]
,'Ethnicity' AggID
,case when Attribute like 'White%' then 'White'
		when Attribute like 'Mixed%' then 'Mixed or Multiple ethnic groups'
		when Attribute like 'Asian%' then 'Asian or Asian British'
		when Attribute like 'Black%' then 'Black, African, Caribbean or Black British'
		when Attribute like '%Other%' then 'Other Ethnicity'
		when Attribute like '%not%' then 'Unknown'
		end DemographicID
,[Start Date] as IndicatorStartDate
,[End Date] as IndicatorEndDate
,[Quarter]
 --FROM [Working].[dbo].[CovidVaccine2324]
 From  EAT_Reporting_BSOL.Development.CovidVaccine_Ethnicity_Age_23_24
   where Attribute like '%registered%'  --Denominator: registered patients
  and [Org Code] <>'Total' 
)a
group by IndicatorID,InsertDate,AreaType, Org_Code, Org_Name,AggID, DemographicID,IndicatorStartDate,IndicatorEndDate,[Quarter]
order by IndicatorID,InsertDate,AreaType, Org_Code, Org_Name,AggID, DemographicID,IndicatorStartDate,IndicatorEndDate,[Quarter]



drop table if exists #Ethnicity
  select n.*
 , d.Denominator
 ,case when Denominator<>0 then	round(Numerator/Denominator *100,2) else 0  end	as IndicatorValue
 into #Ethnicity
from #CovVacNumerator n
join #CovVacDenominator d on  n.IndicatorID=d.IndicatorID
							 and n.Org_Code=d.Org_Code
							 and n.DemographicID=d.DemographicID
							 and n.IndicatorEndDate=d.IndicatorEndDate


 SELECT TOP 1000 *
    FROM EAT_Reporting_BSOL.Development.CovidVaccine_Ethnicity_Age_23_24

--where Attribute like '%50%'
---------------------------------------------------------------------------------------------------
--sorting out age

drop table if exists #CovVacNumeratorAge
select IndicatorID,InsertDate,AreaType, Org_Code, Org_Name,AggID, DemographicID,IndicatorStartDate,IndicatorEndDate,[Quarter], sum([Value]) Numerator
into #CovVacNumeratorAge
from (
SELECT --top 10000 *,
103 IndicatorID
 ,GETDATE() as InsertDate
 ,'Practice' as AreaType
 ,[Org Code] as Org_Code
 ,[Org Name] as Org_Name
,[Value]
,Attribute
,'Age_Band' AggID
,case when Attribute like '%under 16%' then '05-16'
		when Attribute like '%under 50%' then '16-50'
		when Attribute like '%under 65%' then '50-65'
		when Attribute like '%65 plus%' then '65+'
		end DemographicID
,[Start Date] as IndicatorStartDate
,[End Date] as IndicatorEndDate
,[Quarter]
 From  EAT_Reporting_BSOL.Development.CovidVaccine_Ethnicity_Age_23_24
  --FROM [Working].[dbo].[CovidVaccine2324]
  where Attribute like '%vaccinated%'  and Attribute like '%1 dose%' --Numerator: only get the at least 1 dose which should include all other patients
  and [Org Code] <>'Total' 
)a
group by IndicatorID,InsertDate,AreaType, Org_Code, Org_Name,AggID, DemographicID,IndicatorStartDate,IndicatorEndDate,[Quarter]
order by IndicatorID,InsertDate,AreaType, Org_Code, Org_Name,AggID, DemographicID,IndicatorStartDate,IndicatorEndDate,[Quarter]


--Sorting out age band denominator



drop table if exists #CovVacDenominatorAge
select IndicatorID,InsertDate,AreaType, Org_Code, Org_Name,AggID, DemographicID,IndicatorStartDate,IndicatorEndDate,[Quarter], sum([Value]) Denominator
into #CovVacDenominatorAge
from (
SELECT --top 10000 *,
103 IndicatorID
 ,GETDATE() as InsertDate
 ,'Practice' as AreaType
 ,[Org Code] as Org_Code
 ,[Org Name] as Org_Name
,[Value]
,'Age_Band' AggID
,case when  Attribute like '%under 16%' then '05-16'
		when Attribute like '%under 50%' then '16-50'
		when Attribute like '%under 65%' then '50-65'
		when Attribute like '%65 plus%' then '65+'
		end DemographicID
,[Start Date] as IndicatorStartDate
,[End Date] as IndicatorEndDate
,[Quarter]
 From  EAT_Reporting_BSOL.Development.CovidVaccine_Ethnicity_Age_23_24

   where Attribute like '%registered%'  --Denominator: registered patients
  and [Org Code] <>'Total' 
)a
group by IndicatorID,InsertDate,AreaType, Org_Code, Org_Name,AggID, DemographicID,IndicatorStartDate,IndicatorEndDate,[Quarter]
order by IndicatorID,InsertDate,AreaType, Org_Code, Org_Name,AggID, DemographicID,IndicatorStartDate,IndicatorEndDate,[Quarter]


--select top 10 * from #CovVacDenominatorAge
drop table if exists #Age
  select n.*
 , d.Denominator
 ,case when Denominator<>0 then	round(Numerator/Denominator *100,2) else 0  end	as IndicatorValue
 into #Age
from #CovVacNumeratorAge n
join #CovVacDenominatorAge d on  n.IndicatorID=d.IndicatorID
							 and n.Org_Code=d.Org_Code
							 and n.DemographicID=d.DemographicID
							 and n.IndicatorEndDate=d.IndicatorEndDate
--select * from #Age

---------------------------------------------------------------------------------------------------------------------------
--sort out Gender

  SELECT TOP 1000 *
    FROM EAT_Reporting_BSOL.Development.CovidVaccine_Gender


drop table if exists #CovVacNumeratorSex
select IndicatorID,InsertDate,AreaType, Org_Code, Org_Name,AggID, DemographicID,IndicatorStartDate,IndicatorEndDate,[Quarter], sum([Value]) Numerator
into #CovVacNumeratorSex
from (
SELECT --top 10000 *,
 103 IndicatorID
 ,GETDATE() as InsertDate
 ,'Practice' as AreaType
 ,[Org Code] as Org_Code
 ,[Org Name] as Org_Name
,[Value]
,Attribute
,'Sex' AggID
,case when Attribute like 'Male%' then 'Male'
		when Attribute like 'Female%' then 'Female'
		end DemographicID
,[Start Date] as IndicatorStartDate
,[End Date] as IndicatorEndDate
,[Quarter]
 From  EAT_Reporting_BSOL.Development.CovidVaccine_Gender
  --FROM [Working].[dbo].[CovidVaccine2324]
  where Attribute like '%vaccinated%'  and Attribute like '%1 dose%' --Numerator: only get the at least 1 dose which should include all other patients
  and [Org Code] <>'Total' and Attribute <> 'Gender%'
)a
group by IndicatorID,InsertDate,AreaType, Org_Code, Org_Name,AggID, DemographicID,IndicatorStartDate,IndicatorEndDate,[Quarter]
order by IndicatorID,InsertDate,AreaType, Org_Code, Org_Name,AggID, DemographicID,IndicatorStartDate,IndicatorEndDate,[Quarter]


--Sorting out sex denominator



drop table if exists #CovVacDenominatorSex
select IndicatorID,InsertDate,AreaType, Org_Code, Org_Name,AggID, DemographicID,IndicatorStartDate,IndicatorEndDate,[Quarter], sum([Value]) Denominator
into #CovVacDenominatorSex
from (
SELECT --top 10000 Attribute,
 103 IndicatorID
 ,GETDATE() as InsertDate
 ,'Practice' as AreaType
 ,[Org Code] as Org_Code
 ,[Org Name] as Org_Name
,[Value]
,'Sex' AggID
,case when Attribute like 'Male%' then 'Male'
		when Attribute like 'Female%' then 'Female'
		end DemographicID
,[Start Date] as IndicatorStartDate
,[End Date] as IndicatorEndDate
,[Quarter]
 From  EAT_Reporting_BSOL.Development.CovidVaccine_Gender

   where Attribute like '%registered%'  --Denominator: registered patients
  and [Org Code] <>'Total' 
)a
group by IndicatorID,InsertDate,AreaType, Org_Code, Org_Name,AggID, DemographicID,IndicatorStartDate,IndicatorEndDate,[Quarter]
order by IndicatorID,InsertDate,AreaType, Org_Code, Org_Name,AggID, DemographicID,IndicatorStartDate,IndicatorEndDate,[Quarter]

--select top 10* from #CovVacNumeratorSex
--select top 10 * from  #CovVacDenominatorSex
		
--select top 10 * from #CovVacDenominatorAge
drop table if exists #Sex
  select n.*
 , d.Denominator
 ,case when Denominator<>0 then	round(Numerator/Denominator *100,2) else 0  end	as IndicatorValue
 into #Sex
from #CovVacNumeratorSex n
join #CovVacDenominatorSex d on  n.IndicatorID=d.IndicatorID
							 and n.Org_Code=d.Org_Code
							 and n.DemographicID=d.DemographicID
							 and n.IndicatorEndDate=d.IndicatorEndDate

------------------------------------------------------------------------------
-----All data

drop table if exists #AllData
select *
into #AllData
from
(
select * from #Ethnicity
union all
select* from #Age
union all
select* from #Sex
)a



--select top 100 * from [Working].[dbo].[CovidVaccine2324]
select * from #AllData
order by Org_Code, AggID,[Quarter]


--IndicatorID	InsertDate	AreaType	Org_Code	Org_Name	AggID	DemographicID	IndicatorStartDate	IndicatorEndDate	Quarter	Numerator	Denominator	IndicatorValue
--103	2024-03-20 13:25:24.040	Practice	M85797	HOCKLEY MEDICAL PRACTICE, 60 LION COURT, CARVER STREET, BIRMINGHAM, WEST MIDLANDS, B1 3AL	Ethnicity	Black, African, Caribbean or Black British	2022-04-01 00:00:00.000	2023-06-23 00:00:00.000	Q4	915	2206	41.48


--select top 100 * from #AllData