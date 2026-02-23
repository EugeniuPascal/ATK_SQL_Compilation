-- =============================================
-- Compiled Stored Procedure for MSSQL Agent Job (Silver) - Idempotent with Logging
-- Generated: 2026-02-23 15:02:20.833882
-- Source folder: C:\ATK_Project\sql_scripts\Silver
-- Files included: 2
--   mis.Silver_Employee_User.sql
--   mis.Silver_CommiteeProtocol.sql
-- Requires: SQL Server 2016 SP1+ for CREATE OR ALTER
-- =============================================

USE [ATK];
GO

IF OBJECT_ID('mis.usp_SilverTables', 'P') IS NOT NULL
    DROP PROCEDURE mis.usp_SilverTables;
GO

CREATE PROCEDURE mis.usp_SilverTables
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @StartTime DATETIME;
    DECLARE @EndTime DATETIME;
    DECLARE @Status NVARCHAR(50);

    -- Start of: mis.Silver_Employee_User.sql
    SET @StartTime = GETDATE();
    SET @EndTime = NULL;
    SET @Status = 'Running';
    SET @sql = N'IF OBJECT_ID(''mis.[Silver_Employee_User]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Silver_Employee_User];

CREATE TABLE mis.[Silver_Employee_User]
(
    [SalaryPeriod]        DATETIME      NULL,
    [EmployeeID]          VARCHAR(36)   NULL,
    [PositionName]        NVARCHAR(100) NULL,
    [PositionID]          VARCHAR(36)   NULL,
    [BranchName]          NVARCHAR(100) NULL,

    [UserID]              VARCHAR(36)   NULL,
    [IsDeleted]           VARCHAR(36)   NULL,
    [UserName]            NVARCHAR(100) NULL,
    [Primary_EmployeeGroup] NVARCHAR(256) NULL,
    [Employee_UserID]     VARCHAR(36)   NULL,
    [EmployeeName]        NVARCHAR(40)  NULL,
    [CashDeskID]          VARCHAR(36)   NULL,
    [CashDeskName]        NVARCHAR(50)  NULL,
    [IsConnected]         INT           NULL,
    [IsDisabled]          INT           NULL,
    [MI_RepresentativeID] VARCHAR(36)   NULL,
    [MI_RepresentativeName] NVARCHAR(55) NULL,
    [IsInvalid]           VARCHAR(36)   NULL,
    [DepartmentName]      NVARCHAR(10)  NULL,
    [PersonName]          NVARCHAR(10)  NULL,
    [IsSys_User]          VARCHAR(36)   NULL,
    [IsPrepared]          VARCHAR(36)   NULL,
    [IB_ID]               VARCHAR(36)   NULL,
    [ServiceID]           VARCHAR(36)   NULL,
    [IB_Properties]       VARCHAR(36)   NULL,
    [DebtRemind]          VARCHAR(36)   NULL,
    [ClientID]            VARCHAR(36)   NULL
);

INSERT INTO mis.[Silver_Employee_User]
SELECT 

    a.[СотрудникиДанныеПоЗарплате Период]        AS SalaryPeriod,
    a.[СотрудникиДанныеПоЗарплате Сотрудник ID] AS EmployeeID,
    a.[СотрудникиДанныеПоЗарплате Должность]    AS PositionName,
    a.[СотрудникиДанныеПоЗарплате Должность ID] AS PositionID,
    a.[СотрудникиДанныеПоЗарплате Филиал]       AS BranchName,

    
    u.[Пользователи ID]                           AS UserID,
    u.[Пользователи Пометка Удаления]            AS IsDeleted,
    u.[Пользователи Наименование]                AS UserName,
    u.[Пользователи Основная Группа Сотрудников] AS Primary_EmployeeGroup,
    u.[Пользователи Сотрудник ID]                AS Employee_UserID,
    u.[Пользователи Сотрудник]                   AS EmployeeName,
    u.[Пользователи Касса ID]                    AS CashDeskID,
    u.[Пользователи Касса]                       AS CashDeskName,
    u.[Пользователи Подключен]                   AS IsConnected,
    u.[Пользователи Отключить]                   AS IsDisabled,
    u.[Пользователи Представитель MI ID]         AS MI_RepresentativeID,
    u.[Пользователи Представитель MI]            AS MI_RepresentativeName,
    u.[Пользователи Недействителен]              AS IsInvalid,
    u.[Пользователи Подразделение]               AS DepartmentName,
    u.[Пользователи Физическое Лицо]             AS PersonName,
    u.[Пользователи Служебный]                   AS IsSys_User,
    u.[Пользователи Подготовлен]                 AS IsPrepared,
    u.[Пользователи Идентификатор Пользователя ИБ]    AS IB_ID,
    u.[Пользователи Идентификатор Пользователя Сервиса] AS ServiceID,
    u.[Пользователи Свойства Пользователя ИБ]         AS IB_Properties,
    u.[Пользователи Напоминать о Задолженности Поставщики] AS DebtRemind,
    u.[Пользователи Контрагент ID]                    AS ClientID
