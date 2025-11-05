-- =============================================
-- Compiled Stored Procedure for MSSQL Agent Job (Gold) - Idempotent
-- Generated: 2025-11-05 11:56:53.759261
-- Source folder: C:\ATK_Project\sql_scripts\Gold
-- Files included: 16
--   mis.Gold_Dim_AppUsers.sql
--   mis.Gold_Dim_Branch.sql
--   mis.Gold_Dim_Clients.sql
--   mis.Gold_Dim_Credits.sql
--   mis.Gold_Dim_EmployeePayrollData.sql
--   mis.Gold_Dim_Employees.sql
--   mis.Gold_Dim_EmployeesHistory.sql
--   mis.Gold_Dim_PartnersBranch.sql
--   mis.Gold_Fact_AdminTasks.sql
--   mis.Gold_Fact_ArchiveDocument.sql
--   mis.Gold_Fact_BudgetEmployees.sql
--   mis.Gold_Fact_CerereOnline.sql
--   mis.Gold_Fact_CreditsInShadowBranches.sql
--   mis.Gold_Fact_WriteOffCredits.sql
--   mis.Gold_Fact_Disbursement.sql
--   mis.Gold_Fact_Par_Restruct_Daily_Min.sql
-- Requires: SQL Server 2016 SP1+ for CREATE OR ALTER
-- =============================================

USE [ATK];
GO

IF OBJECT_ID('mis.usp_GoldTables', 'P') IS NOT NULL
    DROP PROCEDURE mis.usp_GoldTables;
GO

CREATE PROCEDURE mis.usp_GoldTables
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @sql NVARCHAR(MAX);

    -- Start of: mis.Gold_Dim_AppUsers.sql
    SET @sql = N'IF OBJECT_ID(''mis.[Gold_Dim_AppUsers]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_AppUsers];

CREATE TABLE mis.[Gold_Dim_AppUsers]
(
    App_User_ClientID VARCHAR(36) NOT NULL,
    App_User_UserID VARCHAR(36) NOT NULL,
    App_User_Phone NVARCHAR(50) NULL,
    App_User_FiscalCode NVARCHAR(20) NULL,
    App_User_ClientName NVARCHAR(100) NULL
);

INSERT INTO mis.[Gold_Dim_AppUsers] 
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

FROM [ATK].[mis].[Bronze_РегистрыСведений.СведенияОПользователяхМобильногоПриложения];';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.Gold_Dim_Branch.sql
    SET @sql = N'IF OBJECT_ID(N''mis.[Gold_Dim_Branch]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_Branch];

