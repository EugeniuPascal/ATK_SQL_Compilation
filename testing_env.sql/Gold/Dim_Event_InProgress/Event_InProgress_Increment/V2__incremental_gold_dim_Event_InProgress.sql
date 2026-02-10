
INSERT INTO mis.[Gold_Dim_Event_InProgress]
(
    EventDate,
    ClientType,
    ClientKind,
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
