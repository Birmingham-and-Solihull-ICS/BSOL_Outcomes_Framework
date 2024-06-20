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
CREATE TABLE [OF].[IndicatorValue]
	(
	ValueID int NOT NULL IDENTITY (1, 1),
	IndicatorID int NOT NULL,
	InsertDate datetime NOT NULL,
	Numerator decimal(18, 5) NULL,
	Denominator decimal(18, 5) NULL,
	IndicatorValue decimal(18, 5) NULL,
	LowerCI95 decimal(18, 5) NULL,
	UpperCI95 decimal(18, 5) NULL,
	AggregationID smallint NOT NULL,
	DemographicID smallint NOT NULL,
	DataQualityID smallint NOT NULL,
	IndicatorStartDate datetime NOT NULL,
	IndicatorEndDate datetime NULL
	)  ON [PRIMARY]
GO
ALTER TABLE [OF].[IndicatorValue] ADD CONSTRAINT
	DF_IndicatorValue_1_InsertDate DEFAULT GETDATE() FOR InsertDate
GO
ALTER TABLE [OF].[IndicatorValue] ADD CONSTRAINT
	PK_IndicatorValue_1 PRIMARY KEY CLUSTERED 
	(
	ValueID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
ALTER TABLE [OF].IndicatorValue SET (LOCK_ESCALATION = TABLE)
GO
COMMIT