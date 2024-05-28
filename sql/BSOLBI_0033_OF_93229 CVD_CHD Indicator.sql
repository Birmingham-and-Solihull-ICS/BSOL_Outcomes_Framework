--SELECT TOP (1000) [IndicatorID]
--      ,[ItemID]
--      ,[MetaValue]
--  FROM [EAT_Reporting_BSOL].[OF].[IndicatorMetadata]


--  select * from EAT_Reporting_BSOL.[dbo].[ACS_Coding] order by 1,4



--select top 1000 * from EAT_Reporting_BSOL.dbo.ACS_ICDCoding
----where NHSNumber='25088573'
--order by  codingdate

--select * from [EAT_Reporting_BSOL].[OF].[IndicatorData]



---CVD indicator 93229
/*Emergency hospital admission for Coronary heart disease*/
/*Numerator. Emergency admissions with an admission method 
(ADMIMETH in list '21', '22', '23','24', '25', '28', '2A', '2B', '2C', '2D'); 
defined by a three digit primary diagnosis (ICD10) code of I20, I21, I22, I23, I24 or I25,
patient classification 'ordinary' (1 or 2), episode status is equal to 3, epiorder is equal to 1. 
Denominator RW table.  Count to be reported and DSR  for comparisons where possible*/

select * from [EAT_Reporting_BSOL].[Development].[BSOL_1252_SUS_LTC_ICD10]
where LTC_Condition='CHD'

select  count(*) as Numerator
		,null Denominator
		,g.EthnicCategoryCode
		,g.LowerLayerSuperOutputArea
		,AgeOnAdmission
		, CASE WHEN DatePart(Month, AdmissionDate) >= 4
            THEN concat(DatePart(Year, AdmissionDate), '/', DatePart(Year, AdmissionDate) + 1)
            ELSE concat(DatePart(Year, AdmissionDate) - 1, '/', DatePart(Year, AdmissionDate) )
       END AS Fiscal_Year
into #data
from [SUS].[VwInpatientEpisodesPatientGeography] g
inner join [EAT_Reporting].[dbo].[tbIpDiagnosisRelational] d  on g.EpisodeId=d.EpisodeId
--inner join EAT_Reporting.dbo.tbInpatientEpisodes e on d.EpisodeId=e.EpisodeId
inner join [EAT_Reporting_BSOL].[Development].[BSOL_1252_SUS_LTC_ICD10] i on i.ICD10_Code=d.DiagnosisCode  --has the different ICD10 codes for most LTCs
where LTC_Condition='CHD' --the diagnoses
and g.OrderInSpell='1'
--and ReconcilliationPoint between  '201901' and '202403'
and left(admissionmethodcode,1)='2' --emergency admissions
and NHSNumber is not null
  and (OSLAUA = 'E08000025' or OSLAUA = 'E08000029')
  group by EthnicCategoryCode
		,LowerLayerSuperOutputArea
		,AgeOnAdmission
		, CASE WHEN DatePart(Month, AdmissionDate) >= 4
            THEN concat(DatePart(Year, AdmissionDate), '/', DatePart(Year, AdmissionDate) + 1)
            ELSE concat(DatePart(Year, AdmissionDate) - 1, '/', DatePart(Year, AdmissionDate) )
       END


	  
select * from #data
order by LowerLayerSuperOutputArea,EthnicCategoryCode, AgeOnAdmission