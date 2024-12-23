  Use [EAT_Reporting_BSOL]
  
  Select
  [OF].[IndicatorList].[IndicatorID] as IndicatorNumber
  ,StagingTable1.IndicatorID as StagingTable1
  ,StagingTable2.IndicatorID as StagingTable2
  ,OutputTable.IndicatorID as OutputTable
  From
  [OF].[IndicatorList] 
  
  Full Join 
      (SELECT Distinct [IndicatorID]
      ,[ReferenceID]
  FROM [EAT_Reporting_BSOL].[OF].[IndicatorData]) as StagingTable1
  On [OF].[IndicatorList].[IndicatorID]=StagingTable1.IndicatorID


   Full Join
     (SELECT Distinct [IndicatorID]
  FROM [EAT_Reporting_BSOL].[OF].[IndicatorValue]) as OutputTable
    On
   [OF].[IndicatorList].[IndicatorID]=OutputTable.IndicatorID

   Full Join

   (SELECT Distinct [IndicatorID]
      ,[ReferenceID]
  FROM [EAT_Reporting_BSOL].[OF].[IndicatorDataPredefinedDenominator]) as StagingTable2 
   On 
   [OF].[IndicatorList].[IndicatorID]=StagingTable2.IndicatorID
   
   Order by
   [OF].[IndicatorList].[IndicatorID]
   
   --Coalesce(StagingTable1.IndicatorID, StagingTable2.IndicatorID, OutputTable.IndicatorID)
  