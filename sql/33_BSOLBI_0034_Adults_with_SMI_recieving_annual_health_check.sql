------------------------------------------------------------------
-- Outcomes Framework
-- Indicator 93 - % of adults with SMI receiving full healthcheck
-- JT_db_61, Sub_1110
------------------------------------------------------------------

-- ANALYST: John O'Neill (john.o'neill3@nhs.net)
-- DATE:	2024.08.27

/* 
Indicator: % of adults with SMI receiving healthcheck.

Numerator: No. received healthcheck
Denominator: all on SMI (those who received AND did not receive healthcheck).

Indicator Description: 
	Achievement represents the proportion of individuals on the SMI register who receive six types of health check in the rolling year. These are: a measurement of weight (BMI or BMI + Waist circumference); a blood pressure and pulse check (diastolic and systolic blood pressure recording + pulse rate); a blood lipid including cholesterol test (cholesterol measurement or QRISK measurement); a blood glucose test (blood glucose or HbA1c measurement); an assessment of alcohol consumption; an assessment of smoking status. 
	The SMI register includes all patients with a diagnosis of schizophrenia, bipolar affective disorder and other psychoses and other patients on lithium therapy, as recorded in a GP�s QoF register. 

Ethnicity code nulled for expediency. Ethnicity standardisation needs to take place at a later date, as recording quality is poor.

Initial output hardcoded to 2023.24.Q4 as there is a full dataset for this quarter.

UPDATES:

2024.08.29 - CM added reference ID, removed hardcoded limit to q4 23/24 for back data, but removed most recent quarter after discussion with AT and BA.  Added in as group by instead.
			 Altered format of date to allow SH processing script to pick up.
			 CM and BA reviewed and changed PCN/locality look ups to 'registered' (GP-based lookup route), rather than 'resident' (LSOA based), as this is GP-related indicator.
2024.08.30 - CM altered the joins to make GP practise the current value, filter out of region and make sure valid PCN.

*/

--populate this table [Eat_reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]

-- Output needs to be grouped to the level of 
-- Ethnicity Code
-- LSOA
-- GP Practice. 

-- Data Source: SMI Healthchecks Clinical Systems Extract. 
-- Granularity possible from data source? Yes - Load data into SQL then transact. 
-- Do you have full Q1 data - no TPP is missing , asked clinical systems team to send. 
-- do 2023.24 Q4 Data

-- Issues: Ethnicity Coding is a mess, leave ethnicity null for now, plan to improve later on.

-- Step one: Load Data to SQL
-- Step Two: Transact numerator and denominator grouped
-- Step three: Add LSOA_2021, PCN and Locality information.

-- Raw data location select top 100 * from [Working].[Defaults].[BSOL_0412_SMI_Healthchecks_Demog]

-- Remove whitespace in source dataset

	Update [Working].[Defaults].[BSOL_0412_SMI_Healthchecks_Demog]
	SET [SOA (lower layer)] = null
	WHERE [SOA (lower layer)] = ''

--create table and populate numerator

		if object_id(N'tempdb..#OF_93', N'U')	is not null drop table #OF_93

		Select 
			93 as [IndicatorID]
			,	'MH6' as [ReferenceID]	--what is this?
			,	[Financial Quarter]	as [TimePeriod]	--Current Reporting Period of MHSDS?
			,	'Other' as [TimePeriodDesc]
			,	[GMPC] as [GP_Practice]  --[GMPC] replaced with GP Practise Current
			,	B.[PCN] -- now taken from BSOL_ICS_PracticeMapped 
			,	B.Locality as [Locality_Reg]
			,	null	as [Numerator] 
			,	sum([Patient Count]) as [Denominator] --sum patients who did and didn't have all six checks.
			,	'Practice Level' as [Indicator_Level]
			,	[SOA (lower layer)] as [LSOA_2011]
			,	cast(null as Varchar(15)) as [LSOA_2021]
			,	null as [Ethnicity_Code] -- tidy up and standardise ethncity recording at a later date	

		INTO #OF_93
		-- 
		FROM [Working].[Defaults].[BSOL_0412_SMI_Healthchecks_Demog] 	A
		INNER JOIN	 [EAT_Reporting_BSOL].[Reference].[BSOL_ICS_PracticeMapped] B ON A.[GMPC] = B.[GPPracticeCode_Original]
		WHERE B.[ICS_2223] = 'BSOL'

		--hardcode to latest period where there is a full dataset.  
		--WHERE [Financial Quarter] <>  '2024.25 Q1'

		group by 
				[Financial Quarter]
			,	[GMPC] 
			,	[SOA (lower layer)]	
			--,	[Ethnic_Code]	
			, b.PCN
			, b.Locality


