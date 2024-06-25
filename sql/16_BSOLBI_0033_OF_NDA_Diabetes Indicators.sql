
/*==================================================================================================================================================================
OUTCOMES FRAMEWORK: National Diabetes Audit

	92872	People with Type 1 Diabetes who received all 8 Care Processes


NOTES/CAVEATS WITH DATA:

 - Issues with historical data, i.e. low counts for Audit years pre 2022/23 when compared to nationally published data if using [Parent_Organisation_Code] or [ICB_Code] fields

 - When basing data on CURRENT list of BSOL GP Practices, historical data is more comparable, but does mean we will not have historical GP Practice mapping at time of event.
 - Agreed with RW on 24/05/2024 to base these indicators on CURRENT list of BSOL GP Practices instead of using [Parent_Organisation_Code] or [ICB_Code] in the source data.
 - Use [AUDIT_YEAR] IN  ('201415','201516','201617','201718','201819','201920','202021','202122E4','202223'202324E3') as per Definition from RW
 
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
,			'Financial Year'								AS [TimePeriodDesc]
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
							  '202324E3' ) 

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
,			'Financial Year'								AS [TimePeriodDesc]
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
							  '202324E3' ) 

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


/*==================================================================================================================================================================
OUTCOMES FRAMEWORK: National Diabetes Audit

	92873	People with type 2 diabetes who received all 8 care processes


NOTES/CAVEATS WITH DATA:

 - Issues with historical data, i.e. low counts for Audit years pre 2022/23 when compared to nationally published data if using [Parent_Organisation_Code] or [ICB_Code] fields

 - When basing data on CURRENT list of BSOL GP Practices, historical data is more comparable, but does mean we will not have historical GP Practice mapping at time of event.
 - Agreed with RW on 24/05/2024 to base these indicators on CURRENT list of BSOL GP Practices instead of using [Parent_Organisation_Code] or [ICB_Code] in the source data.
 - Use [AUDIT_YEAR] IN  ('201415','201516','201617','201718','201819','201920','202021','202122E4','202223'202324E3') as per Definition from RW
 
==================================================================================================================================================================*/

/*==================================================================================================================================================================
92873	People with type 2 diabetes who received all 8 care processes

Numerator:		Count of all patients with type 2 diabetes who received all 8 care processes
					- [DERIVED_CLEAN_DIABETES_TYPE] = 2		--Type 2 Diabetes Flag
					- [ALL_8_CARE_PROCESSES] = 1			-- Flag if patient has received all 8 care process	

Denominator:	Count of all patients with Type 2 Diabetes

=================================================================================================================================================================*/

--STEP 01: Numerator: Patients at BSOL GP Practices with Type 2 Diabetes who received all 8 care processes

DROP TABLE IF EXISTS   	#92873_Numerator_NDA_Type2_8CareProcesses

SELECT		'92873'									AS [ReferenceID]
,			[DERIVED_CLEAN_ETHNICITY]				AS [Ethnicity_Code]
,			[AUDIT_YEAR]							AS [TimePeriod]	
,			'Financial Year'								AS [TimePeriodDesc]
,			'Practice Level'						AS [Indicator_Level]
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]

,			PatientId								AS [PseudoNHSNo]
,			1										AS [Numerator]

INTO		#92873_Numerator_NDA_Type2_8CareProcesses

FROM		[LocalFeeds].[Reporting].[NationalDiabetesAudit_NDA_Core_Data] T1		--MLCSU source datatable
INNER JOIN  EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T2					--BSOL Registered
ON			T1.[DERIVED_GP_PRACTICE_CODE] = T2.GPPracticeCode_Original


WHERE		1=1
AND			T2.ICS_2223 = 'BSOL'
AND			[DERIVED_CLEAN_DIABETES_TYPE] = 2		--Type 2 Diabetes Flag
AND			[ALL_8_CARE_PROCESSES] = 1				--Flag if patient has recieved all 8 care process	
AND			[AUDIT_YEAR] IN  ('201415',				--as per OF Indicator spreadsheet definitions 
							  '201516',
							  '201617',
							  '201718',
							  '201819',
							  '201920',
							  '202021',
							  '202122E4',
							  '202223',
							  '202324E3' ) 


