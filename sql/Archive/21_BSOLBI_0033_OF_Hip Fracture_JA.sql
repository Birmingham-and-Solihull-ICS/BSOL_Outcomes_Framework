


/*=================================================================================================
 IndicatorID 114-ReferenceID  41401 - Reduce hip fractures in people age 65yrs and over		

 The number of first finished emergency admission episodes in patients aged 65 and over at the time 
 of admission (episode order number equals 1, admission method starts with 2), with a recording of 
 fractured neck of femur classified by primary diagnosis code (ICD10 S72.0 Fracture of neck of femur;
 S72.1 Pertrochanteric fracture and S72.2 Subtrochanteric fracture) in financial year in which episode ended.
=================================================================================================*/


/*==============================================================================================================================================================
DECLARE START AND END MONTHS
==============================================================================================================================================================*/

DECLARE			@StartMonth		INT
DECLARE			@EndMonth		INT
SET				@StartMonth =	201904
SET				@EndMonth	=	202403


/*==================================================================================================================================================================
CREATE TEMP STAGING DATA TABLES
=================================================================================================================================================================*/

DROP TABLE IF EXISTS   	#BSOL_OF_tbIndicator_PtsCohort_IP
DROP TABLE IF EXISTS   	#BSOL_OF_tbStaging_NumeratorData

CREATE TABLE			#BSOL_OF_tbIndicator_PtsCohort_IP (EpisodeID BIGINT NOT NULL)

CREATE TABLE			#BSOL_OF_tbStaging_NumeratorData 

(						[IndicatorID]			INT
,						[ReferenceID]			INT
,						[TimePeriod]			INT
,						[Financial_Year]		VARCHAR (7)
,						[Ethnicity_Code]		VARCHAR (5)
,						[Gender]				VARCHAR (50)
,						[Age]					INT
,						[LSOA_2011]				VARCHAR (9)	
,						[LSOA_2021]				VARCHAR (9)
,						[Ward_Code]				VARCHAR (9)
,						[Ward_Name]				VARCHAR (53)
,						[Locality_Res]			VARCHAR (10)
,						[GP_Practice]			VARCHAR (10)
,						[Numerator]				FLOAT
,						[LAD_Code]				VARCHAR (9)	
,						[LAD_Name]				VARCHAR (10)
,						EpisodeID				BIGINT NOT NULL 
)


/*==================================================================================================================================================================
INSERT Inpatient Admission Episode Ids into Staging temp table for all Birmingham and Solihull Residents
=================================================================================================================================================================*/

INSERT			INTO #BSOL_OF_tbIndicator_PtsCohort_IP   (EpisodeID)
(
SELECT			T1.EpisodeID
FROM			[EAT_Reporting].[dbo].[tbInpatientEpisodes] T1
INNER JOIN		[EAT_Reporting].[dbo].[tbIPPatientGeography] T2		--New Patient Geography for Inpatients dataset following Unified SUS switch over
				--[EAT_Reporting].[dbo].[tbPatientGeography] T2		--Patient Geography data table pre-Unified SUS switch over
ON				T1.EpisodeId = T2.EpisodeId

WHERE			ReconciliationPoint BETWEEN  @StartMonth AND @EndMonth
AND				T2.OSLAUA  IN ('E08000025', 'E08000029')					--Bham & Solihull LA
--AND				T1.GMPOrganisationCode NOT IN ('M88006')					--Exclude Cape Hill MC ????????

)

INSERT INTO		#BSOL_OF_tbStaging_NumeratorData
(				ReferenceID
,				EpisodeID
,				Numerator
)

(
SELECT			'41401'							AS [ReferenceID]
,				T1.EpisodeId
,				SUM(1)							AS [Numerator]	

FROM			#BSOL_OF_tbIndicator_PtsCohort_IP T1

INNER JOIN		EAT_Reporting.dbo.tbIpDiagnosisRelational T2
ON				T1.EpisodeId = T2.EpisodeID	

INNER JOIN		EAT_Reporting.dbo.tbInpatientEpisodes T3
ON				T1.EpisodeID = T3.EpisodeId

WHERE			1=1
AND 			LEFT(T3.AdmissionMethodCode,1) = 2										--Emergency Admissions
AND				T3.OrderInSpell =1														--First Episode in Spell
AND				LEFT(T2.DiagnosisCode,4) like ('S72[0-2]')
AND				T3.AgeOnAdmission >= 65                                                 --Age 65+


GROUP BY		T1.EpisodeId

)

