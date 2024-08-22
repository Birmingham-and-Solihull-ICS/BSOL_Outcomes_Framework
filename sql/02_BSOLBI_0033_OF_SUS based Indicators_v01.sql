
/*==================================================================================================================================================================
OUTCOMES FRAMEWORK
(SUS/ECDS based indictors numerator actuals)

	22401	Emergency Hospital Admissions due to a fall in adults aged over 65yrs
	92622	Emergency Hospital Admissions for diabetes (under 19 years)
	92623	Admissions for epilepsy (under 19 years)
	93229	Emergency Hospital Admissions for Coronary Heart Disease (CHD)
	93231	Emergency Hospital Admissions for Stroke

	93232	Emergency Hospital Admissions for Myocardial Infarction (Heart Attack)
	93575	Emergency Hospital Admissions for Respiratory Disease
	92302	Emergency Hospital Admissions for COPD (35+)
	90810	Hospital admissions caused by asthma in children <19yrs
    41401   Reduce hip fractures in people age 65yrs and over	
    90808   Hospital admissions due to substance misuse (15 to 24 years).

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
DROP TABLE IF EXISTS    #90808_ICD10_Codes

CREATE TABLE			#BSOL_OF_tbIndicator_PtsCohort_IP (EpisodeID BIGINT NOT NULL)

CREATE TABLE			#BSOL_OF_tbStaging_NumeratorData 

(						[IndicatorID]			INT
,						[ReferenceID]			VARCHAR (20)
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

--select * from #BSOL_OF_tbStaging_NumeratorData 
--select * from #BSOL_OF_tbIndicator_PtsCohort_IP
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

--select * from EAT_Reporting.dbo.tbPatientGeography
--select * from #BSOL_OF_tbIndicator_PtsCohort_IP
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
92623	Admissions for epilepsy (under 19 years)
		
Definition of Numerator: 
Emergency hospital admissions of children and young people aged under 19 years with primary diagnosis of G40 (epilepsy) or G41 (Status epilepticus). 
The number of finished emergency admissions (episode number equals 1, admission method starts with 2)
=================================================================================================================================================================*/


INSERT INTO		#BSOL_OF_tbStaging_NumeratorData
(				ReferenceID
,				EpisodeID
,				Numerator
)

(
SELECT			'92623'							AS [ReferenceID]
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
AND				LEFT(T2.DiagnosisCode,3) IN ('G40', 'G41')		--Epilepsy or Status epilepticus
AND				T2.DiagnosisOrder = 1							--Primary Diagnosis position

GROUP BY		T1.EpisodeId)



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
93575	Reduce rate of emergency admissions for respiratory disease

Definition of Numerator: 
 - Emergency Admissions with an admission method (ADMIMETH in list '21', '22', '23', '24', '25', '28', '2A','2B', '2C', '2D')
  - Defined by a three digit primary diagnosis (ICD10 codes 'J00' to 'J99')
  - Episode number equals 1

  - Patient classification 'ordinary' (1 or 2).
  - All Ages

  - Birmingham or Solihull LA Code


NEED CHECKING WHAT IS MEANT BY THE FOLLOWING IN DEFINITION:
•	episode status = 3
•	CCG responsibility using 2021 CCG configuration across all time periods. 
•	Patients are allocated to a CCG based on the registered practice code on the HES episode.
•	Where the code indicates the responsibility is to a practice outside England, this record is excluded. 
•	All records without a practice code, and those with a practice code that is not recognised but does not indicate that responsibility is outside England, are allocated using the patient postcode, to the CCG within whose geographical boundary they live. 
•	Specialist commissioning codes are excluded

=================================================================================================================================================================*/

INSERT INTO		#BSOL_OF_tbStaging_NumeratorData
(				ReferenceID
,				EpisodeID
,				Numerator
)