-- Update table with numerator

		UPDATE A

		SET A.[Numerator] = B.[Numerator]

		FROM #OF_93 A
		INNER JOIN (Select sum([Patient Count]) as [Numerator]
					,	[Financial Quarter]
					,	[GMPC] 
					,	[SOA (lower layer)]	
			
					FROM [Working].[Defaults].[BSOL_0412_SMI_Healthchecks_Demog]

					WHERE [Received Core Six Checks Flag] = 1

					--hardcode to latest period where there is a full dataset.  
					--AND [Financial Quarter] = '2023.24 Q4'

					GROUP BY 
						[Financial Quarter]
					,	[GMPC] 
					,	[SOA (lower layer)]	
					) B ON A.TimePeriod = B.[Financial Quarter]
						AND A.[GP_Practice] = B.[GMPC]
						AND A.[LSOA_2011] = B.[SOA (lower layer)]


--Update table with LSOA_2021

	UPDATE A
	SET A.[LSOA_2021] = B.[LSOA21CD]

	FROM #OF_93 A
	INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2011_to_LSOA_2021] B ON A.LSOA_2011 = B.[LSOA11CD]

---- update table with Locality
-- cm 2024.08.29 Commented out and replaced with GP-based lookup below.


--	UPDATE A
--	SET A.[Locality_Reg] = B.[Locality]

--	FROM #OF_93 A
--	INNER JOIN	[EAT_Reporting_BSOL].[Reference].[LSOA_2021_BSOL_to_Constituency_2025_Locality] B ON A.[LSOA_2021] = B.[LSOA21CD]
	
-- update table with PCN

	--UPDATE A
	--SET A.[PCN] = B.[PCN]
	--,a.Locality_Reg=b.Locality
	
	--FROM #OF_93 A
	--INNER JOIN	 [EAT_Reporting_BSOL].[Reference].[BSOL_ICS_PracticeMapped] B ON A.[GP_Practice] = B.[GPPracticeCode_Original]
	--WHERE B.[ICS_2223] = 'BSOL'


	--select * from #OF_93


-- Agregate up to financial year for this version
		if object_id(N'tempdb..#OF_93_agg', N'U')	is not null drop table #OF_93_agg

Select IndicatorID
		, ReferenceID
		, substring(TimePeriod, 1, 4) + '/' + substring(TimePeriod,6,2) as TimePeriod
		, 'Financial Year' as TimePeriodDesc
		, [GP_Practice]
		, [PCN]
		, [Locality_Reg]
		, sum([Numerator]) as [Numerator] 
		, sum([Denominator]) as [Denominator]  --sum patients who did and didn't have all six checks.
		, [Indicator_Level]
		, [LSOA_2011]
		, [LSOA_2021]
		, [Ethnicity_Code] -- tidy up and
into #OF_93_agg
from #OF_93
group by IndicatorID
		, ReferenceID
		, substring(TimePeriod, 1, 4) + '/' + substring(TimePeriod,6,2) 
		, [GP_Practice]
		, [PCN]
		, [Locality_Reg] 
		, [Indicator_Level]
		, [LSOA_2011]
		, [LSOA_2021]
		, [Ethnicity_Code]


----------------------------------------------------------------
-- Insert to [OF].[IndicatorDataPredefinedDenominator]
----------------------------------------------------------------
--Delete from [OF].[IndicatorDataPredefinedDenominator] Where IndicatorID = 93
Insert into [OF].[IndicatorDataPredefinedDenominator]

Select * from #OF_93_agg




