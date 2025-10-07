-- Compiled SQL bundle
-- Generated: 2025-10-07 12:45:37
-- Source folder: C:\ATK_Project\sql_scripts\Gold
-- Files (15):
--   mis.2tbl_Gold_Dim_AppUsers.sql
--   mis.2tbl_Gold_Dim_Branch.sql
--   mis.2tbl_Gold_Dim_Clients.sql
--   mis.2tbl_Gold_Dim_Credits.sql
--   mis.2tbl_Gold_Dim_EmployeePayrollData.sql
--   mis.2tbl_Gold_Dim_Employees.sql
--   mis.2tbl_Gold_Dim_EmployeesHistory.sql
--   mis.2tbl_Gold_Dim_PartnersBranch.sql
--   mis.2tbl_Gold_Fact_AdminTasks.sql
--   mis.2tbl_Gold_Fact_ArchiveDocument.sql
--   mis.2tbl_Gold_Fact_BudgetEmployees.sql
--   mis.2tbl_Gold_Fact_CerereOnline.sql
--   mis.2tbl_Gold_Fact_CreditsInShadowBranches.sql
--   mis.2tbl_Gold_Fact_Disbursement.sql
--   mis.2tbl_Gold_Fact_Sold_Par.sql
----------------------------------------------------------------------------------------------------

SET NOCOUNT ON;

----------------------------------------------------------------------------------------------------
-- Start of: mis.2tbl_Gold_Dim_AppUsers.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO

IF OBJECT_ID('mis.[2tbl_Gold_Dim_AppUsers]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_AppUsers];
GO

CREATE TABLE mis.[2tbl_Gold_Dim_AppUsers]
(
    App_User_ClientID VARCHAR(36) NOT NULL,
    App_User_UserID VARCHAR(36) NOT NULL,
    App_User_Phone NVARCHAR(50) NULL,
    App_User_FiscalCode NVARCHAR(20) NULL,
    App_User_ClientName NVARCHAR(100) NULL
);
GO

INSERT INTO mis.[2tbl_Gold_Dim_AppUsers] 
(
    App_User_ClientID,
    App_User_UserID,
    App_User_Phone,
    App_User_FiscalCode,
    App_User_ClientName
)
SELECT
	[СведенияОПользователяхМобильногоПриложения Клиент ID]       AS App_User_ClientID, 
	[СведенияОПользователяхМобильногоПриложения Ид Пользователя] AS App_User_UserID,
    [СведенияОПользователяхМобильногоПриложения Телефон]         AS App_User_Phone,
    [СведенияОПользователяхМобильногоПриложения Фиск Код]        AS App_User_FiscalCode,
    [СведенияОПользователяхМобильногоПриложения Клиент]          AS App_User_ClientName

FROM [ATK].[mis].[Silver_РегистрыСведений.СведенияОПользователяхМобильногоПриложения];
----------------------------------------------------------------------------------------------------
-- End of:   mis.2tbl_Gold_Dim_AppUsers.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.2tbl_Gold_Dim_Branch.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO

-- Drop the table if it exists
IF OBJECT_ID(N'mis.[2tbl_Gold_Dim_Branch]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_Branch];
GO

-- Create the table
CREATE TABLE mis.[2tbl_Gold_Dim_Branch] (
    BranchID VARCHAR(36) NOT NULL,
    BranchCode DECIMAL(3, 0) NULL,
    BranchName NVARCHAR(100) NULL,
    DistrictName NVARCHAR(50) NULL,
    ActivityType NVARCHAR(100) NULL,
    EFSERegion NVARCHAR(50) NULL,
    Address NVARCHAR(150) NULL,
    Phones NVARCHAR(150) NULL,
    Email NVARCHAR(150) NULL,
    PrintBranchName NVARCHAR(100) NULL,
    Latitude DECIMAL(12, 8) NULL,
    Longitude DECIMAL(12, 8) NULL,
    BranchDepartment NVARCHAR(150) NULL,
    BranchRegion NVARCHAR(100) NULL
);
GO

WITH LastSvedeniya AS (
    SELECT 
        [СведенияОФилиалах Филиал ID],
        [СведенияОФилиалах Дирекция],
        [СведенияОФилиалах Регион],
        ROW_NUMBER() OVER (
            PARTITION BY [СведенияОФилиалах Филиал ID] 
            ORDER BY [СведенияОФилиалах Период] DESC
        ) AS rn
    FROM [ATK].[dbo].[РегистрыСведений.СведенияОФилиалах]
)
INSERT INTO mis.[2tbl_Gold_Dim_Branch] (
    BranchID,
    BranchCode,
    BranchName,
    DistrictName,
    ActivityType,
    EFSERegion,
    Address,
    Phones,
    Email,
    PrintBranchName,
    Latitude,
    Longitude,
    BranchDepartment,
    BranchRegion
)
SELECT
    f.[Филиалы ID] AS [BranchID],
    f.[Филиалы Код],
    f.[Филиалы Наименование],
    f.[Филиалы Наименование Района],
    f.[Филиалы Вид Деятельности],
    f.[Филиалы Регион EFSE],
    f.[Филиалы Адрес],
    f.[Филиалы Телефоны],
    f.[Филиалы Электронный Адрес],
    f.[Филиалы Наименование Филиала для Печати],
    f.[Филиалы Координаты Широта],
    f.[Филиалы Координаты Долгота],
    s.[СведенияОФилиалах Дирекция],
    s.[СведенияОФилиалах Регион]
FROM [ATK].[dbo].[Справочники.Филиалы] f
LEFT JOIN LastSvedeniya s
    ON f.[Филиалы ID] = s.[СведенияОФилиалах Филиал ID]
    AND s.rn = 1;
GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.2tbl_Gold_Dim_Branch.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.2tbl_Gold_Dim_Clients.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO
SET NOCOUNT ON;

-- Drop the table if it exists
IF OBJECT_ID(N'mis.[2tbl_Gold_Dim_Clients]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_Clients];
GO

-- Create the table
CREATE TABLE mis.[2tbl_Gold_Dim_Clients] (
    [ClientID]              VARCHAR(36)    NOT NULL,
    [ParentID]              VARCHAR(36)    NOT NULL,
    [BranchID]              VARCHAR(36)    NULL,
    [IsDeleted]             VARCHAR(36)    NULL,
    [IsGroup]               VARCHAR(36)    NULL,
    [ClientCode]            NCHAR(50)      NULL,
    [ClientName]            NVARCHAR(100)  NULL,
    [IsBlocked]             VARCHAR(36)    NULL,
    [Visibility]            INT            NULL,
    [Age]                   INT            NULL,
    [AgeGroup]              NVARCHAR(10)   NULL,
    [City]                  NVARCHAR(30)   NULL,
    [CreatedDate]           DATETIME2(0)   NULL,
    [PartnerCode]           NVARCHAR(3)    NULL,
    [FullName]              NVARCHAR(100)  NULL,
    [IsNonResident]         INT            NULL,
    [NoPaymentNotification] VARCHAR(36)    NULL,
    [Gender]                NVARCHAR(256)  NULL,
    [PostalAddress]         NVARCHAR(85)   NULL,
    [Country]               NVARCHAR(30)   NULL,
    [MobilePhone1]          NVARCHAR(50)    NULL,
    [MobilePhone2]          NVARCHAR(50)    NULL,
    [Phones]                NVARCHAR(50)   NULL,
    [FiscalCode]            NVARCHAR(20)   NULL,
    [LegalAddress]          NVARCHAR(85)   NULL,
    [RegistrationDate]      DATETIME2(0)   NULL,
    [Language]              NVARCHAR(25)   NULL,
    [NoEmailNotifications]  VARCHAR(36)    NULL,
    [NoPromoSMS]            VARCHAR(36)    NULL,
    [OrganizationType]      NVARCHAR(52)   NULL,
    [IsGroupOwner]          BIT            NULL,
    [GroupID]               NVARCHAR(20)    NULL,
    CONSTRAINT PK_2tbl_Gold_Dim_Clients PRIMARY KEY CLUSTERED (ClientID)
);
GO

;WITH Src AS (
    SELECT
        s.[Контрагенты ID] AS ClientID,
        s.[Контрагенты Родитель ID] AS ParentID,
        s.[Контрагенты Филиал ID] AS BranchID,
        s.[Контрагенты Пометка Удаления] AS IsDeleted,
        s.[Контрагенты Это Группа] AS IsGroup,
        s.[Контрагенты Код] AS ClientCode,
        s.[Контрагенты Наименование] AS ClientName,
        s.[Контрагенты Блокирован] AS IsBlocked,
        s.[Контрагенты Видимость] AS Visibility,
        s.[Контрагенты Возраст] AS DOB,
        s.[Контрагенты Город] AS City,
        s.[Контрагенты Страна] AS Country,
        s.[Контрагенты Дата Создания] AS CreatedDate,
        s.[Контрагенты Код Партнера] AS PartnerCode,
        s.[Контрагенты Наименование Полное] AS FullName,
        s.[Контрагенты Не Резидент] AS IsNonResident,
        s.[Контрагенты Не Уведомлять об Оплате] AS NoPaymentNotification,
        s.[Контрагенты Пол] AS Gender,
        s.[Контрагенты Почт Адрес] AS PostalAddress,
        s.[Контрагенты Телефон Мобильный 1] AS MobilePhone1,
        s.[Контрагенты Телефон Мобильный 2] AS MobilePhone2,
        s.[Контрагенты Телефоны] AS Phones,
        s.[Контрагенты Фиск Код] AS FiscalCode,
        s.[Контрагенты Юр Адрес] AS LegalAddress,
        s.[Контрагенты Дата Регистрации] AS RegistrationDate,
        s.[Контрагенты Язык] AS [Language],
        s.[Контрагенты Не Уведомлять Письмом] AS NoEmailNotifications,
        s.[Контрагенты Не Отправлять Рекламные СМС] AS NoPromoSMS,
        fp.[ФормыПредприятия Наименование] AS OrganizationType,
        CASE WHEN g.[ГруппыАффилированныхЛиц Владелец] = s.[Контрагенты ID] THEN 1 ELSE 0 END AS IsGroupOwner,
        ga.[ГруппыАффилированныхЛиц Код] AS GroupID,

        -- Effective representative DOB: use real DOB if available, else keep 1753-01-01
        CASE 
            WHEN r.[Контрагенты Возраст] <> '1753-01-01 00:00:00' THEN r.[Контрагенты Возраст]
            ELSE s.[Контрагенты Возраст]
        END AS EffectiveRepDOB

    FROM [ATK].[mis].[Silver_Справочники.Контрагенты] s
    LEFT JOIN [ATK].[mis].[Silver_Справочники.Контрагенты] r
        ON r.[Контрагенты ID] = s.[Контрагенты Представитель Контрагента ID]
    LEFT JOIN [ATK].[dbo].[Справочники.ФормыПредприятия] fp
        ON fp.[ФормыПредприятия Наименование] = s.[Контрагенты Форма Организации]
    LEFT JOIN [ATK].[dbo].[РегистрыСведений.СоставГруппАффилированныхЛиц] gb
        ON gb.[СоставГруппАффилированныхЛиц Контрагент ID] = s.[Контрагенты ID]
    LEFT JOIN [ATK].[dbo].[Справочники.ГруппыАффилированныхЛиц] ga
        ON ga.[ГруппыАффилированныхЛиц ID] = gb.[СоставГруппАффилированныхЛиц Группа Аффилированных Лиц ID]
    LEFT JOIN [ATK].[dbo].[Справочники.ГруппыАффилированныхЛиц] g
        ON g.[ГруппыАффилированныхЛиц ID] = ga.[ГруппыАффилированныхЛиц ID]
),

AgeCalc AS (
    SELECT *,
        CASE 
            WHEN EffectiveRepDOB IS NULL THEN NULL
            ELSE DATEDIFF(YEAR, EffectiveRepDOB, CAST(SYSDATETIME() AS date))
                 - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, EffectiveRepDOB, CAST(SYSDATETIME() AS date)), EffectiveRepDOB) 
                         > CAST(SYSDATETIME() AS date) THEN 1 ELSE 0 END
        END AS Age
    FROM Src
),

Final AS (
    SELECT
        ClientID, ParentID, BranchID,
        IsDeleted, IsGroup, ClientCode, ClientName, IsBlocked, Visibility,
        Age,
        CASE 
            WHEN Age IS NULL THEN 'n/a'
            WHEN Age <  22 THEN '< 22'
            WHEN Age <  25 THEN '< 25'
            WHEN Age <  35 THEN '< 35'
            WHEN Age <  45 THEN '< 45'
            WHEN Age <  55 THEN '< 55'
            WHEN Age <  65 THEN '< 65'
            WHEN Age > 110 THEN 'n/a'
            ELSE '> 65'
        END AS AgeGroup,
        City, CreatedDate, PartnerCode, FullName, IsNonResident, NoPaymentNotification,
        Gender, PostalAddress, Country, MobilePhone1, MobilePhone2, Phones,
        FiscalCode, LegalAddress, RegistrationDate, [Language],
        NoEmailNotifications, NoPromoSMS, OrganizationType,
        IsGroupOwner, GroupID
    FROM AgeCalc
),

Dedup AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ClientID
               ORDER BY RegistrationDate DESC, CreatedDate DESC
           ) AS rn
    FROM Final
)

