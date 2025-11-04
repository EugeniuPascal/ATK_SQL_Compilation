USE [ATK];
GO

IF OBJECT_ID('mis.[Gold_Dim_EmployeePayrollData]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_EmployeePayrollData];
GO

CREATE TABLE mis.[Gold_Dim_EmployeePayrollData]
(
    EmployeePositionID VARCHAR(36) NOT NULL,
    EmployeePosition NVARCHAR(150) NULL
);
GO

INSERT INTO mis.[Gold_Dim_EmployeePayrollData] 
(
    EmployeePositionID,
    EmployeePosition
)
SELECT 
    [СотрудникиДанныеПоЗарплате Должность ID] AS EmployeePositionID,
	[СотрудникиДанныеПоЗарплате Должность] AS EmployeePosition
    

FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате];
GO