FROM [ATK].[mis].[Bronze_РегистрыСведений.СотрудникиДанныеПоЗарплате] a
LEFT JOIN [ATK].[dbo].[Справочники.Пользователи] u
    ON u.[Пользователи Сотрудник ID] = a.[СотрудникиДанныеПоЗарплате Сотрудник ID]
WHERE u.[Пользователи Пометка Удаления] <> ''01'';';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
        SET @Status = 'Success';
    END TRY
    BEGIN CATCH
        SET @Status = 'Failed';
        THROW;
    END CATCH;

    SET @EndTime = GETDATE();
    INSERT INTO mis.Silver_Proc_Exec_Log (TableName, StartTime, EndTime, Status)
    VALUES ('mis.Silver_Employee_User', @StartTime, @EndTime, @Status);

    -- Start of: mis.Silver_CommiteeProtocol.sql
    SET @StartTime = GETDATE();
    SET @EndTime = NULL;
    SET @Status = 'Running';
    SET @sql = N'IF OBJECT_ID(''mis.[Silver_CommiteeProtocol]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Silver_CommiteeProtocol];

CREATE TABLE mis.[Silver_CommiteeProtocol]
(
    [ПротоколКомитета Дата]                DATETIME NULL,
	[ПротоколКомитета Дата Решения]        DATETIME NULL,
	[ПротоколКомитета Кредит ID]           VARCHAR(36) NOT NULL,
    [ПротоколКомитета ID]	               VARCHAR(36) NOT NULL,
	[ПротоколКомитета Заявка ID]           VARCHAR(36) NOT NULL,
    [ПротоколКомитета Сумма на Выдачу]	   DECIMAL(15, 2) NULL,
	[ПротоколКомитета Сумма Рефинансирования Кредита] DECIMAL(15, 2) NULL,
	[ПротоколКомитета Назначение Использования Кредита] NVARCHAR(150) NULL,
	[ПротоколКомитета Категория Риска AML]  NVARCHAR(256) NULL,
	[ПротоколКомитета Это Зеленый Кредит] VARCHAR(36) NOT NULL,
	[ПротоколКомитета Комитет]            NVARCHAR(156) NULL,
	[ПротоколКомитета Партнер]  NVARCHAR(256) NULL
	
);

INSERT INTO mis.[Silver_CommiteeProtocol] 
(
    [ПротоколКомитета Дата],
	[ПротоколКомитета Дата Решения],
	[ПротоколКомитета Кредит ID], 
	[ПротоколКомитета ID],
	[ПротоколКомитета Заявка ID],
    [ПротоколКомитета Сумма на Выдачу],
	[ПротоколКомитета Сумма Рефинансирования Кредита],
	[ПротоколКомитета Назначение Использования Кредита],
	[ПротоколКомитета Категория Риска AML],
	[ПротоколКомитета Это Зеленый Кредит],
	[ПротоколКомитета Комитет],
	[ПротоколКомитета Партнер]
)
SELECT
    [ПротоколКомитета Дата],
	[ПротоколКомитета Дата Решения],
	[ПротоколКомитета Кредит ID], 
	[ПротоколКомитета ID],
	[ПротоколКомитета Заявка ID],
    [ПротоколКомитета Сумма на Выдачу],
	[ПротоколКомитета Сумма Рефинансирования Кредита],
	[ПротоколКомитета Назначение Использования Кредита],
	[ПротоколКомитета Категория Риска AML],
	[ПротоколКомитета Это Зеленый Кредит],
	[ПротоколКомитета Комитет],
	[ПротоколКомитета Партнер]
	
FROM [ATK].[mis].[Bronze_Документы.ПротоколКомитета];';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
        SET @Status = 'Success';
    END TRY
    BEGIN CATCH
        SET @Status = 'Failed';
        THROW;
    END CATCH;

    SET @EndTime = GETDATE();
    INSERT INTO mis.Silver_Proc_Exec_Log (TableName, StartTime, EndTime, Status)
    VALUES ('mis.Silver_CommiteeProtocol', @StartTime, @EndTime, @Status);

END
GO