INSERT INTO mis.[2tbl_Gold_Dim_Clients] (
    [ClientID],[ParentID],[BranchID],
    [IsDeleted],[IsGroup],[ClientCode],[ClientName],[IsBlocked],[Visibility],
    [Age],[AgeGroup],[City],[CreatedDate],[PartnerCode],[FullName],[IsNonResident],[NoPaymentNotification],
    [Gender],[PostalAddress],[Country],[MobilePhone1],[MobilePhone2],[Phones],
    [FiscalCode],[LegalAddress],[RegistrationDate],[Language],
    [NoEmailNotifications],[NoPromoSMS],[OrganizationType],
    [IsGroupOwner],[GroupID]
)
SELECT
    ClientID, ParentID, BranchID,
    IsDeleted, IsGroup, ClientCode, ClientName, IsBlocked, Visibility,
    Age, AgeGroup, City, CreatedDate, PartnerCode, FullName, IsNonResident, NoPaymentNotification,

    CASE Gender
        WHEN 'Ж' THEN 'F'
        WHEN N'М' THEN 'M'  -- Cyrillic M
        ELSE Gender      
    END AS Gender,
	
	PostalAddress, Country, MobilePhone1, MobilePhone2, Phones,
    FiscalCode, LegalAddress, RegistrationDate, 
	CASE [Language]
	     WHEN 'Русский' THEN 'Russian'
		 WHEN N'Română' THEN 'Romanian'
		 ELSE [Language]
    END AS [Language],
    NoEmailNotifications, NoPromoSMS, OrganizationType,
    IsGroupOwner, GroupID
FROM Dedup
WHERE rn = 1;
GO

-- Indexes
CREATE NONCLUSTERED INDEX IX_Clients_Branch    ON mis.[2tbl_Gold_Dim_Clients](BranchID)   INCLUDE (ClientName, IsBlocked);
CREATE NONCLUSTERED INDEX IX_Clients_AgeGroup  ON mis.[2tbl_Gold_Dim_Clients](AgeGroup)  INCLUDE (City, Country);
CREATE NONCLUSTERED INDEX IX_Clients_IsDeleted ON mis.[2tbl_Gold_Dim_Clients](IsDeleted) INCLUDE (ClientName);
CREATE NONCLUSTERED INDEX IX_Clients_Group     ON mis.[2tbl_Gold_Dim_Clients](IsGroupOwner, GroupID);
GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.2tbl_Gold_Dim_Clients.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.2tbl_Gold_Dim_Credits.sql
----------------------------------------------------------------------------------------------------
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
	
	c.[Кредиты Кредитный Продукт ID],
    c.[Кредиты Кредитный Продукт],
    c.[Кредиты Цель Кредита],	
	
	c.[Кредиты Удалить Источник Финансирования],
    CASE c.[Кредиты Вид Контракта]
	     WHEN 'Контракт' THEN 'Contract'
		 WHEN 'Приложение' THEN 'App'
		 ELSE c.[Кредиты Вид Контракта]
	END AS ContractType, 
	c.[Кредиты Дата Контракта],
    c.[Кредиты Сегмент Доходов],	

	c.[Кредиты Назначение Использования Кредита],
    
	c.[Кредиты Цель Кредита Описание],
	c.[Кредиты Тип Кредитного Продукта],
   
    c.[Кредиты Сфера Использования Кредита],
	
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
    
    gc.GreenCredit,
    gc.CommitteeProt_CrPurpose,	
	
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
----------------------------------------------------------------------------------------------------
-- End of:   mis.2tbl_Gold_Dim_Credits.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.2tbl_Gold_Dim_EmployeePayrollData.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO

-- Drop table if exists
IF OBJECT_ID('mis.[2tbl_Gold_Dim_EmployeePayrollData]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_EmployeePayrollData];
GO

-- Create table
CREATE TABLE mis.[2tbl_Gold_Dim_EmployeePayrollData]
(
    EmployeePositionID VARCHAR(36) NOT NULL,
    EmployeePosition NVARCHAR(150) NULL
);
GO

-- Insert normalized and mapped positions
INSERT INTO mis.[2tbl_Gold_Dim_EmployeePayrollData] 
(
    EmployeePositionID,
    EmployeePosition
)
SELECT 
    [СотрудникиДанныеПоЗарплате Должность ID] AS EmployeePositionID,
	[СотрудникиДанныеПоЗарплате Должность] AS EmployeePosition
    

FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате];
GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.2tbl_Gold_Dim_EmployeePayrollData.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.2tbl_Gold_Dim_Employees.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO

IF OBJECT_ID('mis.[2tbl_Gold_Dim_Employees]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_Employees];
GO

CREATE TABLE mis.[2tbl_Gold_Dim_Employees] (
    [EmployeeID] VARCHAR(36) NOT NULL,
    [EmployeeCode] INT NULL,
    [EmployeeName] NVARCHAR(40) NULL,
    [HireDate] DATETIME NULL,
    [BirthDate] DATETIME NULL,
    [DismissalDate] DATETIME NULL,
    [TimesheetNumber] INT NULL,
    [ExperienceYears] INT NULL,
    [ExperienceMonths] INT NULL,
    [EmploymentPeriod] NVARCHAR(50) NULL,
    [EmployeePositionID] VARCHAR(36) NULL,
    [EmployeePosition] NVARCHAR(150)  NULL
);
GO

INSERT INTO mis.[2tbl_Gold_Dim_Employees] (
    [EmployeeID],
    [EmployeeCode],
    [EmployeeName],
    [HireDate],
    [BirthDate],
    [DismissalDate],
    [TimesheetNumber],
    [ExperienceYears],
    [ExperienceMonths],
    [EmploymentPeriod],
    [EmployeePositionID],
    [EmployeePosition]
)
SELECT 
    a.[Сотрудники ID] AS EmployeeID,
    a.[Сотрудники Код] AS EmployeeCode,
    a.[Сотрудники Наименование] AS EmployeeName,
    a.[Сотрудники Дата Приема] AS HireDate,
    a.[Сотрудники Дата Рождения] AS BirthDate,
    a.[Сотрудники Дата Увольнения] AS DismissalDate,
    a.[Сотрудники Табельный Номер] AS TimesheetNumber,
    DATEDIFF(YEAR, a.[Сотрудники Дата Приема], GETDATE()) AS ExperienceYears,
    DATEDIFF(MONTH, a.[Сотрудники Дата Приема], GETDATE()) % 12 AS ExperienceMonths,
    CASE 
        WHEN a.[Сотрудники Дата Увольнения] IS NULL 
        THEN FORMAT(a.[Сотрудники Дата Приема], 'yyyy-MM-dd') + N' → Present'
        ELSE FORMAT(a.[Сотрудники Дата Приема], 'yyyy-MM-dd') + N' → ' + FORMAT(a.[Сотрудники Дата Увольнения], 'yyyy-MM-dd')
    END AS EmploymentPeriod,
    lastPos.[СотрудникиДанныеПоЗарплате Должность ID] AS EmployeePositionID,
    lastPos.[СотрудникиДанныеПоЗарплате Должность] AS EmployeePosition
FROM [ATK].[dbo].[Справочники.Сотрудники] AS a
OUTER APPLY (
    SELECT TOP 1 *
    FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате] AS b
    WHERE b.[СотрудникиДанныеПоЗарплате Сотрудник ID] = a.[Сотрудники ID]
    ORDER BY b.[СотрудникиДанныеПоЗарплате Период] DESC
) AS lastPos;
GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.2tbl_Gold_Dim_Employees.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.2tbl_Gold_Dim_EmployeesHistory.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO


IF OBJECT_ID('mis.[2tbl_Gold_Dim_EmployeesHistory]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_EmployeesHistory];
GO


CREATE TABLE mis.[2tbl_Gold_Dim_EmployeesHistory] (
    Period       DATETIME      NULL,
    ID           VARCHAR(36)   NOT NULL,
    RowNumber    INT           NULL,
    IsActive     VARCHAR(36)   NULL,
    Credit_ID    VARCHAR(36)   NULL,
    Credit       NVARCHAR(100) NULL,
    Filial_ID    VARCHAR(36)   NULL,
    Filial       NVARCHAR(100) NULL,
    Employee_ID    VARCHAR(36)   NULL,
    Employee       NVARCHAR(100) NULL,
    DateTo       DATETIME      NULL
);
GO

INSERT INTO mis.[2tbl_Gold_Dim_EmployeesHistory] (
    Period,
    ID,
    RowNumber,
    IsActive,
    Credit_ID,
    Credit,
    Filial_ID,
    Filial,
    Employee_ID,
    Employee,
    DateTo
)
SELECT
    [ОтветственныеПоКредитамВыданным Период]                    AS Period,
    [ОтветственныеПоКредитамВыданным ID]                        AS ID,         
    [ОтветственныеПоКредитамВыданным Номер Строки]              AS RowNumber,
    [ОтветственныеПоКредитамВыданным Активность]                AS IsActive,
    [ОтветственныеПоКредитамВыданным Кредит ID]                 AS Credit_ID,
    [ОтветственныеПоКредитамВыданным Кредит]                    AS Credit,
    [ОтветственныеПоКредитамВыданным Филиал ID]                 AS Filial_ID,
    [ОтветственныеПоКредитамВыданным Филиал]                    AS Filial,
    [ОтветственныеПоКредитамВыданным Кредитный Эксперт ID]      AS Employee_ID,
    [ОтветственныеПоКредитамВыданным Кредитный Эксперт]         AS Employee,
    ISNULL(
        LEAD([ОтветственныеПоКредитамВыданным Период]) OVER (
            PARTITION BY [ОтветственныеПоКредитамВыданным Кредит ID]
            ORDER BY [ОтветственныеПоКредитамВыданным Период], [ОтветственныеПоКредитамВыданным Номер Строки]
        ),
        CONVERT(DATETIME, '2222-01-01', 120)
    )                                                           AS DateTo
FROM [ATK].[mis].[Silver_РегистрыСведений.ОтветственныеПоКредитамВыданным];
GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.2tbl_Gold_Dim_EmployeesHistory.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.2tbl_Gold_Dim_PartnersBranch.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO

-- Drop the gold table if it exists
IF OBJECT_ID('mis.[2tbl_Gold_Dim_PartnersBranch]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_PartnersBranch];
GO

-- Create gold table with only essential columns
CREATE TABLE mis.[2tbl_Gold_Dim_PartnersBranch]
(
    [PartnerBranchID]               VARCHAR(36) NOT NULL,
    [PartnerBranchDeletedFlag]      VARCHAR(36) NOT NULL,
    [PartnerBranchOwner]            VARCHAR(36) NOT NULL,
    [PartnerBranchCode]             NVARCHAR(3)   NOT NULL,
    [PartnerBranchName]             NVARCHAR(150) NULL,
    [PartnerBranchAddress]          NVARCHAR(100) NULL,

    [DealerID]                      VARCHAR(36) NULL,
    [DealerDefaultEmployeeID]         VARCHAR(36) NULL,
    [DealerDefaultEmployeeName]       NVARCHAR(50) NULL,
    [DealerOrgRepID]                VARCHAR(36) NULL,
    [DealerOrgRepName]              NVARCHAR(50) NULL

);
GO

-- Insert data from silvers
INSERT INTO mis.[2tbl_Gold_Dim_PartnersBranch]
(
    [PartnerBranchID],
    [PartnerBranchDeletedFlag],
    [PartnerBranchOwner],
    [PartnerBranchCode],
    [PartnerBranchName],
    [PartnerBranchAddress],

    [DealerID],
    [DealerDefaultEmployeeID],
    [DealerDefaultEmployeeName],
    [DealerOrgRepID],
    [DealerOrgRepName]
)
SELECT
    f.[ФилиалыКонтрагентов ID] AS PartnerBranchID,
    f.[ФилиалыКонтрагентов Пометка Удаления] AS PartnerBranchDeletedFlag,
    f.[ФилиалыКонтрагентов Владелец] AS PartnerBranchOwner,
    f.[ФилиалыКонтрагентов Код] AS PartnerBranchCode,
    f.[ФилиалыКонтрагентов Наименование] AS PartnerBranchName,
    f.[ФилиалыКонтрагентов Адрес] AS PartnerBranchAddress,

    d.[Дилеры ID] AS DealerID,
    d.[Дилеры Эксперт по Умолчанию ID] AS DealerDefaultEmployeeID ,
    d.[Дилеры Эксперт по Умолчанию] AS DealerDefaultEmployeeName,
    d.[Дилеры Представитель Организации ID] AS DealerOrgRepID,
    d.[Дилеры Представитель Организации] AS DealerOrgRepName
FROM mis.[Silver_Справочники.ФилиалыКонтрагентов] f
LEFT JOIN mis.[Silver_Справочники.Дилеры] d
  ON d.[Дилеры Владелец] = f.[ФилиалыКонтрагентов ID];
GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.2tbl_Gold_Dim_PartnersBranch.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.2tbl_Gold_Fact_AdminTasks.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO

-- Drop table if exists
IF OBJECT_ID('mis.[2tbl_Gold_Fact_AdminTasks]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Fact_AdminTasks];
GO

-- Create table allowing NULLs
CREATE TABLE mis.[2tbl_Gold_Fact_AdminTasks]
(
    [AdminTask_ID] VARCHAR(36) NOT NULL,
    [AdminTask_RowVersion] ROWVERSION NULL,
    [AdminTask_Deleted] VARCHAR(36) NOT NULL,
    [AdminTask_Date] DATETIME NULL,
    [AdminTask_Number] NVARCHAR(50) NOT NULL,
    [AdminTask_Completed] VARCHAR(36) NOT NULL,
    [AdminTask_Author_ID] VARCHAR(36) NOT NULL,
    [AdminTask_Author] NVARCHAR(150) NOT NULL,
    [AdminTask_Branch_ID] VARCHAR(36) NOT NULL,
    [AdminTask_Branch] NVARCHAR(150) NULL,
    [AdminTask_Category_ID] VARCHAR(36) NOT NULL,
    [AdminTask_Category] NVARCHAR(250) NOT NULL,
    [AdminTask_Type_ID] VARCHAR(36) NOT NULL,
    [AdminTask_Type] NVARCHAR(250) NOT NULL,
    [AdminTask_Description] NVARCHAR(1050) NOT NULL,
    [AdminTask_Base_ID] VARCHAR(36) NOT NULL,
    [AdminTask_Source_Type] VARCHAR(36) NOT NULL,
    [AdminTask_Source_View] VARCHAR(36) NOT NULL,
    [AdminTask_Source_ID] VARCHAR(36) NOT NULL,
    [AdminTask_Client_ID] VARCHAR(36) NOT NULL,
    [AdminTask_Client] NVARCHAR(150) NULL,
    [AdminTask_Credit_ID] VARCHAR(36) NOT NULL,
    [AdminTask_Credit] NVARCHAR(150) NULL,
    [AdminTask_Limit_ID] VARCHAR(36) NOT NULL,
    [AdminTask_Limit] NVARCHAR(150) NULL,
    [AdminTask_CurrentStatus] NVARCHAR(256) NULL,
    [AdminTask_CurrentStatus_ID] VARCHAR(36) NULL,
    [AdminTask_CompletionDate] DATETIME NULL,
    [AdminTask_CurrentComment] NVARCHAR(1000) NULL,
    [AdminTask_SLA] INT NULL,
    [AdminTask_KPI] DECIMAL(6,2) NULL,
    [AdminTask_TaskCount] INT NULL,
    [AdminTask_Priority] NVARCHAR(256) NULL,
    [AdminTask_Priority_ID] VARCHAR(36) NULL,
    [AdminTask_Executor] VARCHAR(36) NULL,

    [TaskType_ID] VARCHAR(36) NULL,
    [TaskType_Deleted] VARCHAR(36) NULL,
    [TaskType_Parent_ID] VARCHAR(36) NULL,
    [TaskType_IsGroup] BIT NULL,
    [TaskType_Code] NVARCHAR(50) NULL,
    [TaskType_Name] NVARCHAR(250) NULL,
    [TaskType_Order] INT NULL,
    [TaskType_SLA] INT NULL,
    [TaskType_KPI] DECIMAL(6,2) NULL,
    [TaskType_BlockEditCount] BIT NULL,
    [TaskType_MaxTime] INT NULL,

    [WaitHours] DECIMAL(18,2) NULL,
    [TotalHours] DECIMAL(18,2) NULL,

    [StatusHistory_ID] VARCHAR(36) NULL,
    [StatusHistory_RowNumber] INT NULL,
    [StatusHistory_Status] NVARCHAR(256) NULL,
    [StatusHistory_StatusID] VARCHAR(36) NULL,
    [StatusHistory_UserID] VARCHAR(36) NULL,
    [StatusHistory_User] NVARCHAR(150) NULL,
    [StatusHistory_StartDate] DATETIME NULL,
    [StatusHistory_EndDate] DATETIME NULL,
    [StatusHistory_Comment] NVARCHAR(1000) NULL,
    [StatusHistory_Seconds] INT NULL
);
GO

-- Insert with historical SLA/KPI
INSERT INTO mis.[2tbl_Gold_Fact_AdminTasks]
(
    [AdminTask_ID],
    [AdminTask_Deleted],
    [AdminTask_Date],
    [AdminTask_Number],
    [AdminTask_Completed],
    [AdminTask_Author_ID],
    [AdminTask_Author],
    [AdminTask_Branch_ID],
    [AdminTask_Branch],
    [AdminTask_Category_ID],
    [AdminTask_Category],
    [AdminTask_Type_ID],
    [AdminTask_Type],
    [AdminTask_Description],
    [AdminTask_Base_ID],
    [AdminTask_Source_Type],
    [AdminTask_Source_View],
    [AdminTask_Source_ID],
    [AdminTask_Client_ID],
    [AdminTask_Client],
    [AdminTask_Credit_ID],
    [AdminTask_Credit],
    [AdminTask_Limit_ID],
    [AdminTask_Limit],
    [AdminTask_CurrentStatus],
    [AdminTask_CurrentStatus_ID],
    [AdminTask_CompletionDate],
    [AdminTask_CurrentComment],
    [AdminTask_SLA],
    [AdminTask_KPI],
    [AdminTask_TaskCount],
    [AdminTask_Priority],
    [AdminTask_Priority_ID],
    [AdminTask_Executor],

    [TaskType_ID],
    [TaskType_Deleted],
    [TaskType_Parent_ID],
    [TaskType_IsGroup],
    [TaskType_Code],
    [TaskType_Name],
    [TaskType_Order],
    [TaskType_SLA],
    [TaskType_KPI],
    [TaskType_BlockEditCount],
    [TaskType_MaxTime],

    [WaitHours],
    [TotalHours],

    [StatusHistory_ID],
    [StatusHistory_RowNumber],
    [StatusHistory_Status],
    [StatusHistory_StatusID],
    [StatusHistory_UserID],
    [StatusHistory_User],
    [StatusHistory_StartDate],
    [StatusHistory_EndDate],
    [StatusHistory_Comment],
    [StatusHistory_Seconds]
)
SELECT
    a.[ЗадачаАдминистратораКредитов ID],
    a.[ЗадачаАдминистратораКредитов Пометка Удаления],
    a.[ЗадачаАдминистратораКредитов Дата],
    a.[ЗадачаАдминистратораКредитов Номер],
    a.[ЗадачаАдминистратораКредитов Выполнена],
    a.[ЗадачаАдминистратораКредитов Автор ID],
    a.[ЗадачаАдминистратораКредитов Автор],
    a.[ЗадачаАдминистратораКредитов Филиал ID],
    a.[ЗадачаАдминистратораКредитов Филиал],
    a.[ЗадачаАдминистратораКредитов Категория Задачи ID],
    a.[ЗадачаАдминистратораКредитов Категория Задачи],
    a.[ЗадачаАдминистратораКредитов Тип Задачи ID],
    a.[ЗадачаАдминистратораКредитов Тип Задачи],
    a.[ЗадачаАдминистратораКредитов Описание Задачи],
    a.[ЗадачаАдминистратораКредитов Задача Основание ID],
    a.[ЗадачаАдминистратораКредитов Источник Тип],
    a.[ЗадачаАдминистратораКредитов Источник Вид],
    a.[ЗадачаАдминистратораКредитов Источник ID],
    a.[ЗадачаАдминистратораКредитов Клиент ID],
    a.[ЗадачаАдминистратораКредитов Клиент],
    a.[ЗадачаАдминистратораКредитов Кредит ID],
    a.[ЗадачаАдминистратораКредитов Кредит],
    a.[ЗадачаАдминистратораКредитов Лимит ID],
    a.[ЗадачаАдминистратораКредитов Лимит],
    sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Статус],
    sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Статус ID],
    a.[ЗадачаАдминистратораКредитов Дата Выполнения],
    a.[ЗадачаАдминистратораКредитов Текущий Комментарий],
    hist_tasktype.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей SLA],
    hist_tasktype.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей KPI],
    a.[ЗадачаАдминистратораКредитов Количество Задач],
    a.[ЗадачаАдминистратораКредитов Приоритет Задачи],
    a.[ЗадачаАдминистратораКредитов Приоритет Задачи ID],
    a.[ЗадачаАдминистратораКредитов Исполнитель],

    t.[ТипыЗадачАдминистратораКредитов ID],
    t.[ТипыЗадачАдминистратораКредитов Пометка Удаления],
    t.[ТипыЗадачАдминистратораКредитов Родитель ID],
    t.[ТипыЗадачАдминистратораКредитов Это Группа],
    t.[ТипыЗадачАдминистратораКредитов Код],
    t.[ТипыЗадачАдминистратораКредитов Наименование],
    t.[ТипыЗадачАдминистратораКредитов Реквизит Доп Упорядочивания],
    hist_tasktype.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей SLA],
    hist_tasktype.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей KPI],
    t.[ТипыЗадачАдминистратораКредитов Запрет Редактирования Количества Задач],
    hist_tasktype.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей Максимальное Время Выполнения],

    COALESCE(wait_hours.WaitHours, 0) AS WaitHours,
    COALESCE(total_hours.TotalHours, 0) AS TotalHours,

    sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID],
    sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Номер Строки],
    sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Статус],
    sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Статус ID],
    sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Пользователь ID],
    sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Пользователь],
    sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Дата Начала],
    sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Дата Окончания],
    sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Комментарий],
    sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Время в Секундах]
