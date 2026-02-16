-- Compiled SQL bundle
-- Generated: 2026-02-16 10:14:34
-- Source folder: C:\ATK_Project\sql_scripts\Gold
-- Files (25):
--   mis.Gold_Dim_AppUsers.sql
--   mis.Gold_Dim_Branch.sql
--   mis.Gold_Dim_Clients.sql
--   mis.Gold_Dim_Credits.sql
--   mis.Gold_Dim_EmployeePayrollData.sql
--   mis.Gold_Dim_Employees.sql
--   mis.Gold_Dim_EmployeesHistory.sql
--   mis.Gold_Dim_Events.sql
--   mis.Gold_Dim_GroupMembershipPeriods.sql
--   mis.Gold_Dim_PartnersBranch.sql
--   mis.Gold_Fact_AdminTasks.sql
--   mis.Gold_Fact_ArchiveDocument.sql
--   mis.Gold_Fact_BudgetEmployees.sql
--   mis.Gold_Fact_CerereOnline.sql
--   mis.Gold_Fact_Comments.sql
--   mis.Gold_Fact_CPD.sql
--   mis.Gold_Fact_CreditsInShadowBranches.sql
--   mis.Gold_Fact_WriteOffCredits.sql
--   mis.Gold_Fact_Restruct_Daily_Min.sql
--   mis.Gold_Fact_Disbursement.sql
--   mis.Gold_Fact_Sold_Par.sql
--   V2__inc_Gold_Dim_Event_InProgress.sql
--   V2__inc_Gold_Dim_Event_Responsible.sql
--   V2__inc_Gold_Dim_Limits.sql
--   V3__inc_Gold_Fact_Restruct_Daily_Sold_Par.sql
----------------------------------------------------------------------------------------------------

SET NOCOUNT ON;

----------------------------------------------------------------------------------------------------
-- Start of: mis.Gold_Dim_AppUsers.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO

IF OBJECT_ID('mis.[Gold_Dim_AppUsers]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_AppUsers];
GO

CREATE TABLE mis.[Gold_Dim_AppUsers]
(
    App_User_ClientID VARCHAR(36) NOT NULL,
    App_User_UserID VARCHAR(36) NOT NULL,
    App_User_Phone NVARCHAR(50) NULL,
    App_User_FiscalCode NVARCHAR(20) NULL,
    App_User_ClientName NVARCHAR(100) NULL
);
GO

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

FROM [ATK].[mis].[Bronze_РегистрыСведений.СведенияОПользователяхМобильногоПриложения];
----------------------------------------------------------------------------------------------------
-- End of:   mis.Gold_Dim_AppUsers.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Gold_Dim_Branch.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO

IF OBJECT_ID(N'mis.[Gold_Dim_Branch]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_Branch];
GO

CREATE TABLE mis.[Gold_Dim_Branch] 
(
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
	BranchDepartmentID VARCHAR(36) NULL,
    BranchRegion NVARCHAR(100) NULL,
	BranchRegionID VARCHAR(36) NULL
);
GO

WITH LastSvedeniya AS (
    SELECT 
        [СведенияОФилиалах Филиал ID],
        [СведенияОФилиалах Дирекция],
		[СведенияОФилиалах Дирекция ID],
        [СведенияОФилиалах Регион],
		[СведенияОФилиалах Регион ID],
        ROW_NUMBER() OVER (
            PARTITION BY [СведенияОФилиалах Филиал ID] 
            ORDER BY [СведенияОФилиалах Период] DESC
        ) AS rn
    FROM [ATK].[dbo].[РегистрыСведений.СведенияОФилиалах]
)
INSERT INTO mis.[Gold_Dim_Branch] 
(
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
	BranchDepartmentID,
    BranchRegion,
	BranchRegionID
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
	s.[СведенияОФилиалах Дирекция ID],
    s.[СведенияОФилиалах Регион],
	s.[СведенияОФилиалах Регион ID]
FROM [ATK].[dbo].[Справочники.Филиалы] f
LEFT JOIN LastSvedeniya s
    ON f.[Филиалы ID] = s.[СведенияОФилиалах Филиал ID]
    AND s.rn = 1;
GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.Gold_Dim_Branch.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Gold_Dim_Clients.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*==============================================================
  DROP + CREATE TABLE
==============================================================*/
IF OBJECT_ID(N'mis.Gold_Dim_Clients', 'U') IS NOT NULL
    DROP TABLE mis.Gold_Dim_Clients;
GO

CREATE TABLE mis.Gold_Dim_Clients
(
    ClientID                VARCHAR(36)  NOT NULL,
    ParentID                VARCHAR(36)  NOT NULL,
    BranchID                VARCHAR(36)  NULL,
    IsDeleted               VARCHAR(36)  NULL,
    IsGroup                 VARCHAR(36)  NULL,
    ClientCode              NCHAR(50)     NULL,
    ClientName              NVARCHAR(100) NULL,
    IsBlocked               VARCHAR(36)  NULL,
    Visibility              INT           NULL,
    Age                     INT           NULL,
    AgeGroup                NVARCHAR(10)  NULL,
    City                    NVARCHAR(30)  NULL,
    CreatedDate             DATETIME2(0)  NULL,
    PartnerCode             NVARCHAR(3)   NULL,
    FullName                NVARCHAR(100) NULL,
    IsNonResident           INT           NULL,
    NoPaymentNotification   VARCHAR(36)  NULL,
    Gender                  NVARCHAR(256) NULL,
    PostalAddress           NVARCHAR(85)  NULL,
    Country                 NVARCHAR(30)  NULL,
    MobilePhone1            NVARCHAR(50)  NULL,
    MobilePhone2            NVARCHAR(50)  NULL,
    Phones                  NVARCHAR(50)  NULL,
    FiscalCode              NVARCHAR(20)  NULL,
    LegalAddress            NVARCHAR(85)  NULL,
    RegistrationDate        DATETIME2(0)  NULL,
    Language                NVARCHAR(25)  NULL,
    NoEmailNotifications    VARCHAR(36)  NULL,
    NoPromoSMS              VARCHAR(36)  NULL,
    EconomicSector          NVARCHAR(200) NULL,
    OrganizationType        NVARCHAR(52)  NULL,
    IsGroupOwner            BIT           NULL,
    GroupID                 NVARCHAR(20)  NULL,
    CRM_Region_Address      NVARCHAR(150) NULL,
    CRM_City_Address        NVARCHAR(150) NULL,
    CRM_Status              NVARCHAR(50)  NULL,
    CRM_ClientType          NVARCHAR(50)  NULL,
    CRM_Employee            NVARCHAR(100) NULL,
    Phone                   NVARCHAR(50)  NULL,
    ANK_LegalAddress        NVARCHAR(150) NULL,
    ANK_ActualAddress       NVARCHAR(150) NULL,

    CONSTRAINT PK_Gold_Dim_Clients
        PRIMARY KEY CLUSTERED (ClientID)
);
GO

/*==============================================================
  CTE PIPELINE
==============================================================*/

;WITH ContactInfoUnified AS
(
    SELECT
        ci.[КонтактнаяИнформация Объект ID] AS ClientID,
        ci.[КонтактнаяИнформация Представление] AS Phone,

        ROW_NUMBER() OVER (
            PARTITION BY ci.[КонтактнаяИнформация Объект ID]
            ORDER BY ci.[КонтактнаяИнформация Поле 2]
        ) AS rn
    FROM dbo.[РегистрыСведений.КонтактнаяИнформация] ci
    WHERE ci.[КонтактнаяИнформация Тип] = N'Телефон'
),

BaseData AS
(
    SELECT
        s.[Контрагенты ID]                      AS ClientID,
        s.[Контрагенты Родитель ID]             AS ParentID,
        s.[Контрагенты Филиал ID]               AS BranchID,
        s.[Контрагенты Пометка Удаления]        AS IsDeleted,
        s.[Контрагенты Это Группа]              AS IsGroup,
        s.[Контрагенты Код]                     AS ClientCode,
        s.[Контрагенты Наименование]            AS ClientName,
        s.[Контрагенты Блокирован]              AS IsBlocked,
        s.[Контрагенты Видимость]               AS Visibility,
        s.[Контрагенты Город]                   AS City,
        s.[Контрагенты Страна]                  AS Country,
        s.[Контрагенты Дата Создания]           AS CreatedDate,
        s.[Контрагенты Код Партнера]            AS PartnerCode,
        s.[Контрагенты Наименование Полное]     AS FullName,
        s.[Контрагенты Не Резидент]             AS IsNonResident,
        s.[Контрагенты Не Уведомлять об Оплате] AS NoPaymentNotification,
        s.[Контрагенты Пол]                     AS Gender,
        s.[Контрагенты Почт Адрес]              AS PostalAddress,
        s.[Контрагенты Телефон Мобильный 1]     AS MobilePhone1,
        s.[Контрагенты Телефон Мобильный 2]     AS MobilePhone2,
        s.[Контрагенты Телефоны]                AS Phones,
        s.[Контрагенты Фиск Код]                AS FiscalCode,
        s.[Контрагенты Юр Адрес]                AS LegalAddress,
        s.[Контрагенты Дата Регистрации]        AS RegistrationDate,
        s.[Контрагенты Язык]                    AS [Language],
        s.[Контрагенты Не Уведомлять Письмом]   AS NoEmailNotifications,
        s.[Контрагенты Не Отправлять Рекламные СМС] AS NoPromoSMS,
        s.[Контрагенты Сектор Экономики]        AS EconomicSector,
        fp.[ФормыПредприятия Наименование]      AS OrganizationType,

        CASE WHEN g.[ГруппыАффилированныхЛиц Владелец] = s.[Контрагенты ID]
             THEN 1 ELSE 0 END                  AS IsGroupOwner,

        g.[ГруппыАффилированныхЛиц Код]          AS GroupID,

        crm.[СлужебныйДанныеПоКлиентуДляCRM Статус]          AS CRM_Status,
        crm.[СлужебныйДанныеПоКлиентуДляCRM Тип Клиента CRM] AS CRM_ClientType,
        crm.[СлужебныйДанныеПоКлиентуДляCRM Сотрудник]       AS CRM_Employee,

        COALESCE(
            crm.[СлужебныйДанныеПоКлиентуДляCRM Регион Юр Адрес],
            crm.[СлужебныйДанныеПоКлиентуДляCRM Регион Факт Адрес],
            ank.[АнкетаПерсональныхДанныхКлиента Юридический Адрес]
        ) AS CRM_Region_Address,

        COALESCE(
            crm.[СлужебныйДанныеПоКлиентуДляCRM Населенный Пункт Юр Адрес],
            crm.[СлужебныйДанныеПоКлиентуДляCRM Населенный Пункт Факт Адрес],
            ank.[АнкетаПерсональныхДанныхКлиента Фактический Адрес]
        ) AS CRM_City_Address,

        ank.[АнкетаПерсональныхДанныхКлиента Юридический Адрес]  AS ANK_LegalAddress,
        ank.[АнкетаПерсональныхДанныхКлиента Фактический Адрес] AS ANK_ActualAddress,

        ci.Phone,

        COALESCE(
            NULLIF(r.[Контрагенты Возраст], '1753-01-01'),
            s.[Контрагенты Возраст]
        ) AS EffectiveDOB
    FROM mis.[Bronze_Справочники.Контрагенты] s
    LEFT JOIN mis.[Bronze_Справочники.Контрагенты] r
        ON r.[Контрагенты ID] = s.[Контрагенты Представитель Контрагента ID]
    LEFT JOIN dbo.[Справочники.ФормыПредприятия] fp
        ON fp.[ФормыПредприятия Наименование] = s.[Контрагенты Форма Организации]
    LEFT JOIN dbo.[РегистрыСведений.СоставГруппАффилированныхЛиц] sg
        ON sg.[СоставГруппАффилированныхЛиц Контрагент ID] = s.[Контрагенты ID]
    LEFT JOIN dbo.[Справочники.ГруппыАффилированныхЛиц] g
        ON g.[ГруппыАффилированныхЛиц ID] =
           sg.[СоставГруппАффилированныхЛиц Группа Аффилированных Лиц ID]
    LEFT JOIN dbo.[РегистрыСведений.СлужебныйДанныеПоКлиентуДляCRM] crm
        ON crm.[СлужебныйДанныеПоКлиентуДляCRM Клиент ID] = s.[Контрагенты ID]
    LEFT JOIN dbo.[Документы.АнкетаПерсональныхДанныхКлиента] ank
        ON ank.[АнкетаПерсональныхДанныхКлиента Клиент ID] = s.[Контрагенты ID]
    LEFT JOIN ContactInfoUnified ci
        ON ci.ClientID = s.[Контрагенты ID] AND ci.rn = 1
),

AgeCalc AS
(
    SELECT *,
        CASE
            WHEN EffectiveDOB IS NULL THEN NULL
            ELSE
                DATEDIFF(YEAR, EffectiveDOB, CAST(SYSDATETIME() AS date))
                - CASE
                    WHEN DATEADD(YEAR,
                         DATEDIFF(YEAR, EffectiveDOB, CAST(SYSDATETIME() AS date)),
                         EffectiveDOB) > CAST(SYSDATETIME() AS date)
                    THEN 1 ELSE 0
                  END
        END AS Age
    FROM BaseData
),

Final AS
(
    SELECT *,
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
        CASE Gender WHEN 'Ж' THEN 'F' WHEN 'М' THEN 'M' ELSE Gender END AS GenderClean,
        CASE [Language] WHEN 'Русский' THEN 'Russian'
                        WHEN 'Română' THEN 'Romanian'
                        ELSE [Language] END AS LanguageClean,
        ROW_NUMBER() OVER (PARTITION BY ClientID ORDER BY RegistrationDate DESC, CreatedDate DESC) AS rn
    FROM AgeCalc
)

-- Insert final data
INSERT INTO mis.[Gold_Dim_Clients]
SELECT
    f.ClientID, f.ParentID, f.BranchID, f.IsDeleted, f.IsGroup, f.ClientCode, f.ClientName, f.IsBlocked,
    f.Visibility, f.Age, f.AgeGroup, f.City, f.CreatedDate, f.PartnerCode, f.FullName, f.IsNonResident,
    f.NoPaymentNotification, f.GenderClean, f.PostalAddress, f.Country, f.MobilePhone1, f.MobilePhone2,
    f.Phones, f.FiscalCode, f.LegalAddress, f.RegistrationDate, f.LanguageClean,
    f.NoEmailNotifications, f.NoPromoSMS, f.EconomicSector, f.OrganizationType,
    f.IsGroupOwner, f.GroupID, f.CRM_Region_Address, f.CRM_City_Address,
    f.CRM_Status, f.CRM_ClientType, f.CRM_Employee,
    f.Phone, 
    f.ANK_LegalAddress, f.ANK_ActualAddress
FROM Final f
WHERE f.rn = 1;
GO

-- ===========================
-- Indexes
-- ===========================
CREATE NONCLUSTERED INDEX IX_Clients_Branch    ON mis.[Gold_Dim_Clients](BranchID)   INCLUDE (ClientName, IsBlocked);
CREATE NONCLUSTERED INDEX IX_Clients_AgeGroup  ON mis.[Gold_Dim_Clients](AgeGroup)  INCLUDE (City, Country);
CREATE NONCLUSTERED INDEX IX_Clients_IsDeleted ON mis.[Gold_Dim_Clients](IsDeleted) INCLUDE (ClientName);
CREATE NONCLUSTERED INDEX IX_Clients_Group     ON mis.[Gold_Dim_Clients](IsGroupOwner, GroupID);
CREATE NONCLUSTERED INDEX IX_Clients_Phone2    ON mis.[Gold_Dim_Clients](Phone);
GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.Gold_Dim_Clients.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Gold_Dim_Credits.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO

IF OBJECT_ID(N'mis.[Gold_Dim_Credits]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_Credits];
GO

CREATE TABLE mis.[Gold_Dim_Credits] 
(
    [CreditID] VARCHAR(36) NOT NULL PRIMARY KEY CLUSTERED,
    [Owner] VARCHAR(36) NULL,
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
        CreditID,
        MAX(CASE WHEN rn_first = 1 THEN FilialID END) AS FirstFilialID,
        MAX(CASE WHEN rn_first = 1 THEN EmployeeID END) AS FirstEmployeeID,
        MAX(CASE WHEN rn_last = 1 THEN FilialID END) AS LastFilialID,
        MAX(CASE WHEN rn_last = 1 THEN EmployeeID END) AS LastEmployeeID
    FROM (
        SELECT 
            [ОтветственныеПоКредитамВыданным Кредит ID] AS CreditID,
            [ОтветственныеПоКредитамВыданным Филиал ID] AS FilialID,
            [ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS EmployeeID,
            ROW_NUMBER() OVER(
                PARTITION BY [ОтветственныеПоКредитамВыданным Кредит ID]
                ORDER BY [ОтветственныеПоКредитамВыданным Период] ASC
            ) AS rn_first,
            ROW_NUMBER() OVER(
                PARTITION BY [ОтветственныеПоКредитамВыданным Кредит ID]
                ORDER BY [ОтветственныеПоКредитамВыданным Период] DESC
            ) AS rn_last
        FROM [ATK].[mis].[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным]
    ) t
    GROUP BY CreditID
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
        FROM [ATK].[mis].[Bronze_Документы.ПротоколКомитета] gc
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
		CASE 
		    WHEN seg.SegmentRevenue = 'Consum non-business'
			   AND fp.FinancialProductsMainGroup = 'Business'
			THEN 'Consumer'
            ELSE fp.FinancialProductsMainGroup
        END AS FinancialProductsMainGroup,   
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
----------------------------------------------------------------------------------------------------
-- End of:   mis.Gold_Dim_Credits.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Gold_Dim_EmployeePayrollData.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO

IF OBJECT_ID('mis.[Gold_Dim_EmployeePayrollData]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_EmployeePayrollData];
GO

CREATE TABLE mis.[Gold_Dim_EmployeePayrollData]
(
    EmployeePositionID VARCHAR(36) NOT NULL,
    EmployeePosition NVARCHAR(150) NULL
);
GO

INSERT INTO mis.[Gold_Dim_EmployeePayrollData] 
(
    EmployeePositionID,
    EmployeePosition
)
SELECT 
    [СотрудникиДанныеПоЗарплате Должность ID] AS EmployeePositionID,
	[СотрудникиДанныеПоЗарплате Должность] AS EmployeePosition
    

FROM [ATK].[mis].[Bronze_РегистрыСведений.СотрудникиДанныеПоЗарплате];
GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.Gold_Dim_EmployeePayrollData.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Gold_Dim_Employees.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO

IF OBJECT_ID('mis.[Gold_Dim_Employees]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_Employees];
GO

CREATE TABLE mis.[Gold_Dim_Employees] 
(
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
GO

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

    -- HireDate
    CASE 
        WHEN e.[Сотрудники Дата Приема] IS NULL OR e.[Сотрудники Дата Приема] = '1753-01-01' THEN N'N/A'
        ELSE FORMAT(e.[Сотрудники Дата Приема], 'yyyy-MM-dd')
    END AS HireDate,

    -- BirthDate
    CASE 
        WHEN e.[Сотрудники Дата Рождения] IS NULL OR e.[Сотрудники Дата Рождения] = '1753-01-01' THEN N'N/A'
        ELSE FORMAT(e.[Сотрудники Дата Рождения], 'yyyy-MM-dd')
    END AS BirthDate,

    -- DismissalDate
    CASE 
        WHEN e.[Сотрудники Дата Увольнения] IS NULL OR e.[Сотрудники Дата Увольнения] = '1753-01-01' THEN N'N/A'
        ELSE FORMAT(e.[Сотрудники Дата Увольнения], 'yyyy-MM-dd')
    END AS DismissalDate,

    e.[Сотрудники Табельный Номер] AS TimesheetNumber,

    -- ExperienceYears
    CASE 
        WHEN e.[Сотрудники Дата Приема] IS NULL OR e.[Сотрудники Дата Приема] = '1753-01-01' THEN NULL
        ELSE DATEDIFF(MONTH, e.[Сотрудники Дата Приема], 
             COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())
        ) / 12
    END AS ExperienceYears,

    -- Total months worked
    CASE 
        WHEN e.[Сотрудники Дата Приема] IS NULL OR e.[Сотрудники Дата Приема] = '1753-01-01' THEN NULL
        ELSE DATEDIFF(MONTH, e.[Сотрудники Дата Приема], 
             COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())
        )
    END AS ExperienceMonths,

    -- ExperienceYM
    CASE 
        WHEN e.[Сотрудники Дата Приема] IS NULL OR e.[Сотрудники Дата Приема] = '1753-01-01' THEN N'N/A'
        ELSE CAST(DATEDIFF(MONTH, e.[Сотрудники Дата Приема], 
                 COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())
            ) / 12 AS NVARCHAR(3)) 
            + N' years ' + 
            CAST(DATEDIFF(MONTH, e.[Сотрудники Дата Приема], 
                 COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())
            ) % 12 AS NVARCHAR(2)) 
            + N' months'
    END AS ExperienceYM,

    -- ExperienceMonthsRange
    CASE 
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())) BETWEEN 0 AND 5 THEN N'1-5 m'
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())) BETWEEN 6 AND 11 THEN N'6-11 m'
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())) BETWEEN 12 AND 35 THEN N'12-35 m'
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())) > 35 THEN N'36+ m'
        ELSE N'N/A'
    END AS ExperienceMonthsRange,

    -- ExperienceIndex
    CASE 
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())) BETWEEN 0 AND 5 THEN 1
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())) BETWEEN 6 AND 11 THEN 2
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())) BETWEEN 12 AND 35 THEN 3
        WHEN DATEDIFF(MONTH, e.[Сотрудники Дата Приема], COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())) > 35 THEN 4
        ELSE NULL
    END AS ExperienceIndex,

    -- EmploymentPeriod
    CASE 
        WHEN e.[Сотрудники Дата Приема] IS NULL OR e.[Сотрудники Дата Приема] = '1753-01-01' THEN N'N/A'
        WHEN e.[Сотрудники Дата Увольнения] IS NULL OR e.[Сотрудники Дата Увольнения] = '1753-01-01'
            THEN FORMAT(e.[Сотрудники Дата Приема], 'yyyy-MM-dd') + N' → Present'
        ELSE FORMAT(e.[Сотрудники Дата Приема], 'yyyy-MM-dd') + N' → ' + FORMAT(e.[Сотрудники Дата Увольнения], 'yyyy-MM-dd')
    END AS EmploymentPeriod,

    lastPos.[СотрудникиДанныеПоЗарплате Вид Должности] AS EmploymentPositionType,
    firstAssigned.FirstDate AS EmpPositionIDdate,
	
	 CASE 
        WHEN firstAssigned.FirstDate IS NULL OR firstAssigned.FirstDate = '1753-01-01' THEN NULL
        ELSE DATEDIFF(MONTH, firstAssigned.FirstDate, 
             COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())
        )
    END AS ExperienceMonthsLastPosition,
	
	 CASE 
        WHEN DATEDIFF(MONTH, firstAssigned.FirstDate, COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())) BETWEEN 0 AND 5 THEN N'1-5 m'
        WHEN DATEDIFF(MONTH, firstAssigned.FirstDate, COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())) BETWEEN 6 AND 11 THEN N'6-11 m'
        WHEN DATEDIFF(MONTH, firstAssigned.FirstDate, COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())) BETWEEN 12 AND 35 THEN N'12-35 m'
        WHEN DATEDIFF(MONTH, firstAssigned.FirstDate, COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())) > 35 THEN N'36+ m'
        ELSE N'N/A'
    END AS ExperienceMonthsRangeLastPosition,
	
	
	CASE 
        WHEN DATEDIFF(MONTH, firstAssigned.FirstDate, COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())) BETWEEN 0 AND 5 THEN 1
        WHEN DATEDIFF(MONTH, firstAssigned.FirstDate, COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())) BETWEEN 6 AND 11 THEN 2
        WHEN DATEDIFF(MONTH, firstAssigned.FirstDate, COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())) BETWEEN 12 AND 35 THEN 3
        WHEN DATEDIFF(MONTH, firstAssigned.FirstDate, COALESCE(NULLIF(e.[Сотрудники Дата Увольнения],'1753-01-01'), GETDATE())) > 35 THEN 4
        ELSE NULL
    END AS ExperienceIndexLastPosition