(
SELECT			'93575'							AS [ReferenceID]
,				T1.EpisodeId
,				SUM(1)							AS [Numerator]	

FROM			#BSOL_OF_tbIndicator_PtsCohort_IP T1

INNER JOIN		EAT_Reporting.dbo.tbIpDiagnosisRelational T2
ON				T1.EpisodeId = T2.EpisodeID	

INNER JOIN		EAT_Reporting.dbo.tbInpatientEpisodes T3
ON				T1.EpisodeID = T3.EpisodeId

WHERE			1=1
AND				LEFT(T3.AdmissionMethodCode,1) = 2										--Emergency Admissions
--AND				T3.PatientClassificationCode IN (1,2)								--patient classification Ordinary/Daycase Admission
AND				T3.OrderInSpell =1														--First Episode in Spell
--AND				LEFT(T2.DiagnosisCode,1) = 'J'											
AND				T2.DiagnosisCode IN (	select	ICD10Code
										from	Reference.dbo.DIM_tbICD10
										where	left(ICD10Code,1) ='J'					--respiratory disease
										group by ICD10Code
									)
AND				T2.DiagnosisOrder = 1													--Primary Diagnosis position

GROUP BY		T1.EpisodeId

)

/*==================================================================================================================================================================
92302	Emergency Hospital Admissions for COPD (35+)

Definition of Numerator: 
  - Emergency Admissions with an admission method (ADMIMETH in list '21', '22', '23', '24', '25', '28', '2A','2B', '2C', '2D')
  - Defined by a three digit primary diagnosis (ICD-10: J40-J44)
  - Aged 35+
  - Episode number equals 1
  - Birmingham or Solihull LA Code

=================================================================================================================================================================*/

INSERT INTO		#BSOL_OF_tbStaging_NumeratorData
(				ReferenceID
,				EpisodeID
,				Numerator
)

(
SELECT			'92302'							AS [ReferenceID]
,				T1.EpisodeId
,				SUM(1)							AS [Numerator]	

FROM			#BSOL_OF_tbIndicator_PtsCohort_IP T1

INNER JOIN		EAT_Reporting.dbo.tbIpDiagnosisRelational T2
ON				T1.EpisodeId = T2.EpisodeID	

INNER JOIN		EAT_Reporting.dbo.tbInpatientEpisodes T3
ON				T1.EpisodeID = T3.EpisodeId

WHERE			1=1
AND				LEFT(T3.AdmissionMethodCode,1) = 2										--Emergency Admissions
AND				T3.OrderInSpell =1														--First Episode in Spell
AND				T2.DiagnosisCode IN (	select	ICD10Code
										from	Reference.dbo.DIM_tbICD10
										where	LEFT(DiagnosisCode,3) LIKE 'J4[01234]'	--COPD
										group by ICD10Code
									)
AND				T3.AgeOnAdmission >= 35                                                 --Age 35+


GROUP BY		T1.EpisodeId

)




/*==================================================================================================================================================================
90810	Hospital admissions caused by asthma in children <19yrs

Definition of Numerator: 
  - Emergency Admissions with an admission method (ADMIMETH in list '21', '22', '23', '24', '25', '28', '2A','2B', '2C', '2D')
  - Defined by a three digit primary diagnosis of either J45:Asthma or J46:Status asthmaticus
  - Aged < 19 yo
  - Episode number equals 1
  - Birmingham or Solihull LA Code

=================================================================================================================================================================*/

INSERT INTO		#BSOL_OF_tbStaging_NumeratorData
(				ReferenceID
,				EpisodeID
,				Numerator
)

