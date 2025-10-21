USE [ATK];
GO

IF OBJECT_ID('mis.[2tbl_Gold_Dim_Employees]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_Employees];
GO

CREATE TABLE mis.[2tbl_Gold_Dim_Employees] (
    [EmployeeID] VARCHAR(36) NOT NULL,
    [EmployeeCode] INT NULL,
    [EmployeePositionID] VARCHAR(36) NULL,
    [EmployeeName] NVARCHAR(40) NULL,
    [EmployeePosition] NVARCHAR(150) NULL,
    [HireDate] NVARCHAR(10) NULL,
    [BirthDate] NVARCHAR(10) NULL,
    [DismissalDate] NVARCHAR(10) NULL,
    [TimesheetNumber] INT NULL,
    [ExperienceYears] INT NULL,
    [ExperienceMonths] INT NULL,
    [ExperienceYM] NVARCHAR(50) NULL,
	[ExperienceMonthsRange] NVARCHAR(50) NULL,
    [ExperienceIndex] INT NULL,
    [EmploymentPeriod] NVARCHAR(50) NULL
);
GO

INSERT INTO mis.[2tbl_Gold_Dim_Employees] 
(
    [EmployeeID],
    [EmployeeCode],
    [EmployeePositionID],
    [EmployeeName],
    [EmployeePosition],
    [HireDate],
    [BirthDate],
    [DismissalDate],
    [TimesheetNumber],
    [ExperienceYears],
    [ExperienceMonths],
    [ExperienceYM],
	[ExperienceMonthsRange],
    [ExperienceIndex],
    [EmploymentPeriod]  
)
SELECT 
    a.[Сотрудники ID] AS EmployeeID,
    a.[Сотрудники Код] AS EmployeeCode,
    lastPos.[СотрудникиДанныеПоЗарплате Должность ID] AS EmployeePositionID,
    a.[Сотрудники Наименование] AS EmployeeName,
    lastPos.[СотрудникиДанныеПоЗарплате Должность] AS EmployeePosition,

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

    -- ExperienceYears as INT
    CASE 
        WHEN a.[Сотрудники Дата Приема] IS NULL OR a.[Сотрудники Дата Приема] = '1753-01-01'
        THEN NULL
        ELSE DATEDIFF(MONTH, a.[Сотрудники Дата Приема], 
             CASE 
                 WHEN a.[Сотрудники Дата Увольнения] IS NULL OR a.[Сотрудники Дата Увольнения] = '1753-01-01'
                 THEN GETDATE()
                 ELSE a.[Сотрудники Дата Увольнения]
             END) / 12
    END AS ExperienceYears,

    -- Total months worked
    CASE 
        WHEN a.[Сотрудники Дата Приема] IS NULL OR a.[Сотрудники Дата Приема] = '1753-01-01'
        THEN NULL
        ELSE DATEDIFF(MONTH, a.[Сотрудники Дата Приема], 
             CASE 
                 WHEN a.[Сотрудники Дата Увольнения] IS NULL OR a.[Сотрудники Дата Увольнения] = '1753-01-01'
                 THEN GETDATE()
                 ELSE a.[Сотрудники Дата Увольнения]
             END)
    END AS ExperienceMonths,

    -- ExperienceYM
    CASE 
        WHEN a.[Сотрудники Дата Приема] IS NULL OR a.[Сотрудники Дата Приема] = '1753-01-01'
        THEN N'N/A'
        ELSE 
            CAST(DATEDIFF(MONTH, a.[Сотрудники Дата Приема], 
                 CASE WHEN a.[Сотрудники Дата Увольнения] IS NULL OR a.[Сотрудники Дата Увольнения] = '1753-01-01' 
                      THEN GETDATE() ELSE a.[Сотрудники Дата Увольнения] END) / 12 AS NVARCHAR(3)) 
            + N' years ' + 
            CAST(DATEDIFF(MONTH, a.[Сотрудники Дата Приема], 
                 CASE WHEN a.[Сотрудники Дата Увольнения] IS NULL OR a.[Сотрудники Дата Увольнения] = '1753-01-01' 
                      THEN GETDATE() ELSE a.[Сотрудники Дата Увольнения] END) % 12 AS NVARCHAR(2)) 
            + N' months'
    END AS ExperienceYM,
	
	-- Add ExperienceMonthsRange
    CASE 
        WHEN DATEDIFF(MONTH, a.[Сотрудники Дата Приема], 
             CASE 
                 WHEN a.[Сотрудники Дата Увольнения] IS NULL OR a.[Сотрудники Дата Увольнения] = '1753-01-01'
                 THEN GETDATE()
                 ELSE a.[Сотрудники Дата Увольнения]
             END) BETWEEN 1 AND 5 THEN N'1-5 m'
        WHEN DATEDIFF(MONTH, a.[Сотрудники Дата Приема], 
             CASE 
                 WHEN a.[Сотрудники Дата Увольнения] IS NULL OR a.[Сотрудники Дата Увольнения] = '1753-01-01'
                 THEN GETDATE()
                 ELSE a.[Сотрудники Дата Увольнения]
             END) BETWEEN 6 AND 11 THEN N'6-11 m'
        WHEN DATEDIFF(MONTH, a.[Сотрудники Дата Приема], 
             CASE 
                 WHEN a.[Сотрудники Дата Увольнения] IS NULL OR a.[Сотрудники Дата Увольнения] = '1753-01-01'
                 THEN GETDATE()
                 ELSE a.[Сотрудники Дата Увольнения]
             END) BETWEEN 12 AND 35 THEN N'12-35 m'
        WHEN DATEDIFF(MONTH, a.[Сотрудники Дата Приема], 
             CASE 
                 WHEN a.[Сотрудники Дата Увольнения] IS NULL OR a.[Сотрудники Дата Увольнения] = '1753-01-01'
                 THEN GETDATE()
                 ELSE a.[Сотрудники Дата Увольнения]
             END) > 35 THEN N'36+ m'
    ELSE N'N/A'
END AS ExperienceMonthsRange,

-- ExperienceIndex
   CASE 
        WHEN DATEDIFF(MONTH, a.[Сотрудники Дата Приема], 
             CASE WHEN a.[Сотрудники Дата Увольнения] IS NULL OR a.[Сотрудники Дата Увольнения] = '1753-01-01' 
               THEN GETDATE() ELSE a.[Сотрудники Дата Увольнения] END) BETWEEN 1 AND 5 THEN 1
        WHEN DATEDIFF(MONTH, a.[Сотрудники Дата Приема], 
             CASE WHEN a.[Сотрудники Дата Увольнения] IS NULL OR a.[Сотрудники Дата Увольнения] = '1753-01-01' 
               THEN GETDATE() ELSE a.[Сотрудники Дата Увольнения] END) BETWEEN 6 AND 11 THEN 2
        WHEN DATEDIFF(MONTH, a.[Сотрудники Дата Приема], 
             CASE WHEN a.[Сотрудники Дата Увольнения] IS NULL OR a.[Сотрудники Дата Увольнения] = '1753-01-01' 
               THEN GETDATE() ELSE a.[Сотрудники Дата Увольнения] END) BETWEEN 12 AND 35 THEN 3
        WHEN DATEDIFF(MONTH, a.[Сотрудники Дата Приема], 
             CASE WHEN a.[Сотрудники Дата Увольнения] IS NULL OR a.[Сотрудники Дата Увольнения] = '1753-01-01' 
               THEN GETDATE() ELSE a.[Сотрудники Дата Увольнения] END) > 35 THEN 4
        ELSE NULL
    END AS ExperienceIndex,

    -- EmploymentPeriod
    CASE 
        WHEN a.[Сотрудники Дата Приема] IS NULL OR a.[Сотрудники Дата Приема] = '1753-01-01'
        THEN N'N/A'
        WHEN a.[Сотрудники Дата Увольнения] IS NULL OR a.[Сотрудники Дата Увольнения] = '1753-01-01'
        THEN FORMAT(a.[Сотрудники Дата Приема], 'yyyy-MM-dd') + N' → Present'
        ELSE FORMAT(a.[Сотрудники Дата Приема], 'yyyy-MM-dd') + N' → ' + FORMAT(a.[Сотрудники Дата Увольнения], 'yyyy-MM-dd')
    END AS EmploymentPeriod

FROM [ATK].[dbo].[Справочники.Сотрудники] AS a
OUTER APPLY (
    SELECT TOP 1 *
    FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате] AS b
    WHERE b.[СотрудникиДанныеПоЗарплате Сотрудник ID] = a.[Сотрудники ID]
    ORDER BY b.[СотрудникиДанныеПоЗарплате Период] DESC
) AS lastPos;
GO