GROUP BY	[DERIVED_CLEAN_ETHNICITY]	
,			[AUDIT_YEAR]				
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]
,			PatientId					

--select * from #92873_Numerator_NDA_Type2_8CareProcesses

-------------------------------------------------------------------------------------------------------------------------------
--STEP 02: UPDATE Ethnicity from local Ethncity Demographic table and source data where missing

UPDATE		T1
SET			T1.[Ethnicity_Code]	= T2.[Ethnic_Code]

FROM		#92873_Numerator_NDA_Type2_8CareProcesses T1

INNER JOIN	EAT_Reporting_BSOL.Demographic.Ethnicity T2
ON			T1.[PseudoNHSNo] = T2.[Pseudo_NHS_Number]


-------------------------------------------------------------------------------------------------------------------------------
--STEP 03: Group up Numerator data 

DROP TABLE IF EXISTS  #92873_Numerator_NDA_Type2_8CareProcesses_Grouped

SELECT		[ReferenceID]
,			[Ethnicity_Code]
,			[TimePeriod]
,			[TimePeriodDesc]
,			[Indicator_Level]
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]
,			SUM([Numerator])					AS [Numerator]

INTO		#92873_Numerator_NDA_Type2_8CareProcesses_Grouped
FROM		#92873_Numerator_NDA_Type2_8CareProcesses

GROUP BY	[ReferenceID]
,			[Ethnicity_Code]
,			[TimePeriod]
,			[TimePeriodDesc]
,			[Indicator_Level]
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]

--SELECT	* FROM #92873_Numerator_NDA_Type2_8CareProcesses_Grouped

-------------------------------------------------------------------------------------------------------------------------------
--STEP 04: [Denominator] Patients at BSOL GP Practices with Type 2 Diabetes 

DROP TABLE IF EXISTS   #92873_Denominator_NDA_Type2

SELECT		'92873'									AS [ReferenceID]
,			[DERIVED_CLEAN_ETHNICITY]				AS [Ethnicity_Code]
,			[AUDIT_YEAR]							AS [TimePeriod]	
,			'Financial Year'								AS [TimePeriodDesc]
,			'Practice Level'						AS [Indicator_Level]
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]
,			PatientId								AS [PseudoNHSNo]
,			1										AS [Denominator]

INTO		#92873_Denominator_NDA_Type2

FROM		[LocalFeeds].[Reporting].[NationalDiabetesAudit_NDA_Core_Data] T1		--MLCSU source datatable
INNER JOIN  EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T2					--BSOL Registered
ON			T1.[DERIVED_GP_PRACTICE_CODE] = T2.GPPracticeCode_Original


WHERE		1=1
AND			T2.ICS_2223 = 'BSOL'
AND			[DERIVED_CLEAN_DIABETES_TYPE] = 2		-- Type 2 Diabetes Flag
AND			[AUDIT_YEAR] IN  ('201415',				-- as per OF Indicator spreadsheet definitions 
							  '201516',
							  '201617',
							  '201718',
							  '201819',
							  '201920',
							  '202021',
							  '202122E4',
							  '202223',
							  '202324E3' ) 


GROUP BY	[DERIVED_CLEAN_ETHNICITY]	
,			[AUDIT_YEAR]				
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]
,			PatientId					

--select * from 	#92873_Denominator_NDA_Type2

-------------------------------------------------------------------------------------------------------------------------------
--STEP 02: UPDATE Ethnicity from local Ethncity Demographic table and source data where missing

UPDATE		T1
SET			T1.[Ethnicity_Code]	= T2.[Ethnic_Code]

FROM		#92873_Denominator_NDA_Type2 T1

INNER JOIN	EAT_Reporting_BSOL.Demographic.Ethnicity T2
ON			T1.[PseudoNHSNo] = T2.[Pseudo_NHS_Number]


-------------------------------------------------------------------------------------------------------------------------------
--STEP 03: Group up Denominator data 

DROP TABLE IF EXISTS  #92873_Denominator_NDA_Type2_Grouped

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


INTO		#92873_Denominator_NDA_Type2_Grouped
FROM		#92873_Denominator_NDA_Type2

GROUP BY	[ReferenceID]
,			[Ethnicity_Code]
,			[TimePeriod]
,			[TimePeriodDesc]
,			[Indicator_Level]
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]

