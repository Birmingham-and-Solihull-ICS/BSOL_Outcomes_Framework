
/*==================================================================================================================================================================
OUTCOMES FRAMEWORK
(SUS/ECDS based indictors numerator actuals)

	22401	Emergency Hospital Admissions due to a fall in adults aged over 65yrs
	92622	Emergency Hospital Admissions for diabetes (under 19 years)
	93229	Emergency Hospital Admissions for Coronary Heart Disease (CHD)
	93231	Emergency Hospital Admissions for Stroke

w/c: 20/05/2024
	93232	Emergency Hospital Admissions for Myocardial Infarction (Heart Attack)

==================================================================================================================================================================*/


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
INNER JOIN		[EAT_Reporting].[dbo].[tbPatientGeography] T2
ON				T1.EpisodeId = T2.EpisodeId

WHERE			ReconciliationPoint BETWEEN  @StartMonth AND @EndMonth
AND				T2.OSLAUA  IN ('E08000025', 'E08000029')					--Bham & Solihull LA
--AND				T1.GMPOrganisationCode NOT IN ('M88006')					--Exclude Cape Hill MC ????????

)


/*==================================================================================================================================================================
22401 -	Emergency hospital admissions due to a fall in adults aged over 65yrs
			
Definition of Numerator: 
Emergency admissions for falls injuries classified by primary diagnosis code (ICD10 code S00 to T98) and external cause (ICD10 code W00 to W19) 
and an emergency admission code (episode order number equals 1, admission method starts with 2).Age at admission 65 and over.
=================================================================================================================================================================*/

DROP TABLE IF EXISTS    #BSOLBI_0033_OF_22401_EM_Falls_65andOver

SELECT			'22401'									AS [ReferenceID]
,				T1.EpisodeId

INTO			#BSOLBI_0033_OF_22401_EM_Falls_65andOver

FROM			#BSOL_OF_tbIndicator_PtsCohort_IP T1

INNER JOIN		EAT_Reporting.dbo.tbIpDiagnosisRelational T2
ON				T1.EpisodeId = T2.EpisodeID	

INNER JOIN		EAT_Reporting.dbo.tbInpatientEpisodes T3
ON				T1.EpisodeID = T3.EpisodeId

WHERE			1=1
AND				LEFT(T3.AdmissionMethodCode,1) = 2				--Emergency Admissions
AND				T3.AgeOnAdmission >= 65							--Age 65 & Over at time of admission
AND				T3.OrderInSpell =1								--First Episode in Spell
AND				LEFT(T2.DiagnosisCode,1) IN ('S','T')			--Falls injuries classified by primary diagnosis code (ICD10 code S00 to T98) 
AND				T2.DiagnosisOrder = 1							--Primary Diagnosis Position

GROUP BY		T1.EpisodeId

-----------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO		#BSOL_OF_tbStaging_NumeratorData
(				ReferenceID
,				EpisodeID
,				Numerator
)

( 
SELECT			T1.ReferenceID
,				T1.EpisodeID
,				SUM (1)							[Numerator]			

FROM			#BSOLBI_0033_OF_22401_EM_Falls_65andOver T1

INNER JOIN		EAT_Reporting.dbo.tbIpDiagnosisRelational T2
ON				T1.EpisodeId = T2.EpisodeId

WHERE			1=1
AND				LEFT(T2.DiagnosisCode,1) IN ('W')				--with a Secondary Diagnosis of W00 to W19

GROUP BY		T1.ReferenceID
,				T1.EpisodeID

)


/*==================================================================================================================================================================
92622	Admissions for Diabetes (under 19 years)
		
Definition of Numerator: 
Emergency hospital admissions of children and young people aged under 19 years with primary diagnosis of E10: Insulin-dependent diabetes mellitus. 
The number of finished emergency admissions (episode number equals 1, admission method starts with 2)
=================================================================================================================================================================*/

INSERT INTO		#BSOL_OF_tbStaging_NumeratorData
(				ReferenceID
,				EpisodeID
,				Numerator
)