IF OBJECT_ID(N''[mis].[Gold_Dim_Branch]'',''U'') IS NOT NULL DROP TABLE [mis].[Gold_Dim_Branch];
CREATE TABLE [mis].[Gold_Dim_Branch](
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
INSERT INTO mis.[Gold_Dim_Branch] (
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

    -- Start of: mis.Gold_Dim_Clients.sql
    SET @sql = N'SET NOCOUNT ON;

IF OBJECT_ID(N''mis.[Gold_Dim_Clients]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_Clients];

IF OBJECT_ID(N''[mis].[Gold_Dim_Clients]'',''U'') IS NOT NULL DROP TABLE [mis].[Gold_Dim_Clients];
CREATE TABLE [mis].[Gold_Dim_Clients](
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
	[EconomicSector]        NVARCHAR(200)  NULL,
    [OrganizationType]      NVARCHAR(52)   NULL,
    [IsGroupOwner]          BIT            NULL,
    [GroupID]               NVARCHAR(20)    NULL,	
    CONSTRAINT PK_Gold_Dim_Clients PRIMARY KEY CLUSTERED (ClientID)
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
		s.[Контрагенты Сектор Экономики] AS EconomicSector,
        fp.[ФормыПредприятия Наименование] AS OrganizationType,
        CASE WHEN g.[ГруппыАффилированныхЛиц Владелец] = s.[Контрагенты ID] THEN 1 ELSE 0 END AS IsGroupOwner,
        ga.[ГруппыАффилированныхЛиц Код] AS GroupID,

        
        CASE 
            WHEN r.[Контрагенты Возраст] <> ''1753-01-01 00:00:00'' THEN r.[Контрагенты Возраст]
            ELSE s.[Контрагенты Возраст]
        END AS EffectiveRepDOB

    FROM [ATK].[mis].[Bronze_Справочники.Контрагенты] s
    LEFT JOIN [ATK].[mis].[Bronze_Справочники.Контрагенты] r
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
        NoEmailNotifications, NoPromoSMS, EconomicSector, OrganizationType,
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

INSERT INTO mis.[Gold_Dim_Clients] (
    [ClientID],[ParentID],[BranchID],
    [IsDeleted],[IsGroup],[ClientCode],[ClientName],[IsBlocked],[Visibility],
    [Age],[AgeGroup],[City],[CreatedDate],[PartnerCode],[FullName],[IsNonResident],[NoPaymentNotification],
    [Gender],[PostalAddress],[Country],[MobilePhone1],[MobilePhone2],[Phones],
    [FiscalCode],[LegalAddress],[RegistrationDate],[Language],
    [NoEmailNotifications],[NoPromoSMS], [EconomicSector], [OrganizationType],
    [IsGroupOwner],[GroupID]
)
SELECT
    ClientID, ParentID, BranchID,
    IsDeleted, IsGroup, ClientCode, ClientName, IsBlocked, Visibility,
    Age, AgeGroup, City, CreatedDate, PartnerCode, FullName, IsNonResident, NoPaymentNotification,

    CASE Gender
        WHEN ''Ж'' THEN ''F''
        WHEN N''М'' THEN ''M''  
        ELSE Gender      
    END AS Gender,
	
	PostalAddress, Country, MobilePhone1, MobilePhone2, Phones,
    FiscalCode, LegalAddress, RegistrationDate, 
	CASE [Language]
	     WHEN ''Русский'' THEN ''Russian''
		 WHEN N''Română'' THEN ''Romanian''
		 ELSE [Language]
    END AS [Language],
    NoEmailNotifications, NoPromoSMS, EconomicSector, OrganizationType,
    IsGroupOwner, GroupID
FROM Dedup
WHERE rn = 1;

CREATE NONCLUSTERED INDEX IX_Clients_Branch    ON mis.[Gold_Dim_Clients](BranchID)   INCLUDE (ClientName, IsBlocked);
CREATE NONCLUSTERED INDEX IX_Clients_AgeGroup  ON mis.[Gold_Dim_Clients](AgeGroup)  INCLUDE (City, Country);
CREATE NONCLUSTERED INDEX IX_Clients_IsDeleted ON mis.[Gold_Dim_Clients](IsDeleted) INCLUDE (ClientName);
CREATE NONCLUSTERED INDEX IX_Clients_Group     ON mis.[Gold_Dim_Clients](IsGroupOwner, GroupID);';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.Gold_Dim_Credits.sql
    SET @sql = N'IF OBJECT_ID(N''mis.[Gold_Dim_Credits]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_Credits];

IF OBJECT_ID(N''[mis].[Gold_Dim_Credits]'',''U'') IS NOT NULL DROP TABLE [mis].[Gold_Dim_Credits];
CREATE TABLE [mis].[Gold_Dim_Credits](
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
	[EconomicSectorEFSE] NVARCHAR(50) NULL,
	[EconomicSector] NVARCHAR(50) NULL,
	[Agro] NVARCHAR(50) NULL
);

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
            NULLIF(LTRIM(RTRIM(oia.[ОбъединеннаяИнтернетЗаявка Источник Заполнения])), '''') AS Source,
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
)

INSERT INTO mis.[Gold_Dim_Credits] (
    [CreditID], [Owner], [Code], [Name],
    [IssueDate], [Term], [Amount],
    [EconomicSectorDetailed], [FinancialProductID], [FinancialProduct],
    [AgroCredit], [LocalityType], [Currency], [ProductID],
    [Product], [Purpose], [RemoveFundingSource],
    [ContractType], [ContractDate], [IncomeSegment],
    [UsagePurpose], [PurposeDescription],
    [ProductType], [EconomicUsageArea], [SigningSource],
    [FinancialProductsMainGroup], [IssuedCreditsStatus],
    [CreditApplicationPartnerID], [FirstFilialID], [FirstEmployeeID],
    [LastFilialID], [LastEmployeeID], [DealerID], [Source],
    [LatestOutstandingAmount], [SegmentRevenue], [GreenCredit],
    [CommitteeProt_CrPurpose], [CommitteeProt_AMLRiskCat],
    [DigitalSign], [EconomicSectorEFSE], [EconomicSector], [Agro]
)
SELECT
    c.[Кредиты ID], c.[Кредиты Владелец], c.[Кредиты Код], c.[Кредиты Наименование],
    c.[Кредиты Дата Выдачи], c.[Кредиты Срок Кредита], c.[Кредиты Сумма Кредита],
    c.[Кредиты Сектор Экономики], c.[Кредиты Финансовый Продукт ID], 
	c.[Кредиты Финансовый Продукт],
	
    CASE c.[Кредиты Агро]
	     WHEN ''Агро'' THEN ''AgroCredit''
         WHEN ''НеАгро'' THEN ''nonAgro''
		 ELSE c.[Кредиты Агро]
	END AS AgroCredit, 
	CASE c.[Кредиты Тип Местности]
	     WHEN ''ГородБольшой'' THEN ''bigCity''
         WHEN ''Пригород'' THEN ''suburb''
	     WHEN ''Город'' THEN ''city''
		 ELSE c.[Кредиты Тип Местности]
	END AS LocalityType,
    c.[Кредиты Валюта],	
	
	c.[Кредиты Кредитный Продукт ID],
    c.[Кредиты Кредитный Продукт],
    c.[Кредиты Цель Кредита],	
	
	c.[Кредиты Удалить Источник Финансирования],
    CASE c.[Кредиты Вид Контракта]
	     WHEN ''Контракт'' THEN ''Contract''
		 WHEN ''Приложение'' THEN ''App''
		 ELSE c.[Кредиты Вид Контракта]
	END AS ContractType, 
	c.[Кредиты Дата Контракта],
    c.[Кредиты Сегмент Доходов],	

	c.[Кредиты Назначение Использования Кредита],
    
	c.[Кредиты Цель Кредита Описание],
	c.[Кредиты Тип Кредитного Продукта],
   
    c.[Кредиты Сфера Использования Кредита],
	
	CASE c.[Кредиты Источник Подписания]
	     WHEN ''Приложение'' THEN ''MobileApp''
		 WHEN ''Сайт'' THEN ''WebSite''
		 ELSE c.[Кредиты Источник Подписания]
	END AS SigningSource,
	fp.FinancialProductsMainGroup,
    
    CASE st.IssuedCreditsStatus
	     WHEN ''Закрыт'' THEN ''Closed''
		 WHEN ''Выдан'' THEN ''Disbursed''
		 WHEN ''Списан'' THEN ''Written off''
	     ELSE st.IssuedCreditsStatus
	END AS IssuedCreditsStatus,
    cr.ApplicationPartnerID,
    COALESCE(r.FirstFilialID, cr.FilialID),
    COALESCE(r.FirstEmployeeID, cr.EmployeeID),
    COALESCE(r.LastFilialID, cr.FilialID),
    COALESCE(r.LastEmployeeID, cr.EmployeeID),
    cr.DealerID,
    CASE cr.Source
         WHEN ''Партнер'' THEN ''Parteners''
         WHEN ''Кассир'' THEN ''CCR''
         WHEN ''СотрудникCallCenter'' THEN ''CallCenter''
         WHEN ''Сайт'' THEN ''WebSite''
         WHEN ''Плагин'' THEN ''API''
	     WHEN ''МобильноеПриложение'' THEN ''MobileApp''
	     WHEN ''КредитныйЭксперт'' THEN ''Employee''
	     WHEN ''Другой'' THEN ''Other''
         ELSE cr.Source
    END AS Source,
    lo.LatestOutstandingAmount,
	seg.SegmentRevenue,
    
    gc.GreenCredit,
    gc.CommitteeProt_CrPurpose,	
	
	CASE gc.CommitteeProt_AMLRiskCat
	   WHEN ''Высокий'' THEN ''High_Risk''
       WHEN ''Средний'' THEN ''Medium_Risk''
       WHEN ''Низкий'' THEN ''Low_Risk''
	   ELSE  gc.CommitteeProt_AMLRiskCat
	END AS CommitteeProt_AMLRiskCat,
    CASE WHEN c.[Кредиты Источник Подписания] IS NOT NULL 
	     THEN ''True'' 
		 ELSE ''False'' 
    END AS DigitalSign,
	e.[СекторыЭкономики Сектор Экономики EFSE] AS EconomicSectorEFSE,
	e.[СекторыЭкономики Основной Раздел] AS EconimicSector,
	
	CASE 
	   WHEN fp.FinancialProductsMainGroup = ''Business''
	   AND e.[СекторыЭкономики Основной Раздел] = ''1. Agricultura''
	   THEN ''Agro''
	   ELSE ''NonAgro''
	END AS Agro
	
FROM Credits c
LEFT JOIN CreditRequest cr ON c.[Кредиты ID] = cr.CreditID
LEFT JOIN Resp r ON c.[Кредиты ID] = r.CreditID
LEFT JOIN FinProducts fp ON c.[Кредиты Финансовый Продукт ID] = fp.FinancialProductID
LEFT JOIN Statuses st ON c.[Кредиты ID] = st.CreditID
LEFT JOIN LatestOutstanding lo ON c.[Кредиты ID] = lo.CreditID
LEFT JOIN SegmentRevenue seg ON c.[Кредиты Кредитный Продукт ID] = seg.ProductID
LEFT JOIN GreenCredit gc ON c.[Кредиты ID] = gc.CreditID
LEFT JOIN [ATK].[dbo].[Справочники.СекторыЭкономики] AS e ON c.[Кредиты Сектор Экономики ID] = e.[СекторыЭкономики ID];';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.Gold_Dim_EmployeePayrollData.sql
    SET @sql = N'IF OBJECT_ID(''mis.[Gold_Dim_EmployeePayrollData]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_EmployeePayrollData];

CREATE TABLE mis.[Gold_Dim_EmployeePayrollData]
(
    EmployeePositionID VARCHAR(36) NOT NULL,
    EmployeePosition NVARCHAR(150) NULL
);

INSERT INTO mis.[Gold_Dim_EmployeePayrollData] 
(
    EmployeePositionID,
    EmployeePosition
)
SELECT 
    [СотрудникиДанныеПоЗарплате Должность ID] AS EmployeePositionID,
	[СотрудникиДанныеПоЗарплате Должность] AS EmployeePosition
    

FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате];';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.Gold_Dim_Employees.sql
    SET @sql = N'IF OBJECT_ID(''mis.[Gold_Dim_Employees]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_Employees];

IF OBJECT_ID(N''[mis].[Gold_Dim_Employees]'',''U'') IS NOT NULL DROP TABLE [mis].[Gold_Dim_Employees];
CREATE TABLE [mis].[Gold_Dim_Employees](
    [EmployeeID] VARCHAR(36) NOT NULL,
	[BranchID] VARCHAR(36) NULL,
    [EmployeeCode] INT NULL,
    [EmployeePositionID] VARCHAR(36) NULL,
    [EmployeeName] NVARCHAR(40) NULL,
    [EmployeePosition] NVARCHAR(150) NULL,
    [HireDate] NVARCHAR(10) NULL,
    [BirthDate] NVARCHAR(10) NULL,
    [DismissalDate] NVARCHAR(10) NULL,
    [TimesheetNumber] INT NULL,
    [ExperienceYears] INT NULL,
    [ExperienceMonths] INT NULL,
    [ExperienceYM] NVARCHAR(50) NULL,
    [ExperienceMonthsRange] NVARCHAR(50) NULL,
    [ExperienceIndex] INT NULL,
    [EmploymentPeriod] NVARCHAR(50) NULL,
    [EmploymentPositionType] NVARCHAR(150) NULL,
    [EmpPositionIDdate] DATETIME,
	[ExperienceMonthsLastPosition] INT NULL,
	[ExperienceMonthsRangeLastPosition] NVARCHAR(50) NULL,
	[ExperienceIndexLastPosition] INT
);

INSERT INTO mis.[Gold_Dim_Employees] 
(
    [EmployeeID],
	[BranchID],
    [EmployeeCode],
    [EmployeePositionID],
    [EmployeeName],
    [EmployeePosition],
    [HireDate],
    [BirthDate],
    [DismissalDate],
    [TimesheetNumber],
    [ExperienceYears],
    [ExperienceMonths],
    [ExperienceYM],
    [ExperienceMonthsRange],
    [ExperienceIndex],
    [EmploymentPeriod],
    [EmploymentPositionType],
    [EmpPositionIDdate],
	[ExperienceMonthsLastPosition],
	[ExperienceMonthsRangeLastPosition],
	[ExperienceIndexLastPosition]
)
SELECT 
    e.[Сотрудники ID] AS EmployeeID,
	lastPos.[СотрудникиДанныеПоЗарплате Филиал ID] AS [BranchID],
    e.[Сотрудники Код] AS EmployeeCode,
    lastPos.[СотрудникиДанныеПоЗарплате Должность ID] AS EmployeePositionID,
    e.[Сотрудники Наименование] AS EmployeeName,
    lastPos.[СотрудникиДанныеПоЗарплате Должность] AS EmployeePosition,

    
    CASE 
        WHEN e.[Сотрудники Дата Приема] IS NULL OR e.[Сотрудники Дата Приема] = ''1753-01-01'' THEN N''N/A''
        ELSE FORMAT(e.[Сотрудники Дата Приема], ''yyyy-MM-dd'')
    END AS HireDate,

    
    CASE 
        WHEN e.[Сотрудники Дата Рождения] IS NULL OR e.[Сотрудники Дата Рождения] = ''1753-01-01'' THEN N''N/A''
        ELSE FORMAT(e.[Сотрудники Дата Рождения], ''yyyy-MM-dd'')
    END AS BirthDate,

    
    CASE 
        WHEN e.[Сотрудники Дата Увольнения] IS NULL OR e.[Сотрудники Дата Увольнения] = ''1753-01-01'' THEN N''N/A''
        ELSE FORMAT(e.[Сотрудники Дата Увольнения], ''yyyy-MM-dd'')
    END AS DismissalDate,

    e.[Сотрудники Табельный Номер] AS TimesheetNumber,

    
    CASE 
        WHEN e.[Сотрудники Дата Приема] IS NULL OR e.[Сотрудники Дата Приема] = ''1753-01-01'' THEN NULL
        ELSE DATEDIFF(MONTH, e.[Сотрудники Дата Приема], 
             COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())
        ) / 12
    END AS ExperienceYears,

    
    CASE 
        WHEN e.[Сотрудники Дата Приема] IS NULL OR e.[Сотрудники Дата Приема] = ''1753-01-01'' THEN NULL
        ELSE DATEDIFF(MONTH, e.[Сотрудники Дата Приема], 
             COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())
        )
    END AS ExperienceMonths,

    
    CASE 
        WHEN e.[Сотрудники Дата Приема] IS NULL OR e.[Сотрудники Дата Приема] = ''1753-01-01'' THEN N''N/A''
        ELSE CAST(DATEDIFF(MONTH, e.[Сотрудники Дата Приема], 
                 COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())
            ) / 12 AS NVARCHAR(3)) 
            + N'' years '' + 
            CAST(DATEDIFF(MONTH, e.[Сотрудники Дата Приема], 
                 COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())
            ) % 12 AS NVARCHAR(2)) 
            + N'' months''
    END AS ExperienceYM,

    
    CASE 
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) BETWEEN 0 AND 5 THEN N''1-5 m''
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) BETWEEN 6 AND 11 THEN N''6-11 m''
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) BETWEEN 12 AND 35 THEN N''12-35 m''
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) > 35 THEN N''36+ m''
        ELSE N''N/A''
    END AS ExperienceMonthsRange,

    
    CASE 
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) BETWEEN 0 AND 5 THEN 1
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) BETWEEN 6 AND 11 THEN 2
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) BETWEEN 12 AND 35 THEN 3
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) > 35 THEN 4
        ELSE NULL
    END AS ExperienceIndex,

    
    CASE 
        WHEN e.[Сотрудники Дата Приема] IS NULL OR e.[Сотрудники Дата Приема] = ''1753-01-01'' THEN N''N/A''
        WHEN e.[Сотрудники Дата Увольнения] IS NULL OR e.[Сотрудники Дата Увольнения] = ''1753-01-01''
            THEN FORMAT(e.[Сотрудники Дата Приема], ''yyyy-MM-dd'') + N'' → Present''
        ELSE FORMAT(e.[Сотрудники Дата Приема], ''yyyy-MM-dd'') + N'' → '' + FORMAT(e.[Сотрудники Дата Увольнения], ''yyyy-MM-dd'')
    END AS EmploymentPeriod,

    lastPos.[СотрудникиДанныеПоЗарплате Вид Должности] AS EmploymentPositionType,
    firstAssigned.FirstDate AS EmpPositionIDdate,
	
	 CASE 
        WHEN firstAssigned.FirstDate IS NULL OR firstAssigned.FirstDate = ''1753-01-01'' THEN NULL
        ELSE DATEDIFF(MONTH, firstAssigned.FirstDate, 
             COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())
        )
    END AS ExperienceMonthsLastPosition,
	
	 CASE 
        WHEN DATEDIFF(MONTH, firstAssigned.FirstDate, COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) BETWEEN 0 AND 5 THEN N''1-5 m''
        WHEN DATEDIFF(MONTH, firstAssigned.FirstDate, COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) BETWEEN 6 AND 11 THEN N''6-11 m''
        WHEN DATEDIFF(MONTH, firstAssigned.FirstDate, COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) BETWEEN 12 AND 35 THEN N''12-35 m''
        WHEN DATEDIFF(MONTH, firstAssigned.FirstDate, COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) > 35 THEN N''36+ m''
        ELSE N''N/A''
    END AS ExperienceMonthsRangeLastPosition,
	
	
	CASE 
        WHEN DATEDIFF(MONTH, firstAssigned.FirstDate, COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) BETWEEN 0 AND 5 THEN 1
        WHEN DATEDIFF(MONTH, firstAssigned.FirstDate, COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) BETWEEN 6 AND 11 THEN 2
        WHEN DATEDIFF(MONTH, firstAssigned.FirstDate, COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) BETWEEN 12 AND 35 THEN 3
        WHEN DATEDIFF(MONTH, firstAssigned.FirstDate, COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],''1753-01-01''), GETDATE())) > 35 THEN 4
        ELSE NULL
    END AS ExperienceIndexLastPosition

FROM [ATK].[dbo].[Справочники.Сотрудники] AS e
OUTER APPLY (
    
    SELECT TOP 1 *
    FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате] AS b
    WHERE b.[СотрудникиДанныеПоЗарплате Сотрудник ID] = e.[Сотрудники ID]
    ORDER BY b.[СотрудникиДанныеПоЗарплате Период] DESC
) AS lastPos
OUTER APPLY (
    
    SELECT MIN(b.[СотрудникиДанныеПоЗарплате Период]) AS FirstDate
    FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате] AS b
    WHERE b.[СотрудникиДанныеПоЗарплате Сотрудник ID] = e.[Сотрудники ID]
      AND b.[СотрудникиДанныеПоЗарплате Вид Должности ID] = lastPos.[СотрудникиДанныеПоЗарплате Вид Должности ID]
) AS firstAssigned;';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.Gold_Dim_EmployeesHistory.sql
    SET @sql = N'IF OBJECT_ID(''mis.[Gold_Dim_EmployeesHistory]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_EmployeesHistory];

IF OBJECT_ID(N''[mis].[Gold_Dim_EmployeesHistory]'',''U'') IS NOT NULL DROP TABLE [mis].[Gold_Dim_EmployeesHistory];
CREATE TABLE [mis].[Gold_Dim_EmployeesHistory](
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

INSERT INTO mis.[Gold_Dim_EmployeesHistory] (
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
        CONVERT(DATETIME, ''2222-01-01'', 120)
    )                                                           AS DateTo
FROM [ATK].[mis].[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным];';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.Gold_Dim_PartnersBranch.sql
    SET @sql = N'IF OBJECT_ID(''mis.[Gold_Dim_PartnersBranch]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_PartnersBranch];

CREATE TABLE mis.[Gold_Dim_PartnersBranch]
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

INSERT INTO mis.[Gold_Dim_PartnersBranch]
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
FROM mis.[Bronze_Справочники.ФилиалыКонтрагентов] f
LEFT JOIN mis.[Bronze_Справочники.Дилеры] d
  ON d.[Дилеры Владелец] = f.[ФилиалыКонтрагентов ID];';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.Gold_Fact_AdminTasks.sql
    SET @sql = N'IF OBJECT_ID(''mis.[Gold_Fact_AdminTasks]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_AdminTasks];

CREATE TABLE mis.[Gold_Fact_AdminTasks]
(
    
    [AdminTask_ID] VARCHAR(36) NOT NULL,
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
    [InProgress] DECIMAL(18,2) NULL,

    
    [StatusHistory_ID] VARCHAR(36) NULL,
    [StatusHistory_RowNumber] INT NULL,
    [StatusHistory_Status] NVARCHAR(256) NULL,
    [StatusHistory_UserID] VARCHAR(36) NULL,
    [StatusHistory_User] NVARCHAR(150) NULL,
    [StatusHistory_StartDate] DATETIME NULL,
    [StatusHistory_EndDate] DATETIME NULL,
    [StatusHistory_Comment] NVARCHAR(1000) NULL,
    [StatusHistory_Seconds] INT NULL,

    
    [СведенияОНаправленияхНаВыплату Направление на Выплату ID] VARCHAR(36) NULL,
    [СведенияОНаправленияхНаВыплату Направление на Выплату] VARCHAR(100) NULL,
    [СведенияОНаправленияхНаВыплату SLA] DECIMAL (8, 3) NULL,
    [СведенияОНаправленияхНаВыплату Максимальное Время Выполнения] DECIMAL(8, 3) NULL,
    [СведенияОНаправленияхНаВыплату Дата Создания] DATETIME NULL,
    [СведенияОНаправленияхНаВыплату Дата Взятия в Работу] DATETIME NULL,
    [СведенияОНаправленияхНаВыплату Дата Утверждения] DATETIME NULL,
    [СведенияОНаправленияхНаВыплату Дата Пометки Удаления] DATETIME NULL,
    [СведенияОНаправленияхНаВыплату Тип Направления на Выплату ID] VARCHAR(36) NULL,
    [СведенияОНаправленияхНаВыплату Тип Направления на Выплату] NVARCHAR(30) NULL,
    
    [НаправлениеНаВыплату ID] VARCHAR(36) NULL,
    [НаправлениеНаВыплату Категория Риска AML] NVARCHAR(256) NULL
);

;WITH AllTasks AS (
    
    SELECT
        a.[ЗадачаАдминистратораКредитов ID] AS AdminTask_ID,
        a.[ЗадачаАдминистратораКредитов Пометка Удаления] AS AdminTask_Deleted,
        a.[ЗадачаАдминистратораКредитов Дата] AS AdminTask_Date,
        a.[ЗадачаАдминистратораКредитов Номер] AS AdminTask_Number,
        a.[ЗадачаАдминистратораКредитов Выполнена] AS AdminTask_Completed,
        a.[ЗадачаАдминистратораКредитов Автор ID] AS AdminTask_Author_ID,
        a.[ЗадачаАдминистратораКредитов Автор] AS AdminTask_Author,
        a.[ЗадачаАдминистратораКредитов Филиал ID] AS AdminTask_Branch_ID,
        a.[ЗадачаАдминистратораКредитов Филиал] AS AdminTask_Branch,
        a.[ЗадачаАдминистратораКредитов Категория Задачи ID] AS AdminTask_Category_ID,
        a.[ЗадачаАдминистратораКредитов Категория Задачи] AS AdminTask_Category,
        a.[ЗадачаАдминистратораКредитов Тип Задачи ID] AS AdminTask_Type_ID,
        a.[ЗадачаАдминистратораКредитов Тип Задачи] AS AdminTask_Type,
        a.[ЗадачаАдминистратораКредитов Описание Задачи] AS AdminTask_Description,
        a.[ЗадачаАдминистратораКредитов Задача Основание ID] AS AdminTask_Base_ID,
        a.[ЗадачаАдминистратораКредитов Источник Тип] AS AdminTask_Source_Type,
        a.[ЗадачаАдминистратораКредитов Источник Вид] AS AdminTask_Source_View,
        a.[ЗадачаАдминистратораКредитов Источник ID] AS AdminTask_Source_ID,
        a.[ЗадачаАдминистратораКредитов Клиент ID] AS AdminTask_Client_ID,
        a.[ЗадачаАдминистратораКредитов Клиент] AS AdminTask_Client,
        a.[ЗадачаАдминистратораКредитов Кредит ID] AS AdminTask_Credit_ID,
        a.[ЗадачаАдминистратораКредитов Кредит] AS AdminTask_Credit,
        a.[ЗадачаАдминистратораКредитов Лимит ID] AS AdminTask_Limit_ID,
        a.[ЗадачаАдминистратораКредитов Лимит] AS AdminTask_Limit,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Статус] AS AdminTask_CurrentStatus,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Статус ID] AS AdminTask_CurrentStatus_ID,
        a.[ЗадачаАдминистратораКредитов Дата Выполнения] AS AdminTask_CompletionDate,
        a.[ЗадачаАдминистратораКредитов Текущий Комментарий] AS AdminTask_CurrentComment,
        hist_tasktype.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей SLA] AS AdminTask_SLA,
        hist_tasktype.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей KPI] AS AdminTask_KPI,
        a.[ЗадачаАдминистратораКредитов Количество Задач] AS AdminTask_TaskCount,
        a.[ЗадачаАдминистратораКредитов Приоритет Задачи] AS AdminTask_Priority,
        a.[ЗадачаАдминистратораКредитов Приоритет Задачи ID] AS AdminTask_Priority_ID,
        a.[ЗадачаАдминистратораКредитов Исполнитель] AS AdminTask_Executor,

        t.[ТипыЗадачАдминистратораКредитов Пометка Удаления] AS TaskType_Deleted,
        t.[ТипыЗадачАдминистратораКредитов Родитель ID] AS TaskType_Parent_ID,
        t.[ТипыЗадачАдминистратораКредитов Это Группа] AS TaskType_IsGroup,
        t.[ТипыЗадачАдминистратораКредитов Код] AS TaskType_Code,
        t.[ТипыЗадачАдминистратораКредитов Наименование] AS TaskType_Name,
        t.[ТипыЗадачАдминистратораКредитов Реквизит Доп Упорядочивания] AS TaskType_Order,
        hist_tasktype.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей SLA] AS TaskType_SLA,
        hist_tasktype.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей KPI] AS TaskType_KPI,
        t.[ТипыЗадачАдминистратораКредитов Запрет Редактирования Количества Задач] AS TaskType_BlockEditCount,
        hist_tasktype.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей Максимальное Время Выполнения] AS TaskType_MaxTime,

        COALESCE(wait_hours.WaitHours, 0) AS WaitHours,
        COALESCE(total_hours.TotalHours, 0) AS TotalHours,
        COALESCE(in_progress.InProgress, 0) AS InProgress,

        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID] AS StatusHistory_ID,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Номер Строки] AS StatusHistory_RowNumber,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Статус] AS StatusHistory_Status,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Пользователь ID] AS StatusHistory_UserID,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Пользователь] AS StatusHistory_User,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Дата Начала] AS StatusHistory_StartDate,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Дата Окончания] AS StatusHistory_EndDate,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Комментарий] AS StatusHistory_Comment,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Время в Секундах] AS StatusHistory_Seconds,

        pay.[СведенияОНаправленияхНаВыплату Направление на Выплату ID],
        pay.[СведенияОНаправленияхНаВыплату Направление на Выплату],
        pay.[СведенияОНаправленияхНаВыплату SLA],
        pay.[СведенияОНаправленияхНаВыплату Максимальное Время Выполнения],
        pay.[СведенияОНаправленияхНаВыплату Дата Создания],
        pay.[СведенияОНаправленияхНаВыплату Дата Взятия в Работу],
        pay.[СведенияОНаправленияхНаВыплату Дата Утверждения],
        pay.[СведенияОНаправленияхНаВыплату Дата Пометки Удаления],
        pay.[СведенияОНаправленияхНаВыплату Тип Направления на Выплату ID],
        pay.[СведенияОНаправленияхНаВыплату Тип Направления на Выплату],
        doc.[НаправлениеНаВыплату ID],
        doc.[НаправлениеНаВыплату Категория Риска AML],
        
        ROW_NUMBER() OVER(PARTITION BY a.[ЗадачаАдминистратораКредитов ID] ORDER BY sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Дата Окончания] DESC) AS rn

    FROM [ATK].[mis].[Bronze_Задачи.ЗадачаАдминистратораКредитов] a
    LEFT JOIN [ATK].[mis].[Bronze_Справочники.ТипыЗадачАдминистратораКредитов] t
        ON a.[ЗадачаАдминистратораКредитов Тип Задачи ID] = t.[ТипыЗадачАдминистратораКредитов ID]
    OUTER APPLY
    (
        SELECT *
        FROM [ATK].[mis].[Bronze_Задачи.ЗадачаАдминистратораКредитов.ИсторияСтатусов] s
        WHERE s.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID] = a.[ЗадачаАдминистратораКредитов ID]
    ) sh
    OUTER APPLY
    (
        SELECT SUM(CAST(s2.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Время в Секундах] AS FLOAT))/3600.0 AS TotalHours
        FROM [ATK].[mis].[Bronze_Задачи.ЗадачаАдминистратораКредитов.ИсторияСтатусов] s2
        WHERE s2.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID] = a.[ЗадачаАдминистратораКредитов ID]
    ) total_hours
    OUTER APPLY
    (
        SELECT SUM(CAST(s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Время в Секундах] AS FLOAT))/3600.0 AS WaitHours
        FROM [ATK].[mis].[Bronze_Задачи.ЗадачаАдминистратораКредитов.ИсторияСтатусов] s3
        WHERE s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID] = a.[ЗадачаАдминистратораКредитов ID]
          AND s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Статус] = N''ВОжидании''
    ) wait_hours
    OUTER APPLY
    (
        SELECT SUM(CAST(s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Время в Секундах] AS FLOAT))/3600.0 AS InProgress
        FROM [ATK].[mis].[Bronze_Задачи.ЗадачаАдминистратораКредитов.ИсторияСтатусов] s3
        WHERE s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID] = a.[ЗадачаАдминистратораКредитов ID]
          AND s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Статус] = N''ВРаботе''
    ) in_progress
    OUTER APPLY
    (
        SELECT TOP 1 *
        FROM [ATK].[mis].[Bronze_Справочники.ТипыЗадачАдминистратораКредитов_ИсторияПоказателей] hist
        WHERE hist.[ТипыЗадачАдминистратораКредитов ID] = t.[ТипыЗадачАдминистратораКредитов ID]
          AND hist.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей Дата Изменения] <= a.[ЗадачаАдминистратораКредитов Дата]
        ORDER BY hist.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей Дата Изменения] DESC
    ) hist_tasktype
    OUTER APPLY
    (
        SELECT TOP 1 *
        FROM [ATK].[mis].[Bronze_Документы.НаправлениеНаВыплату] d
        WHERE d.[НаправлениеНаВыплату Кредит ID] = a.[ЗадачаАдминистратораКредитов Кредит ID]
        ORDER BY d.[НаправлениеНаВыплату Дата] DESC
    ) doc
    OUTER APPLY
    (
        SELECT TOP 1 *
        FROM [ATK].[mis].[Bronze_РегистрыСведений.СведенияОНаправленияхНаВыплату] p
        WHERE p.[СведенияОНаправленияхНаВыплату Направление на Выплату ID] = doc.[НаправлениеНаВыплату ID]
    ) pay
)
INSERT INTO mis.[Gold_Fact_AdminTasks] (
    [AdminTask_ID], [AdminTask_Deleted], [AdminTask_Date], [AdminTask_Number], [AdminTask_Completed],
    [AdminTask_Author_ID], [AdminTask_Author], [AdminTask_Branch_ID], [AdminTask_Branch],
    [AdminTask_Category_ID], [AdminTask_Category], [AdminTask_Type_ID], [AdminTask_Type],
    [AdminTask_Description], [AdminTask_Base_ID], [AdminTask_Source_Type], [AdminTask_Source_View],
    [AdminTask_Source_ID], [AdminTask_Client_ID], [AdminTask_Client], [AdminTask_Credit_ID], [AdminTask_Credit],
    [AdminTask_Limit_ID], [AdminTask_Limit], [AdminTask_CurrentStatus], [AdminTask_CurrentStatus_ID],
    [AdminTask_CompletionDate], [AdminTask_CurrentComment], [AdminTask_SLA], [AdminTask_KPI],
    [AdminTask_TaskCount], [AdminTask_Priority], [AdminTask_Priority_ID], [AdminTask_Executor],
    [TaskType_Deleted], [TaskType_Parent_ID], [TaskType_IsGroup], [TaskType_Code], [TaskType_Name],
    [TaskType_Order], [TaskType_SLA], [TaskType_KPI], [TaskType_BlockEditCount], [TaskType_MaxTime],
    [WaitHours], [TotalHours], [InProgress],
    [StatusHistory_ID], [StatusHistory_RowNumber], [StatusHistory_Status], [StatusHistory_UserID],
    [StatusHistory_User], [StatusHistory_StartDate], [StatusHistory_EndDate], [StatusHistory_Comment],
    [StatusHistory_Seconds],
    [СведенияОНаправленияхНаВыплату Направление на Выплату ID], [СведенияОНаправленияхНаВыплату Направление на Выплату],
    [СведенияОНаправленияхНаВыплату SLA], [СведенияОНаправленияхНаВыплату Максимальное Время Выполнения],
    [СведенияОНаправленияхНаВыплату Дата Создания], [СведенияОНаправленияхНаВыплату Дата Взятия в Работу],
    [СведенияОНаправленияхНаВыплату Дата Утверждения], [СведенияОНаправленияхНаВыплату Дата Пометки Удаления],
    [СведенияОНаправленияхНаВыплату Тип Направления на Выплату ID], [СведенияОНаправленияхНаВыплату Тип Направления на Выплату],
    [НаправлениеНаВыплату ID], [НаправлениеНаВыплату Категория Риска AML]
)
SELECT
    AdminTask_ID, AdminTask_Deleted, AdminTask_Date, AdminTask_Number, AdminTask_Completed,
    AdminTask_Author_ID, AdminTask_Author, AdminTask_Branch_ID, AdminTask_Branch,
    AdminTask_Category_ID, AdminTask_Category, AdminTask_Type_ID, AdminTask_Type,
    AdminTask_Description, AdminTask_Base_ID, AdminTask_Source_Type, AdminTask_Source_View,
    AdminTask_Source_ID, AdminTask_Client_ID, AdminTask_Client, AdminTask_Credit_ID, AdminTask_Credit,
    AdminTask_Limit_ID, AdminTask_Limit, AdminTask_CurrentStatus, AdminTask_CurrentStatus_ID,
    AdminTask_CompletionDate, AdminTask_CurrentComment, AdminTask_SLA, AdminTask_KPI,
    AdminTask_TaskCount, AdminTask_Priority, AdminTask_Priority_ID, AdminTask_Executor,
    TaskType_Deleted, TaskType_Parent_ID, TaskType_IsGroup, TaskType_Code, TaskType_Name,
    TaskType_Order, TaskType_SLA, TaskType_KPI, TaskType_BlockEditCount, TaskType_MaxTime,
    WaitHours, TotalHours, InProgress,
    StatusHistory_ID, StatusHistory_RowNumber, StatusHistory_Status, StatusHistory_UserID,
    StatusHistory_User, StatusHistory_StartDate, StatusHistory_EndDate, StatusHistory_Comment,
    StatusHistory_Seconds,
    [СведенияОНаправленияхНаВыплату Направление на Выплату ID], [СведенияОНаправленияхНаВыплату Направление на Выплату],
    [СведенияОНаправленияхНаВыплату SLA], [СведенияОНаправленияхНаВыплату Максимальное Время Выполнения],
    [СведенияОНаправленияхНаВыплату Дата Создания], [СведенияОНаправленияхНаВыплату Дата Взятия в Работу],
    [СведенияОНаправленияхНаВыплату Дата Утверждения], [СведенияОНаправленияхНаВыплату Дата Пометки Удаления],
    [СведенияОНаправленияхНаВыплату Тип Направления на Выплату ID], [СведенияОНаправленияхНаВыплату Тип Направления на Выплату],
    [НаправлениеНаВыплату ID], [НаправлениеНаВыплату Категория Риска AML]
FROM AllTasks
WHERE rn = 1;';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.Gold_Fact_ArchiveDocument.sql
    SET @sql = N'USE [ATK]

IF OBJECT_ID(''mis.[Gold_Fact_ArchiveDocument]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_ArchiveDocument];

IF OBJECT_ID(N''[mis].[Gold_Fact_ArchiveDocument]'',''U'') IS NOT NULL DROP TABLE [mis].[Gold_Fact_ArchiveDocument];
CREATE TABLE [mis].[Gold_Fact_ArchiveDocument](
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

INSERT INTO mis.[Gold_Fact_ArchiveDocument]
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
WHERE r.[АктыПередачиКредитныхДел Период] >= ''2024-01-01'';';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.Gold_Fact_BudgetEmployees.sql
    SET @sql = N'IF OBJECT_ID(''mis.[Gold_Fact_BudgetEmployees]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_BudgetEmployees];

CREATE TABLE mis.[Gold_Fact_BudgetEmployees] 
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

INSERT INTO mis.[Gold_Fact_BudgetEmployees]
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

    -- Start of: mis.Gold_Fact_CerereOnline.sql
    SET @sql = N'SET NOCOUNT ON;

IF OBJECT_ID(''mis.[Gold_Fact_CerereOnline]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_CerereOnline];

IF OBJECT_ID(N''[mis].[Gold_Fact_CerereOnline]'',''U'') IS NOT NULL DROP TABLE [mis].[Gold_Fact_CerereOnline];
CREATE TABLE [mis].[Gold_Fact_CerereOnline](
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
    
);

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
        COALESCE(
            z.[ЗаявкаНаКредит Клиент ID],
            o.[ОбъединеннаяИнтернетЗаявка Идентификатор],
            o.[ОбъединеннаяИнтернетЗаявка Номер Телефона Мобильный],
            o.[ОбъединеннаяИнтернетЗаявка Автор ID],
            o.[ОбъединеннаяИнтернетЗаявка ID]
        ) AS ClientKey,
        c.[ПротоколКомитета Дата Решения] AS [CommitteeDecisionDate]
    FROM [ATK].[mis].[Bronze_Документы.ЗаявкаНаКредит] z
    LEFT JOIN [ATK].[mis].[Bronze_Документы.ОбъединеннаяИнтернетЗаявка] o
        ON z.[ЗаявкаНаКредит ID] = o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
    LEFT JOIN [ATK].[dbo].[Документы.ПротоколКомитета] c
        ON c.[ПротоколКомитета Заявка ID] = z.[ЗаявкаНаКредит ID]

    
    
    
    UNION ALL
    SELECT
        NULL AS [ID], NULL AS [Date], NULL AS [Status], NULL AS [Posted],
        NULL AS [BusinessSector], NULL AS [Type], NULL AS [HistoryType],
        NULL AS [CreditID], NULL AS [AuthorID], NULL AS [Author], NULL AS [Purpose],
        NULL AS [IsGreen], NULL AS [ClientID], NULL AS [CreditAmount],
        NULL AS [RefusalReason], NULL AS [CreditProduct], NULL AS [ProductID],
        NULL AS [CreditProductID], NULL AS [InternetID], NULL AS [EmployeeID], NULL AS [BranchID],
        NULL AS [PartnerID], NULL AS [Partner],
        
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
        NULL AS [CommitteeDecisionDate]   
    FROM [ATK].[mis].[Bronze_Документы.ОбъединеннаяИнтернетЗаявка] o
    LEFT JOIN [ATK].[mis].[Bronze_Документы.ЗаявкаНаКредит] z
        ON z.[ЗаявкаНаКредит ID] = o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
    WHERE z.[ЗаявкаНаКредит ID] IS NULL
       OR o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID] = ''00000000000000000000000000000000''
)




INSERT INTO mis.[Gold_Fact_CerereOnline]
(
    [ID],[Date],[Status],[Posted],[BusinessSector],[Type],[HistoryType],
    [CreditID],[AuthorID],[Author],[Purpose],[IsGreen],[ClientID],[CreditAmount],[NewExisting_Client],
    [RefusalReason],[CreditProduct],[ProductID],[CreditProductID],[InternetID],[EmployeeID],[BranchID],
    [PartnerID],[Partner],
    
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
        WHEN b.CreditAmount IS NULL OR b.CreditAmount <= 0 THEN N''Cancelled''
        WHEN ROW_NUMBER() OVER (PARTITION BY b.ClientKey ORDER BY b.WebDate) = 1 THEN N''New''
        ELSE N''Existing''
    END AS [NewExisting_Client],
    b.[RefusalReason], b.[CreditProduct], b.[ProductID], b.[CreditProductID],
    b.[InternetID], b.[EmployeeID], b.[BranchID],
    b.[PartnerID], b.[Partner],
    
	b.[WebDate], b.[WebNr], b.[WebPosted], b.[WebIncomeTypeOnline], b.[WebAge],
    b.[WebSubmissionDate], b.[WebCredit], b.[WebIdentifier], b.[WebCreditEmployee], b.[WebMobilePhone],
    b.[WebSentForReview], b.[WebGender], b.[WebStatus], b.[WebCreditTerm], b.[WebBranchID],
    b.[CommitteeDecisionDate]
FROM Base b
LEFT JOIN dbo.[Справочники.Контрагенты] AS c
    ON b.[ClientID] = c.[Контрагенты ID]
WHERE c.[Контрагенты Тестовый Контрагент] = 00;';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.Gold_Fact_CreditsInShadowBranches.sql
    SET @sql = N'IF OBJECT_ID(''mis.[Gold_CreditsInShadowBranches]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_CreditsInShadowBranches];

IF OBJECT_ID(N''[mis].[Gold_CreditsInShadowBranches]'',''U'') IS NOT NULL DROP TABLE [mis].[Gold_CreditsInShadowBranches];
CREATE TABLE [mis].[Gold_CreditsInShadowBranches](
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
    FROM [ATK].[mis].[Bronze_РегистрыСведений.КредитыВТеневыхФилиалах] rs
	WHERE rs.[КредитыВТеневыхФилиалах Период] >= ''2023-01-01''
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
INSERT INTO mis.[Gold_CreditsInShadowBranches] (
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
FROM calc;';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.Gold_Fact_WriteOffCredits.sql
    SET @sql = N'IF OBJECT_ID(''mis.[Gold_Fact_WriteOffCredits]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_WriteOffCredits];

CREATE TABLE mis.[Gold_Fact_WriteOffCredits]
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
	[Canceled_DebitAccount]  NVARCHAR(250) NULL,
    [FinalBranchID]   VARCHAR(36) NULL,
    [FinalExpertID]   VARCHAR(36) NULL
);

INSERT INTO mis.[Gold_Fact_WriteOffCredits]
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
	[Canceled_DebitAccount],
	[FinalBranchID],
    [FinalExpertID]
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
	b.[АнулированиеКредитов Счет Дт],
	lastResp.FinalBranchID,
	lastResp.FinalExpertID
FROM [ATK].[dbo].[Документы.АнулированиеКредитов.Кредиты] AS a
LEFT JOIN [ATK].[dbo].[Документы.АнулированиеКредитов] AS b
    ON a.[АнулированиеКредитов ID] = b.[АнулированиеКредитов ID]
OUTER APPLY (
    SELECT TOP (1)
           c.[BranchID] AS FinalBranchID,
           c.[ExpertID] AS FinalExpertID
    FROM [ATK].[mis].[2tbl_Silver_Resp_SCD] c
    WHERE c.[CreditID] = a.[АнулированиеКредитов.Кредиты Кредит ID]
    ORDER BY 
        ISNULL(CAST(c.[ValidTo] AS date), CONVERT(date,''9999-12-31'')) DESC,
        CAST(c.[ValidFrom] AS date) DESC,
        c.[BranchID] DESC,
        c.[ExpertID] DESC
) AS lastResp;

CREATE INDEX IX_WriteOff_CreditID 
    ON [ATK].[mis].[Gold_Fact_WriteOffCredits] ([Credit_CreditID]);

CREATE INDEX IX_WriteOff_Final 
    ON [ATK].[mis].[Gold_Fact_WriteOffCredits] ([FinalBranchID], [FinalExpertID]);';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.Gold_Fact_Disbursement.sql
    SET @sql = N'IF OBJECT_ID(''tempdb..#Base'')   IS NOT NULL DROP TABLE #Base;
IF OBJECT_ID(''tempdb..#Status'') IS NOT NULL DROP TABLE #Status;
IF OBJECT_ID(''tempdb..#Final'')  IS NOT NULL DROP TABLE #Final;

IF OBJECT_ID(''mis.[Gold_Fact_Disbursement]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_Disbursement];

CREATE TABLE mis.[Gold_Fact_Disbursement] 
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

SELECT
    d.[ДанныеКредитовВыданных Кредит ID]                 AS CreditID,
    k.[Кредиты Владелец]                                 AS ClientID,
    d.[ДанныеКредитовВыданных Дата Выдачи]               AS DisbursementDate,
    d.[ДанныеКредитовВыданных Валюта Кредита ID]         AS CurrencyID,

    
    finalAmount.ChosenAmount                              AS CreditAmount,

    
    ROUND(finalAmount.ChosenAmount * ISNULL(rate.Rate, 1), 2) AS CreditAmountInMDL,

    d.[ДанныеКредитовВыданных Валюта Кредита]            AS CreditCurrency,
    firstR.[ФилиалID]                                     AS FirstFilialID,
    firstR.[ЭкспертID]                                    AS FirstEmployeeID,
    COALESCE(lastR_month.[ФилиалID], firstR.[ФилиалID])   AS LastFilialID,
    COALESCE(lastR_month.[ЭкспертID], firstR.[ЭкспертID]) AS LastEmployeeID,
    irr.IRR                                               AS IRR,
    irr.IRR_Client                                        AS IRR_Client,
    emp.EmployeePositionID                                 AS EmployeePositionID,

    
    proto_refin.[ПротоколКомитета Сумма Рефинансирования Кредита] AS CreditRefinancingAmount,

    rn = ROW_NUMBER() OVER (
            PARTITION BY d.[ДанныеКредитовВыданных Кредит ID]
            ORDER BY d.[ДанныеКредитовВыданных Дата Выдачи]
         )
INTO #Base
FROM [ATK].[mis].[Bronze_РегистрыСведений.ДанныеКредитовВыданных] d
INNER JOIN [ATK].[mis].[Bronze_Справочники.Кредиты] k
    ON k.[Кредиты ID] = d.[ДанныеКредитовВыданных Кредит ID]

                              
OUTER APPLY (
    SELECT TOP 1 v.[Валюта Курс] AS Rate
    FROM [ATK].[mis].[Bronze_РегистрыСведений.Валюта] v
    WHERE v.[Валюта Валюта ID] = d.[ДанныеКредитовВыданных Валюта Кредита ID]
      AND v.[Валюта Период] <= d.[ДанныеКредитовВыданных Период]
    ORDER BY v.[Валюта Период] DESC
) rate

                                  
OUTER APPLY (
    SELECT TOP 1
           r.[ОтветственныеПоКредитамВыданным Филиал ID]            AS [ФилиалID],
           r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID]  AS [ЭкспертID]
    FROM [ATK].[mis].[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным] r
    WHERE r.[ОтветственныеПоКредитамВыданным Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
    ORDER BY r.[ОтветственныеПоКредитамВыданным Период] ASC
) firstR

                                   
OUTER APPLY (
    SELECT TOP 1
           r.[ОтветственныеПоКредитамВыданным Филиал ID]            AS [ФилиалID],
           r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID]  AS [ЭкспертID]
    FROM [ATK].[mis].[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным] r
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
    FROM [ATK].[mis].[Bronze_Документы.УстановкаДанныхКредита] doc
    WHERE doc.[УстановкаДанныхКредита Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
    ORDER BY doc.[УстановкаДанныхКредита Дата] ASC
) irr

                                           
OUTER APPLY (
    SELECT TOP 1 e.[СотрудникиДанныеПоЗарплате Должность ID] AS EmployeePositionID
    FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате] e
    WHERE e.[СотрудникиДанныеПоЗарплате Сотрудник ID] = COALESCE(lastR_month.[ЭкспертID], firstR.[ЭкспертID])
    ORDER BY e.[СотрудникиДанныеПоЗарплате Период] DESC
) emp

                                                                       
OUTER APPLY (
    SELECT TOP 1 p.[ПротоколКомитета Сумма на Выдачу]
    FROM [ATK].[mis].[Bronze_Документы.ПротоколКомитета] p
    WHERE p.[ПротоколКомитета Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
    ORDER BY p.[ПротоколКомитета Дата] DESC, p.[ПротоколКомитета ID] DESC
) proto

                                                
OUTER APPLY (
    SELECT TOP 1 p2.[ПротоколКомитета Сумма Рефинансирования Кредита]
    FROM [ATK].[mis].[Bronze_Документы.ПротоколКомитета] p2
    WHERE p2.[ПротоколКомитета Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
    ORDER BY p2.[ПротоколКомитета Дата] DESC, p2.[ПротоколКомитета ID] DESC
) proto_refin

                                                             
OUTER APPLY (
    SELECT 
        ChosenAmount = CASE
            WHEN k.[Кредиты Цель Кредита ID] = ''B9D1CEBE56F4877143FDF0DD7CAE2AE4''
                 THEN ISNULL(proto.[ПротоколКомитета Сумма на Выдачу], d.[ДанныеКредитовВыданных Сумма Кредита])
            ELSE d.[ДанныеКредитовВыданных Сумма Кредита]
        END
) finalAmount

WHERE d.[ДанныеКредитовВыданных Кредитный Продукт] NOT LIKE N''Medier%''
  AND d.[ДанныеКредитовВыданных Дата Выдачи] >= ''2024-01-01'';

WITH BaseIDs AS (
    SELECT DISTINCT CreditID FROM #Base
),
Cancels AS (
    SELECT a.[АнулированныеКредитыПартнеров Кредит ID] AS CreditID,
           MAX(a.[АнулированныеКредитыПартнеров Период]) AS CancelPeriod
    FROM [ATK].[mis].[Bronze_РегистрыСведений.АнулированныеКредитыПартнеров] a
    INNER JOIN BaseIDs b ON b.CreditID = a.[АнулированныеКредитыПартнеров Кредит ID]
    WHERE a.[АнулированныеКредитыПартнеров Кредит Анулирован] = N''01''
    GROUP BY a.[АнулированныеКредитыПартнеров Кредит ID]
),
Restores AS (
    SELECT a.[АнулированныеКредитыПартнеров Кредит ID] AS CreditID,
           MAX(a.[АнулированныеКредитыПартнеров Период]) AS RestorePeriod
    FROM [ATK].[mis].[Bronze_РегистрыСведений.АнулированныеКредитыПартнеров] a
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

SELECT
    b.CreditID, b.ClientID, b.DisbursementDate, b.CurrencyID,
    b.CreditAmount, b.CreditAmountInMDL, b.CreditCurrency,
    b.FirstFilialID, b.FirstEmployeeID, b.LastFilialID, b.LastEmployeeID,
    b.IRR, b.IRR_Client, 1 AS Qty,
    b.EmployeePositionID
INTO #Final
FROM #Base b
WHERE b.rn = 1;


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

WITH AllSeq AS (
    SELECT
        f.*,
        ROW_NUMBER() OVER (
            PARTITION BY f.ClientID
            ORDER BY f.DisbursementDate, f.CreditID
        ) AS rn_all
    FROM #Final f
)
INSERT INTO mis.[Gold_Fact_Disbursement]
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
        WHEN a.CreditAmount > 0 AND a.rn_all = 1 THEN N''New''
        WHEN a.CreditAmount > 0 THEN N''Existing''
        ELSE N''Cancelled''
    END AS NewExisting_Client,
    a.EmployeePositionID
FROM AllSeq AS a
LEFT JOIN dbo.[Справочники.Контрагенты] AS c
    ON a.ClientID = c.[Контрагенты ID]
WHERE c.[Контрагенты Тестовый Контрагент] = 00;

CREATE CLUSTERED INDEX CIX_Disbursement_DisbursementDate_ClientID
ON mis.[Gold_Fact_Disbursement] (DisbursementDate ASC, ClientID ASC);

CREATE NONCLUSTERED INDEX IX_Disbursement_CreditID
ON mis.[Gold_Fact_Disbursement] (CreditID);

CREATE NONCLUSTERED INDEX IX_Disbursement_FirstFilialID
ON mis.[Gold_Fact_Disbursement] (FirstFilialID);

CREATE NONCLUSTERED INDEX IX_Disbursement_LastFilialID
ON mis.[Gold_Fact_Disbursement] (LastFilialID);

CREATE NONCLUSTERED INDEX IX_Disbursement_NewExisting
ON mis.[Gold_Fact_Disbursement] (NewExisting_Client);

CREATE NONCLUSTERED INDEX IX_Disbursement_ClientID
ON mis.[Gold_Fact_Disbursement] (ClientID);

DROP TABLE #Base;
DROP TABLE #Status;
DROP TABLE #Final;';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.Gold_Fact_Par_Restruct_Daily_Min.sql
    SET @sql = N'SET NOCOUNT ON;

                                                     
DECLARE @DateFrom date = ''2024-01-01'';
DECLARE @DateTo   date = ''2025-12-31'';

PRINT N''=== Пересборка [mis].[Gold_Par_Restruct_Daily_Min] за период ''
      + CONVERT(varchar(10), @DateFrom, 23) + N'' — '' + CONVERT(varchar(10), @DateTo, 23) + N'' ==='';

BEGIN TRAN; 

                                               
IF OBJECT_ID(''tempdb..#Base'')         IS NOT NULL DROP TABLE #Base;
IF OBJECT_ID(''tempdb..#MaxDays'')      IS NOT NULL DROP TABLE #MaxDays;
IF OBJECT_ID(''tempdb..#Flag'')         IS NOT NULL DROP TABLE #Flag;
IF OBJECT_ID(''tempdb..#RespEarliest'') IS NOT NULL DROP TABLE #RespEarliest;
IF OBJECT_ID(''tempdb..#Joined_raw'')   IS NOT NULL DROP TABLE #Joined_raw;
IF OBJECT_ID(''tempdb..#Joined'')       IS NOT NULL DROP TABLE #Joined;

                                                           
IF OBJECT_ID(''[mis].[Gold_Par_Restruct_Daily_Min]'', ''U'') IS NOT NULL
BEGIN
    DROP TABLE [mis].[Gold_Par_Restruct_Daily_Min];
    PRINT N''Старая таблица удалена.'';
END;

IF OBJECT_ID(N''[mis].[Gold_Par_Restruct_Daily_Min]'',''U'') IS NOT NULL DROP TABLE [mis].[Gold_Par_Restruct_Daily_Min];
CREATE TABLE [mis].[Gold_Par_Restruct_Daily_Min](
    SoldDate               date          NOT NULL,
    CreditID               varchar(64)   NOT NULL,
    ClientID               varchar(64)   NOT NULL,
    Balance_Total          money         NULL,
    DaysBucket_Credit      int           NULL,
    DaysFact_Total         int           NULL,
    DaysIFRS               int           NULL,
    StateName_Final        nvarchar(200) NULL,
    TypeName_Sticky_Final  nvarchar(200) NULL,
    CreditStatus_Base      nvarchar(200) NULL,
    LastBranchID           varchar(64)   NULL,
    LastExpertID           varchar(64)   NULL,
    IsSpecialBranch        bit           NULL,
    SegmentIFRS            nvarchar(20)  NULL,
    ParIFRS                nvarchar(20)  NULL,
	StageName              nvarchar(200) NULL,
    CONSTRAINT PK_Gold_ParRestructDailyMin
        PRIMARY KEY (ClientID, CreditID, SoldDate)
);

                                                                           
PRINT N''Шаг 1 — подготовка базы...'';

;WITH cte AS (
    SELECT
        s.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS SoldDate,		
        s.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
        s.[СуммыЗадолженностиПоПериодамПросрочки Клиент ID] AS ClientID,
        s.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит]   AS Balance_Total,
        s.[СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки Кредит]   AS DaysBucket_Credit,
        s.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого]   AS DaysFact_Total,
        s.[СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки МСФО]     AS DaysIFRS,
        r.StateName            AS StateName_Final,
        r.TypeName_Sticky      AS TypeName_Sticky_Final,
        r.CreditStatus         AS CreditStatus_Base,
        ROW_NUMBER() OVER (
            PARTITION BY s.[СуммыЗадолженностиПоПериодамПросрочки Клиент ID],  s.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID], 
			s.[СуммыЗадолженностиПоПериодамПросрочки Дата]
            ORDER BY s.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] DESC, s.[СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки Кредит] DESC
        ) AS rn
    FROM [ATK].[mis].[Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] s
    LEFT JOIN [ATK].[mis].[Silver_Restruct_Merged_SCD] r
           ON r.CreditID = s.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
          AND s.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= r.ValidFrom
          AND s.[СуммыЗадолженностиПоПериодамПросрочки Дата] <= r.ValidTo
    WHERE s.[СуммыЗадолженностиПоПериодамПросрочки Дата] BETWEEN @DateFrom AND @DateTo
)
SELECT
    SoldDate, CreditID, ClientID,
    Balance_Total, DaysBucket_Credit, DaysFact_Total, DaysIFRS,
    StateName_Final, TypeName_Sticky_Final, CreditStatus_Base
INTO #Base
FROM cte
WHERE rn = 1
OPTION (RECOMPILE);

CREATE CLUSTERED INDEX CIX_Base_ClientDateCredit
ON #Base (ClientID, SoldDate, CreditID);

CREATE NONCLUSTERED INDEX IX_Base_CreditDate
ON #Base (CreditID, SoldDate)
INCLUDE (Balance_Total, DaysBucket_Credit, DaysFact_Total, DaysIFRS,
         StateName_Final, TypeName_Sticky_Final, CreditStatus_Base);

PRINT N''✅ Шаг 1: строк '' + CONVERT(varchar(30), @@ROWCOUNT);

                                              
SELECT
    ClientID,
    SoldDate,
    MAX(DaysFact_Total) AS MaxDaysPerClientDay
INTO #MaxDays
FROM #Base
GROUP BY ClientID, SoldDate;

CREATE UNIQUE CLUSTERED INDEX CIX_MaxDays ON #MaxDays (ClientID, SoldDate);

                                                          
SELECT ClientID, SoldDate
INTO #Flag
FROM [ATK].[mis].[Silver_Client_UnhealedFlag]
WHERE HasUnhealed = 1
  AND SoldDate BETWEEN @DateFrom AND @DateTo;

CREATE UNIQUE CLUSTERED INDEX CIX_Flag ON #Flag (ClientID, SoldDate);

                                                                     
;WITH MinFrom AS (
    SELECT CreditID, MIN(ValidFrom) AS MinValidFrom
    FROM [ATK].[mis].[Silver_Resp_SCD]
    GROUP BY CreditID
)
SELECT
    r.CreditID,
    r.FinalBranchID,
    r.FinalExpertID,
    r.IsSpecialBranch
INTO #RespEarliest
FROM [ATK].[mis].[Silver_Resp_SCD] r
JOIN MinFrom m
  ON r.CreditID = m.CreditID
 AND r.ValidFrom = m.MinValidFrom;

CREATE UNIQUE CLUSTERED INDEX CIX_RespEarliest ON #RespEarliest (CreditID);

                                                                          
PRINT N''Шаг 2 — привязка филиала/эксперта...'';

SELECT
    b.SoldDate,
    b.CreditID,
    b.ClientID,
    b.Balance_Total,
    b.DaysBucket_Credit,
    b.DaysFact_Total,
    b.DaysIFRS,
    b.StateName_Final,
    b.TypeName_Sticky_Final,
    b.CreditStatus_Base,
    COALESCE(r_curr.FinalBranchID, e.FinalBranchID)    AS LastBranchID,
    COALESCE(r_curr.FinalExpertID, e.FinalExpertID)    AS LastExpertID,
    COALESCE(r_curr.IsSpecialBranch, e.IsSpecialBranch) AS IsSpecialBranch,
	s.StageName AS CurrentStage
INTO #Joined_raw
FROM #Base b
OUTER APPLY (
    SELECT TOP (1) *
    FROM [ATK].[mis].[Silver_Resp_SCD] r
    WHERE r.CreditID = b.CreditID
      AND b.SoldDate BETWEEN r.ValidFrom AND r.ValidTo
    ORDER BY r.ValidFrom DESC
) r_curr
LEFT JOIN #RespEarliest e
       ON e.CreditID = b.CreditID
LEFT JOIN [ATK].[mis].[Silver_Stages_SCD] s
       ON s.CreditID = b.CreditID
      AND b.SoldDate BETWEEN s.ValidFrom AND s.ValidTo
OPTION (RECOMPILE);

CREATE CLUSTERED INDEX CIX_JoinedRaw_ClientDate
ON #Joined_raw (ClientID, SoldDate, CreditID);

                                                                    
SELECT
    jr.SoldDate,
    jr.CreditID,
    jr.ClientID,
    jr.Balance_Total,
    jr.DaysBucket_Credit,
    jr.DaysFact_Total,
    jr.DaysIFRS,
    jr.StateName_Final,
    jr.TypeName_Sticky_Final,
    jr.CreditStatus_Base,
    jr.LastBranchID,
    jr.LastExpertID,
    jr.IsSpecialBranch,
    CASE 
        WHEN md.MaxDaysPerClientDay BETWEEN 1  AND 30  THEN N''Par0''
        WHEN md.MaxDaysPerClientDay BETWEEN 31 AND 60  THEN N''Par30''
        WHEN md.MaxDaysPerClientDay BETWEEN 61 AND 90  THEN N''Par60''
        WHEN md.MaxDaysPerClientDay BETWEEN 91 AND 180 THEN N''Par90''
        WHEN md.MaxDaysPerClientDay BETWEEN 181 AND 270 THEN N''Par180''
        WHEN md.MaxDaysPerClientDay BETWEEN 271 AND 360 THEN N''Par270''
        WHEN md.MaxDaysPerClientDay > 360           THEN N''Par360''
        ELSE NULL
    END AS ParIFRS
INTO #Joined
FROM #Joined_raw jr
JOIN #MaxDays md
  ON md.ClientID = jr.ClientID
 AND md.SoldDate = jr.SoldDate;

CREATE CLUSTERED INDEX CIX_Joined_ClientDate
ON #Joined (ClientID, SoldDate, CreditID);

                                                                  
PRINT N''Шаг 3 — вставка результата...'';

INSERT                INTO [mis].[Gold_Par_Restruct_Daily_Min] WITH (TABLOCK)
(
    SoldDate, CreditID, ClientID,
    Balance_Total, DaysBucket_Credit, DaysFact_Total, DaysIFRS,
    StateName_Final, TypeName_Sticky_Final, CreditStatus_Base,
    LastBranchID, LastExpertID, IsSpecialBranch, SegmentIFRS, ParIFRS, StageName 
)
SELECT
    j.SoldDate,
    j.CreditID,
    j.ClientID,
    j.Balance_Total,
    j.DaysBucket_Credit,
    j.DaysFact_Total,
    j.DaysIFRS,
    CASE
        WHEN f.ClientID IS NOT NULL
         AND ISNULL(j.StateName_Final, N'''') <> N''НеИзлеченный''
        THEN N''Nevindecat contaminat''
        ELSE j.StateName_Final
    END AS StateName_Final,
    CASE
        WHEN f.ClientID IS NOT NULL
        THEN N''НекоммерческаяРеструктуризация''
        ELSE j.TypeName_Sticky_Final
    END AS TypeName_Sticky_Final,
    j.CreditStatus_Base,
    j.LastBranchID,
    j.LastExpertID,
    j.IsSpecialBranch,
    CASE
        WHEN j.DaysIFRS >=  91 THEN N''e) 90 +''
        WHEN j.DaysIFRS >=  31 THEN N''d) 30 - 90''
        WHEN j.DaysIFRS >=  16 THEN N''c) 16 - 30''
        WHEN j.DaysIFRS >=   4 THEN N''b) 4 - 15''
        WHEN j.DaysIFRS >=   0 THEN N''a) 0 - 3''
        ELSE N''e) 90 +''
    END AS SegmentIFRS,
    j.ParIFRS,
	j.CurrentStage
