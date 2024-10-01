
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

DROP TABLE IF EXISTS #BSOL_OF_tbIndicator_PtsCohort_IP
DROP TABLE IF EXISTS 	#BSOL_OF_tbStaging_NumeratorData
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
ReferenceID  90813 - Hospital admissions as a result of self-harm (10-24 years)

Number of finished admission episodes in children aged between 10 and 24 years 
where the main recorded cause (defined as the first diagnosis code that represents an external cause (V01-Y98)) is between X60 and X84 (Intentional self-harm)
=================================================================================================================================================================*/

INSERT INTO		#BSOL_OF_tbStaging_NumeratorData
(				ReferenceID
,				EpisodeID
,				Numerator
)

(
SELECT			'90813'							AS [ReferenceID]
,				T1.EpisodeId
,				SUM(1)							AS [Numerator]	

FROM			#BSOL_OF_tbIndicator_PtsCohort_IP T1

INNER JOIN		EAT_Reporting.dbo.tbIpDiagnosisRelational T2
ON				T1.EpisodeId = T2.EpisodeID	

INNER JOIN		EAT_Reporting.dbo.tbInpatientEpisodes T3
ON				T1.EpisodeID = T3.EpisodeId

WHERE			1=1
--AND 			LEFT(T3.AdmissionMethodCode,1) = 2										--Emergency Admissions
AND				T3.OrderInSpell =1														--First Episode in Spell
AND				LEFT(T2.DiagnosisCode,3) IN ('X60','X61','X62','X63','X64','X66','X67','X68','X69'
						,'X70','X71','X72','X73','X74','X75','X76','X77','X78','X79'
						,'X80','X81','X82','X83','X84')                                 --Self Harm
AND				AgeOnAdmission >= 10													--10-24 years
AND				AgeOnAdmission <25														--10-24 years

GROUP BY		T1.EpisodeId

)