(
SELECT			'92622'							AS [ReferenceID]
,				T1.EpisodeId
,				SUM (1)							AS [Numerator]	

FROM			#BSOL_OF_tbIndicator_PtsCohort_IP T1

INNER JOIN		EAT_Reporting.dbo.tbIpDiagnosisRelational T2
ON				T1.EpisodeId = T2.EpisodeID	

INNER JOIN		EAT_Reporting.dbo.tbInpatientEpisodes T3
ON				T1.EpisodeID = T3.EpisodeId

WHERE			1=1
AND				LEFT(T3.AdmissionMethodCode,1) = 2				--Emergency Admissions
AND				T3.AgeOnAdmission < 19							--Children and young people aged under 19 years
AND				T3.OrderInSpell =1								--First Episode in Spell
AND				LEFT(T2.DiagnosisCode,3) IN ('E10')				--Insulin-dependent diabetes mellitus
AND				T2.DiagnosisOrder = 1							--Primary Diagnosis position

GROUP BY		T1.EpisodeId

)


/*==================================================================================================================================================================
93229	Emergency Hospital Admissions for Coronary Heart Disease (CHD)

Definition of Numerator: 
 -Emergency Admissions with an admission method (ADMIMETH in list '21', '22', '23','24', '25', '28', '2A', '2B', '2C', '2D'); 
 -Defined by a three digit primary diagnosis (ICD10) code of I20, I21, I22, I23, I24 or I25,
 -patient classification 'ordinary' (1 or 2),
  -epiorder is equal to 1
  -----episode status is equal to 3 <<<<<<<<<<<-- Check what this means?
=================================================================================================================================================================*/

INSERT INTO		#BSOL_OF_tbStaging_NumeratorData
(				ReferenceID
,				EpisodeID
,				Numerator
)

(
SELECT			'93229'							AS [ReferenceID]
,				T1.EpisodeId
,				SUM (1)							AS [Numerator]	

FROM			#BSOL_OF_tbIndicator_PtsCohort_IP T1

INNER JOIN		EAT_Reporting.dbo.tbIpDiagnosisRelational T2
ON				T1.EpisodeId = T2.EpisodeID	

INNER JOIN		EAT_Reporting.dbo.tbInpatientEpisodes T3
ON				T1.EpisodeID = T3.EpisodeId

WHERE			1=1
AND				LEFT(T3.AdmissionMethodCode,1) = 2												--Emergency Admissions
AND				T3.PatientClassificationCode IN (1,2)											--patient classification Ordinary/Daycase Admission
AND				T3.OrderInSpell =1																--First Episode in Spell
AND				LEFT(T2.DiagnosisCode,3) IN  ('I20','I21', 'I22', 'I23', 'I24','I25')			--Coronary Heart Disease (CHD)
AND				T2.DiagnosisOrder = 1															--Primary Diagnosis position

GROUP BY		T1.EpisodeId

)


/*==================================================================================================================================================================
93231	Emergency Hospital Admissions for Stroke

Definition of Numerator: 
 -Emergency Admissions with an admission method (ADMIMETH in list '21', '22', '23', '24', '25', '28', '2A','2B', '2C', '2D'); 
 -Defined by a three digit primary diagnosis (ICD10) codes of I61, I62, I63, I64
 -Patient classification 'ordinary' (1 or 2)

=================================================================================================================================================================*/

INSERT INTO		#BSOL_OF_tbStaging_NumeratorData
(				ReferenceID
,				EpisodeID
,				Numerator
)

