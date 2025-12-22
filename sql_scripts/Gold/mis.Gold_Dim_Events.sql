USE [ATK];
GO

IF OBJECT_ID('mis.[Gold_Dim_Events]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_Events];
GO

CREATE TABLE mis.[Gold_Dim_Events]
(
    Event_Period DATETIME NOT NULL,
    Event_ID VARCHAR(36) NOT NULL,
    Event_ClientID VARCHAR(36) NOT NULL,
    Event_Status NVARCHAR(256) NULL,
    Event_Kind NVARCHAR(256) NULL,
	Event_Type NVARCHAR(256) NULL,
	Event_Project NVARCHAR(150) NULL,
	Event_Content NVARCHAR(1000) NULL,
	Event_ResponsibleID VARCHAR(36) NOT NULL,
	Event_Responsible NVARCHAR(1000) NULL,
	Event_NextDateEvent DATETIME NOT NULL,
	Event_NextKindEvent NVARCHAR(256) NULL,
	Event_BranchID VARCHAR(36) NOT NULL
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
	Event_BranchID
)
SELECT

    [СведенияОСобытиях Период] AS Event_Period,
    [СведенияОСобытиях ID] AS Event_ID,
    [СведенияОСобытиях Контрагент ID] AS Event_ClientID,
    [СведенияОСобытиях Состояние События] AS Event_Status,
    [СведенияОСобытиях Вид События] AS Event_Kind,
    [СведенияОСобытиях Тип События] AS Event_Type,
    [СведенияОСобытиях Проект] AS Event_Project,
    [СведенияОСобытиях Содержание События] AS Event_Content,
    [СведенияОСобытиях Ответственный ID] AS Event_ResponsibleID,
    [СведенияОСобытиях Ответственный] AS Event_Responsible,
    [СведенияОСобытиях Дата Следующего События] AS Event_NextDateEvent,
    [СведенияОСобытиях Вид Следующего События] AS Event_NextKindEvent,
    [СведенияОСобытиях Филиал ID] AS Event_BranchID

  FROM [ATK].[dbo].[РегистрыСведений.СведенияОСобытиях];