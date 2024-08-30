---------------------------------------------
-- JT_db_61 sub_1106, Outcomes Framework
-- IndicatorID 90 - CYP preavelence accessing
---------------------------------------------

-- ANALYST: John O'Neill
-- DATE: 2024.08.23

-- OUTPUT: #OF_90

/*

TITLE
Increase access rates to children & young people�s mental health services for 0-17yrs (C2+5CYP)

INDICATOR LABEL (chosen by me J.O)
Proportion of 0-17 prevalent with Any mental disorder (0-15) or Common Mental Disorder (16+) who are accessing Seconday MH support (1+ contact).

Numerator: 0-17's with 1+ contact in R12m
Denominator: Prevalent Population


*/

-- UPDATES	2024.08.28 Patient ethncity imputation table changed to EAT_Reporting_BSOL.Demographic.Ethnicity as request of Chris Mainey (was previously [EAT_Reporting_BSOL].[Demographic].[BSOL_Registered_Population]) 
--			2024.08.28 Patient ethncity codes of 9 changed to Z to align with project standardisation.
--			2024.08.28 [TimePeriod] of '2023-24' added to output. 
--          2024.08.29 CM and BA reviewed and changed PCN/locality look ups to 'registered' (GP-based lookup route), rather than 'resident' (LSOA based), as this is GP-related indicator.

-----------------------------------------------------------------------
-- Sub_1106 0-17 Prevalent Population
-- Adapted from BSOL_1191 MH Community Tranformation Project - Equalities Dashboard - Prevalent Pop, Age bands / filters changed to be 0-17.
-- Further simplification for this purpose possible when time pressure is less.
-----------------------------------------------------------------------

			-- OUTPUT:	#BSOL_Sub_1106_CMD_AMD_Prevalent_Pop

			-- Metric:	Common Mental Disorder, Prevalent Population in BSOL Age banded, as relative to NHS Spine.

			-- Dimensions:	Local Authority, Locality, PCN, LSOA, IMD, Gender, Age band aligned with prevalence age bands, Ethnicity.

			-- Analyst: John O'Neill (john.o'neill3@nhs.net)

			-- UPDATES:	gender could be added to this group by later. 
			--			2023.05.19 Ward Code and name for Ridgeacre surgery modified so the ward code is quinton in birmingham, rather than old warley as it is in BSOL practice mapped reference table. (old warley is in Sandwell). 
			--						ward code and name for Queslett medical centre changed to perry bar, so it maps in B'ham and not walsall.
			--			2023.05.23	Logic changed to return records for 5-25's only to suit CYP access dash, and align to prevalence which starts at 5 years old.
			--			2024.08.22	fields added to group by / output to align with Outcome Framework (JT_db_61, Sub_1106)
			--			2024.08.22	Age filters changed to be 0-17
			--			2024.08.22	Output location changed removed, Output now #Temp db, SQL moved inline
     

