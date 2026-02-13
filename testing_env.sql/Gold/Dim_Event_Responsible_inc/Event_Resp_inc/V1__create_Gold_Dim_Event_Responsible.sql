USE [ATK];
GO

IF OBJECT_ID('[mis].[Gold_Dim_Event_Responsible]', 'U') IS NULL
BEGIN

    CREATE TABLE [mis].[Gold_Dim_Event_Responsible]
    (
        EventDocumentID      VARCHAR(36)   NOT NULL,
        EventRowNumber       INT           NULL,
        ClientType           VARCHAR(36)   NULL,
        ClientKind           VARCHAR(36)   NULL,
        ClientID             VARCHAR(36)   NULL,
        EventStatus          NVARCHAR(256) NULL,
        ResponsibleID        VARCHAR(36)   NULL,
        ResponsibleName      NVARCHAR(40)  NULL,
        SelectionFlag        VARCHAR(36)   NULL,
        NewResponsibleID     VARCHAR(36)   NULL,
        NewResponsibleName   NVARCHAR(40)  NULL,
        NewBranchID          VARCHAR(36)   NULL,
        NewBranchName        NVARCHAR(100) NULL,
        AffiliatedGroupID    VARCHAR(36)   NULL,
        AffiliatedGroupName  NVARCHAR(150) NULL
    );
END;
GO
