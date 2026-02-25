USE [ATK];
GO
SET NOCOUNT ON;

IF OBJECT_ID('mis.[Silver_CerereOnline_base]', 'U') IS NOT NULL
    DROP TABLE mis.[Silver_CerereOnline_base];
GO

CREATE TABLE mis.[Silver_CerereOnline_base] 
(
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
    [CreditAmount]          DECIMAL(15,2)  NULL,
    [CurrencyType]          NVARCHAR(36)   NULL,
    [CreditAmountInMDL]     DECIMAL(18,2)  NULL,
    [NewExisting_Client]    NVARCHAR(20)   NULL,
    [RefusalReason]         NVARCHAR(200)  NULL,
    [CreditProduct]         NVARCHAR(150)  NULL,
    [ProductID]             VARCHAR(36)    NULL,
    [CreditProductID]       VARCHAR(36)    NULL,
    [InternetID]            VARCHAR(36)    NULL,
    [EmployeeID]            VARCHAR(36)    NULL,
    [BranchID]              VARCHAR(36)    NULL,
    [PartnerID]             VARCHAR(36)    NULL,
    [Partner]               NVARCHAR(150)  NULL,
    [WebDate]               DATETIME       NULL,
    [WebNr]                 NVARCHAR(50)   NULL,
    [WebPosted]             VARCHAR(36)    NULL,
    [WebIncomeTypeOnline]   NVARCHAR(200)  NULL,
    [WebAge]                INT            NULL,
    [WebSubmissionDate]     DATETIME       NULL,
    [WebCredit]             NVARCHAR(100)  NULL,
    [WebIdentifier]         NVARCHAR(50)   NULL,
    [WebCreditEmployee]     NVARCHAR(50)   NULL,
    [WebMobilePhone]        NVARCHAR(20)   NULL,
    [WebSentForReview]      NVARCHAR(36)   NULL,
    [WebGender]             NVARCHAR(256)  NULL,
    [WebStatus]             NVARCHAR(256)  NULL,
    [WebCreditTerm]         INT            NULL,
    [WebBranchID]           VARCHAR(36)    NULL,
	[ContactPerson]         NVARCHAR(100)  NULL,
	[ContactPersonPhone]     NVARCHAR(50)   NULL,
    [CommitteeDecisionDate] DATETIME       NULL,
	[CommitteeDecision]     NVARCHAR(256)  NULL
);
GO

