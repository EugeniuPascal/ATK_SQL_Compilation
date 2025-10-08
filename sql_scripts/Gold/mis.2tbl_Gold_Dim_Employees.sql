USE [ATK];
GO

IF OBJECT_ID('mis.[2tbl_Gold_Dim_Employees]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_Employees];
GO

CREATE TABLE mis.[2tbl_Gold_Dim_Employees] (
    [EmployeeID] VARCHAR(36) NOT NULL,
    [EmployeeCode] INT NULL,
    [EmployeeName] NVARCHAR(40) NULL,
    [HireDate] NVARCHAR(10) NULL,
    [BirthDate] NVARCHAR(10) NULL,
    [DismissalDate] NVARCHAR(10) NULL,
    [TimesheetNumber] INT NULL,
    [ExperienceYears] INT NULL,
    [ExperienceMonths] INT NULL,
    [ExperienceYM] NVARCHAR(50) NULL,
    [EmploymentPeriod] NVARCHAR(50) NULL,
    [EmployeePositionID] VARCHAR(36) NULL,
    [EmployeePosition] NVARCHAR(150) NULL,
    [ExperienceYearIndex] INT NULL
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
    [ExperienceYM],
    [EmploymentPeriod],
    [EmployeePositionID],
    [EmployeePosition],
    [ExperienceYearIndex]
)
SELECT 
    a.[Сотрудники ID] AS EmployeeID,
    a.[Сотрудники Код] AS EmployeeCode,
    a.[Сотрудники Наименование] AS EmployeeName,
    
    -- HireDate
    CASE 
        WHEN a.[Сотрудники Дата Приема] IS NULL OR a.[Сотрудники Дата Приема] = '1753-01-01'
        THEN N'N/A'
        ELSE FORMAT(a.[Сотрудники Дата Приема], 'yyyy-MM-dd')
    END AS HireDate,
    
    -- BirthDate
    CASE 
        WHEN a.[Сотрудники Дата Рождения] IS NULL OR a.[Сотрудники Дата Рождения] = '1753-01-01'
        THEN N'N/A'
        ELSE FORMAT(a.[Сотрудники Дата Рождения], 'yyyy-MM-dd')
    END AS BirthDate,
    
    -- DismissalDate
    CASE 
        WHEN a.[Сотрудники Дата Увольнения] IS NULL OR a.[Сотрудники Дата Увольнения] = '1753-01-01'
        THEN N'N/A'
        ELSE FORMAT(a.[Сотрудники Дата Увольнения], 'yyyy-MM-dd')
    END AS DismissalDate,
    
    a.[Сотрудники Табельный Номер] AS TimesheetNumber,

    -- ExperienceYears
    CASE 
        WHEN a.[Сотрудники Дата Приема] IS NULL OR a.[Сотрудники Дата Приема] = '1753-01-01'
        THEN NULL
        ELSE DATEDIFF(YEAR, a.[Сотрудники Дата Приема], 
             CASE 
                 WHEN a.[Сотрудники Дата Увольнения] IS NULL OR a.[Сотрудники Дата Увольнения] = '1753-01-01'
                 THEN GETDATE()
                 ELSE a.[Сотрудники Дата Увольнения]
             END)
    END AS ExperienceYears,

    -- ExperienceMonths (months leftover after full years)
    CASE 
        WHEN a.[Сотрудники Дата Приема] IS NULL OR a.[Сотрудники Дата Приема] = '1753-01-01'
        THEN NULL
        ELSE DATEDIFF(MONTH, a.[Сотрудники Дата Приема], 
             CASE 
                 WHEN a.[Сотрудники Дата Увольнения] IS NULL OR a.[Сотрудники Дата Увольнения] = '1753-01-01'
                 THEN GETDATE()
                 ELSE a.[Сотрудники Дата Увольнения]
             END) % 12
    END AS ExperienceMonths,

    -- ExperienceYM
    CASE 
        WHEN a.[Сотрудники Дата Приема] IS NULL OR a.[Сотрудники Дата Приема] = '1753-01-01'
        THEN N'N/A'
        ELSE CAST(DATEDIFF(YEAR, a.[Сотрудники Дата Приема], 
                 CASE 
                     WHEN a.[Сотрудники Дата Увольнения] IS NULL OR a.[Сотрудники Дата Увольнения] = '1753-01-01'
                     THEN GETDATE()
                     ELSE a.[Сотрудники Дата Увольнения]
                 END) AS NVARCHAR(3)) + N' years ' +
             CAST(DATEDIFF(MONTH, a.[Сотрудники Дата Приема], 
                 CASE 
                     WHEN a.[Сотрудники Дата Увольнения] IS NULL OR a.[Сотрудники Дата Увольнения] = '1753-01-01'
                     THEN GETDATE()
                     ELSE a.[Сотрудники Дата Увольнения]
                 END) % 12 AS NVARCHAR(2)) + N' months'
    END AS ExperienceYM,

    -- EmploymentPeriod
    CASE 
        WHEN a.[Сотрудники Дата Приема] IS NULL OR a.[Сотрудники Дата Приема] = '1753-01-01'
        THEN N'N/A'
        WHEN a.[Сотрудники Дата Увольнения] IS NULL OR a.[Сотрудники Дата Увольнения] = '1753-01-01'
        THEN FORMAT(a.[Сотрудники Дата Приема], 'yyyy-MM-dd') + N' → Present'
        ELSE FORMAT(a.[Сотрудники Дата Приема], 'yyyy-MM-dd') + N' → ' + FORMAT(a.[Сотрудники Дата Увольнения], 'yyyy-MM-dd')
    END AS EmploymentPeriod,

    -- Employee Position
    lastPos.[СотрудникиДанныеПоЗарплате Должность ID] AS EmployeePositionID,
    lastPos.[СотрудникиДанныеПоЗарплате Должность] AS EmployeePosition,

    -- ExperienceYearIndex
    CASE 
        WHEN DATEDIFF(YEAR, a.[Сотрудники Дата Приема], 
             CASE 
                 WHEN a.[Сотрудники Дата Увольнения] IS NULL OR a.[Сотрудники Дата Увольнения] = '1753-01-01'
                 THEN GETDATE()
                 ELSE a.[Сотрудники Дата Увольнения]
             END) < 1 THEN 0
        WHEN DATEDIFF(YEAR, a.[Сотрудники Дата Приема], 
             CASE 
                 WHEN a.[Сотрудники Дата Увольнения] IS NULL OR a.[Сотрудники Дата Увольнения] = '1753-01-01'
                 THEN GETDATE()
                 ELSE a.[Сотрудники Дата Увольнения]
             END) BETWEEN 1 AND 20 THEN 1
        WHEN DATEDIFF(YEAR, a.[Сотрудники Дата Приема], 
             CASE 
                 WHEN a.[Сотрудники Дата Увольнения] IS NULL OR a.[Сотрудники Дата Увольнения] = '1753-01-01'
                 THEN GETDATE()
                 ELSE a.[Сотрудники Дата Увольнения]
             END) BETWEEN 21 AND 30 THEN 2
        WHEN DATEDIFF(YEAR, a.[Сотрудники Дата Приема], 
             CASE 
                 WHEN a.[Сотрудники Дата Увольнения] IS NULL OR a.[Сотрудники Дата Увольнения] = '1753-01-01'
                 THEN GETDATE()
                 ELSE a.[Сотрудники Дата Увольнения]
             END) BETWEEN 31 AND 40 THEN 3
        ELSE 4
    END AS ExperienceYearIndex

FROM [ATK].[dbo].[Справочники.Сотрудники] AS a
OUTER APPLY (
    SELECT TOP 1 *
    FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате] AS b
    WHERE b.[СотрудникиДанныеПоЗарплате Сотрудник ID] = a.[Сотрудники ID]
    ORDER BY b.[СотрудникиДанныеПоЗарплате Период] DESC
) AS lastPos;
GO
