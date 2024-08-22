  
  DROP TABLE IF EXISTS #Dataset
  
/*=================================================================================================
 Get Dataset together			
=================================================================================================*/

  SELECT T1.EpisodeId
        --,AdmissionDate
		,ReconciliationPoint
		,GMPOrganisationCode
		,T2.PCN
		,T2.Locality
		,T3.LowerlayerSuperOutputArea2011			as LSOA_2011
		,CONVERT(VARCHAR(10),NULL)					as LSOA_2021
		,T1.NHSNumber
		,AgeOnAdmission
		,CONVERT(VARCHAR(20),NULL)					as Ethnic_Code

	INTO #Dataset

    FROM [EAT_Reporting].[Dbo].[tbInpatientEpisodes] T1

	INNER JOIN EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T2
      ON T1.GMPOrganisationCode = T2.GPPracticeCode_Original
    
	LEFT JOIN [EAT_Reporting].[Dbo].[tbIPPatientGeography] T3
	  ON T1.EpisodeId = T3.EpisodeId
   
   WHERE T1.OrderInSpell = 1							--First Episode in Spell
	AND ReconciliationPoint BETWEEN 201904 AND 202403	-- 5 years pooled data
    AND T2.ICS_2223 = 'BSOL'							--BSOL ICB GP Practices

	AND CBSADerivedSpellHRGCode  IN (	'NZ30A',		--	Normal Delivery with CC Score 2+
										'NZ30B',		--	Normal Delivery with CC Score 1
										'NZ30C',		--	Normal Delivery with CC Score 0
										'NZ31A',		--	Normal Delivery, with Epidural or Induction, with CC Score 2+
										'NZ31B',		--	Normal Delivery, with Epidural or Induction, with CC Score 1
										'NZ31C',		--	Normal Delivery, with Epidural or Induction, with CC Score 0
										'NZ32A',		--	Normal Delivery, with Epidural and Induction, or with Post-Partum Surgical Intervention, with CC Score 2+
										'NZ32B',		--	Normal Delivery, with Epidural and Induction, or with Post-Partum Surgical Intervention, with CC Score 1
										'NZ32C',		--	Normal Delivery, with Epidural and Induction, or with Post-Partum Surgical Intervention, with CC Score 0
										'NZ33A',		--	Normal Delivery, with Epidural or Induction, and with Post-Partum Surgical Intervention, with CC Score 2+
										'NZ33B',		--	Normal Delivery, with Epidural or Induction, and with Post-Partum Surgical Intervention, with CC Score 1
										'NZ33C',		--	Normal Delivery, with Epidural or Induction, and with Post-Partum Surgical Intervention, with CC Score 0
										'NZ34A',		--	Normal Delivery, with Epidural, Induction and Post-Partum Surgical Intervention, with CC Score 2+
										'NZ34B',		--	Normal Delivery, with Epidural, Induction and Post-Partum Surgical Intervention, with CC Score 1
										'NZ34C',		--	Normal Delivery, with Epidural, Induction and Post-Partum Surgical Intervention, with CC Score 0
										'NZ40A',		--	Assisted Delivery with CC Score 2+
										'NZ40B',		--	Assisted Delivery with CC Score 1
										'NZ40C',		--	Assisted Delivery with CC Score 0
										'NZ41A',		--	Assisted Delivery, with Epidural or Induction, with CC Score 2+
										'NZ41B',		--	Assisted Delivery, with Epidural or Induction, with CC Score 1
										'NZ41C',		--	Assisted Delivery, with Epidural or Induction, with CC Score 0
										'NZ42A',		--	Assisted Delivery, with Epidural and Induction, or with Post-Partum Surgical Intervention, with CC Score 2+
										'NZ42B',		--	Assisted Delivery, with Epidural and Induction, or with Post-Partum Surgical Intervention, with CC Score 1
										'NZ42C',		--	Assisted Delivery, with Epidural and Induction, or with Post-Partum Surgical Intervention, with CC Score 0
										'NZ43A',		--	Assisted Delivery, with Epidural or Induction, and with Post-Partum Surgical Intervention, with CC Score 2+
										'NZ43B',		--	Assisted Delivery, with Epidural or Induction, and with Post-Partum Surgical Intervention, with CC Score 1
										'NZ43C',		--	Assisted Delivery, with Epidural or Induction, and with Post-Partum Surgical Intervention, with CC Score 0
										'NZ44A',		--	Assisted Delivery, with Epidural, Induction and Post-Partum Surgical Intervention, with CC Score 2+
										'NZ44B',		--	Assisted Delivery, with Epidural, Induction and Post-Partum Surgical Intervention, with CC Score 1
										'NZ44C',		--	Assisted Delivery, with Epidural, Induction and Post-Partum Surgical Intervention, with CC Score 0
										'NZ50A',		--	Planned Caesarean Section with CC Score 4+
										'NZ50B',		--	Planned Caesarean Section with CC Score 2-3
										'NZ50C',		--	Planned Caesarean Section with CC Score 0-1
										'NZ51A',		--	Emergency Caesarean Section with CC Score 4+
										'NZ51B',		--	Emergency Caesarean Section with CC Score 2-3
										'NZ51C'			--	Emergency Caesarean Section with CC Score 0-1
										)



