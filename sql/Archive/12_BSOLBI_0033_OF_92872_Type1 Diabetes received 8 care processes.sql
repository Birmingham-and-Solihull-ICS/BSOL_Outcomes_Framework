
/*==================================================================================================================================================================
OUTCOMES FRAMEWORK: National Diabetes Audit

	92872	People with Type 1 Diabetes who received all 8 Care Processes


NOTES/CAVEATS WITH DATA:

 - Issues with historical data, i.e. low counts for Audit years pre 2022/23 when compared to nationally published data if using [Parent_Organisation_Code] or [ICB_Code] fields

 - When basing data on CURRENT list of BSOL GP Practices, historical data is more comparable, but does mean we will not have historical GP Practice mapping at time of event.
 - Agreed with RW on 24/05/2024 to base these indicators on CURRENT list of BSOL GP Practices instead of using [Parent_Organisation_Code] or [ICB_Code] in the source data.
 - Use [AUDIT_YEAR] IN  ('201415','201516','201617','201718','201819','201920','202021','202122E4','202223'202324E1') as per Definition from RW
 
==================================================================================================================================================================*/



/*==================================================================================================================================================================
92872	People with Type 1 Diabetes who received all 8 Care Processes.

Numerator:		Count of all patients with type 1 diabetes who received all 8 care processes
					- [DERIVED_CLEAN_DIABETES_TYPE] = 1		-- Type 1 Diabetes Flag
					- [ALL_8_CARE_PROCESSES] = 1			-- Flag if patient has received all 8 care process	

Denominator:	Count of all patients with Type 1 Diabetes

=================================================================================================================================================================*/

--STEP 01: Numerator: Patients at BSOL GP Practices with Type 1 Diabetes who received all 8 care processes

DROP TABLE IF EXISTS   	#92872_Numerator_NDA_Type1_8CareProcesses

SELECT		'92872'									AS [ReferenceID]
,			[DERIVED_CLEAN_ETHNICITY]				AS [Ethnicity_Code]
,			[AUDIT_YEAR]							AS [TimePeriod]	
,			'Yearly'								AS [TimePeriodDesc]
,			'Practice Level'						AS [Indicator_Level]
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]

,			PatientId								AS [PseudoNHSNo]
,			1										AS [Numerator]

INTO		#92872_Numerator_NDA_Type1_8CareProcesses

FROM		[LocalFeeds].[Reporting].[NationalDiabetesAudit_NDA_Core_Data] T1		--MLCSU source datatable
INNER JOIN  EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T2					--BSOL Registered
ON			T1.[DERIVED_GP_PRACTICE_CODE] = T2.GPPracticeCode_Original


WHERE		1=1
AND			T2.ICS_2223 = 'BSOL'
AND			[DERIVED_CLEAN_DIABETES_TYPE] = 1		-- Type 1 Diabetes Flag
AND			[ALL_8_CARE_PROCESSES] = 1				-- Flag if patient has recieved all 8 care process	
AND			[AUDIT_YEAR] IN  ('201415',				-- as per OF Indicator spreadsheet definitions 
							  '201516',
							  '201617',
							  '201718',
							  '201819',
							  '201920',
							  '202021',
							  '202122E4',
							  '202223',
							  '202324E1' ) 

GROUP BY	[DERIVED_CLEAN_ETHNICITY]	
,			[AUDIT_YEAR]				
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]
,			PatientId					

--select * from #92872_Numerator_NDA_Type1_8CareProcesses

-------------------------------------------------------------------------------------------------------------------------------
--STEP 02: UPDATE Ethnicity from local Ethncity Demographic table and source data where missing

UPDATE		T1
SET			T1.[Ethnicity_Code]	= T2.[Ethnic_Code]

FROM		#92872_Numerator_NDA_Type1_8CareProcesses T1

INNER JOIN	EAT_Reporting_BSOL.Demographic.Ethnicity T2
ON			T1.[PseudoNHSNo] = T2.[Pseudo_NHS_Number]


-------------------------------------------------------------------------------------------------------------------------------
--STEP 03: Group up Numerator data 

DROP TABLE IF EXISTS  #92872_Numerator_NDA_Type1_8CareProcesses_Grouped

SELECT		[ReferenceID]
,			[Ethnicity_Code]
,			[TimePeriod]
,			[TimePeriodDesc]
,			[Indicator_Level]
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]
,			SUM([Numerator])					AS [Numerator]

INTO		#92872_Numerator_NDA_Type1_8CareProcesses_Grouped
FROM		#92872_Numerator_NDA_Type1_8CareProcesses

GROUP BY	[ReferenceID]
,			[Ethnicity_Code]
,			[TimePeriod]
,			[TimePeriodDesc]
,			[Indicator_Level]
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]

--SELECT	* FROM #92872_Numerator_NDA_Type1_8CareProcesses_Grouped


-------------------------------------------------------------------------------------------------------------------------------
--STEP 04: [Denominator] Patients at BSOL GP Practices with Type 1 Diabetes 

DROP TABLE IF EXISTS   	#92872_Denominator_NDA_Type1

SELECT		'92872'									AS [ReferenceID]
,			[DERIVED_CLEAN_ETHNICITY]				AS [Ethnicity_Code]
,			[AUDIT_YEAR]							AS [TimePeriod]	
,			'Yearly'								AS [TimePeriodDesc]
,			'Practice Level'						AS [Indicator_Level]
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]
,			PatientId								AS [PseudoNHSNo]
,			1										AS [Denominator]

INTO		#92872_Denominator_NDA_Type1

FROM		[LocalFeeds].[Reporting].[NationalDiabetesAudit_NDA_Core_Data] T1		--MLCSU source datatable
INNER JOIN  EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T2					--BSOL Registered
ON			T1.[DERIVED_GP_PRACTICE_CODE] = T2.GPPracticeCode_Original


