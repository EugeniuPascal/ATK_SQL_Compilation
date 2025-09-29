-- =============================================
-- Compiled Stored Procedure for MSSQL Agent Job (Gold) - Idempotent
-- Generated: 2025-09-29 09:13:31.481578
-- Source folder: C:\ATK_Project\sql_scripts\Gold
-- Files included: 14
--   mis.2tbl_Gold_Dim_AppUsers.sql
--   mis.2tbl_Gold_Dim_Branch.sql
--   mis.2tbl_Gold_Dim_Clients.sql
--   mis.2tbl_Gold_Dim_Credits.sql
--   mis.2tbl_Gold_Dim_Experts.sql
--   mis.2tbl_Gold_Dim_ExpertsHistory.sql
--   mis.2tbl_Gold_Dim_PartnersBranch.sql
--   mis.2tbl_Gold_Fact_BudgetExperts.sql
--   mis.2tbl_Gold_Fact_CerereCredit.sql
--   mis.2tbl_Gold_Fact_CerereOnline.sql
--   mis.2tbl_Gold_Fact_CerereOnline_1.sql
--   mis.2tbl_Gold_Fact_CreditsInShadowBranches.sql
--   mis.2tbl_Gold_Fact_Disbursement.sql
--   mis.2tbl_Gold_Fact_Sold_Par.sql
-- Requires: SQL Server 2016 SP1+ for CREATE OR ALTER
-- =============================================

USE [ATK];
GO

IF OBJECT_ID('mis.usp_CompileGoldTables', 'P') IS NOT NULL
    DROP PROCEDURE mis.usp_CompileGoldTables;
GO

CREATE PROCEDURE mis.usp_CompileGoldTables
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @sql NVARCHAR(MAX);

    -- Start of: mis.2tbl_Gold_Dim_AppUsers.sql
    SET @sql = N'IF OBJECT_ID(''mis.[2tbl_Gold_Dim_AppUsers]'', ''U'') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_AppUsers];

IF OBJECT_ID(N''[mis].[2tbl_Gold_Dim_AppUsers]'',''U'') IS NOT NULL DROP TABLE [mis].[2tbl_Gold_Dim_AppUsers];
CREATE TABLE [mis].[2tbl_Gold_Dim_AppUsers]
(
    App_User_ClientID VARCHAR(36) NOT NULL,
    App_User_UserID VARCHAR(36) NOT NULL,
    App_User_Phone NVARCHAR(50) NULL,
    App_User_FiscalCode NVARCHAR(20) NULL,
    App_User_ClientName NVARCHAR(100) NULL
);

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

FROM [ATK].[mis].[Silver_РегистрыСведений.СведенияОПользователяхМобильногоПриложения];';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.2tbl_Gold_Dim_Branch.sql
    SET @sql = N'-- Drop the table if it exists
IF OBJECT_ID(N''mis.[2tbl_Gold_Dim_Branch]'', ''U'') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_Branch];

-- Create the table
IF OBJECT_ID(N''[mis].[2tbl_Gold_Dim_Branch]'',''U'') IS NOT NULL DROP TABLE [mis].[2tbl_Gold_Dim_Branch];
CREATE TABLE [mis].[2tbl_Gold_Dim_Branch](
    BranchID VARCHAR(36) NOT NULL,
    BranchCode DECIMAL(2, 0) NULL,
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
    AND s.rn = 1;';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.2tbl_Gold_Dim_Clients.sql
    SET @sql = N'SET NOCOUNT ON;

-- Drop the table if it exists
IF OBJECT_ID(N''mis.[2tbl_Gold_Dim_Clients]'', ''U'') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_Clients];

-- Create the table
IF OBJECT_ID(N''[mis].[2tbl_Gold_Dim_Clients]'',''U'') IS NOT NULL DROP TABLE [mis].[2tbl_Gold_Dim_Clients];
CREATE TABLE [mis].[2tbl_Gold_Dim_Clients](
    [ClientID]              VARCHAR(36)    NOT NULL,
    [ParentID]              VARCHAR(36)    NOT NULL,
    [BranchID]              VARCHAR(36)    NULL,
    [IsDeleted]             VARCHAR(36)    NULL,
    [IsGroup]               VARCHAR(36)    NULL,
    [ClientCode]            NCHAR(13)      NULL,
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
    [MobilePhone1]          NVARCHAR(9)    NULL,
    [MobilePhone2]          NVARCHAR(9)    NULL,
    [Phones]                NVARCHAR(50)   NULL,
    [FiscalCode]            NVARCHAR(20)   NULL,
    [LegalAddress]          NVARCHAR(85)   NULL,
    [RegistrationDate]      DATETIME2(0)   NULL,
    [Language]              NVARCHAR(25)   NULL,
    [NoEmailNotifications]  VARCHAR(36)    NULL,
    [NoPromoSMS]            VARCHAR(36)    NULL,
    [OrganizationType]      NVARCHAR(52)   NULL,
    [IsGroupOwner]          BIT            NULL,
    [GroupID]               NVARCHAR(5)    NULL,
    CONSTRAINT PK_2tbl_Gold_Dim_Clients PRIMARY KEY CLUSTERED (ClientID)
);

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
            WHEN r.[Контрагенты Возраст] <> ''1753-01-01 00:00:00'' THEN r.[Контрагенты Возраст]
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
            WHEN Age IS NULL THEN ''n/a''
            WHEN Age <  22 THEN ''< 22''
            WHEN Age <  25 THEN ''< 25''
            WHEN Age <  35 THEN ''< 35''
            WHEN Age <  45 THEN ''< 45''
            WHEN Age <  55 THEN ''< 55''
            WHEN Age <  65 THEN ''< 65''
            WHEN Age > 110 THEN ''n/a''
            ELSE ''> 65''
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
    Gender, PostalAddress, Country, MobilePhone1, MobilePhone2, Phones,
    FiscalCode, LegalAddress, RegistrationDate, [Language],
    NoEmailNotifications, NoPromoSMS, OrganizationType,
    IsGroupOwner, GroupID
FROM Dedup
WHERE rn = 1;

-- Indexes
CREATE NONCLUSTERED INDEX IX_Clients_Branch    ON mis.[2tbl_Gold_Dim_Clients](BranchID)   INCLUDE (ClientName, IsBlocked);
CREATE NONCLUSTERED INDEX IX_Clients_AgeGroup  ON mis.[2tbl_Gold_Dim_Clients](AgeGroup)  INCLUDE (City, Country);
CREATE NONCLUSTERED INDEX IX_Clients_IsDeleted ON mis.[2tbl_Gold_Dim_Clients](IsDeleted) INCLUDE (ClientName);
CREATE NONCLUSTERED INDEX IX_Clients_Group     ON mis.[2tbl_Gold_Dim_Clients](IsGroupOwner, GroupID);';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.2tbl_Gold_Dim_Credits.sql
    SET @sql = N'-- Drop table if exists
IF OBJECT_ID(N''mis.[2tbl_Gold_Dim_Credits]'', ''U'') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_Credits];

