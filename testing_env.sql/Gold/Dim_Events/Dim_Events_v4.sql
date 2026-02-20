USE [ATK];
GO

IF OBJECT_ID('mis.[Gold_Dim_Events]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_Events];
GO

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
GO

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
);

