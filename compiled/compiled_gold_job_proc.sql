-- =============================================
-- Compiled Stored Procedure for MSSQL Agent Job (Gold) - Idempotent with Logging
-- Generated: 2026-02-26 11:49:25.741895
-- Source folder: C:\ATK_Project\sql_scripts\Gold
-- Files included: 10
--   mis.Gold_Dim_AppUsers.sql
--   mis.Gold_Dim_Branch.sql
--   mis.Gold_Dim_EmployeePayrollData.sql
--   mis.Gold_Dim_Employees.sql
--   mis.Gold_Dim_GroupMembershipPeriods.sql
--   mis.Gold_Fact_BudgetEmployees.sql
--   mis.Gold_Fact_Comments.sql
--   mis.Gold_Fact_CPD.sql
--   mis.Gold_Fact_CreditsInShadowBranches.sql
--   mis.Gold_Fact_WriteOffCredits.sql
-- Requires: SQL Server 2016 SP1+ for CREATE OR ALTER
-- =============================================

USE [ATK];
GO

IF OBJECT_ID('mis.usp_GoldTables', 'P') IS NOT NULL
    DROP PROCEDURE mis.usp_GoldTables;
GO

CREATE PROCEDURE mis.usp_GoldTables
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @StartTime DATETIME;
    DECLARE @EndTime DATETIME;
    DECLARE @Status NVARCHAR(50);

    DECLARE @FailureNote NVARCHAR(MAX);

    -- Start of: mis.Gold_Dim_AppUsers.sql
    SET @StartTime = GETDATE();
    SET @EndTime = NULL;
    SET @Status = 'Running';
    SET @sql = N'IF OBJECT_ID(''mis.[Gold_Dim_AppUsers]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_AppUsers];

CREATE TABLE mis.[Gold_Dim_AppUsers]
(
    App_User_ClientID VARCHAR(36) NOT NULL,
    App_User_UserID VARCHAR(36) NOT NULL,
    App_User_Phone NVARCHAR(50) NULL,
    App_User_FiscalCode NVARCHAR(20) NULL,
    App_User_ClientName NVARCHAR(100) NULL
);

INSERT INTO mis.[Gold_Dim_AppUsers] 
(
    App_User_ClientID,
    App_User_UserID,
    App_User_Phone,
    App_User_FiscalCode,
    App_User_ClientName
)
SELECT
	[СведенияОПользователяхМобильногоПриложения Клиент ID]       AS App_User_ClientID, 
	[СведенияОПользователяхМобильногоПриложения Ид Пользователя] AS App_User_UserID,
    [СведенияОПользователяхМобильногоПриложения Телефон]         AS App_User_Phone,
    [СведенияОПользователяхМобильногоПриложения Фиск Код]        AS App_User_FiscalCode,
    [СведенияОПользователяхМобильногоПриложения Клиент]          AS App_User_ClientName

FROM [ATK].[mis].[Bronze_РегистрыСведений.СведенияОПользователяхМобильногоПриложения];';
    BEGIN TRY
        SET @FailureNote = '';
        EXEC sys.sp_executesql @sql;
        SET @Status = 'Success';
    END TRY
    BEGIN CATCH
        SET @Status = 'Failed';
        SET @FailureNote = CONCAT(
            'Msg: ', ERROR_MESSAGE(),
            ' | Line: ', ERROR_LINE(),
            ' | Number: ', ERROR_NUMBER()
        );
        -- Continue to next file without THROW
    END CATCH;

    SET @EndTime = GETDATE();
    INSERT INTO mis.Gold_Proc_Exec_Log (TableName, StartTime, EndTime, Status, Failure_Note)
    VALUES ('mis.Gold_Dim_AppUsers', @StartTime, @EndTime, @Status, @FailureNote);

    -- Start of: mis.Gold_Dim_Branch.sql
    SET @StartTime = GETDATE();
    SET @EndTime = NULL;
    SET @Status = 'Running';
    SET @sql = N'IF OBJECT_ID(N''mis.[Gold_Dim_Branch]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_Branch];

CREATE TABLE mis.[Gold_Dim_Branch] 
(
    BranchID VARCHAR(36) NOT NULL,
    BranchCode DECIMAL(3, 0) NULL,
    BranchName NVARCHAR(100) NULL,
    DistrictName NVARCHAR(50) NULL,
    ActivityType NVARCHAR(100) NULL,
    EFSERegion NVARCHAR(50) NULL,
    Address NVARCHAR(150) NULL,
    Phones NVARCHAR(150) NULL,
    Email NVARCHAR(150) NULL,
    PrintBranchName NVARCHAR(100) NULL,
    Latitude DECIMAL(12, 8) NULL,
    Longitude DECIMAL(12, 8) NULL,
    BranchDepartment NVARCHAR(150) NULL,
	BranchDepartmentID VARCHAR(36) NULL,
    BranchRegion NVARCHAR(100) NULL,
	BranchRegionID VARCHAR(36) NULL
);

WITH LastSvedeniya AS (
    SELECT 
        [СведенияОФилиалах Филиал ID],
        [СведенияОФилиалах Дирекция],
		[СведенияОФилиалах Дирекция ID],
        [СведенияОФилиалах Регион],
		[СведенияОФилиалах Регион ID],
        ROW_NUMBER() OVER (
            PARTITION BY [СведенияОФилиалах Филиал ID] 
            ORDER BY [СведенияОФилиалах Период] DESC
        ) AS rn
    FROM [ATK].[dbo].[РегистрыСведени.СведенияОФилиалах]
)
INSERT INTO mis.[Gold_Dim_Branch] 
(
    BranchID,
    BranchCode,
    BranchName,
    DistrictName,
    ActivityType,
    EFSERegion,
    Address,
    Phones,
    Email,
    PrintBranchName,
    Latitude,
    Longitude,
    BranchDepartment,
	BranchDepartmentID,
    BranchRegion,
	BranchRegionID
)
SELECT
    f.[Филиалы ID] AS [BranchID],
    f.[Филиалы Код],
    f.[Филиалы Наименование],
    f.[Филиалы Наименование Района],
    f.[Филиалы Вид Деятельности],
    f.[Филиалы Регион EFSE],
    f.[Филиалы Адрес],
    f.[Филиалы Телефоны],
    f.[Филиалы Электронный Адрес],
    f.[Филиалы Наименование Филиала для Печати],
    f.[Филиалы Координаты Широта],
    f.[Филиалы Координаты Долгота],
    s.[СведенияОФилиалах Дирекция],
	s.[СведенияОФилиалах Дирекция ID],
    s.[СведенияОФилиалах Регион],
	s.[СведенияОФилиалах Регион ID]