-- IF OBJECT_ID(N''[mis].[with DigitalSign column]'',''U'') IS NOT NULL DROP TABLE [mis].[with DigitalSign column];
CREATE TABLE [mis].[with DigitalSign column]
IF OBJECT_ID(N''[mis].[2tbl_Gold_Dim_Credits]'',''U'') IS NOT NULL DROP TABLE [mis].[2tbl_Gold_Dim_Credits];
CREATE TABLE [mis].[2tbl_Gold_Dim_Credits](
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
    [Source] NVARCHAR(50) NULL,
    [LatestOutstandingAmount] DECIMAL(18,2) NULL,
    [SegmentRevenue] NVARCHAR(50) NULL,
    [GreenCredit] VARCHAR(36) NULL,
    [CommitteeProt_CrPurpose] NVARCHAR(150) NULL,
    [CommitteeProt_AMLRiskCat] NVARCHAR(256) NULL,
    [DigitalSign] NVARCHAR(50) NULL
);

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
            NULLIF(LTRIM(RTRIM(oia.[ОбъединеннаяИнтернетЗаявка Источник Заполнения])), '''') AS Source,
            oia.[ОбъединеннаяИнтернетЗаявка Филиал ID] AS FilialID,
            oia.[ОбъединеннаяИнтернетЗаявка Кредитный Эксперт ID] AS ExpertID,
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
        MIN([ОтветственныеПоКредитамВыданным Кредитный Эксперт ID]) AS FirstExpertID,
        MAX([ОтветственныеПоКредитамВыданным Филиал ID]) AS LastFilialID,
        MAX([ОтветственныеПоКредитамВыданным Кредитный Эксперт ID]) AS LastExpertID
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
    [CreditApplicationPartnerID], [FirstFilialID], [FirstExpertID],
    [LastFilialID], [LastExpertID], [DealerID], [Source],
    [LatestOutstandingAmount], [SegmentRevenue], [GreenCredit],
    [CommitteeProt_CrPurpose], [CommitteeProt_AMLRiskCat],
    [DigitalSign] 
)
SELECT
    c.[Кредиты ID], c.[Кредиты Владелец], c.[Кредиты Код], c.[Кредиты Наименование],
    c.[Кредиты Дата Выдачи], c.[Кредиты Срок Кредита], c.[Кредиты Сумма Кредита],
    c.[Кредиты Сектор Экономики], c.[Кредиты Финансовый Продукт ID], c.[Кредиты Финансовый Продукт],
    c.[Кредиты Агро], c.[Кредиты Тип Местности], c.[Кредиты Валюта], c.[Кредиты Кредитный Продукт ID],
    c.[Кредиты Кредитный Продукт], c.[Кредиты Цель Кредита], c.[Кредиты Удалить Источник Финансирования],
    c.[Кредиты Вид Контракта], c.[Кредиты Дата Контракта], c.[Кредиты Сегмент Доходов],
    c.[Кредиты Назначение Использования Кредита], c.[Кредиты Цель Кредита Описание],
    c.[Кредиты Тип Кредитного Продукта], c.[Кредиты Сфера Использования Кредита], c.[Кредиты Источник Подписания],
    fp.FinancialProductsMainGroup,
    st.IssuedCreditsStatus,
    cr.ApplicationPartnerID,
    COALESCE(r.FirstFilialID, cr.FilialID),
    COALESCE(r.FirstExpertID, cr.ExpertID),
    COALESCE(r.LastFilialID, cr.FilialID),
    COALESCE(r.LastExpertID, cr.ExpertID),
    cr.DealerID, cr.Source,
    lo.LatestOutstandingAmount,
    seg.SegmentRevenue,
    gc.GreenCredit, gc.CommitteeProt_CrPurpose, gc.CommitteeProt_AMLRiskCat,
    CASE WHEN c.[Кредиты Источник Подписания] IS NOT NULL 
	     THEN ''True'' 
		 ELSE ''False'' 
    END AS DigitalSign
FROM Credits c
LEFT JOIN CreditRequest cr ON c.[Кредиты ID] = cr.CreditID
LEFT JOIN Resp r ON c.[Кредиты ID] = r.CreditID
LEFT JOIN FinProducts fp ON c.[Кредиты Финансовый Продукт ID] = fp.FinancialProductID
LEFT JOIN Statuses st ON c.[Кредиты ID] = st.CreditID
LEFT JOIN LatestOutstanding lo ON c.[Кредиты ID] = lo.CreditID
LEFT JOIN SegmentRevenue seg ON c.[Кредиты Кредитный Продукт ID] = seg.ProductID
LEFT JOIN GreenCredit gc ON c.[Кредиты ID] = gc.CreditID;';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.2tbl_Gold_Dim_Experts.sql
    SET @sql = N'IF OBJECT_ID(''mis.[2tbl_Gold_Dim_Experts]'', ''U'') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_Experts];

IF OBJECT_ID(N''[mis].[2tbl_Gold_Dim_Experts]'',''U'') IS NOT NULL DROP TABLE [mis].[2tbl_Gold_Dim_Experts];
CREATE TABLE [mis].[2tbl_Gold_Dim_Experts](
    [ExpertID] VARCHAR(36) NOT NULL,
    [ExpertCode] INT NULL,
    [ExpertName] NVARCHAR(40) NULL,
    [HireDate] DATETIME NULL,
    [BirthDate] DATETIME NULL,
    [DismissalDate] DATETIME NULL,
    [Position] NVARCHAR(100) NULL,
    [TimesheetNumber] INT NULL,
    [ExperienceYears] INT NULL,
    [ExperienceMonths] INT NULL,
    [EmploymentPeriod] NVARCHAR(50) NULL
);

INSERT INTO mis.[2tbl_Gold_Dim_Experts] (
    [ExpertID],
    [ExpertCode],
    [ExpertName],
    [HireDate],
    [BirthDate],
    [DismissalDate],
    [Position],
    [TimesheetNumber],
    [ExperienceYears],
    [ExperienceMonths],
    [EmploymentPeriod]
)
SELECT 
    [Сотрудники ID] AS ExpertID,
    [Сотрудники Код] AS ExpertCode,
    [Сотрудники Наименование] AS ExpertName,
    [Сотрудники Дата Приема] AS HireDate,
    [Сотрудники Дата Рождения] AS BirthDate,
    [Сотрудники Дата Увольнения] AS DismissalDate,
    [Сотрудники Должность Спр] AS Position,
    [Сотрудники Табельный Номер] AS TimesheetNumber,
    DATEDIFF(YEAR, [Сотрудники Дата Приема], GETDATE()) AS ExperienceYears,
    DATEDIFF(MONTH, [Сотрудники Дата Приема], GETDATE()) % 12 AS ExperienceMonths,
    CASE 
        WHEN [Сотрудники Дата Увольнения] IS NULL 
            THEN FORMAT([Сотрудники Дата Приема], ''yyyy-MM-dd'') + N'' → Present''
        ELSE FORMAT([Сотрудники Дата Приема], ''yyyy-MM-dd'') + N'' → '' + FORMAT([Сотрудники Дата Увольнения], ''yyyy-MM-dd'')
    END AS EmploymentPeriod
FROM [ATK].[dbo].[Справочники.Сотрудники];';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.2tbl_Gold_Dim_ExpertsHistory.sql
    SET @sql = N'IF OBJECT_ID(''mis.[2tbl_Gold_Dim_ExpertsHistory]'', ''U'') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_ExpertsHistory];

IF OBJECT_ID(N''[mis].[2tbl_Gold_Dim_ExpertsHistory]'',''U'') IS NOT NULL DROP TABLE [mis].[2tbl_Gold_Dim_ExpertsHistory];
CREATE TABLE [mis].[2tbl_Gold_Dim_ExpertsHistory](
    Period       DATETIME      NULL,
    ID           VARCHAR(36)   NOT NULL,
    RowNumber    INT           NULL,
    IsActive     VARCHAR(36)   NULL,
    Credit_ID    VARCHAR(36)   NULL,
    Credit       NVARCHAR(100) NULL,
    Filial_ID    VARCHAR(36)   NULL,
    Filial       NVARCHAR(100) NULL,
    Expert_ID    VARCHAR(36)   NULL,
    Expert       NVARCHAR(100) NULL,
    DateTo       DATETIME      NULL
);

INSERT INTO mis.[2tbl_Gold_Dim_ExpertsHistory] (
    Period,
    ID,
    RowNumber,
    IsActive,
    Credit_ID,
    Credit,
    Filial_ID,
    Filial,
    Expert_ID,
    Expert,
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
    [ОтветственныеПоКредитамВыданным Кредитный Эксперт ID]      AS Expert_ID,
    [ОтветственныеПоКредитамВыданным Кредитный Эксперт]         AS Expert,
    ISNULL(
        LEAD([ОтветственныеПоКредитамВыданным Период]) OVER (
            PARTITION BY [ОтветственныеПоКредитамВыданным Кредит ID]
            ORDER BY [ОтветственныеПоКредитамВыданным Период], [ОтветственныеПоКредитамВыданным Номер Строки]
        ),
        CONVERT(DATETIME, ''2222-01-01'', 120)
    )                                                           AS DateTo
FROM [ATK].[mis].[Silver_РегистрыСведений.ОтветственныеПоКредитамВыданным];';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.2tbl_Gold_Dim_PartnersBranch.sql
    SET @sql = N'-- Drop the gold table if it exists
IF OBJECT_ID(''mis.[2tbl_Gold_Dim_PartnersBranch]'', ''U'') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_PartnersBranch];

-- Create gold table with only essential columns
IF OBJECT_ID(N''[mis].[2tbl_Gold_Dim_PartnersBranch]'',''U'') IS NOT NULL DROP TABLE [mis].[2tbl_Gold_Dim_PartnersBranch];
CREATE TABLE [mis].[2tbl_Gold_Dim_PartnersBranch]
(
    [PartnerBranchID]               VARCHAR(36) NOT NULL,
    [PartnerBranchDeletedFlag]      VARCHAR(36) NOT NULL,
    [PartnerBranchOwner]            VARCHAR(36) NOT NULL,
    [PartnerBranchCode]             NVARCHAR(3)   NOT NULL,
    [PartnerBranchName]             NVARCHAR(150) NULL,
    [PartnerBranchAddress]          NVARCHAR(100) NULL,

    [DealerID]                      VARCHAR(36) NULL,
    [DealerDefaultExpertID]         VARCHAR(36) NULL,
    [DealerDefaultExpertName]       NVARCHAR(50) NULL,
    [DealerOrgRepID]                VARCHAR(36) NULL,
    [DealerOrgRepName]              NVARCHAR(50) NULL

);

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
    [DealerDefaultExpertID],
    [DealerDefaultExpertName],
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
    d.[Дилеры Эксперт по Умолчанию ID] AS DealerDefaultExpertID ,
    d.[Дилеры Эксперт по Умолчанию] AS DealerDefaultExpertName,
    d.[Дилеры Представитель Организации ID] AS DealerOrgRepID,
    d.[Дилеры Представитель Организации] AS DealerOrgRepName
FROM mis.[Silver_Справочники.ФилиалыКонтрагентов] f
LEFT JOIN mis.[Silver_Справочники.Дилеры] d
  ON d.[Дилеры Владелец] = f.[ФилиалыКонтрагентов ID];';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.2tbl_Gold_Fact_BudgetExperts.sql
    SET @sql = N'IF OBJECT_ID(''mis.[2tbl_Gold_Fact_BudgetExperts]'', ''U'') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Fact_BudgetExperts];

IF OBJECT_ID(N''[mis].[2tbl_Gold_Fact_BudgetExperts]'',''U'') IS NOT NULL DROP TABLE [mis].[2tbl_Gold_Fact_BudgetExperts];
CREATE TABLE [mis].[2tbl_Gold_Fact_BudgetExperts](
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

INSERT INTO mis.[2tbl_Gold_Fact_BudgetExperts]
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
WHERE d.[БюджетПоСотрудникам Дата] >= ''2023-01-01'';';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.2tbl_Gold_Fact_CerereCredit.sql
    SET @sql = N'IF OBJECT_ID(''mis.[2tbl_Gold_Fact_CerereCredit]'', ''U'') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Fact_CerereCredit];

IF OBJECT_ID(N''[mis].[2tbl_Gold_Fact_CerereCredit]'',''U'') IS NOT NULL DROP TABLE [mis].[2tbl_Gold_Fact_CerereCredit];
CREATE TABLE [mis].[2tbl_Gold_Fact_CerereCredit](
    AppID                VARCHAR(36)   NOT NULL,
    Date                 DATETIME      NULL,
    Nr                   NVARCHAR(50)  NULL,
    Posted               VARCHAR(36)   NOT NULL,
    Author               NVARCHAR(256) NULL,
    Agro                 NVARCHAR(256) NULL,
    AlternativeSector    NVARCHAR(150) NULL,
    BusinessOrg          NVARCHAR(100) NULL,
    BusinessSector       NVARCHAR(150) NULL,
    Currency             NVARCHAR(50)  NULL,
    Type                 NVARCHAR(100) NULL,
    CreditHistType       NVARCHAR(256) NULL,
    CollateralType       NVARCHAR(256) NULL,
    RefusalType          NVARCHAR(256) NULL,
    PaymentType          NVARCHAR(256) NULL,
    DebtRestructType     NVARCHAR(256) NULL,
    EnergyEffType        NVARCHAR(150) NULL,
    Dealer               NVARCHAR(150) NULL,
    ClientWebID          VARCHAR(36)   NULL,
    ClientWeb            NVARCHAR(100) NULL,
    Identifier           NVARCHAR(50)  NULL,
    ClientName           NVARCHAR(100) NULL,
    LoanPurposeCat       NVARCHAR(256) NULL,
    EnergyEffCat         NVARCHAR(150) NULL,
    ClientID             VARCHAR(36)   NULL,
    Client               NVARCHAR(100) NULL,
    FamilyTotal          INT           NULL,
    FamilyDependants     INT           NULL,
    CommitteeID          VARCHAR(36)   NULL,
    Committee            NVARCHAR(150) NULL,
    CreditID             VARCHAR(36)   NULL,
    CreditProdID         VARCHAR(36)   NULL,
    CreditExpertID       VARCHAR(36)   NULL,
    CreditExpert         NVARCHAR(50)  NULL,
    RefusalReason        NVARCHAR(200) NULL,
    CommitteeProtID      VARCHAR(36)   NULL,
    CommitteeProt        NVARCHAR(100) NULL,
    CommitteeDecision    NVARCHAR(256) NULL,
    EconSector           NVARCHAR(150) NULL,
    FinalScore           DECIMAL(10,2) NULL,
    Status               NVARCHAR(256) NULL,
    LoanTerm             INT           NULL,
    WorkExpTotal         INT           NULL,
    LoanAmount           DECIMAL(18,2) NULL,
    FinRiskLevel         DECIMAL(10,2) NULL,
    BranchID             VARCHAR(36)   NULL,
    PartnerBranch        NVARCHAR(150) NULL,
    FinProdID            VARCHAR(36)   NULL,
    FinProd              NVARCHAR(100) NULL,
    LoanPurpose          NVARCHAR(100) NULL,
    IsGreenLoan          NVARCHAR(36)  NULL
);

INSERT INTO mis.[2tbl_Gold_Fact_CerereCredit] (
    AppID, Date, Nr, Posted, Author, Agro, AlternativeSector,
    BusinessOrg, BusinessSector, Currency, Type, CreditHistType, CollateralType,
    RefusalType, PaymentType, DebtRestructType, EnergyEffType, Dealer,
    ClientWebID, ClientWeb, Identifier, ClientName, LoanPurposeCat, EnergyEffCat,
    ClientID, Client, FamilyTotal, FamilyDependants, CommitteeID, Committee,
    CreditID, CreditProdID, CreditExpertID, CreditExpert, RefusalReason,
    CommitteeProtID, CommitteeProt, CommitteeDecision, EconSector, FinalScore,
    Status, LoanTerm, WorkExpTotal, LoanAmount, FinRiskLevel,
    BranchID, PartnerBranch, FinProdID, FinProd, LoanPurpose, IsGreenLoan
)
SELECT
    [ЗаявкаНаКредит ID], [ЗаявкаНаКредит Дата], [ЗаявкаНаКредит Номер], [ЗаявкаНаКредит Проведен],
    [ЗаявкаНаКредит Автор], [ЗаявкаНаКредит Агро], [ЗаявкаНаКредит Альтернативный Сектор Экономики],
    [ЗаявкаНаКредит Бизнес Организация], [ЗаявкаНаКредит Бизнес Сектор Экономики], [ЗаявкаНаКредит Валюта],
    [ЗаявкаНаКредит Вид Заявки], [ЗаявкаНаКредит Вид Кредитной Истории], [ЗаявкаНаКредит Вид Обеспечения],
    [ЗаявкаНаКредит Вид Отказа], [ЗаявкаНаКредит Вид Перечисления], [ЗаявкаНаКредит Вид Реструктуризации Долга],
    [ЗаявкаНаКредит Вид Энергетической Эффективности], [ЗаявкаНаКредит Дилер], [ЗаявкаНаКредит Заявка Клиента Интернет ID],
    [ЗаявкаНаКредит Заявка Клиента Интернет], [ЗаявкаНаКредит Идентификатор], [ЗаявкаНаКредит Имя Клиента],
    [ЗаявкаНаКредит Категория Цель Кредита], [ЗаявкаНаКредит Категория Энергетической Эффективности],
    [ЗаявкаНаКредит Клиент ID], [ЗаявкаНаКредит Клиент], [ЗаявкаНаКредит Количество Членов Семьи Итого],
    [ЗаявкаНаКредит Количество Членов Семьи на Иждевении], [ЗаявкаНаКредит Комитет ID], [ЗаявкаНаКредит Комитет],
    [ЗаявкаНаКредит Кредит ID], [ЗаявкаНаКредит Кредитный Продукт ID], [ЗаявкаНаКредит Кредитный Эксперт ID],
    [ЗаявкаНаКредит Кредитный Эксперт], [ЗаявкаНаКредит Причина Отказа], [ЗаявкаНаКредит Протокол Комитета ID],
    [ЗаявкаНаКредит Протокол Комитета], [ЗаявкаНаКредит Решение Комитета], [ЗаявкаНаКредит Сектор Экономики],
    [ЗаявкаНаКредит Скоринг Финальная Оценка], [ЗаявкаНаКредит Состояние Заявки], [ЗаявкаНаКредит Срок Кредита],
    [ЗаявкаНаКредит Стаж Работы Общий], [ЗаявкаНаКредит Сумма Кредита], [ЗаявкаНаКредит Уровень Финансового Риска],
    [ЗаявкаНаКредит Филиал ID], [ЗаявкаНаКредит Филиал Партнера], [ЗаявкаНаКредит Финансовый Продукт ID],
    [ЗаявкаНаКредит Финансовый Продукт], [ЗаявкаНаКредит Цель Кредита], [ЗаявкаНаКредит Это Зеленый Кредит]
FROM [ATK].[mis].[Silver_Документы.ЗаявкаНаКредит]
WHERE [ЗаявкаНаКредит Проведен] = 1
AND [ЗаявкаНаКредит Дата] >= ''2023-01-01'';

CREATE NONCLUSTERED INDEX IX_CC_Date   ON mis.[2tbl_Gold_Fact_CerereCredit](Date);
CREATE NONCLUSTERED INDEX IX_CC_Client ON mis.[2tbl_Gold_Fact_CerereCredit](ClientID) 
    INCLUDE (LoanAmount, Status);';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.2tbl_Gold_Fact_CerereOnline.sql
    SET @sql = N'SET NOCOUNT ON;

-- Drop table if exists
IF OBJECT_ID(''mis.[2tbl_Gold_Fact_CerereOnline]'', ''U'') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Fact_CerereOnline];

-- IF OBJECT_ID(N''[mis].[with shortened English]'',''U'') IS NOT NULL DROP TABLE [mis].[with shortened English];
CREATE TABLE [mis].[with shortened English]-style column names
IF OBJECT_ID(N''[mis].[2tbl_Gold_Fact_CerereOnline]'',''U'') IS NOT NULL DROP TABLE [mis].[2tbl_Gold_Fact_CerereOnline];
CREATE TABLE [mis].[2tbl_Gold_Fact_CerereOnline](
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
    WHERE o.[ОбъединеннаяИнтернетЗаявка Дата] >= ''2023-01-01''
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
     WHEN CreditAmount IS NULL OR CreditAmount <= 0 THEN N''Cancelled''
     WHEN ClientOrder = 1 THEN N''New''
     ELSE N''Existing''
END AS [NewExisting_Client],
       [RefusalReason]
FROM WithCreditFlag;

-- Indexes
CREATE NONCLUSTERED INDEX IX_CO_Date
    ON mis.[2tbl_Gold_Fact_CerereOnline]([WebDate]);

CREATE NONCLUSTERED INDEX IX_CO_Client
    ON mis.[2tbl_Gold_Fact_CerereOnline]([ClientID])
    INCLUDE ([NewExisting_Client],[WebCreditAmount]);

CREATE NONCLUSTERED INDEX IX_CO_Status
    ON mis.[2tbl_Gold_Fact_CerereOnline]([WebStatus]);';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.2tbl_Gold_Fact_CerereOnline_1.sql
    SET @sql = N'SET NOCOUNT ON;

-- Drop table if exists
IF OBJECT_ID(''mis.[2tbl_Gold_Fact_CerereOnline_1]'', ''U'') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Fact_CerereOnline_1];

-- IF OBJECT_ID(N''[CREATE TABLE mis].[2tbl_Gold_Fact_CerereOnline_1]'',''U'') IS NOT NULL DROP TABLE [CREATE TABLE mis].[2tbl_Gold_Fact_CerereOnline_1];
CREATE TABLE [CREATE TABLE mis].[2tbl_Gold_Fact_CerereOnline_1](
    [ID]                    VARCHAR(36)    NULL,
    [Date]                  DATETIME       NULL,
    [Status]                NVARCHAR(256)  NULL,
    [Posted]                VARCHAR(36)    NULL,
    [BusinessSector]        NVARCHAR(150)  NULL,
    [Type]                  NVARCHAR(100)  NULL,
    [HistoryType]           NVARCHAR(256)  NULL,
    [CreditID]              VARCHAR(36)    NULL,
    [AuthorID]              VARCHAR(36)    NULL,
    [Purpose]               NVARCHAR(150)  NULL,
    [IsGreen]               NVARCHAR(36)   NULL,
    [ClientID]              VARCHAR(36)    NULL,
    [NewExisting_Client]    NVARCHAR(20)   NULL,
    [RefusalReason]         NVARCHAR(200)  NULL,
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
    --[WebCompanyFiscalCode]  NVARCHAR(50)   NULL,
    --[WebPartnerConsultant]  NVARCHAR(100)  NULL,
    [WebCreditProductID]    VARCHAR(36)    NULL,
    [WebCreditProduct]      NVARCHAR(150)  NULL,
    [WebCreditExpertID]     VARCHAR(36)    NULL,
    [WebCreditExpert]       NVARCHAR(50)   NULL,
    [WebMobilePhone]        NVARCHAR(20)   NULL,
    [WebSentForReview]      NVARCHAR(36)   NULL,
    [WebGender]             NVARCHAR(256)  NULL,
    [WebStatus]             NVARCHAR(256)  NULL,
    [WebCreditTerm]         INT            NULL,
    --[WebCreditAmount]       DECIMAL(18,2)  NULL,
    [WebBranchID]           VARCHAR(36)    NULL,
    CONSTRAINT PK_2tbl_Gold_Fact_CerereOnline_1 PRIMARY KEY CLUSTERED ([WebID])
);

;WITH Base AS (
    -- 1️⃣ Credit requests with optional linked online requests
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
        z.[ЗаявкаНаКредит Цель Кредита] AS [Purpose],
        z.[ЗаявкаНаКредит Это Зеленый Кредит] AS [IsGreen],
        z.[ЗаявкаНаКредит Клиент ID] AS [ClientID],
        z.[ЗаявкаНаКредит Сумма Кредита] AS [CreditAmount],
        z.[ЗаявкаНаКредит Причина Отказа] AS [RefusalReason],
        COALESCE(o.[ОбъединеннаяИнтернетЗаявка ID], CAST(NEWID() AS VARCHAR(36))) AS [WebID],
        o.[ОбъединеннаяИнтернетЗаявка Дата] AS [WebDate],
        o.[ОбъединеннаяИнтернетЗаявка Номер] AS [WebNr],
        o.[ОбъединеннаяИнтернетЗаявка Проведен] AS [WebPosted],
        o.[ОбъединеннаяИнтернетЗаявка Автор ID] AS [WebAuthorID],
        o.[ОбъединеннаяИнтернетЗаявка Автор] AS [WebAuthor],
        o.[ОбъединеннаяИнтернетЗаявка Вид Доходов Онлайн] AS [WebIncomeTypeOnline],
        o.[ОбъединеннаяИнтернетЗаявка Вид Интернет Заявки] AS [WebType],
        o.[ОбъединеннаяИнтернетЗаявка Возраст] AS [WebAge],
        o.[ОбъединеннаяИнтернетЗаявка Дата Отправки на Рассмотрение] AS [WebSubmissionDate],
        o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID] AS [WebCreditID],
        o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит] AS [WebCredit],
        o.[ОбъединеннаяИнтернетЗаявка Идентификатор] AS [WebIdentifier],
        --o.[ОбъединеннаяИнтернетЗаявка Компания Фиск Код] AS [WebCompanyFiscalCode],
        --o.[ОбъединеннаяИнтернетЗаявка Консультант Партнера] AS [WebPartnerConsultant],
        o.[ОбъединеннаяИнтернетЗаявка Кредитный Продукт WEB ID] AS [WebCreditProductID],
        o.[ОбъединеннаяИнтернетЗаявка Кредитный Продукт WEB] AS [WebCreditProduct],
        o.[ОбъединеннаяИнтернетЗаявка Кредитный Эксперт ID] AS [WebCreditExpertID],
        o.[ОбъединеннаяИнтернетЗаявка Кредитный Эксперт] AS [WebCreditExpert],
        o.[ОбъединеннаяИнтернетЗаявка Номер Телефона Мобильный] AS [WebMobilePhone],
        o.[ОбъединеннаяИнтернетЗаявка Отправлена на Рассмотрение] AS [WebSentForReview],
        o.[ОбъединеннаяИнтернетЗаявка Пол] AS [WebGender],
        o.[ОбъединеннаяИнтернетЗаявка Состояние Заявки] AS [WebStatus],
        o.[ОбъединеннаяИнтернетЗаявка Срок Кредита] AS [WebCreditTerm],
        --o.[ОбъединеннаяИнтернетЗаявка Сумма Кредита] AS [WebCreditAmount],
        o.[ОбъединеннаяИнтернетЗаявка Филиал ID] AS [WebBranchID],
        COALESCE(
            z.[ЗаявкаНаКредит Клиент ID],
            o.[ОбъединеннаяИнтернетЗаявка Идентификатор],
            o.[ОбъединеннаяИнтернетЗаявка Номер Телефона Мобильный],
            o.[ОбъединеннаяИнтернетЗаявка Автор ID],
            o.[ОбъединеннаяИнтернетЗаявка ID]
        ) AS ClientKey
    FROM [ATK].[mis].[Silver_Документы.ЗаявкаНаКредит] z
    LEFT JOIN [ATK].[mis].[Silver_Документы.ОбъединеннаяИнтернетЗаявка] o
        ON z.[ЗаявкаНаКредит ID] = o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
        AND o.[ОбъединеннаяИнтернетЗаявка Дата] >= ''2023-01-01''

    UNION ALL

    -- 2️⃣ Online requests unmatched or with placeholder 000...
    SELECT
        NULL AS [ID], NULL AS [Date], NULL AS [Status], NULL AS [Posted],
        NULL AS [BusinessSector], NULL AS [Type], NULL AS [HistoryType],
        NULL AS [CreditID], NULL AS [AuthorID],  NULL AS [Purpose], NULL AS [IsGreen],
        NULL AS [ClientID], NULL AS [CreditAmount], NULL AS [RefusalReason],
        COALESCE(o.[ОбъединеннаяИнтернетЗаявка ID], CAST(NEWID() AS VARCHAR(36))) AS [WebID],
        o.[ОбъединеннаяИнтернетЗаявка Дата] AS [WebDate],
        o.[ОбъединеннаяИнтернетЗаявка Номер] AS [WebNr],
        o.[ОбъединеннаяИнтернетЗаявка Проведен] AS [WebPosted],
        o.[ОбъединеннаяИнтернетЗаявка Автор ID] AS [WebAuthorID],
        o.[ОбъединеннаяИнтернетЗаявка Автор] AS [WebAuthor],
        o.[ОбъединеннаяИнтернетЗаявка Вид Доходов Онлайн] AS [WebIncomeTypeOnline],
        o.[ОбъединеннаяИнтернетЗаявка Вид Интернет Заявки] AS [WebType],
        o.[ОбъединеннаяИнтернетЗаявка Возраст] AS [WebAge],
        o.[ОбъединеннаяИнтернетЗаявка Дата Отправки на Рассмотрение] AS [WebSubmissionDate],
        o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID] AS [WebCreditID],
        o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит] AS [WebCredit],
        o.[ОбъединеннаяИнтернетЗаявка Идентификатор] AS [WebIdentifier],
        --o.[ОбъединеннаяИнтернетЗаявка Компания Фиск Код] AS [WebCompanyFiscalCode],
        --o.[ОбъединеннаяИнтернетЗаявка Консультант Партнера] AS [WebPartnerConsultant],
        o.[ОбъединеннаяИнтернетЗаявка Кредитный Продукт WEB ID] AS [WebCreditProductID],
        o.[ОбъединеннаяИнтернетЗаявка Кредитный Продукт WEB] AS [WebCreditProduct],
        o.[ОбъединеннаяИнтернетЗаявка Кредитный Эксперт ID] AS [WebCreditExpertID],
        o.[ОбъединеннаяИнтернетЗаявка Кредитный Эксперт] AS [WebCreditExpert],
        o.[ОбъединеннаяИнтернетЗаявка Номер Телефона Мобильный] AS [WebMobilePhone],
        o.[ОбъединеннаяИнтернетЗаявка Отправлена на Рассмотрение] AS [WebSentForReview],
        o.[ОбъединеннаяИнтернетЗаявка Пол] AS [WebGender],
        o.[ОбъединеннаяИнтернетЗаявка Состояние Заявки] AS [WebStatus],
        o.[ОбъединеннаяИнтернетЗаявка Срок Кредита] AS [WebCreditTerm],
        --o.[ОбъединеннаяИнтернетЗаявка Сумма Кредита] AS [WebCreditAmount],
        o.[ОбъединеннаяИнтернетЗаявка Филиал ID] AS [WebBranchID],
        COALESCE(
            o.[ОбъединеннаяИнтернетЗаявка Идентификатор],
            o.[ОбъединеннаяИнтернетЗаявка Номер Телефона Мобильный],
            o.[ОбъединеннаяИнтернетЗаявка Автор ID],
            o.[ОбъединеннаяИнтернетЗаявка ID]
        ) AS ClientKey
    FROM [ATK].[mis].[Silver_Документы.ОбъединеннаяИнтернетЗаявка] o
    LEFT JOIN [ATK].[mis].[Silver_Документы.ЗаявкаНаКредит] z
        ON z.[ЗаявкаНаКредит ID] = o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
    WHERE z.[ЗаявкаНаКредит ID] IS NULL
       OR o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID] = ''00000000000000000000000000000000''
)
-- Insert final
INSERT INTO mis.[2tbl_Gold_Fact_CerereOnline_1]
SELECT
    [ID],[Date],[Status],[Posted],[BusinessSector],[Type],[HistoryType],
    [CreditID],[AuthorID], [Purpose],[IsGreen],[ClientID],
    CASE
         WHEN CreditAmount IS NULL OR CreditAmount <= 0 THEN N''Cancelled''
         WHEN ROW_NUMBER() OVER (
                 PARTITION BY ClientKey
                 ORDER BY WebDate
             ) = 1 THEN N''New''
         ELSE N''Existing''
    END AS [NewExisting_Client],
    [RefusalReason],
    [WebID],[WebDate],[WebNr],[WebPosted],[WebAuthorID],[WebAuthor],[WebIncomeTypeOnline],
    [WebType],[WebAge],[WebSubmissionDate],[WebCreditID],[WebCredit],[WebIdentifier],
    --[WebCompanyFiscalCode],
	--[WebPartnerConsultant],
	[WebCreditProductID],[WebCreditProduct],
    [WebCreditExpertID],[WebCreditExpert],[WebMobilePhone],[WebSentForReview],[WebGender],
    [WebStatus],[WebCreditTerm],
	--[WebCreditAmount],
	[WebBranchID]
FROM Base;';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.2tbl_Gold_Fact_CreditsInShadowBranches.sql
    SET @sql = N'IF OBJECT_ID(''mis.[2tbl_Gold_CreditsInShadowBranches]'', ''U'') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_CreditsInShadowBranches];

IF OBJECT_ID(N''[mis].[2tbl_Gold_CreditsInShadowBranches]'',''U'') IS NOT NULL DROP TABLE [mis].[2tbl_Gold_CreditsInShadowBranches];
CREATE TABLE [mis].[2tbl_Gold_CreditsInShadowBranches](
    Period DATETIME NULL,
    --Registrar_TRef NVARCHAR(100) NULL,
    ID VARCHAR(32) NOT NULL,
    RowNumber INT NULL,
    Active VARCHAR(36) NULL,
    CreditID VARCHAR(32) NULL,
    Credit NVARCHAR(100) NULL,
    BranchID VARCHAR(32) NULL,
    Branch NVARCHAR(100) NULL,
    CreditExpertID VARCHAR(32) NULL,
    CreditExpert NVARCHAR(100) NULL,
    DateTo DATETIME NULL
);

;WITH src AS (
    SELECT
          rs.[КредитыВТеневыхФилиалах Период]                 AS Period,
          --rs.[КредитыВТеневыхФилиалах Регистратор _TRef]      AS Registrar_TRef,
          rs.[КредитыВТеневыхФилиалах ID]                     AS ID,
          rs.[КредитыВТеневыхФилиалах Номер Строки]           AS RowNumber,
          rs.[КредитыВТеневыхФилиалах Активность]             AS Active,
          rs.[КредитыВТеневыхФилиалах Кредит ID]              AS CreditID,
          rs.[КредитыВТеневыхФилиалах Кредит]                 AS Credit,
          rs.[КредитыВТеневыхФилиалах Филиал ID]              AS BranchID,
          rs.[КредитыВТеневыхФилиалах Филиал]                 AS Branch,
          rs.[КредитыВТеневыхФилиалах Кредитный Эксперт ID]   AS CreditExpertID,
          rs.[КредитыВТеневыхФилиалах Кредитный Эксперт]      AS CreditExpert
    FROM [ATK].[mis].[Silver_РегистрыСведений.КредитыВТеневыхФилиалах] rs
	WHERE rs.[КредитыВТеневыхФилиалах Период] >= ''2023-01-01''
),
calc AS (
    SELECT
          Period,
          --Registrar_TRef,
          ID,
          RowNumber,
          Active,
          CreditID,
          Credit,
          BranchID,
          Branch,
          CreditExpertID,
          CreditExpert,
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
      CreditExpertID,
      CreditExpert,
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
      CreditExpertID,
      CreditExpert,
      DateTo
FROM calc;';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.2tbl_Gold_Fact_Disbursement.sql
    SET @sql = N'/* ============================
   Clean up
   ============================ */
IF OBJECT_ID(''tempdb..#Base'')   IS NOT NULL DROP TABLE #Base;
IF OBJECT_ID(''tempdb..#Status'') IS NOT NULL DROP TABLE #Status;
IF OBJECT_ID(''tempdb..#Final'')  IS NOT NULL DROP TABLE #Final;

IF OBJECT_ID(''mis.[2tbl_Gold_Fact_Disbursement]'', ''U'') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Fact_Disbursement];

/* ============================
   Target table
   (ID lengths aligned to 36)
   ============================ */
IF OBJECT_ID(N''[mis].[2tbl_Gold_Fact_Disbursement]'',''U'') IS NOT NULL DROP TABLE [mis].[2tbl_Gold_Fact_Disbursement];
CREATE TABLE [mis].[2tbl_Gold_Fact_Disbursement](
    CreditID           NVARCHAR(36)   NOT NULL,
    ClientID           NVARCHAR(36)   NULL,
    DisbursementDate   DATETIME2      NULL,
    CurrencyID         NVARCHAR(36)   NULL,
    CreditAmount       DECIMAL(18,2)  NULL,
    CreditAmountInMDL  DECIMAL(18,2)  NULL,
    CreditCurrency     NVARCHAR(50)   NULL,
    FirstFilialID      NVARCHAR(36)   NULL,
    FirstExpertID      NVARCHAR(36)   NULL,
    LastFilialID       NVARCHAR(36)   NULL,
    LastExpertID       NVARCHAR(36)   NULL,
    IRR                DECIMAL(18,2)  NULL,
    IRR_Client         DECIMAL(18,2)  NULL,
    Qty                INT            NULL,
    NewExisting_Client NVARCHAR(20)   NULL,
    CreatedAt          DATETIME       NOT NULL DEFAULT GETDATE()
);

/* ============================
   Base rows
   - one per disbursed tranche
   - rn=1 = first tranche per credit
   - last expert/filial as of end of disbursement month
   ============================ */
SELECT
    d.[ДанныеКредитовВыданных Кредит ID]                 AS CreditID,
    k.[Кредиты Владелец]                                 AS ClientID,
    d.[ДанныеКредитовВыданных Дата Выдачи]               AS DisbursementDate,
    d.[ДанныеКредитовВыданных Валюта Кредита ID]         AS CurrencyID,
    d.[ДанныеКредитовВыданных Сумма Кредита]             AS CreditAmount,
    ROUND(d.[ДанныеКредитовВыданных Сумма Кредита] * ISNULL(rate.Rate, 1), 2)
                                                         AS CreditAmountInMDL,
    d.[ДанныеКредитовВыданных Валюта Кредита]            AS CreditCurrency,
    firstR.[ФилиалID]                                     AS FirstFilialID,
    firstR.[ЭкспертID]                                    AS FirstExpertID,
    COALESCE(lastR_month.[ФилиалID], firstR.[ФилиалID])   AS LastFilialID,
    COALESCE(lastR_month.[ЭкспертID], firstR.[ЭкспертID]) AS LastExpertID,
    irr.IRR                                               AS IRR,
    irr.IRR_Client                                        AS IRR_Client,
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
    /* earliest responsible overall */
    SELECT TOP 1
           r.[ОтветственныеПоКредитамВыданным Филиал ID]            AS [ФилиалID],
           r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID]  AS [ЭкспертID]
    FROM [ATK].[mis].[Silver_РегистрыСведений.ОтветственныеПоКредитамВыданным] r
    WHERE r.[ОтветственныеПоКредитамВыданным Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
    ORDER BY r.[ОтветственныеПоКредитамВыданным Период] ASC
) firstR
OUTER APPLY (
    /* last responsible AS OF end of disbursement month */
    SELECT TOP 1
           r.[ОтветственныеПоКредитамВыданным Филиал ID]            AS [ФилиалID],
           r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID]  AS [ЭкспертID]
    FROM [ATK].[mis].[Silver_РегистрыСведений.ОтветственныеПоКредитамВыданным] r
    WHERE r.[ОтветственныеПоКредитамВыданным Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
      AND r.[ОтветственныеПоКредитамВыданным Период] <= EOMONTH(d.[ДанныеКредитовВыданных Дата Выдачи])
    ORDER BY r.[ОтветственныеПоКредитамВыданным Период] DESC
) lastR_month
OUTER APPLY (
    /* IRR with conditional: prefer IRR_Year (<100) else IRR_Client; round to 6dp; no TRY_CONVERT */
    SELECT TOP 1
        IRR_Client = ROUND(
            COALESCE(
                doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая], 0), 2),
        IRR = ROUND(
            COALESCE(
                CASE
                    WHEN doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Годовая] IS NOT NULL
                     AND doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Годовая] < 100
                        THEN doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Годовая]
                    ELSE doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая]
                END,
                0), 2)
    FROM [ATK].[mis].[Silver_Документы.УстановкаДанныхКредита] doc
    WHERE doc.[УстановкаДанныхКредита Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
    ORDER BY doc.[УстановкаДанныхКредита Дата] DESC
) irr
WHERE d.[ДанныеКредитовВыданных Кредитный Продукт] NOT LIKE N''Medier%''
  AND d.[ДанныеКредитовВыданных Дата Выдачи] >= ''2024-01-01'';

SELECT COUNT(*) AS BaseRows FROM #Base;

/* ============================
   Status (cancel/restore)
   - cancel = ''01''  -> negative row
   - restore = ''00'' -> positive row
   Build only for credits present in #Base
   ============================ */
WITH BaseIDs AS (
    SELECT DISTINCT CreditID FROM #Base
),
Cancels AS (
    SELECT a.[АнулированныеКредитыПартнеров Кредит ID] AS CreditID,
           MAX(a.[АнулированныеКредитыПартнеров Период]) AS CancelPeriod
    FROM [ATK].[mis].[Silver_РегистрыСведений.АнулированныеКредитыПартнеров] a
    INNER JOIN BaseIDs b ON b.CreditID = a.[АнулированныеКредитыПартнеров Кредит ID]
    WHERE a.[АнулированныеКредитыПартнеров Кредит Анулирован] = N''01''
    GROUP BY a.[АнулированныеКредитыПартнеров Кредит ID]
),
Restores AS (
    SELECT a.[АнулированныеКредитыПартнеров Кредит ID] AS CreditID,
           MAX(a.[АнулированныеКредитыПартнеров Период]) AS RestorePeriod
    FROM [ATK].[mis].[Silver_РегистрыСведений.АнулированныеКредитыПартнеров] a
    INNER JOIN BaseIDs b ON b.CreditID = a.[АнулированныеКредитыПартнеров Кредит ID]
    WHERE a.[АнулированныеКредитыПартнеров Кредит Восстановлен] = N''00''
    GROUP BY a.[АнулированныеКредитыПартнеров Кредит ID]
)
SELECT b.CreditID,
       c.CancelPeriod,
       r.RestorePeriod
INTO #Status
FROM BaseIDs b
LEFT JOIN Cancels  c ON c.CreditID = b.CreditID
LEFT JOIN Restores r ON r.CreditID = b.CreditID;

SELECT COUNT(*) AS StatusRows FROM #Status;

/* ============================
   Build #Final
   ============================ */
SELECT
    b.CreditID, b.ClientID, b.DisbursementDate, b.CurrencyID,
    b.CreditAmount, b.CreditAmountInMDL, b.CreditCurrency,
    b.FirstFilialID, b.FirstExpertID, b.LastFilialID, b.LastExpertID,
    b.IRR, b.IRR_Client, 1 AS Qty
INTO #Final
FROM #Base b
WHERE b.rn = 1;

-- Cancel rows (negative amounts) — only when cancel is on/after disbursement
INSERT INTO #Final
SELECT
    b.CreditID, b.ClientID, s.CancelPeriod, b.CurrencyID,
    -b.CreditAmount, -b.CreditAmountInMDL, b.CreditCurrency,
    b.FirstFilialID, b.FirstExpertID, b.LastFilialID, b.LastExpertID,
    b.IRR, b.IRR_Client, -1 AS Qty
FROM #Status s
JOIN #Base b ON b.CreditID = s.CreditID AND b.rn = 1
WHERE s.CancelPeriod IS NOT NULL
  AND s.CancelPeriod >= b.DisbursementDate;

-- Restore rows (positive amounts) — only if after cancel and on/after disbursement
INSERT INTO #Final
SELECT
    b.CreditID, b.ClientID, s.RestorePeriod, b.CurrencyID,
    b.CreditAmount, b.CreditAmountInMDL, b.CreditCurrency,
    b.FirstFilialID, b.FirstExpertID, b.LastFilialID, b.LastExpertID,
    b.IRR, b.IRR_Client, 1 AS Qty
FROM #Status s
JOIN #Base b ON b.CreditID = s.CreditID AND b.rn = 1
WHERE s.RestorePeriod IS NOT NULL
  AND s.RestorePeriod >= b.DisbursementDate
  AND (s.CancelPeriod IS NULL OR s.RestorePeriod > s.CancelPeriod);

SELECT COUNT(*) AS FinalRows FROM #Final;

/* ============================
   Insert to target
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
    CreditCurrency, FirstFilialID, FirstExpertID, LastFilialID, LastExpertID,
    IRR, IRR_Client, Qty, NewExisting_Client
)
SELECT
    CreditID, ClientID, DisbursementDate, CurrencyID, CreditAmount, CreditAmountInMDL,
    CreditCurrency, FirstFilialID, FirstExpertID, LastFilialID, LastExpertID,
    IRR, IRR_Client, Qty,
    CASE
        WHEN CreditAmount > 0 AND rn_all = 1 THEN N''New''
        WHEN CreditAmount > 0 THEN N''Existing''
        ELSE N''Cancelled''
    END AS NewExisting_Client
FROM AllSeq;

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

/* ============================
   Cleanup
   ============================ */
DROP TABLE #Base;
DROP TABLE #Status;
DROP TABLE #Final;';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.2tbl_Gold_Fact_Sold_Par.sql
    SET @sql = N'SET NOCOUNT ON;

DECLARE @DateFrom DATE = ''2024-01-01'';

-- Drop & recreate main GOLD table
DROP TABLE IF EXISTS mis.[2tbl_Gold_Fact_Sold_Par];

IF OBJECT_ID(N''[mis].[2tbl_Gold_Fact_Sold_Par]'',''U'') IS NOT NULL DROP TABLE [mis].[2tbl_Gold_Fact_Sold_Par];
CREATE TABLE [mis].[2tbl_Gold_Fact_Sold_Par](
    SoldDate      DATE         NOT NULL,
    CreditID      VARCHAR(36)  NOT NULL,
    SoldAmount    DECIMAL(18,2) NULL,
    IRR_Values    DECIMAL(18,6) NULL,
    BranchShadow  NVARCHAR(100) NULL,
    ExpertID      VARCHAR(36)  NULL,
    BranchID      VARCHAR(36)  NULL,
    Par_0_IFRS    DECIMAL(18,6) NULL,
    Par_30_IFRS   DECIMAL(18,6) NULL,
    Par_60_IFRS   DECIMAL(18,6) NULL,
    Par_90_IFRS   DECIMAL(18,6) NULL
)
WITH (DATA_COMPRESSION = PAGE);

-----------------------------------------------------
-- Step 1: Max Past Days (explicit temp table)
-----------------------------------------------------
IF OBJECT_ID(''tempdb..#MaxPastDays'') IS NOT NULL DROP TABLE #MaxPastDays;
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
IF OBJECT_ID(''tempdb..#ShadowBranch'') IS NOT NULL DROP TABLE #ShadowBranch;
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
-- Step 3: Responsible / Expert (explicit temp table)
-----------------------------------------------------
IF OBJECT_ID(''tempdb..#Responsible'') IS NOT NULL DROP TABLE #Responsible;
CREATE TABLE #Responsible (
    CreditID VARCHAR(36) NOT NULL,
    ExpertID VARCHAR(36) NULL,
    BranchID VARCHAR(36) NULL,
    Period   DATE        NULL
);

INSERT INTO #Responsible (CreditID, ExpertID, BranchID, Period)
SELECT
    r.[ОтветственныеПоКредитамВыданным Кредит ID] AS CreditID,
    r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS ExpertID,
    r.[ОтветственныеПоКредитамВыданным Филиал ID] AS BranchID,
    r.[ОтветственныеПоКредитамВыданным Период] AS Period
FROM mis.[Silver_РегистрыСведений.ОтветственныеПоКредитамВыданным] r;

CREATE NONCLUSTERED INDEX IX_Resp_Credit_Period ON #Responsible (CreditID, Period);

-----------------------------------------------------
-- Step 4: IRR last (explicit temp table)
-----------------------------------------------------
IF OBJECT_ID(''tempdb..#IRR'') IS NOT NULL DROP TABLE #IRR;
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
FROM mis.[Silver_Документы.УстановкаДанныхКредита] i;

CREATE NONCLUSTERED INDEX IX_IRR_Credit_Date ON #IRR (CreditID, IRRDate);

-----------------------------------------------------
-- Prepare ranges (ValidFrom, ValidTo) for Responsible & ShadowBranch
-----------------------------------------------------
;WITH RespRanges AS (
    SELECT 
        CreditID,
        ExpertID,
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
)
-----------------------------------------------------
-- Step 5: Main Insert (range-join approach)
-----------------------------------------------------
INSERT INTO mis.[2tbl_Gold_Fact_Sold_Par] WITH (TABLOCK)
(
    SoldDate, CreditID, SoldAmount, IRR_Values, BranchShadow, ExpertID, BranchID,
    Par_0_IFRS, Par_30_IFRS, Par_60_IFRS, Par_90_IFRS
)
SELECT
    sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS SoldDate,
    sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
    sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] AS SoldAmount,
    
    -- IRR Values with conditional logic
    ROUND(
        COALESCE(
            CASE 
                WHEN ir.IRR_Year IS NOT NULL AND ir.IRR_Year < 100 
                    THEN ir.IRR_Year
                ELSE ir.IRR_Client
            END,
            0
        )
        * sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит], 2
    ) AS IRR_Values,
    
    -- BranchShadow from ranges (valid from Period until next change)
    sh.BranchShadow,
    
    -- ExpertID and BranchID from ranges (valid from Period until next change)
    r.ExpertID,
    r.BranchID AS BranchID,
    
    -- ParNas IFRS
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

-- Responsible: range join using RespRanges
LEFT JOIN RespRanges r
    ON r.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
   AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= r.ValidFrom
   AND (r.ValidTo IS NULL OR sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] < r.ValidTo)

-- Shadow Branch: range join using ShadowRanges
LEFT JOIN ShadowRanges sh
    ON sh.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
   AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= sh.ValidFrom
   AND (sh.ValidTo IS NULL OR sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] < sh.ValidTo)

-- IRR latest (keeps your original OUTER APPLY style for IRR)
OUTER APPLY (
    SELECT TOP(1) i.IRR_Year, i.IRR_Client
    FROM #IRR i
    WHERE i.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
    ORDER BY i.IRRDate DESC
) ir

  WHERE sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] <> 0
  AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= @DateFrom;

-----------------------------------------------------
-- Columnstore
-----------------------------------------------------
CREATE CLUSTERED COLUMNSTORE INDEX CCSI_2tbl_Gold_Fact_Sold_Par
ON mis.[2tbl_Gold_Fact_Sold_Par];

-- Drop temp tables
DROP TABLE IF EXISTS #MaxPastDays, #ShadowBranch, #Responsible, #IRR;';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

END
GO