FROM [ATK].[mis].[Silver_Задачи.ЗадачаАдминистратораКредитов] a
LEFT JOIN [ATK].[mis].[Silver_Справочники.ТипыЗадачАдминистратораКредитов] t
    ON a.[ЗадачаАдминистратораКредитов Тип Задачи ID] = t.[ТипыЗадачАдминистратораКредитов ID]
OUTER APPLY
(
    -- latest status row per task
    SELECT TOP 1 *
    FROM [ATK].[mis].[Silver_Задачи.ЗадачаАдминистратораКредитов.ИсторияСтатусов] s
    WHERE s.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID] = a.[ЗадачаАдминистратораКредитов ID]
    ORDER BY s.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Номер Строки] DESC
) sh
OUTER APPLY
(
    -- sum of all seconds for task
    SELECT SUM(CAST(s2.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Время в Секундах] AS FLOAT))/3600.0 AS TotalHours
    FROM [ATK].[mis].[Silver_Задачи.ЗадачаАдминистратораКредитов.ИсторияСтатусов] s2
    WHERE s2.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID] = a.[ЗадачаАдминистратораКредитов ID]
) total_hours
OUTER APPLY
(
    -- sum of seconds for status = 'ВОжидании'
    SELECT SUM(CAST(s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Время в Секундах] AS FLOAT))/3600.0 AS WaitHours
    FROM [ATK].[mis].[Silver_Задачи.ЗадачаАдминистратораКредитов.ИсторияСтатусов] s3
    WHERE s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID] = a.[ЗадачаАдминистратораКредитов ID]
      AND s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Статус] = N'ВОжидании'
) wait_hours
OUTER APPLY
(
    -- get SLA/KPI from history as of task date
    SELECT TOP 1 *
    FROM [ATK].[dbo].[Справочники.ТипыЗадачАдминистратораКредитов_ИсторияПоказателей] hist
    WHERE hist.[ТипыЗадачАдминистратораКредитов ID] = t.[ТипыЗадачАдминистратораКредитов ID]
      AND hist.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей Дата Изменения] <= a.[ЗадачаАдминистратораКредитов Дата]
    ORDER BY hist.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей Дата Изменения] DESC
) hist_tasktype;
GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.2tbl_Gold_Fact_AdminTasks.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.2tbl_Gold_Fact_ArchiveDocument.sql
----------------------------------------------------------------------------------------------------
USE [ATK]
GO

