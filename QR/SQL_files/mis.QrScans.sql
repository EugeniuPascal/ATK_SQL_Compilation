USE [ATK];
SET NOCOUNT ON;

-- Create QrScans table in mis schema
IF OBJECT_ID('[mis].[QrScans]', 'U') IS NULL
BEGIN
    CREATE TABLE [mis].[QrScans] (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        EmployeeID VARCHAR(50) NOT NULL,
		EmployeeName NVARCHAR(200) NULL,
		BranchID VARCHAR(50) NULL,
        ScanTime DATETIME NOT NULL DEFAULT GETDATE(),
        ClientIP VARCHAR(50),
        UserAgent NVARCHAR(200)
    );
END
GO