-- CTE for base data
;WITH Base AS (
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
        z.[ЗаявкаНаКредит Валюта] AS [CurrencyType],
        z.[ЗаявкаНаКредит Причина Отказа] AS [RefusalReason],
        z.[ЗаявкаНаКредит Кредитный Продукт] AS [CreditProduct],
        z.[ЗаявкаНаКредит Финансовый Продукт ID] AS [ProductID],
        z.[ЗаявкаНаКредит Кредитный Продукт ID] AS [CreditProductID],
        z.[ЗаявкаНаКредит Заявка Клиента Интернет ID] AS [InternetID],
        z.[ЗаявкаНаКредит Кредитный Эксперт ID] AS [EmployeeID],
        z.[ЗаявкаНаКредит Филиал ID] AS [BranchID],
        z.[ЗаявкаНаКредит Партнер ID] AS [PartnerID],
        z.[ЗаявкаНаКредит Партнер] AS [Partner],
        o.[ОбъединеннаяИнтернетЗаявка Дата] AS [WebDate],
        o.[ОбъединеннаяИнтернетЗаявка Номер] AS [WebNr],
        o.[ОбъединеннаяИнтернетЗаявка Проведен] AS [WebPosted],
        o.[ОбъединеннаяИнтернетЗаявка Вид Доходов Онлайн] AS [WebIncomeTypeOnline],
        o.[ОбъединеннаяИнтернетЗаявка Возраст] AS [WebAge],
        o.[ОбъединеннаяИнтернетЗаявка Дата Отправки на Рассмотрение] AS [WebSubmissionDate],
        o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит] AS [WebCredit],
        o.[ОбъединеннаяИнтернетЗаявка Идентификатор] AS [WebIdentifier],
        o.[ОбъединеннаяИнтернетЗаявка Кредитный Эксперт] AS [WebCreditEmployee],
        o.[ОбъединеннаяИнтернетЗаявка Номер Телефона Мобильный] AS [WebMobilePhone],
        o.[ОбъединеннаяИнтернетЗаявка Отправлена на Рассмотрение] AS [WebSentForReview],
        o.[ОбъединеннаяИнтернетЗаявка Пол] AS [WebGender],
        o.[ОбъединеннаяИнтернетЗаявка Состояние Заявки] AS [WebStatus],
        o.[ОбъединеннаяИнтернетЗаявка Срок Кредита] AS [WebCreditTerm],
        o.[ОбъединеннаяИнтернетЗаявка Филиал ID] AS [WebBranchID],
		o.[ОбъединеннаяИнтернетЗаявка Контактное Лицо] AS ContactPerson,
		o.[ОбъединеннаяИнтернетЗаявка Контактное Лицо Номер Телефона Мобильный] AS [ContactPersonPhone],
        COALESCE(
            z.[ЗаявкаНаКредит Клиент ID],
            o.[ОбъединеннаяИнтернетЗаявка Идентификатор],
            o.[ОбъединеннаяИнтернетЗаявка Номер Телефона Мобильный],
            o.[ОбъединеннаяИнтернетЗаявка Автор ID],
            o.[ОбъединеннаяИнтернетЗаявка ID]
        ) AS ClientKey,
        c.[ПротоколКомитета Дата Решения] AS [CommitteeDecisionDate],
		c.[ПротоколКомитета Решение Комитета] AS [CommitteeDecision]
    FROM [ATK].[mis].[Bronze_Документы.ЗаявкаНаКредит] z
    LEFT JOIN [ATK].[mis].[Bronze_Документы.ОбъединеннаяИнтернетЗаявка] o
        ON z.[ЗаявкаНаКредит ID] = o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
		AND (o.[ОбъединеннаяИнтернетЗаявка Пометка Удаления] = '00'
	    OR o.[ОбъединеннаяИнтернетЗаявка Пометка Удаления] IS NULL)
    INNER JOIN [ATK].[mis].[Bronze_Документы.ПротоколКомитета] c
        ON c.[ПротоколКомитета Заявка ID] = z.[ЗаявкаНаКредит ID]
		AND c.[ПротоколКомитета Проведен] = '01'
		

    UNION ALL

    SELECT
        NULL AS [ID], NULL AS [Date], NULL AS [Status], NULL AS [Posted], NULL AS [BusinessSector], NULL AS [Type], NULL AS [HistoryType],
        NULL AS [CreditID], NULL AS [AuthorID], NULL AS [Author], NULL AS [Purpose], NULL AS [IsGreen], NULL AS [ClientID], 
		NULL AS [CreditAmount], NULL AS [CurrencyType], NULL AS [RefusalReason], NULL AS [CreditProduct], NULL AS [ProductID], 
		NULL AS [CreditProductID], NULL AS [InternetID], NULL AS [EmployeeID], NULL AS [BranchID], NULL AS [PartnerID], NULL AS [Partner],
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
		o.[ОбъединеннаяИнтернетЗаявка Контактное Лицо],
		o.[ОбъединеннаяИнтернетЗаявка Контактное Лицо Номер Телефона Мобильный],
        COALESCE(
            o.[ОбъединеннаяИнтернетЗаявка Идентификатор],
            o.[ОбъединеннаяИнтернетЗаявка Номер Телефона Мобильный],
            o.[ОбъединеннаяИнтернетЗаявка Автор ID],
            o.[ОбъединеннаяИнтернетЗаявка ID]
        ) AS ClientKey,
        NULL AS [CommitteeDecisionDate],
		NULL AS [CommitteeDecision]

    FROM [ATK].[mis].[Bronze_Документы.ОбъединеннаяИнтернетЗаявка] o
    LEFT JOIN [ATK].[mis].[Bronze_Документы.ЗаявкаНаКредит] z
        ON z.[ЗаявкаНаКредит ID] = o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
    WHERE z.[ЗаявкаНаКредит ID] IS NULL
       OR o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID] = '00000000000000000000000000000000'
	   AND (o.[ОбъединеннаяИнтернетЗаявка Пометка Удаления] = '00'
	   OR o.[ОбъединеннаяИнтернетЗаявка Пометка Удаления] IS NULL)
)
INSERT INTO mis.[Silver_CerereOnline_base] 
(
    [ID],[Date],[Status],[Posted],[BusinessSector],[Type],[HistoryType], [CreditID],[AuthorID],[Author],[Purpose],[IsGreen],[ClientID],
    [CreditAmount],[CurrencyType], [CreditAmountInMDL],[NewExisting_Client], [RefusalReason],[CreditProduct],[ProductID],[CreditProductID],
    [InternetID],[EmployeeID],[BranchID],[PartnerID],[Partner], [WebDate],[WebNr],[WebPosted],[WebIncomeTypeOnline],[WebAge],
    [WebSubmissionDate],[WebCredit],[WebIdentifier],[WebCreditEmployee], [WebMobilePhone],[WebSentForReview],[WebGender],[WebStatus],
    [WebCreditTerm],[WebBranchID],[ContactPerson],[ContactPersonPhone], [CommitteeDecisionDate], [CommitteeDecision]
)
SELECT
    b.[ID], b.[Date], b.[Status], b.[Posted],
    b.[BusinessSector], b.[Type], b.[HistoryType],
    b.[CreditID], b.[AuthorID], b.[Author], b.[Purpose],
    b.[IsGreen], b.[ClientID], b.[CreditAmount], b.[CurrencyType],
    ROUND(b.[CreditAmount] * ISNULL(v.[Валюта Курс], 1), 2) AS [CreditAmountInMDL],
    CASE
        WHEN b.CreditAmount IS NULL OR b.CreditAmount <= 0 THEN N'Cancelled'
        WHEN ROW_NUMBER() OVER (PARTITION BY b.ClientKey ORDER BY b.WebDate) = 1 THEN N'New'
        ELSE N'Existing'
    END AS [NewExisting_Client],
    b.[RefusalReason], b.[CreditProduct], b.[ProductID], b.[CreditProductID],
    b.[InternetID], b.[EmployeeID], b.[BranchID], b.[PartnerID], b.[Partner],
    b.[WebDate], b.[WebNr], b.[WebPosted], b.[WebIncomeTypeOnline], b.[WebAge],
    b.[WebSubmissionDate], b.[WebCredit], b.[WebIdentifier], b.[WebCreditEmployee],
    b.[WebMobilePhone], b.[WebSentForReview], b.[WebGender], b.[WebStatus],
    b.[WebCreditTerm], b.[WebBranchID], b.[ContactPerson], b.[ContactPersonPhone],
	b.[CommitteeDecisionDate], b.[CommitteeDecision]
FROM Base b
LEFT JOIN [ATK].[mis].[Bronze_Справочники.Контрагенты] AS c
    ON b.[ClientID] = c.[Контрагенты ID]
OUTER APPLY (
    SELECT TOP 1 v.[Валюта Курс]
    FROM [ATK].[mis].[Bronze_РегистрыСведений.Валюта] v
    WHERE v.[Валюта Валюта] = b.[CurrencyType]
      AND v.[Валюта Период] <= b.[Date]
    ORDER BY v.[Валюта Период] DESC
) AS v
WHERE c.[Контрагенты Тестовый Контрагент] = 0;
GO