-- Drop table if exists
IF OBJECT_ID('mis.[2tbl_Gold_Fact_ArchiveDocument]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Fact_ArchiveDocument];
GO

-- Step 1: Create the table structure (no data yet)
CREATE TABLE mis.[2tbl_Gold_Fact_ArchiveDocument] (
    [АктыПередачиКредитныхДел Период]         DATETIME NULL,
    [АктыПередачиКредитныхДел ID]             VARCHAR(36) NULL,
    [АктыПередачиКредитныхДел Номер Строки]   INT NULL,
    [АктыПередачиКредитныхДел Активность]     VARCHAR(50) NULL,
    [АктыПередачиКредитныхДел Кредит Tип]     VARCHAR(50) NULL,
    [АктыПередачиКредитныхДел Кредит Вид]     VARCHAR(50) NULL,
    [АктыПередачиКредитныхДел Кредит ID]      VARCHAR(36) NULL,
    [АктыПередачиКредитныхДел Контрагент ID]  VARCHAR(36) NULL,
    [АктыПередачиКредитныхДел Контрагент]     NVARCHAR(250) NULL,
    [АктыПередачиКредитныхДел Вид Акта]       NVARCHAR(256) NULL,
    [АктыПередачиКредитныхДел Вид Операции Tип] VARCHAR(50) NULL,
    [АктыПередачиКредитныхДел Вид Операции Вид] VARCHAR(50) NULL,
    [АктыПередачиКредитныхДел Вид Операции ID] VARCHAR(50) NULL,
    [АктыПередачиКредитныхДел Вид Операции Документ Tип] VARCHAR(50) NULL,
    [АктыПередачиКредитныхДел Вид Операции Документ Вид] VARCHAR(50) NULL,
    [АктыПередачиКредитныхДел Вид Операции Документ ID] VARCHAR(36) NULL,
    [АктыПередачиКредитныхДел Вид Акта Передачи Кредитных Дел] NVARCHAR(256) NULL,
    [АктыПередачиКредитныхДел Статус Досье] NVARCHAR(256) NULL,
    [АктыПередачиКредитныхДел Статус Акта] NVARCHAR(256) NULL,
    [АктыПередачиКредитныхДел Получатель Tип] VARCHAR(50) NULL,
    [АктыПередачиКредитныхДел Получатель Вид] VARCHAR(50) NULL,
    [АктыПередачиКредитныхДел Получатель ID] VARCHAR(36) NULL,
    [АктыПередачиКредитныхДел Дата Получения] DATETIME NULL,
    [АктыПередачиКредитныхДел Дата Проверки] DATETIME NULL,
    [АктыПередачиКредитныхДел Комментарий] NVARCHAR(1000) NULL,
    [АктыПередачиКредитныхДел Автор ID] VARCHAR(36) NULL,
    [АктыПередачиКредитныхДел Автор] NVARCHAR(250) NULL,
    [АктыПередачиКредитныхДел Дедлайн] DATETIME NULL,

    [ОтветственныеПоКредитнымДелам Период] DATETIME NULL,
    [ОтветственныеПоКредитнымДелам ID] VARCHAR(36) NULL,
    [ОтветственныеПоКредитнымДелам Номер Строки] INT NULL,
    [ОтветственныеПоКредитнымДелам Активность] VARCHAR(50) NULL,
    [ОтветственныеПоКредитнымДелам Кредит Tип] VARCHAR(50) NULL,
    [ОтветственныеПоКредитнымДелам Кредит Вид] VARCHAR(50) NULL,
    [ОтветственныеПоКредитнымДелам Кредит ID] VARCHAR(36) NULL,
    [ОтветственныеПоКредитнымДелам Ответственный Tип] VARCHAR(50) NULL,
    [ОтветственныеПоКредитнымДелам Ответственный Вид] VARCHAR(50) NULL,
    [ОтветственныеПоКредитнымДелам Ответственный ID] VARCHAR(36) NULL,
    [ОтветственныеПоКредитнымДелам Дата Проверки] DATETIME NULL,
    [ОтветственныеПоКредитнымДелам Комментарий] NVARCHAR(1000) NULL,
    [ОтветственныеПоКредитнымДелам Телефон] NVARCHAR(50) NULL,
    [ОтветственныеПоКредитнымДелам Филиал ID] VARCHAR(36) NULL,
    [ОтветственныеПоКредитнымДелам Филиал] NVARCHAR(250) NULL,
    [ОтветственныеПоКредитнымДелам Вид Акта Передачи Кредитных Дел] NVARCHAR(256) NULL,
    [ОтветственныеПоКредитнымДелам Отправитель ID] VARCHAR(36) NULL,
    [ОтветственныеПоКредитнымДелам Отправитель] NVARCHAR(100) NULL,
    [ОтветственныеПоКредитнымДелам Ссылка на Документ ID] VARCHAR(36) NULL,
    [ОтветственныеПоКредитнымДелам Ссылка на Документ] NVARCHAR(150) NULL,
    [ОтветственныеПоКредитнымДелам Статус Акта] NVARCHAR(256) NULL
);
GO

-- Step 2: Insert data from 2024-01-01 onward
INSERT INTO mis.[2tbl_Gold_Fact_ArchiveDocument]
SELECT
    r.[АктыПередачиКредитныхДел Период],
    r.[АктыПередачиКредитныхДел ID],
    r.[АктыПередачиКредитныхДел Номер Строки],
    r.[АктыПередачиКредитныхДел Активность],
    r.[АктыПередачиКредитныхДел Кредит Tип],
    r.[АктыПередачиКредитныхДел Кредит Вид],
    r.[АктыПередачиКредитныхДел Кредит ID],
    r.[АктыПередачиКредитныхДел Контрагент ID],
    r.[АктыПередачиКредитныхДел Контрагент],
    r.[АктыПередачиКредитныхДел Вид Акта],
    r.[АктыПередачиКредитныхДел Вид Операции Tип],
    r.[АктыПередачиКредитныхДел Вид Операции Вид],
    r.[АктыПередачиКредитныхДел Вид Операции ID],
    r.[АктыПередачиКредитныхДел Вид Операции Документ Tип],
    r.[АктыПередачиКредитныхДел Вид Операции Документ Вид],
    r.[АктыПередачиКредитныхДел Вид Операции Документ ID],
    r.[АктыПередачиКредитныхДел Вид Акта Передачи Кредитных Дел],
    r.[АктыПередачиКредитныхДел Статус Досье],
    r.[АктыПередачиКредитныхДел Статус Акта],
    r.[АктыПередачиКредитныхДел Получатель Tип],
    r.[АктыПередачиКредитныхДел Получатель Вид],
    r.[АктыПередачиКредитныхДел Получатель ID],
    r.[АктыПередачиКредитныхДел Дата Получения],
    r.[АктыПередачиКредитныхДел Дата Проверки],
    r.[АктыПередачиКредитныхДел Комментарий],
    r.[АктыПередачиКредитныхДел Автор ID],
    r.[АктыПередачиКредитныхДел Автор],
    r.[АктыПередачиКредитныхДел Дедлайн],

    o.[ОтветственныеПоКредитнымДелам Период],
    o.[ОтветственныеПоКредитнымДелам ID],
    o.[ОтветственныеПоКредитнымДелам Номер Строки],
    o.[ОтветственныеПоКредитнымДелам Активность],
    o.[ОтветственныеПоКредитнымДелам Кредит Tип],
    o.[ОтветственныеПоКредитнымДелам Кредит Вид],
    o.[ОтветственныеПоКредитнымДелам Кредит ID],
    o.[ОтветственныеПоКредитнымДелам Ответственный Tип],
    o.[ОтветственныеПоКредитнымДелам Ответственный Вид],
    o.[ОтветственныеПоКредитнымДелам Ответственный ID],
    o.[ОтветственныеПоКредитнымДелам Дата Проверки],
    o.[ОтветственныеПоКредитнымДелам Комментарий],
    o.[ОтветственныеПоКредитнымДелам Телефон],
    o.[ОтветственныеПоКредитнымДелам Филиал ID],
    o.[ОтветственныеПоКредитнымДелам Филиал],
    o.[ОтветственныеПоКредитнымДелам Вид Акта Передачи Кредитных Дел],
    o.[ОтветственныеПоКредитнымДелам Отправитель ID],
    o.[ОтветственныеПоКредитнымДелам Отправитель],
    o.[ОтветственныеПоКредитнымДелам Ссылка на Документ ID],
    o.[ОтветственныеПоКредитнымДелам Ссылка на Документ],
    o.[ОтветственныеПоКредитнымДелам Статус Акта]  

FROM [ATK].[dbo].[РегистрыСведений.АктыПередачиКредитныхДел] r
LEFT JOIN [ATK].[dbo].[РегистрыСведений.ОтветственныеПоКредитнымДелам] o
       ON o.[ОтветственныеПоКредитнымДелам ID] = r.[АктыПередачиКредитныхДел ID]
       AND o.[ОтветственныеПоКредитнымДелам Кредит ID] = r.[АктыПередачиКредитныхДел Кредит ID]
WHERE r.[АктыПередачиКредитныхДел Период] >= '2024-01-01';
GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.2tbl_Gold_Fact_ArchiveDocument.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.2tbl_Gold_Fact_BudgetEmployees.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO

IF OBJECT_ID('mis.[2tbl_Gold_Fact_BudgetEmployees]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Fact_BudgetEmployees];
GO

CREATE TABLE mis.[2tbl_Gold_Fact_BudgetEmployees] 
(
    [EmployeeID]          VARCHAR(36) NOT NULL,
    [Employee]            NVARCHAR(40) NULL,
    [AmountIssued]        DECIMAL(18,2) NULL,
    [PortfolioAmount]     DECIMAL(18,2) NULL,
    [QuantityIssued]      INT NULL,
    [DailyVisitPromotions] INT NULL,
    [DailyCallPromotions]  INT NULL,
    [PAR30]               INT NULL,
    [FinProductID]        VARCHAR(36) NULL,
    [FinProductName]      NVARCHAR(100) NULL,
    [DataVersion]         INT NULL,
    [DeletedFlag]         VARCHAR(36) NULL,
    [Date]                DATETIME NULL,
    [Number]              NVARCHAR(50) NULL,
    [Posted]              VARCHAR(36) NULL,
    [BranchID]            VARCHAR(36) NULL,
    [BranchName]          NVARCHAR(100) NULL,
    [Comment]             NVARCHAR(256) NULL,
    [Organization]        NVARCHAR(100) NULL,
    [TotalAmountIssued]   DECIMAL(18,2) NULL,
    [TotalPortfolioAmount] DECIMAL(18,2) NULL,
    [TotalPAR0]           INT NULL,
    [NonBusinessPAR30]    INT NULL
);
GO

INSERT INTO mis.[2tbl_Gold_Fact_BudgetEmployees]
SELECT
    s.[БюджетПоСотрудникам ID] AS EmployeeID,
    s.[БюджетПоСотрудникам.Сотрудники Сотрудник] AS Employee,
    s.[БюджетПоСотрудникам.Сотрудники Сумма Выдано] AS AmountIssued,
    s.[БюджетПоСотрудникам.Сотрудники Сумма Портфель] AS PortfolioAmount,
    s.[БюджетПоСотрудникам.Сотрудники Количество Выдано] AS QuantityIssued,
    s.[БюджетПоСотрудникам.Сотрудники Количество Продвижений Визиты в День] AS DailyVisitPromotions,
    s.[БюджетПоСотрудникам.Сотрудники Количество Продвижений Звонки в День] AS DailyCallPromotions,
    s.[БюджетПоСотрудникам.Сотрудники PAR30] AS PAR30,
    s.[БюджетПоСотрудникам.Сотрудники Финансовый Продукт ID] AS FinProductID,
    s.[БюджетПоСотрудникам.Сотрудники Финансовый Продукт] AS FinProductName,
    d.[БюджетПоСотрудникам Версия Данных] AS DataVersion,
    d.[БюджетПоСотрудникам Пометка Удаления] AS DeletedFlag,
    d.[БюджетПоСотрудникам Дата] AS Date,
    d.[БюджетПоСотрудникам Номер] AS Number,
    d.[БюджетПоСотрудникам Проведен] AS Posted,
    d.[БюджетПоСотрудникам Филиал ID] AS BranchID,
    d.[БюджетПоСотрудникам Филиал] AS BranchName,
    d.[БюджетПоСотрудникам Комментарий] AS Comment,
    d.[БюджетПоСотрудникам Организация] AS Organization,
    d.[БюджетПоСотрудникам Сумма Выдано Итого] AS TotalAmountIssued,
    d.[БюджетПоСотрудникам Сумма Портфель Итого] AS TotalPortfolioAmount,
    d.[БюджетПоСотрудникам PAR0] AS TotalPAR0,
    d.[БюджетПоСотрудникам PAR30 Нон Бизнес] AS NonBusinessPAR30
FROM [ATK].[dbo].[Документы.БюджетПоСотрудникам.Сотрудники] s
LEFT JOIN [ATK].[dbo].[Документы.БюджетПоСотрудникам] d
    ON s.[БюджетПоСотрудникам ID] = d.[БюджетПоСотрудникам ID]
WHERE d.[БюджетПоСотрудникам Дата] >= '2023-01-01';
GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.2tbl_Gold_Fact_BudgetEmployees.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.2tbl_Gold_Fact_CerereOnline.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO
SET NOCOUNT ON;

-----------------------------------------------------------------------------------
-- 2tbl_Gold_Fact_CerereOnline
-- Purpose:
--     Builds GOLD-level fact table for online credit requests (Cerere Online).
--     Combines data from:
--         - [Silver_Документы.ЗаявкаНаКредит]
--         - [Silver_Документы.ОбъединеннаяИнтернетЗаявка]
--     Excludes test clients based on [Контрагенты Тестовый Контрагент] = 00.
-----------------------------------------------------------------------------------
IF OBJECT_ID('mis.[2tbl_Gold_Fact_CerereOnline]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Fact_CerereOnline];
GO

CREATE TABLE mis.[2tbl_Gold_Fact_CerereOnline] (
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
    --[WebID]                 VARCHAR(36)    NOT NULL,
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
    [CommitteeDecisionDate] DATETIME       NULL,
    --CONSTRAINT PK_2tbl_Gold_Fact_CerereOnline PRIMARY KEY CLUSTERED ([WebID])
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
        z.[ЗаявкаНаКредит Кредитный Продукт] AS [CreditProduct],
        z.[ЗаявкаНаКредит Финансовый Продукт ID] AS [ProductID],
        z.[ЗаявкаНаКредит Кредитный Продукт ID] AS [CreditProductID],
        z.[ЗаявкаНаКредит Заявка Клиента Интернет ID] AS [InternetID],
        z.[ЗаявкаНаКредит Кредитный Эксперт ID] AS [EmployeeID],
        z.[ЗаявкаНаКредит Филиал ID] AS [BranchID],
        z.[ЗаявкаНаКредит Партнер ID] AS [PartnerID],
        z.[ЗаявкаНаКредит Партнер] AS [Partner],
        --COALESCE(o.[ОбъединеннаяИнтернетЗаявка ID], CAST(NEWID() AS VARCHAR(36))) AS [WebID],
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
        COALESCE(
            z.[ЗаявкаНаКредит Клиент ID],
            o.[ОбъединеннаяИнтернетЗаявка Идентификатор],
            o.[ОбъединеннаяИнтернетЗаявка Номер Телефона Мобильный],
            o.[ОбъединеннаяИнтернетЗаявка Автор ID],
            o.[ОбъединеннаяИнтернетЗаявка ID]
        ) AS ClientKey,
        c.[ПротоколКомитета Дата Решения] AS [CommitteeDecisionDate]
    FROM [ATK].[mis].[Silver_Документы.ЗаявкаНаКредит] z
    LEFT JOIN [ATK].[mis].[Silver_Документы.ОбъединеннаяИнтернетЗаявка] o
        ON z.[ЗаявкаНаКредит ID] = o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
    LEFT JOIN [ATK].[dbo].[Документы.ПротоколКомитета] c
        ON c.[ПротоколКомитета Заявка ID] = z.[ЗаявкаНаКредит ID]

    -------------------------------------------------------------------------------
    -- B. From ОбъединеннаяИнтернетЗаявка (when no linked ЗаявкаНаКредит)
    -------------------------------------------------------------------------------
    UNION ALL
    SELECT
        NULL AS [ID], NULL AS [Date], NULL AS [Status], NULL AS [Posted],
        NULL AS [BusinessSector], NULL AS [Type], NULL AS [HistoryType],
        NULL AS [CreditID], NULL AS [AuthorID], NULL AS [Author], NULL AS [Purpose],
        NULL AS [IsGreen], NULL AS [ClientID], NULL AS [CreditAmount],
        NULL AS [RefusalReason], NULL AS [CreditProduct], NULL AS [ProductID],
        NULL AS [CreditProductID], NULL AS [InternetID], NULL AS [EmployeeID], NULL AS [BranchID],
        NULL AS [PartnerID], NULL AS [Partner],
        --COALESCE(o.[ОбъединеннаяИнтернетЗаявка ID], CAST(NEWID() AS VARCHAR(36))) AS [WebID],
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
        ) AS ClientKey,
        NULL AS [CommitteeDecisionDate]   -- ✅ fixed here
    FROM [ATK].[mis].[Silver_Документы.ОбъединеннаяИнтернетЗаявка] o
    LEFT JOIN [ATK].[mis].[Silver_Документы.ЗаявкаНаКредит] z
        ON z.[ЗаявкаНаКредит ID] = o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
    WHERE z.[ЗаявкаНаКредит ID] IS NULL
       OR o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID] = '00000000000000000000000000000000'
)

-----------------------------------------------------------------------------------
-- 4️⃣ Insert into final GOLD table, excluding test clients
-----------------------------------------------------------------------------------
INSERT INTO mis.[2tbl_Gold_Fact_CerereOnline]
(
    [ID],[Date],[Status],[Posted],[BusinessSector],[Type],[HistoryType],
    [CreditID],[AuthorID],[Author],[Purpose],[IsGreen],[ClientID],[CreditAmount],[NewExisting_Client],
    [RefusalReason],[CreditProduct],[ProductID],[CreditProductID],[InternetID],[EmployeeID],[BranchID],
    [PartnerID],[Partner],
    --[WebID],
	[WebDate],[WebNr],[WebPosted],[WebIncomeTypeOnline],[WebAge],
    [WebSubmissionDate],[WebCredit],[WebIdentifier],[WebCreditEmployee],[WebMobilePhone],
    [WebSentForReview],[WebGender],[WebStatus],[WebCreditTerm],[WebBranchID],[CommitteeDecisionDate]
)
SELECT
    b.[ID], b.[Date], b.[Status], b.[Posted],
    b.[BusinessSector], b.[Type], b.[HistoryType],
    b.[CreditID], b.[AuthorID], b.[Author], b.[Purpose],
    b.[IsGreen], b.[ClientID], b.[CreditAmount],
    CASE
        WHEN b.CreditAmount IS NULL OR b.CreditAmount <= 0 THEN N'Cancelled'
        WHEN ROW_NUMBER() OVER (PARTITION BY b.ClientKey ORDER BY b.WebDate) = 1 THEN N'New'
        ELSE N'Existing'
    END AS [NewExisting_Client],
    b.[RefusalReason], b.[CreditProduct], b.[ProductID], b.[CreditProductID],
    b.[InternetID], b.[EmployeeID], b.[BranchID],
    b.[PartnerID], b.[Partner],
    --b.[WebID], 
	b.[WebDate], b.[WebNr], b.[WebPosted], b.[WebIncomeTypeOnline], b.[WebAge],
    b.[WebSubmissionDate], b.[WebCredit], b.[WebIdentifier], b.[WebCreditEmployee], b.[WebMobilePhone],
    b.[WebSentForReview], b.[WebGender], b.[WebStatus], b.[WebCreditTerm], b.[WebBranchID],
    b.[CommitteeDecisionDate]
FROM Base b
LEFT JOIN dbo.[Справочники.Контрагенты] AS c
    ON b.[ClientID] = c.[Контрагенты ID]
WHERE c.[Контрагенты Тестовый Контрагент] = 00;
GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.2tbl_Gold_Fact_CerereOnline.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.2tbl_Gold_Fact_CreditsInShadowBranches.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO


IF OBJECT_ID('mis.[2tbl_Gold_CreditsInShadowBranches]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_CreditsInShadowBranches];
GO

CREATE TABLE mis.[2tbl_Gold_CreditsInShadowBranches] (
    Period DATETIME NULL,
    ID VARCHAR(32) NOT NULL,
    RowNumber INT NULL,
    Active VARCHAR(36) NULL,
    CreditID VARCHAR(32) NULL,
    Credit NVARCHAR(100) NULL,
    BranchID VARCHAR(32) NULL,
    Branch NVARCHAR(100) NULL,
    CreditEmployeeID VARCHAR(32) NULL,
    CreditEmployee NVARCHAR(100) NULL,
    DateTo DATETIME NULL
);
GO

;WITH src AS (
    SELECT
          rs.[КредитыВТеневыхФилиалах Период]                 AS Period,
          rs.[КредитыВТеневыхФилиалах ID]                     AS ID,
          rs.[КредитыВТеневыхФилиалах Номер Строки]           AS RowNumber,
          rs.[КредитыВТеневыхФилиалах Активность]             AS Active,
          rs.[КредитыВТеневыхФилиалах Кредит ID]              AS CreditID,
          rs.[КредитыВТеневыхФилиалах Кредит]                 AS Credit,
          rs.[КредитыВТеневыхФилиалах Филиал ID]              AS BranchID,
          rs.[КредитыВТеневыхФилиалах Филиал]                 AS Branch,
          rs.[КредитыВТеневыхФилиалах Кредитный Эксперт ID]   AS CreditEmployeeID,
          rs.[КредитыВТеневыхФилиалах Кредитный Эксперт]      AS CreditEmployee
    FROM [ATK].[mis].[Silver_РегистрыСведений.КредитыВТеневыхФилиалах] rs
	WHERE rs.[КредитыВТеневыхФилиалах Период] >= '2023-01-01'
),
calc AS (
    SELECT
          Period,
          ID,
          RowNumber,
          Active,
          CreditID,
          Credit,
          BranchID,
          Branch,
          CreditEmployeeID,
          CreditEmployee,
          LEAD(Period) OVER (
              PARTITION BY CreditID
              ORDER BY Period, RowNumber
          ) AS DateTo
    FROM src
)
INSERT INTO mis.[2tbl_Gold_CreditsInShadowBranches] (
      Period,
      ID,
      RowNumber,
      Active,
      CreditID,
      Credit,
      BranchID,
      Branch,
      CreditEmployeeID,
      CreditEmployee,
      DateTo
)
SELECT
      Period,
      ID,
      RowNumber,
      Active,
      CreditID,
      Credit,
      BranchID,
      Branch,
      CreditEmployeeID,
      CreditEmployee,
      DateTo
FROM calc;

GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.2tbl_Gold_Fact_CreditsInShadowBranches.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.2tbl_Gold_Fact_Disbursement.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO

/* ============================
   Clean up temp tables & target table
   ============================ */
IF OBJECT_ID('tempdb..#Base')   IS NOT NULL DROP TABLE #Base;
IF OBJECT_ID('tempdb..#Status') IS NOT NULL DROP TABLE #Status;
IF OBJECT_ID('tempdb..#Final')  IS NOT NULL DROP TABLE #Final;

IF OBJECT_ID('mis.[2tbl_Gold_Fact_Disbursement]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Fact_Disbursement];
GO

/* ============================
   Create target table
   ============================ */
CREATE TABLE mis.[2tbl_Gold_Fact_Disbursement] 
(
    CreditID           NVARCHAR(36)   NOT NULL,
    ClientID           NVARCHAR(36)   NULL,
    DisbursementDate   DATETIME2      NULL,
    CurrencyID         NVARCHAR(36)   NULL,
    CreditAmount       DECIMAL(18,2)  NULL,
    CreditAmountInMDL  DECIMAL(18,2)  NULL,
    CreditCurrency     NVARCHAR(50)   NULL,
    FirstFilialID      NVARCHAR(36)   NULL,
    FirstEmployeeID    NVARCHAR(36)   NULL,
    LastFilialID       NVARCHAR(36)   NULL,
    LastEmployeeID     NVARCHAR(36)   NULL,
    IRR                DECIMAL(18,2)  NULL,
    IRR_Client         DECIMAL(18,2)  NULL,
    Qty                INT            NULL,
    NewExisting_Client NVARCHAR(20)   NULL,
    EmployeePositionID NVARCHAR(36)   NULL,
    CreatedAt          DATETIME       NOT NULL DEFAULT GETDATE()
);
GO

/* ============================
   Build #Base
   Include last EmployeePositionID based on latest period
   ============================ */
SELECT
    d.[ДанныеКредитовВыданных Кредит ID]                 AS CreditID,
    k.[Кредиты Владелец]                                 AS ClientID,
    d.[ДанныеКредитовВыданных Дата Выдачи]               AS DisbursementDate,
    d.[ДанныеКредитовВыданных Валюта Кредита ID]         AS CurrencyID,
    d.[ДанныеКредитовВыданных Сумма Кредита]             AS CreditAmount,
    ROUND(d.[ДанныеКредитовВыданных Сумма Кредита] * ISNULL(rate.Rate, 1), 2) AS CreditAmountInMDL,
    d.[ДанныеКредитовВыданных Валюта Кредита]            AS CreditCurrency,
    firstR.[ФилиалID]                                     AS FirstFilialID,
    firstR.[ЭкспертID]                                    AS FirstEmployeeID,
    COALESCE(lastR_month.[ФилиалID], firstR.[ФилиалID])   AS LastFilialID,
    COALESCE(lastR_month.[ЭкспертID], firstR.[ЭкспертID]) AS LastEmployeeID,
    irr.IRR                                               AS IRR,
    irr.IRR_Client                                        AS IRR_Client,
    emp.EmployeePositionID                                 AS EmployeePositionID,
    rn = ROW_NUMBER() OVER (
            PARTITION BY d.[ДанныеКредитовВыданных Кредит ID]
            ORDER BY d.[ДанныеКредитовВыданных Дата Выдачи]
         )
INTO #Base
FROM [ATK].[mis].[Silver_РегистрыСведений.ДанныеКредитовВыданных] d
INNER JOIN [ATK].[mis].[Silver_Справочники.Кредиты] k
    ON k.[Кредиты ID] = d.[ДанныеКредитовВыданных Кредит ID]
OUTER APPLY (
    SELECT TOP 1 v.[Валюта Курс] AS Rate
    FROM [ATK].[mis].[Silver_РегистрыСведений.Валюта] v
    WHERE v.[Валюта Валюта ID] = d.[ДанныеКредитовВыданных Валюта Кредита ID]
      AND v.[Валюта Период] <= d.[ДанныеКредитовВыданных Период]
    ORDER BY v.[Валюта Период] DESC
) rate
OUTER APPLY (
    SELECT TOP 1
           r.[ОтветственныеПоКредитамВыданным Филиал ID]            AS [ФилиалID],
           r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID]  AS [ЭкспертID]
    FROM [ATK].[mis].[Silver_РегистрыСведений.ОтветственныеПоКредитамВыданным] r
    WHERE r.[ОтветственныеПоКредитамВыданным Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
    ORDER BY r.[ОтветственныеПоКредитамВыданным Период] ASC
) firstR
OUTER APPLY (
    SELECT TOP 1
           r.[ОтветственныеПоКредитамВыданным Филиал ID]            AS [ФилиалID],
           r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID]  AS [ЭкспертID]
    FROM [ATK].[mis].[Silver_РегистрыСведений.ОтветственныеПоКредитамВыданным] r
    WHERE r.[ОтветственныеПоКредитамВыданным Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
      AND r.[ОтветственныеПоКредитамВыданным Период] <= EOMONTH(d.[ДанныеКредитовВыданных Дата Выдачи])
    ORDER BY r.[ОтветственныеПоКредитамВыданным Период] DESC
) lastR_month
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
OUTER APPLY (
    -- Get last EmployeePositionID based on latest period
    SELECT TOP 1 e.[СотрудникиДанныеПоЗарплате Должность ID] AS EmployeePositionID
    FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате] e
    WHERE e.[СотрудникиДанныеПоЗарплате Сотрудник ID] = COALESCE(lastR_month.[ЭкспертID], firstR.[ЭкспертID])
    ORDER BY e.[СотрудникиДанныеПоЗарплате Период] DESC
) emp
WHERE d.[ДанныеКредитовВыданных Кредитный Продукт] NOT LIKE N'Medier%'
  AND d.[ДанныеКредитовВыданных Дата Выдачи] >= '2024-01-01';
GO

/* ============================
   Build #Status (cancel/restore)
   ============================ */
WITH BaseIDs AS (
    SELECT DISTINCT CreditID FROM #Base
),
Cancels AS (
    SELECT a.[АнулированныеКредитыПартнеров Кредит ID] AS CreditID,
           MAX(a.[АнулированныеКредитыПартнеров Период]) AS CancelPeriod
    FROM [ATK].[mis].[Silver_РегистрыСведений.АнулированныеКредитыПартнеров] a
    INNER JOIN BaseIDs b ON b.CreditID = a.[АнулированныеКредитыПартнеров Кредит ID]
    WHERE a.[АнулированныеКредитыПартнеров Кредит Анулирован] = N'01'
    GROUP BY a.[АнулированныеКредитыПартнеров Кредит ID]
),
Restores AS (
    SELECT a.[АнулированныеКредитыПартнеров Кредит ID] AS CreditID,
           MAX(a.[АнулированныеКредитыПартнеров Период]) AS RestorePeriod
    FROM [ATK].[mis].[Silver_РегистрыСведений.АнулированныеКредитыПартнеров] a
    INNER JOIN BaseIDs b ON b.CreditID = a.[АнулированныеКредитыПартнеров Кредит ID]
    WHERE a.[АнулированныеКредитыПартнеров Кредит Восстановлен] = N'00'
    GROUP BY a.[АнулированныеКредитыПартнеров Кредит ID]
)
SELECT b.CreditID,
       c.CancelPeriod,
       r.RestorePeriod
INTO #Status
FROM BaseIDs b
LEFT JOIN Cancels  c ON c.CreditID = b.CreditID
LEFT JOIN Restores r ON r.CreditID = b.CreditID;
GO

/* ============================
   Build #Final
   ============================ */
SELECT
    b.CreditID, b.ClientID, b.DisbursementDate, b.CurrencyID,
    b.CreditAmount, b.CreditAmountInMDL, b.CreditCurrency,
    b.FirstFilialID, b.FirstEmployeeID, b.LastFilialID, b.LastEmployeeID,
    b.IRR, b.IRR_Client, 1 AS Qty,
    b.EmployeePositionID
INTO #Final
FROM #Base b
WHERE b.rn = 1;

-- Cancel rows
INSERT INTO #Final
SELECT
    b.CreditID, b.ClientID, s.CancelPeriod, b.CurrencyID,
    -b.CreditAmount, -b.CreditAmountInMDL, b.CreditCurrency,
    b.FirstFilialID, b.FirstEmployeeID, b.LastFilialID, b.LastEmployeeID,
    b.IRR, b.IRR_Client, -1 AS Qty,
    b.EmployeePositionID
FROM #Status s
JOIN #Base b ON b.CreditID = s.CreditID AND b.rn = 1
WHERE s.CancelPeriod IS NOT NULL
  AND s.CancelPeriod >= b.DisbursementDate;

-- Restore rows
INSERT INTO #Final
SELECT
    b.CreditID, b.ClientID, s.RestorePeriod, b.CurrencyID,
    b.CreditAmount, b.CreditAmountInMDL, b.CreditCurrency,
    b.FirstFilialID, b.FirstEmployeeID, b.LastFilialID, b.LastEmployeeID,
    b.IRR, b.IRR_Client, 1 AS Qty,
    b.EmployeePositionID
FROM #Status s
JOIN #Base b ON b.CreditID = s.CreditID AND b.rn = 1
WHERE s.RestorePeriod IS NOT NULL
  AND s.RestorePeriod >= b.DisbursementDate
  AND (s.CancelPeriod IS NULL OR s.RestorePeriod > s.CancelPeriod);
GO

/* ============================
   Insert into final table
   Exclude test clients
   ============================ */
WITH AllSeq AS (
    SELECT
        f.*,
        ROW_NUMBER() OVER (
            PARTITION BY f.ClientID
            ORDER BY f.DisbursementDate, f.CreditID
        ) AS rn_all
    FROM #Final f
)
INSERT INTO mis.[2tbl_Gold_Fact_Disbursement]
(
    CreditID, ClientID, DisbursementDate, CurrencyID, CreditAmount, CreditAmountInMDL,
    CreditCurrency, FirstFilialID, FirstEmployeeID, LastFilialID, LastEmployeeID,
    IRR, IRR_Client, Qty, NewExisting_Client, EmployeePositionID
)
SELECT
    a.CreditID, a.ClientID, a.DisbursementDate, a.CurrencyID, a.CreditAmount, a.CreditAmountInMDL,
    a.CreditCurrency, a.FirstFilialID, a.FirstEmployeeID, a.LastFilialID, a.LastEmployeeID,
    a.IRR, a.IRR_Client, a.Qty,
    CASE
        WHEN a.CreditAmount > 0 AND a.rn_all = 1 THEN N'New'
        WHEN a.CreditAmount > 0 THEN N'Existing'
        ELSE N'Cancelled'
    END AS NewExisting_Client,
    a.EmployeePositionID
FROM AllSeq AS a
LEFT JOIN dbo.[Справочники.Контрагенты] AS c
    ON a.ClientID = c.[Контрагенты ID]
WHERE c.[Контрагенты Тестовый Контрагент] = 00;
GO

/* ============================
   Indexes
   ============================ */
CREATE CLUSTERED INDEX CIX_Disbursement_DisbursementDate_ClientID
ON mis.[2tbl_Gold_Fact_Disbursement] (DisbursementDate ASC, ClientID ASC);

CREATE NONCLUSTERED INDEX IX_Disbursement_CreditID
ON mis.[2tbl_Gold_Fact_Disbursement] (CreditID);

CREATE NONCLUSTERED INDEX IX_Disbursement_FirstFilialID
ON mis.[2tbl_Gold_Fact_Disbursement] (FirstFilialID);

CREATE NONCLUSTERED INDEX IX_Disbursement_LastFilialID
ON mis.[2tbl_Gold_Fact_Disbursement] (LastFilialID);

CREATE NONCLUSTERED INDEX IX_Disbursement_NewExisting
ON mis.[2tbl_Gold_Fact_Disbursement] (NewExisting_Client);

CREATE NONCLUSTERED INDEX IX_Disbursement_ClientID
ON mis.[2tbl_Gold_Fact_Disbursement] (ClientID);
GO

/* ============================
   Cleanup temp tables
   ============================ */
DROP TABLE #Base;
DROP TABLE #Status;
DROP TABLE #Final;
GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.2tbl_Gold_Fact_Disbursement.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.2tbl_Gold_Fact_Sold_Par.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
SET NOCOUNT ON;

DECLARE @DateFrom DATE = '2024-01-01';

-----------------------------------------------------
-- Drop & recreate main GOLD table
-----------------------------------------------------
DROP TABLE IF EXISTS mis.[2tbl_Gold_Fact_Sold_Par];

CREATE TABLE mis.[2tbl_Gold_Fact_Sold_Par] (
    SoldDate      DATE         NOT NULL,
    CreditID      VARCHAR(36)  NOT NULL,
    SoldAmount    DECIMAL(18,2) NULL,
    IRR_Values    DECIMAL(18,6) NULL,
    BranchShadow  NVARCHAR(100) NULL,
    EmployeeID      VARCHAR(36)  NULL,
    BranchID      VARCHAR(36)  NULL,
    EmployeePositionID VARCHAR(36) NULL,
    Par_0_IFRS    DECIMAL(18,6) NULL,
    Par_30_IFRS   DECIMAL(18,6) NULL,
    Par_60_IFRS   DECIMAL(18,6) NULL,
    Par_90_IFRS   DECIMAL(18,6) NULL
) WITH (DATA_COMPRESSION = PAGE);

-----------------------------------------------------
-- Step 1: Max Past Days (explicit temp table)
-----------------------------------------------------
IF OBJECT_ID('tempdb..#MaxPastDays') IS NOT NULL DROP TABLE #MaxPastDays;
CREATE TABLE #MaxPastDays (
    OwnerID   VARCHAR(36) NOT NULL,
    ParDate   DATE        NOT NULL,
    MaxPastDays INT       NULL
);

INSERT INTO #MaxPastDays (OwnerID, ParDate, MaxPastDays)
SELECT 
    k.[Кредиты Владелец] AS OwnerID,
    sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS ParDate,
    MAX(sd.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого]) AS MaxPastDays
