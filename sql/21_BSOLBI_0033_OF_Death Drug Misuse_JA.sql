


/*=================================================================================================
 IndicatorID 26-ReferenceID  92432 - Deaths from drug misuse / rate per 100,000 		
=================================================================================================*/

/*Deaths where the underlying cause of death has been coded to the following categories of mental and behavioural disorders due to psychoactive substance use (excluding alcohol, tobacco and volatile solvents):
(i)                opioids (F11)
(ii)               cannabinoids (F12)
(iii)              sedatives or hypnotics (F13)
(iv)              cocaine (F14)
(v)               other stimulants, including caffeine (F15)
(vi)              hallucinogens (F16) and
(vii)             multiple drug use and use of other psychoactive substances (F19)


AND 

Deaths coded to the following categories and where a drug controlled under the Misuse of Drugs Act 1971 was mentioned on the death record:
(i)             Accidental poisoning by drugs, medicaments and biological substances (X40 to X44)
(ii)            Intentional self-poisoning by drugs, medicaments and biological substances (X60 to X64)
(iii)           Poisoning by drugs, medicaments and biological substances, undetermined intent (Y10 to Y14)
(iv)           Assault by drugs, medicaments and biological substances (X85) and
(v)            Mental and behavioural disorders due to use of volatile solvents (F18)*/

--select PatientId, S_UNDERLYING_COD_ICD10, REG_DATE
--,diag1.DiagnosisDescription,diag1.DiagnosisCode
--,diag2.DiagnosisDescription,diag2.DiagnosisCode
--,diag3.DiagnosisDescription,diag3.DiagnosisCode
--from  LocalFeeds.[Reporting].[Deaths_Register] d
 
