USE [ATK];
GO

IF OBJECT_ID('[mis].[Gold_Dim_Limits]', 'U') IS NULL
BEGIN

    CREATE TABLE [mis].[Gold_Dim_Limits]
    (
        [LimitRegistrationID] VARCHAR(36) PRIMARY KEY,
        [LimitRegistrationDate] DATETIME,
        [AuthorID] VARCHAR(36),
        [AuthorName] NVARCHAR(255),
        [UsageType] NVARCHAR(256),
        [LimitType] NVARCHAR(256),
        [OperationType] NVARCHAR(256),
        [DecisionDate] DATETIME,
        [BaseDocumentType] VARCHAR(36),
        [BaseDocumentID] VARCHAR(36),
        [ValidityMonths] INT,
        [CommitteeID] VARCHAR(36),
        [CommitteeName] NVARCHAR(255),
        [Comment] NVARCHAR(1100),
        [CreditExpertID] VARCHAR(36),
        [CreditExpertName] NVARCHAR(50),
        [LimitRegLimitID] VARCHAR(36),
        [MainClientID] VARCHAR(36),
        [MainClientName] NVARCHAR(150),
        [CommitteeChairmanID] VARCHAR(36),
        [CommitteeChairmanName] NVARCHAR(50),
        [MIRepresentativeID] VARCHAR(36),
        [MIRepresentativeName] NVARCHAR(60),
        [RejectionReasonID] VARCHAR(36),
        [RejectionReason] NVARCHAR(255),
        [RejectionReasonDescription] NVARCHAR(300),
        [RegistrationStatus] NVARCHAR(256),
        [ApprovedAmount] DECIMAL(15,2),
        [DecisionText] NVARCHAR(1100),
        [BranchID] VARCHAR(36),
        [BranchName] NVARCHAR(150),
        [ExcessPercentage] DECIMAL(10,2),
        [SummaryData] VARCHAR(36),
        [SubmissionDate] DATETIME,
        [IsSummaryCompleted] VARCHAR(36),
        [AffiliatedGroupID] VARCHAR(36),
        [AffiliatedGroupName] NVARCHAR(256),
        [ConsolidatedBalance] DECIMAL(18,2),
        [EffectiveStartDate] DATETIME,
        [AnalysisType] NVARCHAR(256),
        [UnsecuredAmount] DECIMAL(18,2),
        [UnsecuredAmountComment] NVARCHAR(1100),
        [IsIndividualGuaranteeAnalyzed] VARCHAR(36),
        [ProceduralUnsecuredAmount] DECIMAL(18,2),
        [LimitID] VARCHAR(36),
        [LimitDeletedFlag] VARCHAR(36),
        [LimitCode] NVARCHAR(50),
        [GroupOwner] NVARCHAR(150),
        [GroupNameFull] NVARCHAR(255),
        [EmployeeID] VARCHAR(36)
    );
END;
GO
