/* To prevent any potential data loss issues, you should review this script in detail before running it outside the context of the database designer.*/
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
CREATE TABLE [OF].[Demographic]
	(
	DemographicID smallint NOT NULL IDENTITY (1, 1),
	DemographicLabel nvarchar(120),
	Gender nvarchar(12),
	IMD int,
	AgeGrp nvarchar(20),
	Ethnicity nvarchar(12)
	)  ON [PRIMARY]
GO

ALTER TABLE [OF].[Demographic] ADD CONSTRAINT
	PK_Demographic_1 PRIMARY KEY CLUSTERED 
	(
	DemographicID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
ALTER TABLE [OF].[Demographic] SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