--left join Reference.dbo.DIM_tbDiagnosis diag1 On d.S_UNDERLYING_COD_ICD10 = diag1.DiagnosisCode
--left join Reference.dbo.DIM_tbDiagnosis diag2 On d.S_COD_CODE_2 = diag2.DiagnosisCode
--left join Reference.dbo.DIM_tbDiagnosis diag3 On d.S_COD_CODE_3 = diag3.DiagnosisCode
--left join Reference.dbo.DIM_tbDiagnosis diag4 On d.S_COD_CODE_4 = diag4.DiagnosisCode
--left join Reference.dbo.DIM_tbDiagnosis diag5 On d.S_COD_CODE_5 = diag5.DiagnosisCode
--left join Reference.dbo.DIM_tbDiagnosis diag6 On d.S_COD_CODE_6 = diag6.DiagnosisCode
--left join Reference.dbo.DIM_tbDiagnosis diag7 On d.S_COD_CODE_7 = diag7.DiagnosisCode
--left join Reference.dbo.DIM_tbDiagnosis diag8 On d.S_COD_CODE_8 = diag8.DiagnosisCode
--left join Reference.dbo.DIM_tbDiagnosis diag9 On d.S_COD_CODE_9 = diag9.DiagnosisCode
--left join Reference.dbo.DIM_tbDiagnosis diag10 On d.S_COD_CODE_10 = diag10.DiagnosisCode
--left join Reference.dbo.DIM_tbDiagnosis diag11 On d.S_COD_CODE_11 = diag11.DiagnosisCode
--left join Reference.dbo.DIM_tbDiagnosis diag12 On d.S_COD_CODE_12 = diag12.DiagnosisCode
--left join Reference.dbo.DIM_tbDiagnosis diag13 On d.S_COD_CODE_13 = diag13.DiagnosisCode
--left join Reference.dbo.DIM_tbDiagnosis diag14 On d.S_COD_CODE_14 = diag14.DiagnosisCode
--left join Reference.dbo.DIM_tbDiagnosis diag15 On d.S_COD_CODE_15 = diag15.DiagnosisCode
----where DiagnosisCode like '%Z915%' or DiagnosisCode like 'X84%' or DiagnosisCode like 'Y870'
-- where (left(diag1.DiagnosisCode,3) like 'F1[1-6]' 
--		or  left(diag1.DiagnosisCode,3) in ('F19'))		--underlying cause of death
-- AND
--		(left(diag2.DiagnosisCode,3) like 'X4[0-4]'		 --mentioned on the death record
--		or left(diag2.DiagnosisCode,3) like 'X6[0-4]' 
--		or left(diag2.DiagnosisCode,3) like 'Y1[0-4]'
--		or left(diag2.DiagnosisCode,3) in ('X85','F18')
		
--		or left(diag3.DiagnosisCode,3) like 'X4[0-4]' 
--		or left(diag3.DiagnosisCode,3) like 'X6[0-4]' 
--		or left(diag3.DiagnosisCode,3) like 'Y1[0-4]'
--		or left(diag3.DiagnosisCode,3) in ('X85','F18')
		
--		or left(diag4.DiagnosisCode,3) like 'X4[0-4]' 
--		or left(diag4.DiagnosisCode,3) like 'X6[0-4]' 
--		or left(diag4.DiagnosisCode,3) like 'Y1[0-4]'
--		or left(diag4.DiagnosisCode,3) in ('X85','F18')
		
--		or left(diag5.DiagnosisCode,3) like 'X4[0-4]' 
--		or left(diag5.DiagnosisCode,3) like 'X6[0-4]' 
--		or left(diag5.DiagnosisCode,3) like 'Y1[0-4]'
--		or left(diag5.DiagnosisCode,3) in ('X85','F18')
		
--		or left(diag6.DiagnosisCode,3) like 'X4[0-4]' 
--		or left(diag6.DiagnosisCode,3) like 'X6[0-4]' 
--		or left(diag6.DiagnosisCode,3) like 'Y1[0-4]'
--		or left(diag6.DiagnosisCode,3) in ('X85','F18')

--		or left(diag7.DiagnosisCode,3) like 'X4[0-4]' 
--		or left(diag7.DiagnosisCode,3) like 'X6[0-4]' 
--		or left(diag7.DiagnosisCode,3) like 'Y1[0-4]'
--		or left(diag7.DiagnosisCode,3) in ('X85','F18')

--		or left(diag8.DiagnosisCode,3) like 'X4[0-4]' 
--		or left(diag8.DiagnosisCode,3) like 'X6[0-4]' 
--		or left(diag8.DiagnosisCode,3) like 'Y1[0-4]'
--		or left(diag8.DiagnosisCode,3) in ('X85','F18')

--		or left(diag9.DiagnosisCode,3) like 'X4[0-4]' 
--		or left(diag9.DiagnosisCode,3) like 'X6[0-4]' 
--		or left(diag9.DiagnosisCode,3) like 'Y1[0-4]'
--		or left(diag9.DiagnosisCode,3) in ('X85','F18')

--		or left(diag10.DiagnosisCode,3) like 'X4[0-4]' 
--		or left(diag10.DiagnosisCode,3) like 'X6[0-4]' 
--		or left(diag10.DiagnosisCode,3) like 'Y1[0-4]'
--		or left(diag10.DiagnosisCode,3) in ('X85','F18')

--		or left(diag11.DiagnosisCode,3) like 'X4[0-4]' 
--		or left(diag11.DiagnosisCode,3) like 'X6[0-4]' 
--		or left(diag11.DiagnosisCode,3) like 'Y1[0-4]'
--		or left(diag11.DiagnosisCode,3) in ('X85','F18')

--		or left(diag12.DiagnosisCode,3) like 'X4[0-4]' 
--		or left(diag12.DiagnosisCode,3) like 'X6[0-4]' 
--		or left(diag12.DiagnosisCode,3) like 'Y1[0-4]'
--		or left(diag12.DiagnosisCode,3) in ('X85','F18')

--		or left(diag13.DiagnosisCode,3) like 'X4[0-4]' 
--		or left(diag13.DiagnosisCode,3) like 'X6[0-4]' 
--		or left(diag13.DiagnosisCode,3) like 'Y1[0-4]'
--		or left(diag13.DiagnosisCode,3) in ('X85','F18')

--		or left(diag14.DiagnosisCode,3) like 'X4[0-4]' 
--		or left(diag14.DiagnosisCode,3) like 'X6[0-4]' 
--		or left(diag14.DiagnosisCode,3) like 'Y1[0-4]'
--		or left(diag14.DiagnosisCode,3) in ('X85','F18')

--		or left(diag15.DiagnosisCode,3) like 'X4[0-4]' 
--		or left(diag15.DiagnosisCode,3) like 'X6[0-4]' 
--		or left(diag15.DiagnosisCode,3) like 'Y1[0-4]'
--		or left(diag15.DiagnosisCode,3) in ('X85','F18')
		
--		)															

 --select top 100 * from LocalFeeds.[Reporting].[Deaths_Register]
 ------------------------------------------------------------------------
