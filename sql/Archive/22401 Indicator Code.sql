  DROP TABLE IF EXISTS #Falls_Episodes, #Falls_Final,[EAT_Reporting_BSOL].[OF].[IndicatorData]

    CREATE TABLE [EAT_Reporting_BSOL].[OF].[IndicatorData] (
       [IndicatorID] INT
      ,[TimePeriod] INT
      ,[Ethnicity] VARCHAR(250)
      ,[Gender] VARCHAR(250)
      ,[Age] INT
      ,[LSOA] VARCHAR(15)
      ,[GP_Practice] VARCHAR(10)
      ,[Numerator] FLOAT
	  )
  
  SELECT T3.EpisodeId
    INTO #Falls_Episodes
	FROM EAT_Reporting.dbo.tbIpDiagnosisRelational T1
   INNER JOIN [EAT_Reporting_BSOL].[Development].[BSOL_0049_Falls_diags_23] T2
	  ON LEFT(T1.DiagnosisCode,4) = T2.Code
   INNER JOIN EAT_Reporting.dbo.tbInpatientEpisodes T3
      ON T1.EpisodeId = T3.EpisodeId
   WHERE T2.Code like 'S%'
     AND DiagnosisOrder = 1
     AND CONVERT(VARCHAR(6),T3.AdmissionDate,112) BETWEEN '201904' AND '202403'
	 AND LEFT(T3.AdmissionMethodCode,1) = 2
	 AND T3.OrderInSpell = 1
	 AND T3.AgeonAdmission >= 65
	 AND T3.CCGCode IN ('15E00','13P00','05P00','04X00','QHL') 
	 AND T3.GMPOrganisationCode NOT IN ('M88006')


  INSERT INTO #Falls_Episodes (
         EpisodeId
		 )
		 (
  SELECT T3.EpisodeId
	FROM EAT_Reporting.dbo.tbIpDiagnosisRelational T1
   INNER JOIN [EAT_Reporting_BSOL].[Development].[BSOL_0049_Falls_diags_23] T2
	  ON LEFT(T1.DiagnosisCode,4) = T2.Code
   INNER JOIN EAT_Reporting.dbo.tbInpatientEpisodes T3
      ON T1.EpisodeId = T3.EpisodeId
   WHERE T2.Code like 'S%'
     AND DiagnosisOrder = 1
     AND CONVERT(VARCHAR(6),T3.AdmissionDate,112) BETWEEN '201904' AND '202403'-- BETWEEN @AdmitStart AND @AdmitEnd 
	 AND LEFT(T3.AdmissionMethodCode,1) = 2
	 AND T3.OrderInSpell = 1
	 AND T3.AgeonAdmission >= 65
	 AND T3.[CCGCode] IN ('D2P2L','05L00','05Y00','06A00','05C00') 
     AND T3.GMPOrganisationCode IN (SELECT [GpPracticeCode] FROM	[EAT_Reporting_BSOL].[SUS].[tbRefGpPracticesAdditional])
         )

  INSERT INTO #Falls_Episodes (
         EpisodeId
		 )
		 (
  SELECT T3.EpisodeId
	FROM EAT_Reporting.dbo.tbIpDiagnosisRelational T1
   INNER JOIN [EAT_Reporting_BSOL].[Development].[BSOL_0049_Falls_diags_23] T2
	  ON LEFT(T1.DiagnosisCode,4) = T2.Code
   INNER JOIN EAT_Reporting.dbo.tbInpatientEpisodes T3
      ON T1.EpisodeId = T3.EpisodeId
   WHERE T2.Code like 'T%'
     AND DiagnosisOrder = 1
     AND CONVERT(VARCHAR(6),T3.AdmissionDate,112) BETWEEN '201904' AND '202403'-- BETWEEN @AdmitStart AND @AdmitEnd 
	 AND LEFT(T3.AdmissionMethodCode,1) = 2
	 AND T3.OrderInSpell = 1
	 AND T3.AgeonAdmission >= 65
	 AND T3.CCGCode IN ('15E00','13P00','05P00','04X00','QHL') 
	 AND T3.GMPOrganisationCode NOT IN ('M88006')
         )


  INSERT INTO #Falls_Episodes (
         EpisodeId
		 )
		 (
  SELECT T3.EpisodeId
	FROM EAT_Reporting.dbo.tbIpDiagnosisRelational T1
   INNER JOIN [EAT_Reporting_BSOL].[Development].[BSOL_0049_Falls_diags_23] T2
	  ON LEFT(T1.DiagnosisCode,4) = T2.Code
   INNER JOIN EAT_Reporting.dbo.tbInpatientEpisodes T3
      ON T1.EpisodeId = T3.EpisodeId
   WHERE T2.Code like 'T%'
     AND DiagnosisOrder = 1
     AND CONVERT(VARCHAR(6),T3.AdmissionDate,112) BETWEEN '201904' AND '202403'-- BETWEEN @AdmitStart AND @AdmitEnd 
	 AND LEFT(T3.AdmissionMethodCode,1) = 2
	 AND T3.OrderInSpell = 1
	 AND T3.AgeonAdmission >= 65
	 AND T3.[CCGCode] IN ('D2P2L','05L00','05Y00','06A00','05C00') 
     AND T3.GMPOrganisationCode IN (SELECT [GpPracticeCode] FROM	[EAT_Reporting_BSOL].[SUS].[tbRefGpPracticesAdditional])
         )
 
  SELECT '22401' as IndicatorID
        ,CONVERT(VARCHAR(6),T3.AdmissionDate,112) AS TimePeriod
		,T7.Ethnic_Code
		,T3.GenderDescription
        ,T3.AgeonAdmission
		,T4.LowerlayerSuperOutputArea2011
		,T3.GMPOrganisationCode
		,COUNT(T1.EpisodeID) as 'Numerator'
	INTO #Falls_Final
	FROM EAT_Reporting.dbo.tbIpDiagnosisRelational T1
   INNER JOIN [EAT_Reporting_BSOL].[Development].[BSOL_0049_Falls_diags_23] T2
	  ON LEFT(T1.DiagnosisCode,4) = T2.Code
   INNER JOIN EAT_Reporting.dbo.tbInpatientEpisodes T3
      ON T1.EpisodeId = T3.EpisodeId
   INNER JOIN [EAT_Reporting].[dbo].[tbPatientGeography] T4
      ON T1.EpisodeId = T4.EpisodeId
   INNER JOIN #Falls_Episodes T6
      ON T1.EpisodeId = T6.EpisodeId
    LEFT JOIN EAT_Reporting_BSOL.Demographic.Ethnicity T7
      ON T3.NHSNumber = T7.Pseudo_NHS_Number
   WHERE T2.Code like 'W%'
   GROUP BY CONVERT(VARCHAR(6),T3.AdmissionDate,112)
           ,T7.Ethnic_Code
		   ,T3.GenderDescription
           ,T3.AgeonAdmission
		   ,T4.LowerlayerSuperOutputArea2011
		   ,T3.GMPOrganisationCode

  
  INSERT INTO [EAT_Reporting_BSOL].[OF].[IndicatorData] (
       [IndicatorID] 
      ,[TimePeriod] 
      ,[Ethnicity] 
      ,[Gender] 
      ,[Age] 
      ,[LSOA] 
      ,[GP_Practice] 
      ,[Numerator] 
	  )
	  (
	  SELECT *
	    FROM #Falls_Final
	)


	 

