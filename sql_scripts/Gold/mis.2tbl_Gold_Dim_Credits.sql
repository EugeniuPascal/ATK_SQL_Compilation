USE [ATK];
GO

IF OBJECT_ID(N'mis.[2tbl_Gold_Dim_Credits]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_Credits];
GO

CREATE TABLE mis.[2tbl_Gold_Dim_Credits] (
    [CreditID] VARCHAR(36) NOT NULL,
    [Owner] NVARCHAR(100) NULL,
    [Code] NVARCHAR(50) NULL,
    [Name] NVARCHAR(255) NULL,
    [IssueDate] DATE NULL,
    [Term] INT NULL,
    [Amount] DECIMAL(18, 2) NULL,
    [EconomicSector] NVARCHAR(255) NULL,
    [FinancialProductID] VARCHAR(36) NULL,
    [FinancialProduct] NVARCHAR(255) NULL,
    [Agro] NVARCHAR(255) NULL,
    [LocalityType] NVARCHAR(255) NULL,
    [Currency] NVARCHAR(50) NULL,
    [ProductID] VARCHAR(36) NULL,
    [Product] NVARCHAR(255) NULL,
    [Purpose] NVARCHAR(255) NULL,
    [RemoveFundingSource] NVARCHAR(255) NULL,
    [ContractType] NVARCHAR(255) NULL,
    [ContractDate] DATE NULL,
    [IncomeSegment] NVARCHAR(255) NULL,
    [UsagePurpose] NVARCHAR(500) NULL,
    [PurposeDescription] NVARCHAR(904) NULL,
    [ProductType] NVARCHAR(255) NULL,
    [UsageArea] NVARCHAR(255) NULL,
    [SigningSource] NVARCHAR(256) NULL,
    [FinancialProductsMainGroup] NVARCHAR(255) NULL,
    [IssuedCreditsStatus] NVARCHAR(50) NULL,
    [CreditApplicationPartnerID] VARCHAR(36) NULL,
    [FirstFilialID] VARCHAR(36) NULL,
    [FirstExpertID] VARCHAR(36) NULL,
    [LastFilialID] VARCHAR(36) NULL,
    [LastExpertID] VARCHAR(36) NULL,
    [DealerID] VARCHAR(36) NULL,
    [Source] VARCHAR(36) NULL,
    [LatestOutstandingAmount] DECIMAL(18,2) NULL,
    [SegmentRevenue] NVARCHAR(50) NULL,
    [GreenCredit] VARCHAR(36) NULL,
    CONSTRAINT PK_2tbl_Gold_Dim_Credits PRIMARY KEY CLUSTERED ([CreditID])
);
GO

WITH 
-- Credits (dedup, DATETIME already correct)
Credits AS (
    SELECT *
    FROM (
        SELECT  *,
                [Кредиты ID]                AS CreditID,
                [Кредиты Владелец]          AS Owner,
                [Кредиты Финансовый Продукт ID] AS FinancialProductID,
                [Кредиты Кредитный Продукт ID]  AS ProductID,
                ROW_NUMBER() OVER (
                    PARTITION BY [Кредиты ID]
                    ORDER BY [Кредиты Дата Выдачи] DESC, [Кредиты Код]
                ) AS rn
        FROM [ATK].[mis].[Silver_Справочники.Кредиты]
    ) x
    WHERE rn = 1
),

-- CreditRequest (keep latest)
CreditRequest AS (
    SELECT *
    FROM (
        SELECT
            znk.[ЗаявкаНаКредит Кредит ID] AS CreditID,
            znk.[ЗаявкаНаКредит Партнер ID] AS ApplicationPartnerID,
            oia.[ОбъединеннаяИнтернетЗаявка Дилер ID] AS DealerID,
            oia.[ОбъединеннаяИнтернетЗаявка Источник Заполнения] AS Source,
            oia.[ОбъединеннаяИнтернетЗаявка Филиал ID] AS FilialID,
            oia.[ОбъединеннаяИнтернетЗаявка Кредитный Эксперт ID] AS ExpertID,
            ROW_NUMBER() OVER (
                PARTITION BY znk.[ЗаявкаНаКредит Кредит ID]
                ORDER BY oia.[ОбъединеннаяИнтернетЗаявка Дата] DESC,
                         oia.[ОбъединеннаяИнтернетЗаявка ID] DESC
            ) AS rn
        FROM [ATK].[mis].[Silver_Документы.ЗаявкаНаКредит] znk
        LEFT JOIN [ATK].[mis].[Silver_Документы.ОбъединеннаяИнтернетЗаявка] oia
            ON znk.[ЗаявкаНаКредит ID] = oia.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
    ) t
    WHERE rn = 1
),

-- First/Last Responsible
FirstLast AS (
    SELECT
        [ОтветственныеПоКредитамВыданным Кредит ID] AS CreditID,
        [ОтветственныеПоКредитамВыданным Филиал ID] AS FilialID,
        [ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS ExpertID,
        ROW_NUMBER() OVER (
            PARTITION BY [ОтветственныеПоКредитамВыданным Кредит ID]
            ORDER BY [ОтветственныеПоКредитамВыданным Период],
                     [ОтветственныеПоКредитамВыданным Номер Строки]
        ) AS rn_first,
        ROW_NUMBER() OVER (
            PARTITION BY [ОтветственныеПоКредитамВыданным Кредит ID]
            ORDER BY [ОтветственныеПоКредитамВыданным Период] DESC,
                     [ОтветственныеПоКредитамВыданным Номер Строки] DESC
        ) AS rn_last
    FROM [ATK].[mis].[Silver_РегистрыСведений.ОтветственныеПоКредитамВыданным]
),
FirstResp AS (
    SELECT CreditID, FilialID AS FirstFilialID, ExpertID AS FirstExpertID
    FROM FirstLast WHERE rn_first = 1
),
LastResp AS (
    SELECT CreditID, FilialID AS LastFilialID, ExpertID AS LastExpertID
    FROM FirstLast WHERE rn_last = 1
),

-- Financial Products
FinProducts AS (
    SELECT [ФинансовыеПродукты ID] AS CreditFinancialProductID,
           [ФинансовыеПродукты Основная Группа] AS FinancialProductsMainGroup
    FROM [ATK].[mis].[Silver_Справочники.ФинансовыеПродукты]
),

-- Statuses (already DATETIME in Period column)
Statuses AS (
    SELECT *
    FROM (
        SELECT s.[СтатусыКредитовВыданных Кредит ID] AS CreditID,
               s.[СтатусыКредитовВыданных Статус] AS IssuedCreditsStatus,
               ROW_NUMBER() OVER (
                   PARTITION BY s.[СтатусыКредитовВыданных Кредит ID]
                   ORDER BY s.[СтатусыКредитовВыданных Период] DESC,
                            s.[СтатусыКредитовВыданных Номер Строки] DESC,
                            s.[СтатусыКредитовВыданных ID] DESC
               ) AS rn
        FROM [ATK].[mis].[Silver_РегистрыСведений.СтатусыКредитовВыданных] s
        WHERE s.[СтатусыКредитовВыданных Активность] = 0x01
    ) z
    WHERE rn = 1
),

-- Latest Outstanding (DATETIME date)
LatestOutstanding AS (
    SELECT sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
           sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] AS LatestOutstandingAmount
    FROM [ATK].[mis].[Silver_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] sd
    INNER JOIN (
        SELECT [СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
               MAX([СуммыЗадолженностиПоПериодамПросрочки Дата]) AS MaxDate
        FROM [ATK].[mis].[Silver_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки]
        WHERE [СуммыЗадолженностиПоПериодамПросрочки Дата] IS NOT NULL
          AND [СуммыЗадолженностиПоПериодамПросрочки Дата] <= CAST(GETDATE() AS DATE)
        GROUP BY [СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
    ) md
      ON sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID] = md.CreditID
     AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] = md.MaxDate
),

-- Segment Revenue
SegmentRevenue AS (
    SELECT
        cp.[КредитныеПродукты ID] AS ProductID,
        MAX(cp.[КредитныеПродукты Сегмент Доходов]) AS SegmentRevenue
    FROM [ATK].[dbo].[Справочники.КредитныеПродукты] cp
    WHERE cp.[КредитныеПродукты Сегмент Доходов] IS NOT NULL
    GROUP BY cp.[КредитныеПродукты ID]
),

-- Green Credit (committee date is DATETIME)
GreenCredit AS (
    SELECT *
    FROM (
        SELECT gc.[ПротоколКомитета Кредит ID] AS CreditID,
               gc.[ПротоколКомитета Это Зеленый Кредит] AS GreenCredit,
               ROW_NUMBER() OVER (
                   PARTITION BY gc.[ПротоколКомитета Кредит ID]
                   ORDER BY gc.[ПротоколКомитета Дата] DESC,
                            gc.[ПротоколКомитета ID] DESC
               ) AS rn
        FROM [ATK].[dbo].[Документы.ПротоколКомитета] gc
    ) t
    WHERE rn = 1
),

-- Final Rows
FinalRows AS (
    SELECT
        c.CreditID,
        c.Owner,
        c.[Кредиты Код] AS [Code],
        c.[Кредиты Наименование] AS [Name],
        c.[Кредиты Дата Выдачи] AS [IssueDate],
        c.[Кредиты Срок Кредита] AS [Term],
        c.[Кредиты Сумма Кредита] AS [Amount],
        c.[Кредиты Сектор Экономики] AS [EconomicSector],
        c.FinancialProductID,
        c.[Кредиты Финансовый Продукт] AS [FinancialProduct],
        c.[Кредиты Агро] AS [Agro],
        c.[Кредиты Тип Местности] AS [LocalityType],
        c.[Кредиты Валюта] AS [Currency],
        c.ProductID,
        c.[Кредиты Кредитный Продукт] AS [Product],
        c.[Кредиты Цель Кредита] AS [Purpose],
        c.[Кредиты Удалить Источник Финансирования] AS [RemoveFundingSource],
        c.[Кредиты Вид Контракта] AS [ContractType],
        c.[Кредиты Дата Контракта] AS [ContractDate],
        c.[Кредиты Сегмент Доходов] AS [IncomeSegment],
        c.[Кредиты Назначение Использования Кредита] AS [UsagePurpose],
        c.[Кредиты Цель Кредита Описание] AS [PurposeDescription],
        c.[Кредиты Тип Кредитного Продукта] AS [ProductType],
        c.[Кредиты Сфера Использования Кредита] AS [UsageArea],
        c.[Кредиты Источник Подписания] AS [SigningSource],
        fp.FinancialProductsMainGroup,
        st.IssuedCreditsStatus,
        cr.ApplicationPartnerID AS [CreditApplicationPartnerID],
        COALESCE(fr.FirstFilialID, cr.FilialID) AS [FirstFilialID],
        COALESCE(fr.FirstExpertID, cr.ExpertID) AS [FirstExpertID],
        COALESCE(lr.LastFilialID, cr.FilialID) AS [LastFilialID],
        COALESCE(lr.LastExpertID, cr.ExpertID) AS [LastExpertID],
        cr.DealerID,
        cr.Source,
        lo.LatestOutstandingAmount,
        seg.SegmentRevenue,
        gr.GreenCredit,
        ROW_NUMBER() OVER (
            PARTITION BY c.CreditID
            ORDER BY ISNULL(c.[Кредиты Дата Выдачи], '19000101') DESC,
                     c.[Кредиты Код]
        ) AS rn
    FROM Credits c
    LEFT JOIN CreditRequest  cr  ON c.CreditID = cr.CreditID
    LEFT JOIN FirstResp      fr  ON c.CreditID = fr.CreditID
    LEFT JOIN LastResp       lr  ON c.CreditID = lr.CreditID
    LEFT JOIN FinProducts    fp  ON c.FinancialProductID = fp.CreditFinancialProductID
    LEFT JOIN Statuses       st  ON c.CreditID = st.CreditID
    LEFT JOIN LatestOutstanding lo ON c.CreditID = lo.CreditID
    LEFT JOIN SegmentRevenue seg ON c.ProductID = seg.ProductID
    LEFT JOIN GreenCredit    gr  ON c.CreditID = gr.CreditID
)

INSERT INTO mis.[2tbl_Gold_Dim_Credits] (
    [CreditID], [Owner], [Code], [Name],
    [IssueDate], [Term], [Amount],
    [EconomicSector], [FinancialProductID], [FinancialProduct],
    [Agro], [LocalityType], [Currency], [ProductID],
    [Product], [Purpose], [RemoveFundingSource],
    [ContractType], [ContractDate], [IncomeSegment],
    [UsagePurpose], [PurposeDescription],
    [ProductType], [UsageArea], [SigningSource],
    [FinancialProductsMainGroup], [IssuedCreditsStatus],
    [CreditApplicationPartnerID], [FirstFilialID], [FirstExpertID],
    [LastFilialID], [LastExpertID], [DealerID], [Source],
    [LatestOutstandingAmount], [SegmentRevenue], [GreenCredit]
)
SELECT
    CreditID, Owner, [Code], [Name],
    [IssueDate], [Term], [Amount],
    [EconomicSector], [FinancialProductID], [FinancialProduct],
    [Agro], [LocalityType], [Currency], [ProductID],
    [Product], [Purpose], [RemoveFundingSource],
    [ContractType], [ContractDate], [IncomeSegment],
    [UsagePurpose], [PurposeDescription],
    [ProductType], [UsageArea], [SigningSource],
    [FinancialProductsMainGroup], [IssuedCreditsStatus],
    [CreditApplicationPartnerID], [FirstFilialID], [FirstExpertID],
    [LastFilialID], [LastExpertID], [DealerID], [Source],
    [LatestOutstandingAmount], [SegmentRevenue], [GreenCredit]
FROM FinalRows
WHERE rn = 1;
GO