--SELECT	* FROM #92873_Denominator_NDA_Type2_Grouped

-------------------------------------------------------------------------------------------------------------------------------
--STEP 07:  UPDATE Numerator into Denominator table 

UPDATE		T1
SET			T1.[Numerator] = T2.[Numerator]

FROM		#92873_Denominator_NDA_Type2_Grouped T1

INNER JOIN	#92873_Numerator_NDA_Type2_8CareProcesses_Grouped T2
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
FROM		#92873_Denominator_NDA_Type2_Grouped  T1
INNER JOIN	EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T2
ON			T1.DERIVED_GP_PRACTICE_CODE = T2.GPPracticeCode_Original
WHERE       ICS_2223 = 'BSOL'


/*==================================================================================================================================================================
UPDATE IndicatorID
=================================================================================================================================================================*/

UPDATE		T1
SET			T1.IndicatorID = T2.IndicatorID

FROM		#92873_Denominator_NDA_Type2_Grouped  T1
INNER JOIN	[EAT_Reporting_BSOL].[OF].[IndicatorList] T2
ON			T1.ReferenceID = T2.ReferenceID


--SELECT	* FROM #92873_Denominator_NDA_Type2_Grouped



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

--FROM			#92873_Denominator_NDA_Type2_Grouped

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
--  WHERE	IndicatorID =36





/*==================================================================================================================================================================
 92874 People with type 1 diabetes who achieved all three treatment targets
=================================================================================================================================================================*/

--STEP 01: Numerator: Patients at BSOL GP Practices with Type 1 Diabetes who achieved all three treatment targets

DROP TABLE IF EXISTS   	#92874_Numerator

SELECT		'92874'									AS [ReferenceID]
,			[DERIVED_CLEAN_ETHNICITY]				AS [Ethnicity_Code]
,			[AUDIT_YEAR]							AS [TimePeriod]	
,			'Financial Year'								AS [TimePeriodDesc]
,			'Practice Level'						AS [Indicator_Level]
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]

,			PatientId								AS [PseudoNHSNo]
,			1										AS [Numerator]

INTO		#92874_Numerator

FROM		[LocalFeeds].[Reporting].[NationalDiabetesAudit_NDA_Core_Data] T1		--MLCSU source datatable
INNER JOIN  EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T2					--BSOL Registered
ON			T1.[DERIVED_GP_PRACTICE_CODE] = T2.GPPracticeCode_Original


WHERE		1=1
AND			T2.ICS_2223 = 'BSOL'
AND			[DERIVED_CLEAN_DIABETES_TYPE] = 1		-- Type 2 Diabetes Flag
AND			[ALL_3_TREATMENT_TARGETS] = 1		    -- Flag if patient has achieved all 3 Treatment targets	
AND			[AUDIT_YEAR] IN  ('201415',				-- as per OF Indicator spreadsheet definitions 
							  '201516',
							  '201617',
							  '201718',
							  '201819',
							  '201920',
							  '202021',
							  '202122E4',
							  '202223',
							  '202324E3' ) 

GROUP BY	[DERIVED_CLEAN_ETHNICITY]	
,			[AUDIT_YEAR]				
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]
,			PatientId					

--select * from #92874_Numerator

-------------------------------------------------------------------------------------------------------------------------------
--STEP 02: UPDATE Ethnicity from local Ethncity Demographic table and source data where missing

UPDATE		T1
SET			T1.[Ethnicity_Code]	= T2.[Ethnic_Code]

FROM		#92874_Numerator T1

INNER JOIN	EAT_Reporting_BSOL.Demographic.Ethnicity T2
ON			T1.[PseudoNHSNo] = T2.[Pseudo_NHS_Number]


-------------------------------------------------------------------------------------------------------------------------------
--STEP 03: Group up Numerator data 

DROP TABLE IF EXISTS  #92874_Numerator_Grouped

SELECT		[ReferenceID]
,			[Ethnicity_Code]
,			[TimePeriod]
,			[TimePeriodDesc]
,			[Indicator_Level]
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]
,			SUM([Numerator])					AS [Numerator]

INTO		#92874_Numerator_Grouped
FROM		#92874_Numerator

GROUP BY	[ReferenceID]
,			[Ethnicity_Code]
,			[TimePeriod]
,			[TimePeriodDesc]
,			[Indicator_Level]
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]

