/* PCN */
Insert into [OF].[Aggregation]
SELECT 'PCN' as Aggregation,
		[PCN_Code] as AggregationCode,
		[PCN] as AggregationLabel
      
  FROM [EAT_Reporting_BSOL].[Reference].[vw_BSOL_PCN_to_Locality]


/* Ward */
Insert into [OF].[Aggregation]
select  Distinct 
'Ward' as AggregationType,
WD19CD as AggregationCode,
WD19NM as AggregationLabel
FROM [Reference].[Ref].[LSOA_WARD_LAD]
Where LAD19CD in( 'E08000025' --Birmingham
				, 'E08000029' --Solihull
				)

/* Cnstituency */
Insert into [OF].[Aggregation]
Select distinct		'Constituency' as AggregationType, 
					[PCON19CD] as AggregationCode,
					[PCON19NM] as AggregationLabel
 from working.[DEFAULTS].[BSOL_0863_Ward(2019)_to_Constituency_toLA]
 Where LAD19CD in( 'E08000025' --Birmingham
				, 'E08000029')


/* Local Authority */
Insert into [OF].[Aggregation]
Select 'Local Authority'as AggregationType, 'E08000029' as AggregationCode, 'Solihull' as AggregationLabel	
UNION ALL
Select 'Local Authority'as AggregationType, 'E08000025' as AggregationCode, 'Birmingham' as AggregationLabel	


/* ICB */
Insert into [OF].[Aggregation]
Select 'ICB'as AggregationType, 'E08000025' as AggregationCode, 'BSOL ICB' as AggregationLabel	

/* ENgland */
Insert into [OF].[Aggregation]
Select 'England'as AggregationType, 'E92000001' as AggregationCode, 'England' as AggregationLabel	


	