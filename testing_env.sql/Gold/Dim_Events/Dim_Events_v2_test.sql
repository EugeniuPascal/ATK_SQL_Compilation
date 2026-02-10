USE [ATK];
GO

IF OBJECT_ID('mis.[Gold_Dim_Events]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_Events];
GO

CREATE TABLE mis.[Gold_Dim_Events]
(
    Event_Period DATETIME NULL,
    Event_ID VARCHAR(36) NULL,
    Event_ClientID VARCHAR(36) NULL,
    Event_Status NVARCHAR(256) NULL,
    Event_Kind NVARCHAR(256) NULL,
    Event_Type NVARCHAR(256) NULL,
    Event_Project NVARCHAR(150) NULL,
    Event_Content NVARCHAR(1000) NULL,
    Event_ResponsibleID VARCHAR(36) NULL,
    Event_Responsible NVARCHAR(1000) NULL,
    Event_NextDateEvent DATETIME NULL,
    Event_NextKindEvent NVARCHAR(256) NULL,
    Event_BranchID VARCHAR(36) NULL,
    BranchID VARCHAR(36) NULL,
    FiscalCode VARCHAR(50) NULL,
    EmployeeName NVARCHAR(256) NULL,
    EmployeePosition NVARCHAR(256) NULL,
    FilialaEveniment NVARCHAR(100) NULL,
    FilialaResponsabil NVARCHAR(100) NULL
);
GO

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
    BranchID,
    FiscalCode,
    EmployeeName,
    EmployeePosition,
  
    FilialaEveniment

)
SELECT DISTINCT
    ev.[СведенияОСобытиях Период] AS Event_Period,
    ev.[СведенияОСобытиях ID] AS Event_ID,
    ev.[СведенияОСобытиях Контрагент ID] AS Event_ClientID,
    ev.[СведенияОСобытиях Состояние События] AS Event_Status,
    ev.[СведенияОСобытиях Вид События] AS Event_Kind,
    ev.[СведенияОСобытиях Тип События] AS Event_Type,
    ev.[СведенияОСобытиях Проект] AS Event_Project,
    ev.[СведенияОСобытиях Содержание События] AS Event_Content,
    ev.[СведенияОСобытиях Ответственный ID] AS Event_ResponsibleID,
    ev.[СведенияОСобытиях Ответственный] AS Event_Responsible,
    ev.[СведенияОСобытиях Дата Следующего События] AS Event_NextDateEvent,
    ev.[СведенияОСобытиях Вид Следующего События] AS Event_NextKindEvent,
    ev.[СведенияОСобытиях Филиал ID] AS Event_BranchID,
    br.[Филиалы ID] AS BranchID,
	br.[Филиалы Наименование] AS FilialaEveniment,
    c.[Контрагенты Фиск Код] AS FiscalCode,
    emp.[Сотрудники Наименование] AS EmployeeName,
    sal.[СотрудникиДанныеПоЗарплате Должность] AS EmployeePosition


FROM [ATK].[dbo].[РегистрыСведений.СведенияОСобытиях] ev
LEFT JOIN mis.[Bronze_Справочники.Контрагенты] c
       ON ev.[СведенияОСобытиях Контрагент ID] = c.[Контрагенты ID]
JOIN [ATK].[dbo].[Справочники.Филиалы] br
       ON ev.[СведенияОСобытиях Филиал ID] = br.[Филиалы ID]
JOIN [ATK].[dbo].[Справочники.Сотрудники] emp
       ON ev.[СведенияОСобытиях Ответственный ID] = emp.[Сотрудники ID]
OUTER APPLY
(
    SELECT TOP 1 *
    FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате] s
    WHERE s.[СотрудникиДанныеПоЗарплате Сотрудник ID] = ev.[СведенияОСобытиях Ответственный ID]
      AND s.[СотрудникиДанныеПоЗарплате Период] <= ev.[СведенияОСобытиях Период]
    ORDER BY s.[СотрудникиДанныеПоЗарплате Период] DESC
) sal

