USE [ATK];
GO

IF OBJECT_ID(N'mis.[Gold_Dim_Credits]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_Credits];
GO

CREATE TABLE mis.[Gold_Dim_Credits] 
(
    [CreditID] VARCHAR(36) NOT NULL PRIMARY KEY CLUSTERED,
    [Owner] NVARCHAR(100) NULL,
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
    [CreditApplicationPartnerID] VARCHAR(36) NULL,
    [CreditPartnerName] NVARCHAR(255) NULL,
    [FirstFilialID] VARCHAR(36) NULL,
    [FirstEmployeeID] VARCHAR(36) NULL,
    [LastFilialID] VARCHAR(36) NULL,
    [LastEmployeeID] VARCHAR(36) NULL,
    [DealerID] VARCHAR(36) NULL,
    [Source] NVARCHAR(50) NULL,
    [LatestOutstandingAmount] DECIMAL(18,2) NULL,
	[SegmentRevenue] NVARCHAR(50) NULL,
    [GreenCredit] VARCHAR(36) NULL,
    [CommitteeProt_CrPurpose] NVARCHAR(150) NULL,
    [CommitteeProt_AMLRiskCat] NVARCHAR(256) NULL,
    [DigitalSign] NVARCHAR(50) NULL,
    [EconomicSectorEFSE] NVARCHAR(255) NULL,
    [EconomicSector] NVARCHAR(255) NULL,
    [Agro] NVARCHAR(50) NULL,
    [IsFormal] NVARCHAR(50) NULL
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
            znk.[ЗаявкаНаКредит Партнер ID] AS ApplicationPartnerID,
            oia.[ОбъединеннаяИнтернетЗаявка Дилер ID] AS DealerID,
            NULLIF(LTRIM(RTRIM(oia.[ОбъединеннаяИнтернетЗаявка Источник Заполнения])), '') AS Source,
            oia.[ОбъединеннаяИнтернетЗаявка Филиал ID] AS FilialID,
            oia.[ОбъединеннаяИнтернетЗаявка Кредитный Эксперт ID] AS EmployeeID,
            oia.[ОбъединеннаяИнтернетЗаявка ID] AS OIA_ID,
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
-- Segment revenue
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
			   gc.[ПротоколКомитета Партнер] AS CommitteePartner,
               ROW_NUMBER() OVER(PARTITION BY gc.[ПротоколКомитета Кредит ID]
                                 ORDER BY gc.[ПротоколКомитета Дата] ASC,
                                          gc.[ПротоколКомитета ID] ASC) AS rn
        FROM [ATK].[dbo].[Документы.ПротоколКомитета] gc
    ) t
    WHERE rn = 1
),
ClientPartner AS (
    SELECT 
        c.[Кредиты ID] AS CreditID,
        cpLatest.CreditPartnerName
    FROM Credits c
    OUTER APPLY (
        SELECT TOP 1
            CASE 
                WHEN c.[Кредиты Дата Выдачи] = '1753-01-01' THEN NULL
                ELSE znk.[ЗаявкаНаКредит Партнер]
            END AS CreditPartnerName
        FROM [ATK].[mis].[Bronze_Документы.ЗаявкаНаКредит] znk
        WHERE znk.[ЗаявкаНаКредит Кредит ID] = c.[Кредиты ID]
        ORDER BY znk.[ЗаявкаНаКредит Дата] DESC, znk.[ЗаявкаНаКредит ID] DESC
    ) cpLatest
),
DigitalSignSrc AS (
    SELECT
        [НаправлениеНаВыплату Кредит ID] AS CreditID,
        CASE WHEN NULLIF(LTRIM(RTRIM([НаправлениеНаВыплату Источник Заполнения])), '') IS NOT NULL
             THEN 1 ELSE 0 END AS HasPaymentDirectionSource
    FROM mis.[Bronze_Документы.НаправлениеНаВыплату]
),
FormalCredits AS (
    SELECT DISTINCT c.[Кредиты ID] AS CreditID
    FROM Credits c
    INNER JOIN [ATK].[mis].[Bronze_Документы.ЗаявкаНаКредит] znk
        ON znk.[ЗаявкаНаКредит Кредит ID] = c.[Кредиты ID]
    INNER JOIN [ATK].[mis].[Bronze_Документы.ОбъединеннаяИнтернетЗаявка] oia
        ON oia.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID] = znk.[ЗаявкаНаКредит ID]
    INNER JOIN [ATK].[dbo].[Документы.ОбъединеннаяИнтернетЗаявка.РискФакторы] rf
        ON rf.[ОбъединеннаяИнтернетЗаявка ID] = oia.[ОбъединеннаяИнтернетЗаявка ID]
       AND rf.[ОбъединеннаяИнтернетЗаявка.РискФакторы Риск Фактор ID] IN (
              'B74000155D65140C11EDEA76A63D59BC',
              '9DCB83734038510A448E495536F415C8',
              '810500155D65040111EC119B4AF60D86'
          )
    WHERE rf.[ОбъединеннаяИнтернетЗаявка.РискФакторы Выбран] = '01'
),
FinalData AS (
    SELECT
        crd.[Кредиты ID] AS CreditID,
        crd.[Кредиты Владелец] AS Owner,
        crd.[Кредиты Код] AS Code,
        crd.[Кредиты Наименование] AS Name,
        crd.[Кредиты Дата Выдачи] AS IssueDate,
        crd.[Кредиты Срок Кредита] AS Term,
        crd.[Кредиты Сумма Кредита] AS Amount,
        crd.[Кредиты Сектор Экономики] AS EconomicSectorDetailed,
        crd.[Кредиты Финансовый Продукт ID] AS FinancialProductID,
        crd.[Кредиты Финансовый Продукт] AS FinancialProduct,
        CASE crd.[Кредиты Агро]
            WHEN 'Агро' THEN 'AgroCredit'
            WHEN 'НеАгро' THEN 'nonAgro'
            ELSE crd.[Кредиты Агро]
        END AS AgroCredit,
        CASE crd.[Кредиты Тип Местности]
            WHEN 'ГородБольшой' THEN 'bigCity'
            WHEN 'Пригород' THEN 'suburb'
            WHEN 'Город' THEN 'city'
            ELSE crd.[Кредиты Тип Местности]
        END AS LocalityType,
        crd.[Кредиты Валюта] AS Currency,
        crd.[Кредиты Кредитный Продукт ID] AS ProductID,
        crd.[Кредиты Кредитный Продукт] AS Product,
        crd.[Кредиты Цель Кредита] AS Purpose,
        crd.[Кредиты Удалить Источник Финансирования] AS RemoveFundingSource,
        CASE crd.[Кредиты Вид Контракта]
            WHEN 'Контракт' THEN 'Contract'
            WHEN 'Приложение' THEN 'App'
            ELSE crd.[Кредиты Вид Контракта]
        END AS ContractType,
        crd.[Кредиты Дата Контракта] AS ContractDate,
        crd.[Кредиты Сегмент Доходов] AS IncomeSegment,
        crd.[Кредиты Назначение Использования Кредита] AS UsagePurpose,
        crd.[Кредиты Цель Кредита Описание] AS PurposeDescription,
        crd.[Кредиты Тип Кредитного Продукта] AS ProductType,
        crd.[Кредиты Сфера Использования Кредита] AS EconomicUsageArea,
        CASE crd.[Кредиты Источник Подписания]
            WHEN 'Приложение' THEN 'MobileApp'
            WHEN 'Сайт' THEN 'WebSite'
            ELSE crd.[Кредиты Источник Подписания]
        END AS SigningSource,
        fp.FinancialProductsMainGroup,
        CASE st.IssuedCreditsStatus
            WHEN 'Закрыт' THEN 'Closed'
            WHEN 'Выдан' THEN 'Disbursed'
            WHEN 'Списан' THEN 'Written off'
            ELSE st.IssuedCreditsStatus
        END AS IssuedCreditsStatus,
        cr.ApplicationPartnerID AS CreditApplicationPartnerID,
        COALESCE(cp.CreditPartnerName, gc.CommitteePartner) AS CreditPartnerName, 
        COALESCE(resp.FirstFilialID, cr.FilialID) AS FirstFilialID,
        COALESCE(resp.FirstEmployeeID, cr.EmployeeID) AS FirstEmployeeID,
        COALESCE(resp.LastFilialID, cr.FilialID) AS LastFilialID,
        COALESCE(resp.LastEmployeeID, cr.EmployeeID) AS LastEmployeeID,
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
        CASE
            WHEN gc.CommitteeProt_AMLRiskCat = 'Высокий' THEN 'High_Risk'
            WHEN gc.CommitteeProt_AMLRiskCat = 'Средний' THEN 'Medium_Risk'
            WHEN gc.CommitteeProt_AMLRiskCat = 'Низкий' THEN 'Low_Risk'
            ELSE gc.CommitteeProt_AMLRiskCat
        END AS CommitteeProt_AMLRiskCat,
        CASE
            WHEN ds.HasPaymentDirectionSource = 1 THEN 'True'
            ELSE 'False'
        END AS DigitalSign,
		e.[СекторыЭкономики Сектор Экономики EFSE] AS EconomicSectorEFSE,
        e.[СекторыЭкономики Основной Раздел] AS EconomicSector,
        CASE
            WHEN fp.FinancialProductsMainGroup = 'Business' AND e.[СекторыЭкономики Основной Раздел] = '1. Agricultura'
            THEN 'Agro'
            ELSE 'NonAgro'
        END AS Agro,
        CASE WHEN fc.CreditID IS NOT NULL THEN 'Formal'
             ELSE 'Non-Formal'
        END AS IsFormal
    FROM Credits crd
    LEFT JOIN CreditRequest cr ON crd.[Кредиты ID] = cr.CreditID
    LEFT JOIN Resp resp ON crd.[Кредиты ID] = resp.CreditID
    LEFT JOIN FinProducts fp ON crd.[Кредиты Финансовый Продукт ID] = fp.FinancialProductID
    LEFT JOIN Statuses st ON crd.[Кредиты ID] = st.CreditID
    LEFT JOIN LatestOutstanding lo ON crd.[Кредиты ID] = lo.CreditID
	LEFT JOIN SegmentRevenue seg ON crd.[Кредиты Кредитный Продукт ID] = seg.ProductID
    LEFT JOIN GreenCredit gc ON crd.[Кредиты ID] = gc.CreditID
    LEFT JOIN ClientPartner cp ON crd.[Кредиты ID] = cp.CreditID
	LEFT JOIN [ATK].[dbo].[Справочники.СекторыЭкономики] e 
        ON crd.[Кредиты Сектор Экономики ID] = e.[СекторыЭкономики ID]
    LEFT JOIN DigitalSignSrc ds ON crd.[Кредиты ID] = ds.CreditID
    LEFT JOIN FormalCredits fc ON crd.[Кредиты ID] = fc.CreditID
)

INSERT INTO mis.[Gold_Dim_Credits] (
    CreditID, Owner, Code, Name, IssueDate, Term, Amount, EconomicSectorDetailed,
    FinancialProductID, FinancialProduct, AgroCredit, LocalityType, Currency,
    ProductID, Product, Purpose, RemoveFundingSource, ContractType, ContractDate,
    IncomeSegment, UsagePurpose, PurposeDescription, ProductType, EconomicUsageArea,
    SigningSource, FinancialProductsMainGroup, IssuedCreditsStatus,
    CreditApplicationPartnerID, CreditPartnerName, FirstFilialID, FirstEmployeeID,
    LastFilialID, LastEmployeeID, DealerID, Source, LatestOutstandingAmount, SegmentRevenue,
    GreenCredit, CommitteeProt_CrPurpose, CommitteeProt_AMLRiskCat,
    DigitalSign, EconomicSectorEFSE, EconomicSector, Agro, IsFormal
)
SELECT *
FROM FinalData
;
GO