Use EAT_Reporting_BSOL
GO

			-------------------
			-- Create [Geography_Category] lookup table
			-------------------

			if object_id(N'tempdb..#Geog_Cat', N'U')	is not null drop table #Geog_Cat

				Create TABLE #Geog_Cat (
						[Locality] nvarchar(50),
						[Local Authority] nvarchar(50),
		
					)

				Insert INTO #Geog_Cat

				VALUES	
					('Central', 'Birmingham') ,
					('East', 'Birmingham') ,
					('North', 'Birmingham') ,
					('Solihull', 'Solihull') ,
					('South', 'Birmingham') ,
					('West', 'Birmingham') 


			-----------------
			-- Create Population baseline at Ward / pcn / age band Level.
			-- Source for data is BSOL NHS spine at patient level.
			-----------------

			if object_id(N'tempdb..#POP_Baselines', N'U')	is not null drop table #POP_Baselines

			-- Population by Age brackets, Ward, BSOL localities and PCN's

					Select '5-17 aged Population' as [Theme]
						
						,	[GP_Code]
						,	[LSOA_2011]
						,	[Local Authority]
						,	[Ethnic_Code]
						,	[Age_banding]
						,	'NHS Spine' as	[Data Source]
						,	count(1) as [Population_Value]

						INTO #POP_Baselines

						from   (
								select 
									[GP_Code]
								  ,	[ProxyAgeAtEOM]	
								  ,	iif([Ethnic_Code] = '9', 'Z',[Ethnic_Code]) as [Ethnic_Code]
								  , [LSOA_2011]	
								  ,	p.[Locality]
								  ,	BSOL_Table_Snapshot
								  ,	g.[Local Authority]
								  --case statement to define age bands (remember that '95+' has been changed into 95)
									-- start with brackets that match prevalence calculations.
								,	Case	When [ProxyAgeAtEOM] between 5 and 15 THEN '5 - 15'	--to match 'Estimated number of children and young people with mental disorders � aged 5 to 17'
									When [ProxyAgeAtEOM] between 16 and 64 THEN '16 - 64'	--to match 'Common Mental Disorder age brackets'
									When [ProxyAgeAtEOM] >64 THEN '65+'	
									ELSE NULL END
									 as		[Age_banding]
				  				
								FROM  [EAT_Reporting_BSOL].[Demographic].[BSOL_Registered_Population] p

								LEFT JOIN #Geog_Cat g ON p.Locality = g.[Locality]

								 --filter to CYP 5-17 aged cohort
								Where [ProxyAgeAtEOM] between 5 and 17

								) age 
				
						Group by 
								[GP_Code]
						,	[Local Authority]
						,	[LSOA_2011]
						,	[Ethnic_Code]
						,	[Age_banding]

			--select  * from #POP_Baselines 
			--select sum([population_value]) from #pop_baselines


			-----------------
			-- Create Prevalence Rates Table.
			-----------------
				if object_id(N'tempdb..#Prevalence', N'U')	is not null drop table #Prevalence

				Create TABLE #Prevalence (
						[Prevalence_Type] nvarchar(50),
						[Source] nvarchar(135),
						[Data_Currency] date,
						[Geography_Type] nvarchar(50),
						[Geography_Category] nvarchar(50),
						[Geography_Code] nvarchar(50),
						[Age_Band] nvarchar(50),
						[Prevalence_Rate] float
					)

				Insert INTO #Prevalence 

				VALUES	
						('Common Mental Disorder', 'https://fingertips.phe.org.uk/profile-group/mental-health/profile/common-mental-disorders', '2017-01-01', 'Local Authority',	'Birmingham',				'E08000025', '16 - 64',	0.211 ),
						('Common Mental Disorder', 'https://fingertips.phe.org.uk/profile-group/mental-health/profile/common-mental-disorders', '2017-01-01', 'Local Authority',	'Birmingham',				'E08000025', '65+',		0.127 ),
						('Common Mental Disorder', 'https://fingertips.phe.org.uk/profile-group/mental-health/profile/common-mental-disorders', '2017-01-01', 'ICB',				'Birmingham and Solihull',	'E54000055', '16 - 64',	0.196 ),
						('Common Mental Disorder', 'https://fingertips.phe.org.uk/profile-group/mental-health/profile/common-mental-disorders', '2017-01-01', 'ICB',				'Birmingham and Solihull',	'E54000055', '65+',		0.117 ),
						('Common Mental Disorder', 'https://fingertips.phe.org.uk/profile-group/mental-health/profile/common-mental-disorders', '2017-01-01', 'Local Authority',	'Solihull',					'E08000029', '16 - 64',	0.147 ),
						('Common Mental Disorder', 'https://fingertips.phe.org.uk/profile-group/mental-health/profile/common-mental-disorders', '2017-01-01', 'Local Authority',	'Solihull',					'E08000029', '65+',		0.092 ),
						('Any Mental Disorder', 'https://digital.nhs.uk/data-and-information/publications/statistical/mental-health-of-children-and-young-people-in-england/2017/2017', '2017-01-01', 'Local Authority', 'Birmingham', 'E08000025', '5 - 15', 0.112 ),
						('Any Mental Disorder', 'https://digital.nhs.uk/data-and-information/publications/statistical/mental-health-of-children-and-young-people-in-england/2017/2017', '2017-01-01', 'ICB', 'Birmingham and Solihull', 'E54000055', '5 - 15', 0.112 ),
						('Any Mental Disorder', 'https://digital.nhs.uk/data-and-information/publications/statistical/mental-health-of-children-and-young-people-in-england/2017/2017', '2017-01-01', 'Local Authority', 'Solihull', 'E08000029', '5 - 15', 0.112 )


						--select * from #Prevalence
			---------------------------------
			-- Work out Prevalent Population
			---------------------------------

			--if object_id('[Working].[Defaults].[BSOL_Sub_1106_CMD_&_AMD_Prevalent_Pop]')	is not null drop table [Working].[Defaults].[BSOL_Sub_1106_CMD_&_AMD_Prevalent_Pop]
			if object_id(N'tempdb..#BSOL_Sub_1106_CMD_AMD_Prevalent_Pop', N'U')	is not null drop table #BSOL_Sub_1106_CMD_AMD_Prevalent_Pop

			Select 
						pop.*
					,	prev.Prevalence_Rate
					,	prev.Prevalence_Type
					,	round([Population_Value] * prev.Prevalence_Rate,2) as [Prevalent_Population]

			INTO #BSOL_Sub_1106_CMD_AMD_Prevalent_Pop
   
			FROM #POP_Baselines pop

			LEFT JOIN #Prevalence prev	ON	pop.[Local Authority] = prev.[Geography_Category]
										AND pop.[Age_banding] = prev.[Age_Band]

										--Select * from  #BSOL_Sub_1106_CMD_AMD_Prevalent_Pop
