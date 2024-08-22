
  Insert into [EAT_Reporting_BSOL].[OF].[MetadataItems2]
  Select ItemLabel 
  from [EAT_Reporting_BSOL].[OF].[MetadataItems]
  Where ItemID in (10,12,9,11, 14, 25, 30)
  Union
  Select 'Rate Type'
  Union
  Select 'External Reference'