--select * from #BSOL_OF_tbStaging_NumeratorData


/*==================================================================================================================================================================
UPDATE TimePeriod, Gender, Age and GP Practice from Source data at time of admission
=================================================================================================================================================================*/

UPDATE		T1
SET			T1.[TimePeriod]		= T2.[ReconciliationPoint]
--,			T1.[Gender]			= T2.[GenderDescription]
,			T1.[Age]			= T2.[AgeonAdmission]
,			T1.[GP_Practice]	=  T2.[GMPOrganisationCode]

FROM		#BSOL_OF_tbStaging_NumeratorData T1

INNER JOIN	[EAT_Reporting].[dbo].[tbInpatientEpisodes] T2
ON			T1.[EpisodeID] = T2.[EpisodeId]


/*==================================================================================================================================================================
UPDATE Gender from Source data at time of admission
=================================================================================================================================================================*/

--SELECT * FROM #BSOL_OF_tbStaging_NumeratorData T1

UPDATE		T1
SET			T1.[Gender]			= T3.[GenderDescription]

FROM		#BSOL_OF_tbStaging_NumeratorData T1

INNER JOIN	[EAT_Reporting].[dbo].[tbInpatientEpisodes] T2
ON			T1.[EpisodeID] = T2.[EpisodeId]

LEFT JOIN	[Reference].[dbo].[DIM_tbGender] T3
ON			T2.GenderCode = T3.GenderCode


/*==================================================================================================================================================================
UPDATE LSOA_2011 from CSU Patient Geography data table
=================================================================================================================================================================*/

UPDATE		T1
SET			T1.[LSOA_2011]	= T2.[LowerlayerSuperOutputArea2011]
-- ,           T1.[LSOA_2021]  = T2.[LowerLayerSuperOutputArea] -- This column is currently using 2001 LSOAs 

FROM		#BSOL_OF_tbStaging_NumeratorData T1

INNER JOIN	[EAT_Reporting].[dbo].[tbIPPatientGeography] T2		--New Patient Geography for Inpatients dataset following Unified SUS switch over
			--[EAT_Reporting].[dbo].[tbPatientGeography] T2		--Patient Geography data table pre-Unified SUS switch over
ON			T1.[EpisodeID] = T2.[EpisodeId]


/*==================================================================================================================================================================
UPDATE LSOA_2021 - temporarily updating LSOA 2021 based off LSOA 2011 ONS best fit lookup until DMT include LSOA 2021 in SUS dataset
=================================================================================================================================================================*/

UPDATE		T1
SET			T1.LSOA_2021 = T2.[LSOA21CD]

FROM		#BSOL_OF_tbStaging_NumeratorData T1

INNER JOIN  [EAT_Reporting_BSOL].[Reference].[LSOA_2011_to_LSOA_2021] T2
ON          T1.LSOA_2011 = T2.LSOA11CD



/*==================================================================================================================================================================
UPDATE WardCode from local LSOA21 to Ward22 mapping table
=================================================================================================================================================================*/

UPDATE		T1
SET			T1.[Ward_Code]	= T2.[WD22CD]
,			T1.[Ward_Name]	= T2.[WD22NM]
,			T1.[LAD_Code]	= T2.LAD22CD
,			T1.[LAD_Name]   = T2.LAD22NM
 
FROM		#BSOL_OF_tbStaging_NumeratorData T1
 
INNER JOIN	[EAT_Reporting_BSOL].[Reference].[LSOA_2021_WARD_LAD] T2
ON			T1.[LSOA_2021] = T2.[LSOA21CD]



/*==================================================================================================================================================================
UPDATE Locality from local LSOA21 to Locality mapping table
=================================================================================================================================================================*/

UPDATE		T1
SET			T1.[Locality_Res]	= T2.[Locality]

FROM		#BSOL_OF_tbStaging_NumeratorData T1

INNER JOIN	[EAT_Reporting_BSOL].[Reference].[LSOA_2021_BSOL_to_Constituency_2025_Locality] T2
ON			T1.[LSOA_2021] = T2.[LSOA21CD]


