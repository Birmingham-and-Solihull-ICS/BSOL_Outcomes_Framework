
/*=================================================================================================
 IndicatorID 86-ReferenceID  CV4 - Improve management of hypertension- CVD prevent CVDP007HYP			
=================================================================================================*/



--Data from Fingertips
--time period is in calendar year

  DROP TABLE IF EXISTS #Dataset
  

select i.[TimePeriodName] as TimePeriod
		,[Numerator] 
		,Denominator 
		,i.AreaCode as GP_Practice
		--,i.AreaName
		--,i.AreaType
		,T3.PCN
		,T3.Locality as Locality_Reg
		
into #Dataset
from [EAT_Reporting_BSOL].[Development].[BSOL_1255_CVDP_Data] i
inner join EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T3		ON		i.[AreaCode]= T3.GPPracticeCode_Original--BSOL Registered
where IndicatorCode='CVDP007HYP' 
--and Sex='Persons' 
and T3.ICS_2223 = 'BSOL'
and AreaType='Practice'



--where Category is not null 
--select distinct top 100 * from [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]


--There is no denominator
/*=================================================================================================
IndicatorID 86-ReferenceID  CV4 - Improve management of hyptertension- CVD prevent
=================================================================================================*/
/*
  INSERT INTO [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator] (
		 [IndicatorID]		
        ,[ReferenceID] 
        ,[TimePeriod] 
	    ,[TimePeriodDesc]
		,GP_Practice
		,PCN
		,Locality_Reg
        ,[Numerator] 
	    ,[Denominator] 
		,[Indicator_Level]
	    )
		(
  SELECT '86'
		,'CV4'
        ,[TimePeriod]
		,'Other'
		,GP_Practice
		,PCN
		,Locality_Reg
        ,[Numerator]
        ,[Denominator]
		,'Practice Level'

   FROM #Dataset T1
           )
  
  */



  








  