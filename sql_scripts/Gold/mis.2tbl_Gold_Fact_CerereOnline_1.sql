USE [ATK];
GO
SET NOCOUNT ON;

-----------------------------------------------------------------------------------
-- 2tbl_Gold_Fact_CerereOnline_1
-- Purpose:
--     Builds GOLD-level fact table for online credit requests (Cerere Online).
--     Combines data from:
--         - [Silver_Документы.ЗаявкаНаКредит]
--         - [Silver_Документы.ОбъединеннаяИнтернетЗаявка]
--     Excludes test clients based on [Контрагенты Тестовый Контрагент] = 00.
-----------------------------------------------------------------------------------

-- 1️⃣ Drop table if it exists
IF OBJECT_ID('mis.[2tbl_Gold_Fact_CerereOnline_1]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Fact_CerereOnline_1];
GO

-- 2️⃣ Create the final GOLD table structure
CREATE TABLE mis.[2tbl_Gold_Fact_CerereOnline_1] (
    [ID]                    VARCHAR(36)    NULL,
    [Date]                  DATETIME       NULL,
    [Status]                NVARCHAR(256)  NULL,
    [Posted]                VARCHAR(36)    NULL,
    [BusinessSector]        NVARCHAR(150)  NULL,
    [Type]                  NVARCHAR(100)  NULL,
    [HistoryType]           NVARCHAR(256)  NULL,
    [CreditID]              VARCHAR(36)    NULL,
    [AuthorID]              VARCHAR(36)    NULL,
    [Author]                NVARCHAR(100)  NULL,
    [Purpose]               NVARCHAR(150)  NULL,
    [IsGreen]               NVARCHAR(36)   NULL,
    [ClientID]              VARCHAR(36)    NULL,
    [NewExisting_Client]    NVARCHAR(20)   NULL,
    [RefusalReason]         NVARCHAR(200)  NULL,
    [ProductID]             VARCHAR(36)    NULL,
    [InternetID]            VARCHAR(36)    NULL,
    [CreditProductID]       VARCHAR(36)    NULL,
    [CreditProduct]         NVARCHAR(150)  NULL,
    [WebID]                 VARCHAR(36)    NOT NULL,
    [WebDate]               DATETIME       NULL,
    [WebNr]                 NVARCHAR(50)   NULL,
    [WebPosted]             VARCHAR(36)    NULL,
    [WebIncomeTypeOnline]   NVARCHAR(200)  NULL,
    [WebAge]                INT            NULL,
    [WebSubmissionDate]     DATETIME       NULL,
    [WebCredit]             NVARCHAR(100)  NULL,
    [WebIdentifier]         NVARCHAR(50)   NULL,
    [WebCreditExpert]       NVARCHAR(50)   NULL,
    [WebMobilePhone]        NVARCHAR(20)   NULL,
    [WebSentForReview]      NVARCHAR(36)   NULL,
    [WebGender]             NVARCHAR(256)  NULL,
    [WebStatus]             NVARCHAR(256)  NULL,
    [WebCreditTerm]         INT            NULL,
    [WebBranchID]           VARCHAR(36)    NULL,
    CONSTRAINT PK_2tbl_Gold_Fact_CerereOnline_1 PRIMARY KEY CLUSTERED ([WebID])
);
GO


-----------------------------------------------------------------------------------
-- 3️⃣ Build the base dataset combining credit requests and online requests
-----------------------------------------------------------------------------------
;WITH Base AS (
    -------------------------------------------------------------------------------
    -- A. From ЗаявкаНаКредит (main table) with possible linked ОбъединеннаяИнтернетЗаявка
    -------------------------------------------------------------------------------
    SELECT
        z.[ЗаявкаНаКредит ID] AS [ID],
        z.[ЗаявкаНаКредит Дата] AS [Date],
        z.[ЗаявкаНаКредит Состояние Заявки] AS [Status],
        z.[ЗаявкаНаКредит Проведен] AS [Posted],
        z.[ЗаявкаНаКредит Бизнес Сектор Экономики] AS [BusinessSector],
        z.[ЗаявкаНаКредит Вид Заявки] AS [Type],
        z.[ЗаявкаНаКредит Вид Кредитной Истории] AS [HistoryType],
        z.[ЗаявкаНаКредит Кредит ID] AS [CreditID],
        z.[ЗаявкаНаКредит Автор ID] AS [AuthorID],
        z.[ЗаявкаНаКредит Автор] AS [Author],
        z.[ЗаявкаНаКредит Цель Кредита] AS [Purpose],
        z.[ЗаявкаНаКредит Это Зеленый Кредит] AS [IsGreen],
        z.[ЗаявкаНаКредит Клиент ID] AS [ClientID],
        z.[ЗаявкаНаКредит Сумма Кредита] AS [CreditAmount],
        z.[ЗаявкаНаКредит Причина Отказа] AS [RefusalReason],
        z.[ЗаявкаНаКредит Финансовый Продукт ID] AS ProductID,
        z.[ЗаявкаНаКредит Кредитный Эксперт ID] AS ExpertID,
        z.[ЗаявкаНаКредит Филиал ID] AS BranchID,
        z.[ЗаявкаНаКредит Заявка Клиента Интернет ID] AS InternetID,
        z.[ЗаявкаНаКредит Кредитный Продукт ID] AS CreditProductID,
        z.[ЗаявкаНаКредит Кредитный Продукт] AS CreditProduct, 
        COALESCE(o.[ОбъединеннаяИнтернетЗаявка ID], CAST(NEWID() AS VARCHAR(36))) AS [WebID],
        o.[ОбъединеннаяИнтернетЗаявка Дата] AS [WebDate],
        o.[ОбъединеннаяИнтернетЗаявка Номер] AS [WebNr],
        o.[ОбъединеннаяИнтернетЗаявка Проведен] AS [WebPosted],
        o.[ОбъединеннаяИнтернетЗаявка Вид Доходов Онлайн] AS [WebIncomeTypeOnline],
        o.[ОбъединеннаяИнтернетЗаявка Возраст] AS [WebAge],
        o.[ОбъединеннаяИнтернетЗаявка Дата Отправки на Рассмотрение] AS [WebSubmissionDate],
        o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит] AS [WebCredit],
        o.[ОбъединеннаяИнтернетЗаявка Идентификатор] AS [WebIdentifier],
        o.[ОбъединеннаяИнтернетЗаявка Кредитный Эксперт] AS [WebCreditExpert],
        o.[ОбъединеннаяИнтернетЗаявка Номер Телефона Мобильный] AS [WebMobilePhone],
        o.[ОбъединеннаяИнтернетЗаявка Отправлена на Рассмотрение] AS [WebSentForReview],
        o.[ОбъединеннаяИнтернетЗаявка Пол] AS [WebGender],
        o.[ОбъединеннаяИнтернетЗаявка Состояние Заявки] AS [WebStatus],
        o.[ОбъединеннаяИнтернетЗаявка Срок Кредита] AS [WebCreditTerm],
        o.[ОбъединеннаяИнтернетЗаявка Филиал ID] AS [WebBranchID],
        COALESCE(
            z.[ЗаявкаНаКредит Клиент ID],
            o.[ОбъединеннаяИнтернетЗаявка Идентификатор],
            o.[ОбъединеннаяИнтернетЗаявка Номер Телефона Мобильный],
            o.[ОбъединеннаяИнтернетЗаявка Автор ID],
            o.[ОбъединеннаяИнтернетЗаявка ID]
        ) AS ClientKey
    FROM [ATK].[mis].[Silver_Документы.ЗаявкаНаКредит] z
    LEFT JOIN [ATK].[mis].[Silver_Документы.ОбъединеннаяИнтернетЗаявка] o
        ON z.[ЗаявкаНаКредит ID] = o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
        AND o.[ОбъединеннаяИнтернетЗаявка Дата] >= '2023-01-01'

    -------------------------------------------------------------------------------
    -- B. From ОбъединеннаяИнтернетЗаявка (when no linked ЗаявкаНаКредит)
    -------------------------------------------------------------------------------
    UNION ALL

    SELECT
        NULL AS [ID], NULL AS [Date], NULL AS [Status], NULL AS [Posted],
        NULL AS [BusinessSector], NULL AS [Type], NULL AS [HistoryType],
        NULL AS [CreditID], NULL AS [AuthorID], NULL AS [Author], NULL AS [Purpose],
        NULL AS [IsGreen], NULL AS [ClientID], NULL AS [CreditAmount],
        NULL AS [RefusalReason], NULL AS [ProductID], NULL AS [ExpertID],
        NULL AS [BranchID], NULL AS [InternetID], NULL AS [CreditProductID],
        NULL AS [CreditProduct],
        COALESCE(o.[ОбъединеннаяИнтернетЗаявка ID], CAST(NEWID() AS VARCHAR(36))) AS [WebID],
        o.[ОбъединеннаяИнтернетЗаявка Дата],
        o.[ОбъединеннаяИнтернетЗаявка Номер],
        o.[ОбъединеннаяИнтернетЗаявка Проведен],
        o.[ОбъединеннаяИнтернетЗаявка Вид Доходов Онлайн],
        o.[ОбъединеннаяИнтернетЗаявка Возраст],
        o.[ОбъединеннаяИнтернетЗаявка Дата Отправки на Рассмотрение],
        o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит],
        o.[ОбъединеннаяИнтернетЗаявка Идентификатор],
        o.[ОбъединеннаяИнтернетЗаявка Кредитный Эксперт],
        o.[ОбъединеннаяИнтернетЗаявка Номер Телефона Мобильный],
        o.[ОбъединеннаяИнтернетЗаявка Отправлена на Рассмотрение],
        o.[ОбъединеннаяИнтернетЗаявка Пол],
        o.[ОбъединеннаяИнтернетЗаявка Состояние Заявки],
        o.[ОбъединеннаяИнтернетЗаявка Срок Кредита],
        o.[ОбъединеннаяИнтернетЗаявка Филиал ID],
        COALESCE(
            o.[ОбъединеннаяИнтернетЗаявка Идентификатор],
            o.[ОбъединеннаяИнтернетЗаявка Номер Телефона Мобильный],
            o.[ОбъединеннаяИнтернетЗаявка Автор ID],
            o.[ОбъединеннаяИнтернетЗаявка ID]
        ) AS ClientKey
    FROM [ATK].[mis].[Silver_Документы.ОбъединеннаяИнтернетЗаявка] o
    LEFT JOIN [ATK].[mis].[Silver_Документы.ЗаявкаНаКредит] z
        ON z.[ЗаявкаНаКредит ID] = o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
    WHERE z.[ЗаявкаНаКредит ID] IS NULL
       OR o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID] = '00000000000000000000000000000000'
)