FROM mis.[Silver_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] sd
LEFT JOIN mis.[Silver_Справочники.Кредиты] k
  ON k.[Кредиты ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
WHERE sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] <> 0
  AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= @DateFrom
GROUP BY k.[Кредиты Владелец], sd.[СуммыЗадолженностиПоПериодамПросрочки Дата];

CREATE UNIQUE NONCLUSTERED INDEX IX_MaxPastDays_Owner_ParDate ON #MaxPastDays (OwnerID, ParDate);

-----------------------------------------------------
-- Step 2: Shadow Branch (explicit temp table)
-----------------------------------------------------
IF OBJECT_ID('tempdb..#ShadowBranch') IS NOT NULL DROP TABLE #ShadowBranch;
CREATE TABLE #ShadowBranch (
    CreditID     VARCHAR(36)  NOT NULL,
    BranchShadow NVARCHAR(100) NULL,
    Period       DATE         NULL
);

INSERT INTO #ShadowBranch (CreditID, BranchShadow, Period)
SELECT 
    x.[КредитыВТеневыхФилиалах Кредит ID] AS CreditID,
    x.[КредитыВТеневыхФилиалах Филиал] AS BranchShadow,
    x.[КредитыВТеневыхФилиалах Период] AS Period
FROM mis.[Silver_РегистрыСведений.КредитыВТеневыхФилиалах] x;

