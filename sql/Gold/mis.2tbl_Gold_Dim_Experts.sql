USE [ATK];
GO


IF OBJECT_ID('mis.[2tbl_Gold_Dim_Experts]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_Experts];
GO

CREATE TABLE mis.[2tbl_Gold_Dim_Experts] (
    [ExpertID] VARCHAR(36) NOT NULL,
    [ExpertCode] INT NULL,
    [ExpertName] NVARCHAR(40) NULL,
    [HireDate] DATETIME NULL,
    [BirthDate] DATETIME NULL,
    [DismissalDate] DATETIME NULL,
    [Position] NVARCHAR(100) NULL,
    [TimesheetNumber] INT NULL,
    [ExperienceYears] INT NULL,
    [ExperienceMonths] INT NULL,
    [EmploymentPeriod] NVARCHAR(50) NULL
);
GO

INSERT INTO mis.[2tbl_Gold_Dim_Experts] (
    [ExpertID],
    [ExpertCode],
    [ExpertName],
    [HireDate],
    [BirthDate],
    [DismissalDate],
    [Position],
    [TimesheetNumber],
    [ExperienceYears],
    [ExperienceMonths],
    [EmploymentPeriod]
)
SELECT 
    [Сотрудники ID] AS ExpertID,
    [Сотрудники Код] AS ExpertCode,
    [Сотрудники Наименование] AS ExpertName,
    [Сотрудники Дата Приема] AS HireDate,
    [Сотрудники Дата Рождения] AS BirthDate,
    [Сотрудники Дата Увольнения] AS DismissalDate,
    [Сотрудники Должность Спр] AS Position,
    [Сотрудники Табельный Номер] AS TimesheetNumber,
    DATEDIFF(YEAR, [Сотрудники Дата Приема], GETDATE()) AS ExperienceYears,
    DATEDIFF(MONTH, [Сотрудники Дата Приема], GETDATE()) % 12 AS ExperienceMonths,
    CASE 
        WHEN [Сотрудники Дата Увольнения] IS NULL 
            THEN FORMAT([Сотрудники Дата Приема], 'yyyy-MM-dd') + N' → Present'
        ELSE FORMAT([Сотрудники Дата Приема], 'yyyy-MM-dd') + N' → ' + FORMAT([Сотрудники Дата Увольнения], 'yyyy-MM-dd')
    END AS EmploymentPeriod
FROM [ATK].[dbo].[Справочники.Сотрудники];
GO