FROM [ATK].[dbo].[Справочники.Сотрудники] AS e
OUTER APPLY (
    -- get last/current position
    SELECT TOP 1 *
    FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате] AS b
    WHERE b.[СотрудникиДанныеПоЗарплате Сотрудник ID] = e.[Сотрудники ID]
    ORDER BY b.[СотрудникиДанныеПоЗарплате Период] DESC
) AS lastPos
OUTER APPLY (
    -- get first date when last position was assigned
    SELECT MIN(b.[СотрудникиДанныеПоЗарплате Период]) AS FirstDate
    FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате] AS b
    WHERE b.[СотрудникиДанныеПоЗарплате Сотрудник ID] = e.[Сотрудники ID]
      AND b.[СотрудникиДанныеПоЗарплате Вид Должности ID] = lastPos.[СотрудникиДанныеПоЗарплате Вид Должности ID]
) AS firstAssigned;
GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.Gold_Dim_Employees.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Gold_Dim_EmployeesHistory.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO


IF OBJECT_ID('mis.[Gold_Dim_EmployeesHistory]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_EmployeesHistory];
GO


CREATE TABLE mis.[Gold_Dim_EmployeesHistory] 
(
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

INSERT INTO mis.[Gold_Dim_EmployeesHistory] 
(
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
FROM [ATK].[mis].[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным];
GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.Gold_Dim_EmployeesHistory.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Gold_Dim_Events.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO

IF OBJECT_ID('mis.[Gold_Dim_Events]', 'U') IS NULL
BEGIN
    CREATE TABLE mis.[Gold_Dim_Events]
    (
        Event_Period        DATETIME        NOT NULL,
        Event_ID            VARCHAR(36)     NOT NULL PRIMARY KEY,
        Event_ClientID      VARCHAR(36)     NOT NULL,
        Event_Status        NVARCHAR(256)   NULL,
        Event_Kind          NVARCHAR(256)   NULL,
        Event_Type          NVARCHAR(256)   NULL,
        Event_Project       NVARCHAR(150)   NULL,
        Event_Content       NVARCHAR(1000)  NULL,
        Event_ResponsibleID VARCHAR(36)     NOT NULL,
        Event_Responsible   NVARCHAR(1000)  NULL,
        Event_NextDateEvent DATETIME        NOT NULL,
        Event_NextKindEvent NVARCHAR(256)   NULL,
        Event_BranchID      VARCHAR(36)     NOT NULL,
        Event_Branch_Name   NVARCHAR(256)   NULL,
        EmployeePosition    NVARCHAR(100)   NULL,
        EmployeeBranch      NVARCHAR(100)   NULL
    );
END
GO

IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IX_Salary_Employee_Period' 
      AND object_id = OBJECT_ID('mis.[Bronze_РегистрыСведений.СотрудникиДанныеПоЗарплате]')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Salary_Employee_Period
    ON mis.[Bronze_РегистрыСведений.СотрудникиДанныеПоЗарплате]
    (
        [СотрудникиДанныеПоЗарплате Сотрудник ID],
        [СотрудникиДанныеПоЗарплате Период] DESC
    )
    INCLUDE ([СотрудникиДанныеПоЗарплате Должность],
             [СотрудникиДанныеПоЗарплате Филиал]);
END
GO

INSERT INTO mis.[Gold_Dim_Events]
(
    Event_Period,
    Event_ID,
    Event_ClientID,
    Event_Status,
    Event_Kind,
    Event_Type,
    Event_Project,
    Event_Content,
    Event_ResponsibleID,
    Event_Responsible,
    Event_NextDateEvent,
    Event_NextKindEvent,
    Event_BranchID,
    Event_Branch_Name,
    EmployeePosition,
    EmployeeBranch
)
SELECT
    e.[СведенияОСобытиях Период],
    e.[СведенияОСобытиях ID],
    e.[СведенияОСобытиях Контрагент ID],
    e.[СведенияОСобытиях Состояние События],
    e.[СведенияОСобытиях Вид События],
    e.[СведенияОСобытиях Тип События],
    e.[СведенияОСобытиях Проект],
    e.[СведенияОСобытиях Содержание События],
    e.[СведенияОСобытиях Ответственный ID],
    e.[СведенияОСобытиях Ответственный],
    e.[СведенияОСобытиях Дата Следующего События],
    e.[СведенияОСобытиях Вид Следующего События],
    e.[СведенияОСобытиях Филиал ID],
    e.[СведенияОСобытиях Филиал],
    s.[СотрудникиДанныеПоЗарплате Должность],
    s.[СотрудникиДанныеПоЗарплате Филиал]
FROM [ATK].[dbo].[РегистрыСведений.СведенияОСобытиях] e
OUTER APPLY
(
    SELECT TOP 1
           p.[СотрудникиДанныеПоЗарплате Должность],
           p.[СотрудникиДанныеПоЗарплате Филиал]
    FROM mis.[Bronze_РегистрыСведений.СотрудникиДанныеПоЗарплате] p
    WHERE p.[СотрудникиДанныеПоЗарплате Сотрудник ID] = e.[СведенияОСобытиях Ответственный ID]
      AND p.[СотрудникиДанныеПоЗарплате Период] <= e.[СведенияОСобытиях Период]
    ORDER BY p.[СотрудникиДанныеПоЗарплате Период] DESC
) s
WHERE NOT EXISTS (
    SELECT 1
    FROM mis.[Gold_Dim_Events] g
    WHERE g.Event_ID = e.[СведенияОСобытиях ID]
);
GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.Gold_Dim_Events.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Gold_Dim_GroupMembershipPeriods.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO

IF OBJECT_ID('mis.[Gold_Dim_GroupMembershipPeriods]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_GroupMembershipPeriods];
GO

CREATE TABLE mis.[Gold_Dim_GroupMembershipPeriods]
(
    GroupID        VARCHAR(36) NOT NULL,
    PersonID       VARCHAR(36) NULL,
    PersonName     NVARCHAR(255) NOT NULL,
    PeriodOriginal DATETIME2(0) NOT NULL,
    ActiveFlag     VARCHAR(36) NULL,
    ExcludedFlag   VARCHAR(36) NULL,
    GroupName      NVARCHAR(255) NULL,
    GroupOwner     VARCHAR(36) NULL,
    GroupCode      NVARCHAR(50) NULL,
    GroupNameFull  NVARCHAR(255) NULL,
    GroupOwnerTax  NVARCHAR(50) NULL,
    PeriodStart    DATETIME2(0) NOT NULL,
    PeriodEnd      DATETIME2(0) NOT NULL
);
GO

WITH Events AS (
    SELECT
        sg.[СоставГруппАффилированныхЛиц Группа Аффилированных Лиц ID] AS GroupID,
        sg.[СоставГруппАффилированныхЛиц Контрагент ID] AS PersonID,
        sg.[СоставГруппАффилированныхЛиц Контрагент] AS PersonName,
        sg.[СоставГруппАффилированныхЛиц Период] AS PeriodOriginal,
        sg.[СоставГруппАффилированныхЛиц Активность] AS ActiveFlag,
        sg.[СоставГруппАффилированныхЛиц Исключен] AS ExcludedFlag,
        sg.[СоставГруппАффилированныхЛиц Группа Аффилированных Лиц] AS GroupName,

        g.[ГруппыАффилированныхЛиц Владелец] AS GroupOwner,
        g.[ГруппыАффилированныхЛиц Код] AS GroupCode,
        g.[ГруппыАффилированныхЛиц Наименование] AS GroupNameFull,
        g.[ГруппыАффилированныхЛиц Владелец Фиск Код] AS GroupOwnerTax,

        CASE WHEN sg.[СоставГруппАффилированныхЛиц Исключен] = '00'
             THEN 'Included' ELSE 'Excluded' END AS EventType,
        g.[ГруппыАффилированныхЛиц Пометка Удаления] AS DeletionFlag
    FROM [ATK].[dbo].[РегистрыСведений.СоставГруппАффилированныхЛиц] sg
    LEFT JOIN [ATK].[dbo].[Справочники.ГруппыАффилированныхЛиц] g
        ON g.[ГруппыАффилированныхЛиц ID] =
           sg.[СоставГруппАффилированныхЛиц Группа Аффилированных Лиц ID]
),

Dedup AS (
    SELECT *
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (
                   PARTITION BY
                       GroupID, PersonID, PersonName, PeriodOriginal,
                       ActiveFlag, ExcludedFlag, GroupName,
                       GroupOwner, GroupCode, GroupNameFull, GroupOwnerTax,
                       EventType, DeletionFlag
                   ORDER BY (SELECT NULL)
               ) AS rn
        FROM Events
    ) d
    WHERE rn = 1
),

Ordered AS (
    SELECT
        *,
        LEAD(PeriodOriginal) OVER (
            PARTITION BY GroupID, PersonID
            ORDER BY PeriodOriginal
        ) AS NextDate,
        LEAD(EventType) OVER (
            PARTITION BY GroupID, PersonID
            ORDER BY PeriodOriginal
        ) AS NextType
    FROM Dedup
)

INSERT INTO mis.[Gold_Dim_GroupMembershipPeriods]
(
    GroupID, PersonID, PersonName,
    PeriodOriginal, ActiveFlag, ExcludedFlag, GroupName,
    GroupOwner, GroupCode, GroupNameFull, GroupOwnerTax,
    PeriodStart, PeriodEnd
)
SELECT
    GroupID, PersonID, PersonName,
    PeriodOriginal, ActiveFlag, ExcludedFlag, GroupName,
    GroupOwner, GroupCode, GroupNameFull, GroupOwnerTax,
    PeriodOriginal AS PeriodStart,
    CASE 
        WHEN NextType = 'Excluded'
            THEN DATEADD(SECOND, -1, NextDate)
        ELSE CONVERT(DATETIME2(0), '2222-01-01 00:00:00')
    END AS PeriodEnd
FROM Ordered
WHERE EventType = 'Included'
  AND DeletionFlag = '00'
ORDER BY GroupID, PersonID, PeriodOriginal;
GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.Gold_Dim_GroupMembershipPeriods.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Gold_Dim_PartnersBranch.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO

IF OBJECT_ID('mis.[Gold_Dim_PartnersBranch]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_PartnersBranch];
GO

CREATE TABLE mis.[Gold_Dim_PartnersBranch]
(
    [PartnerBranchID]               VARCHAR(36) NOT NULL,
    [PartnerBranchDeletedFlag]      VARCHAR(36) NOT NULL,
    [PartnerBranchOwner]            VARCHAR(36) NOT NULL,
    [PartnerBranchCode]             NVARCHAR(3) NOT NULL,
    [PartnerBranchName]             NVARCHAR(150) NULL,
    [PartnerBranchAddress]          NVARCHAR(100) NULL,

    [PartnerOwnerName]              NVARCHAR(150) NULL,

    [DealerID]                      VARCHAR(36) NULL,
    [DealerDefaultEmployeeID]       VARCHAR(36) NULL,
    [DealerDefaultEmployeeName]     NVARCHAR(50) NULL,
    [DealerOrgRepID]                VARCHAR(36) NULL,
    [DealerOrgRepName]              NVARCHAR(50) NULL,
    [DealerCabinetID]               VARCHAR(36) NULL,
    [DealerCabinetType]             NVARCHAR(25) NULL,
    [Contact_Info]                  NVARCHAR(150) NULL
);
GO

;WITH ContactInfoRanked AS
(
    SELECT
        ci.[КонтактнаяИнформация Объект ID] AS ObjectID,
        ci.[КонтактнаяИнформация Поле 2]    AS Contact_Info,
        ROW_NUMBER() OVER
        (
            PARTITION BY ci.[КонтактнаяИнформация Объект ID]
            ORDER BY CASE ci.[КонтактнаяИнформация Вид]
                         WHEN '9BD07509DFA6385644A4DA59663DE54A' THEN 1
                         WHEN '855E215869755D34405C9E2F87D961A6' THEN 2
                         ELSE 3
                     END
        ) AS rn
    FROM dbo.[РегистрыСведений.КонтактнаяИнформация] ci
    WHERE ci.[КонтактнаяИнформация Вид] IN
          (
              '9BD07509DFA6385644A4DA59663DE54A',
              '855E215869755D34405C9E2F87D961A6'
          )
)
INSERT INTO mis.[Gold_Dim_PartnersBranch]
(
    PartnerBranchID,
    PartnerBranchDeletedFlag,
    PartnerBranchOwner,
    PartnerBranchCode,
    PartnerBranchName,
    PartnerBranchAddress,
    PartnerOwnerName,
    DealerID,
    DealerDefaultEmployeeID,
    DealerDefaultEmployeeName,
    DealerOrgRepID,
    DealerOrgRepName,
    DealerCabinetID,
    DealerCabinetType,
    Contact_Info
)
SELECT
    f.[ФилиалыКонтрагентов ID],
    f.[ФилиалыКонтрагентов Пометка Удаления],
    f.[ФилиалыКонтрагентов Владелец],
    f.[ФилиалыКонтрагентов Код],
    f.[ФилиалыКонтрагентов Наименование],
    f.[ФилиалыКонтрагентов Адрес],

    k.[Контрагенты Наименование],

    d.[Дилеры ID],
    d.[Дилеры Эксперт по Умолчанию ID],
    d.[Дилеры Эксперт по Умолчанию],
    d.[Дилеры Представитель Организации ID],
    d.[Дилеры Представитель Организации],
    d.[Дилеры Вид Кабинета ID],
    d.[Дилеры Вид Кабинета],

    ci.Contact_Info
FROM mis.[Bronze_Справочники.ФилиалыКонтрагентов] f
LEFT JOIN mis.[Bronze_Справочники.Дилеры] d
       ON d.[Дилеры Владелец] = f.[ФилиалыКонтрагентов ID]
LEFT JOIN mis.[Bronze_Справочники.Контрагенты] k
       ON k.[Контрагенты ID] = f.[ФилиалыКонтрагентов Владелец]
LEFT JOIN ContactInfoRanked ci
       ON ci.ObjectID = k.[Контрагенты ID]
      AND ci.rn = 1;
GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.Gold_Dim_PartnersBranch.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Gold_Fact_AdminTasks.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO

IF OBJECT_ID('mis.[Gold_Fact_AdminTasks]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_AdminTasks];
GO

CREATE TABLE mis.[Gold_Fact_AdminTasks]
(
    -- Existing AdminTask columns
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

    -- Task type columns
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

    -- Hours
    [WaitHours] DECIMAL(18,2) NULL,
    [TotalHours] DECIMAL(18,2) NULL,
    [InProgress] DECIMAL(18,2) NULL,

    -- Status history
    [StatusHistory_ID] VARCHAR(36) NULL,
    [StatusHistory_RowNumber] INT NULL,
    [StatusHistory_Status] NVARCHAR(256) NULL,
    [StatusHistory_UserID] VARCHAR(36) NULL,
    [StatusHistory_User] NVARCHAR(150) NULL,
    [StatusHistory_StartDate] DATETIME NULL,
    [StatusHistory_EndDate] DATETIME NULL,
    [StatusHistory_Comment] NVARCHAR(1000) NULL,
    [StatusHistory_Seconds] INT NULL,

    -- New columns from СведенияОНаправленияхНаВыплату
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
GO

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
          AND s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Статус] = N'ВОжидании'
    ) wait_hours
    OUTER APPLY
    (
        SELECT SUM(CAST(s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Время в Секундах] AS FLOAT))/3600.0 AS InProgress
        FROM [ATK].[mis].[Bronze_Задачи.ЗадачаАдминистратораКредитов.ИсторияСтатусов] s3
        WHERE s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID] = a.[ЗадачаАдминистратораКредитов ID]
          AND s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Статус] = N'ВРаботе'
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
INSERT INTO mis.[Gold_Fact_AdminTasks] 
(
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
WHERE rn = 1;
----------------------------------------------------------------------------------------------------
-- End of:   mis.Gold_Fact_AdminTasks.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Gold_Fact_ArchiveDocument.sql
----------------------------------------------------------------------------------------------------
USE [ATK]
GO

IF OBJECT_ID('mis.[Gold_Fact_ArchiveDocument]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_ArchiveDocument];
GO

CREATE TABLE mis.[Gold_Fact_ArchiveDocument] 
(
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
WHERE r.[АктыПередачиКредитныхДел Период] >= '2023-09-01';
GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.Gold_Fact_ArchiveDocument.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Gold_Fact_BudgetEmployees.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO

IF OBJECT_ID('mis.[Gold_Fact_BudgetEmployees]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_BudgetEmployees];
GO

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
GO

INSERT INTO mis.[Gold_Fact_BudgetEmployees]
SELECT
    s.[БюджетПоСотрудникам.Сотрудники Сотрудник ID] AS EmployeeID,
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
WHERE d.[БюджетПоСотрудникам Дата] >= '2023-09-01';
GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.Gold_Fact_BudgetEmployees.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Gold_Fact_CerereOnline.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @TargetPosID varchar(36) = '812b00155d65040111ed03ac01bd0d94';
DECLARE @FromDate    datetime   = '2013-01-01T00:00:00';

--------------------------------------------------------------------------------
-- 0A) Calendar tables (temp) - NO named constraints (avoid PK name collisions)
--------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#Dim_WorkCalendar_All_08_20') IS NOT NULL DROP TABLE #Dim_WorkCalendar_All_08_20;
IF OBJECT_ID('tempdb..#Dim_WorkCalendar_MonFri_08_18') IS NOT NULL DROP TABLE #Dim_WorkCalendar_MonFri_08_18;

CREATE TABLE #Dim_WorkCalendar_All_08_20
(
      [Date]            date        NOT NULL PRIMARY KEY CLUSTERED
    , IsWeekend         bit         NOT NULL
    , WorkStartDttm     datetime2(0) NOT NULL
    , WorkEndDttm       datetime2(0) NOT NULL
    , WorkMinutesPerDay int         NOT NULL
    , CumWorkMinutes    bigint      NOT NULL
);

CREATE TABLE #Dim_WorkCalendar_MonFri_08_18
(
      [Date]            date        NOT NULL PRIMARY KEY CLUSTERED
    , IsWeekend         bit         NOT NULL
    , WorkStartDttm     datetime2(0) NOT NULL
    , WorkEndDttm       datetime2(0) NOT NULL
    , WorkMinutesPerDay int         NOT NULL
    , CumWorkMinutes    bigint      NOT NULL
);

DECLARE @CalStart date = '2023-01-01';
DECLARE @CalEnd   date = DATEADD(year, 5, CONVERT(date, GETDATE()));

;WITH N AS
(
    SELECT TOP (DATEDIFF(day, @CalStart, @CalEnd) + 1)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
),
d AS (SELECT [Date] = DATEADD(day, n, @CalStart) FROM N),
x AS (SELECT [Date], WDay = (DATEDIFF(day, CONVERT(date,'19000101'), [Date]) % 7) + 1 FROM d),
src AS (SELECT [Date], WDay, IsWeekend = CASE WHEN WDay IN (6,7) THEN 1 ELSE 0 END FROM x)
INSERT INTO #Dim_WorkCalendar_All_08_20
([Date], IsWeekend, WorkStartDttm, WorkEndDttm, WorkMinutesPerDay, CumWorkMinutes)
SELECT
      s.[Date]
    , s.IsWeekend
    , DATEADD(minute,  8*60, CAST(s.[Date] AS datetime2(0)))
    , DATEADD(minute, 20*60, CAST(s.[Date] AS datetime2(0)))
    , 720
    , SUM(CAST(720 AS bigint)) OVER (ORDER BY s.[Date] ROWS UNBOUNDED PRECEDING)
FROM src s;

;WITH N AS
(
    SELECT TOP (DATEDIFF(day, @CalStart, @CalEnd) + 1)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
),
d AS (SELECT [Date] = DATEADD(day, n, @CalStart) FROM N),
x AS (SELECT [Date], WDay = (DATEDIFF(day, CONVERT(date,'19000101'), [Date]) % 7) + 1 FROM d),
src AS (SELECT [Date], WDay, IsWeekend = CASE WHEN WDay IN (6,7) THEN 1 ELSE 0 END FROM x)
INSERT INTO #Dim_WorkCalendar_MonFri_08_18
([Date], IsWeekend, WorkStartDttm, WorkEndDttm, WorkMinutesPerDay, CumWorkMinutes)
SELECT
      s.[Date]
    , s.IsWeekend
    , DATEADD(minute,  8*60, CAST(s.[Date] AS datetime2(0)))
    , DATEADD(minute, 18*60, CAST(s.[Date] AS datetime2(0)))
    , CASE WHEN s.WDay BETWEEN 1 AND 5 THEN 600 ELSE 0 END
    , SUM(CAST(CASE WHEN s.WDay BETWEEN 1 AND 5 THEN 600 ELSE 0 END AS bigint))
        OVER (ORDER BY s.[Date] ROWS UNBOUNDED PRECEDING)
FROM src s;

--------------------------------------------------------------------------------
-- 1) Rebuild target table from base (ONLY 2024+)
--------------------------------------------------------------------------------
IF OBJECT_ID('mis.Gold_Fact_CerereOnline','U') IS NOT NULL
    DROP TABLE mis.Gold_Fact_CerereOnline;

SELECT f.*
INTO mis.Gold_Fact_CerereOnline
FROM [ATK].[mis].[Silver_CerereOnline_base] f
WHERE f.[Date] >= @FromDate;

--------------------------------------------------------------------------------
-- 1B) Indexes for faster joins/updates
--------------------------------------------------------------------------------
CREATE INDEX IX_Gold_CerereOnline_ID       ON mis.Gold_Fact_CerereOnline([ID]);
CREATE INDEX IX_Gold_CerereOnline_CreditID ON mis.Gold_Fact_CerereOnline([CreditID]);
CREATE INDEX IX_Gold_CerereOnline_AuthorID ON mis.Gold_Fact_CerereOnline([AuthorID]);
CREATE INDEX IX_Gold_CerereOnline_Date     ON mis.Gold_Fact_CerereOnline([Date]);

--------------------------------------------------------------------------------
-- 2) Ensure required columns (add only if missing)
--------------------------------------------------------------------------------
IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Data autorizarii') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Data autorizarii] datetime2(0) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Data depunerii cererii') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Data depunerii cererii] datetime2(0) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Data votarii') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Data votarii] datetime2(0) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Autor Votare') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Autor Votare] nvarchar(255) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'AutorVotare ID') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [AutorVotare ID] varchar(36) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Autor decizie') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Autor decizie] nvarchar(255) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'AutorDecizie ID') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [AutorDecizie ID] varchar(36) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Кредиты Сегмент Доходов') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Кредиты Сегмент Доходов] nvarchar(255) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Tip Рассмотрения Заявки RO') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Tip Рассмотрения Заявки RO] nvarchar(50) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Viteza de decizie') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Viteza de decizie] decimal(18,2) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Viteza de votare') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Viteza de votare] decimal(18,2) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Viteza de procesare') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Viteza de procesare] decimal(18,2) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Analyse') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Analyse] decimal(18,2) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Viteza de votare CC') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Viteza de votare CC] decimal(18,2) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'CC') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [CC] decimal(18,2) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Disbusement speed') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Disbusement speed] decimal(18,2) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Total speed') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Total speed] decimal(18,2) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Timpul de asteptare') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Timpul de asteptare] decimal(18,2) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Viteza de decizie CC') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Viteza de decizie CC] decimal(18,2) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Viteza debursare(dupa procesare)') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Viteza debursare(dupa procesare)] decimal(18,2) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Viteza debursare(dupa Decizie)') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Viteza debursare(dupa Decizie)] decimal(18,2) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Depasire norma viteza') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Depasire norma viteza] bit NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'LoadDttm_Ext') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline
        ADD [LoadDttm_Ext] datetime NOT NULL
            CONSTRAINT DF_Gold_Fact_CerereOnline_LoadDttm DEFAULT (GETDATE());