FROM [ATK].[dbo].[Справочники.Филиалы] f
LEFT JOIN LastSvedeniya s
    ON f.[Филиалы ID] = s.[СведенияОФилиалах Филиал ID]
    AND s.rn = 1;';
    BEGIN TRY
        SET @FailureNote = '';
        EXEC sys.sp_executesql @sql;
        SET @Status = 'Success';
    END TRY
    BEGIN CATCH
        SET @Status = 'Failed';
        SET @FailureNote = CONCAT(
            'Msg: ', ERROR_MESSAGE(),
            ' | Line: ', ERROR_LINE(),
            ' | Number: ', ERROR_NUMBER()
        );
        -- Continue to next file without THROW
    END CATCH;

    SET @EndTime = GETDATE();
    INSERT INTO mis.Gold_Proc_Exec_Log (TableName, StartTime, EndTime, Status, Failure_Note)
    VALUES ('mis.Gold_Dim_Branch', @StartTime, @EndTime, @Status, @FailureNote);

    -- Start of: mis.Gold_Dim_EmployeePayrollData.sql
    SET @StartTime = GETDATE();
    SET @EndTime = NULL;
    SET @Status = 'Running';
    SET @sql = N'IF OBJECT_ID(''mis.[Gold_Dim_EmployeePayrollData]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_EmployeePayrollData];

CREATE TABLE mis.[Gold_Dim_EmployeePayrollData]
(
    EmployeePositionID VARCHAR(36) NOT NULL,
    EmployeePosition NVARCHAR(150) NULL
);

INSERT INTO mis.[Gold_Dim_EmployeePayrollData] 
(
    EmployeePositionID,
    EmployeePosition
)
SELECT 
    [СотрудникиДанныеПоЗарплате Должность ID] AS EmployeePositionID,
	[СотрудникиДанныеПоЗарплате Должность] AS EmployeePosition
    

FROM [ATK].[mis].[Bronze_РегистрыСведений.СотрудникиДанныеПоЗарплате];';
    BEGIN TRY
        SET @FailureNote = '';
        EXEC sys.sp_executesql @sql;
        SET @Status = 'Success';
    END TRY
    BEGIN CATCH
        SET @Status = 'Failed';
        SET @FailureNote = CONCAT(
            'Msg: ', ERROR_MESSAGE(),
            ' | Line: ', ERROR_LINE(),
            ' | Number: ', ERROR_NUMBER()
        );
        -- Continue to next file without THROW
    END CATCH;

    SET @EndTime = GETDATE();
    INSERT INTO mis.Gold_Proc_Exec_Log (TableName, StartTime, EndTime, Status, Failure_Note)
    VALUES ('mis.Gold_Dim_EmployeePayrollData', @StartTime, @EndTime, @Status, @FailureNote);

    -- Start of: mis.Gold_Dim_Employees.sql
    SET @StartTime = GETDATE();
    SET @EndTime = NULL;
    SET @Status = 'Running';
    SET @sql = N'IF OBJECT_ID(''mis.[Gold_Dim_Employees]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_Employees];

CREATE TABLE mis.[Gold_Dim_Employees] 
(
    [EmployeeID] VARCHAR(36) NOT NULL,
	[BranchID] VARCHAR(36) NULL,
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
    [EmpPositionIDdate] DATETIME,
	[ExperienceMonthsLastPosition] INT NULL,
	[ExperienceMonthsRangeLastPosition] NVARCHAR(50) NULL,
	[ExperienceIndexLastPosition] INT
);

