USE [ATK];
GO
SET NOCOUNT ON;

IF OBJECT_ID(N'mis.[Gold_Dim_Clients1]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_Clients1];
GO

CREATE TABLE mis.[Gold_Dim_Clients1] 
(
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
    [GroupID]               NVARCHAR(20)   NULL,	
	[CRM_Region_Address]    NVARCHAR(150)  NULL,
    [CRM_City_Address]      NVARCHAR(150)  NULL,

    [CRM_Status]            NVARCHAR(50)   NULL,
    [CRM_ClientType]        NVARCHAR(50)   NULL,
    [CRM_Employee]          NVARCHAR(100)  NULL,

	[Contact_Info]          NVARCHAR(150)  NULL,

    [ANK_LegalAddress]      NVARCHAR(150)  NULL,
    [ANK_ActualAddress]     NVARCHAR(150)  NULL,
	
    CONSTRAINT PK_Gold_Dim_Clients1 PRIMARY KEY CLUSTERED (ClientID)
);
GO
-- Drop if exists
IF OBJECT_ID('tempdb..#SrcTemp') IS NOT NULL DROP TABLE #SrcTemp;

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
    g.[ГруппыАффилированныхЛиц Код] AS GroupID,
    crm.[СлужебныйДанныеПоКлиентуДляCRM Регион Юр Адрес] AS RegionLegalAddress,
    crm.[СлужебныйДанныеПоКлиентуДляCRM Регион Факт Адрес] AS RegionActualAddress,
    crm.[СлужебныйДанныеПоКлиентуДляCRM Населенный Пункт Юр Адрес] AS CityLegalAddress,
    crm.[СлужебныйДанныеПоКлиентуДляCRM Населенный Пункт Факт Адрес] AS CityActualAddress,
    crm.[СлужебныйДанныеПоКлиентуДляCRM Статус] AS CRMStatus,
    crm.[СлужебныйДанныеПоКлиентуДляCRM Тип Клиента CRM] AS CRMClientType,
    crm.[СлужебныйДанныеПоКлиентуДляCRM Сотрудник] AS CRMEmployee,
    ank.[АнкетаПерсональныхДанныхКлиента Юридический Адрес] AS ANK_LegalAddress,
    ank.[АнкетаПерсональныхДанныхКлиента Фактический Адрес] AS ANK_ActualAddress,
    ci.[КонтактнаяИнформация Поле 2] AS Contact_Info,
    CASE 
        WHEN r.[Контрагенты Возраст] <> '1753-01-01 00:00:00' THEN r.[Контрагенты Возраст]
        ELSE s.[Контрагенты Возраст]
    END AS EffectiveRepDOB
INTO #SrcTemp
FROM ATK.mis.[Bronze_Справочники.Контрагенты] s
LEFT JOIN ATK.mis.[Bronze_Справочники.Контрагенты] r
    ON r.[Контрагенты ID] = s.[Контрагенты Представитель Контрагента ID]
LEFT JOIN ATK.dbo.[Справочники.ФормыПредприятия] fp
    ON fp.[ФормыПредприятия Наименование] = s.[Контрагенты Форма Организации]
LEFT JOIN ATK.dbo.[РегистрыСведений.СоставГруппАффилированныхЛиц] sg
    ON sg.[СоставГруппАффилированныхЛиц Контрагент ID] = s.[Контрагенты ID]
LEFT JOIN ATK.dbo.[Справочники.ГруппыАффилированныхЛиц] g
    ON g.[ГруппыАффилированныхЛиц ID] = sg.[СоставГруппАффилированныхЛиц Группа Аффилированных Лиц ID]
LEFT JOIN dbo.[РегистрыСведений.СлужебныйДанныеПоКлиентуДляCRM] crm
    ON crm.[СлужебныйДанныеПоКлиентуДляCRM Клиент ID] = s.[Контрагенты ID]
LEFT JOIN dbo.[Документы.АнкетаПерсональныхДанныхКлиента] ank
    ON ank.[АнкетаПерсональныхДанныхКлиента Клиент ID] = s.[Контрагенты ID]
OUTER APPLY (
    SELECT TOP 1 ci.[КонтактнаяИнформация Поле 2]
    FROM [ATK].[dbo].[РегистрыСведений.КонтактнаяИнформация] ci
    WHERE ci.[КонтактнаяИнформация Объект ID] = s.[Контрагенты ID]
      AND ci.[КонтактнаяИнформация Вид] IN ('9BD07509DFA6385644A4DA59663DE54A', '855E215869755D34405C9E2F87D961A6')
    ORDER BY CASE ci.[КонтактнаяИнформация Вид]
                 WHEN '9BD07509DFA6385644A4DA59663DE54A' THEN 1
                 WHEN '855E215869755D34405C9E2F87D961A6' THEN 2
                 ELSE 3
             END
) ci;

IF OBJECT_ID('tempdb..#AgeCalcTemp') IS NOT NULL DROP TABLE #AgeCalcTemp;

SELECT *,
    CASE 
        WHEN EffectiveRepDOB IS NULL THEN NULL
        ELSE DATEDIFF(YEAR, EffectiveRepDOB, CAST(SYSDATETIME() AS date))
             - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, EffectiveRepDOB, CAST(SYSDATETIME() AS date)), EffectiveRepDOB) 
                     > CAST(SYSDATETIME() AS date) THEN 1 ELSE 0 END
    END AS Age
