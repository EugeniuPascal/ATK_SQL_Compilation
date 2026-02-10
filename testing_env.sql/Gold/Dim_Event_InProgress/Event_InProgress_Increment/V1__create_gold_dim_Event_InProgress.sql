USE [ATK];
GO

IF OBJECT_ID(N'mis.Gold_Dim_Event_InProgress', 'U') IS NOT NULL
    DROP TABLE mis.Gold_Dim_Event_InProgress;
GO

CREATE TABLE mis.Gold_Dim_Event_InProgress
    (
        EventDate                 DATETIME        NULL,
        ClientType                VARCHAR(36)     NULL,
        ClientKind                VARCHAR(36)     NULL,
        ClientTRef                NVARCHAR(256)   NULL,
        ClientID                  VARCHAR(36)     NULL,
        CreditID                  VARCHAR(36)     NULL,
        CreditName                NVARCHAR(100)   NULL,
        ContactPerson             NVARCHAR(150)   NULL,
        ResponsibleID             VARCHAR(36)     NULL,
        ResponsibleName           NVARCHAR(40)    NULL,
        BranchID                  VARCHAR(36)     NULL,
        BranchName                NVARCHAR(100)   NULL,
        EventStatus               NVARCHAR(256)   NULL,
        EventKind                 NVARCHAR(256)   NULL,
        EventType                 NVARCHAR(256)   NULL,
        ProjectID                 VARCHAR(36)     NULL,
        ProjectName               NVARCHAR(100)   NULL,
        EventContent              NVARCHAR(1000)  NULL,
        EventResult               NVARCHAR(1000)  NULL,
        EventPandemicRelated      VARCHAR(36)     NULL,
        DecisionDeadline          DATETIME        NULL,
        MobilePhone               NVARCHAR(50)    NULL,
        AdditionalPhone           NVARCHAR(50)    NULL,
        PaymentDate               DATETIME        NULL,
        CallStatus                NVARCHAR(256)   NULL
    );
GO




