-- =============================================
-- Compiled Stored Procedure for MSSQL Agent Job (Gold) - Idempotent
-- Generated: 2026-02-20 10:17:07.402616
-- Source folder: C:\ATK_Project\sql_scripts\Gold
-- Files included: 2
--   mis.Gold_Dim_AppUsers.sql
--   mis.Gold_Dim_Events.sql
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

    -- Start of: mis.Gold_Dim_AppUsers.sql
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
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.Gold_Dim_Events.sql
    SET @sql = N'IF OBJECT_ID(''mis.[Gold_Dim_Events]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_Events];

CREATE TABLE mis.[Gold_Dim_Events]
(
    Event_Period        DATETIME        NOT NULL,
    Event_ID            VARCHAR(36)     NOT NULL,
    Event_ClientID      VARCHAR(36)     NOT NULL,
    Event_Status        NVARCHAR(256)   NULL,
    Event_Kind          NVARCHAR(256)   NULL,
    Event_Type          NVARCHAR(256)   NULL,
    Event_Project       NVARCHAR(150)   NULL,
    Event_Content       NVARCHAR(1000)  NULL,
    Event_ResponsibleID VARCHAR(36)     NOT NULL,
    Event_Responsible   NVARCHAR(1000)  NULL,
    Event_NextDateEvent DATETIME        NOT NULL,
    Event_NextKindEvent NVARCHAR(256)   NULL,
    Event_BranchID      VARCHAR(36)     NOT NULL,
    Event_Branch_Name   NVARCHAR(256)   NULL,
    EmployeePosition    NVARCHAR(100)   NULL,
	EmployeeBranch      NVARCHAR(100)   NULL
);

;WITH EventData AS
(
    SELECT
        e.[СведенияОСобытиях Период]                   AS Event_Period,
        e.[СведенияОСобытиях ID]                       AS Event_ID,
        e.[СведенияОСобытиях Контрагент ID]            AS Event_ClientID,
        e.[СведенияОСобытиях Состояние События]        AS Event_Status,
        e.[СведенияОСобытиях Вид События]              AS Event_Kind,
        e.[СведенияОСобытиях Тип События]              AS Event_Type,
        e.[СведенияОСобытиях Проект]                   AS Event_Project,
        e.[СведенияОСобытиях Содержание События]       AS Event_Content,
        e.[СведенияОСобытиях Ответственный ID]         AS Event_ResponsibleID,
        e.[СведенияОСобытиях Ответственный]            AS Event_Responsible,
        e.[СведенияОСобытиях Дата Следующего События]  AS Event_NextDateEvent,
        e.[СведенияОСобытиях Вид Следующего События]   AS Event_NextKindEvent,
        e.[СведенияОСобытиях Филиал ID]                AS Event_BranchID,
        e.[СведенияОСобытиях Филиал]                   AS Event_Branch_Name,
        s.[СотрудникиДанныеПоЗарплате Должность]       AS EmployeePosition,
        s.[СотрудникиДанныеПоЗарплате Филиал]          AS EmployeeBranch
    FROM [ATK].[dbo].[РегистрыСведений.СведенияОСобытиях] e
    OUTER APPLY
    (
        SELECT TOP 1
               p.[СотрудникиДанныеПоЗарплате Должность],
               p.[СотрудникиДанныеПоЗарплате Филиал]
        FROM mis.[Bronze_РегистрыСведений.СотрудникиДанныеПоЗарплате] p
        WHERE p.[СотрудникиДанныеПоЗарплате Сотрудник ID] = e.[СведенияОСобытиях Ответственный ID]
          AND p.[СотрудникиДанныеПоЗарплате Период] <= e.[СведенияОСобытиях Период]
        ORDER BY p.[СотрудникиДанныеПоЗарплате Период] DESC
    ) s
)
INSERT INTO mis.[Gold_Dim_Events]
(
    Event_Period,
    Event_ID,
    Event_ClientID,
    Event_Status,
    Event_Kind,
    Event_Type,
    Event_Project,
    Event_Content,
    Event_ResponsibleID,
    Event_Responsible,
    Event_NextDateEvent,
    Event_NextKindEvent,
    Event_BranchID,
    Event_Branch_Name,
    EmployeePosition,
    EmployeeBranch
)
SELECT *
FROM EventData ed
WHERE NOT EXISTS (
    SELECT 1
    FROM mis.[Gold_Dim_Events] g
    WHERE g.Event_ID = ed.Event_ID
);';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

END
GO