(
SELECT			'93231'							AS [ReferenceID]
,				T1.EpisodeId
,				SUM(1)							AS [Numerator]	

FROM			#BSOL_OF_tbIndicator_PtsCohort_IP T1

INNER JOIN		EAT_Reporting.dbo.tbIpDiagnosisRelational T2
ON				T1.EpisodeId = T2.EpisodeID	

INNER JOIN		EAT_Reporting.dbo.tbInpatientEpisodes T3
ON				T1.EpisodeID = T3.EpisodeId

WHERE			1=1
AND				LEFT(T3.AdmissionMethodCode,1) = 2										--Emergency Admissions
AND				T3.PatientClassificationCode IN (1,2)									--patient classification Ordinary/Daycase Admission
AND				T3.OrderInSpell =1														--First Episode in Spell
AND				LEFT(T2.DiagnosisCode,3) IN ('I61','I62','I63','I64')					--Stroke
AND				T2.DiagnosisOrder = 1													--Primary Diagnosis position

GROUP BY		T1.EpisodeId

)


/*==================================================================================================================================================================
93232	Emergency Hospital Admissions for Myocardial Infarction (heart attack)

Definition of Numerator: 
 - Emergency Admissions with an admission method (ADMIMETH in list '21', '22', '23', '24', '25', '28', '2A','2B', '2C', '2D')
  - Defined by a three digit primary diagnosis (ICD10) code of I21 or I22
  - Patient classification 'ordinary' (1 or 2).
  - All Ages
  - Episode number equals 1
  - Birmingham or Solihull LA Code

=================================================================================================================================================================*/

INSERT INTO		#BSOL_OF_tbStaging_NumeratorData
(				ReferenceID
,				EpisodeID
,				Numerator
)

(
SELECT			'93232'							AS [ReferenceID]
,				T1.EpisodeId
,				SUM(1)							AS [Numerator]	

FROM			#BSOL_OF_tbIndicator_PtsCohort_IP T1

INNER JOIN		EAT_Reporting.dbo.tbIpDiagnosisRelational T2
ON				T1.EpisodeId = T2.EpisodeID	

INNER JOIN		EAT_Reporting.dbo.tbInpatientEpisodes T3
ON				T1.EpisodeID = T3.EpisodeId

WHERE			1=1
AND				LEFT(T3.AdmissionMethodCode,1) = 2										--Emergency Admissions
AND				T3.PatientClassificationCode IN (1,2)									--patient classification Ordinary/Daycase Admission
AND				T3.OrderInSpell =1														--First Episode in Spell
AND				LEFT(T2.DiagnosisCode,3) IN ('I21','I22')								--Myocardial Infarction (heart attack)
AND				T2.DiagnosisOrder = 1													--Primary Diagnosis position

GROUP BY		T1.EpisodeId

)


/*==================================================================================================================================================================
UPDATE TimePeriod, Gender, Age and GP Practice from Source data at time of admission
=================================================================================================================================================================*/

UPDATE		T1
SET			T1.[TimePeriod]		= T2.[ReconciliationPoint]
,			T1.[Gender]			= T2.[GenderDescription]
,			T1.[Age]			= T2.[AgeonAdmission]
,			T1.[GP_Practice]	=  T2.[GMPOrganisationCode]

FROM		#BSOL_OF_tbStaging_NumeratorData T1

INNER JOIN	[EAT_Reporting].[dbo].[tbInpatientEpisodes] T2
ON			T1.[EpisodeID] = T2.[EpisodeId]


/*==================================================================================================================================================================
UPDATE LSOA_2011 from CSU Patient Geography data table
=================================================================================================================================================================*/

UPDATE		T1
SET			T1.[LSOA_2011]	= T2.[LowerlayerSuperOutputArea2011]
,           T1.[LSOA_2021]  = T2.[LowerLayerSuperOutputArea] 

FROM		#BSOL_OF_tbStaging_NumeratorData T1

INNER JOIN	[EAT_Reporting].[dbo].[tbPatientGeography] T2
ON			T1.[EpisodeID] = T2.[EpisodeId]



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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

--UPDATAES ANY MISSING ETHNICITY FROM RAW SOURCE DATA (i.e. SUS)

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
ON			T1.[ReferenceID] = T2.[ReferenceID]



/*==================================================================================================================================================================
INSERT FINAL Numerator Date into [EAT_Reporting_BSOL].[OF].[IndicatorData]
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
--SELECT			[IndicatorID]
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




