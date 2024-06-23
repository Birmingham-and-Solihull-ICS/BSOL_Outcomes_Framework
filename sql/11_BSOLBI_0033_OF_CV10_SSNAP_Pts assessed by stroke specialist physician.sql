
/*==================================================================================================================================================================
OUTCOMES FRAMEWORK: SSNAP INDICATORS:

	CV10	SSNAP	Proportion of patients assessed by a stroke specialist consultant physician within 24h of clock start

==================================================================================================================================================================*/


/*==================================================================================================================================================================
CV10	SSNAP	Proportion of patients assessed by a stroke specialist consultant physician within 24h of clock start

Numerator	= number of patients who were assessed by a stroke specialist consultant physician within 24h of clock start.
Denominator = all the patients in the cohort. Patients who are not assessed by a stroke consultant are included in the denominator.
                          
To calculate whether a patient is included in the numerator:

Part01: For newly arrived patients, the difference between:
			- the date and time of assessment by stroke consultant (Q 3.3)
			- date and time of arrival (Q 1.13)
		must be greater than or equal to 0 minutes and less than or equal to 1440 minutes.

	
Part02: For patients already in hospital at the time of their stroke (Q 1.10 is ‘Yes’),the difference between:
			- date and time of assessment by stroke consultant (Q 3.3)
			- and the date and time of symptom onset (Q 1.11)
		must be greater or equal to 0 minutes and less than or equal to 1440 minutes.


Key Fields in the SSNAP dataset:

S1FIRSTARRIVALDATETIME:					timedate_of_arrival
S1OnsetInHospita:						Was the patient already an inpatient at the time of stroke? (Y/N)
S3StrokeConsultantAssessedDateTime:		If first contact with consultant was not in person, date & time first assessed by stroke specialist consultant physician in person
S1OnsetDateTime:						Date/ time of onset/ awareness of symptoms

=================================================================================================================================================================*/


/*=================================================================================================================================================================
STEP 01: Number of patients who were assessed by a stroke specialist consultant physician within 24h of clock start.
 - newly arrived patients
 - patients already in hospital at the time of their stroke
=================================================================================================================================================================*/

DROP TABLE IF EXISTS   #CV10_Numerator_Pts_Level

--Part01: For newly arrived patients,
SELECT		'CV10'													AS [ReferenceID]
,			[S1ETHNICITY]											AS [Ethnicity_Code]
,			YEAR(S1FirstArrivalDateTime)							AS [TimePeriod]		
,			'Yearly'												AS [TimePeriodDesc]
,			'ICB Level'												AS [Indicator_Level]
,			[CCG_of_Residence]
,			[LSOA_OF_RESIDENCE]
,			[PseudoNHSNo]
,			1														AS	[Numerator]

INTO		#CV10_Numerator_Pts_Level
FROM		[EAT_Reporting_BSOL].[National].[SSNAP] T1

WHERE		[CCG_of_Residence] IN ('13P','04X','05P','15E','QHL')		--BSOL Resident patient
AND			S1OnsetInHospital = 'N'										--Was the patient already an inpatient at the time of stroke? 

AND			DATEDIFF (MINUTE, TRY_CONVERT(DATETIME2,S1FIRSTARRIVALDATETIME), TRY_CONVERT(DATETIME2,S3StrokeConsultantAssessedDateTime)) >= 0	--DateTime of Arrival AND DateTime of assessment by stroke consultant 
AND			DATEDIFF (MINUTE, TRY_CONVERT(DATETIME2,S1FIRSTARRIVALDATETIME), TRY_CONVERT(DATETIME2,S3StrokeConsultantAssessedDateTime)) <  1440	--DateTime of Arrival AND DateTime of assessment by stroke consultant 

GROUP BY	[S1ETHNICITY]										
,			YEAR(S1FirstArrivalDateTime)
,			[CCG_of_Residence]
,			[LSOA_OF_RESIDENCE]
,			[PseudoNHSNo]

-----------------------------------------------------------------------------------------------------------------------------------------------------------------
UNION ALL