--SELECT	* FROM #92874_Numerator_Grouped


-------------------------------------------------------------------------------------------------------------------------------
--STEP 04: [Denominator] Patients at BSOL GP Practices with Type 1 Diabetes 

DROP TABLE IF EXISTS   	#92874_Denominator

SELECT		'92874'									AS [ReferenceID]
,			[DERIVED_CLEAN_ETHNICITY]				AS [Ethnicity_Code]
,			[AUDIT_YEAR]							AS [TimePeriod]	
,			'Financial Year'								AS [TimePeriodDesc]
,			'Practice Level'						AS [Indicator_Level]
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]
,			PatientId								AS [PseudoNHSNo]
,			1										AS [Denominator]

INTO		#92874_Denominator

FROM		[LocalFeeds].[Reporting].[NationalDiabetesAudit_NDA_Core_Data] T1		--MLCSU source datatable
INNER JOIN  EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T2					--BSOL Registered
ON			T1.[DERIVED_GP_PRACTICE_CODE] = T2.GPPracticeCode_Original


WHERE		1=1
AND			T2.ICS_2223 = 'BSOL'
AND			[DERIVED_CLEAN_DIABETES_TYPE] = 2		-- Type 2 Diabetes Flag
AND			[AUDIT_YEAR] IN  ('201415',				-- as per OF Indicator spreadsheet definitions 
							  '201516',
							  '201617',
							  '201718',
							  '201819',
							  '201920',
							  '202021',
							  '202122E4',
							  '202223',
							  '202324E3' ) 

GROUP BY	[DERIVED_CLEAN_ETHNICITY]	
,			[AUDIT_YEAR]				
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]
,			PatientId					

--select * from 	#92874_Denominator

-------------------------------------------------------------------------------------------------------------------------------
--STEP 02: UPDATE Ethnicity from local Ethncity Demographic table and source data where missing

UPDATE		T1
SET			T1.[Ethnicity_Code]	= T2.[Ethnic_Code]

FROM		#92874_Denominator T1

INNER JOIN	EAT_Reporting_BSOL.Demographic.Ethnicity T2
ON			T1.[PseudoNHSNo] = T2.[Pseudo_NHS_Number]


-------------------------------------------------------------------------------------------------------------------------------
--STEP 03: Group up Denominator data 

DROP TABLE IF EXISTS  #92874_Denominator_Grouped

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


INTO		#92874_Denominator_Grouped
FROM		#92874_Denominator

GROUP BY	[ReferenceID]
,			[Ethnicity_Code]
,			[TimePeriod]
,			[TimePeriodDesc]
,			[Indicator_Level]
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]

--SELECT	* FROM #92874_Denominator_Grouped

-------------------------------------------------------------------------------------------------------------------------------
--STEP 07:  UPDATE Numerator into Denominator table 

UPDATE		T1
SET			T1.[Numerator] = T2.[Numerator]

FROM		#92874_Denominator_Grouped T1

INNER JOIN	#92874_Numerator_Grouped T2
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
FROM		#92874_Denominator_Grouped  T1
INNER JOIN	EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T2
ON			T1.DERIVED_GP_PRACTICE_CODE = T2.GPPracticeCode_Original
WHERE       ICS_2223 = 'BSOL'


/*==================================================================================================================================================================
UPDATE IndicatorID
=================================================================================================================================================================*/

UPDATE		T1
SET			T1.IndicatorID = T2.IndicatorID

FROM		#92874_Denominator_Grouped  T1
INNER JOIN	[EAT_Reporting_BSOL].[OF].[IndicatorList] T2
ON			T1.ReferenceID = T2.ReferenceID

--SELECT TOP 1000	* FROM #92874_Denominator_Grouped WHERE Numerator IS NOT NULL

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

--FROM			#92874_Denominator_Grouped 

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
--   WHERE IndicatorID =37







/*==================================================================================================================================================================
  92875 -- People with type 2 diabetes who achieved all three treatment targets	
=================================================================================================================================================================*/

--STEP 01: Numerator: Patients at BSOL GP Practices with Type 1 Diabetes who received all 8 care processes

DROP TABLE IF EXISTS   	#92875_Numerator

