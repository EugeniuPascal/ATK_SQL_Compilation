USE [ATK];
GO

-- Drop table if exists
IF OBJECT_ID(N'mis.[2tbl_Gold_Dim_Credits]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_Credits];
GO

-- Create table with DigitalSign column
CREATE TABLE mis.[2tbl_Gold_Dim_Credits] (
    [CreditID] VARCHAR(36) NOT NULL PRIMARY KEY CLUSTERED,
    [Owner] NVARCHAR(100) NULL,
    [Code] NVARCHAR(50) NULL,
    [Name] NVARCHAR(255) NULL,
    [IssueDate] DATE NULL,
    [Term] INT NULL,
    [Amount] DECIMAL(18,2) NULL,
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
    [PurposeDescription] NVARCHAR(1000) NULL,
    [ProductType] NVARCHAR(255) NULL,
    [UsageArea] NVARCHAR(255) NULL,
    [SigningSource] NVARCHAR(500) NULL,
    [FinancialProductsMainGroup] NVARCHAR(255) NULL,
    [IssuedCreditsStatus] NVARCHAR(50) NULL,
    [CreditApplicationPartnerID] VARCHAR(36) NULL,
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
    [DigitalSign] NVARCHAR(50) NULL
);
GO

WITH
-- Latest credit per CreditID
Credits AS (
    SELECT *
    FROM (
        SELECT *,
               ROW_NUMBER() OVER(PARTITION BY [Кредиты ID] ORDER BY [Кредиты Дата Выдачи] DESC, [Кредиты Код]) AS rn
        FROM [ATK].[mis].[Silver_Справочники.Кредиты]
    ) t
    WHERE rn = 1
),
-- Latest OIA row per Application (collapse multiple OIA rows to one per application)
OIA_LatestPerApp AS (
    SELECT *
    FROM (
        SELECT oia.*,
               ROW_NUMBER() OVER (
                   PARTITION BY oia.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
                   ORDER BY oia.[ОбъединеннаяИнтернетЗаявка Дата] DESC,
                            oia.[ОбъединеннаяИнтернетЗаявка ID] DESC
               ) AS rn
        FROM [ATK].[mis].[Silver_Документы.ОбъединеннаяИнтернетЗаявка] oia
    ) t
    WHERE rn = 1
),
-- Latest credit request per CreditID (take latest Source via joined latest-per-application rows)
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
            ROW_NUMBER() OVER (
                PARTITION BY znk.[ЗаявкаНаКредит Кредит ID]
                ORDER BY oia.[ОбъединеннаяИнтернетЗаявка Дата] DESC,
                         oia.[ОбъединеннаяИнтернетЗаявка ID] DESC
            ) AS rn
        FROM [ATK].[mis].[Silver_Документы.ЗаявкаНаКредит] znk
        LEFT JOIN OIA_LatestPerApp oia
           ON znk.[ЗаявкаНаКредит ID] = oia.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
    ) t
    WHERE rn = 1
),
-- First/Last Responsible
Resp AS (
    SELECT
        [ОтветственныеПоКредитамВыданным Кредит ID] AS CreditID,
        MIN([ОтветственныеПоКредитамВыданным Филиал ID]) AS FirstFilialID,
        MIN([ОтветственныеПоКредитамВыданным Кредитный Эксперт ID]) AS FirstEmployeeID,
        MAX([ОтветственныеПоКредитамВыданным Филиал ID]) AS LastFilialID,
        MAX([ОтветственныеПоКредитамВыданным Кредитный Эксперт ID]) AS LastEmployeeID
    FROM [ATK].[mis].[Silver_РегистрыСведений.ОтветственныеПоКредитамВыданным]
    GROUP BY [ОтветственныеПоКредитамВыданным Кредит ID]
),
-- Financial products main group
FinProducts AS (
    SELECT [ФинансовыеПродукты ID] AS FinancialProductID,
           [ФинансовыеПродукты Основная Группа] AS FinancialProductsMainGroup
    FROM [ATK].[mis].[Silver_Справочники.ФинансовыеПродукты]
),
-- Latest credit status
Statuses AS (
    SELECT *
    FROM (
        SELECT s.[СтатусыКредитовВыданных Кредит ID] AS CreditID,
               s.[СтатусыКредитовВыданных Статус] AS IssuedCreditsStatus,
               ROW_NUMBER() OVER(PARTITION BY s.[СтатусыКредитовВыданных Кредит ID]
                                 ORDER BY s.[СтатусыКредитовВыданных Период] DESC,
                                          s.[СтатусыКредитовВыданных Номер Строки] DESC) AS rn
        FROM [ATK].[mis].[Silver_РегистрыСведений.СтатусыКредитовВыданных] s
        WHERE s.[СтатусыКредитовВыданных Активность] = 1
    ) t
    WHERE rn = 1
),
-- Latest outstanding per credit
LatestOutstanding AS (
    SELECT sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
           sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] AS LatestOutstandingAmount
    FROM [ATK].[mis].[Silver_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] sd
    INNER JOIN (
        SELECT [СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
               MAX([СуммыЗадолженностиПоПериодамПросрочки Дата]) AS MaxDate
        FROM [ATK].[mis].[Silver_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки]
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
-- Committee info / Green Credit
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
)
-- Final insert
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
    [CreditApplicationPartnerID], [FirstFilialID], [FirstEmployeeID],
    [LastFilialID], [LastEmployeeID], [DealerID], [Source],
    [LatestOutstandingAmount], [SegmentRevenue], [GreenCredit],
    [CommitteeProt_CrPurpose], [CommitteeProt_AMLRiskCat],
    [DigitalSign] 
)
SELECT
    c.[Кредиты ID], c.[Кредиты Владелец], c.[Кредиты Код], c.[Кредиты Наименование],
    c.[Кредиты Дата Выдачи], c.[Кредиты Срок Кредита], c.[Кредиты Сумма Кредита],
    c.[Кредиты Сектор Экономики], c.[Кредиты Финансовый Продукт ID], 
	c.[Кредиты Финансовый Продукт],
	/*CASE c.[Кредиты Финансовый Продукт]
	     WHEN 'Credite auto denominate in Euro' THEN 'Auto Loans EUR'
         WHEN 'Credite ipotecare MDL' THEN 'Mortgage MDL'
         WHEN 'Credite auto denominate in moneda nationala' THEN 'Auto Loans Local'
         WHEN 'Credite ipotecare USD' THEN 'Mortgage USD'
         WHEN 'Creditare directa denominata in moneda Euro' THEN 'Direct Lending EUR'
         WHEN 'Credite pentru conditii de trai denominate in Euro' THEN 'Living Condition Loans EUR'
         WHEN 'Creditare directa denominata in moneda USD' THEN 'Direct Lending USD'
         WHEN 'Creditare directa denominata in moneda nationala' THEN 'Direct Lending Local'
         WHEN 'Creditarea in parteneriat cu comerciantii' THEN 'Partner Lending'
         WHEN 'Creditare auto' THEN 'Auto Loans'
         WHEN 'Credite studii  denominate in moneda nationala' THEN 'Study Loans Local'
         WHEN 'Credite calatorii  denominate in Eur' THEN 'Travel Loans EUR'
         WHEN 'Garantii financiare' THEN 'Financial Guarantees'
         WHEN 'Credite HIL denominate in moneda nationala' THEN 'HIL Loans Local'
         WHEN 'Credite  istorice in valuta ( pina la 23.05.2008)' THEN 'Historical Loans'
         WHEN 'Credite pentru conditii de trai denominate in moneda nationala' THEN 'Living Condition Loans Local'
         WHEN 'Credite Consumer Non-Business denominate in moneda nationala' THEN 'Consumer Loans Non-Business'
         WHEN 'Credite ipotecare EUR' THEN 'Mortgage EUR'
         WHEN 'Capital de risc' THEN 'Venture Capital'
         WHEN 'Credite work&travel denominate in moneda nationala' THEN 'Work&Travel Loans Local'
         WHEN 'Credite HIL denominate in Euro' THEN 'HIL Loans EUR'
         WHEN 'Credite work&travel denominate in USD' THEN 'Work&Travel Loans USD'
         WHEN 'Credite angajati' THEN 'Employee Loans'
         WHEN 'Creditare Asociatie' THEN 'Association Lending'
         WHEN 'Credite calatorii  denominate in moneda nationala' THEN 'Travel Loans Local'
         WHEN 'Credite pentru conditii de trai denominate in USD' THEN 'Living Condition Loans USD'
         WHEN 'Creditare in grup' THEN 'Group Lending'
         WHEN 'Credite auto denominate in USD' THEN 'Auto Loans USD'
		 ELSE  c.[Кредиты Финансовый Продукт]
	END AS FinancialProduct,*/
    CASE c.[Кредиты Агро]
	     WHEN 'Агро' THEN 'Agro'
         WHEN 'НеАгро' THEN 'nonAgro'
		 ELSE c.[Кредиты Агро]
	END AS Agro, 
	CASE c.[Кредиты Тип Местности]
	     WHEN 'ГородБольшой' THEN 'bigCity'
         WHEN 'Пригород' THEN 'suburb'
	     WHEN 'Город' THEN 'city'
		 ELSE c.[Кредиты Тип Местности]
	END AS LocalityType,
    c.[Кредиты Валюта],	
	/*CASE c.[Кредиты Валюта]
	     WHEN 'Lei' THEN 'MDL'
		 ELSE c.[Кредиты Валюта]
	END AS Currency,*/
	c.[Кредиты Кредитный Продукт ID],
    c.[Кредиты Кредитный Продукт],
    c.[Кредиты Цель Кредита],	
	/*CASE c.[Кредиты Цель Кредита]
	     WHEN 'Altele pentru activitate de antreprenoriat/profesională' THEN 'Other Prof. Activity'
         WHEN 'Afacere Mijloace fixe' THEN 'Business Fixed Assets'
         WHEN 'Tratament' THEN 'Treatment'
         WHEN 'Procurare Imobil (teren sau constructii)' THEN 'Real Estate'
         WHEN 'Altele' THEN 'Other'
         WHEN 'Vacanta' THEN 'Vacation'
         WHEN 'Refinantarea creditelor alte comp/p.f.' THEN 'Loan Refinancing'
         WHEN 'Mixt cu Refinantare' THEN 'Mixed w/ Refinancing'
         WHEN 'Mijloace fixe' THEN 'Fixed Assets'
         WHEN 'Mixt' THEN 'Mixed'
         WHEN 'Formare /rambursare împrumut față de fondator' THEN 'Loan to Founder'
         WHEN 'Refinantare MI' THEN 'MI Refinancing'
         WHEN 'Materiale de Constructie (reparatii, renovări si reconstructii)' THEN 'Construction Mat.'
         WHEN 'Refinantare institutilor terte (si altele) prin viramente' THEN '3rd Party Refin.'
         WHEN 'Autoturism' THEN 'Car'
         WHEN 'Mixt Mijloace Circulante' THEN 'Mixed Current Assets'
         WHEN 'Mobilier (categoria medie)' THEN 'Furniture'
         WHEN 'Echipament pt Gospodarie' THEN 'Household Equip.'
         WHEN 'Mediere' THEN 'Mediation'
         WHEN 'Conditii de trai' THEN 'Living Cond.'
         WHEN 'Alte imbunatatiri ale conditiilor de trai' THEN 'Living Improvements'
         WHEN 'Formare /rambursare împrumut față de fondator / PF' THEN 'Loan to Founder/Ind.'
         WHEN 'Mixt retroactive' THEN 'Retroactive Mixed'
         WHEN 'Studii' THEN 'Studies'
         WHEN 'Gadgeturi' THEN 'Gadgets'
         WHEN 'Mixt cu Refinantare MI' THEN 'Mixed w/ MI Refin.'
         WHEN 'Fix retroactive' THEN 'Retroactive Fixed'
         WHEN 'Sisteme de Incalzire,conditionare, apa Canalizare' THEN 'HVAC & Water'
         WHEN 'Ceremonii/ Eveniment organizat' THEN 'Event / Ceremony'
         WHEN 'Mijloace circulante' THEN 'Current Assets'
         WHEN 'Electrocasnice (Echipament si sisteme electrice)' THEN 'Appliances'
         WHEN 'Nevoi personale' THEN 'Personal Needs'
         WHEN 'Finantare retail' THEN 'Retail Financing'
         WHEN 'Afacere Mijloace circulante' THEN 'Business Curr. Assets'
         WHEN 'Mixt cu refinantare prin compensare' THEN 'Mixed Offset Refin.'
         WHEN 'Necesitati curente' THEN 'Current Necessities'
         WHEN 'Necesitati personale' THEN 'Personal Necessities'
         WHEN 'Mixt cu esalonare/preluare' THEN 'Mixed Installments'
		 ELSE c.[Кредиты Цель Кредита]
	END AS Purpose,*/
	c.[Кредиты Удалить Источник Финансирования],
    CASE c.[Кредиты Вид Контракта]
	     WHEN 'Контракт' THEN 'Contract'
		 WHEN 'Приложение' THEN 'App'
		 ELSE c.[Кредиты Вид Контракта]
	END AS ContractType, 
	c.[Кредиты Дата Контракта],
    c.[Кредиты Сегмент Доходов],	
