
/*=================================================================================================
 IndicatorID 121-ReferenceID  93438 - Positive GP Experience 			
=================================================================================================*/



--Data from Fingertips
--time period is in calendar year

  DROP TABLE IF EXISTS #Dataset
  

select i.[Time period] as TimePeriod
		,[Count] as Numerator
		,Denominator as Denominator
		,i.[Area Code] as GP_Practice
		,T3.PCN
		,T3.Locality as Locality_Reg
into #Dataset
from Working.[dbo].[BSOL_0033_OF_93438_PositiveGPExperience] i
inner join EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped T3		ON		i.[Area Code]= T3.GPPracticeCode_Original--BSOL Registered
where Sex='Persons' 
and T3.ICS_2223 = 'BSOL'


select  top 100 * from Working.[dbo].[BSOL_0033_OF_93438_PositiveGPExperience]
--where Category is not null 
select distinct top 100 * from [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]


--There is no denominator
/*=================================================================================================
 ID 93438- Positive GP Experience 
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
  SELECT '121'
		,'93438'
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



  








  