(
SELECT			'90810'							AS [ReferenceID]
,				T1.EpisodeId
,				SUM(1)							AS [Numerator]	

FROM			#BSOL_OF_tbIndicator_PtsCohort_IP T1

INNER JOIN		EAT_Reporting.dbo.tbIpDiagnosisRelational T2
ON				T1.EpisodeId = T2.EpisodeID	

INNER JOIN		EAT_Reporting.dbo.tbInpatientEpisodes T3
ON				T1.EpisodeID = T3.EpisodeId

WHERE			1=1
AND				LEFT(T3.AdmissionMethodCode,1) = 2										--Emergency Admissions
AND				T3.OrderInSpell =1														--First Episode in Spell
AND				T2.DiagnosisCode IN (	select	ICD10Code
										from	Reference.dbo.DIM_tbICD10
										where	LEFT(DiagnosisCode,3) LIKE 'J4[56]'		--Asthma or Status asthmaticus
										group by ICD10Code
									)

AND				T3.AgeOnAdmission < 19                                                 --Age <19


GROUP BY		T1.EpisodeId

)

/*==================================================================================================================================================================
ReferenceID  41401 - Reduce hip fractures in people age 65yrs and over		

 The number of first finished emergency admission episodes in patients aged 65 and over at the time 
 of admission (episode order number equals 1, admission method starts with 2), with a recording of 
 fractured neck of femur classified by primary diagnosis code (ICD10 S72.0 Fracture of neck of femur;
 S72.1 Pertrochanteric fracture and S72.2 Subtrochanteric fracture) in financial year in which episode ended.
=================================================================================================================================================================*/


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
AND				LEFT(T2.DiagnosisCode,4) like ('S72[0-2]')                              --Hip Fractures
AND				T3.AgeOnAdmission >= 65                                                 --Age 65+


GROUP BY		T1.EpisodeId

)

/*==================================================================================================================================================================
ReferenceID  90808 - Hospital admissions due to substance misuse (15 to 24 years).
=================================================================================================================================================================*/

  SELECT DISTINCT 
         [ICD10Code]
	INTO #90808_ICD10_Codes
    FROM [Reference].[dbo].[DIM_tbICD10]
   WHERE LEFT([ICD10Code],3) LIKE 'F1[1-9]'

  INSERT INTO #90808_ICD10_Codes (
         [ICD10Code]
		 )
		 (
  SELECT DISTINCT 
         [ICD10Code]
    FROM [Reference].[dbo].[DIM_tbICD10]
   WHERE LEFT([ICD10Code],3) = 'T40'
         )

  INSERT INTO #90808_ICD10_Codes (
         [ICD10Code]
		 )
		 (
  SELECT DISTINCT 
         [ICD10Code]
    FROM [Reference].[dbo].[DIM_tbICD10]
   WHERE LEFT([ICD10Code],3) = 'T52'
         )

  INSERT INTO #90808_ICD10_Codes (
         [ICD10Code]
		 )
		 (
  SELECT DISTINCT 
         [ICD10Code]
    FROM [Reference].[dbo].[DIM_tbICD10]
   WHERE LEFT([ICD10Code],3) = 'T59'
         )  

  INSERT INTO #90808_ICD10_Codes (
         [ICD10Code]
		 )
		 (
  SELECT DISTINCT 
         [ICD10Code]
    FROM [Reference].[dbo].[DIM_tbICD10]
   WHERE LEFT([ICD10Code],4) = 'T436'
         )  

  INSERT INTO #90808_ICD10_Codes (
         [ICD10Code]
		 )
		 (
  SELECT DISTINCT 
         [ICD10Code]
    FROM [Reference].[dbo].[DIM_tbICD10]
   WHERE LEFT([ICD10Code],3) = 'Y12'
         )  

  INSERT INTO #90808_ICD10_Codes (
         [ICD10Code]
		 )
		 (
  SELECT DISTINCT 
         [ICD10Code]
    FROM [Reference].[dbo].[DIM_tbICD10]
   WHERE LEFT([ICD10Code],3) = 'Y16'
         )  
  
  INSERT INTO #90808_ICD10_Codes (
         [ICD10Code]
		 )
		 (
  SELECT DISTINCT 
         [ICD10Code]
    FROM [Reference].[dbo].[DIM_tbICD10]
   WHERE LEFT([ICD10Code],3) = 'Y19'
         )