/*CASE c.[Кредиты Сегмент Доходов]
         WHEN 'Business Rapid MDL' THEN 'Business Rapid MDL'
         WHEN 'Consum & HAI' THEN 'Consumer & HAI'
         WHEN 'Retail fără comisioane' THEN 'Retail No Fees'
         WHEN 'Altele' THEN 'Other'
         WHEN 'FX Consum & HAI' THEN 'FX Consumer & HAI'
         WHEN 'FX Creditare Auto' THEN 'FX Auto Loan'
         WHEN 'Linia de credit retail' THEN 'Retail Credit Line'
         WHEN 'Retail Standart 2/4%' THEN 'Retail Standard 2/4%'
         WHEN 'Retail Standart' THEN 'Retail Standard'
         WHEN 'HIL clienti business' THEN 'HIL Business Clients'
         WHEN 'Retail standard 5/9%' THEN 'Retail Standard 5/9%'
         WHEN 'HIL cu gaj clienti business' THEN 'HIL Pledged Business'
         WHEN 'FX Business Oferta Afaceri' THEN 'FX Business Offer'
         WHEN 'Creditare Auto' THEN 'Auto Loan'
         WHEN 'HIL' THEN 'HIL'
         WHEN 'Consum clienti business' THEN 'Business Consumer'
         WHEN 'Retail Mixt' THEN 'Retail Mixed'
         WHEN 'Business Creditare Directă' THEN 'Business Direct Loan'
         WHEN 'Ipoteca FX' THEN 'FX Mortgage'
         WHEN 'Ipoteca' THEN 'Mortgage'
         WHEN 'FX Business Partners' THEN 'FX Business Partners'
         WHEN 'Mediere' THEN 'Mediation'
         WHEN 'Retail Gratie Comision' THEN 'Retail Comision Free'
         WHEN 'B2B Partners EUR' THEN 'B2B Partners EUR'
         WHEN 'Retail 0%' THEN 'Retail 0%'
         WHEN 'B2B Partners MDL' THEN 'B2B Partners MDL'
         WHEN 'Business partners' THEN 'Business Partners'
         WHEN 'HIL FX clienti business' THEN 'HIL FX Business'
         WHEN 'Online Cash' THEN 'Online Cash'
         WHEN 'Consum FX clienti business' THEN 'FX Consumer Business'
         WHEN 'Business Rapid EUR' THEN 'Business Rapid EUR'
         WHEN 'Retail Double' THEN 'Retail Double'
         WHEN 'HIL cu gaj' THEN 'HIL Pledged'
         WHEN 'Consum non-business' THEN 'Non-Business Consumer'
         WHEN 'FX Business Creditare Directă' THEN 'FX Business Direct Loan'
         ELSE c.[Кредиты Сегмент Доходов]
    END AS IncomeSegment,*/
	c.[Кредиты Назначение Использования Кредита],
    /*CASE c.[Кредиты Назначение Использования Кредита]
		 WHEN 'Antreprenor' THEN 'Bussines'
		 WHEN 'Necesitati personale' THEN 'Personal Needs'
		 ELSE c.[Кредиты Назначение Использования Кредита]
	END AS UsagePurpose,*/	 	
	c.[Кредиты Цель Кредита Описание],
	c.[Кредиты Тип Кредитного Продукта],
    /*CASE c.[Кредиты Тип Кредитного Продукта]
	     WHEN 'Dezvoltarea afacerii' THEN 'Business Development'
         WHEN 'Credit prin partener' THEN 'Partner Loan'
         WHEN 'Procurare imobil' THEN 'Property Purchase'
         WHEN 'Credit' THEN 'Loan'
         WHEN 'Procurare automobil' THEN 'Car Purchase'
         WHEN 'Linia de credit' THEN 'Credit Line'
         WHEN 'Necesitati curente' THEN 'Current Needs'
		 ELSE c.[Кредиты Тип Кредитного Продукта]
	END AS ProductType,*/ 
    c.[Кредиты Сфера Использования Кредита],
	/*CASE c.[Кредиты Сфера Использования Кредита]
         WHEN 'Constructiile' THEN 'Construction'
         WHEN 'Altele' THEN 'Other'
         WHEN 'Comert' THEN 'Trade'
         WHEN 'Prestarea serviciilor' THEN 'Services'
         WHEN 'Transport si Telecomunicatii' THEN 'Transport & Telecom'
         WHEN 'Agricultura' THEN 'Agriculture'
         WHEN 'Ipoteca' THEN 'Mortgage'
         WHEN 'Industria alimentara' THEN 'Food Industry'
         WHEN 'Consum' THEN 'Consumption'
         WHEN 'Antreprenori' THEN 'Entrepreneurs'
         WHEN 'Industria energetica' THEN 'Energy Industry'
         WHEN 'Producere' THEN 'Manufacturing'
		 ELSE c.[Кредиты Сфера Использования Кредита]
	END AS UsageArea,*/
	CASE c.[Кредиты Источник Подписания]
	     WHEN 'Приложение' THEN 'MobileApp'
		 WHEN 'Сайт' THEN 'WebSite'
		 ELSE c.[Кредиты Источник Подписания]
	END AS SigningSource,
	fp.FinancialProductsMainGroup,
    /*CASE fp.FinancialProductsMainGroup
	     WHEN 'Creditare Retail' THEN 'Retail Credit'
		 WHEN 'Mediere' THEN 'Mediation'
		 WHEN 'REPLACE Credite istorice' THEN 'Replace Historical Credits'
         WHEN 'Restructurare' THEN 'Restructuring'
		 ELSE fp.FinancialProductsMainGroup
	END AS FinancialProductsMainGroup,*/
    CASE st.IssuedCreditsStatus
	     WHEN 'Закрыт' THEN 'Closed'
		 WHEN 'Выдан' THEN 'Disbursed'
		 WHEN 'Списан' THEN 'Written off'
	     ELSE st.IssuedCreditsStatus
	END AS IssuedCreditsStatus,
    cr.ApplicationPartnerID,
    COALESCE(r.FirstFilialID, cr.FilialID),
    COALESCE(r.FirstEmployeeID, cr.EmployeeID),
    COALESCE(r.LastFilialID, cr.FilialID),
    COALESCE(r.LastEmployeeID, cr.EmployeeID),
    cr.DealerID,
    CASE cr.Source
         WHEN 'Партнер' THEN 'Parteners'
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
    /*CASE seg.SegmentRevenue
	     WHEN 'Business Rapid MDL' THEN 'Biz Rapid MDL'
         WHEN 'Consum & HAI' THEN 'Cons & HAI'
         WHEN 'Retail fără comisioane' THEN 'Retail No Fee'
         WHEN 'Altele' THEN 'Other'
         WHEN 'FX Consum & HAI' THEN 'FX Cons & HAI'
         WHEN 'FX Creditare Auto' THEN 'FX Auto Credit'
         WHEN 'Linia de credit retail' THEN 'Retail Credit Line'
         WHEN 'Retail Standart 2/4%' THEN 'Retail Std 2/4%'
         WHEN 'Retail Standart' THEN 'Retail Std'
         WHEN 'HIL clienti business' THEN 'HIL Biz Clients'
         WHEN 'Retail standard 5/9%' THEN 'Retail Std 5/9%'
         WHEN 'HIL cu gaj clienti business' THEN 'HIL Secured Biz Clients'
         WHEN 'FX Business Oferta Afaceri' THEN 'FX Biz Offer'
         WHEN 'HIL' THEN 'HIL'
         WHEN 'Creditare Auto' THEN 'Auto Credit'
         WHEN 'Consum clienti business' THEN 'Cons Biz Clients'
         WHEN 'Retail Mixt' THEN 'Retail Mixed'
         WHEN 'Business Creditare Directă' THEN 'Biz Direct Credit'
         WHEN 'Ipoteca FX' THEN 'FX Mortgage'
         WHEN 'Business Oferta Specială Agro' THEN 'Biz Agro Special Offer'
         WHEN 'Ipoteca' THEN 'Mortgage'
         WHEN 'FX Business Partners' THEN 'FX Biz Partners'
         WHEN 'Mediere' THEN 'Mediation'
         WHEN 'Retail Gratie Comision' THEN 'Retail Fee Waived'
         WHEN 'B2B Partners EUR' THEN 'B2B Partners EUR'
         WHEN 'Retail 0%' THEN 'Retail 0%'
         WHEN 'B2B Partners MDL' THEN 'B2B Partners MDL'
         WHEN 'Business partners' THEN 'Biz Partners'
         WHEN 'HIL FX clienti business' THEN 'HIL FX Biz Clients'
         WHEN 'Online Cash' THEN 'Online Cash'
         WHEN 'Consum FX clienti business' THEN 'Cons FX Biz Clients'
         WHEN 'Business Rapid EUR' THEN 'Biz Rapid EUR'
         WHEN 'Retail Double' THEN 'Retail Double'
         WHEN 'HIL cu gaj' THEN 'HIL Secured'
         WHEN 'Consum non-business' THEN 'Cons Non-Biz'
         WHEN 'FX Business Creditare Directă' THEN 'FX Biz Direct Credit'
		 ELSE seg.SegmentRevenue
	END AS SegmentRevenue ,*/
    gc.GreenCredit,
    gc.CommitteeProt_CrPurpose,	
	/*CASE gc.CommitteeProt_CrPurpose
		 WHEN 'Antreprenor' THEN 'Bussines'
		 WHEN 'Necesitati personale' THEN 'Personal Needs'
         ELSE  gc.CommitteeProt_CrPurpose
    END AS CommitteeProt_CrPurpose,*/ 
	CASE gc.CommitteeProt_AMLRiskCat
	   WHEN 'Высокий' THEN 'High_Risk'
       WHEN 'Средний' THEN 'Medium_Risk'
       WHEN 'Низкий' THEN 'Low_Risk'
	   ELSE  gc.CommitteeProt_AMLRiskCat
	END AS CommitteeProt_AMLRiskCat,
    CASE WHEN c.[Кредиты Источник Подписания] IS NOT NULL 
	     THEN 'True' 
		 ELSE 'False' 
    END AS DigitalSign
FROM Credits c
LEFT JOIN CreditRequest cr ON c.[Кредиты ID] = cr.CreditID
LEFT JOIN Resp r ON c.[Кредиты ID] = r.CreditID
LEFT JOIN FinProducts fp ON c.[Кредиты Финансовый Продукт ID] = fp.FinancialProductID
LEFT JOIN Statuses st ON c.[Кредиты ID] = st.CreditID
LEFT JOIN LatestOutstanding lo ON c.[Кредиты ID] = lo.CreditID
LEFT JOIN SegmentRevenue seg ON c.[Кредиты Кредитный Продукт ID] = seg.ProductID
LEFT JOIN GreenCredit gc ON c.[Кредиты ID] = gc.CreditID;
GO