SELECT		'92875'									AS [ReferenceID]
,			[DERIVED_CLEAN_ETHNICITY]				AS [Ethnicity_Code]
,			[AUDIT_YEAR]							AS [TimePeriod]	
,			'Financial Year'								AS [TimePeriodDesc]
,			'Practice Level'						AS [Indicator_Level]
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]

,			PatientId								AS [PseudoNHSNo]
,			1										AS [Numerator]

INTO		#92875_Numerator

FROM		[LocalFeeds].[Reporting].[NationalDiabetesAudit_NDA_Core_Data] T1		--MLCSU source datatable
INNER JOIN  EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T2					--BSOL Registered
ON			T1.[DERIVED_GP_PRACTICE_CODE] = T2.GPPracticeCode_Original


WHERE		1=1
AND			T2.ICS_2223 = 'BSOL'
AND			[DERIVED_CLEAN_DIABETES_TYPE] = 2		-- Type 2 Diabetes Flag
AND			[ALL_3_TREATMENT_TARGETS] = 1				-- Flag if patient has achieved all 3 Treatment targets	
AND			[AUDIT_YEAR] IN  ('201415',				-- as per OF Indicator spreadsheet definitions 
							  '201516',
							  '201617',
							  '201718',
							  '201819',
							  '201920',
							  '202021',
							  '202122E4',
							  '202223',
							  '202324E3' ) 

GROUP BY	[DERIVED_CLEAN_ETHNICITY]	
,			[AUDIT_YEAR]				
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]
,			PatientId					

--select * from #92875_Numerator

-------------------------------------------------------------------------------------------------------------------------------
--STEP 02: UPDATE Ethnicity from local Ethncity Demographic table and source data where missing

UPDATE		T1
SET			T1.[Ethnicity_Code]	= T2.[Ethnic_Code]

FROM		#92875_Numerator T1

INNER JOIN	EAT_Reporting_BSOL.Demographic.Ethnicity T2
ON			T1.[PseudoNHSNo] = T2.[Pseudo_NHS_Number]


-------------------------------------------------------------------------------------------------------------------------------
--STEP 03: Group up Numerator data 

DROP TABLE IF EXISTS  #92875_Numerator_Grouped

SELECT		[ReferenceID]
,			[Ethnicity_Code]
,			[TimePeriod]
,			[TimePeriodDesc]
,			[Indicator_Level]
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]
,			SUM([Numerator])					AS [Numerator]

INTO		#92875_Numerator_Grouped
FROM		#92875_Numerator

GROUP BY	[ReferenceID]
,			[Ethnicity_Code]
,			[TimePeriod]
,			[TimePeriodDesc]
,			[Indicator_Level]
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]

--SELECT	* FROM #92875_Numerator_Grouped


-------------------------------------------------------------------------------------------------------------------------------
--STEP 04: [Denominator] Patients at BSOL GP Practices with Type 1 Diabetes 

DROP TABLE IF EXISTS   	#92875_Denominator

SELECT		'92875'									AS [ReferenceID]
,			[DERIVED_CLEAN_ETHNICITY]				AS [Ethnicity_Code]
,			[AUDIT_YEAR]							AS [TimePeriod]	
,			'Financial Year'								AS [TimePeriodDesc]
,			'Practice Level'						AS [Indicator_Level]
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]
,			PatientId								AS [PseudoNHSNo]
,			1										AS [Denominator]

INTO		#92875_Denominator

FROM		[LocalFeeds].[Reporting].[NationalDiabetesAudit_NDA_Core_Data] T1		--MLCSU source datatable
INNER JOIN  EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T2					--BSOL Registered
ON			T1.[DERIVED_GP_PRACTICE_CODE] = T2.GPPracticeCode_Original


WHERE		1=1
AND			T2.ICS_2223 = 'BSOL'
AND			[DERIVED_CLEAN_DIABETES_TYPE] = 2		-- Type 2 Diabetes Flag
AND			[AUDIT_YEAR] IN  ('201415',				-- as per OF Indicator spreadsheet definitions 
							  '201516',
							  '201617',
							  '201718',
							  '201819',
							  '201920',
							  '202021',
							  '202122E4',
							  '202223',
							  '202324E3' ) 

GROUP BY	[DERIVED_CLEAN_ETHNICITY]	
,			[AUDIT_YEAR]				
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]
,			PatientId					

