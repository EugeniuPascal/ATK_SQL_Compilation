USE [ATK];
GO

IF OBJECT_ID('mis.[2tbl_Gold_Fact_WriteOffCredits]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Fact_WriteOffCredits];
GO

CREATE TABLE mis.[2tbl_Gold_Fact_WriteOffCredits]
(
    [Credit_CanceledCreditID] VARCHAR(36) NOT NULL,
    [Credit_RowNumber]        INT NULL,
    [Credit_AccountID]        VARCHAR(36) NULL,
    [Credit_Account]          NVARCHAR(250) NULL,
    [Credit_ClientID]         VARCHAR(36) NULL,
    [Credit_Client]           NVARCHAR(150) NULL,
    [Credit_CreditID]         VARCHAR(36) NULL,
    [Credit_Credit]           NVARCHAR(150) NULL,
    [Credit_CurrencyID]       VARCHAR(36) NULL,
    [Credit_Currency]         NVARCHAR(50) NULL,
    [Credit_Amount]           DECIMAL(14, 2) NULL,
    [Credit_AmountCurrency]   DECIMAL(14, 2) NULL,
    [Credit_Interest]         DECIMAL(14, 2) NULL,
    [Credit_InterestCurrency] DECIMAL(14, 2) NULL,
    [Credit_Penalty]          DECIMAL(14, 2) NULL,
    [Credit_PenaltyCurrency]  DECIMAL(14, 2) NULL,
    [Credit_Commission]       DECIMAL(15, 2) NULL,
    [Credit_CommissionCurrency] DECIMAL(15, 2) NULL,
    [Credit_LineAmount]       DECIMAL(15, 2) NULL,
    [Credit_LineAmountCurrency] DECIMAL(15, 2) NULL,
    [Canceled_CreditDate]    DATETIME NULL,
    [Canceled_CreditPosted]  VARCHAR(36) NULL,
    [Canceled_CreditBase]    NVARCHAR(250) NULL,
	[Canceled_CreditAuthorID] VARCHAR(36) NULL,
	[Canceled_DebitAccount]  NVARCHAR(250) NULL
);
GO

INSERT INTO mis.[2tbl_Gold_Fact_WriteOffCredits]
(
    [Credit_CanceledCreditID],
    [Credit_RowNumber],
    [Credit_AccountID],
    [Credit_Account],
    [Credit_ClientID],
    [Credit_Client],
    [Credit_CreditID],
    [Credit_Credit],
    [Credit_CurrencyID],
    [Credit_Currency],
    [Credit_Amount],
    [Credit_AmountCurrency],
    [Credit_Interest],
    [Credit_InterestCurrency],
    [Credit_Penalty],
    [Credit_PenaltyCurrency],
    [Credit_Commission],
    [Credit_CommissionCurrency],
    [Credit_LineAmount],
    [Credit_LineAmountCurrency],
    [Canceled_CreditDate],
    [Canceled_CreditPosted],
    [Canceled_CreditBase],
	[Canceled_CreditAuthorID],
	[Canceled_DebitAccount]
)
SELECT
    a.[АнулированиеКредитов ID],
    a.[АнулированиеКредитов.Кредиты Номер Строки],
    a.[АнулированиеКредитов.Кредиты Счет ID],
    a.[АнулированиеКредитов.Кредиты Счет],
    a.[АнулированиеКредитов.Кредиты Контрагент ID],
    a.[АнулированиеКредитов.Кредиты Контрагент],
    a.[АнулированиеКредитов.Кредиты Кредит ID],
    a.[АнулированиеКредитов.Кредиты Кредит],
    a.[АнулированиеКредитов.Кредиты Валюта ID],
    a.[АнулированиеКредитов.Кредиты Валюта],
    a.[АнулированиеКредитов.Кредиты Сумма],
    a.[АнулированиеКредитов.Кредиты Сумма Валютная],
    a.[АнулированиеКредитов.Кредиты Процент],
    a.[АнулированиеКредитов.Кредиты Процент Валютный],
    a.[АнулированиеКредитов.Кредиты Пеня],
    a.[АнулированиеКредитов.Кредиты Пеня Валютный],
    a.[АнулированиеКредитов.Кредиты Комиссион],
    a.[АнулированиеКредитов.Кредиты Комиссион Валютный],
    a.[АнулированиеКредитов.Кредиты Сумма Кредитная Линия],
    a.[АнулированиеКредитов.Кредиты Сумма Кредитная Линия Валютная],
    b.[АнулированиеКредитов Дата],
    b.[АнулированиеКредитов Проведен],
    b.[АнулированиеКредитов Основание],
	b.[АнулированиеКредитов Автор ID],
	b.[АнулированиеКредитов Счет Дт]
FROM [ATK].[dbo].[Документы.АнулированиеКредитов.Кредиты] AS a
LEFT JOIN [ATK].[dbo].[Документы.АнулированиеКредитов] AS b
    ON a.[АнулированиеКредитов ID] = b.[АнулированиеКредитов ID];
GO