GO

USE [ATK];
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @TargetPosID varchar(36) = '812b00155d65040111ed03ac01bd0d94';

--------------------------------------------------------------------------------
-- 3) FAST ENRICH: restrict heavy work to only IDs from rebuilt table
--------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#t') IS NOT NULL DROP TABLE #t;

;WITH x AS
(
    SELECT
          t.[ID]
        , t.[CreditID]
        , t.[AuthorID]
        , t.[BranchID]
        , t.[CommitteeDecisionDate]
        , rn = ROW_NUMBER() OVER
          (
            PARTITION BY t.[ID]
            ORDER BY t.[Date] DESC, t.[CreditID] DESC
          )
    FROM mis.Gold_Fact_CerereOnline t
)
SELECT [ID], [CreditID], [AuthorID], [BranchID], [CommitteeDecisionDate]
INTO #t
FROM x
WHERE rn = 1;

CREATE CLUSTERED INDEX CIX_t_ID ON #t([ID]);
CREATE INDEX IX_t_CreditID ON #t([CreditID]);
CREATE INDEX IX_t_AuthorID ON #t([AuthorID]);

-- d_last
IF OBJECT_ID('tempdb..#d_last') IS NOT NULL DROP TABLE #d_last;
;WITH d_src AS
(
    SELECT
          d.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID] AS CerereOnlineID
        , CAST(d.[ОбъединеннаяИнтернетЗаявка Дата] AS datetime2(0)) AS Dep
        , CAST(d.[ОбъединеннаяИнтернетЗаявка Дата Отправки на Рассмотрение] AS datetime2(0)) AS InCC
        , CAST(d.[ОбъединеннаяИнтернетЗаявка Дата Взятия в Работу] AS datetime2(0)) AS ProcDttm
        , d.[ОбъединеннаяИнтернетЗаявка Тип Рассмотрения Заявки] AS Tip
        , rn = ROW_NUMBER() OVER
          (
              PARTITION BY d.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
              ORDER BY CAST(d.[ОбъединеннаяИнтернетЗаявка Дата] AS datetime2(0)) DESC,
                       d.[ОбъединеннаяИнтернетЗаявка ID] DESC
          )
    FROM [ATK].[dbo].[Документы.ОбъединеннаяИнтернетЗаявка] d
    JOIN #t tt ON tt.[ID] = d.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
    WHERE ISNULL(d.[ОбъединеннаяИнтернетЗаявка Проведен], 0) = 0
      AND ISNULL(d.[ОбъединеннаяИнтернетЗаявка Пометка Удаления], 0) = 0
)
SELECT CerereOnlineID, Dep, InCC, ProcDttm, Tip
INTO #d_last
FROM d_src
WHERE rn = 1;

