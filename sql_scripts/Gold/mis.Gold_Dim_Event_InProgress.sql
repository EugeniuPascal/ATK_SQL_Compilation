USE [ATK];
GO

IF OBJECT_ID('mis.[Gold_Dim_Event_InProgress]', 'U') IS NULL
BEGIN
    CREATE TABLE mis.[Gold_Dim_Event_InProgress]
    (
        EventDate                 DATETIME        NULL,
        ClientType                VARCHAR(36)     NULL,
        ClientKind                VARCHAR(36)     NULL,
        ClientTRef                NVARCHAR(256)   NULL,
        ClientID                  VARCHAR(36)     NULL,
        CreditID                  VARCHAR(36)     NULL,
        CreditName                NVARCHAR(100)   NULL,
        ContactPerson             NVARCHAR(150)   NULL,
        ResponsibleID             VARCHAR(36)     NULL,
        ResponsibleName           NVARCHAR(40)    NULL,
        BranchID                  VARCHAR(36)     NULL,
        BranchName                NVARCHAR(100)   NULL,
        EventStatus               NVARCHAR(256)   NULL,
        EventKind                 NVARCHAR(256)   NULL,
        EventType                 NVARCHAR(256)   NULL,
        ProjectID                 VARCHAR(36)     NULL,
        ProjectName               NVARCHAR(100)   NULL,
        EventContent              NVARCHAR(1000)  NULL,
        EventResult               NVARCHAR(1000)  NULL,
        EventPandemicRelated      VARCHAR(36)     NULL,
        DecisionDeadline          DATETIME        NULL,
        MobilePhone               NVARCHAR(50)    NULL,
        AdditionalPhone           NVARCHAR(50)    NULL,
        PaymentDate               DATETIME        NULL,
        CallStatus                NVARCHAR(256)   NULL
    );
END
GO

INSERT INTO mis.[Gold_Dim_Event_InProgress]
(
    EventDate,
    ClientType,
    ClientKind,
    ClientTRef,
    ClientID,
    CreditID,
    CreditName,
    ContactPerson,
    ResponsibleID,
    ResponsibleName,
    BranchID,
    BranchName,
    EventStatus,
    EventKind,
    EventType,
    ProjectID,
    ProjectName,
    EventContent,
    EventResult,
    EventPandemicRelated,
    DecisionDeadline,
    MobilePhone,
    AdditionalPhone,
    PaymentDate,
    CallStatus
)
SELECT
    [СведенияОСобытияхВРаботе Дата События]             AS EventDate,
    [СведенияОСобытияхВРаботе Контрагент Tип]          AS ClientType,
    [СведенияОСобытияхВРаботе Контрагент Вид]          AS ClientKind,
    [СведенияОСобытияхВРаботе Контрагент _TRef]        AS ClientTRef,
    [СведенияОСобытияхВРаботе Контрагент ID]           AS ClientID,
    [СведенияОСобытияхВРаботе Кредит ID]               AS CreditID,
    [СведенияОСобытияхВРаботе Кредит]                  AS CreditName,
    [СведенияОСобытияхВРаботе Контактное Лицо]         AS ContactPerson,
    [СведенияОСобытияхВРаботе Ответственный ID]        AS ResponsibleID,
    [СведенияОСобытияхВРаботе Ответственный]           AS ResponsibleName,
    [СведенияОСобытияхВРаботе Филиал ID]               AS BranchID,
    [СведенияОСобытияхВРаботе Филиал]                  AS BranchName,
    [СведенияОСобытияхВРаботе Состояние События]       AS EventStatus,
    [СведенияОСобытияхВРаботе Вид События]             AS EventKind,
    [СведенияОСобытияхВРаботе Тип События]             AS EventType,
    [СведенияОСобытияхВРаботе Проект ID]               AS ProjectID,
    [СведенияОСобытияхВРаботе Проект]                  AS ProjectName,
    [СведенияОСобытияхВРаботе Содержание События]      AS EventContent,
    [СведенияОСобытияхВРаботе Результат События]       AS EventResult,
    [СведенияОСобытияхВРаботе Событие Связано с Пандемией] AS EventPandemicRelated,
    [СведенияОСобытияхВРаботе Срок Выполнения Решения] AS DecisionDeadline,
    [СведенияОСобытияхВРаботе Телефон Мобильный]       AS MobilePhone,
    [СведенияОСобытияхВРаботе Дополнительный Телефон]  AS AdditionalPhone,
    [СведенияОСобытияхВРаботе Дата Оплаты]             AS PaymentDate,
    [СведенияОСобытияхВРаботе Статус Телефонного Звонка] AS CallStatus
FROM [ATK].[dbo].[РегистрыСведений.СведенияОСобытияхВРаботе] e
WHERE NOT EXISTS (
    SELECT 1
    FROM mis.[Gold_Dim_Event_InProgress] g
    WHERE g.ClientID = e.[СведенияОСобытияхВРаботе Контрагент ID]
      AND g.EventDate = e.[СведенияОСобытияхВРаботе Дата События]
      AND g.ResponsibleID = e.[СведенияОСобытияхВРаботе Ответственный ID]
);
GO
