
/*==================================================================================================================================================================
OUTCOMES FRAMEWORK

SSNAP INDICATORS:

	CV8	SSNAP	Number of people receiving mechanical thrombectomy as a % of all Stroke Patients

==================================================================================================================================================================*/


/*==================================================================================================================================================================
CV8		Number of people receiving mechanical thrombectomy as a % of all Stroke Patients

Numerator	= Total number of patients who were given thrombolysis
Denominator = Total number of patients in the cohort (Patients who were not thrombolysed are included in the denominator, 
				regardless of the reason why thrombolysis was not provided)
 
To calculate the numerator, count the number of patients who were given thrombolysis (Q2.6 is “Yes”)

--S1FirstArrivalDateTime Time period YYYY
=================================================================================================================================================================*/

--STEP 01: Numerator for BSOL Resident patients given thrombolysis

DROP TABLE IF EXISTS   	#CV8_Numerator

SELECT		'CV8'													AS [ReferenceID]
,			[S1ETHNICITY]											AS [Ethnicity_Code]
,			YEAR(S1FirstArrivalDateTime)							AS [TimePeriod]		--What field is this derived from?
,			'Other'												AS [TimePeriodDesc]
,			'ICB Level'													AS [Indicator_Level]
,			[CCG_of_Residence]
,			[LSOA_OF_RESIDENCE]
,			[PseudoNHSNo]
,			1													AS	[Numerator]

INTO		#CV8_Numerator
FROM		[EAT_Reporting_BSOL].[National].[SSNAP] T1

WHERE		[CCG_of_Residence] IN ('13P','04X','05P','15E','QHL')		--BSOL Resident patient
AND			[S2THROMBOLYSIS] ='Y'										--patients who were given thrombolysis


GROUP BY	[S1ETHNICITY]										
,			YEAR(S1FirstArrivalDateTime)
,			[CCG_of_Residence]
,			[LSOA_OF_RESIDENCE]
,			[PseudoNHSNo]

--select  * from #CV8_Numerator

-------------------------------------------------------------------------------------------------------------------------------
--STEP 02: UPDATE Ethnicity from local Ethncity Demographic table

UPDATE		T1
SET			T1.[Ethnicity_Code]	= T2.[Ethnic_Code]

FROM		#CV8_Numerator T1

INNER JOIN	EAT_Reporting_BSOL.Demographic.Ethnicity T2
ON			T1.[PseudoNHSNo] = T2.[Pseudo_NHS_Number]


-------------------------------------------------------------------------------------------------------------------------------
--STEP 03: Numerator for BSOL Resident patients given thrombolysis Grouped up

DROP TABLE IF EXISTS   #CV8_Numerator_Grouped

SELECT		[ReferenceID]
,			[Ethnicity_Code]
,			[TimePeriod]
,			[TimePeriodDesc]
,			[Indicator_Level]
,			[CCG_of_Residence]
,			[LSOA_OF_RESIDENCE]
,			SUM([Numerator])				[Numerator]

INTO		#CV8_Numerator_Grouped
FROM		#CV8_Numerator

GROUP BY	[ReferenceID]
,			[Ethnicity_Code]
,			[TimePeriod]
,			[TimePeriodDesc]
,			[Indicator_Level]
,			[CCG_of_Residence]
,			[LSOA_OF_RESIDENCE]

--SELECT	* FROM #CV8_Numerator_Grouped

-------------------------------------------------------------------------------------------------------------------------------
--STEP 04: [Denominator] for BSOL Resident patients

DROP TABLE IF EXISTS   	#CV8_Denominator

SELECT		'CV8'													AS [ReferenceID]
,			[S1ETHNICITY]											AS [Ethnicity_Code]
,			YEAR(S1FirstArrivalDateTime)							AS [TimePeriod]		--What field is this derived from?
,			'Other'												AS [TimePeriodDesc]
,			'ICB Level'														AS [Indicator_Level]
,			[CCG_of_Residence]
,			[LSOA_OF_RESIDENCE]
,			[PseudoNHSNo]
,			1														AS	[Denominator]

INTO		#CV8_Denominator
FROM		[EAT_Reporting_BSOL].[National].[SSNAP] T1

WHERE		[CCG_of_Residence] IN ('13P','04X','05P','15E','QHL')

GROUP BY	[S1ETHNICITY]										
,			YEAR(S1FirstArrivalDateTime)
,			[CCG_of_Residence]
,			[LSOA_OF_RESIDENCE]
,			[PseudoNHSNo]

--select distinct CCG from #CV8_Denominator

-------------------------------------------------------------------------------------------------------------------------------
--STEP 05: UPDATE Ethnicity from local Ethncity Demographic table

UPDATE		T1
SET			T1.[Ethnicity_Code]	= T2.[Ethnic_Code]

FROM		#CV8_Denominator T1

INNER JOIN	EAT_Reporting_BSOL.Demographic.Ethnicity T2
ON			T1.[PseudoNHSNo] = T2.[Pseudo_NHS_Number]


-------------------------------------------------------------------------------------------------------------------------------
--STEP 06:  Denominator for BSOL Resident patients Grouped up

DROP TABLE IF EXISTS  #CV8_Denominator_Grouped

SELECT		74											AS [IndicatorID]
,			[ReferenceID]
,			[Ethnicity_Code]
,			[TimePeriod]
,			[TimePeriodDesc]
,			[Indicator_Level]
,			[CCG_of_Residence]
,			[LSOA_OF_RESIDENCE]
,			SUM([Denominator])							AS [Denominator]
,			CAST(NULL AS FLOAT)							AS [Numerator]

INTO		#CV8_Denominator_Grouped
FROM		#CV8_Denominator

GROUP BY	[ReferenceID]
,			[Ethnicity_Code]
,			[TimePeriod]
,			[TimePeriodDesc]
,			[Indicator_Level]
,			[CCG_of_Residence]
,			[LSOA_OF_RESIDENCE]


-------------------------------------------------------------------------------------------------------------------------------
--STEP 07:  UPDATE Numerator into Denominator table 

UPDATE		T1
SET			T1.[Numerator] = T2.[Numerator]

FROM		#CV8_Denominator_Grouped T1

INNER JOIN	#CV8_Numerator_Grouped T2
ON			T1.Ethnicity_Code	 = T2.Ethnicity_Code
AND			T1.CCG_of_Residence	 = T2.CCG_of_Residence
AND			T1.LSOA_OF_RESIDENCE = T2.LSOA_OF_RESIDENCE


--SELECT	* FROM #CV8_Numerator_Grouped
--SELECT	* FROM #CV8_Denominator_Grouped


/*==================================================================================================================================================================
UPDATE IndicatorID 
=================================================================================================================================================================*/


/*==================================================================================================================================================================
DELETE DATA 
=================================================================================================================================================================*/

--DELETE FROM [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]
--WHERE	[IndicatorID]= 74


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

--FROM			#CV8_Denominator_Grouped
--GROUP BY		IndicatorID
--,				ReferenceID
--,				TimePeriod
--,				TimePeriodDesc
--,				Indicator_Level
--,				LSOA_OF_RESIDENCE				--LSOA 2011
--,				Ethnicity_Code

--)



--SELECT *
--  FROM [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]
--  WHERE	IndicatorID =74