CREATE UNIQUE CLUSTERED INDEX CIX_dlast_ID ON #d_last(CerereOnlineID);

-- proto_last
IF OBJECT_ID('tempdb..#proto_last') IS NOT NULL DROP TABLE #proto_last;
;WITH p_src AS
(
    SELECT
          p.[ПротоколКомитета Заявка ID] AS CerereOnlineID
        , p.[ПротоколКомитета ID]        AS ProtocolID
        , CAST(p.[ПротоколКомитета Дата] AS datetime2(0)) AS ProtocolDate
        , p.[ПротоколКомитета Председатель Комитета]       AS ChairName
        , p.[ПротоколКомитета Председатель Комитета ID]    AS ChairEmployeeID
        , rn = ROW_NUMBER() OVER
          (
              PARTITION BY p.[ПротоколКомитета Заявка ID]
              ORDER BY CAST(p.[ПротоколКомитета Дата] AS datetime2(0)) DESC,
                       p.[ПротоколКомитета ID] DESC
          )
    FROM [ATK].[dbo].[Документы.ПротоколКомитета] p
    JOIN #t tt ON tt.[ID] = p.[ПротоколКомитета Заявка ID]
    WHERE ISNULL(p.[ПротоколКомитета Пометка Удаления], 0) = 0
      AND ISNULL(p.[ПротоколКомитета Вид Комитета], N'') = N'ПредоставлениеКредита'
)
SELECT CerereOnlineID, ProtocolID, ProtocolDate, ChairName, ChairEmployeeID
INTO #proto_last
FROM p_src
WHERE rn = 1;

CREATE UNIQUE CLUSTERED INDEX CIX_proto_ID ON #proto_last(CerereOnlineID);
CREATE INDEX IX_proto_ProtocolID ON #proto_last(ProtocolID);

-- members
IF OBJECT_ID('tempdb..#members') IS NOT NULL DROP TABLE #members;
SELECT
      pl.CerereOnlineID
    , pl.ProtocolDate
    , VoteDate =
        NULLIF(
            CAST(m.[ПротоколКомитета.ЧленыКомитета Дата Голоса] AS datetime2(0)),
            CAST('1753-01-01T00:00:00' AS datetime2(0))
        )
    , MemberName = m.[ПротоколКомитета.ЧленыКомитета Член Комитета]
    , MemberEmployeeID = m.[ПротоколКомитета.ЧленыКомитета Член Комитета ID]
INTO #members
FROM #proto_last pl
LEFT JOIN [ATK].[dbo].[Документы.ПротоколКомитета.ЧленыКомитета] m
  ON m.[ПротоколКомитета ID] = pl.ProtocolID;

CREATE INDEX IX_members_ID ON #members(CerereOnlineID);
CREATE INDEX IX_members_emp ON #members(MemberEmployeeID);

-- salary pos (set-based)
IF OBJECT_ID('tempdb..#m_pos') IS NOT NULL DROP TABLE #m_pos;
;WITH s AS
(
    SELECT
          m.CerereOnlineID
        , m.VoteDate
        , m.MemberEmployeeID
        , m.MemberName
        , PosID = s.[СотрудникиДанныеПоЗарплате Должность ID]
        , rn = ROW_NUMBER() OVER
          (
            PARTITION BY m.CerereOnlineID, m.MemberEmployeeID, m.VoteDate
            ORDER BY CAST(s.[СотрудникиДанныеПоЗарплате Период] AS datetime2(0)) DESC
          )
    FROM #members m
    LEFT JOIN [ATK].[mis].[Bronze_РегистрыСведений.СотрудникиДанныеПоЗарплате] s
      ON s.[СотрудникиДанныеПоЗарплате Сотрудник ID] = m.MemberEmployeeID
     AND m.VoteDate IS NOT NULL
     AND CAST(s.[СотрудникиДанныеПоЗарплате Период] AS datetime2(0)) <= m.VoteDate
)
SELECT CerereOnlineID, VoteDate, MemberEmployeeID, MemberName, PosID
INTO #m_pos
FROM s
WHERE rn = 1;

CREATE INDEX IX_mpos_ID ON #m_pos(CerereOnlineID);

-- pick FIRST vote prefer TargetPos; fallback chair if none
IF OBJECT_ID('tempdb..#vote_final') IS NOT NULL DROP TABLE #vote_final;

;WITH ranked AS
(
    SELECT
          CerereOnlineID
        , VoteDate
        , [Autor Votare]    = MemberName
        , [AutorVotare ID]  = MemberEmployeeID
        , rn = ROW_NUMBER() OVER
          (
            PARTITION BY CerereOnlineID
            ORDER BY
                CASE WHEN VoteDate IS NULL THEN 1 ELSE 0 END,
                CASE WHEN PosID = @TargetPosID THEN 0 ELSE 1 END,
                VoteDate ASC,
                MemberEmployeeID ASC
          )
    FROM #m_pos
)
SELECT CerereOnlineID, VoteDate, [Autor Votare], [AutorVotare ID]
INTO #vote_final
FROM ranked
WHERE rn = 1;

INSERT INTO #vote_final(CerereOnlineID, VoteDate, [Autor Votare], [AutorVotare ID])
SELECT
      pl.CerereOnlineID
    , pl.ProtocolDate
    , pl.ChairName
    , pl.ChairEmployeeID