--Part02: For patients already in hospital at the time of their stroke
SELECT		'CV10'													AS [ReferenceID]
,			[S1ETHNICITY]											AS [Ethnicity_Code]
,			YEAR(S1FirstArrivalDateTime)							AS [TimePeriod]		--What field is this derived from?
,			'Yearly'												AS [TimePeriodDesc]
,			'ICB Level'												AS [Indicator_Level]
,			[CCG_of_Residence]
,			[LSOA_OF_RESIDENCE]
,			[PseudoNHSNo]
,			1														AS	[Numerator]

FROM		[EAT_Reporting_BSOL].[National].[SSNAP] T1

WHERE		[CCG_of_Residence] IN ('13P','04X','05P','15E','QHL')		--BSOL Resident patient
AND			S1OnsetInHospital = 'Y'										--Was the patient already an inpatient at the time of stroke? 
AND			DATEDIFF (MINUTE, TRY_CONVERT(DATETIME2,S3StrokeConsultantAssessedDateTime), TRY_CONVERT(DATETIME2,S1OnsetDateTime)) >= 0		--DateTime of assessment by stroke consultant AND DateTime Symptom Onset
AND			DATEDIFF (MINUTE, TRY_CONVERT(DATETIME2,S3StrokeConsultantAssessedDateTime), TRY_CONVERT(DATETIME2,S1OnsetDateTime)) <  1440	--DateTime of assessment by stroke consultant AND DateTime Symptom Onset

GROUP BY	[S1ETHNICITY]										
,			YEAR(S1FirstArrivalDateTime)
,			[CCG_of_Residence]
,			[LSOA_OF_RESIDENCE]
,			[PseudoNHSNo]


--select  * from #CV10_Numerator_Pts_Level

-------------------------------------------------------------------------------------------------------------------------------
--STEP 02: UPDATE Ethnicity from local Ethncity Demographic table for Numerator

UPDATE		T1
SET			T1.[Ethnicity_Code]	= T2.[Ethnic_Code]

FROM		#CV10_Numerator_Pts_Level T1

INNER JOIN	EAT_Reporting_BSOL.Demographic.Ethnicity T2
ON			T1.[PseudoNHSNo] = T2.[Pseudo_NHS_Number]


-------------------------------------------------------------------------------------------------------------------------------
--STEP 03: Numerator for BSOL Resident patients who were assessed by a stroke specialist consultant physician within 24h of clock start.

DROP TABLE IF EXISTS   #CV10_Numerator_Grouped

SELECT		[ReferenceID]
,			[Ethnicity_Code]
,			[TimePeriod]
,			[TimePeriodDesc]
,			[Indicator_Level]
,			[CCG_of_Residence]
,			[LSOA_OF_RESIDENCE]
,			SUM([Numerator])				[Numerator]

INTO		#CV10_Numerator_Grouped
FROM		#CV10_Numerator_Pts_Level

GROUP BY	[ReferenceID]
,			[Ethnicity_Code]
,			[TimePeriod]
,			[TimePeriodDesc]
,			[Indicator_Level]
,			[CCG_of_Residence]
,			[LSOA_OF_RESIDENCE]

--SELECT	* FROM #CV10_Numerator_Grouped

-------------------------------------------------------------------------------------------------------------------------------
--STEP 04: [Denominator] for BSOL Resident patients

DROP TABLE IF EXISTS   	#CV10_Denominator_Pts_Level

SELECT		'CV10'													AS [ReferenceID]
,			[S1ETHNICITY]											AS [Ethnicity_Code]
,			YEAR(S1FirstArrivalDateTime)							AS [TimePeriod]		--What field is this derived from?
,			'Yearly'												AS [TimePeriodDesc]
,			'ICB Level'												AS [Indicator_Level]
,			[CCG_of_Residence]
,			[LSOA_OF_RESIDENCE]
,			[PseudoNHSNo]
,			1														AS	[Denominator]

INTO		#CV10_Denominator_Pts_Level
FROM		[EAT_Reporting_BSOL].[National].[SSNAP] T1

