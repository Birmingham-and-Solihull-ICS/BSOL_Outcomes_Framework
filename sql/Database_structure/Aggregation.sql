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
CREATE TABLE [OF].[Aggregation]
	(
	[AggregationID] [smallint] IDENTITY(1,1) NOT NULL,
	[AggregationType] [nvarchar](50),
	[AggregationCode] [nvarchar](20),
	[AggregationLabel] [nvarchar](500) NULL,
	[FTPAreaType] [int] NULL
	)  ON [PRIMARY]
GO

ALTER TABLE [OF].[Aggregation] ADD CONSTRAINT
	PK_Aggregation_1 PRIMARY KEY CLUSTERED 
	(
	AggregationID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
ALTER TABLE [OF].[Aggregation] SET (LOCK_ESCALATION = TABLE)
GO
COMMIT