drop table if exists #Dataset
SELECT T1.PatientId
        ,CONVERT(DATE,REG_DATE) as REG_DATE
		,DEC_SEX
        ,DEC_AGEC
	    ,T1.LSOA_OF_RESIDENCE_CODE
		,GP_PRACTICE_CODE
        ,[S_UNDERLYING_COD_ICD10]
		,CONVERT(VARCHAR(5),NULL) as Ethnicity_Code
        ,[S_COD_CODE_1]
        ,[S_COD_CODE_2]
        ,[S_COD_CODE_3]
        ,[S_COD_CODE_4]
        ,[S_COD_CODE_5]
        ,[S_COD_CODE_6]
        ,[S_COD_CODE_7]
        ,[S_COD_CODE_8]
        ,[S_COD_CODE_9]
        ,[S_COD_CODE_10]
        ,[S_COD_CODE_11]
        ,[S_COD_CODE_12]
        ,[S_COD_CODE_13]
        ,[S_COD_CODE_14]
        ,[S_COD_CODE_15]
INTO #Dataset
FROM LocalFeeds.[Reporting].[Deaths_Register] T1
INNER JOIN [Reference].[Ref].[LSOA_WARD_LAD] T2
ON T1.LSOA_OF_RESIDENCE_CODE = T2.LSOA11CD
WHERE T2.LAD19NM IN ('Birmingham', 'Solihull')
 
 
UPDATE #Dataset  
SET Ethnicity_Code = T2.Ethnic_Code
FROM #Dataset T1
LEFT JOIN [EAT_Reporting_BSOL].[Demographic].[Ethnicity] T2		ON T1.PatientId = T2.Pseudo_NHS_Number
--where REG_DATE >= '01-AUG-2013'  --let's see all available years 
	--and ULA_OF_RESIDENCE_CODE in ('E08000025','E08000029')
	--and T3.ICS_2223 = 'BSOL'
drop table if exists #Unpivotted_Dataset
SELECT PatientId
        ,REG_DATE
		,DEC_SEX
        ,DEC_AGEC
	    ,LSOA_OF_RESIDENCE_CODE
		,Ethnicity_Code
		,GP_PRACTICE_CODE
		,ICD_CODE
		,ICD_CODE_POSITION
INTO #Unpivotted_Dataset
FROM #Dataset
UNPIVOT (
       ICD_CODE FOR ICD_CODE_POSITION IN 
	   (
         [S_UNDERLYING_COD_ICD10]
        ,[S_COD_CODE_1]
        ,[S_COD_CODE_2]
        ,[S_COD_CODE_3]
        ,[S_COD_CODE_4]
        ,[S_COD_CODE_5]
        ,[S_COD_CODE_6]
        ,[S_COD_CODE_7]
        ,[S_COD_CODE_8]
        ,[S_COD_CODE_9]
        ,[S_COD_CODE_10]
        ,[S_COD_CODE_11]
        ,[S_COD_CODE_12]
        ,[S_COD_CODE_13]
        ,[S_COD_CODE_14]
        ,[S_COD_CODE_15]        
		)
	) UNPVT

--select top 100 * from LocalFeeds.[Reporting].[Deaths_Register]
-- cannot find ethnicty in source data- death register for the missing ethnicity

--UPDATE		T1
--SET			T1.[Ethnicity_Code]	= T2.??