--select * from 	#92875_Denominator

-------------------------------------------------------------------------------------------------------------------------------
--STEP 02: UPDATE Ethnicity from local Ethncity Demographic table and source data where missing

UPDATE		T1
SET			T1.[Ethnicity_Code]	= T2.[Ethnic_Code]

FROM		#92875_Denominator T1

INNER JOIN	EAT_Reporting_BSOL.Demographic.Ethnicity T2
ON			T1.[PseudoNHSNo] = T2.[Pseudo_NHS_Number]


-------------------------------------------------------------------------------------------------------------------------------
--STEP 03: Group up Denominator data 

DROP TABLE IF EXISTS  #92875_Denominator_Grouped

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


INTO		#92875_Denominator_Grouped
FROM		#92875_Denominator

GROUP BY	[ReferenceID]
,			[Ethnicity_Code]
,			[TimePeriod]
,			[TimePeriodDesc]
,			[Indicator_Level]
,			[DERIVED_LSOA]
,			[DERIVED_GP_PRACTICE_CODE]

--SELECT	* FROM #92875_Denominator_Grouped

-------------------------------------------------------------------------------------------------------------------------------
--STEP 07:  UPDATE Numerator into Denominator table 

UPDATE		T1
SET			T1.[Numerator] = T2.[Numerator]

FROM		#92875_Denominator_Grouped T1

INNER JOIN	#92875_Numerator_Grouped T2
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
FROM		#92875_Denominator_Grouped  T1
INNER JOIN	EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T2
ON			T1.DERIVED_GP_PRACTICE_CODE = T2.GPPracticeCode_Original
WHERE       ICS_2223 = 'BSOL'


/*==================================================================================================================================================================
UPDATE IndicatorID
=================================================================================================================================================================*/

UPDATE		T1
SET			T1.IndicatorID = T2.IndicatorID

FROM		#92875_Denominator_Grouped  T1
INNER JOIN	[EAT_Reporting_BSOL].[OF].[IndicatorList] T2
ON			T1.ReferenceID = T2.ReferenceID

--SELECT TOP 1000	* FROM #92875_Denominator_Grouped

/*==================================================================================================================================================================
INSERT FINAL DATA into [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]
=================================================================================================================================================================*/

INSERT INTO		[EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]

(				[IndicatorID]
,				[ReferenceID]
,				[TimePeriod]
,				[TimePeriodDesc]
,				[GP_Practice]
,				[PCN]
,				[Locality_Reg]
,				[Numerator]
,				[Denominator]
,				[Indicator_Level]
,				[LSOA_2011]
,				[Ethnicity_Code]

)
(				
SELECT			[IndicatorID]
,				[ReferenceID]
,				[TimePeriod_Cleaned]
,				[TimePeriodDesc]
,				[DERIVED_GP_PRACTICE_CODE]			AS [GP_Practice]
,				[PCN]
,				[Locality_Reg]
,				SUM([Numerator])					AS [Numerator]
,				SUM([Denominator])					AS [Denominator]
,				[Indicator_Level]
,				[DERIVED_LSOA]						AS [LSOA 2011]
,				[Ethnicity_Code]

FROM			#92875_Denominator_Grouped 

GROUP BY		[IndicatorID]
,				[ReferenceID]
,				[TimePeriod_Cleaned]
,				[TimePeriodDesc]
,				[DERIVED_GP_PRACTICE_CODE]
,				[PCN]
,				[Locality_Reg]
,				[Indicator_Level]
,				[DERIVED_LSOA]
,				[Ethnicity_Code]

)



--SELECT *
--  FROM [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]
-- WHERE IndicatorID = 38


