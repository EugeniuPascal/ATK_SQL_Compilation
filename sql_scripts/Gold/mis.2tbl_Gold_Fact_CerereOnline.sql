USE [ATK];
GO
SET NOCOUNT ON;

-- Drop table if exists
IF OBJECT_ID('mis.[2tbl_Gold_Fact_CerereOnline]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Fact_CerereOnline];
GO

-- Create table with shortened English-style column names
CREATE TABLE mis.[2tbl_Gold_Fact_CerereOnline] (
    [WebID]                 VARCHAR(36)    NOT NULL,
    [WebDate]               DATETIME       NULL,
    [WebNr]                 NVARCHAR(50)   NULL,
    [WebPosted]             VARCHAR(36)    NULL,
    [WebAuthorID]           VARCHAR(36)    NULL,
    [WebAuthor]             NVARCHAR(100)  NULL,
    [WebIncomeTypeOnline]   NVARCHAR(200)  NULL,
    [WebType]               NVARCHAR(256)  NULL,
    [WebAge]                INT            NULL,
    [WebSubmissionDate]     DATETIME       NULL,
    [WebCreditID]           VARCHAR(36)    NULL,
    [WebCredit]             NVARCHAR(100)  NULL,
    [WebIdentifier]         NVARCHAR(50)   NULL,
    [WebCompanyFiscalCode]  NVARCHAR(50)   NULL,
    [WebPartnerConsultant]  NVARCHAR(100)  NULL,
    [WebCreditProductID]    VARCHAR(36)    NULL,
    [WebCreditProduct]      NVARCHAR(150)  NULL,
    [WebCreditExpertID]     VARCHAR(36)    NULL,
    [WebCreditExpert]       NVARCHAR(50)   NULL,
    [WebMobilePhone]        NVARCHAR(20)   NULL,
    [WebSentForReview]      NVARCHAR(36)   NULL,
    [WebGender]             NVARCHAR(256)  NULL,
    [WebStatus]             NVARCHAR(256)  NULL,
    [WebCreditTerm]         INT            NULL,
    [WebCreditAmount]       DECIMAL(18,2)  NULL,
    [WebBranchID]           VARCHAR(36)    NULL,
    [ID]              VARCHAR(36)    NULL,
    [Date]            DATETIME       NULL,
    [Status]          NVARCHAR(256)  NULL,
    [Posted]          VARCHAR(36)    NULL,
    [BusinessSector]  NVARCHAR(150)  NULL,
    [Type]            NVARCHAR(100)  NULL,
    [HistoryType]     NVARCHAR(256)  NULL,
    [CreditID]          VARCHAR(36)    NULL,
    [Purpose]         NVARCHAR(150)  NULL,
    [IsGreen]         NVARCHAR(36)   NULL,
    [ClientID]        VARCHAR(36)    NULL,
    [NewExisting_Client]    NVARCHAR(20)   NULL,
	[RefusalReason]        NVARCHAR(200)   NULL,
    CONSTRAINT PK_2tbl_Gold_Fact_CerereOnline PRIMARY KEY CLUSTERED ([WebID])
);
GO

-- CTE to assign row numbers per client and detect New/Existing
;WITH WithCreditFlag AS (
    SELECT
        o.[ОбъединеннаяИнтернетЗаявка ID]                 AS [WebID],
        o.[ОбъединеннаяИнтернетЗаявка Дата]               AS [WebDate],
        o.[ОбъединеннаяИнтернетЗаявка Номер]              AS [WebNr],
        o.[ОбъединеннаяИнтернетЗаявка Проведен]           AS [WebPosted],
        o.[ОбъединеннаяИнтернетЗаявка Автор ID]           AS [WebAuthorID],
        o.[ОбъединеннаяИнтернетЗаявка Автор]              AS [WebAuthor],
        o.[ОбъединеннаяИнтернетЗаявка Вид Доходов Онлайн] AS [WebIncomeTypeOnline],
        o.[ОбъединеннаяИнтернетЗаявка Вид Интернет Заявки] AS [WebType],
        o.[ОбъединеннаяИнтернетЗаявка Возраст]            AS [WebAge],
        o.[ОбъединеннаяИнтернетЗаявка Дата Отправки на Рассмотрение] AS [WebSubmissionDate],
        o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID] AS [WebCreditID],
        o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит]  AS [WebCredit],
        o.[ОбъединеннаяИнтернетЗаявка Идентификатор]     AS [WebIdentifier],
        o.[ОбъединеннаяИнтернетЗаявка Компания Фиск Код] AS [WebCompanyFiscalCode],
        o.[ОбъединеннаяИнтернетЗаявка Консультант Партнера] AS [WebPartnerConsultant],
        o.[ОбъединеннаяИнтернетЗаявка Кредитный Продукт WEB ID] AS [WebCreditProductID],
        o.[ОбъединеннаяИнтернетЗаявка Кредитный Продукт WEB] AS [WebCreditProduct],
        o.[ОбъединеннаяИнтернетЗаявка Кредитный Эксперт ID] AS [WebCreditExpertID],
        o.[ОбъединеннаяИнтернетЗаявка Кредитный Эксперт] AS [WebCreditExpert],
        o.[ОбъединеннаяИнтернетЗаявка Номер Телефона Мобильный] AS [WebMobilePhone],
        o.[ОбъединеннаяИнтернетЗаявка Отправлена на Рассмотрение] AS [WebSentForReview],
        o.[ОбъединеннаяИнтернетЗаявка Пол]               AS [WebGender],
        o.[ОбъединеннаяИнтернетЗаявка Состояние Заявки]  AS [WebStatus],
        o.[ОбъединеннаяИнтернетЗаявка Срок Кредита]      AS [WebCreditTerm],
        o.[ОбъединеннаяИнтернетЗаявка Сумма Кредита]     AS [WebCreditAmount],
        o.[ОбъединеннаяИнтернетЗаявка Филиал ID]         AS [WebBranchID],
        z.[ЗаявкаНаКредит ID]                            AS [ID],
        z.[ЗаявкаНаКредит Дата]                          AS [Date],
        z.[ЗаявкаНаКредит Состояние Заявки]              AS [Status],
        z.[ЗаявкаНаКредит Проведен]                      AS [Posted],
        z.[ЗаявкаНаКредит Бизнес Сектор Экономики]       AS [BusinessSector],
        z.[ЗаявкаНаКредит Вид Заявки]                    AS [Type],
        z.[ЗаявкаНаКредит Вид Кредитной Истории]         AS [HistoryType],
        z.[ЗаявкаНаКредит Кредит ID]                     AS [CreditID],
        z.[ЗаявкаНаКредит Цель Кредита]                  AS [Purpose],
        z.[ЗаявкаНаКредит Это Зеленый Кредит]            AS [IsGreen],
        z.[ЗаявкаНаКредит Клиент ID]                     AS [ClientID],
        z.[ЗаявкаНаКредит Сумма Кредита]                 AS [CreditAmount],
		z.[ЗаявкаНаКредит Причина Отказа]                AS [RefusalReason],
    ROW_NUMBER() OVER (
            PARTITION BY COALESCE(
                z.[ЗаявкаНаКредит Клиент ID],
                o.[ОбъединеннаяИнтернетЗаявка Идентификатор],
                o.[ОбъединеннаяИнтернетЗаявка Номер Телефона Мобильный],
                o.[ОбъединеннаяИнтернетЗаявка Автор ID],
                o.[ОбъединеннаяИнтернетЗаявка ID]
            )
            ORDER BY o.[ОбъединеннаяИнтернетЗаявка Дата]
        ) AS ClientOrder
    FROM [ATK].[mis].[Silver_Документы.ОбъединеннаяИнтернетЗаявка] o
    LEFT JOIN [ATK].[mis].[Silver_Документы.ЗаявкаНаКредит] z
        ON z.[ЗаявкаНаКредит ID] = o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
    WHERE o.[ОбъединеннаяИнтернетЗаявка Дата] >= '2023-01-01'
)
INSERT INTO mis.[2tbl_Gold_Fact_CerereOnline]
(
    [WebID],
    [WebDate],
    [WebNr],
    [WebPosted],
    [WebAuthorID],
    [WebAuthor],
    [WebIncomeTypeOnline],
    [WebType],
    [WebAge],
    [WebSubmissionDate],
    [WebCreditID],
    [WebCredit],
    [WebIdentifier],
    [WebCompanyFiscalCode],
    [WebPartnerConsultant],
    [WebCreditProductID],
    [WebCreditProduct],
    [WebCreditExpertID],
    [WebCreditExpert],
    [WebMobilePhone],
    [WebSentForReview],
    [WebGender],
    [WebStatus],
    [WebCreditTerm],
    [WebCreditAmount],
    [WebBranchID],
    [ID],
    [Date],
    [Status],
    [Posted],
    [BusinessSector],
    [Type],
    [HistoryType],
    [CreditID],
    [Purpose],
    [IsGreen],
    [ClientID],
    [NewExisting_Client],
	[RefusalReason]
)
SELECT
    [WebID],
    [WebDate],
    [WebNr],
    [WebPosted],
    [WebAuthorID],
    [WebAuthor],
    [WebIncomeTypeOnline],
    [WebType],
    [WebAge],
    [WebSubmissionDate],
    [WebCreditID],
    [WebCredit],
    [WebIdentifier],
    [WebCompanyFiscalCode],
    [WebPartnerConsultant],
    [WebCreditProductID],
    [WebCreditProduct],
    [WebCreditExpertID],
    [WebCreditExpert],
    [WebMobilePhone],
    [WebSentForReview],
    [WebGender],
    [WebStatus],
    [WebCreditTerm],
    [WebCreditAmount],
    [WebBranchID],
    [ID],
    [Date],
    [Status],
    [Posted],
    [BusinessSector],
    [Type],
    [HistoryType],
    [CreditID],
    [Purpose],
    [IsGreen],
    [ClientID],
CASE
     WHEN CreditAmount IS NULL OR CreditAmount <= 0 THEN N'Cancelled'
     WHEN ClientOrder = 1 THEN N'New'
     ELSE N'Existing'
END AS [NewExisting_Client],
       [RefusalReason]
FROM WithCreditFlag;
    
GO

-- Indexes
CREATE NONCLUSTERED INDEX IX_CO_Date
    ON mis.[2tbl_Gold_Fact_CerereOnline]([WebDate]);

CREATE NONCLUSTERED INDEX IX_CO_Client
    ON mis.[2tbl_Gold_Fact_CerereOnline]([ClientID])
    INCLUDE ([NewExisting_Client],[WebCreditAmount]);

CREATE NONCLUSTERED INDEX IX_CO_Status
    ON mis.[2tbl_Gold_Fact_CerereOnline]([WebStatus]);
GO
