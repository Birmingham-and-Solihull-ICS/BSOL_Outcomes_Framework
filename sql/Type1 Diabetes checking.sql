

SELECT		[AUDIT_YEAR]		AS [TimePeriod]		
,			SUM(1)				[Count]

FROM		[LocalFeeds].[Reporting].[NationalDiabetesAudit_NDA_Core_Data] T1		--MLCSU source datatable

WHERE		1=1
AND			[DERIVED_CLEAN_DIABETES_TYPE] = 1		-- Type 1 Diabetes Flag
AND			[AUDIT_YEAR] IN  ('201415',
							  '201516',
							  '201617',
							  '201718',
							  '201819',
							  '201920',
							  '202021',
							  '202122E4',
							  '202223',
							  '202324E1' ) 

AND			[DERIVED_GP_PRACTICE_CODE] IN ( SELECT	GPPracticeCode_Current				--Cuurent BSOL GP Practice
											FROM	EAT_Reporting_BSOL.Reference.BSOL_ICS_PracticeMapped
											WHERE	Is_Current_Practice =1  )
GROUP BY	[AUDIT_YEAR]				

ORDER BY	1