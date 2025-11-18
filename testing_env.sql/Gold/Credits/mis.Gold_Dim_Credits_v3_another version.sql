USE [ATK];
GO

-- Drop table if exists
IF OBJECT_ID(N'mis.[2tbl_Gold_Dim_Credits_v3]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_Credits_v3];
GO

-- Create table
CREATE TABLE mis.[2tbl_Gold_Dim_Credits_v3] (
    [CreditID] VARCHAR(36) NOT NULL PRIMARY KEY CLUSTERED,
    [Owner] NVARCHAR(150) NULL,
    [Code] NVARCHAR(50) NULL,
    [Name] NVARCHAR(255) NULL,
    [IssueDate] DATE NULL,
    [Term] INT NULL,
    [Amount] DECIMAL(18,2) NULL,
    [EconomicSectorDetailed] NVARCHAR(255) NULL,
    [FinancialProductID] VARCHAR(36) NULL,
    [FinancialProduct] NVARCHAR(255) NULL,
    [AgroCredit] NVARCHAR(50) NULL,
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
    [PurposeDescription] NVARCHAR(1000) NULL,
    [ProductType] NVARCHAR(255) NULL,
    [EconomicUsageArea] NVARCHAR(255) NULL,
    [SigningSource] NVARCHAR(500) NULL,
    [FinancialProductsMainGroup] NVARCHAR(255) NULL,
    [IssuedCreditsStatus] NVARCHAR(50) NULL,
    [PartnerID] VARCHAR(36) NULL,
    [First_PartnerID] VARCHAR(36) NULL,
    [First_PartnerName] NVARCHAR(255) NULL,
    [PartnerName] NVARCHAR(255) NULL,
    [FirstFilialID] VARCHAR(36) NULL,
    [FirstEmployeeID] VARCHAR(36) NULL,
    [LastFilialID] VARCHAR(36) NULL,
    [LastEmployeeID] VARCHAR(36) NULL,
    [DealerID] VARCHAR(36) NULL,
    [Source] NVARCHAR(150) NULL,
    [LatestOutstandingAmount] DECIMAL(18,2) NULL,
    [SegmentRevenue] NVARCHAR(50) NULL,
    [GreenCredit] VARCHAR(36) NULL,
    [CommitteeProt_CrPurpose] NVARCHAR(256) NULL,
    [CommitteeProt_AMLRiskCat] NVARCHAR(256) NULL,
    [DigitalSign] NVARCHAR(50) NULL,
    [EconomicSectorEFSE] NVARCHAR(100) NULL,
    [EconomicSector] NVARCHAR(100) NULL,
    [Agro] NVARCHAR(50) NULL,
    [First_PartnerID_2023] VARCHAR(36) NULL,
    [First_PartnerID_2024] VARCHAR(36) NULL,
    [First_PartnerID_2025] VARCHAR(36) NULL
);
GO

WITH
Credits AS (
    SELECT *
    FROM (
        SELECT *,
               ROW_NUMBER() OVER(PARTITION BY [Кредиты ID] ORDER BY [Кредиты Дата Выдачи] DESC, [Кредиты Код]) AS rn
        FROM [ATK].[mis].[Bronze_Справочники.Кредиты]
    ) t
    WHERE rn = 1
),

OIA_LatestPerApp AS (
    SELECT *
    FROM (
        SELECT oia.*,
               ROW_NUMBER() OVER (
                   PARTITION BY oia.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
                   ORDER BY oia.[ОбъединеннаяИнтернетЗаявка Дата] DESC,
                            oia.[ОбъединеннаяИнтернетЗаявка ID] DESC
               ) AS rn
        FROM [ATK].[mis].[Bronze_Документы.ОбъединеннаяИнтернетЗаявка] oia
    ) t
    WHERE rn = 1
),
CreditRequest AS (
    SELECT *
    FROM (
        SELECT
            znk.[ЗаявкаНаКредит Кредит ID] AS CreditID,
            znk.[ЗаявкаНаКредит Партнер ID] AS PartnerID,
            oia.[ОбъединеннаяИнтернетЗаявка Дилер ID] AS DealerID,
            NULLIF(LTRIM(RTRIM(oia.[ОбъединеннаяИнтернетЗаявка Источник Заполнения])), '') AS Source,
            oia.[ОбъединеннаяИнтернетЗаявка Филиал ID] AS FilialID,
            oia.[ОбъединеннаяИнтернетЗаявка Кредитный Эксперт ID] AS EmployeeID,
            ROW_NUMBER() OVER (
                PARTITION BY znk.[ЗаявкаНаКредит Кредит ID]
                ORDER BY oia.[ОбъединеннаяИнтернетЗаявка Дата] DESC,
                         oia.[ОбъединеннаяИнтернетЗаявка ID] DESC
            ) AS rn
        FROM [ATK].[mis].[Bronze_Документы.ЗаявкаНаКредит] znk
        LEFT JOIN OIA_LatestPerApp oia
           ON znk.[ЗаявкаНаКредит ID] = oia.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
    ) t
    WHERE rn = 1
),
Resp AS (
    SELECT
        [ОтветственныеПоКредитамВыданным Кредит ID] AS CreditID,
        MIN([ОтветственныеПоКредитамВыданным Филиал ID]) AS FirstFilialID,
        MIN([ОтветственныеПоКредитамВыданным Кредитный Эксперт ID]) AS FirstEmployeeID,
        MAX([ОтветственныеПоКредитамВыданным Филиал ID]) AS LastFilialID,
        MAX([ОтветственныеПоКредитамВыданным Кредитный Эксперт ID]) AS LastEmployeeID
    FROM [ATK].[mis].[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным]
    GROUP BY [ОтветственныеПоКредитамВыданным Кредит ID]
),
FinProducts AS (
    SELECT [ФинансовыеПродукты ID] AS FinancialProductID,
           [ФинансовыеПродукты Основная Группа] AS FinancialProductsMainGroup
    FROM [ATK].[mis].[Bronze_Справочники.ФинансовыеПродукты]
),
Statuses AS (
    SELECT *
    FROM (
        SELECT s.[СтатусыКредитовВыданных Кредит ID] AS CreditID,
               s.[СтатусыКредитовВыданных Статус] AS IssuedCreditsStatus,
               ROW_NUMBER() OVER(PARTITION BY s.[СтатусыКредитовВыданных Кредит ID]
                                 ORDER BY s.[СтатусыКредитовВыданных Период] DESC,
                                          s.[СтатусыКредитовВыданных Номер Строки] DESC) AS rn
        FROM [ATK].[mis].[Bronze_РегистрыСведений.СтатусыКредитовВыданных] s
        WHERE s.[СтатусыКредитовВыданных Активность] = 1
    ) t
    WHERE rn = 1
),
LatestOutstanding AS (
    SELECT sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
           sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] AS LatestOutstandingAmount
    FROM [ATK].[mis].[Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] sd
    INNER JOIN (
        SELECT [СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
               MAX([СуммыЗадолженностиПоПериодамПросрочки Дата]) AS MaxDate
        FROM [ATK].[mis].[Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки]
        GROUP BY [СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
    ) md
      ON sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID] = md.CreditID
     AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] = md.MaxDate
),
SegmentRevenue AS (
    SELECT [КредитныеПродукты ID] AS ProductID,
           MAX([КредитныеПродукты Сегмент Доходов]) AS SegmentRevenue
    FROM [ATK].[dbo].[Справочники.КредитныеПродукты]
    WHERE [КредитныеПродукты Сегмент Доходов] IS NOT NULL
    GROUP BY [КредитныеПродукты ID]
),
GreenCredit AS (
    SELECT *
    FROM (
        SELECT gc.[ПротоколКомитета Кредит ID] AS CreditID,
               gc.[ПротоколКомитета Назначение Использования Кредита] AS CommitteeProt_CrPurpose,
               gc.[ПротоколКомитета Категория Риска AML] AS CommitteeProt_AMLRiskCat,
               gc.[ПротоколКомитета Это Зеленый Кредит] AS GreenCredit,
               ROW_NUMBER() OVER(PARTITION BY gc.[ПротоколКомитета Кредит ID]
                                 ORDER BY gc.[ПротоколКомитета Дата] DESC,
                                          gc.[ПротоколКомитета ID] DESC) AS rn
        FROM [ATK].[dbo].[Документы.ПротоколКомитета] gc
    ) t
    WHERE rn = 1
),
-- FirstPartner per Owner integrated here
FirstPartner AS (
    SELECT 
        [Кредиты Владелец] AS Owner,
        MIN([Кредиты Дата Выдачи]) AS FirstIssueDateWithPartner,
        MIN(znk.[ЗаявкаНаКредит Партнер ID]) AS First_PartnerID,
        MIN(znk.[ЗаявкаНаКредит Партнер]) AS First_PartnerName
    FROM [ATK].[mis].[Bronze_Документы.ЗаявкаНаКредит] znk
    INNER JOIN Credits c
        ON c.[Кредиты ID] = znk.[ЗаявкаНаКредит Кредит ID]
    WHERE znk.[ЗаявкаНаКредит Партнер ID] IS NOT NULL
      AND znk.[ЗаявкаНаКредит Партнер ID] <> '00000000000000000000000000000000'
     AND c.[Кредиты Дата Выдачи] IS NOT NULL
     AND c.[Кредиты Дата Выдачи] > '1753-01-01'
    GROUP BY [Кредиты Владелец]
),
ClientPartnerTimeFrames AS (
    SELECT 
        c.[Кредиты ID] AS CreditID,
        -- Only assign First_PartnerID if IssueDate valid and PartnerID is not dummy
        CASE 
            WHEN c.[Кредиты Дата Выдачи] > '1753-01-01' 
                 AND fp.First_PartnerID IS NOT NULL
                 AND fp.First_PartnerID <> '00000000000000000000000000000000'
            THEN fp.First_PartnerID 
            ELSE NULL 
        END AS First_PartnerID,
        CASE 
            WHEN c.[Кредиты Дата Выдачи] > '1753-01-01' 
                 AND fp.First_PartnerName IS NOT NULL
            THEN fp.First_PartnerName 
            ELSE NULL 
        END AS First_PartnerName,
        -- Latest partner for this credit
        pn.PartnerName,
        -- First partner per year
        CASE 
            WHEN c.[Кредиты Дата Выдачи] >= '2023-01-01' 
                 AND znk2023.[ЗаявкаНаКредит Партнер ID] IS NOT NULL
                 AND znk2023.[ЗаявкаНаКредит Партнер ID] <> '00000000000000000000000000000000'
            THEN znk2023.[ЗаявкаНаКредит Партнер ID] 
            ELSE NULL 
        END AS First_PartnerID_2023,
        CASE 
            WHEN c.[Кредиты Дата Выдачи] >= '2024-01-01' 
                 AND znk2024.[ЗаявкаНаКредит Партнер ID] IS NOT NULL
                 AND znk2024.[ЗаявкаНаКредит Партнер ID] <> '00000000000000000000000000000000'
            THEN znk2024.[ЗаявкаНаКредит Партнер ID] 
            ELSE NULL 
        END AS First_PartnerID_2024,
        CASE 
            WHEN c.[Кредиты Дата Выдачи] >= '2025-01-01' 
                 AND znk2025.[ЗаявкаНаКредит Партнер ID] IS NOT NULL
                 AND znk2025.[ЗаявкаНаКредит Партнер ID] <> '00000000000000000000000000000000'
            THEN znk2025.[ЗаявкаНаКредит Партнер ID] 
            ELSE NULL 
        END AS First_PartnerID_2025
    FROM Credits c
    LEFT JOIN FirstPartner fp
        ON c.[Кредиты Владелец] = fp.Owner
    -- Latest partner for this credit
    OUTER APPLY (
        SELECT TOP 1 
            znk.[ЗаявкаНаКредит Партнер] AS PartnerName
        FROM [ATK].[mis].[Bronze_Документы.ЗаявкаНаКредит] znk
        WHERE znk.[ЗаявкаНаКредит Кредит ID] = c.[Кредиты ID]
          AND znk.[ЗаявкаНаКредит Партнер] IS NOT NULL
        ORDER BY znk.[ЗаявкаНаКредит Дата] DESC, znk.[ЗаявкаНаКредит ID] DESC
    ) pn
    -- First partner per year
    OUTER APPLY (
        SELECT TOP 1 *
        FROM [ATK].[mis].[Bronze_Документы.ЗаявкаНаКредит] znk
        WHERE znk.[ЗаявкаНаКредит Кредит ID] = c.[Кредиты ID]
          AND znk.[ЗаявкаНаКредит Дата] >= '2023-01-01'
        ORDER BY znk.[ЗаявкаНаКредит Дата] ASC
    ) znk2023
    OUTER APPLY (
        SELECT TOP 1 *
        FROM [ATK].[mis].[Bronze_Документы.ЗаявкаНаКредит] znk
        WHERE znk.[ЗаявкаНаКредит Кредит ID] = c.[Кредиты ID]
          AND znk.[ЗаявкаНаКредит Дата] >= '2024-01-01'
        ORDER BY znk.[ЗаявкаНаКредит Дата] ASC
    ) znk2024
    OUTER APPLY (
        SELECT TOP 1 *
        FROM [ATK].[mis].[Bronze_Документы.ЗаявкаНаКредит] znk
        WHERE znk.[ЗаявкаНаКредит Кредит ID] = c.[Кредиты ID]
          AND znk.[ЗаявкаНаКредит Дата] >= '2025-01-01'
        ORDER BY znk.[ЗаявкаНаКредит Дата] ASC
    ) znk2025
)
INSERT INTO mis.[2tbl_Gold_Dim_Credits_v3] (
    [CreditID], [Owner], [Code], [Name],
    [IssueDate], [Term], [Amount],
    [EconomicSectorDetailed], [FinancialProductID], [FinancialProduct],
    [AgroCredit], [LocalityType], [Currency], [ProductID],
    [Product], [Purpose], [RemoveFundingSource],
    [ContractType], [ContractDate], [IncomeSegment],
    [UsagePurpose], [PurposeDescription], [ProductType],
    [EconomicUsageArea], [SigningSource], [FinancialProductsMainGroup],
    [IssuedCreditsStatus], [PartnerID],[First_PartnerID],
    [First_PartnerName], [PartnerName],
    [FirstFilialID], [FirstEmployeeID], [LastFilialID], [LastEmployeeID],
    [DealerID], [Source], [LatestOutstandingAmount],
    [SegmentRevenue], [GreenCredit], [CommitteeProt_CrPurpose],
    [CommitteeProt_AMLRiskCat], [DigitalSign],
    [EconomicSectorEFSE], [EconomicSector], [Agro],
    [First_PartnerID_2023], [First_PartnerID_2024], [First_PartnerID_2025]
)
SELECT
    c.[Кредиты ID], c.[Кредиты Владелец], c.[Кредиты Код], c.[Кредиты Наименование],
    c.[Кредиты Дата Выдачи], c.[Кредиты Срок Кредита], c.[Кредиты Сумма Кредита],
    c.[Кредиты Сектор Экономики], c.[Кредиты Финансовый Продукт ID], c.[Кредиты Финансовый Продукт],
    CASE c.[Кредиты Агро]
        WHEN 'Агро' THEN 'AgroCredit'
        WHEN 'НеАгро' THEN 'nonAgro'
        ELSE c.[Кредиты Агро]
    END AS AgroCredit,
    CASE c.[Кредиты Тип Местности]
        WHEN 'ГородБольшой' THEN 'bigCity'
        WHEN 'Пригород' THEN 'suburb'
        WHEN 'Город' THEN 'city'
        ELSE c.[Кредиты Тип Местности]
    END AS LocalityType,
    c.[Кредиты Валюта], c.[Кредиты Кредитный Продукт ID], c.[Кредиты Кредитный Продукт],
    c.[Кредиты Цель Кредита], c.[Кредиты Удалить Источник Финансирования],
    CASE c.[Кредиты Вид Контракта]
        WHEN 'Контракт' THEN 'Contract'
        WHEN 'Приложение' THEN 'App'
        ELSE c.[Кредиты Вид Контракта]
    END AS ContractType,
    c.[Кредиты Дата Контракта], c.[Кредиты Сегмент Доходов], c.[Кредиты Назначение Использования Кредита],
    c.[Кредиты Цель Кредита Описание], c.[Кредиты Тип Кредитного Продукта], c.[Кредиты Сфера Использования Кредита],
    CASE c.[Кредиты Источник Подписания]
        WHEN 'Приложение' THEN 'MobileApp'
        WHEN 'Сайт' THEN 'WebSite'
        ELSE c.[Кредиты Источник Подписания]
    END AS SigningSource,
    fp.FinancialProductsMainGroup,
    CASE st.IssuedCreditsStatus
        WHEN 'Закрыт' THEN 'Closed'
        WHEN 'Выдан' THEN 'Disbursed'
        WHEN 'Списан' THEN 'Written off'
        ELSE st.IssuedCreditsStatus
    END AS IssuedCreditsStatus,
    cr.PartnerID,
    CASE 
        WHEN c.[Кредиты Дата Выдачи] > '1753-01-01'
             AND cr.PartnerID IS NOT NULL
             AND cr.PartnerID <> '00000000000000000000000000000000'
        THEN cp.First_PartnerID 
        ELSE NULL 
    END AS First_PartnerID,
    CASE 
        WHEN c.[Кредиты Дата Выдачи] > '1753-01-01'
             AND cr.PartnerID IS NOT NULL
             AND cr.PartnerID <> '00000000000000000000000000000000'
        THEN cp.First_PartnerName 
        ELSE NULL 
    END AS First_PartnerName,
    cp.PartnerName,
    COALESCE(r.FirstFilialID, cr.FilialID),
    COALESCE(r.FirstEmployeeID, cr.EmployeeID),
    COALESCE(r.LastFilialID, cr.FilialID),
    COALESCE(r.LastEmployeeID, cr.EmployeeID),
    cr.DealerID,
    CASE cr.Source
        WHEN 'Партнер' THEN 'Partners'
        WHEN 'Кассир' THEN 'CCR'
        WHEN 'СотрудникCallCenter' THEN 'CallCenter'
        WHEN 'Сайт' THEN 'WebSite'
        WHEN 'Плагин' THEN 'API'
        WHEN 'МобильноеПриложение' THEN 'MobileApp'
        WHEN 'КредитныйЭксперт' THEN 'Employee'
        WHEN 'Другой' THEN 'Other'
        ELSE cr.Source
    END AS Source,
    lo.LatestOutstandingAmount,
    seg.SegmentRevenue,
    gc.GreenCredit,
    gc.CommitteeProt_CrPurpose,
    CASE gc.CommitteeProt_AMLRiskCat
        WHEN 'Высокий' THEN 'High_Risk'
        WHEN 'Средний' THEN 'Medium_Risk'
        WHEN 'Низкий' THEN 'Low_Risk'
        ELSE gc.CommitteeProt_AMLRiskCat
    END AS CommitteeProt_AMLRiskCat,
    CASE WHEN c.[Кредиты Источник Подписания] IS NOT NULL THEN 'True' ELSE 'False' END AS DigitalSign,
    e.[СекторыЭкономики Сектор Экономики EFSE] AS EconomicSectorEFSE,
    c.[Кредиты Сектор Экономики] AS EconomicSector,
    CASE
        WHEN fp.FinancialProductsMainGroup = 'Business' AND c.[Кредиты Сектор Экономики] = '1. Agricultura'
        THEN 'Agro'
        ELSE 'NonAgro'
    END AS Agro,
    CASE 
        WHEN c.[Кредиты Дата Выдачи] > '1753-01-01'
             AND cr.PartnerID IS NOT NULL
             AND cr.PartnerID <> '00000000000000000000000000000000'
        THEN cp.First_PartnerID_2023 
        ELSE NULL
    END AS First_PartnerID_2023,
    CASE 
        WHEN c.[Кредиты Дата Выдачи] > '1753-01-01'
             AND cr.PartnerID IS NOT NULL
             AND cr.PartnerID <> '00000000000000000000000000000000'
        THEN cp.First_PartnerID_2024 
        ELSE NULL
    END AS First_PartnerID_2024,
    CASE 
        WHEN c.[Кредиты Дата Выдачи] > '1753-01-01'
             AND cr.PartnerID IS NOT NULL
             AND cr.PartnerID <> '00000000000000000000000000000000'
        THEN cp.First_PartnerID_2025 
        ELSE NULL
    END AS First_PartnerID_2025
FROM Credits c
LEFT JOIN CreditRequest cr ON c.[Кредиты ID] = cr.CreditID
LEFT JOIN Resp r ON c.[Кредиты ID] = r.CreditID
LEFT JOIN FinProducts fp ON c.[Кредиты Финансовый Продукт ID] = fp.FinancialProductID
LEFT JOIN Statuses st ON c.[Кредиты ID] = st.CreditID
LEFT JOIN LatestOutstanding lo ON c.[Кредиты ID] = lo.CreditID
LEFT JOIN SegmentRevenue seg ON c.[Кредиты Кредитный Продукт ID] = seg.ProductID
LEFT JOIN GreenCredit gc ON c.[Кредиты ID] = gc.CreditID
LEFT JOIN ClientPartnerTimeFrames cp ON c.[Кредиты ID] = cp.CreditID
LEFT JOIN [ATK].[dbo].[Справочники.СекторыЭкономики] AS e ON c.[Кредиты Сектор Экономики ID] = e.[СекторыЭкономики ID]
WHERE c.[Кредиты Владелец] = '80D300155D010F0111E6BD2A754DD3BA';