/*==================================================================================================================================================================
UPDATE Ethnicity from local Ethncity Demographic table and then from SUS where NULL
=================================================================================================================================================================*/

UPDATE		T1
SET			T1.[Ethnicity_Code]	= T3.[Ethnic_Code]

FROM		#BSOL_OF_tbStaging_NumeratorData T1

INNER JOIN	[EAT_Reporting].[dbo].[tbInpatientEpisodes] T2
ON			T1.[EpisodeID] = T2.[EpisodeId]

INNER JOIN	EAT_Reporting_BSOL.Demographic.Ethnicity T3
ON			T2.[NHSNumber] = T3.[Pseudo_NHS_Number]


--select * from #BSOL_OF_tbStaging_NumeratorData
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

--UPDATES ANY MISSING ETHNICITY FROM RAW SOURCE DATA (i.e. SUS)

UPDATE		T1
SET			T1.[Ethnicity_Code]	= T2.[EthnicCategoryCode] 

FROM		#BSOL_OF_tbStaging_NumeratorData T1

INNER JOIN	[EAT_Reporting].[dbo].[tbInpatientEpisodes] T2
ON			T1.[EpisodeID] = T2.[EpisodeId]

WHERE		T1.Ethnicity_Code IS NULL



/*==================================================================================================================================================================
UPDATE FinancialYear 
=================================================================================================================================================================*/

UPDATE		T1
SET			T1.[Financial_Year]	= T2.[HCSFinancialYearName]

FROM		#BSOL_OF_tbStaging_NumeratorData T1

INNER JOIN	[Reference].[dbo].[DIM_tbDate] T2
ON			T1.[TimePeriod] = T2.[HCCSReconciliationPoint]


/*==================================================================================================================================================================
UPDATE IndicatorID 
=================================================================================================================================================================*/

UPDATE		T1
SET			T1.[IndicatorID] = T2.[IndicatorID]

FROM		#BSOL_OF_tbStaging_NumeratorData T1

INNER JOIN	[EAT_Reporting_BSOL].[OF].[IndicatorList] T2
ON			cast(T1.[ReferenceID] as varchar) = T2.[ReferenceID]


select * from #BSOL_OF_tbStaging_NumeratorData 


/*==================================================================================================================================================================
INSERT FINAL Numerator Date into [EAT_Reporting_BSOL].[OF].[IndicatorData]
IndicatorID 114-ReferenceID  41401 - Reduce hip fractures in people age 65yrs and over	
=================================================================================================================================================================*/


--INSERT INTO		[EAT_Reporting_BSOL].[OF].[IndicatorData] 

--(				[IndicatorID]
--,	            [ReferenceID]
--,				[TimePeriod] 
--,				[Financial_Year]
--,				[Ethnicity_Code]
--,				[Gender]	
--,				[Age]		
--,				[LSOA_2011] 
--,				[LSOA_2021] 
--,				[Ward_Code] 
--,				[Ward_Name] 
--,				[LAD_Code]
--,				[LAD_Name]
--,				[Locality_Res]
--,				[GP_Practice]	
--,				[Numerator]		
--)

--(
--SELECT		[IndicatorID]
--,				[ReferenceID]
--,				[TimePeriod] 
--,				[Financial_Year]
--,				[Ethnicity_Code]
--,				[Gender]	
--,				[Age]		
--,				[LSOA_2011] 
--,				[LSOA_2021] 
--,				[Ward_Code] 
--,				[Ward_Name] 
--,				[LAD_Code]
--,				[LAD_Name]
--,				[Locality_Res]
--,				[GP_Practice]	
--,				SUM ([Numerator])				[Numerator]

--FROM			#BSOL_OF_tbStaging_NumeratorData



--GROUP BY		[IndicatorID]
--,				[ReferenceID]
--,				[TimePeriod] 
--,				[Financial_Year]
--,				[Ethnicity_Code]
--,				[Gender]	
--,				[Age]		
--,				[LSOA_2011] 
--,				[LSOA_2021] 
--,				[Ward_Code] 
--,				[Ward_Name] 
--,				[LAD_Code]
--,				[LAD_Name]
--,				[Locality_Res]
--,				[GP_Practice]	

--)




