USE [ATK];
GO

IF OBJECT_ID('[mis].[Gold_Fact_Restruct_Daily_Sold_Par]', 'U') IS NULL
BEGIN
    CREATE TABLE [mis].[Gold_Fact_Restruct_Daily_Sold_Par] 
    (
        SoldDate              DATE          NOT NULL,
        CreditID              VARCHAR(36)   NOT NULL,
        ClientID              VARCHAR(36)   NOT NULL,
        Balance_Total         MONEY        NULL,
        IRR_Values            DECIMAL(18,6) NULL,
        DaysBucket_Credit     INT           NULL,
        DaysFact_Total        INT           NULL,
        DaysIFRS              INT           NULL,
        StateName_Final       NVARCHAR(200) NULL,
        TypeName_Sticky_Final NVARCHAR(200) NULL,
        CreditStatus_Base     NVARCHAR(200) NULL,
        LastBranchID          VARCHAR(64)   NULL,
        LastEmployeeID        VARCHAR(64)   NULL,
        BranchID              VARCHAR(36)   NULL,
        EmployeeID            VARCHAR(36)   NULL,
        IsSpecialBranch       BIT           NULL,
        SegmentIFRS           NVARCHAR(20)  NULL,
        ParIFRS               NVARCHAR(20)  NULL,
        Par                   NVARCHAR(20)  NULL,
        StageName             NVARCHAR(200) NULL,
        CONSTRAINT PK_Gold_Fact_Restruct_Daily_Sold_Par
            PRIMARY KEY (ClientID, CreditID, SoldDate)
    );
END;
GO