--------------------------------------------------------------------
---------------------- NUMERATOR
-- Work Out 12m Rolling Accessing Volumes from MHSDS for 5-17 's 
----------------------

		-- Group by: GP code, LSOA 2011 and ethncity code (PCN and LSOA 2021 can be mapped from this I think)
			
		if object_id(N'tempdb..#CYP_Access', N'U')	is not null drop table #CYP_Access

		select 
				
				count  ( distinct [Person_ID]) as [5-17 Patients Accessing]
			,	[LSOA2011]
			,	GMPCodeReg
			,	[NHSDEthnicity]
						
			--Data Coverage Fields
			,	min([ReferralRequestReceivedDate]) as [Referrals_Received_From]
			,	max([ReferralRequestReceivedDate]) as [Referrals_Received_To]

		INTO #CYP_Access

		from (--pull required fields and impute missing data via join to spine table 
				Select
					[UniqServReqID]
				,	[Pseudo_NHSNumber]
				,	[Person_ID]
				,	isnull(mh.[LSOA2011],pop.[LSOA_2011]) as [LSOA2011]
				,	iif(mh.GMPCodeReg in('V81998','V81999') and pop.[GP_Code] is not null, pop.[GP_Code],isnull(mh.GMPCodeReg, pop.[GP_Code]) ) as GMPCodeReg
				,	isnull(eth.[Ethnic_Code],mh.[NHSDEthnicity]) as [NHSDEthnicity]
				,	AgeServReferRecDate
				,	[ReferralRequestReceivedDate]

				FROM [Working].[Defaults].[MHSDS_Referrals_MultiTableAggregation_V5] mh

				--BSOL registered pop table to impute LSOA and GP code
				LEFT JOIN [EAT_Reporting_BSOL].[Demographic].[BSOL_Registered_Population] pop ON mh.[Pseudo_NHSNumber] = pop.Pseudo_NHS_Number

				--Chris Mainey asked that ethnicity be imputed from this tables
				LEFT JOIN [EAT_Reporting_BSOL].[Demographic].[Ethnicity] eth ON mh.[Pseudo_NHSNumber] = eth.[Pseudo_NHS_Number]

				where [AgeServReferRecDate] Between 5 and 17 --make results 5-17, to match outcomes framework indicator
					--only keep referrals where there is at least one contact
				AND [Attended care contacts (exc email, text and mssg board (asynchronous))] >0
					-- exclude Single Point of Access Teams
				AND [ServTeamTypeRefToMH] <> 'A18' 
					--limit to Rolling 12 months
				AND [ReferralRequestReceivedDate] >= (Select dateadd(month,-11, max([ReportingPeriodStartDate]) ) from [Working].[Defaults].[MHSDS_Referrals_MultiTableAggregation_V5] )
					--limit to BSOL patient's
				AND [OrgIDComm] in( '15E', '15E00','QHL', 'QHL00')

				) r

		GROUP BY  	
					[LSOA2011]
			,		GMPCodeReg
			,	[NHSDEthnicity]
				
		--standardise ethnicity codes to match BSOL Spine

		Update #CYP_Access 
		SET [NHSDEthnicity] = 'Z' Where [NHSDEthnicity] in('-1','99','Z','9') or [NHSDEthnicity] is null