FROM #proto_last pl
WHERE NOT EXISTS (SELECT 1 FROM #vote_final v WHERE v.CerereOnlineID = pl.CerereOnlineID);

CREATE UNIQUE CLUSTERED INDEX CIX_vote_ID ON #vote_final(CerereOnlineID);

-- credits_dim
IF OBJECT_ID('tempdb..#credits_dim') IS NOT NULL DROP TABLE #credits_dim;
SELECT c.[Кредиты ID] AS CreditID, MAX(c.[Кредиты Сегмент Доходов]) AS IncomeSeg
INTO #credits_dim
FROM [ATK].[mis].[Bronze_Справочники.Кредиты] c
JOIN (SELECT DISTINCT CreditID FROM #t) x ON x.CreditID = c.[Кредиты ID]
GROUP BY c.[Кредиты ID];
CREATE UNIQUE CLUSTERED INDEX CIX_cr ON #credits_dim(CreditID);

-- users_dim
IF OBJECT_ID('tempdb..#users_dim') IS NOT NULL DROP TABLE #users_dim;
SELECT u.[Пользователи ID] AS AuthorID,
       MAX(u.[Пользователи Сотрудник ID]) AS AutorDecizieID,
       MAX(u.[Пользователи Сотрудник])    AS AutorDecizie
INTO #users_dim
FROM [ATK].[dbo].[Справочники.Пользователи] u
JOIN (SELECT DISTINCT AuthorID FROM #t) x ON x.AuthorID = u.[Пользователи ID]
GROUP BY u.[Пользователи ID];
CREATE UNIQUE CLUSTERED INDEX CIX_usr ON #users_dim(AuthorID);

-- pay_last
IF OBJECT_ID('tempdb..#pay_last') IS NOT NULL DROP TABLE #pay_last;
;WITH p AS
(
    SELECT
          p.[НаправлениеНаВыплату Кредит ID] AS CreditID
        , CAST(p.[НаправлениеНаВыплату Дата] AS datetime2(0)) AS DataAut
        , rn = ROW_NUMBER() OVER
          (
              PARTITION BY p.[НаправлениеНаВыплату Кредит ID]
              ORDER BY CAST(p.[НаправлениеНаВыплату Дата] AS datetime2(0)) DESC,
                       p.[НаправлениеНаВыплату ID] DESC
          )
    FROM [ATK].[dbo].[Документы.НаправлениеНаВыплату] p
    JOIN (SELECT DISTINCT CreditID FROM #t) x ON x.CreditID = p.[НаправлениеНаВыплату Кредит ID]
    WHERE ISNULL(p.[НаправлениеНаВыплату Пометка Удаления], 0) = 0
      AND ISNULL(p.[НаправлениеНаВыплату Проведен], 0) = 0
)
SELECT CreditID, DataAut
INTO #pay_last
FROM p
WHERE rn = 1;
CREATE UNIQUE CLUSTERED INDEX CIX_pay ON #pay_last(CreditID);

--------------------------------------------------------------------------------
-- FINAL UPDATE
--------------------------------------------------------------------------------
UPDATE t
SET
      t.[Autor Votare]            = v.[Autor Votare]
    , t.[AutorVotare ID]          = v.[AutorVotare ID]
    , t.[Data depunerii cererii]  = d.Dep
    , t.[Data votarii]            = v.VoteDate
    , t.[Autor decizie]           = u.[AutorDecizie]
    , t.[AutorDecizie ID]         = u.[AutorDecizieID]
    , t.[Кредиты Сегмент Доходов] = cr.IncomeSeg
    , t.[Data autorizarii]        = pay.DataAut
    , t.[Tip Рассмотрения Заявки RO] =
        CASE
            WHEN v.[AutorVotare ID] = '813100155D65040111ED171A45F42146' THEN N'Fara sunet'
            WHEN d.Tip = N'БезЗвонка'   THEN N'Fara sunet'
            WHEN d.Tip = N'Стандартный' THEN N'Standart'
            ELSE NULL
        END
    , t.[Viteza de decizie] =
        mis.fn_WorkMinutesSigned(d.Dep, t.[CommitteeDecisionDate], 8*60, 20*60)
    , t.[Viteza de votare] =
        mx.Minutes_DepVote_08_20
    , t.[Viteza de procesare] =
        mis.fn_WorkMinutesSigned(d.ProcDttm, v.VoteDate, 8*60, 20*60)
    , t.[Analyse] =
        mis.fn_WorkMinutesSigned_MonFri(d.Dep, d.InCC, 8*60, 18*60)
    , t.[Viteza de votare CC] =
        CASE
            WHEN t.[BranchID] IN
            (
                'B4A7BE35292F478C43E38230566F5F97',
                '80E300155D010F0111E783EB9D2D0BD9',
                '810100155D01451511EA26363FF9CEA0',
                '975B0018FEFB2E3711DD498DDAA682E1',
                'B7B700155D65140C11EFB0AFF47A513B'
            )
            THEN mis.fn_WorkMinutesSigned_MonFri(d.InCC, v.VoteDate, 9*60, 18*60)
            ELSE mis.fn_WorkMinutesSigned_MonFri(d.InCC, v.VoteDate, 8*60, 17*60)
        END
    , t.[CC] =
        mis.fn_WorkMinutesSigned_MonFri(d.InCC, t.[CommitteeDecisionDate], 8*60, 18*60)
    , t.[Disbusement speed] =
        mis.fn_WorkMinutesSigned_MonFri(t.[CommitteeDecisionDate], pay.DataAut, 8*60, 18*60)
    , t.[Total speed] =
        mis.fn_WorkMinutesSigned_MonFri(d.Dep, pay.DataAut, 8*60, 18*60)
    , t.[Timpul de asteptare] =
        mis.fn_WorkMinutesSigned_MonFri(d.Dep, d.ProcDttm, 9*60, 18*60)
    , t.[Viteza de decizie CC] =
        mis.fn_WorkMinutesSigned_MonFri(d.Dep, t.[CommitteeDecisionDate], 8*60, 18*60)
    , t.[Viteza debursare(dupa procesare)] =
        mis.fn_WorkMinutesSigned_MonFri(d.ProcDttm, pay.DataAut, 8*60, 18*60)
    , t.[Viteza debursare(dupa Decizie)] =
        mis.fn_WorkMinutesSigned_MonFri(t.[CommitteeDecisionDate], pay.DataAut, 8*60, 18*60)
    , t.[Depasire norma viteza] =
        CASE
            WHEN mx.Minutes_DepVote_08_20 IS NULL THEN NULL
            WHEN (
                     cr.IncomeSeg LIKE N'Ipoteca%'
                  OR cr.IncomeSeg LIKE N'HIL%'
                  OR cr.IncomeSeg =  N'Consum non-business'
                  OR cr.IncomeSeg =  N'Linia de credit retail'
                 )
                 AND mx.Minutes_DepVote_08_20 > 420 THEN 1
            WHEN (
                     cr.IncomeSeg NOT LIKE N'Ipoteca%'
                 AND cr.IncomeSeg NOT LIKE N'HIL%'
                 AND cr.IncomeSeg <> N'Consum non-business'
                 AND cr.IncomeSeg <> N'Linia de credit retail'
                 )
                 AND mx.Minutes_DepVote_08_20 > 120 THEN 1
            ELSE 0
        END
    , t.[LoadDttm_Ext] = GETDATE()
FROM mis.Gold_Fact_CerereOnline t
JOIN #t tt               ON tt.[ID] = t.[ID]
LEFT JOIN #d_last d       ON d.CerereOnlineID = t.[ID]
LEFT JOIN #vote_final v   ON v.CerereOnlineID = t.[ID]
LEFT JOIN #credits_dim cr ON cr.CreditID      = t.[CreditID]
LEFT JOIN #users_dim u    ON u.AuthorID       = t.[AuthorID]
LEFT JOIN #pay_last pay   ON pay.CreditID     = t.[CreditID]
OUTER APPLY
(
    SELECT Minutes_DepVote_08_20 =
        CASE WHEN d.Dep IS NULL OR v.VoteDate IS NULL
             THEN NULL
             ELSE mis.fn_WorkMinutesSigned(d.Dep, v.VoteDate, 8*60, 20*60)
        END
) mx;
----------------------------------------------------------------------------------------------------
-- End of:   mis.Gold_Fact_CerereOnline.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Gold_Fact_Comments.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO

IF OBJECT_ID('mis.[Gold_Fact_Comments]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_Comments];
GO

CREATE TABLE mis.[Gold_Fact_Comments]
(
    CommentID VARCHAR(36) NOT NULL PRIMARY KEY,
    AllComments NVARCHAR(MAX) NULL
);
GO

SELECT 
    [КомментарийКУсловиямПослеВыдачи ИД] AS CommentID,
    CONVERT(VARCHAR(10), [КомментарийКУсловиямПослеВыдачи Период], 120) AS Period,
    [КомментарийКУсловиямПослеВыдачи Исполнитель] AS Executor,
    [КомментарийКУсловиямПослеВыдачи Комментарий] AS Comment
INTO #FilteredComments
FROM [ATK].[dbo].[РегистрыСведений.КомментарийКУсловиямПослеВыдачи]
WHERE [КомментарийКУсловиямПослеВыдачи Объект Tип] = '08'
  AND [КомментарийКУсловиямПослеВыдачи Клиент] IS NOT NULL;
GO

INSERT INTO mis.[Gold_Fact_Comments] (CommentID, AllComments)
SELECT 
    fc1.CommentID,
    STUFF(
        (
            SELECT CHAR(13) + CHAR(10) +
                   CONCAT(fc2.Period, ' ', fc2.Executor, ': ', fc2.Comment)
            FROM #FilteredComments fc2
            WHERE fc2.CommentID = fc1.CommentID
            ORDER BY fc2.Period
            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 2, ''
    ) AS AllComments
FROM (SELECT DISTINCT CommentID FROM #FilteredComments) fc1;
GO

DROP TABLE #FilteredComments;
GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.Gold_Fact_Comments.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Gold_Fact_CPD.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO

IF OBJECT_ID('mis.[Gold_Fact_CPD]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_CPD];
GO

CREATE TABLE mis.[Gold_Fact_CPD]
( 
    [Period]              DATETIME NULL,
    [ObjectType]          VARCHAR(36) NULL,
    [ObjectKind]          VARCHAR(36) NULL,
    [ObjectID]            VARCHAR(36) NULL,
    [ID]                  VARCHAR(36) NULL,
    [ConditionType]       NVARCHAR(256) NULL,
    [ConditionObjectType] VARCHAR(36) NULL,
    [ConditionObject_S]   NVARCHAR(600) NULL,
    [ConditionObject]     VARCHAR(36) NULL,
    [AdditionalInterest]  DECIMAL(4, 2) NULL,
    [DueDate]             DATETIME NULL,
    [ResponsibleID]       VARCHAR(36) NULL,
    [Responsible]         NVARCHAR(50) NULL,
    [IssueDate]           DATETIME NULL,
    [Completed]           VARCHAR(36) NULL,
    [CompletionDate]      DATETIME NULL,
    [Comment]             NVARCHAR(1000) NULL,
    [Verified]            VARCHAR(36) NULL,
    [IsAdditionalCondition]  VARCHAR(36) NULL,
    [Cancelled]           VARCHAR(36) NULL,
    [CreditRisk]          NVARCHAR(256) NULL,
    [LegalRisk]           NVARCHAR(256) NULL,
    [CommitteeApproved]   VARCHAR(36) NULL,
    [CollateralID]        VARCHAR(36) NULL,
    [Collateral]          NVARCHAR(150) NULL,
    [CancelledByID]       VARCHAR(36) NULL,
    [CancelledBy]         NVARCHAR(150) NULL,
    [VerifiedByID]        VARCHAR(36) NULL,
    [VerifiedBy]          NVARCHAR(150) NULL,
    [ModifiedDate]        DATETIME NULL,
    [SourceType]          VARCHAR(36) NULL,
    [SourceKind]          VARCHAR(36) NULL,
    [SourceID]            VARCHAR(36) NULL,
    [OwnerID]             VARCHAR(36) NULL,
    [Owner]               NVARCHAR(150) NULL
);
GO

INSERT INTO mis.[Gold_Fact_CPD]
(
    [Period],
    [ObjectType],
    [ObjectKind],
    [ObjectID],
    [ID],
    [ConditionType],
    [ConditionObjectType],
    [ConditionObject_S],
    [ConditionObject],
    [AdditionalInterest],
    [DueDate],
    [ResponsibleID],
    [Responsible],
    [IssueDate],
    [Completed],
    [CompletionDate],
    [Comment],
    [Verified],
    [IsAdditionalCondition],
    [Cancelled],
    [CreditRisk],
    [LegalRisk],
    [CommitteeApproved],
    [CollateralID],
    [Collateral],
    [CancelledByID],
    [CancelledBy],
    [VerifiedByID],
    [VerifiedBy],
    [ModifiedDate],
    [SourceType],
    [SourceKind],
    [SourceID],
    [OwnerID],
    [Owner]
)
SELECT
    [УсловияПослеВыдачиКредита Период],
    [УсловияПослеВыдачиКредита Объект Tип],
    [УсловияПослеВыдачиКредита Объект Вид],
    [УсловияПослеВыдачиКредита Объект ID],
    [УсловияПослеВыдачиКредита ИД],
    [УсловияПослеВыдачиКредита Тип Условия],
    [УсловияПослеВыдачиКредита Объект Условия Tип],
    [УсловияПослеВыдачиКредита Объект Условия _S],
    [УсловияПослеВыдачиКредита Объект Условия],
    [УсловияПослеВыдачиКредита Доп Проценты],
    [УсловияПослеВыдачиКредита Срок Выполнения],
    [УсловияПослеВыдачиКредита Исполнитель ID],
    [УсловияПослеВыдачиКредита Исполнитель],
    [УсловияПослеВыдачиКредита Дата Выдачи],
    [УсловияПослеВыдачиКредита Выполнено],
    [УсловияПослеВыдачиКредита Дата Выполнения],
    [УсловияПослеВыдачиКредита Комментарий],
    [УсловияПослеВыдачиКредита Проверено],
    [УсловияПослеВыдачиКредита Это Доп Условия],
    [УсловияПослеВыдачиКредита Аннулирован],
    [УсловияПослеВыдачиКредита Кредитный Риск],
    [УсловияПослеВыдачиКредита Юридический Риск],
    [УсловияПослеВыдачиКредита Одобренно Комитетом],
    [УсловияПослеВыдачиКредита Залог ID],
    [УсловияПослеВыдачиКредита Залог],
    [УсловияПослеВыдачиКредита Автор Аннулирования ID],
    [УсловияПослеВыдачиКредита Автор Аннулирования],
    [УсловияПослеВыдачиКредита Автор Проверки ID],
    [УсловияПослеВыдачиКредита Автор Проверки],
    [УсловияПослеВыдачиКредита Дата Изменения],
    [УсловияПослеВыдачиКредита Источник Tип],
    [УсловияПослеВыдачиКредита Источник Вид],
    [УсловияПослеВыдачиКредита Источник ID],
    [УсловияПослеВыдачиКредита Ответственный ID],
    [УсловияПослеВыдачиКредита Ответственный]
	
FROM [ATK].[dbo].[РегистрыСведений.УсловияПослеВыдачиКредита];
----------------------------------------------------------------------------------------------------
-- End of:   mis.Gold_Fact_CPD.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Gold_Fact_CreditsInShadowBranches.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO


IF OBJECT_ID('mis.[Gold_CreditsInShadowBranches]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_CreditsInShadowBranches];
GO

CREATE TABLE mis.[Gold_CreditsInShadowBranches] 
(
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
    FROM [ATK].[mis].[Bronze_РегистрыСведений.КредитыВТеневыхФилиалах] rs
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
INSERT INTO mis.[Gold_CreditsInShadowBranches] 
(
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
-- End of:   mis.Gold_Fact_CreditsInShadowBranches.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Gold_Fact_WriteOffCredits.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO

IF OBJECT_ID('mis.[Gold_Fact_WriteOffCredits]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_WriteOffCredits];
GO

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
GO

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
           c.[FinalBranchID] AS FinalBranchID,
           c.[FinalExpertID] AS FinalExpertID
    FROM [ATK].[mis].[Silver_Resp_SCD] c
    WHERE c.[CreditID] = a.[АнулированиеКредитов.Кредиты Кредит ID]
    ORDER BY 
        ISNULL(CAST(c.[ValidTo] AS date), CONVERT(date,'9999-12-31')) DESC,
        CAST(c.[ValidFrom] AS date) DESC,
        c.[FinalBranchID] DESC,
        c.[FinalExpertID] DESC
) AS lastResp;

CREATE INDEX IX_WriteOff_CreditID 
    ON [ATK].[mis].[Gold_Fact_WriteOffCredits] ([Credit_CreditID]);

CREATE INDEX IX_WriteOff_Final 
    ON [ATK].[mis].[Gold_Fact_WriteOffCredits] ([FinalBranchID], [FinalExpertID]);
----------------------------------------------------------------------------------------------------
-- End of:   mis.Gold_Fact_WriteOffCredits.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Gold_Fact_Restruct_Daily_Min.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
SET NOCOUNT ON;

/* ================== ПАРАМЕТРЫ ================== */
DECLARE @DateFrom date = '2024-01-01';
DECLARE @DateTo   date = '2026-12-31';

PRINT N'=== Пересборка [mis].[Gold_Fact_Restruct_Daily_Min] за период '
      + CONVERT(varchar(10), @DateFrom, 23) + N' — ' + CONVERT(varchar(10), @DateTo, 23) + N' ===';

BEGIN TRAN; -- Опционально для консистентности

/* ========== Очистка temp-таблиц ========== */
IF OBJECT_ID('tempdb..#Base')         IS NOT NULL DROP TABLE #Base;
IF OBJECT_ID('tempdb..#MaxDays')      IS NOT NULL DROP TABLE #MaxDays;
IF OBJECT_ID('tempdb..#Flag')         IS NOT NULL DROP TABLE #Flag;
IF OBJECT_ID('tempdb..#RespEarliest') IS NOT NULL DROP TABLE #RespEarliest;
IF OBJECT_ID('tempdb..#Joined_raw')   IS NOT NULL DROP TABLE #Joined_raw;
IF OBJECT_ID('tempdb..#Joined')       IS NOT NULL DROP TABLE #Joined;

/* ================== ЦЕЛЕВАЯ ТАБЛИЦА ================== */
IF OBJECT_ID('[mis].[Gold_Fact_Restruct_Daily_Min]', 'U') IS NOT NULL
BEGIN
    DROP TABLE [mis].[Gold_Fact_Restruct_Daily_Min];
    PRINT N'Старая таблица удалена.';
END;

CREATE TABLE [mis].[Gold_Fact_Restruct_Daily_Min] 
(
    SoldDate               date          NOT NULL,
    CreditID               varchar(36)   NOT NULL,
    ClientID               varchar(36)   NOT NULL,
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
    CONSTRAINT PK_Gold_Fact_RestructDailyMin
        PRIMARY KEY (ClientID, CreditID, SoldDate)
);

/* ================== ШАГ 1. БАЗА (устранение дублей) ================== */
PRINT N'Шаг 1 — подготовка базы...';

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
            ORDER BY s.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] DESC, 
			         s.[СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки Кредит] DESC
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

PRINT N'✅ Шаг 1: строк ' + CONVERT(varchar(30), @@ROWCOUNT);

/* ===== ШАГ 1.1. MaxDaysPerClientDay ===== */
SELECT
    ClientID,
    SoldDate,
    MAX(DaysFact_Total) AS MaxDaysPerClientDay
INTO #MaxDays
FROM #Base
GROUP BY ClientID, SoldDate;

CREATE UNIQUE CLUSTERED INDEX CIX_MaxDays ON #MaxDays (ClientID, SoldDate);

/* ================== ШАГ 1.2. Флаги ================== */
SELECT ClientID, SoldDate
INTO #Flag
FROM [ATK].[mis].[Silver_Client_UnhealedFlag]
WHERE HasUnhealed = 1
  AND SoldDate BETWEEN @DateFrom AND @DateTo;

CREATE UNIQUE CLUSTERED INDEX CIX_Flag ON #Flag (ClientID, SoldDate);

/* ===== ШАГ 2. Самая ранняя запись ответственных (fallback) ===== */
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

/* ============ ШАГ 3. Привязка ответственных (с фолбэком) ============ */
PRINT N'Шаг 2 — привязка филиала/эксперта...';

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

/* ================ ШАГ 4. ParIFRS (по #MaxDays) ================ */
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
        WHEN md.MaxDaysPerClientDay BETWEEN 1  AND 30  THEN N'Par0'
        WHEN md.MaxDaysPerClientDay BETWEEN 31 AND 60  THEN N'Par30'
        WHEN md.MaxDaysPerClientDay BETWEEN 61 AND 90  THEN N'Par60'
        WHEN md.MaxDaysPerClientDay BETWEEN 91 AND 180 THEN N'Par90'
        WHEN md.MaxDaysPerClientDay BETWEEN 181 AND 270 THEN N'Par180'
        WHEN md.MaxDaysPerClientDay BETWEEN 271 AND 360 THEN N'Par270'
        WHEN md.MaxDaysPerClientDay > 360           THEN N'Par360'
        ELSE NULL
    END AS ParIFRS,
	jr.CurrentStage
INTO #Joined
FROM #Joined_raw jr
JOIN #MaxDays md
  ON md.ClientID = jr.ClientID
 AND md.SoldDate = jr.SoldDate;

CREATE CLUSTERED INDEX CIX_Joined_ClientDate
ON #Joined (ClientID, SoldDate, CreditID);

/* ================ ШАГ 5. Вставка результата ================= */
PRINT N'Шаг 3 — вставка результата...';

INSERT /*+ TABLOCK */ INTO [mis].[Gold_Fact_Restruct_Daily_Min] WITH (TABLOCK)
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
        AND ISNULL(j.StateName_Final, N'') <> N'НеИзлеченный'
        THEN N'Nevindecat contaminat'
		WHEN j.StateName_Final = N'Излеченный' THEN N'Vindecat'
        WHEN j.StateName_Final = N'НеИзлеченный' THEN N'Nevindecat'
        ELSE j.StateName_Final
    END AS StateName_Final,
    CASE
        WHEN f.ClientID IS NOT NULL
        THEN N'НекоммерческаяРеструктуризация'
        ELSE j.TypeName_Sticky_Final
    END AS TypeName_Sticky_Final,
    j.CreditStatus_Base,
    j.LastBranchID,
    j.LastExpertID,
    j.IsSpecialBranch,
    CASE
        WHEN j.DaysIFRS >=  91 THEN N'e) 90 +'
        WHEN j.DaysIFRS >=  31 THEN N'd) 30 - 90'
        WHEN j.DaysIFRS >=  16 THEN N'c) 16 - 30'
        WHEN j.DaysIFRS >=   4 THEN N'b) 4 - 15'
        WHEN j.DaysIFRS >=   0 THEN N'a) 0 - 3'
        ELSE N'e) 90 +'
    END AS SegmentIFRS,
    j.ParIFRS,
	CASE j.CurrentStage
	   WHEN 'Стадия1' THEN 'Stage1'
       WHEN 'Стадия2' THEN 'Stage2'
       WHEN 'Стадия3' THEN 'Stage3'
	   ELSE  j.CurrentStage
	END AS CurrentStage
FROM #Joined j
LEFT JOIN #Flag f
  ON f.ClientID = j.ClientID
 AND f.SoldDate = j.SoldDate
OPTION (RECOMPILE);

PRINT N'✅ Вставка завершена.';

/* ================ УБОРКА ================= */
DROP TABLE #Base;
DROP TABLE #MaxDays;
DROP TABLE #Flag;
DROP TABLE #RespEarliest;
DROP TABLE #Joined_raw;
DROP TABLE #Joined;

/* ================ ИТОГ ================= */
DECLARE @cnt bigint;
SELECT @cnt = COUNT_BIG(*) FROM [mis].[Gold_Fact_Restruct_Daily_Min];
PRINT N'🏁 Готово. Строк: ' + CONVERT(varchar(30), @cnt);

COMMIT TRAN;
----------------------------------------------------------------------------------------------------
-- End of:   mis.Gold_Fact_Restruct_Daily_Min.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Gold_Fact_Disbursement.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO

IF OBJECT_ID('tempdb..#Base')   IS NOT NULL DROP TABLE #Base;
IF OBJECT_ID('tempdb..#Status') IS NOT NULL DROP TABLE #Status;
IF OBJECT_ID('tempdb..#Final')  IS NOT NULL DROP TABLE #Final;
IF OBJECT_ID('tempdb..#FirstDisbursementPerClient') IS NOT NULL DROP TABLE #FirstDisbursementPerClient;


IF OBJECT_ID('mis.[Gold_Fact_Disbursement]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_Disbursement];
GO

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
    EmployeePosition   NVARCHAR(100)  NULL,
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
============================ */
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
    emp.EmployeePosition,
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
    SELECT TOP 1 
           e.[СотрудникиДанныеПоЗарплате Должность ID] AS EmployeePositionID,
           e.[СотрудникиДанныеПоЗарплате Должность]    AS EmployeePosition
    FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате] e
    WHERE e.[СотрудникиДанныеПоЗарплате Сотрудник ID] = COALESCE(lastR_month.[ЭкспертID], firstR.[ЭкспертID])
      AND e.[СотрудникиДанныеПоЗарплате Период] <= d.[ДанныеКредитовВыданных Дата Выдачи]
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
            WHEN k.[Кредиты Цель Кредита ID] = 'B9D1CEBE56F4877143FDF0DD7CAE2AE4'
                 THEN ISNULL(proto.[ПротоколКомитета Сумма на Выдачу], d.[ДанныеКредитовВыданных Сумма Кредита])
            ELSE d.[ДанныеКредитовВыданных Сумма Кредита]
        END
) finalAmount

WHERE d.[ДанныеКредитовВыданных Кредитный Продукт] NOT LIKE N'Medier%'
  AND d.[ДанныеКредитовВыданных Дата Выдачи] >= '2023-09-01';
GO

/*==============================================================
  Build #FirstDisbursementPerClient (all-time)
==============================================================*/
SELECT
    k.[Кредиты Владелец] AS ClientID,
    MIN(d.[ДанныеКредитовВыданных Дата Выдачи]) AS FirstDisbursementDate
INTO #FirstDisbursementPerClient
FROM [ATK].[mis].[Bronze_РегистрыСведений.ДанныеКредитовВыданных] d
INNER JOIN [ATK].[mis].[Bronze_Справочники.Кредиты] k
    ON k.[Кредиты ID] = d.[ДанныеКредитовВыданных Кредит ID]
GROUP BY k.[Кредиты Владелец];
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
    FROM [ATK].[mis].[Bronze_РегистрыСведений.АнулированныеКредитыПартнеров] a
    INNER JOIN BaseIDs b ON b.CreditID = a.[АнулированныеКредитыПартнеров Кредит ID]
    WHERE a.[АнулированныеКредитыПартнеров Кредит Анулирован] = N'01'
    GROUP BY a.[АнулированныеКредитыПартнеров Кредит ID]
),
Restores AS (
    SELECT a.[АнулированныеКредитыПартнеров Кредит ID] AS CreditID,
           MAX(a.[АнулированныеКредитыПартнеров Период]) AS RestorePeriod
    FROM [ATK].[mis].[Bronze_РегистрыСведений.АнулированныеКредитыПартнеров] a
    INNER JOIN BaseIDs b ON b.CreditID = a.[АнулированныеКредитыПартнеров Кредит ID]
    WHERE a.[АнулированныеКредитыПартнеров Кредит Восстановлен] = N'01'
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
    b.FirstFilialID, b.FirstEmployeeID, b.EmployeePosition,
    b.LastFilialID, b.LastEmployeeID,
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
    b.FirstFilialID, b.FirstEmployeeID, b.EmployeePosition,
    b.LastFilialID, b.LastEmployeeID,
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
    b.FirstFilialID, b.FirstEmployeeID, b.EmployeePosition,
    b.LastFilialID, b.LastEmployeeID,
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
============================ */
WITH AllSeq AS (
    SELECT
        f.*,
        fd.FirstDisbursementDate,
        ROW_NUMBER() OVER (
            PARTITION BY f.ClientID
            ORDER BY  f.DisbursementDate, f.CreditID
        ) AS rn_all
    FROM #Final f
    LEFT JOIN #FirstDisbursementPerClient fd
        ON f.ClientID = fd.ClientID
)
INSERT INTO mis.[Gold_Fact_Disbursement]
(
    CreditID, ClientID, DisbursementDate, CurrencyID, CreditAmount, CreditAmountInMDL,
    CreditCurrency, FirstFilialID, FirstEmployeeID, LastFilialID, LastEmployeeID,
    IRR, IRR_Client, Qty, NewExisting_Client,
    EmployeePositionID, EmployeePosition
)
SELECT
    a.CreditID, a.ClientID, a.DisbursementDate, a.CurrencyID, a.CreditAmount, a.CreditAmountInMDL,
    a.CreditCurrency, a.FirstFilialID, a.FirstEmployeeID, a.LastFilialID, a.LastEmployeeID,
    a.IRR, a.IRR_Client, a.Qty,
    CASE
        WHEN a.CreditAmount > 0 AND a.DisbursementDate = a.FirstDisbursementDate THEN N'New'
        WHEN a.CreditAmount > 0 THEN N'Existing'
        ELSE N'Cancelled'
    END AS NewExisting_Client,
    a.EmployeePositionID,
    a.EmployeePosition
FROM AllSeq AS a
LEFT JOIN dbo.[Справочники.Контрагенты] AS c
    ON a.ClientID = c.[Контрагенты ID]
WHERE c.[Контрагенты Тестовый Контрагент] = 00;
GO

/* ============================
   Indexes
============================ */
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
GO

/* ============================
   Cleanup temp tables
============================ */
DROP TABLE #Base;
DROP TABLE #Status;
DROP TABLE #Final;
DROP TABLE #FirstDisbursementPerClient;
GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.Gold_Fact_Disbursement.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Gold_Fact_Sold_Par.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
SET NOCOUNT ON;

DECLARE @DateFrom DATE = '2024-01-01';

-----------------------------------------------------
-- Drop & recreate main GOLD table with single Par column
-----------------------------------------------------
DROP TABLE IF EXISTS mis.[Gold_Fact_Sold_Par];

CREATE TABLE mis.[Gold_Fact_Sold_Par] 
(
    SoldDate                DATE         NOT NULL,
	ClientID                VARCHAR(36)  NULL,
    CreditID                VARCHAR(36)  NOT NULL,
    SoldAmount              DECIMAL(18,2) NULL,
    NumberOfOverdueDaysIFRS DECIMAL(15,2) NULL,
    IRR_Values              DECIMAL(18,6) NULL,
    BranchShadow            NVARCHAR(100) NULL,
    EmployeeID              VARCHAR(36)  NULL,
    BranchID                VARCHAR(36)  NULL,
    EmployeePositionID      VARCHAR(36)  NULL,
    Par                     NVARCHAR(20) NULL
) WITH (DATA_COMPRESSION = PAGE);

-----------------------------------------------------
-- Step 1: Shadow Branch, Responsible, EmployeePos, IRR temp tables
-- NOTE: cast periods/dates to DATE to avoid time-of-day mismatches
-----------------------------------------------------

-- Shadow Branch
IF OBJECT_ID('tempdb..#ShadowBranch') IS NOT NULL DROP TABLE #ShadowBranch;
SELECT 
    [КредитыВТеневыхФилиалах Кредит ID] AS CreditID,
    [КредитыВТеневыхФилиалах Филиал] AS BranchShadow,
    CAST([КредитыВТеневыхФилиалах Период] AS DATE) AS Period
INTO #ShadowBranch
FROM mis.[Bronze_РегистрыСведений.КредитыВТеневыхФилиалах];

CREATE NONCLUSTERED INDEX IX_Shadow_Credit_Period ON #ShadowBranch (CreditID, Period);

-- MaxDays per client per date (SoldDate already as DATE)
IF OBJECT_ID('tempdb..#MaxDays') IS NOT NULL DROP TABLE #MaxDays;
SELECT
    [СуммыЗадолженностиПоПериодамПросрочки Клиент ID] AS ClientID,
    CAST([СуммыЗадолженностиПоПериодамПросрочки Дата] AS DATE) AS SoldDate,
    MAX([СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого]) AS MaxDaysPerClientDay
INTO #MaxDays
FROM mis.[Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки]
GROUP BY
    [СуммыЗадолженностиПоПериодамПросрочки Клиент ID],
    CAST([СуммыЗадолженностиПоПериодамПросрочки Дата] AS DATE);

CREATE NONCLUSTERED INDEX IX_MaxDays_Client_SoldDate ON #MaxDays(ClientID, SoldDate);

-- Responsible (cast Period -> DATE)
IF OBJECT_ID('tempdb..#Responsible') IS NOT NULL DROP TABLE #Responsible;
SELECT
    [ОтветственныеПоКредитамВыданным Кредит ID] AS CreditID,
    [ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS EmployeeID,
    [ОтветственныеПоКредитамВыданным Филиал ID] AS BranchID,
    CAST([ОтветственныеПоКредитамВыданным Период] AS DATE) AS Period
INTO #Responsible
FROM mis.[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным];

CREATE NONCLUSTERED INDEX IX_Resp_Credit_Period ON #Responsible (CreditID, Period);

-- Employee Position (cast Period -> DATE)
IF OBJECT_ID('tempdb..#EmployeePos') IS NOT NULL DROP TABLE #EmployeePos;
SELECT
    [СотрудникиДанныеПоЗарплате Сотрудник ID] AS EmployeeID,
    [СотрудникиДанныеПоЗарплате Должность ID] AS PositionID,
    CAST([СотрудникиДанныеПоЗарплате Период] AS DATE) AS Period
INTO #EmployeePos
FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате]
WHERE CAST([СотрудникиДанныеПоЗарплате Период] AS DATE) >= DATEADD(YEAR,-1,@DateFrom);

CREATE CLUSTERED INDEX CX_EmployeePos_Emp_Period ON #EmployeePos (EmployeeID, Period);

-- IRR (cast to DATE)
IF OBJECT_ID('tempdb..#IRR') IS NOT NULL DROP TABLE #IRR;
SELECT
    [УстановкаДанныхКредита Кредит ID] AS CreditID,
    [УстановкаДанныхКредита Внутренняя Норма Доходности Годовая] AS IRR_Year,
    [УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая] AS IRR_Client,
    CAST([УстановкаДанныхКредита Дата] AS DATE) AS IRRDate
INTO #IRR
FROM mis.[Bronze_Документы.УстановкаДанныхКредита]
WHERE [УстановкаДанныхКредита Кредит ID] IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_IRR_Credit_Date ON #IRR (CreditID, IRRDate DESC);

-----------------------------------------------------
-- Step 2: SourceData (pre-cast SoldDate) and insert Gold Fact
-----------------------------------------------------
;WITH SourceData AS (
    SELECT
        CAST([СуммыЗадолженностиПоПериодамПросрочки Дата] AS DATE) AS SoldDate,
        [СуммыЗадолженностиПоПериодамПросрочки Клиент ID] AS ClientID,
        [СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
        [СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] AS SoldAmount,
        [СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки МСФО] AS NumberOfOverdueDaysIFRS
    FROM mis.[Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки]
    WHERE [СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] <> 0
      AND CAST([СуммыЗадолженностиПоПериодамПросрочки Дата] AS DATE) >= @DateFrom
)
INSERT INTO mis.[Gold_Fact_Sold_Par] WITH (TABLOCK)
(
    SoldDate, ClientID, CreditID, SoldAmount, NumberOfOverdueDaysIFRS, IRR_Values,
    BranchShadow, EmployeeID, BranchID, EmployeePositionID, Par
)
SELECT
    sd.SoldDate,
    sd.ClientID,
    sd.CreditID,
    sd.SoldAmount,
    sd.NumberOfOverdueDaysIFRS,

    -- IRR Values (latest IRR where IRRDate <= SoldDate)
    ROUND(
        COALESCE(
            CASE WHEN irr.IRR_Year IS NOT NULL AND irr.IRR_Year < 100 THEN irr.IRR_Year
                 ELSE irr.IRR_Client
            END, 0
        ) * sd.SoldAmount, 2
    ) AS IRR_Values,

    -- BranchShadow: latest shadow row with Period <= SoldDate
    sh.BranchShadow,

    -- Employee & Branch: latest responsible row with Period <= SoldDate
    r.EmployeeID,
    r.BranchID,

    -- EmployeePositionID: latest employee position row (by Period) for r.EmployeeID where Period <= SoldDate
    empPos.PositionID AS EmployeePositionID,

    -- Par by MaxDays (max days per client per date)
    CASE
        WHEN md.MaxDaysPerClientDay BETWEEN 1   AND 30  THEN N'Par0'
        WHEN md.MaxDaysPerClientDay BETWEEN 31  AND 60  THEN N'Par30'
        WHEN md.MaxDaysPerClientDay BETWEEN 61  AND 90  THEN N'Par60'
        WHEN md.MaxDaysPerClientDay BETWEEN 91  AND 180 THEN N'Par90'
        WHEN md.MaxDaysPerClientDay BETWEEN 181 AND 270 THEN N'Par180'
        WHEN md.MaxDaysPerClientDay BETWEEN 271 AND 360 THEN N'Par270'
        WHEN md.MaxDaysPerClientDay > 360           THEN N'Par360'
        ELSE NULL
    END AS Par

FROM SourceData sd


-- latest Responsible row for the credit where Period <= SoldDate
OUTER APPLY (
    SELECT TOP (1)
        rr.EmployeeID,
        rr.BranchID
    FROM #Responsible rr
    WHERE rr.CreditID = sd.CreditID
      AND rr.Period <= sd.SoldDate
    ORDER BY rr.Period DESC
) AS r

-- latest Employee position for the picked employee where Period <= SoldDate
OUTER APPLY (
    SELECT TOP (1) ep.PositionID
    FROM #EmployeePos ep
    WHERE ep.EmployeeID = r.EmployeeID
      AND ep.Period <= sd.SoldDate
    ORDER BY ep.Period DESC
) AS empPos

-- latest ShadowBranch for credit where Period <= SoldDate
OUTER APPLY (
    SELECT TOP (1) sb.BranchShadow
    FROM #ShadowBranch sb
    WHERE sb.CreditID = sd.CreditID
      AND sb.Period <= sd.SoldDate
    ORDER BY sb.Period DESC
) AS sh

-- MaxDays join (exact sold date)
LEFT JOIN #MaxDays md
    ON md.ClientID = sd.ClientID
   AND md.SoldDate = sd.SoldDate

-- IRR lookup (already used above via outer apply in IRR_Values)
OUTER APPLY (
    SELECT TOP (1) i.IRR_Year, i.IRR_Client
    FROM #IRR i
    WHERE i.CreditID = sd.CreditID
      AND i.IRRDate <= sd.SoldDate
    ORDER BY i.IRRDate DESC
) AS irr
;
-----------------------------------------------------
-- Columnstore
-----------------------------------------------------
CREATE CLUSTERED COLUMNSTORE INDEX CCSI_Gold_Fact_Sold_Par
ON mis.[Gold_Fact_Sold_Par];

-- Drop temp tables
DROP TABLE IF EXISTS #ShadowBranch, #Responsible, #EmployeePos, #IRR, #MaxDays;
----------------------------------------------------------------------------------------------------
-- End of:   mis.Gold_Fact_Sold_Par.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: V2__inc_Gold_Dim_Event_InProgress.sql
----------------------------------------------------------------------------------------------------
INSERT INTO mis.[Gold_Dim_Event_InProgress]
(
    EventDate,
    ClientType,
    ClientKind,
    ClientID,
    CreditID,
    CreditName,
    ContactPerson,
    ResponsibleID,
    ResponsibleName,
    BranchID,
    BranchName,
    EventStatus,
    EventKind,
    EventType,
    ProjectID,
    ProjectName,
    EventContent,
    EventResult,
    EventPandemicRelated,
    DecisionDeadline,
    MobilePhone,
    AdditionalPhone,
    PaymentDate,
    CallStatus
)
SELECT
    [СведенияОСобытияхВРаботе Дата События]             AS EventDate,
    [СведенияОСобытияхВРаботе Контрагент Tип]          AS ClientType,
    [СведенияОСобытияхВРаботе Контрагент Вид]          AS ClientKind,
    [СведенияОСобытияхВРаботе Контрагент ID]           AS ClientID,
    [СведенияОСобытияхВРаботе Кредит ID]               AS CreditID,
    [СведенияОСобытияхВРаботе Кредит]                  AS CreditName,
    [СведенияОСобытияхВРаботе Контактное Лицо]         AS ContactPerson,
    [СведенияОСобытияхВРаботе Ответственный ID]        AS ResponsibleID,
    [СведенияОСобытияхВРаботе Ответственный]           AS ResponsibleName,
    [СведенияОСобытияхВРаботе Филиал ID]               AS BranchID,
    [СведенияОСобытияхВРаботе Филиал]                  AS BranchName,
    [СведенияОСобытияхВРаботе Состояние События]       AS EventStatus,
    [СведенияОСобытияхВРаботе Вид События]             AS EventKind,
    [СведенияОСобытияхВРаботе Тип События]             AS EventType,
    [СведенияОСобытияхВРаботе Проект ID]               AS ProjectID,
    [СведенияОСобытияхВРаботе Проект]                  AS ProjectName,
    [СведенияОСобытияхВРаботе Содержание События]      AS EventContent,
    [СведенияОСобытияхВРаботе Результат События]       AS EventResult,
    [СведенияОСобытияхВРаботе Событие Связано с Пандемией] AS EventPandemicRelated,
    [СведенияОСобытияхВРаботе Срок Выполнения Решения] AS DecisionDeadline,
    [СведенияОСобытияхВРаботе Телефон Мобильный]       AS MobilePhone,
    [СведенияОСобытияхВРаботе Дополнительный Телефон]  AS AdditionalPhone,
    [СведенияОСобытияхВРаботе Дата Оплаты]             AS PaymentDate,
    [СведенияОСобытияхВРаботе Статус Телефонного Звонка] AS CallStatus

FROM [ATK].[dbo].[РегистрыСведений.СведенияОСобытияхВРаботе] e


WHERE NOT EXISTS (
    SELECT 1
    FROM mis.[Gold_Dim_Event_InProgress] g
    WHERE g.ClientID = e.[СведенияОСобытияхВРаботе Контрагент ID]
      AND g.EventDate = e.[СведенияОСобытияхВРаботе Дата События]
      AND g.ResponsibleID = e.[СведенияОСобытияхВРаботе Ответственный ID]
      );
----------------------------------------------------------------------------------------------------
-- End of:   V2__inc_Gold_Dim_Event_InProgress.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: V2__inc_Gold_Dim_Event_Responsible.sql
----------------------------------------------------------------------------------------------------
INSERT INTO mis.[Gold_Dim_Event_Responsible]
(
    EventDocumentID,
    EventRowNumber,
    ClientType,
    ClientKind,
    ClientID,
    EventStatus,
    ResponsibleID,
    ResponsibleName,
    SelectionFlag,
    NewResponsibleID,
    NewResponsibleName,
    NewBranchID,
    NewBranchName,
    AffiliatedGroupID,
    AffiliatedGroupName
)
SELECT
    [УстановкаОтветственныхПоКредитамИКлиентам ID]                             AS EventDocumentID,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Номер Строки]           AS EventRowNumber,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Клиент Tип]             AS ClientType,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Клиент Вид]             AS ClientKind,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Клиент ID]              AS ClientID,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Состояние События]      AS EventStatus,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Ответственный ID]       AS ResponsibleID,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Ответственный]          AS ResponsibleName,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Отметка Выбора]         AS SelectionFlag,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Новый Ответственный ID] AS NewResponsibleID,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Новый Ответственный]    AS NewResponsibleName,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Новый Филиал ID]        AS NewBranchID,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Новый Филиал]           AS NewBranchName,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Группа Аффилированных Лиц ID]  AS AffiliatedGroupID,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Группа Аффилированных Лиц]     AS AffiliatedGroupName
	