CREATE NONCLUSTERED INDEX IX_Shadow_Credit_Period ON #ShadowBranch (CreditID, Period);

-----------------------------------------------------
-- Step 3: Responsible / Employee (explicit temp table)
-----------------------------------------------------
IF OBJECT_ID('tempdb..#Responsible') IS NOT NULL DROP TABLE #Responsible;
CREATE TABLE #Responsible (
    CreditID VARCHAR(36) NOT NULL,
    EmployeeID VARCHAR(36) NULL,
    BranchID VARCHAR(36) NULL,
    Period   DATE        NULL
);

INSERT INTO #Responsible (CreditID, EmployeeID, BranchID, Period)
SELECT
    r.[ОтветственныеПоКредитамВыданным Кредит ID] AS CreditID,
    r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS EmployeeID,
    r.[ОтветственныеПоКредитамВыданным Филиал ID] AS BranchID,
    r.[ОтветственныеПоКредитамВыданным Период] AS Period
FROM mis.[Silver_РегистрыСведений.ОтветственныеПоКредитамВыданным] r;

CREATE NONCLUSTERED INDEX IX_Resp_Credit_Period ON #Responsible (CreditID, Period);

-----------------------------------------------------
-- Step 3.1: Employee Position (explicit temp table) - OPTIMIZED
-----------------------------------------------------
IF OBJECT_ID('tempdb..#EmployeePos') IS NOT NULL DROP TABLE #EmployeePos;
CREATE TABLE #EmployeePos (
    EmployeeID VARCHAR(36) NOT NULL,
    PositionID VARCHAR(36) NULL,
    Period DATE NULL
);