-----------------------------
--	Join Accessing to Prevalent Population data for final output
------------------------------

		-- create output table and populate with denominator

		--	Prevalent Population Data
		if object_id(N'tempdb..#OF_90', N'U')	is not null drop table #OF_90

		Select 
			90 as [IndicatorID]
			,	'MH2'	as [ReferenceID]	--what is this?
			,	'2023-24'	as [TimePeriod]	--Current Reporting Period of MHSDS?
			,	'Financial Year' as [TimePeriodDesc]
			,	[GP_Code] as [GP_Practice]
			,	cast(null as Varchar(45))	as [PCN]
			,	cast(null as Varchar(15)) as [Locality_Reg]
			,	null	as [Numerator]
			,	sum([Prevalent_Population]) as [Denominator]
			,	'Practice Level' as [Indicator_Level]
			,	LSOA_2011	
			,	cast(null as Varchar(15)) as [LSOA_2021]
			,	[Ethnic_Code] as [Ethnicity_Code]	

		INTO #OF_90

		FROM #BSOL_Sub_1106_CMD_AMD_Prevalent_Pop

		group by 
				[GP_Code] 
			,	LSOA_2011	
			,	[Ethnic_Code]	

	-- update table with numerator.

	UPDATE A
	SET A.[Numerator] = B.[5-17 Patients Accessing]

	FROM #OF_90 A
	INNER JOIN #CYP_Access B	ON A.[GP_Practice] = B.[GMPCodeReg]
								AND A.[LSOA_2011] = B.[LSOA2011]
								AND A.Ethnicity_Code = B.NHSDEthnicity

	--update table with LSOA_2021

	UPDATE A
	SET A.[LSOA_2021] = B.[LSOA21CD]

	FROM #OF_90 A
	INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2011_to_LSOA_2021] B ON A.LSOA_2011 = B.[LSOA11CD]

	---- update table with Locality
	-- cm 2024.08.29 Commented out and replaced with GP-based lookup below.

	--UPDATE A
	--SET A.[Locality_Reg] = B.[Locality]

	--FROM #OF_90 A
	--INNER JOIN	[EAT_Reporting_BSOL].[Reference].[LSOA_2021_BSOL_to_Constituency_2025_Locality] B ON A.[LSOA_2021] = B.[LSOA21CD]
	
	-- update table with PCN

	UPDATE A
	SET A.[PCN] = B.[PCN]
	,a.Locality_Reg=b.Locality

	
	FROM #OF_90 A
	INNER JOIN	 [EAT_Reporting_BSOL].[Reference].[BSOL_ICS_PracticeMapped] B ON A.[GP_Practice] = B.[GPPracticeCode_Original]
	WHERE B.[ICS_2223] = 'BSOL'

	



--------------------------------------------------------------------------------
-- Insert into the [OF].[IndicatorDataPredefinedDenominator] table
--------------------------------------------------------------------------------

--Insert into [OF].[IndicatorDataPredefinedDenominator]
Insert into [OF].[IndicatorDataPredefinedDenominator]
Select * from #OF_90
