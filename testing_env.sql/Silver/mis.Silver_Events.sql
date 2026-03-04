USE [ATK];
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'[mis].[Silver_Events]', N'U') IS NOT NULL
    DROP TABLE [mis].[Silver_Events];

CREATE TABLE [mis].[Silver_Events]
(
      [ID]                     VARCHAR(34)     NOT NULL,
      [ПометкаУдаления]         BINARY(1)       NULL,
      [Дата]                    DATETIME2       NULL,
      [Проведен]                BINARY(1)       NULL,
      [Номер]                   NUMERIC(9,0)    NULL,
      [ДатаСоздания]            DATETIME2       NULL,
      [ДатаПроведения]          DATETIME2       NULL,
      [АвторID]                 VARCHAR(34)     NULL,
      [КонтрагентID]            VARCHAR(34)     NULL,
      [КредитID]                VARCHAR(34)     NULL,
      [ВидСобытия]              NVARCHAR(256)   NULL,
      [ОписаниеСобытия]         NVARCHAR(MAX)   NULL,
      [ОтветственныйID]         VARCHAR(34)     NULL,
      [ОтветственныйФилиалID]   VARCHAR(34)     NULL,
      [ДолжностьID]             VARCHAR(34)     NULL,
      [Должность]               NVARCHAR(150)   NULL,
      [ВидДолжностиID]          VARCHAR(34)     NULL,
      [ВидДолжности]            NVARCHAR(150)   NULL,
      [Проект]                  NVARCHAR(256)   NULL,
      [СодержаниеСобытия]       NVARCHAR(MAX)   NULL,
      [СостояниеСобытия]        NVARCHAR(256)   NULL,
      [ТипСобытия]              NVARCHAR(50)    NULL,
      [ТелефонМобильный]        NVARCHAR(15)    NULL,
      [ДатаСледующегоСобытия]   DATETIME2       NULL,
      [ВидСледующегоСобытия]    NVARCHAR(256)   NULL,
      [СтатусТелефонногоЗвонка] NVARCHAR(256)   NULL,
      [ФискКод]                 NVARCHAR(50)    NULL,
      [ВидКонтакта]             NVARCHAR(10)    NULL
);

INSERT INTO [mis].[Silver_Events]
SELECT
      REPLACE(CONVERT(varchar(34), b.[ID], 1), '0x', '')                 AS [ID]
    , b.[ПометкаУдаления]
    , b.[Дата]
    , b.[Проведен]
    , b.[Номер]
    , b.[ДатаСоздания]
    , b.[ДатаПроведения]
    , REPLACE(CONVERT(varchar(34), b.[АвторID], 1), '0x', '')            AS [АвторID]
    , x.[КонтрагентID_hex]                                              AS [КонтрагентID]
    , REPLACE(CONVERT(varchar(34), b.[КредитID], 1), '0x', '')           AS [КредитID]
    , ev1.[ВидыСобытий]                                                  AS [ВидСобытия]
    , b.[ОписаниеСобытия]
    , b.[ОтветственныйID]
    , emp.[СотрудникиДанныеПоЗарплате Филиал ID]                         AS [ОтветственныйФилиалID]
    , emp.[СотрудникиДанныеПоЗарплате Должность ID]                      AS [ДолжностьID]
    , emp.[СотрудникиДанныеПоЗарплате Должность]                         AS [Должность]
    , emp.[СотрудникиДанныеПоЗарплате Вид Должности ID]                  AS [ВидДолжностиID]
    , emp.[СотрудникиДанныеПоЗарплате Вид Должности]                     AS [ВидДолжности]  
    , pr.[Проекты Наименование]                                          AS [Проект]
    , b.[СодержаниеСобытия]
    , st.[СостоянияСобытий]                                              AS [СостояниеСобытия]
    , io.[ВходящееИсходящееСобытие]                                      AS [ТипСобытия]
    , b.[ТелефонМобильный]
    , b.[ДатаСледующегоСобытия]
    , ev2.[ВидыСобытий]                                                  AS [ВидСледующегоСобытия]
    , ts.[СтатусыТелефонногоЗвонка]                                      AS [СтатусТелефонногоЗвонка]
    , COALESCE(c.[Контрагенты Фиск Код], l.[Лиды Фиск Код])              AS [ФискКод]
    , CASE
        WHEN c.[Контрагенты ID] IS NOT NULL THEN 'Client'
        WHEN l.[Лиды ID]        IS NOT NULL THEN 'Lead'
        ELSE NULL
      END                                                               AS [ВидКонтакта]
FROM [mis].[Bronze_Документы.События] b

CROSS APPLY
(
    SELECT REPLACE(CONVERT(varchar(34), b.[КонтрагентID], 1), '0x', '') AS [КонтрагентID_hex]
) x

OUTER APPLY
(
    SELECT TOP (1)
          s.[СотрудникиДанныеПоЗарплате Период]
        , s.[СотрудникиДанныеПоЗарплате Сотрудник ID]
        , s.[СотрудникиДанныеПоЗарплате Филиал ID]
        , s.[СотрудникиДанныеПоЗарплате Должность ID]
        , s.[СотрудникиДанныеПоЗарплате Должность]
        , s.[СотрудникиДанныеПоЗарплате Вид Должности ID]
        , s.[СотрудникиДанныеПоЗарплате Вид Должности]
    FROM [ATK].[mis].[Bronze_РегистрыСведений.СотрудникиДанныеПоЗарплате] s
    WHERE s.[СотрудникиДанныеПоЗарплате Сотрудник ID] = b.[ОтветственныйID]
      AND s.[СотрудникиДанныеПоЗарплате Период] < DATEADD(DAY, 1, CONVERT(date, b.[Дата]))
    ORDER BY s.[СотрудникиДанныеПоЗарплате Период] DESC
) emp

LEFT JOIN [ATK].[dbo].[Перечисления.СостоянияСобытий] st
    ON st.[СостоянияСобытий ID] = b.[СостояниеСобытияID]

LEFT JOIN [ATK].[dbo].[Справочники.Проекты] pr
    ON pr.[Проекты ID] = REPLACE(CONVERT(varchar(34), b.[ПроектID], 1), '0x', '')

LEFT JOIN [ATK].[dbo].[Перечисления.ВходящееИсходящееСобытие] io
    ON io.[ВходящееИсходящееСобытие ID] = b.[ТипСобытияID]

LEFT JOIN [ATK].[dbo].[Перечисления.ВидыСобытий] ev1
    ON ev1.[ВидыСобытий ID] = b.[ВидСобытияID]

LEFT JOIN [ATK].[dbo].[Перечисления.ВидыСобытий] ev2
    ON ev2.[ВидыСобытий ID] = b.[ВидСледующегоСобытияID]

LEFT JOIN [ATK].[dbo].[Перечисления.СтатусыТелефонногоЗвонка] ts
    ON ts.[СтатусыТелефонногоЗвонка ID] = b.[СтатусыТелефонногоЗвонкаID]

LEFT JOIN [ATK].[mis].[Bronze_Справочники.Контрагенты] c
    ON c.[Контрагенты ID] = x.[КонтрагентID_hex]

LEFT JOIN [ATK].[dbo].[Справочники.Лиды] l
    ON l.[Лиды ID] = x.[КонтрагентID_hex];



