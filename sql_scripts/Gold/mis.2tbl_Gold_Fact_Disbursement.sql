USE [ATK];
GO

IF OBJECT_ID('mis.[2tbl_Gold_Fact_Disbursement]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Fact_Disbursement];
GO

CREATE TABLE mis.[2tbl_Gold_Fact_Disbursement] 
(
    CreditID                NVARCHAR(36)   NOT NULL,
    ClientID                NVARCHAR(36)   NULL,
    DisbursementDate        DATETIME2      NULL,
    CurrencyID              NVARCHAR(36)   NULL,
    CreditAmount            DECIMAL(18,2)  NULL,
    CreditAmountInMDL       DECIMAL(18,2)  NULL,
    CreditCurrency          NVARCHAR(50)   NULL,
    FirstFilialID           NVARCHAR(36)   NULL,
    FirstEmployeeID         NVARCHAR(36)   NULL,
    LastFilialID            NVARCHAR(36)   NULL,
    LastEmployeeID          NVARCHAR(36)   NULL,
    IRR                     DECIMAL(18,2)  NULL,
    IRR_Client              DECIMAL(18,2)  NULL,
    EmployeePositionID      NVARCHAR(36)   NULL,
    CreditRefinancingAmount DECIMAL(15, 2) NULL,
    CreatedAt               DATETIME       NOT NULL DEFAULT GETDATE()
);
GO

-- Insert data with adjusted CreditAmount
INSERT INTO mis.[2tbl_Gold_Fact_Disbursement]
(
    CreditID,
    ClientID,
    DisbursementDate,
    CurrencyID,
    CreditAmount,
    CreditAmountInMDL,
    CreditCurrency,
    FirstFilialID,
    FirstEmployeeID,
    LastFilialID,
    LastEmployeeID,
    IRR,
    IRR_Client,
    EmployeePositionID,
    CreditRefinancingAmount
)
SELECT
    d.[ДанныеКредитовВыданных Кредит ID]                 AS CreditID,
    k.[Кредиты Владелец]                                 AS ClientID,
    d.[ДанныеКредитовВыданных Дата Выдачи]               AS DisbursementDate,
    d.[ДанныеКредитовВыданных Валюта Кредита ID]         AS CurrencyID,
    
    -- Overwrite CreditAmount with adjusted value
    CASE      
        WHEN k.[Кредиты Цель Кредита ID] = 'B9D1CEBE56F4877143FDF0DD7CAE2AE4'
        THEN ISNULL(proto.[ПротоколКомитета Сумма на Выдачу], d.[ДанныеКредитовВыданных Сумма Кредита])
    ELSE d.[ДанныеКредитовВыданных Сумма Кредита]
    END AS CreditAmount,

    -- Convert to MDL
    ROUND(
    ISNULL(proto.[ПротоколКомитета Сумма на Выдачу], d.[ДанныеКредитовВыданных Сумма Кредита]) 
    * ISNULL(rate.Rate, 1), 
    2
) AS CreditAmountInMDL,
    
    d.[ДанныеКредитовВыданных Валюта Кредита]            AS CreditCurrency,
    firstR.[ФилиалID]                                     AS FirstFilialID,
    firstR.[ЭкспертID]                                    AS FirstEmployeeID,
    COALESCE(lastR_month.[ФилиалID], firstR.[ФилиалID])   AS LastFilialID,
    COALESCE(lastR_month.[ЭкспертID], firstR.[ЭкспертID]) AS LastEmployeeID,
    irr.IRR                                               AS IRR,
    irr.IRR_Client                                        AS IRR_Client,
    emp.EmployeePositionID                                AS EmployeePositionID,
    proto_refin.[ПротоколКомитета Сумма Рефинансирования Кредита] AS CreditRefinancingAmount

FROM [ATK].[mis].[Silver_РегистрыСведений.ДанныеКредитовВыданных] d
INNER JOIN [ATK].[mis].[Silver_Справочники.Кредиты] k
    ON k.[Кредиты ID] = d.[ДанныеКредитовВыданных Кредит ID]

-- Latest protocol for credit disbursement
OUTER APPLY (
    SELECT TOP 1 p.[ПротоколКомитета Сумма на Выдачу]
    FROM [ATK].[mis].[Silver_Документы.ПротоколКомитета] p
    WHERE p.[ПротоколКомитета Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
    ORDER BY p.[ПротоколКомитета Дата] DESC
) proto

-- Latest protocol for refinancing
OUTER APPLY (
    SELECT TOP 1 p2.[ПротоколКомитета Сумма Рефинансирования Кредита]
    FROM [ATK].[mis].[Silver_Документы.ПротоколКомитета] p2
    WHERE p2.[ПротоколКомитета Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
    ORDER BY p2.[ПротоколКомитета Дата] DESC
) proto_refin

-- Currency rate
OUTER APPLY (
    SELECT TOP 1 v.[Валюта Курс] AS Rate
    FROM [ATK].[mis].[Silver_РегистрыСведений.Валюта] v
    WHERE v.[Валюта Валюта ID] = d.[ДанныеКредитовВыданных Валюта Кредита ID]
      AND v.[Валюта Период] <= d.[ДанныеКредитовВыданных Период]
    ORDER BY v.[Валюта Период] DESC
) rate

-- First responsible employee
OUTER APPLY (
    SELECT TOP 1
           r.[ОтветственныеПоКредитамВыданным Филиал ID] AS [ФилиалID],
           r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS [ЭкспертID]
    FROM [ATK].[mis].[Silver_РегистрыСведений.ОтветственныеПоКредитамВыданным] r
    WHERE r.[ОтветственныеПоКредитамВыданным Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
    ORDER BY r.[ОтветственныеПоКредитамВыданным Период] ASC
) firstR

-- Last responsible employee at month-end
OUTER APPLY (
    SELECT TOP 1
           r.[ОтветственныеПоКредитамВыданным Филиал ID] AS [ФилиалID],
           r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS [ЭкспертID]
    FROM [ATK].[mis].[Silver_РегистрыСведений.ОтветственныеПоКредитамВыданным] r
    WHERE r.[ОтветственныеПоКредитамВыданным Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
      AND r.[ОтветственныеПоКредитамВыданным Период] <= EOMONTH(d.[ДанныеКредитовВыданных Дата Выдачи])
    ORDER BY r.[ОтветственныеПоКредитамВыданным Период] DESC
) lastR_month

-- IRR
OUTER APPLY (
    SELECT TOP 1
        IRR_Client = ROUND(COALESCE(doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая], 0), 2),
        IRR = ROUND(COALESCE(
                CASE
                    WHEN doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Годовая] IS NOT NULL
                         AND doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Годовая] < 100
                        THEN doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Годовая]
                    ELSE doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая]
                END, 0), 2)
    FROM [ATK].[mis].[Silver_Документы.УстановкаДанныхКредита] doc
    WHERE doc.[УстановкаДанныхКредита Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
    ORDER BY doc.[УстановкаДанныхКредита Дата] ASC
) irr

-- Employee position
OUTER APPLY (
    SELECT TOP 1 e.[СотрудникиДанныеПоЗарплате Должность ID] AS EmployeePositionID
    FROM [ATK].[mis].[Silver_РегистрыСведений.СотрудникиДанныеПоЗарплате] e
    WHERE e.[СотрудникиДанныеПоЗарплате Сотрудник ID] = COALESCE(lastR_month.[ЭкспертID], firstR.[ЭкспертID])
    ORDER BY e.[СотрудникиДанныеПоЗарплате Период] DESC
) emp

WHERE d.[ДанныеКредитовВыданных Кредитный Продукт] NOT LIKE N'Medier%'
  AND d.[ДанныеКредитовВыданных Дата Выдачи] >= '2024-01-01';
GO