-----------------------------------------------------------------------------------
-- 4️⃣ Insert into final GOLD table, excluding test clients
-----------------------------------------------------------------------------------
INSERT INTO mis.[2tbl_Gold_Fact_CerereOnline_1]
(
    [ID],[Date],[Status],[Posted],[BusinessSector],[Type],[HistoryType],
    [CreditID],[AuthorID],[Author],[Purpose],[IsGreen],[ClientID],[NewExisting_Client],
    [RefusalReason],[ProductID],[InternetID],[CreditProductID],[CreditProduct],
    [WebID],[WebDate],[WebNr],[WebPosted],[WebIncomeTypeOnline],[WebAge],
    [WebSubmissionDate],[WebCredit],[WebIdentifier],[WebCreditExpert],[WebMobilePhone],
    [WebSentForReview],[WebGender],[WebStatus],[WebCreditTerm],[WebBranchID]
)
SELECT
    b.[ID], b.[Date], b.[Status], b.[Posted], b.[BusinessSector], b.[Type], b.[HistoryType],
    b.[CreditID], b.[AuthorID], b.[Author], b.[Purpose], b.[IsGreen], b.[ClientID],
    CASE
        WHEN b.CreditAmount IS NULL OR b.CreditAmount <= 0 THEN N'Cancelled'
        WHEN ROW_NUMBER() OVER (
            PARTITION BY b.ClientKey ORDER BY b.WebDate
        ) = 1 THEN N'New'
        ELSE N'Existing'
    END AS [NewExisting_Client],
    b.[RefusalReason], b.[ProductID], b.[InternetID], b.[CreditProductID], b.[CreditProduct],
    b.[WebID], b.[WebDate], b.[WebNr], b.[WebPosted], b.[WebIncomeTypeOnline], b.[WebAge],
    b.[WebSubmissionDate], b.[WebCredit], b.[WebIdentifier], b.[WebCreditExpert], b.[WebMobilePhone],
    b.[WebSentForReview], b.[WebGender], b.[WebStatus], b.[WebCreditTerm], b.[WebBranchID]
FROM Base b
LEFT JOIN dbo.[Справочники.Контрагенты] AS c
    ON b.[ClientID] = c.[Контрагенты ID]
WHERE c.[Контрагенты Тестовый Контрагент] = 00;
GO