FROM [ATK].[dbo].[Документы.УстановкаОтветственныхПоКредитамИКлиентам.События] e
WHERE NOT EXISTS (
    SELECT 1
    FROM mis.[Gold_Dim_Event_Responsible] g
    WHERE g.EventDocumentID = e.[УстановкаОтветственныхПоКредитамИКлиентам ID]
      AND g.EventRowNumber  = e.[УстановкаОтветственныхПоКредитамИКлиентам.События Номер Строки]
);
----------------------------------------------------------------------------------------------------
-- End of:   V2__inc_Gold_Dim_Event_Responsible.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: V2__inc_Gold_Dim_Limits.sql
----------------------------------------------------------------------------------------------------
;WITH LatestGroups AS
(
    SELECT
        sg.[СоставГруппАффилированныхЛиц Контрагент ID] AS ClientID,
        sg.[СоставГруппАффилированныхЛиц Группа Аффилированных Лиц ID] AS GroupID,
        sg.[СоставГруппАффилированныхЛиц Период] AS Period,
        d.[РегистрацияЛимита ID] AS LimitRegID,
        ROW_NUMBER() OVER(PARTITION BY d.[РегистрацияЛимита ID] ORDER BY sg.[СоставГруппАффилированныхЛиц Период] DESC) AS rn
    FROM [ATK].[dbo].[РегистрыСведений.СоставГруппАффилированныхЛиц] sg
    JOIN [ATK].[dbo].[Документы.РегистрацияЛимита] d
        ON sg.[СоставГруппАффилированныхЛиц Контрагент ID] = d.[РегистрацияЛимита Основной Клиент ID]
       AND sg.[СоставГруппАффилированныхЛиц Период] <= d.[РегистрацияЛимита Дата]
    WHERE d.[РегистрацияЛимита Проведен] = '01'
      AND d.[РегистрацияЛимита Пометка Удаления] = '00'
)
INSERT INTO mis.[Gold_Dim_Limits]
(
    [LimitRegistrationID],
    [LimitRegistrationDate],
    [AuthorID],
    [AuthorName],
    [UsageType],
    [LimitType],
    [OperationType],
    [DecisionDate],
    [BaseDocumentType],
    [BaseDocumentID],
    [ValidityMonths],
    [CommitteeID],
    [CommitteeName],
    [Comment],
    [CreditExpertID],
    [CreditExpertName],
    [LimitRegLimitID],
    [MainClientID],
    [MainClientName],
    [CommitteeChairmanID],
    [CommitteeChairmanName],
    [MIRepresentativeID],
    [MIRepresentativeName],
    [RejectionReasonID],
    [RejectionReason],
    [RejectionReasonDescription],
    [RegistrationStatus],
    [ApprovedAmount],
    [DecisionText],
    [BranchID],
    [BranchName],
    [ExcessPercentage],
    [SummaryData],
    [SubmissionDate],
    [IsSummaryCompleted],
    [AffiliatedGroupID],
    [AffiliatedGroupName],
    [ConsolidatedBalance],
    [EffectiveStartDate],
    [AnalysisType],
    [UnsecuredAmount],
    [UnsecuredAmountComment],
    [IsIndividualGuaranteeAnalyzed],
    [ProceduralUnsecuredAmount],
    [LimitID],
    [LimitDeletedFlag],
    [LimitCode],
    [GroupOwner],
    [GroupNameFull],
    [EmployeeID]
)
SELECT  
     d.[РегистрацияЛимита ID]                       AS [LimitRegistrationID],
     d.[РегистрацияЛимита Дата]                     AS [LimitRegistrationDate],
     d.[РегистрацияЛимита Автор ID]                 AS [AuthorID],
     d.[РегистрацияЛимита Автор]                    AS [AuthorName],
     d.[РегистрацияЛимита Вид Использования]        AS [UsageType],
     d.[РегистрацияЛимита Вид Лимита]               AS [LimitType],
     d.[РегистрацияЛимита Вид Операции]             AS [OperationType],
     d.[РегистрацияЛимита Дата Решения]             AS [DecisionDate],
     d.[РегистрацияЛимита Документ Основание Tип]   AS [BaseDocumentType],
     d.[РегистрацияЛимита Документ Основание ID]    AS [BaseDocumentID],
     d.[РегистрацияЛимита Количество Месяцев Действия Лимита]     AS [ValidityMonths],
     d.[РегистрацияЛимита Комитет ID]               AS [CommitteeID],
     d.[РегистрацияЛимита Комитет]                  AS [CommitteeName],
     d.[РегистрацияЛимита Комментарий]              AS [Comment],
     d.[РегистрацияЛимита Кредитный Эксперт ID]     AS [CreditExpertID],
     d.[РегистрацияЛимита Кредитный Эксперт]        AS [CreditExpertName],
     d.[РегистрацияЛимита Лимит ID]                 AS [LimitRegLimitID],
     d.[РегистрацияЛимита Основной Клиент ID]       AS [MainClientID],
     d.[РегистрацияЛимита Основной Клиент]          AS [MainClientName],
     d.[РегистрацияЛимита Председатель Комитета ID] AS [CommitteeChairmanID],
     d.[РегистрацияЛимита Председатель Комитета]    AS [CommitteeChairmanName],
     d.[РегистрацияЛимита Представитель MI ID]      AS [MIRepresentativeID],
     d.[РегистрацияЛимита Представитель MI]         AS [MIRepresentativeName],
     d.[РегистрацияЛимита Причина Отказа ID]        AS [RejectionReasonID],
     d.[РегистрацияЛимита Причина Отказа]           AS [RejectionReason],
     d.[РегистрацияЛимита Причина Отказа Описание]  AS [RejectionReasonDescription],
     d.[РегистрацияЛимита Состояние]                AS [RegistrationStatus],
     d.[РегистрацияЛимита Сумма]                    AS [ApprovedAmount],
     d.[РегистрацияЛимита Текст Решения]            AS [DecisionText],
     d.[РегистрацияЛимита Филиал ID]                AS [BranchID],
     d.[РегистрацияЛимита Филиал]                   AS [BranchName],
     d.[РегистрацияЛимита Процент Превышения Лимита]       AS [ExcessPercentage],
     d.[РегистрацияЛимита Данные Резюме]                   AS [SummaryData],
     d.[РегистрацияЛимита Дата Отправки на Рассмотрение]   AS [SubmissionDate],
     d.[РегистрацияЛимита Резюме Заполнено]                AS [IsSummaryCompleted],
     d.[РегистрацияЛимита Группа Аффилированных Лиц ID]    AS [AffiliatedGroupID],
     d.[РегистрацияЛимита Группа Аффилированных Лиц]       AS [AffiliatedGroupName],
     d.[РегистрацияЛимита Консолидированное Сальдо]        AS [ConsolidatedBalance],
     d.[РегистрацияЛимита Начало Действия]                 AS [EffectiveStartDate],
     d.[РегистрацияЛимита Тип Анализа Лимита]              AS [AnalysisType],
     d.[РегистрацияЛимита Сумма к Выдаче без Залога]       AS [UnsecuredAmount],
     d.[РегистрацияЛимита Комментарий Сумма к Выдаче без Залога] AS [UnsecuredAmountComment],
     d.[РегистрацияЛимита Предложенное Поручительство Анализировано Индивидуально] AS [IsIndividualGuaranteeAnalyzed],
     d.[РегистрацияЛимита В Соответствии с Процедурой Сумма к Выдаче без Залога]   AS [ProceduralUnsecuredAmount],
     l.[Лимиты ID]                                    AS [LimitID],
     l.[Лимиты Пометка Удаления]                      AS [LimitDeletedFlag],
     l.[Лимиты Код]                                   AS [LimitCode],
     COALESCE(g.[ГруппыАффилированныхЛиц Владелец], d.[РегистрацияЛимита Основной Клиент ID])  AS [GroupOwner],
     g.[ГруппыАффилированныхЛиц Наименование]         AS [GroupNameFull],
     CASE 
         WHEN k.[Контрагенты Сотрудник ID] = '00000000000000000000000000000000' 
         THEN NULL 
         ELSE k.[Контрагенты Сотрудник ID] 
     END AS [EmployeeID]
