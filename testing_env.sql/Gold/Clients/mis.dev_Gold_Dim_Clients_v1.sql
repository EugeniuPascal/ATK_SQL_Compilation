USE [ATK];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*==============================================================
  DROP + CREATE TABLE
==============================================================*/
IF OBJECT_ID(N'mis.dev_Gold_Dim_Clients_v1', 'U') IS NOT NULL
    DROP TABLE mis.dev_Gold_Dim_Clients_v1;
GO

CREATE TABLE mis.dev_Gold_Dim_Clients_v1
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
	EmployeeID              VARCHAR(36)   NULL,
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
	ТелефонМобильный_Last           NVARCHAR(50)  NULL,
    ТелефонМобильный_LastDate       DATETIME2(0)  NULL,
    ТелефонМобильный_LastEventID    VARCHAR(36)   NULL,

    ФискКод_Last                    NVARCHAR(50)  NULL,
    ФискКод_LastDate                DATETIME2(0)  NULL,
    ФискКод_LastEventID             VARCHAR(36)   NULL,

    Venit_dupa_hotare               BIT           NULL,
    ФилиалID_Original               VARCHAR(36)   NULL,


    CONSTRAINT PK_dev_Gold_Dim_Clients_v1
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

EvPhone AS (
    SELECT
          e.[КонтрагентID] AS ClientID
        , PhoneVal = NULLIF(LTRIM(RTRIM(e.[ТелефонМобильный])), '')
        , e.[Дата]
        , e.[ID]
        , rn = ROW_NUMBER() OVER (
            PARTITION BY e.[КонтрагентID]
            ORDER BY e.[Дата] DESC, e.[ID] DESC
        )
    FROM [mis].[Silver_Events] e
    WHERE e.[ТелефонМобильный] IS NOT NULL
    AND e.[ТелефонМобильный] <> ''
),

EvFisk AS (
    SELECT
          e.[КонтрагентID] AS ClientID
        , FiskVal = NULLIF(LTRIM(RTRIM(e.[ФискКод])), '')
        , e.[Дата]
        , e.[ID]
        , rn = ROW_NUMBER() OVER (
            PARTITION BY e.[КонтрагентID]
            ORDER BY e.[Дата] DESC, e.[ID] DESC
        )
    FROM [mis].[Silver_Events] e
    WHERE e.[ФискКод] IS NOT NULL
	AND e.[ФискКод] <> ''
),

VenitHotare AS (
    SELECT
        v.[Клиент ID] AS ClientID,
        Venit_dupa_hotare =
            CASE
                WHEN SUM(
                    CASE
                        WHEN v.[Вид Дохода] = N'ЗаграничныйДоход'
                             AND v.[Не Получает] IS NOT NULL
                             AND v.[Не Получает] <> 0x01
                        THEN 1 ELSE 0
                    END
                ) > 0 THEN 1 ELSE 0
            END
    FROM [mis].[Bronze_РегистрыСведений.СведенияОПрочихДоходахКлиента] v
    GROUP BY v.[Клиент ID]
),

CtrBranch AS (
    SELECT
        c.[Контрагенты ID]        AS ClientID,
        c.[Контрагенты Филиал ID] AS [Филиал ID]
    FROM [mis].[Bronze_Справочники.Контрагенты] c
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
		s.[Контрагенты Кредитный Эксперт ID]    AS EmployeeID,
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
        ) AS EffectiveDOB,
		
		ph.PhoneVal AS ТелефонМобильный_Last,
        ph.[Дата]   AS ТелефонМобильный_LastDate,
        ph.[ID]     AS ТелефонМобильный_LastEventID,

        fc.FiskVal  AS ФискКод_Last,
        fc.[Дата]   AS ФискКод_LastDate,
        fc.[ID]     AS ФискКод_LastEventID,

        ISNULL(vh.Venit_dupa_hotare, 0) AS Venit_dupa_hotare,

        cb.[Филиал ID] AS ФилиалID_Original
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
	LEFT JOIN EvPhone ph
        ON ph.ClientID = s.[Контрагенты ID] AND ph.rn = 1
    LEFT JOIN EvFisk fc
        ON fc.ClientID = s.[Контрагенты ID] AND fc.rn = 1
    LEFT JOIN VenitHotare vh
        ON vh.ClientID = s.[Контрагенты ID]
    LEFT JOIN CtrBranch cb
        ON cb.ClientID = s.[Контрагенты ID]
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

INSERT INTO mis.[dev_Gold_Dim_Clients_v1]
SELECT
    f.ClientID, f.ParentID, f.BranchID, f.IsDeleted, f.IsGroup, f.ClientCode, f.ClientName, f.IsBlocked,
    f.Visibility, f.Age, f.AgeGroup, f.City, f.CreatedDate, f.PartnerCode, f.FullName, f.IsNonResident,
    f.NoPaymentNotification, f.GenderClean, f.PostalAddress, f.Country, f.MobilePhone1, f.MobilePhone2,
    f.Phones, f.FiscalCode, f.LegalAddress, f.RegistrationDate, f.LanguageClean, f.NoEmailNotifications, 
	f.NoPromoSMS, f.EconomicSector, f.EmployeeID, f.OrganizationType, f.IsGroupOwner, f.GroupID, 
	f.CRM_Region_Address, f.CRM_City_Address, f.CRM_Status, f.CRM_ClientType, f.CRM_Employee,f.Phone, 
    f.ANK_LegalAddress, f.ANK_ActualAddress, f.ТелефонМобильный_Last, f.ТелефонМобильный_LastDate,
    f.ТелефонМобильный_LastEventID, f.ФискКод_Last, f.ФискКод_LastDate, f.ФискКод_LastEventID,
    f.Venit_dupa_hotare, f.ФилиалID_Original
FROM Final f
WHERE f.rn = 1;
GO

-- ===========================
-- Indexes
-- ===========================
CREATE NONCLUSTERED INDEX IX_Clients_Branch
ON mis.dev_Gold_Dim_Clients_v1 (BranchID)
INCLUDE (ClientName, IsBlocked);

CREATE NONCLUSTERED INDEX IX_Clients_AgeGroup
ON mis.dev_Gold_Dim_Clients_v1 (AgeGroup)
INCLUDE (City, Country);

CREATE NONCLUSTERED INDEX IX_Clients_IsDeleted
ON mis.dev_Gold_Dim_Clients_v1 (IsDeleted)
INCLUDE (ClientName);

CREATE NONCLUSTERED INDEX IX_Clients_Group
ON mis.dev_Gold_Dim_Clients_v1 (IsGroupOwner, GroupID);

CREATE NONCLUSTERED INDEX IX_Clients_Phone2
ON mis.dev_Gold_Dim_Clients_v1 (Phone);

CREATE INDEX IX_Silver_Events_Client_Date
ON mis.Silver_Events (КонтрагентID, Дата DESC);

GO