WHERE		[CCG_of_Residence] IN ('13P','04X','05P','15E','QHL')

GROUP BY	[S1ETHNICITY]										
,			YEAR(S1FirstArrivalDateTime)
,			[CCG_of_Residence]
,			[LSOA_OF_RESIDENCE]
,			[PseudoNHSNo]

--select * from #CV10_Denominator_Pts_Level

-------------------------------------------------------------------------------------------------------------------------------
--STEP 05: UPDATE Ethnicity from local Ethncity Demographic table for Denominator

UPDATE		T1
SET			T1.[Ethnicity_Code]	= T2.[Ethnic_Code]

FROM		#CV10_Denominator_Pts_Level T1

INNER JOIN	EAT_Reporting_BSOL.Demographic.Ethnicity T2
ON			T1.[PseudoNHSNo] = T2.[Pseudo_NHS_Number]


-------------------------------------------------------------------------------------------------------------------------------
--STEP 06:  Denominator for BSOL Resident patients Grouped up

DROP TABLE IF EXISTS  #CV10_Denominator_Grouped

SELECT		78											AS [IndicatorID]
,			[ReferenceID]
,			[Ethnicity_Code]
,			[TimePeriod]
,			[TimePeriodDesc]
,			[Indicator_Level]
,			[CCG_of_Residence]
,			[LSOA_OF_RESIDENCE]
,			SUM([Denominator])							AS [Denominator]
,			CAST(NULL AS FLOAT)							AS [Numerator]

INTO		#CV10_Denominator_Grouped
FROM		#CV10_Denominator_Pts_Level

GROUP BY	[ReferenceID]
,			[Ethnicity_Code]
,			[TimePeriod]
,			[TimePeriodDesc]
,			[Indicator_Level]
,			[CCG_of_Residence]
,			[LSOA_OF_RESIDENCE]

--select * from #CV10_Denominator_Grouped

-------------------------------------------------------------------------------------------------------------------------------
--STEP 07:  UPDATE Numerator into Denominator table 

UPDATE		T1
SET			T1.[Numerator] = T2.[Numerator]

FROM		#CV10_Denominator_Grouped T1

INNER JOIN	#CV10_Numerator_Grouped T2
ON			T1.Ethnicity_Code	 = T2.Ethnicity_Code
AND			T1.CCG_of_Residence	 = T2.CCG_of_Residence
AND			T1.LSOA_OF_RESIDENCE = T2.LSOA_OF_RESIDENCE
AND			T1.TimePeriod		 = T2.TimePeriod


--SELECT	* FROM #CV10_Denominator_Grouped 


/*==================================================================================================================================================================
UPDATE IndicatorID 
=================================================================================================================================================================*/


/*==================================================================================================================================================================
DELETE DATA 
=================================================================================================================================================================*/

--DELETE FROM [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]
--WHERE	[IndicatorID]= 78


/*==================================================================================================================================================================
INSERT FINAL DATA into [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]
=================================================================================================================================================================*/

--INSERT INTO		[EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]

--(				[IndicatorID]
----,				[ReferenceID]
--,				[TimePeriod]
--,				[TimePeriodDesc]
--,				[Numerator]
--,				[Denominator]
--,				[Indicator_Level]
--,				[LSOA_2011]
--,				[Ethnicity_Code]

--)
--(				
--SELECT			IndicatorID
----,				ReferenceID
--,				TimePeriod
--,				TimePeriodDesc
--,				SUM([Numerator])					AS [Numerator]
--,				SUM([Denominator])					AS [Denominator]
--,				Indicator_Level
--,				LSOA_OF_RESIDENCE				--LSOA 2011
--,				Ethnicity_Code

--FROM			#CV10_Denominator_Grouped
--GROUP BY		IndicatorID
----,				ReferenceID
--,				TimePeriod
--,				TimePeriodDesc
--,				Indicator_Level
--,				LSOA_OF_RESIDENCE				--LSOA 2011
--,				Ethnicity_Code

--)



--SELECT *
--  FROM [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]
--  WHERE	IndicatorID =78