FROM [ATK].[dbo].[Документы.РегистрацияЛимита] d
LEFT JOIN [ATK].[dbo].[Справочники.Лимиты] l
       ON d.[РегистрацияЛимита Лимит ID] = l.[Лимиты ID]
LEFT JOIN LatestGroups lg
       ON lg.LimitRegID = d.[РегистрацияЛимита ID] AND lg.rn = 1
LEFT JOIN [ATK].[dbo].[Справочники.ГруппыАффилированныхЛиц] g
       ON lg.GroupID = g.[ГруппыАффилированныхЛиц ID]
LEFT JOIN [ATK].[dbo].[Справочники.Контрагенты] k
       ON k.[Контрагенты ID] = COALESCE(g.[ГруппыАффилированныхЛиц Владелец], d.[РегистрацияЛимита Основной Клиент ID])
WHERE d.[РегистрацияЛимита Проведен] = '01'
  AND d.[РегистрацияЛимита Пометка Удаления] = '00'
  AND NOT EXISTS
  (
      SELECT 1
      FROM mis.[Gold_Dim_Limits] gl
      WHERE gl.LimitRegistrationID = d.[РегистрацияЛимита ID]
  );
----------------------------------------------------------------------------------------------------
-- End of:   V2__inc_Gold_Dim_Limits.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: V3__inc_Gold_Fact_Restruct_Daily_Sold_Par.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

