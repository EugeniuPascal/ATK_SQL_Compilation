USE [ATK];
GO

IF OBJECT_ID('mis.[2tbl_Gold_Dim_Employees]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_Employees];
GO

CREATE TABLE mis.[2tbl_Gold_Dim_Employees] (
    [EmployeeID] VARCHAR(36) NOT NULL,
    [EmployeeCode] INT NULL,
    [EmployeeName] NVARCHAR(40) NULL,
    [HireDate] DATETIME NULL,
    [BirthDate] DATETIME NULL,
    [DismissalDate] DATETIME NULL,
    [TimesheetNumber] INT NULL,
    [ExperienceYears] INT NULL,
    [ExperienceMonths] INT NULL,
    [EmploymentPeriod] NVARCHAR(50) NULL,
    [EmployeePositionID] VARCHAR(36) NULL,
    [EmployeePosition] NVARCHAR(150)  NULL
);
GO

INSERT INTO mis.[2tbl_Gold_Dim_Employees] (
    [EmployeeID],
    [EmployeeCode],
    [EmployeeName],
    [HireDate],
    [BirthDate],
    [DismissalDate],
    [TimesheetNumber],
    [ExperienceYears],
    [ExperienceMonths],
    [EmploymentPeriod],
    [EmployeePositionID],
    [EmployeePosition]
)
SELECT 
    a.[Сотрудники ID] AS EmployeeID,
    a.[Сотрудники Код] AS EmployeeCode,
    a.[Сотрудники Наименование] AS EmployeeName,
    a.[Сотрудники Дата Приема] AS HireDate,
    a.[Сотрудники Дата Рождения] AS BirthDate,
    a.[Сотрудники Дата Увольнения] AS DismissalDate,
    a.[Сотрудники Табельный Номер] AS TimesheetNumber,
    DATEDIFF(YEAR, a.[Сотрудники Дата Приема], GETDATE()) AS ExperienceYears,
    DATEDIFF(MONTH, a.[Сотрудники Дата Приема], GETDATE()) % 12 AS ExperienceMonths,
    CASE 
        WHEN a.[Сотрудники Дата Увольнения] IS NULL 
        THEN FORMAT(a.[Сотрудники Дата Приема], 'yyyy-MM-dd') + N' → Present'
        ELSE FORMAT(a.[Сотрудники Дата Приема], 'yyyy-MM-dd') + N' → ' + FORMAT(a.[Сотрудники Дата Увольнения], 'yyyy-MM-dd')
    END AS EmploymentPeriod,
    lastPos.[СотрудникиДанныеПоЗарплате Должность ID] AS EmployeePositionID,
    lastPos.[СотрудникиДанныеПоЗарплате Должность] AS EmployeePosition
FROM [ATK].[dbo].[Справочники.Сотрудники] AS a
OUTER APPLY (
    SELECT TOP 1 *
    FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате] AS b
    WHERE b.[СотрудникиДанныеПоЗарплате Сотрудник ID] = a.[Сотрудники ID]
    ORDER BY b.[СотрудникиДанныеПоЗарплате Период] DESC
) AS lastPos;
GO
