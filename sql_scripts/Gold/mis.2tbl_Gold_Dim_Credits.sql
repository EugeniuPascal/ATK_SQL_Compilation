USE [ATK];
GO

-- Drop table if it exists
IF OBJECT_ID(N'mis.[2tbl_Gold_Dim_Credits]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_Credits];
GO

-- Create table
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
    [LatestOutstandingAmount] DECIMAL(18,2) NULL
);
GO

WITH 
-- Base Credits
Credits AS (
    SELECT *,
           [Кредиты ID] AS CreditID,
           [Кредиты Владелец] AS Owner,
           [Кредиты Финансовый Продукт ID] AS FinancialProductID,
           [Кредиты Кредитный Продукт ID] AS ProductID
    FROM [ATK].[mis].[Silver_Справочники.Кредиты]
),

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
                ORDER BY oia.[ОбъединеннаяИнтернетЗаявка Дата] DESC
            ) AS rn
        FROM [ATK].[mis].[Silver_Документы.ЗаявкаНаКредит] znk
        LEFT JOIN [ATK].[mis].[Silver_Документы.ОбъединеннаяИнтернетЗаявка] oia
            ON znk.[ЗаявкаНаКредит ID] = oia.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
    ) t
    WHERE rn = 1
),

-- First and Last responsible experts/branches
FirstLast AS (
    SELECT
        [ОтветственныеПоКредитамВыданным Кредит ID] AS CreditID,
        [ОтветственныеПоКредитамВыданным Филиал ID] AS FilialID,
        [ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS ExpertID,
        ROW_NUMBER() OVER (PARTITION BY [ОтветственныеПоКредитамВыданным Кредит ID]
                           ORDER BY [ОтветственныеПоКредитамВыданным Период],
                                    [ОтветственныеПоКредитамВыданным Номер Строки]) AS rn_first,
        ROW_NUMBER() OVER (PARTITION BY [ОтветственныеПоКредитамВыданным Кредит ID]
                           ORDER BY [ОтветственныеПоКредитамВыданным Период] DESC,
                                    [ОтветственныеПоКредитамВыданным Номер Строки] DESC) AS rn_last
    FROM [ATK].[mis].[Silver_РегистрыСведений.ОтветственныеПоКредитамВыданным]
),

FirstResp AS (
    SELECT CreditID, FilialID AS FirstFilialID, ExpertID AS FirstExpertID
    FROM FirstLast
    WHERE rn_first = 1
),

LastResp AS (
    SELECT CreditID, FilialID AS LastFilialID, ExpertID AS LastExpertID
    FROM FirstLast
    WHERE rn_last = 1
),

-- Financial Products
FinProducts AS (
    SELECT [ФинансовыеПродукты ID] AS CreditFinancialProductID,
           [ФинансовыеПродукты Основная Группа] AS FinancialProductsMainGroup
    FROM [ATK].[mis].[Silver_Справочники.ФинансовыеПродукты]
),

-- Latest Statuses
Statuses AS (
    SELECT s.[СтатусыКредитовВыданных Кредит ID] AS CreditID,
           s.[СтатусыКредитовВыданных Статус] AS IssuedCreditsStatus,
           ROW_NUMBER() OVER (PARTITION BY s.[СтатусыКредитовВыданных Кредит ID]
                              ORDER BY s.[СтатусыКредитовВыданных Период] DESC,
                                       s.[СтатусыКредитовВыданных Номер Строки] DESC,
                                       s.[СтатусыКредитовВыданных ID] DESC) AS rn_last
    FROM [ATK].[mis].[Silver_РегистрыСведений.СтатусыКредитовВыданных] s
    WHERE s.[СтатусыКредитовВыданных Активность] = 0x01
),

-- Latest Outstanding Amount
LatestOutstanding AS (
    SELECT
        sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
        sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] AS LatestOutstandingAmount
    FROM [ATK].[mis].[Silver_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] sd
    INNER JOIN (
        SELECT 
            [СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
            MAX([СуммыЗадолженностиПоПериодамПросрочки Дата]) AS MaxDate
        FROM [ATK].[mis].[Silver_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки]
        WHERE [СуммыЗадолженностиПоПериодамПросрочки Дата] <= CAST(GETDATE() AS DATE)
        GROUP BY [СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
    ) md
        ON sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID] = md.CreditID
       AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] = md.MaxDate
)

-- Insert all columns
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
    [LatestOutstandingAmount]
)
SELECT
    c.CreditID,
    c.Owner,
    c.[Кредиты Код],
    c.[Кредиты Наименование],
    c.[Кредиты Дата Выдачи],
    c.[Кредиты Срок Кредита],
    c.[Кредиты Сумма Кредита],
    c.[Кредиты Сектор Экономики],
    c.FinancialProductID,
    c.[Кредиты Финансовый Продукт],
    c.[Кредиты Агро],
    c.[Кредиты Тип Местности],
    c.[Кредиты Валюта],
    c.ProductID,
    c.[Кредиты Кредитный Продукт],
    c.[Кредиты Цель Кредита],
    c.[Кредиты Удалить Источник Финансирования],
    c.[Кредиты Вид Контракта],
    c.[Кредиты Дата Контракта],
    c.[Кредиты Сегмент Доходов],
    c.[Кредиты Назначение Использования Кредита],
    c.[Кредиты Цель Кредита Описание],
    c.[Кредиты Тип Кредитного Продукта],
    c.[Кредиты Сфера Использования Кредита],
    c.[Кредиты Источник Подписания],
    fp.FinancialProductsMainGroup,
    st.IssuedCreditsStatus,
    cr.ApplicationPartnerID,
    COALESCE(fr.FirstFilialID, cr.FilialID),
    COALESCE(fr.FirstExpertID, cr.ExpertID),
    COALESCE(lr.LastFilialID, cr.FilialID),
    COALESCE(lr.LastExpertID, cr.ExpertID),
    cr.DealerID,
    cr.Source,
    lo.LatestOutstandingAmount
FROM Credits c
LEFT JOIN CreditRequest cr ON c.CreditID = cr.CreditID
LEFT JOIN FirstResp fr ON c.CreditID = fr.CreditID
LEFT JOIN LastResp lr ON c.CreditID = lr.CreditID
LEFT JOIN FinProducts fp ON c.FinancialProductID = fp.CreditFinancialProductID
LEFT JOIN Statuses st ON c.CreditID = st.CreditID AND st.rn_last = 1
LEFT JOIN LatestOutstanding lo ON c.CreditID = lo.CreditID;
GO

-- Optional index for faster queries
CREATE INDEX IX_2tbl_Gold_Dim_Credits_CreditID 
ON mis.[2tbl_Gold_Dim_Credits]([CreditID]);
GO