---------------------------------------------------------
-- PARAMETERS (incremental window)
---------------------------------------------------------
DECLARE @DateFrom date = DATEADD(day, -60, CAST(GETDATE() AS date));
DECLARE @DateTo   date = CAST(GETDATE() AS date);

PRINT N'=== Incremental load [mis].[Gold_Fact_Restruct_Daily_Sold_Par] '
    + CONVERT(varchar(10), @DateFrom, 23)
    + N' → '
    + CONVERT(varchar(10), @DateTo, 23) + N' ===';

---------------------------------------------------------
-- DELETE TARGET WINDOW (idempotent)
---------------------------------------------------------
DELETE FROM [mis].[Gold_Fact_Restruct_Daily_Sold_Par]
WHERE SoldDate BETWEEN @DateFrom AND @DateTo;

---------------------------------------------------------
-- CLEAN TEMP
---------------------------------------------------------
IF OBJECT_ID('tempdb..#Base')          IS NOT NULL DROP TABLE #Base;
IF OBJECT_ID('tempdb..#MaxDays')       IS NOT NULL DROP TABLE #MaxDays;
IF OBJECT_ID('tempdb..#Flag')          IS NOT NULL DROP TABLE #Flag;
IF OBJECT_ID('tempdb..#RespEarliest')  IS NOT NULL DROP TABLE #RespEarliest;
IF OBJECT_ID('tempdb..#Joined_raw')    IS NOT NULL DROP TABLE #Joined_raw;
IF OBJECT_ID('tempdb..#Joined')        IS NOT NULL DROP TABLE #Joined;
IF OBJECT_ID('tempdb..#IRR')           IS NOT NULL DROP TABLE #IRR;
IF OBJECT_ID('tempdb..#Responsible')   IS NOT NULL DROP TABLE #Responsible;

---------------------------------------------------------
-- RESPONSIBLE (source-based)
---------------------------------------------------------
SELECT
    [ОтветственныеПоКредитамВыданным Кредит ID] AS CreditID,
    [ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS EmployeeID,
    [ОтветственныеПоКредитамВыданным Филиал ID] AS BranchID,
    CAST([ОтветственныеПоКредитамВыданным Период] AS date) AS Period
INTO #Responsible
FROM mis.[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным];

CREATE NONCLUSTERED INDEX IX_Resp ON #Responsible (CreditID, Period);

---------------------------------------------------------
-- IRR
---------------------------------------------------------
SELECT
    [УстановкаДанныхКредита Кредит ID] AS CreditID,
    [УстановкаДанныхКредита Внутренняя Норма Доходности Годовая] AS IRR_Year,
    [УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая] AS IRR_Client,
    CAST([УстановкаДанныхКредита Дата] AS date) AS IRRDate
INTO #IRR
FROM mis.[Bronze_Документы.УстановкаДанныхКредита]
WHERE [УстановкаДанныхКредита Кредит ID] IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_IRR ON #IRR (CreditID, IRRDate DESC);

---------------------------------------------------------
-- BASE
---------------------------------------------------------
;WITH cte AS (
    SELECT
        CAST(s.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS date) AS SoldDate,
        s.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
        s.[СуммыЗадолженностиПоПериодамПросрочки Клиент ID] AS ClientID,
        s.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] AS Balance_Total,
        s.[СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки Кредит] AS DaysBucket_Credit,
        s.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого] AS DaysFact_Total,
        s.[СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки МСФО] AS DaysIFRS,
        r.StateName AS StateName_Final,
        r.TypeName_Sticky AS TypeName_Sticky_Final,
        r.CreditStatus AS CreditStatus_Base,
        ROW_NUMBER() OVER (
            PARTITION BY
                s.[СуммыЗадолженностиПоПериодамПросрочки Клиент ID],
                s.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID],
                CAST(s.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS date)
            ORDER BY s.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] DESC
        ) AS rn,
        (
            SELECT TOP (1)
                CASE WHEN i.IRR_Year < 100 THEN i.IRR_Year ELSE i.IRR_Client END
            FROM #IRR i
            WHERE i.CreditID = s.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
              AND i.IRRDate <= CAST(s.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS date)
            ORDER BY i.IRRDate DESC
        ) AS IRR_Rate
    FROM mis.[Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] s
    LEFT JOIN mis.[Silver_Restruct_Merged_SCD] r
        ON r.CreditID = s.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
       AND CAST(s.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS date)
           BETWEEN r.ValidFrom AND r.ValidTo
    WHERE s.[СуммыЗадолженностиПоПериодамПросрочки Дата]
          BETWEEN @DateFrom AND @DateTo
)
SELECT *
INTO #Base
FROM cte
WHERE rn = 1;

---------------------------------------------------------
-- MAX DAYS
---------------------------------------------------------
SELECT ClientID, SoldDate, MAX(DaysFact_Total) AS MaxDaysPerClientDay
INTO #MaxDays
FROM #Base
GROUP BY ClientID, SoldDate;

---------------------------------------------------------
-- UNHEALED FLAG
---------------------------------------------------------
SELECT DISTINCT ClientID, SoldDate
INTO #Flag
FROM mis.[Silver_Client_UnhealedFlag]
WHERE HasUnhealed = 1
  AND SoldDate BETWEEN @DateFrom AND @DateTo;

---------------------------------------------------------
-- EARLIEST RESPONSIBLE
---------------------------------------------------------
;WITH MinFrom AS (
    SELECT CreditID, MIN(ValidFrom) AS MinValidFrom
    FROM mis.[Silver_Resp_SCD]
    GROUP BY CreditID
)
SELECT r.CreditID, r.FinalBranchID, r.FinalExpertID, r.IsSpecialBranch
INTO #RespEarliest
FROM mis.[Silver_Resp_SCD] r
JOIN MinFrom m
  ON r.CreditID = m.CreditID
 AND r.ValidFrom = m.MinValidFrom;

---------------------------------------------------------
-- JOIN RESPONSIBLE + STAGE
---------------------------------------------------------
SELECT
    b.*,
    COALESCE(rc.FinalBranchID, e.FinalBranchID) AS LastBranchID,
    COALESCE(rc.FinalExpertID, e.FinalExpertID) AS LastExpertID,
    f.EmployeeID,
    f.BranchID,
    COALESCE(rc.IsSpecialBranch, e.IsSpecialBranch) AS IsSpecialBranch,
    st.StageName AS CurrentStage
INTO #Joined_raw
FROM #Base b
OUTER APPLY (
    SELECT TOP (1) *
    FROM mis.[Silver_Resp_SCD] r
    WHERE r.CreditID = b.CreditID
      AND b.SoldDate BETWEEN r.ValidFrom AND r.ValidTo
    ORDER BY r.ValidFrom DESC
) rc
LEFT JOIN #RespEarliest e ON e.CreditID = b.CreditID
LEFT JOIN mis.[Silver_Stages_SCD] st
  ON st.CreditID = b.CreditID
 AND b.SoldDate BETWEEN st.ValidFrom AND st.ValidTo
OUTER APPLY (
    SELECT TOP (1) rr.EmployeeID, rr.BranchID
    FROM #Responsible rr
    WHERE rr.CreditID = b.CreditID
      AND rr.Period <= b.SoldDate
    ORDER BY rr.Period DESC
) f;

---------------------------------------------------------
-- PAR IFRS
---------------------------------------------------------
SELECT
    jr.*,
    CASE
        WHEN md.MaxDaysPerClientDay BETWEEN 1  AND 30  THEN N'Par0'
        WHEN md.MaxDaysPerClientDay BETWEEN 31 AND 60  THEN N'Par30'
        WHEN md.MaxDaysPerClientDay BETWEEN 61 AND 90  THEN N'Par60'
        WHEN md.MaxDaysPerClientDay BETWEEN 91 AND 180 THEN N'Par90'
        WHEN md.MaxDaysPerClientDay BETWEEN 181 AND 270 THEN N'Par180'
        WHEN md.MaxDaysPerClientDay BETWEEN 271 AND 360 THEN N'Par270'
        WHEN md.MaxDaysPerClientDay > 360           THEN N'Par360'
    END AS ParIFRS
INTO #Joined
FROM #Joined_raw jr
JOIN #MaxDays md
  ON md.ClientID = jr.ClientID
 AND md.SoldDate = jr.SoldDate;

---------------------------------------------------------
-- FINAL INSERT
---------------------------------------------------------
INSERT INTO mis.[Gold_Fact_Restruct_Daily_Sold_Par]
(
    SoldDate, CreditID, ClientID, Balance_Total, IRR_Values,
    DaysBucket_Credit, DaysFact_Total, DaysIFRS,
    StateName_Final, TypeName_Sticky_Final, CreditStatus_Base,
    LastBranchID, LastExpertID, BranchID, EmployeeID,
    IsSpecialBranch, SegmentIFRS, ParIFRS, Par, StageName
)
SELECT
    j.SoldDate,
    j.CreditID,
    j.ClientID,
    j.Balance_Total,
    ROUND(ISNULL(j.IRR_Rate,0) * j.Balance_Total, 2),
    j.DaysBucket_Credit,
    j.DaysFact_Total,
    j.DaysIFRS,
    j.StateName_Final,
    j.TypeName_Sticky_Final,
    j.CreditStatus_Base,
    j.LastBranchID,
    j.LastExpertID,
    j.BranchID,
    j.EmployeeID,
    j.IsSpecialBranch,
    CASE
        WHEN j.DaysIFRS >= 91 THEN N'e) 90 +'
        WHEN j.DaysIFRS >= 31 THEN N'd) 30 - 90'
        WHEN j.DaysIFRS >= 16 THEN N'c) 16 - 30'
        WHEN j.DaysIFRS >= 4  THEN N'b) 4 - 15'
        ELSE N'a) 0 - 3'
    END,
    j.ParIFRS,
    CASE
        WHEN j.DaysBucket_Credit BETWEEN 1   AND 30  THEN N'Par0'
        WHEN j.DaysBucket_Credit BETWEEN 31  AND 60  THEN N'Par30'
        WHEN j.DaysBucket_Credit BETWEEN 61  AND 90  THEN N'Par60'
        WHEN j.DaysBucket_Credit BETWEEN 91 AND 180 THEN N'Par90'
        WHEN j.DaysBucket_Credit BETWEEN 181 AND 270 THEN N'Par180'
        WHEN j.DaysBucket_Credit BETWEEN 271 AND 360 THEN N'Par270'
        WHEN j.DaysBucket_Credit > 360           THEN N'Par360'
    END,
    CASE j.CurrentStage
        WHEN N'Стадия1' THEN N'Stage1'
        WHEN N'Стадия2' THEN N'Stage2'
        WHEN N'Стадия3' THEN N'Stage3'
        ELSE j.CurrentStage
    END
FROM #Joined j;

PRINT N'🏁 Incremental load completed successfully';
----------------------------------------------------------------------------------------------------
-- End of:   V3__inc_Gold_Fact_Restruct_Daily_Sold_Par.sql
----------------------------------------------------------------------------------------------------

GO