-- Only employees present in #Responsible and recent periods
INSERT INTO #EmployeePos (EmployeeID, PositionID, Period)
SELECT
    emp.[СотрудникиДанныеПоЗарплате Сотрудник ID] AS EmployeeID,
    emp.[СотрудникиДанныеПоЗарплате Должность ID] AS PositionID,
    emp.[СотрудникиДанныеПоЗарплате Период] AS Period
FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате] emp
INNER JOIN (
    SELECT DISTINCT EmployeeID
    FROM #Responsible
    WHERE EmployeeID IS NOT NULL
) rlist
  ON emp.[СотрудникиДанныеПоЗарплате Сотрудник ID] = rlist.EmployeeID
WHERE emp.[СотрудникиДанныеПоЗарплате Период] >= DATEADD(year,-1,@DateFrom);

CREATE CLUSTERED INDEX CX_EmployeePos_Emp_Period 
ON #EmployeePos (EmployeeID, Period);

-----------------------------------------------------
-- Step 4: IRR (keep all records, we'll choose top-1 per sold row via OUTER APPLY)
-----------------------------------------------------
IF OBJECT_ID('tempdb..#IRR') IS NOT NULL DROP TABLE #IRR;
CREATE TABLE #IRR (
    CreditID VARCHAR(36) NOT NULL,
    IRR_Year DECIMAL(18,6) NULL,
    IRR_Client DECIMAL(18,6) NULL,
    IRRDate DATETIME2 NULL
);

INSERT INTO #IRR (CreditID, IRR_Year, IRR_Client, IRRDate)
SELECT
    i.[УстановкаДанныхКредита Кредит ID] AS CreditID,
    i.[УстановкаДанныхКредита Внутренняя Норма Доходности Годовая] AS IRR_Year,
    i.[УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая] AS IRR_Client,
    i.[УстановкаДанныхКредита Дата] AS IRRDate
FROM mis.[Silver_Документы.УстановкаДанныхКредита] i
WHERE i.[УстановкаДанныхКредита Кредит ID] IS NOT NULL;

-- helpful index to speed the OUTER APPLY lookup
CREATE NONCLUSTERED INDEX IX_IRR_Credit_Date ON #IRR (CreditID, IRRDate DESC);

-----------------------------------------------------
-- Prepare ranges (ValidFrom, ValidTo) for Responsible, ShadowBranch & EmployeePos
-- and perform final insert (CTEs immediately followed by INSERT)
-----------------------------------------------------
;WITH RespRanges AS (
    SELECT 
        CreditID,
        EmployeeID,
        BranchID,
        Period AS ValidFrom,
        LEAD(Period) OVER (PARTITION BY CreditID ORDER BY Period) AS ValidTo
    FROM #Responsible
),
ShadowRanges AS (
    SELECT
        CreditID,
        BranchShadow,
        Period AS ValidFrom,
        LEAD(Period) OVER (PARTITION BY CreditID ORDER BY Period) AS ValidTo
    FROM #ShadowBranch
),
EmpPosRanges AS (
    SELECT
        EmployeeID,
        PositionID,
        Period AS ValidFrom,
        LEAD(Period) OVER (PARTITION BY EmployeeID ORDER BY Period) AS ValidTo
    FROM #EmployeePos
)
INSERT INTO mis.[2tbl_Gold_Fact_Sold_Par] WITH (TABLOCK)
(
    SoldDate, CreditID, SoldAmount, IRR_Values, BranchShadow, EmployeeID, BranchID, EmployeePositionID,
    Par_0_IFRS, Par_30_IFRS, Par_60_IFRS, Par_90_IFRS
)
SELECT
    sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS SoldDate,
    sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
    sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] AS SoldAmount,
    
    -- IRR Values: pick latest IRR (by datetime) whose date <= SoldDate (cast to date)
    ROUND(
        COALESCE(
            CASE 
                WHEN irr.IRR_Year IS NOT NULL AND irr.IRR_Year < 100 
                    THEN irr.IRR_Year
                ELSE irr.IRR_Client
            END,
            0
        )
        * sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит], 2
    ) AS IRR_Values,
    
    -- BranchShadow from ranges
    sh.BranchShadow,
    
    -- EmployeeID and BranchID from ranges
    r.EmployeeID,
    r.BranchID,
    empPos.PositionID AS EmployeePositionID,

    -- ParNas IFRS buckets
    CASE WHEN mpd.MaxPastDays > 0  THEN sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE 0 END AS Par_0_IFRS,
    CASE WHEN mpd.MaxPastDays > 30 THEN sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE 0 END AS Par_30_IFRS,
    CASE WHEN mpd.MaxPastDays > 60 THEN sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE 0 END AS Par_60_IFRS,
    CASE WHEN mpd.MaxPastDays > 90 THEN sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE 0 END AS Par_90_IFRS

FROM mis.[Silver_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] sd
JOIN mis.[Silver_Справочники.Кредиты] k
  ON k.[Кредиты ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]

-- MaxPastDays
LEFT JOIN #MaxPastDays mpd
  ON mpd.OwnerID = k.[Кредиты Владелец]
 AND mpd.ParDate = sd.[СуммыЗадолженностиПоПериодамПросрочки Дата]

-- Responsible: range join
LEFT JOIN RespRanges r
    ON r.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
   AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= r.ValidFrom
   AND (r.ValidTo IS NULL OR sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] < r.ValidTo)

-- Employee Position: range join
LEFT JOIN EmpPosRanges empPos
    ON empPos.EmployeeID = r.EmployeeID
   AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= empPos.ValidFrom
   AND (empPos.ValidTo IS NULL OR sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] < empPos.ValidTo)

-- Shadow Branch: range join
LEFT JOIN ShadowRanges sh
    ON sh.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
   AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= sh.ValidFrom
   AND (sh.ValidTo IS NULL OR sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] < sh.ValidTo)

-- IRR: pick latest per sold row (no row multiplication)
OUTER APPLY (
    SELECT TOP (1) i.IRR_Year, i.IRR_Client
    FROM #IRR i
    WHERE i.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
      AND CAST(i.IRRDate AS DATE) <= CAST(sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS DATE)
    ORDER BY i.IRRDate DESC
) AS irr

WHERE sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] <> 0
AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= @DateFrom;

-----------------------------------------------------
-- Columnstore
-----------------------------------------------------
CREATE CLUSTERED COLUMNSTORE INDEX CCSI_2tbl_Gold_Fact_Sold_Par
ON mis.[2tbl_Gold_Fact_Sold_Par];

-----------------------------------------------------
-- Drop temp tables
-----------------------------------------------------
DROP TABLE IF EXISTS #MaxPastDays, #ShadowBranch, #Responsible, #IRR, #EmployeePos;
----------------------------------------------------------------------------------------------------
-- End of:   mis.2tbl_Gold_Fact_Sold_Par.sql
----------------------------------------------------------------------------------------------------

GO