/*=================================================================================================
  UPDATEs for all 4 NDA Diabetes Indicators with Predefined Denominator		
=================================================================================================*/

  UPDATE T1
     SET T1.LSOA_2021 = T2.[LSOA21CD]
	FROM [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator] T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2011_to_LSOA_2021] T2
      ON T1.LSOA_2011 = T2.LSOA11CD
   WHERE T1.ReferenceID IN (92872,92873,92874,92875)


  UPDATE [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]
     SET TimePeriod = '2014-15'
   WHERE TimePeriod = '201415'
     AND ReferenceID IN (92872,92873,92874,92875)

  UPDATE [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]
     SET TimePeriod = '2015-16'
   WHERE TimePeriod = '201516'
     AND ReferenceID IN (92872,92873,92874,92875)

  UPDATE [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]
     SET TimePeriod = '2016-17'
   WHERE TimePeriod = '201617'
     AND ReferenceID IN (92872,92873,92874,92875)

  UPDATE [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]
     SET TimePeriod = '2017-18'
   WHERE TimePeriod = '201718'
     AND ReferenceID IN (92872,92873,92874,92875)

  UPDATE [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]
     SET TimePeriod = '2018-19'
   WHERE TimePeriod = '201819'
     AND ReferenceID IN (92872,92873,92874,92875)

  UPDATE [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]
     SET TimePeriod = '2019-20'
   WHERE TimePeriod = '201920'
     AND ReferenceID IN (92872,92873,92874,92875)

  UPDATE [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]
     SET TimePeriod = '2020-21'
   WHERE TimePeriod = '202021'
     AND ReferenceID IN (92872,92873,92874,92875)

  UPDATE [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]
     SET TimePeriod = '2021-22'
   WHERE TimePeriod = '202122'
     AND ReferenceID IN (92872,92873,92874,92875)

  UPDATE [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]
     SET TimePeriod = '2022-23'
   WHERE TimePeriod = '202223'
     AND ReferenceID IN (92872,92873,92874,92875)

  UPDATE [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]
     SET TimePeriod = '2023-24'
   WHERE TimePeriod = '202324'
     AND ReferenceID IN (92872,92873,92874,92875)

 