INSERT INTO mis.[Gold_Dim_Employees] 
(
    [EmployeeID],
	[BranchID],
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
    [EmpPositionIDdate],
	[ExperienceMonthsLastPosition],
	[ExperienceMonthsRangeLastPosition],
	[ExperienceIndexLastPosition]
)
SELECT 
    e.[Сотрудники ID] AS EmployeeID,
	lastPos.[СотрудникиДанныеПоЗарплате Филиал ID] AS [BranchID],
    e.[Сотрудники Код] AS EmployeeCode,
    lastPos.[СотрудникиДанныеПоЗарплате Должность ID] AS EmployeePositionID,
    e.[Сотрудники Наименование] AS EmployeeName,
    lastPos.[СотрудникиДанныеПоЗарплате Должность] AS EmployeePosition,

    
    CASE 
        WHEN e.[Сотрудники Дата Приема] IS NULL OR e.[Сотрудники Дата Приема] = ''1753-01-01'' THEN N''N/A''
        ELSE FORMAT(e.[Сотрудники Дата Приема], ''yyyy-MM-dd'')
    END AS HireDate,

    
    CASE 
        WHEN e.[Сотрудники Дата Рождения] IS NULL OR e.[Сотрудники Дата Рождения] = ''1753-01-01'' THEN N''N/A''
        ELSE FORMAT(e.[Сотрудники Дата Рождения], ''yyyy-MM-dd'')
    END AS BirthDate,

    
    CASE 
        WHEN e.[Сотрудники Дата Увольнения] IS NULL OR e.[Сотрудники Дата Увольнения] = ''1753-01-01'' THEN N''N/A''
        ELSE FORMAT(e.[Сотрудники Дата Увольнения], ''yyyy-MM-dd'')
    END AS DismissalDate,

    e.[Сотрудники Табельный Номер] AS TimesheetNumber,

    
    CASE 
        WHEN e.[Сотрудники Дата Приема] IS NULL OR e.[Сотрудники Дата Приема] = ''1753-01-01'' THEN NULL
        ELSE DATEDIFF(MONTH, e.[Сотрудники Дата Приема], 
             COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())
        ) / 12
    END AS ExperienceYears,

    
    CASE 
        WHEN e.[Сотрудники Дата Приема] IS NULL OR e.[Сотрудники Дата Приема] = ''1753-01-01'' THEN NULL
        ELSE DATEDIFF(MONTH, e.[Сотрудники Дата Приема], 
             COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())
        )
    END AS ExperienceMonths,

    
    CASE 
        WHEN e.[Сотрудники Дата Приема] IS NULL OR e.[Сотрудники Дата Приема] = ''1753-01-01'' THEN N''N/A''
        ELSE CAST(DATEDIFF(MONTH, e.[Сотрудники Дата Приема], 
                 COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())
            ) / 12 AS NVARCHAR(3)) 
            + N'' years '' + 
            CAST(DATEDIFF(MONTH, e.[Сотрудники Дата Приема], 
                 COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())
            ) % 12 AS NVARCHAR(2)) 
            + N'' months''
    END AS ExperienceYM,

    
    CASE 
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) BETWEEN 0 AND 5 THEN N''1-5 m''
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) BETWEEN 6 AND 11 THEN N''6-11 m''
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) BETWEEN 12 AND 35 THEN N''12-35 m''
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) > 35 THEN N''36+ m''
        ELSE N''N/A''
    END AS ExperienceMonthsRange,

    
    CASE 
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) BETWEEN 0 AND 5 THEN 1
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) BETWEEN 6 AND 11 THEN 2
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) BETWEEN 12 AND 35 THEN 3
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) > 35 THEN 4
        ELSE NULL
    END AS ExperienceIndex,

    
    CASE 
        WHEN e.[Сотрудники Дата Приема] IS NULL OR e.[Сотрудники Дата Приема] = ''1753-01-01'' THEN N''N/A''
        WHEN e.[Сотрудники Дата Увольнения] IS NULL OR e.[Сотрудники Дата Увольнения] = ''1753-01-01''
            THEN FORMAT(e.[Сотрудники Дата Приема], ''yyyy-MM-dd'') + N'' → Present''
        ELSE FORMAT(e.[Сотрудники Дата Приема], ''yyyy-MM-dd'') + N'' → '' + FORMAT(e.[Сотрудники Дата Увольнения], ''yyyy-MM-dd'')
    END AS EmploymentPeriod,

    lastPos.[СотрудникиДанныеПоЗарплате Вид Должности] AS EmploymentPositionType,
    firstAssigned.FirstDate AS EmpPositionIDdate,
	
	 CASE 
        WHEN firstAssigned.FirstDate IS NULL OR firstAssigned.FirstDate = ''1753-01-01'' THEN NULL
        ELSE DATEDIFF(MONTH, firstAssigned.FirstDate, 
             COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())
        )
    END AS ExperienceMonthsLastPosition,
	
	 CASE 
        WHEN DATEDIFF(MONTH, firstAssigned.FirstDate, COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) BETWEEN 0 AND 5 THEN N''1-5 m''
        WHEN DATEDIFF(MONTH, firstAssigned.FirstDate, COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) BETWEEN 6 AND 11 THEN N''6-11 m''
        WHEN DATEDIFF(MONTH, firstAssigned.FirstDate, COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) BETWEEN 12 AND 35 THEN N''12-35 m''
        WHEN DATEDIFF(MONTH, firstAssigned.FirstDate, COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) > 35 THEN N''36+ m''
        ELSE N''N/A''
    END AS ExperienceMonthsRangeLastPosition,
	
	
	CASE 
        WHEN DATEDIFF(MONTH, firstAssigned.FirstDate, COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) BETWEEN 0 AND 5 THEN 1
        WHEN DATEDIFF(MONTH, firstAssigned.FirstDate, COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) BETWEEN 6 AND 11 THEN 2
        WHEN DATEDIFF(MONTH, firstAssigned.FirstDate, COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) BETWEEN 12 AND 35 THEN 3
        WHEN DATEDIFF(MONTH, firstAssigned.FirstDate, COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) > 35 THEN 4
        ELSE NULL
    END AS ExperienceIndexLastPosition

FROM [ATK].[dbo].[Справочники.Сотрудники] AS e
OUTER APPLY (
    
   
    FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате] AS b
    WHERE b.[СотрудникиДанныеПоЗарплате Сотрудник ID] = e.[Сотрудники ID]
    ORDER BY b.[СотрудникиДанныеПоЗарплате Период] DESC
) AS lastPos
OUTER APPLY (
    
    SELECT MIN(b.[СотрудникиДанныеПоЗарплате Период]) AS FirstDate
    FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате] AS b
    WHERE b.[СотрудникиДанныеПоЗарплате Сотрудник ID] = e.[Сотрудники ID]
      AND b.[СотрудникиДанныеПоЗарплате Вид Должности ID] = lastPos.[СотрудникиДанныеПоЗарплате Вид Должности ID]
) AS firstAssigned;';
    BEGIN TRY
        SET @FailureNote = '';
        EXEC sys.sp_executesql @sql;
        SET @Status = 'Success';
    END TRY
    BEGIN CATCH
        SET @Status = 'Failed';
        SET @FailureNote = CONCAT(
            'Msg: ', ERROR_MESSAGE(),
            ' | Line: ', ERROR_LINE(),
            ' | Number: ', ERROR_NUMBER()
        );
        -- Continue to next file without THROW
    END CATCH;

    SET @EndTime = GETDATE();
    INSERT INTO mis.Gold_Proc_Exec_Log (TableName, StartTime, EndTime, Status, Failure_Note)
    VALUES ('mis.Gold_Dim_Employees', @StartTime, @EndTime, @Status, @FailureNote);

    -- Start of: mis.Gold_Dim_GroupMembershipPeriods.sql
    SET @StartTime = GETDATE();
    SET @EndTime = NULL;
    SET @Status = 'Running';
    SET @sql = N'IF OBJECT_ID(''mis.[Gold_Dim_GroupMembershipPeriods]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_GroupMembershipPeriods];

