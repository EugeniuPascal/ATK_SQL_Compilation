USE [ATK];
GO

-- Drop table if exists
IF OBJECT_ID('mis.[2tbl_Gold_Dim_EmployeePayrollData]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_EmployeePayrollData];
GO

-- Create table
CREATE TABLE mis.[2tbl_Gold_Dim_EmployeePayrollData]
(
    EmployeePositionID VARCHAR(36) NOT NULL,
    EmployeePosition NVARCHAR(150) NULL
);
GO

-- Insert normalized and mapped positions
INSERT INTO mis.[2tbl_Gold_Dim_EmployeePayrollData] 
(
    EmployeePositionID,
    EmployeePosition
)
SELECT 
    [СотрудникиДанныеПоЗарплате Должность ID] AS EmployeePositionID,
	[СотрудникиДанныеПоЗарплате Должность] AS EmployeePosition
    

FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате];
GO
