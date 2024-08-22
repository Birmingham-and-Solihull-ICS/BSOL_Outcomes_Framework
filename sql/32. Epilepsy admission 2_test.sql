

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
AND				LEFT(T2.DiagnosisCode,3) IN ('G40', 'G41')		--Epilepsy or Status epilepticus
AND				T2.DiagnosisOrder = 1							--Primary Diagnosis position

GROUP BY		T1.EpisodeId)