WHERE		1=1
AND			T2.ICS_2223 = 'BSOL'
AND			[DERIVED_CLEAN_DIABETES_TYPE] = 1		-- Type 1 Diabetes Flag
AND			[AUDIT_YEAR] IN  ('201415',				-- as per OF Indicator spreadsheet definitions 
							  '201516',
							  '201617',
							  '201718',
							  '201819',
							  '201920',
							  '202021',
							  '202122E4',
							  '202223',
							  '202324E1' ) 

GROUP BY	[DERIVED_CLEAN_ETHNICITY]	
,			[AUDIT_YEAR]				
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]
,			PatientId					

--select * from 	#92872_Denominator_NDA_Type1

-------------------------------------------------------------------------------------------------------------------------------
--STEP 02: UPDATE Ethnicity from local Ethncity Demographic table and source data where missing

UPDATE		T1
SET			T1.[Ethnicity_Code]	= T2.[Ethnic_Code]

FROM		#92872_Denominator_NDA_Type1 T1

INNER JOIN	EAT_Reporting_BSOL.Demographic.Ethnicity T2
ON			T1.[PseudoNHSNo] = T2.[Pseudo_NHS_Number]


-------------------------------------------------------------------------------------------------------------------------------
--STEP 03: Group up Denominator data 

DROP TABLE IF EXISTS  #92872_Denominator_NDA_Type1_Grouped

SELECT		[ReferenceID]
,			[Ethnicity_Code]
,			[TimePeriod]
,			[TimePeriodDesc]
,			[Indicator_Level]
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]
,			SUM([Denominator])							AS [Denominator]
,			CAST(NULL AS FLOAT)							AS [Numerator]
,			CAST(NULL AS varchar(100))					AS [PCN]
,			CAST(NULL AS varchar(50))					AS [Locality_Reg]
,			CAST(LEFT([TimePeriod],6) AS int)			AS [TimePeriod_Cleaned]
,			CAST(NULL AS INT)							AS [IndicatorID]


INTO		#92872_Denominator_NDA_Type1_Grouped
FROM		#92872_Denominator_NDA_Type1

GROUP BY	[ReferenceID]
,			[Ethnicity_Code]
,			[TimePeriod]
,			[TimePeriodDesc]
,			[Indicator_Level]
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]

--SELECT	* FROM #92872_Denominator_NDA_Type1_Grouped

-------------------------------------------------------------------------------------------------------------------------------
--STEP 07:  UPDATE Numerator into Denominator table 

UPDATE		T1
SET			T1.[Numerator] = T2.[Numerator]

FROM		#92872_Denominator_NDA_Type1_Grouped T1

INNER JOIN	#92872_Numerator_NDA_Type1_8CareProcesses_Grouped T2
ON			T1.Ethnicity_Code			= T2.Ethnicity_Code
AND			T1.TimePeriod				= T2.TimePeriod
AND			T1.DERIVED_LSOA				= T2.DERIVED_LSOA
AND			T1.DERIVED_GP_PRACTICE_CODE = T2.DERIVED_GP_PRACTICE_CODE


/*==================================================================================================================================================================
UPDATE PCN and Locality
=================================================================================================================================================================*/

UPDATE		T1
SET			T1.PCN = T2.PCN
,			T1.Locality_Reg = T2.Locality
FROM		#92872_Denominator_NDA_Type1_Grouped  T1
INNER JOIN	EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T2
ON			T1.DERIVED_GP_PRACTICE_CODE = T2.GPPracticeCode_Original
WHERE       ICS_2223 = 'BSOL'


/*==================================================================================================================================================================
UPDATE IndicatorID
=================================================================================================================================================================*/

UPDATE		T1
SET			T1.IndicatorID = T2.IndicatorID

FROM		#92872_Denominator_NDA_Type1_Grouped  T1
INNER JOIN	[EAT_Reporting_BSOL].[OF].[IndicatorList] T2
ON			T1.ReferenceID = T2.ReferenceID

--SELECT TOP 1000	* FROM #92872_Denominator_NDA_Type1_Grouped

/*==================================================================================================================================================================
INSERT FINAL DATA into [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]
=================================================================================================================================================================*/

--INSERT INTO		[EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]

--(				[IndicatorID]
--,				[ReferenceID]
--,				[TimePeriod]
--,				[TimePeriodDesc]
--,				[GP_Practice]
--,				[PCN]
--,				[Locality_Reg]
--,				[Numerator]
--,				[Denominator]
--,				[Indicator_Level]
--,				[LSOA_2011]
--,				[Ethnicity_Code]

--)
--(				
--SELECT			[IndicatorID]
--,				[ReferenceID]
--,				[TimePeriod_Cleaned]
--,				[TimePeriodDesc]
--,				[DERIVED_GP_PRACTICE_CODE]			AS [GP_Practice]
--,				[PCN]
--,				[Locality_Reg]
--,				SUM([Numerator])					AS [Numerator]
--,				SUM([Denominator])					AS [Denominator]
--,				[Indicator_Level]
--,				[DERIVED_LSOA]						AS [LSOA 2011]
--,				[Ethnicity_Code]

--FROM			#92872_Denominator_NDA_Type1_Grouped 

--GROUP BY		[IndicatorID]
--,				[ReferenceID]
--,				[TimePeriod_Cleaned]
--,				[TimePeriodDesc]
--,				[DERIVED_GP_PRACTICE_CODE]
--,				[PCN]
--,				[Locality_Reg]
--,				[Indicator_Level]
--,				[DERIVED_LSOA]
--,				[Ethnicity_Code]

--)



--SELECT *
--  FROM [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]
--  WHERE	IndicatorID =35