FROM #Joined j
LEFT JOIN #Flag f
  ON f.ClientID = j.ClientID
 AND f.SoldDate = j.SoldDate
OPTION (RECOMPILE);

PRINT N''✅ Вставка завершена.'';

                                               
DROP TABLE #Base;
DROP TABLE #MaxDays;
DROP TABLE #Flag;
DROP TABLE #RespEarliest;
DROP TABLE #Joined_raw;
DROP TABLE #Joined;

                                             
DECLARE @cnt bigint;
SELECT @cnt = COUNT_BIG(*) FROM [mis].[Gold_Par_Restruct_Daily_Min];
PRINT N''🏁 Готово. Строк: '' + CONVERT(varchar(30), @cnt);

COMMIT TRAN;

                                                       
CREATE INDEX IX_RespSCD_Credit_FromTo
ON [ATK].[mis].[Silver_Resp_SCD](CreditID, ValidFrom, ValidTo)
INCLUDE (FinalBranchID, FinalExpertID, IsSpecialBranch);

CREATE INDEX IX_ParMin_SoldDate   ON [mis].[Gold_Par_Restruct_Daily_Min](SoldDate);
CREATE INDEX IX_ParMin_ClientDate ON [mis].[Gold_Par_Restruct_Daily_Min](ClientID, SoldDate)
INCLUDE (ParIFRS, SegmentIFRS, Balance_Total, CreditID);';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

END
GO