CREATE TABLE mis.[Gold_Dim_GroupMembershipPeriods]
(
    GroupID        VARCHAR(36) NOT NULL,
    PersonID       VARCHAR(36) NULL,
    PersonName     NVARCHAR(255) NOT NULL,
    PeriodOriginal DATETIME2(0) NOT NULL,
    ActiveFlag     VARCHAR(36) NULL,
    ExcludedFlag   VARCHAR(36) NULL,
    GroupName      NVARCHAR(255) NULL,
    GroupOwner     VARCHAR(36) NULL,
    GroupCode      NVARCHAR(50) NULL,
    GroupNameFull  NVARCHAR(255) NULL,
    GroupOwnerTax  NVARCHAR(50) NULL,
    PeriodStart    DATETIME2(0) NOT NULL,
    PeriodEnd      DATETIME2(0) NOT NULL
);

WITH Events AS (
    SELECT
        sg.[СоставГруппАффилированныхЛиц Группа Аффилированных Лиц ID] AS GroupID,
        sg.[СоставГруппАффилированныхЛиц Контрагент ID] AS PersonID,
        sg.[СоставГруппАффилированныхЛиц Контрагент] AS PersonName,
        sg.[СоставГруппАффилированныхЛиц Период] AS PeriodOriginal,
        sg.[СоставГруппАффилированныхЛиц Активность] AS ActiveFlag,
        sg.[СоставГруппАффилированныхЛиц Исключен] AS ExcludedFlag,
        sg.[СоставГруппАффилированныхЛиц Группа Аффилированных Лиц] AS GroupName,

        g.[ГруппыАффилированныхЛиц Владелец] AS GroupOwner,
        g.[ГруппыАффилированныхЛиц Код] AS GroupCode,
        g.[ГруппыАффилированныхЛиц Наименование] AS GroupNameFull,
        g.[ГруппыАффилированныхЛиц Владелец Фиск Код] AS GroupOwnerTax,

        CASE WHEN sg.[СоставГруппАффилированныхЛиц Исключен] = ''00''
             THEN ''Included'' ELSE ''Excluded'' END AS EventType,
        g.[ГруппыАффилированныхЛиц Пометка Удаления] AS DeletionFlag
    FROM [ATK].[dbo].[РегистрыСведений.СоставГруппАффилированныхЛиц] sg
    LEFT JOIN [ATK].[dbo].[Справочники.ГруппыАффилированныхЛиц] g
        ON g.[ГруппыАффилированныхЛиц ID] =
           sg.[СоставГруппАффилированныхЛиц Группа Аффилированных Лиц ID]
),

Dedup AS (
    SELECT *
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (
                   PARTITION BY
                       GroupID, PersonID, PersonName, PeriodOriginal,
                       ActiveFlag, ExcludedFlag, GroupName,
                       GroupOwner, GroupCode, GroupNameFull, GroupOwnerTax,
                       EventType, DeletionFlag
                   ORDER BY (SELECT NULL)
               ) AS rn
        FROM Events
    ) d
    WHERE rn = 1
),

Ordered AS (
    SELECT
        *,
        LEAD(PeriodOriginal) OVER (
            PARTITION BY GroupID, PersonID
            ORDER BY PeriodOriginal
        ) AS NextDate,
        LEAD(EventType) OVER (
            PARTITION BY GroupID, PersonID
            ORDER BY PeriodOriginal
        ) AS NextType
    FROM Dedup
)

INSERT INTO mis.[Gold_Dim_GroupMembershipPeriods]
(
    GroupID, PersonID, PersonName,
    PeriodOriginal, ActiveFlag, ExcludedFlag, GroupName,
    GroupOwner, GroupCode, GroupNameFull, GroupOwnerTax,
    PeriodStart, PeriodEnd
)
SELECT
    GroupID, PersonID, PersonName,
    PeriodOriginal, ActiveFlag, ExcludedFlag, GroupName,
    GroupOwner, GroupCode, GroupNameFull, GroupOwnerTax,
    PeriodOriginal AS PeriodStart,
    CASE 
        WHEN NextType = ''Excluded''
            THEN DATEADD(SECOND, -1, NextDate)
        ELSE CONVERT(DATETIME2(0), ''2222-01-01 00:00:00'')
    END AS PeriodEnd
FROM Ordered
WHERE EventType = ''Included''
  AND DeletionFlag = ''00''
ORDER BY GroupID, PersonID, PeriodOriginal;';
    BEGIN TRY
        SET @FailureNote = '';
        EXEC sys.sp_executesql @sql;
        SET @Status = 'Success';
    END TRY
    BEGIN CATCH
        SET @Status = 'Failed';
        SET @FailureNote = CONCAT(
            'Msg: ', ERROR_MESSAGE(),
            ' | Line: ', ERROR_LINE(),
            ' | Number: ', ERROR_NUMBER()
        );
        -- Continue to next file without THROW
    END CATCH;

    SET @EndTime = GETDATE();
    INSERT INTO mis.Gold_Proc_Exec_Log (TableName, StartTime, EndTime, Status, Failure_Note)
    VALUES ('mis.Gold_Dim_GroupMembershipPeriods', @StartTime, @EndTime, @Status, @FailureNote);

    -- Start of: mis.Gold_Fact_BudgetEmployees.sql
    SET @StartTime = GETDATE();
    SET @EndTime = NULL;
    SET @Status = 'Running';
    SET @sql = N'IF OBJECT_ID(''mis.[Gold_Fact_BudgetEmployees]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_BudgetEmployees];