/*=================================================================================================
  93209 -- Percentage of people with type 2 diabetes aged 40 to 64		
=================================================================================================*/
 
 DROP TABLE IF EXISTS #Dataset
                       ,#Dataset_Final


  SELECT CONVERT(INT,NULL) as IndicatorID
        ,'93209' as ReferenceID
		,NULL as TimePeriod
		,AUDIT_YEAR as Financial_Year
		,DERIVED_CLEAN_ETHNICITY as Ethnicity_Code 
		,CONVERT(VARCHAR(20),DERIVED_CLEAN_SEX) as Gender
		,AGE
		,DERIVED_LSOA as LSOA_2011
		,CONVERT(VARCHAR(10),NULL) as LSOA_2021
		,CONVERT(VARCHAR(9),NULL)  as Ward_Code
		,CONVERT(VARCHAR(53),NULL) as Ward_Name		
		,CONVERT(VARCHAR(9),NULL)  as LAD_Code
		,CONVERT(VARCHAR(10),NULL) as LAD_Name
		,CONVERT(VARCHAR(10),NULL) as Locality_Res		
        ,DERIVED_GP_PRACTICE_CODE  as GP_Practice
		,PatientId
	INTO #Dataset
    FROM localfeeds.[Reporting].[NationalDiabetesAudit_NDA_Core_Data] T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2011_BSOL_Codes] T2  
      ON T1.DERIVED_LSOA = T2.CODE  -- BSOL Residents
   WHERE T1.DERIVED_CLEAN_DIABETES_TYPE = 2 
     AND age >= 40 AND age <=64
     AND AUDIT_YEAR in ('201415','201516','201617','201718','201819'
	                   ,'201920','202021','202122E4','202223','202324E3')

  UPDATE #Dataset
     SET Ethnicity_Code = T2.Ethnic_Code
    FROM #Dataset T1
   INNER JOIN EAT_Reporting_BSOL.Demographic.Ethnicity T2
      ON T1.PatientId = T2.Pseudo_NHS_Number

  UPDATE #Dataset
     SET Financial_Year = '2021-22'
   WHERE Financial_Year = '202122E4'

  UPDATE #Dataset
     SET Financial_Year = '2023-24'
   WHERE Financial_Year = '202324E3'

  UPDATE #Dataset
     SET Financial_Year = '2018-19'
   WHERE Financial_Year = '201819'

  UPDATE #Dataset
     SET Financial_Year = '2014-15'
   WHERE Financial_Year = '201415'

  UPDATE #Dataset
     SET Financial_Year = '2022-23'
   WHERE Financial_Year = '202223'

  UPDATE #Dataset
     SET Financial_Year = '2016-17'
   WHERE Financial_Year = '201617'

  UPDATE #Dataset
     SET Financial_Year = '2015-16'
   WHERE Financial_Year = '201516'

  UPDATE #Dataset
     SET Financial_Year = '2019-20'
   WHERE Financial_Year = '201920'

  UPDATE #Dataset
     SET Financial_Year = '2023-24'
   WHERE Financial_Year = '202324'

  UPDATE #Dataset
     SET Financial_Year = '2020-21'
   WHERE Financial_Year = '202021'

  UPDATE #Dataset
     SET Financial_Year = '2017-18'
   WHERE Financial_Year = '201718'

  UPDATE #Dataset
     SET Financial_Year = '2021-22'
   WHERE Financial_Year = '202122'

  UPDATE #Dataset
     SET Gender = 'Not Known'
   WHERE Gender = '0'

  UPDATE #Dataset
     SET Gender = 'Male'
   WHERE Gender = '1'

  UPDATE #Dataset
     SET Gender = 'Female'
   WHERE Gender = '2'

  UPDATE #Dataset
     SET Gender = 'Not Specified'
   WHERE Gender = '9'

  UPDATE T1
     SET T1.LSOA_2021 = T2.[LSOA21CD]
	FROM #Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2011_to_LSOA_2021] T2
      ON T1.LSOA_2011 = T2.LSOA11CD

  UPDATE T1
     SET T1.[Ward_Code]	= T2.[WD22CD]
        ,T1.[Ward_Name]	= T2.[WD22NM]
        ,T1.[LAD_Code]	= T2.LAD22CD
        ,T1.[LAD_Name]  = T2.LAD22NM
    FROM #Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_WARD_LAD] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]

  UPDATE T1
     SET T1.[Locality_Res]	= T2.[Locality]
    FROM #Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_BSOL_to_Constituency_2025_Locality] T2
      ON T1.[LSOA_2021] = T2.[LSOA21CD]
 
  UPDATE T1
     SET IndicatorID = T2.IndicatorID
	FROM #Dataset T1
   INNER JOIN [EAT_Reporting_BSOL].[OF].[IndicatorList] T2
      ON T1.ReferenceID = T2.ReferenceID



  SELECT IndicatorID
        ,ReferenceID
		,TimePeriod
		,Financial_Year
		,Ethnicity_Code
		,Gender
		,Age
		,LSOA_2011
		,LSOA_2021
		,Ward_Code
		,Ward_Name
		,LAD_Code
		,LAD_Name
		,Locality_Res
		,GP_Practice 
		,SUM(1) as Numerator
	INTO #Dataset_Final
    FROM #Dataset
   GROUP BY IndicatorID
           ,ReferenceID
		   ,TimePeriod
		   ,Financial_Year
		   ,Ethnicity_Code
		   ,Gender
		   ,Age
		   ,LSOA_2011
		   ,LSOA_2021
		   ,Ward_Code
		   ,Ward_Name
		   ,LAD_Code
		   ,LAD_Name
		   ,Locality_Res
		   ,GP_Practice


  SELECT TOP 1000 *
    FROM #Dataset_Final

  INSERT INTO [EAT_Reporting_BSOL].[OF].[IndicatorData] 
        (				
		 [IndicatorID]
        ,[ReferenceID]
        ,[TimePeriod] 
        ,[Financial_Year]
        ,[Ethnicity_Code]
        ,[Gender]	
        ,[Age]		
        ,[LSOA_2011] 
        ,[LSOA_2021] 
        ,[Ward_Code] 
        ,[Ward_Name] 
        ,[LAD_Code]
        ,[LAD_Name]
        ,[Locality_Res]
        ,[GP_Practice]	
        ,[Numerator]		
        )
		(
  SELECT [IndicatorID]
        ,[ReferenceID]
        ,[TimePeriod] 
        ,[Financial_Year]
        ,[Ethnicity_Code]
        ,[Gender]	
        ,[Age]		
        ,[LSOA_2011] 
        ,[LSOA_2021] 
        ,[Ward_Code] 
        ,[Ward_Name] 
        ,[LAD_Code]
        ,[LAD_Name]
        ,[Locality_Res]
        ,[GP_Practice]	
        ,[Numerator]	
    FROM #Dataset_Final
	    )




  