INTO #AgeCalcTemp
FROM #SrcTemp;

IF OBJECT_ID('tempdb..#FinalTemp') IS NOT NULL DROP TABLE #FinalTemp;

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
    CASE [Language] WHEN 'Русский' THEN 'Russian' WHEN 'Română' THEN 'Romanian' ELSE [Language] END AS LanguageClean,
    COALESCE(RegionLegalAddress, RegionActualAddress, ANK_LegalAddress) AS CRM_Region_Address,
    COALESCE(CityLegalAddress, CityActualAddress, ANK_ActualAddress) AS CRM_City_Address
INTO #FinalTemp
FROM #AgeCalcTemp;

IF OBJECT_ID('tempdb..#DedupTemp') IS NOT NULL DROP TABLE #DedupTemp;

SELECT *,
       ROW_NUMBER() OVER (PARTITION BY ClientID ORDER BY RegistrationDate DESC, CreatedDate DESC) AS rn
INTO #DedupTemp
FROM #FinalTemp;


INSERT INTO mis.[Gold_Dim_Clients1] (
    ClientID, ParentID, BranchID, IsDeleted, IsGroup, ClientCode, ClientName, IsBlocked, Visibility,
    Age, AgeGroup, City, CreatedDate, PartnerCode, FullName, IsNonResident, NoPaymentNotification,
    Gender, PostalAddress, Country, MobilePhone1, MobilePhone2, Phones,
    FiscalCode, LegalAddress, RegistrationDate, [Language],
    NoEmailNotifications, NoPromoSMS, EconomicSector, OrganizationType,
    IsGroupOwner, GroupID, CRM_Region_Address, CRM_City_Address,
    CRM_Status, CRM_ClientType, CRM_Employee, Contact_Info,
    ANK_LegalAddress, ANK_ActualAddress
)
SELECT
    ClientID, ParentID, BranchID, IsDeleted, IsGroup, ClientCode, ClientName, IsBlocked, Visibility,
    Age, AgeGroup, City, CreatedDate, PartnerCode, FullName, IsNonResident, NoPaymentNotification,
    GenderClean, PostalAddress, Country, MobilePhone1, MobilePhone2, Phones,
    FiscalCode, LegalAddress, RegistrationDate, LanguageClean,
    NoEmailNotifications, NoPromoSMS, EconomicSector, OrganizationType,
    IsGroupOwner, GroupID, CRM_Region_Address, CRM_City_Address,
    CRMStatus, CRMClientType, CRMEmployee, Contact_Info,
    ANK_LegalAddress, ANK_ActualAddress
FROM #DedupTemp
WHERE rn = 1;

--AND ClientID = 'b7bc00155d65140c11efc4286029fd98' ;
GO

-- Indexes
CREATE NONCLUSTERED INDEX IX_Clients_Branch    ON mis.[Gold_Dim_Clients1](BranchID)   INCLUDE (ClientName, IsBlocked);
CREATE NONCLUSTERED INDEX IX_Clients_AgeGroup  ON mis.[Gold_Dim_Clients1](AgeGroup)  INCLUDE (City, Country);
CREATE NONCLUSTERED INDEX IX_Clients_IsDeleted ON mis.[Gold_Dim_Clients1](IsDeleted) INCLUDE (ClientName);
CREATE NONCLUSTERED INDEX IX_Clients_Group     ON mis.[Gold_Dim_Clients1](IsGroupOwner, GroupID);
GO