CREATE TABLE mis.[Gold_Fact_BudgetEmployees] 
(
    [EmployeeID]          VARCHAR(36) NOT NULL,
    [Employee]            NVARCHAR(40) NULL,
    [AmountIssued]        DECIMAL(18,2) NULL,
    [PortfolioAmount]     DECIMAL(18,2) NULL,
    [QuantityIssued]      INT NULL,
    [DailyVisitPromotions] INT NULL,
    [DailyCallPromotions]  INT NULL,
    [PAR30]               INT NULL,
    [FinProductID]        VARCHAR(36) NULL,
    [FinProductName]      NVARCHAR(100) NULL,
    [DataVersion]         INT NULL,
    [DeletedFlag]         VARCHAR(36) NULL,
    [Date]                DATETIME NULL,
    [Number]              NVARCHAR(50) NULL,
    [Posted]              VARCHAR(36) NULL,
    [BranchID]            VARCHAR(36) NULL,
    [BranchName]          NVARCHAR(100) NULL,
    [Comment]             NVARCHAR(256) NULL,
    [Organization]        NVARCHAR(100) NULL,
    [TotalAmountIssued]   DECIMAL(18,2) NULL,
    [TotalPortfolioAmount] DECIMAL(18,2) NULL,
    [TotalPAR0]           INT NULL,
    [NonBusinessPAR30]    INT NULL
);

INSERT INTO mis.[Gold_Fact_BudgetEmployees]
SELECT
    s.[БюджетПоСотрудникам.Сотрудники Сотрудник ID] AS EmployeeID,
    s.[БюджетПоСотрудникам.Сотрудники Сотрудник] AS Employee,
    s.[БюджетПоСотрудникам.Сотрудники Сумма Выдано] AS AmountIssued,
    s.[БюджетПоСотрудникам.Сотрудники Сумма Портфель] AS PortfolioAmount,
    s.[БюджетПоСотрудникам.Сотрудники Количество Выдано] AS QuantityIssued,
    s.[БюджетПоСотрудникам.Сотрудники Количество Продвижений Визиты в День] AS DailyVisitPromotions,
    s.[БюджетПоСотрудникам.Сотрудники Количество Продвижений Звонки в День] AS DailyCallPromotions,
    s.[БюджетПоСотрудникам.Сотрудники PAR30] AS PAR30,
    s.[БюджетПоСотрудникам.Сотрудники Финансовый Продукт ID] AS FinProductID,
    s.[БюджетПоСотрудникам.Сотрудники Финансовый Продукт] AS FinProductName,
    d.[БюджетПоСотрудникам Версия Данных] AS DataVersion,
    d.[БюджетПоСотрудникам Пометка Удаления] AS DeletedFlag,
    d.[БюджетПоСотрудникам Дата] AS Date,
    d.[БюджетПоСотрудникам Номер] AS Number,
    d.[БюджетПоСотрудникам Проведен] AS Posted,
    d.[БюджетПоСотрудникам Филиал ID] AS BranchID,
    d.[БюджетПоСотрудникам Филиал] AS BranchName,
    d.[БюджетПоСотрудникам Комментарий] AS Comment,
    d.[БюджетПоСотрудникам Организация] AS Organization,
    d.[БюджетПоСотрудникам Сумма Выдано Итого] AS TotalAmountIssued,
    d.[БюджетПоСотрудникам Сумма Портфель Итого] AS TotalPortfolioAmount,
    d.[БюджетПоСотрудникам PAR0] AS TotalPAR0,
    d.[БюджетПоСотрудникам PAR30 Нон Бизнес] AS NonBusinessPAR30
FROM [ATK].[dbo].[Документы.БюджетПоСотрудникам.Сотрудники] s
LEFT RIGHT [ATK].[dbo].[Документы.БюджетПоСотрудникам] d
    ON s.[БюджетПоСотрудникам ID] = d.[БюджетПоСотрудникам ID]
WHERE d.[БюджетПоСотрудникам Дата] >= ''2023-09-01'';';
    BEGIN TRY
        SET @FailureNote = '';
        EXEC sys.sp_executesql @sql;
        SET @Status = 'Success';
    END TRY
    BEGIN CATCH
        SET @Status = 'Failed';
        SET @FailureNote = CONCAT(
            'Msg: ', ERROR_MESSAGE(),
            ' | Line: ', ERROR_LINE(),
            ' | Number: ', ERROR_NUMBER()
        );
        -- Continue to next file without THROW
    END CATCH;

    SET @EndTime = GETDATE();
    INSERT INTO mis.Gold_Proc_Exec_Log (TableName, StartTime, EndTime, Status, Failure_Note)
    VALUES ('mis.Gold_Fact_BudgetEmployees', @StartTime, @EndTime, @Status, @FailureNote);

    -- Start of: mis.Gold_Fact_Comments.sql
    SET @StartTime = GETDATE();
    SET @EndTime = NULL;
    SET @Status = 'Running';
    SET @sql = N'IF OBJECT_ID(''mis.[Gold_Fact_Comments]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_Comments];

CREATE TABLE mis.[Gold_Fact_Comments]
(
    CommentID VARCHAR(36) NOT NULL PRIMARY KEY,
    AllComments NVARCHAR(MAX) NULL
);

SELECT 
    [КомментарийКУсловиямПослеВыдачи ИД] AS CommentID,
    CONVERT(VARCHAR(10), [КомментарийКУсловиямПослеВыдачи Период], 120) AS Period,
    [КомментарийКУсловиямПослеВыдачи Исполнитель] AS Executor,
    [КомментарийКУсловиямПослеВыдачи Комментарий] AS Comment
INTO #FilteredComments
FROM [ATK].[dbo].[РегистрыСведений.КомментарийКУсловиямПослеВыдачи]
WHERE [КомментарийКУсловиямПослеВыдачи Объект Tип] = ''08''
  AND [КомментарийКУсловиямПослеВыдачи Клиент] IS NOT NULL;

