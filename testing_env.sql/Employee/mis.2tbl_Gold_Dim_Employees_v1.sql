USE [ATK];
GO

IF OBJECT_ID('mis.[2tbl_Gold_Dim_Employees1]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_Employees1];
GO

CREATE TABLE mis.[2tbl_Gold_Dim_Employees1] (
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
    [EmploymentPeriod] NVARCHAR(50) NULL,
    [EmploymentPositionType] NVARCHAR(150) NULL,
    [EmpPositionIDdate] DATETIME
);
GO

INSERT INTO mis.[2tbl_Gold_Dim_Employees1] 
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
    [EmploymentPeriod],
    [EmploymentPositionType],
    [EmpPositionIDdate]
)
SELECT 
    e.[Сотрудники ID] AS EmployeeID,
    e.[Сотрудники Код] AS EmployeeCode,
    lastPos.[СотрудникиДанныеПоЗарплате Должность ID] AS EmployeePositionID,
    e.[Сотрудники Наименование] AS EmployeeName,
    lastPos.[СотрудникиДанныеПоЗарплате Должность] AS EmployeePosition,

    -- HireDate
    CASE 
        WHEN e.[Сотрудники Дата Приема] IS NULL OR e.[Сотрудники Дата Приема] = '1753-01-01' THEN N'N/A'
        ELSE FORMAT(e.[Сотрудники Дата Приема], 'yyyy-MM-dd')
    END AS HireDate,

    -- BirthDate
    CASE 
        WHEN e.[Сотрудники Дата Рождения] IS NULL OR e.[Сотрудники Дата Рождения] = '1753-01-01' THEN N'N/A'
        ELSE FORMAT(e.[Сотрудники Дата Рождения], 'yyyy-MM-dd')
    END AS BirthDate,

    -- DismissalDate
    CASE 
        WHEN e.[Сотрудники Дата Увольнения] IS NULL OR e.[Сотрудники Дата Увольнения] = '1753-01-01' THEN N'N/A'
        ELSE FORMAT(e.[Сотрудники Дата Увольнения], 'yyyy-MM-dd')
    END AS DismissalDate,

    e.[Сотрудники Табельный Номер] AS TimesheetNumber,

    -- ExperienceYears
    CASE 
        WHEN e.[Сотрудники Дата Приема] IS NULL OR e.[Сотрудники Дата Приема] = '1753-01-01' THEN NULL
        ELSE DATEDIFF(MONTH, e.[Сотрудники Дата Приема], 
             COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())
        ) / 12
    END AS ExperienceYears,

    -- Total months worked
    CASE 
        WHEN e.[Сотрудники Дата Приема] IS NULL OR e.[Сотрудники Дата Приема] = '1753-01-01' THEN NULL
        ELSE DATEDIFF(MONTH, e.[Сотрудники Дата Приема], 
             COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())
        )
    END AS ExperienceMonths,

    -- ExperienceYM
    CASE 
        WHEN e.[Сотрудники Дата Приема] IS NULL OR e.[Сотрудники Дата Приема] = '1753-01-01' THEN N'N/A'
        ELSE CAST(DATEDIFF(MONTH, e.[Сотрудники Дата Приема], 
                 COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())
            ) / 12 AS NVARCHAR(3)) 
            + N' years ' + 
            CAST(DATEDIFF(MONTH, e.[Сотрудники Дата Приема], 
                 COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())
            ) % 12 AS NVARCHAR(2)) 
            + N' months'
    END AS ExperienceYM,

    -- ExperienceMonthsRange
    CASE 
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())) BETWEEN 1 AND 5 THEN N'1-5 m'
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())) BETWEEN 6 AND 11 THEN N'6-11 m'
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())) BETWEEN 12 AND 35 THEN N'12-35 m'
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())) > 35 THEN N'36+ m'
        ELSE N'N/A'
    END AS ExperienceMonthsRange,

    -- ExperienceIndex
    CASE 
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())) BETWEEN 1 AND 5 THEN 1
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())) BETWEEN 6 AND 11 THEN 2
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())) BETWEEN 12 AND 35 THEN 3
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())) > 35 THEN 4
        ELSE NULL
    END AS ExperienceIndex,

    -- EmploymentPeriod
    CASE 
        WHEN e.[Сотрудники Дата Приема] IS NULL OR e.[Сотрудники Дата Приема] = '1753-01-01' THEN N'N/A'
        WHEN e.[Сотрудники Дата Увольнения] IS NULL OR e.[Сотрудники Дата Увольнения] = '1753-01-01'
            THEN FORMAT(e.[Сотрудники Дата Приема], 'yyyy-MM-dd') + N' → Present'
        ELSE FORMAT(e.[Сотрудники Дата Приема], 'yyyy-MM-dd') + N' → ' + FORMAT(e.[Сотрудники Дата Увольнения], 'yyyy-MM-dd')
    END AS EmploymentPeriod,

    lastPos.[СотрудникиДанныеПоЗарплате Должность] AS EmploymentPositionType,
    firstAssigned.FirstDate AS EmpPositionIDdate

FROM [ATK].[dbo].[Справочники.Сотрудники] AS e
OUTER APPLY (
    -- get last/current position
    SELECT TOP 1 *
    FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате] AS b
    WHERE b.[СотрудникиДанныеПоЗарплате Сотрудник ID] = e.[Сотрудники ID]
    ORDER BY b.[СотрудникиДанныеПоЗарплате Период] DESC
) AS lastPos
OUTER APPLY (
    -- get first date when last position was assigned
    SELECT MIN(b.[СотрудникиДанныеПоЗарплате Период]) AS FirstDate
    FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате] AS b
    WHERE b.[СотрудникиДанныеПоЗарплате Сотрудник ID] = e.[Сотрудники ID]
      AND b.[СотрудникиДанныеПоЗарплате Вид Должности ID] = lastPos.[СотрудникиДанныеПоЗарплате Вид Должности ID]
) AS firstAssigned;
GO
