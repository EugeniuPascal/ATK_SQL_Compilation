USE [ATK];
GO

IF OBJECT_ID('mis.[EmployeeQR_AllScans]', 'U') IS NOT NULL
    DROP TABLE mis.[EmployeeQR_AllScans];
GO

CREATE TABLE mis.[EmployeeQR_AllScans] 
(
    [ID] INT IDENTITY(1,1) NOT NULL PRIMARY KEY, -- surrogate PK
    [EmployeeID]        VARCHAR(36)  NOT NULL,
    [EmployeeName]      NVARCHAR(255) NULL,
    [BranchID]          VARCHAR(36)  NULL,
    [BranchName]        NVARCHAR(255) NULL,
    [CreatedAt]         DATETIME     NULL,

    [ScanTime]          DATETIME     NULL,
    [ClientIP]          VARCHAR(50)  NULL,
    [UserAgent]         NVARCHAR(255) NULL
);
GO