INSERT INTO mis.[Gold_Fact_Comments] (CommentID, AllComments)
SELECT 
    fc1.CommentID,
    STUFF(
        (
            SELECT CHAR(13) + CHAR(10) +
                   CONCAT(fc2.Period, '' '', fc2.Executor, '': '', fc2.Comment)
            FROM #FilteredComments fc2
            WHERE fc2.CommentID = fc1.CommentID
            ORDER BY fc2.Period
            FOR XML PATH(''''), TYPE
        ).value(''.'', ''NVARCHAR(MAX)''), 1, 2, ''''
    ) AS AllComments
FROM (SELECT DISTINCT CommentID FROM #FilteredComments) fc1;

DROP TABLE #FilteredComments;';
    BEGIN TRY
        SET @FailureNote = '';
        EXEC sys.sp_executesql @sql;
        SET @Status = 'Success';
    END TRY
    BEGIN CATCH
        SET @Status = 'Failed';
        SET @FailureNote = CONCAT(
            'Msg: ', ERROR_MESSAGE(),
            ' | Line: ', ERROR_LINE(),
            ' | Number: ', ERROR_NUMBER()
        );
        -- Continue to next file without THROW
    END CATCH;

    SET @EndTime = GETDATE();
    INSERT INTO mis.Gold_Proc_Exec_Log (TableName, StartTime, EndTime, Status, Failure_Note)
    VALUES ('mis.Gold_Fact_Comments', @StartTime, @EndTime, @Status, @FailureNote);

    -- Start of: mis.Gold_Fact_CPD.sql
    SET @StartTime = GETDATE();
    SET @EndTime = NULL;
    SET @Status = 'Running';
    SET @sql = N'IF OBJECT_ID(''mis.[Gold_Fact_CPD]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_CPD];

CREATE TABLE mis.[Gold_Fact_CPD]
( 
    [Period]              DATETIME NULL,
    [ObjectType]          VARCHAR(36) NULL,
    [ObjectKind]          VARCHAR(36) NULL,
    [ObjectID]            VARCHAR(36) NULL,
    [ID]                  VARCHAR(36) NULL,
    [ConditionType]       NVARCHAR(256) NULL,
    [ConditionObjectType] VARCHAR(36) NULL,
    [ConditionObject_S]   NVARCHAR(600) NULL,
    [ConditionObject]     VARCHAR(36) NULL,
    [AdditionalInterest]  DECIMAL(4, 2) NULL,
    [DueDate]             DATETIME NULL,
    [ResponsibleID]       VARCHAR(36) NULL,
    [Responsible]         NVARCHAR(50) NULL,
    [IssueDate]           DATETIME NULL,
    [Completed]           VARCHAR(36) NULL,
    [CompletionDate]      DATETIME NULL,
    [Comment]             NVARCHAR(1000) NULL,
    [Verified]            VARCHAR(36) NULL,
    [IsAdditionalCondition]  VARCHAR(36) NULL,
    [Cancelled]           VARCHAR(36) NULL,
    [CreditRisk]          NVARCHAR(256) NULL,
    [LegalRisk]           NVARCHAR(256) NULL,
    [CommitteeApproved]   VARCHAR(36) NULL,
    [CollateralID]        VARCHAR(36) NULL,
    [Collateral]          NVARCHAR(150) NULL,
    [CancelledByID]       VARCHAR(36) NULL,
    [CancelledBy]         NVARCHAR(150) NULL,
    [VerifiedByID]        VARCHAR(36) NULL,
    [VerifiedBy]          NVARCHAR(150) NULL,
    [ModifiedDate]        DATETIME NULL,
    [SourceType]          VARCHAR(36) NULL,
    [SourceKind]          VARCHAR(36) NULL,
    [SourceID]            VARCHAR(36) NULL,
    [OwnerID]             VARCHAR(36) NULL,
    [Owner]               NVARCHAR(150) NULL
);

INSERT INTO mis.[Gold_Fact_CPD]
(
    [Period],
    [ObjectType],
    [ObjectKind],
    [ObjectID],
    [ID],
    [ConditionType],
    [ConditionObjectType],
    [ConditionObject_S],
    [ConditionObject],
    [AdditionalInterest],
    [DueDate],
    [ResponsibleID],
    [Responsible],
    [IssueDate],
    [Completed],
    [CompletionDate],
    [Comment],
    [Verified],
    [IsAdditionalCondition],
    [Cancelled],
    [CreditRisk],
    [LegalRisk],
    [CommitteeApproved],
    [CollateralID],
    [Collateral],
    [CancelledByID],
    [CancelledBy],
    [VerifiedByID],
    [VerifiedBy],
    [ModifiedDate],
    [SourceType],
    [SourceKind],
    [SourceID],
    [OwnerID],
    [Owner]
)
SELECT
    [УсловияПослеВыдачиКредита Период],
    [УсловияПослеВыдачиКредита Объект Tип],
    [УсловияПослеВыдачиКредита Объект Вид],
    [УсловияПослеВыдачиКредита Объект ID],
    [УсловияПослеВыдачиКредита ИД],
    [УсловияПослеВыдачиКредита Тип Условия],
    [УсловияПослеВыдачиКредита Объект Условия Tип],
    [УсловияПослеВыдачиКредита Объект Условия _S],
    [УсловияПослеВыдачиКредита Объект Условия],
    [УсловияПослеВыдачиКредита Доп Проценты],
    [УсловияПослеВыдачиКредита Срок Выполнения],
    [УсловияПослеВыдачиКредита Исполнитель ID],
    [УсловияПослеВыдачиКредита Исполнитель],
    [УсловияПослеВыдачиКредита Дата Выдачи],
    [УсловияПослеВыдачиКредита Выполнено],
    [УсловияПослеВыдачиКредита Дата Выполнения],
    [УсловияПослеВыдачиКредита Комментарий],
    [УсловияПослеВыдачиКредита Проверено],
    [УсловияПослеВыдачиКредита Это Доп Условия],
    [УсловияПослеВыдачиКредита Аннулирован],
    [УсловияПослеВыдачиКредита Кредитный Риск],
    [УсловияПослеВыдачиКредита Юридический Риск],
    [УсловияПослеВыдачиКредита Одобренно Комитетом],
    [УсловияПослеВыдачиКредита Залог ID],
    [УсловияПослеВыдачиКредита Залог],
    [УсловияПослеВыдачиКредита Автор Аннулирования ID],
    [УсловияПослеВыдачиКредита Автор Аннулирования],
    [УсловияПослеВыдачиКредита Автор Проверки ID],
    [УсловияПослеВыдачиКредита Автор Проверки],
    [УсловияПослеВыдачиКредита Дата Изменения],
    [УсловияПослеВыдачиКредита Источник Tип],
    [УсловияПослеВыдачиКредита Источник Вид],
    [УсловияПослеВыдачиКредита Источник ID],
    [УсловияПослеВыдачиКредита Ответственный ID],
    [УсловияПослеВыдачиКредита Ответственный]
	
FROM [ATK].[dbo].[РегистрыСведений.УсловияПослеВыдачиКредита];';
    BEGIN TRY
        SET @FailureNote = '';
        EXEC sys.sp_executesql @sql;
        SET @Status = 'Success';
    END TRY
    BEGIN CATCH
        SET @Status = 'Failed';
        SET @FailureNote = CONCAT(
            'Msg: ', ERROR_MESSAGE(),
            ' | Line: ', ERROR_LINE(),
            ' | Number: ', ERROR_NUMBER()
        );
        -- Continue to next file without THROW
    END CATCH;

    SET @EndTime = GETDATE();
    INSERT INTO mis.Gold_Proc_Exec_Log (TableName, StartTime, EndTime, Status, Failure_Note)
    VALUES ('mis.Gold_Fact_CPD', @StartTime, @EndTime, @Status, @FailureNote);

    -- Start of: mis.Gold_Fact_CreditsInShadowBranches.sql
    SET @StartTime = GETDATE();
    SET @EndTime = NULL;
    SET @Status = 'Running';
    SET @sql = N'IF OBJECT_ID(''mis.[Gold_Fact_CreditsInShadowBranches]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_CreditsInShadowBranches];

CREATE TABLE mis.[Gold_Fact_CreditsInShadowBranches] 
(
    Period DATETIME NULL,
    ID VARCHAR(32) NOT NULL,
    RowNumber INT NULL,
    Active VARCHAR(36) NULL,
    CreditID VARCHAR(32) NULL,
    Credit NVARCHAR(100) NULL,
    BranchID VARCHAR(32) NULL,
    Branch NVARCHAR(100) NULL,
    CreditEmployeeID VARCHAR(32) NULL,
    CreditEmployee NVARCHAR(100) NULL,
    DateTo DATETIME NULL
);

;WITH src AS (
    SELECT
          rs.[КредитыВТеневыхФилиалах Период]                 AS Period,
          rs.[КредитыВТеневыхФилиалах ID]                     AS ID,
          rs.[КредитыВТеневыхФилиалах Номер Строки]           AS RowNumber,
          rs.[КредитыВТеневыхФилиалах Активность]             AS Active,
          rs.[КредитыВТеневыхФилиалах Кредит ID]              AS CreditID,
          rs.[КредитыВТеневыхФилиалах Кредит]                 AS Credit,
          rs.[КредитыВТеневыхФилиалах Филиал ID]              AS BranchID,
          rs.[КредитыВТеневыхФилиалах Филиал]                 AS Branch,
          rs.[КредитыВТеневыхФилиалах Кредитный Эксперт ID]   AS CreditEmployeeID,
          rs.[КредитыВТеневыхФилиалах Кредитный Эксперт]      AS CreditEmployee
    FROM [ATK].[mis].[Bronze_РегистрыСведений.КредитыВТеневыхФилиалах] rs
	WHERE rs.[КредитыВТеневыхФилиалах Период] >= ''2023-01-01''
),
calc AS (
    SELECT
          Period,
          ID,
          RowNumber,
          Active,
          CreditID,
          Credit,
          BranchID,
          Branch,
          CreditEmployeeID,
          CreditEmployee,
          LEAD(Period) OVER (
              PARTITION BY CreditID
              ORDER BY Period, RowNumber
          ) AS DateTo
    FROM src
)
INSERT INTO mis.[Gold_Fact_CreditsInShadowBranches] 
(
      Period,
      ID,
      RowNumber,
      Active,
      CreditID,
      Credit,
      BranchID,
      Branch,
      CreditEmployeeID,
      CreditEmployee,
      DateTo
)
SELECT
      Period,
      ID,
      RowNumber,
      Active,
      CreditID,
      Credit,
      BranchID,
      Branch,
      CreditEmployeeID,
      CreditEmployee,
      DateTo
FROM calc;';
    BEGIN TRY
        SET @FailureNote = '';
        EXEC sys.sp_executesql @sql;
        SET @Status = 'Success';
    END TRY
    BEGIN CATCH
        SET @Status = 'Failed';
        SET @FailureNote = CONCAT(
            'Msg: ', ERROR_MESSAGE(),
            ' | Line: ', ERROR_LINE(),
            ' | Number: ', ERROR_NUMBER()
        );
        -- Continue to next file without THROW
    END CATCH;

    SET @EndTime = GETDATE();
    INSERT INTO mis.Gold_Proc_Exec_Log (TableName, StartTime, EndTime, Status, Failure_Note)
    VALUES ('mis.Gold_Fact_CreditsInShadowBranches', @StartTime, @EndTime, @Status, @FailureNote);

    -- Start of: mis.Gold_Fact_WriteOffCredits.sql
    SET @StartTime = GETDATE();
    SET @EndTime = NULL;
    SET @Status = 'Running';
    SET @sql = N'IF OBJECT_ID(''mis.[Gold_Fact_WriteOffCredits]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_WriteOffCredits];

CREATE TABLE mis.[Gold_Fact_WriteOffCredits]
(
    [Credit_CanceledCreditID] VARCHAR(36) NOT NULL,
    [Credit_RowNumber]        INT NULL,
    [Credit_AccountID]        VARCHAR(36) NULL,
    [Credit_Account]          NVARCHAR(250) NULL,
    [Credit_ClientID]         VARCHAR(36) NULL,
    [Credit_Client]           NVARCHAR(150) NULL,
    [Credit_CreditID]         VARCHAR(36) NULL,
    [Credit_Credit]           NVARCHAR(150) NULL,
    [Credit_CurrencyID]       VARCHAR(36) NULL,
    [Credit_Currency]         NVARCHAR(50) NULL,
    [Credit_Amount]           DECIMAL(14, 2) NULL,
    [Credit_AmountCurrency]   DECIMAL(14, 2) NULL,
    [Credit_Interest]         DECIMAL(14, 2) NULL,
    [Credit_InterestCurrency] DECIMAL(14, 2) NULL,
    [Credit_Penalty]          DECIMAL(14, 2) NULL,
    [Credit_PenaltyCurrency]  DECIMAL(14, 2) NULL,
    [Credit_Commission]       DECIMAL(15, 2) NULL,
    [Credit_CommissionCurrency] DECIMAL(15, 2) NULL,
    [Credit_LineAmount]       DECIMAL(15, 2) NULL,
    [Credit_LineAmountCurrency] DECIMAL(15, 2) NULL,
    [Canceled_CreditDate]    DATETIME NULL,
    [Canceled_CreditPosted]  VARCHAR(36) NULL,
    [Canceled_CreditBase]    NVARCHAR(250) NULL,
	[Canceled_CreditAuthorID] VARCHAR(36) NULL,
	[Canceled_DebitAccount]  NVARCHAR(250) NULL,
    [FinalBranchID]   VARCHAR(36) NULL,
    [FinalExpertID]   VARCHAR(36) NULL
);

INSERT INTO mis.[Gold_Fact_WriteOffCredits]
(
    [Credit_CanceledCreditID],
    [Credit_RowNumber],
    [Credit_AccountID],
    [Credit_Account],
    [Credit_ClientID],
    [Credit_Client],
    [Credit_CreditID],
    [Credit_Credit],
    [Credit_CurrencyID],
    [Credit_Currency],
    [Credit_Amount],
    [Credit_AmountCurrency],
    [Credit_Interest],
    [Credit_InterestCurrency],
    [Credit_Penalty],
    [Credit_PenaltyCurrency],
    [Credit_Commission],
    [Credit_CommissionCurrency],
    [Credit_LineAmount],
    [Credit_LineAmountCurrency],
    [Canceled_CreditDate],
    [Canceled_CreditPosted],
    [Canceled_CreditBase],
	[Canceled_CreditAuthorID],
	[Canceled_DebitAccount],
	[FinalBranchID],
    [FinalExpertID]
)
SELECT
    a.[АнулированиеКредитов ID],
    a.[АнулированиеКредитов.Кредиты Номер Строки],
    a.[АнулированиеКредитов.Кредиты Счет ID],
    a.[АнулированиеКредитов.Кредиты Счет],
    a.[АнулированиеКредитов.Кредиты Контрагент ID],
    a.[АнулированиеКредитов.Кредиты Контрагент],
    a.[АнулированиеКредитов.Кредиты Кредит ID],
    a.[АнулированиеКредитов.Кредиты Кредит],
    a.[АнулированиеКредитов.Кредиты Валюта ID],
    a.[АнулированиеКредитов.Кредиты Валюта],
    a.[АнулированиеКредитов.Кредиты Сумма],
    a.[АнулированиеКредитов.Кредиты Сумма Валютная],
    a.[АнулированиеКредитов.Кредиты Процент],
    a.[АнулированиеКредитов.Кредиты Процент Валютный],
    a.[АнулированиеКредитов.Кредиты Пеня],
    a.[АнулированиеКредитов.Кредиты Пеня Валютный],
    a.[АнулированиеКредитов.Кредиты Комиссион],
    a.[АнулированиеКредитов.Кредиты Комиссион Валютный],
    a.[АнулированиеКредитов.Кредиты Сумма Кредитная Линия],
    a.[АнулированиеКредитов.Кредиты Сумма Кредитная Линия Валютная],
    b.[АнулированиеКредитов Дата],
    b.[АнулированиеКредитов Проведен],
    b.[АнулированиеКредитов Основание],
	b.[АнулированиеКредитов Автор ID],
	b.[АнулированиеКредитов Счет Дт],
	lastResp.FinalBranchID,
	lastResp.FinalExpertID
FROM [ATK].[dbo].[Документы.АнулированиеКредитов.Кредиты] AS a
LEFT JOIN [ATK].[dbo].[Документы.АнулированиеКредитов] AS b
    ON a.[АнулированиеКредитов ID] = b.[АнулированиеКредитов ID]
OUTER APPLY (
    SELECT TOP (1)
           c.[FinalBranchID] AS FinalBranchID,
           c.[FinalExpertID] AS FinalExpertID
    FROM [ATK].[mis].[Silver_Resp_SCD] c
    WHERE c.[CreditID] = a.[АнулированиеКредитов.Кредиты Кредит ID]
    ORDER BY 
        ISNULL(CAST(c.[ValidTo] AS date), CONVERT(date,''9999-12-31'')) DESC,
        CAST(c.[ValidFrom] AS date) DESC,
        c.[FinalBranchID] DESC,
        c.[FinalExpertID] DESC
) AS lastResp;

CREATE INDEX IX_WriteOff_CreditID 
    ON [ATK].[mis].[Gold_Fact_WriteOffCredits] ([Credit_CreditID]);

CREATE INDEX IX_WriteOff_Final 
    ON [ATK].[mis].[Gold_Fact_WriteOffCredits] ([FinalBranchID], [FinalExpertID]);';
    BEGIN TRY
        SET @FailureNote = '';
        EXEC sys.sp_executesql @sql;
        SET @Status = 'Success';
    END TRY
    BEGIN CATCH
        SET @Status = 'Failed';
        SET @FailureNote = CONCAT(
            'Msg: ', ERROR_MESSAGE(),
            ' | Line: ', ERROR_LINE(),
            ' | Number: ', ERROR_NUMBER()
        );
        -- Continue to next file without THROW
    END CATCH;

    SET @EndTime = GETDATE();
    INSERT INTO mis.Gold_Proc_Exec_Log (TableName, StartTime, EndTime, Status, Failure_Note)
    VALUES ('mis.Gold_Fact_WriteOffCredits', @StartTime, @EndTime, @Status, @FailureNote);

END
GO