/*===========================================================================================================================================
  UPDATE LSOA
  ==============================================================================================================================================*/

  UPDATE #Dataset
     SET LSOA_2021 = T2.LSOA21CD
    FROM #Dataset T1
   INNER JOIN  [EAT_Reporting_BSOL].[Reference].[LSOA_2011_to_LSOA_2021] T2
      ON T1.LSOA_2011 = T2.LSOA11CD

  UPDATE #Dataset
     SET Ethnic_Code = T2.Ethnic_Code
	FROM #Dataset T1
   INNER JOIN EAT_Reporting_BSOL.Demographic.Ethnicity T2
      ON T1.NHSNumber = T2.Pseudo_NHS_Number


/*=================================================================================================
 Derive Numerator and Denominator			
=================================================================================================*/

  SELECT ReconciliationPoint			  as YYYYMM
  --CONVERT(VARCHAR(6),AdmissionDate,112) as YYYYMM
		,GMPOrganisationCode
		,PCN
		,Locality
		,LSOA_2011
		,LSOA_2021
		,Ethnic_Code
		,SUM(1) as Numerator
	INTO #Numerator
    FROM #Dataset
   WHERE AgeOnAdmission BETWEEN 12 AND 17
   GROUP BY ReconciliationPoint
   --CONVERT(VARCHAR(6),AdmissionDate,112)
		   ,GMPOrganisationCode
		   ,PCN
		   ,Locality
		   ,LSOA_2011
		   ,LSOA_2021
		   ,Ethnic_Code


  SELECT ReconciliationPoint			  as YYYYMM
  --CONVERT(VARCHAR(6),AdmissionDate,112) as YYYYMM
		,GMPOrganisationCode
		,PCN
		,Locality
		,LSOA_2011
		,LSOA_2021
		,Ethnic_Code
		,CONVERT(INT,NULL) as Numerator
		,SUM(1) as Denominator
	INTO #Denominator
    FROM #Dataset
   GROUP BY ReconciliationPoint
  --CONVERT(VARCHAR(6),AdmissionDate,112)
		   ,GMPOrganisationCode
		   ,PCN
		   ,Locality
		   ,LSOA_2011
		   ,LSOA_2021
		   ,Ethnic_Code


  UPDATE #Denominator
     SET Numerator = T2.Numerator
    FROM #Denominator T1
   INNER JOIN #Numerator T2
      ON T1.YYYYMM = T2.YYYYMM
	 AND T1.GMPOrganisationCode = T2.GMPOrganisationCode
	 AND T1.PCN = T2.PCN
	 AND T1.Locality = T2.Locality
	 AND T1.Ethnic_Code = T2.Ethnic_Code


 /*=================================================================================================
 Insert into Staging Table			
=================================================================================================*/
/*
  INSERT INTO [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator] (
         [IndicatorID]
        ,[ReferenceID]
        ,[TimePeriod]
        ,[TimePeriodDesc]
        ,[GP_Practice]
        ,[PCN]
        ,[Locality_Reg]
        ,[Numerator]
        ,[Denominator]
        ,[Indicator_Level]
        ,[LSOA_2011]
        ,[LSOA_2021]
        ,[Ethnicity_Code]
		)
		(
  SELECT '46'
        ,'93113'
		,YYYYMM
		,'Month'
		,GMPOrganisationCode
		,PCN
		,Locality
		,Numerator
		,Denominator
		,'Practice Level'
		,LSOA_2011
		,LSOA_2021
		,Ethnic_Code
    FROM #Denominator
	     )
 */