--FROM		#Unpivotted_Dataset T1

--INNER JOIN	LocalFeeds.[Reporting].[Deaths_Register]  T2
--ON			T1.PatientId = T2.PatientId

--WHERE		T1.Ethnicity_Code IS NULL

	--first lot in all causes of death
drop table if exists #First
select distinct PatientId
	,REG_DATE
	,LSOA_OF_RESIDENCE_CODE
	,Ethnicity_Code
	,GP_PRACTICE_CODE,DEC_SEX
    ,DEC_AGEC
into #First
from #Unpivotted_Dataset u
where (left(ICD_CODE,3) like 'F1[1-6]' 
		or  left(ICD_CODE,3) in ('F19'))		--underlying cause of death in all causes of death
--order by GP_PRACTICE_CODE
--339

--second lot in all causes of death
drop table if exists #Second
select distinct PatientId
into #Second
from #Unpivotted_Dataset
where left(ICD_CODE,3) like 'X4[0-4]' 
		or left(ICD_CODE,3) like 'X6[0-4]' 
		or left(ICD_CODE,3) like 'Y1[0-4]'
		or left(ICD_CODE,3) in ('X85','F18')

--1289

--union AND

drop table if exists #Numer
select convert(varchar(6),left(convert(varchar, f.REG_DATE, 112),6)) as TimePeriod
--, f.REG_DATE
,da.[HCSFinancialYearName]  as Financial_Year
,Ethnicity_Code
,DEC_SEX as Gender
,DEC_AGEC as Age
,LSOA_OF_RESIDENCE_CODE as LSOA_2011
,T5.LSOA21CD  as LSOA_2021
,T6.WD22CD as Ward_Code
,T6.WD22NM as Ward_Name
,T6.LAD22CD as LAD_Code
,T6.LAD22NM as LAD_Name
,T7.Locality as Locality_Res
,GP_PRACTICE_CODE as GP_Practice
,sum(1) as Numerator
into #Numer
from #First f
INNER JOIN #Second s on f.PatientId=s.PatientId 
--INNER JOIN  EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T3		ON		f.GP_PRACTICE_CODE = T3.GPPracticeCode_Original--BSOL Registered
LEFT JOIN  [EAT_Reporting_BSOL].[Reference].[LSOA_2011_to_LSOA_2021] T5	ON f.LSOA_OF_RESIDENCE_CODE = T5.LSOA11CD
LEFT JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_WARD_LAD] T6 ON T5.LSOA21CD=T6.LSOA21CD
LEFT JOIN [EAT_Reporting_BSOL].[Reference].[LSOA_2021_BSOL_to_Constituency_2025_Locality] T7 ON T5.LSOA21CD=T7.LSOA21CD
join	[Reference].[dbo].[DIM_tbDate] da  on f.REG_DATE=da.DateFormatYYYYMMDD	
group by f.REG_DATE
,[HCSFinancialYearName]
,Ethnicity_Code
,DEC_SEX 
,DEC_AGEC 
,LSOA_OF_RESIDENCE_CODE 
,T5.LSOA21CD
,T6.WD22CD 
,T6.WD22NM 
,T6.LAD22CD 
,T6.LAD22NM 
,T7.Locality
,GP_PRACTICE_CODE
--128


--select  * from #d

--select top 10 * from EAT_Reporting_BSOL.[OF].[IndicatorData]

--select top 10 * from [EAT_Reporting_BSOL].[Reference].[vwYear_Month] 

/*=================================================================================================
 ID 92432 - Death from drug misuse		
=================================================================================================*/
/*
  INSERT INTO [EAT_Reporting_BSOL].[OF].[IndicatorData] (
		 [IndicatorID]		
        ,[ReferenceID] 
        ,[TimePeriod] 
	    ,[Financial_Year]
		,[Ethnicity_Code]
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
        ,[Numerator]
	    )
		(
  SELECT '26'
		,'92432'
        ,[TimePeriod] 
	    ,[Financial_Year]
		,[Ethnicity_Code]
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
        ,[Numerator]

   FROM  #Numer T1
           )
  
  */