INSERT INTO		#BSOL_OF_tbStaging_NumeratorData
(				ReferenceID
,				EpisodeID
,				Numerator
)

(
SELECT			'90808'							AS [ReferenceID]
,				T1.EpisodeId
,				SUM(1)							AS [Numerator]	

FROM			#BSOL_OF_tbIndicator_PtsCohort_IP T1

INNER JOIN		EAT_Reporting.dbo.tbIpDiagnosisRelational T2
ON				T1.EpisodeId = T2.EpisodeID	

INNER JOIN		EAT_Reporting.dbo.tbInpatientEpisodes T3
ON				T1.EpisodeID = T3.EpisodeId

INNER JOIN      #90808_ICD10_Codes T4
ON			    T2.DiagnosisCode = T4.ICD10Code

WHERE			1=1
AND 			T2.DiagnosisOrder = 1											        -- Primary Diagnosis
AND				T3.OrderInSpell = 1														--First Episode in Spell
AND				T3.AgeOnAdmission BETWEEN 15 AND 24                                     -- Age between 15 and 24


GROUP BY		T1.EpisodeId

)


/*==================================================================================================================================================================
ReferenceID  21001 - Emergency Hospital Admissions for Intentional Self-Harm

The number of first finished emergency admission episodes in patients (episode number equals 1, admission method starts with 2), 
with a recording of self harm by cause code (ICD10 X60 to X84) in financial year in which episode ended. 
Regular and day attenders have been excluded. Regions are the sum of the Local Authorities. England is the sum of all Local Authorities 
and admissions coded as U (England NOS).

Numerator Extraction: Emergency Hospital Admissions for Intentional Self Harm. Counts of first finished consultant episodes with an external cause of intentional self harm 
and an emergency admission method were extracted from HES. First finished consultant episode counts (excluding regular attenders) were summed in an excel pivot table filtered for emergency admission method 
and separated by quinary age for all ages, sex and local authority in the respective financial year. 
Self harm is defined by external cause codes (ICD10 X60 to X84) which include: 
• Intentional self poisoning (X60 to X69 inclusive), 
• Intentional self harm by hanging, drowning or jumping (X70, X71 and X80), 
• Intentional self harm by firearm or explosive (X72 to X75 inclusive), 
• Intentional self harm using other implement (X78 and X79) 
• Intentional self harm other (X76, X77 and X81 to X84) 
Please note this definition does not include events of undetermined intent.

Numerator Aggregation or allocation: Local Authority of residence of each Finished Admission Episode is allocated by HES. 
Values for England, Regions, Counties, Centres, Deprivation deciles and ONS cluster groups are aggregates of these. 
Data for Isles of Scilly and City of London have been aggregated with Cornwall and Hackney respectively in order to prevent possible disclosure and disclosure by differencing.
=================================================================================================================================================================*/

INSERT INTO		#BSOL_OF_tbStaging_NumeratorData
(				ReferenceID
,				EpisodeID
,				Numerator
)

(
SELECT			'21001'							AS [ReferenceID]
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
AND				LEFT(T2.DiagnosisCode,3) IN ('X60','X61','X62','X63','X64','X66','X67','X68','X69'
						,'X70','X71','X72','X73','X74','X75','X76','X77','X78','X79'
						,'X80','X81','X82','X83','X84')                              --Self Harm

GROUP BY		T1.EpisodeId

)



--select * from #BSOL_OF_tbStaging_NumeratorData

/*==================================================================================================================================================================
UPDATE TimePeriod, Gender, Age and GP Practice from Source data at time of admission
=================================================================================================================================================================*/

UPDATE		T1
SET			T1.[TimePeriod]		= T2.[ReconciliationPoint]
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

--WHERE			ReferenceID ='21001'

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

