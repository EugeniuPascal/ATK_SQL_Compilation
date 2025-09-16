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
    [IsDeleted]             NVARCHAR(36)   NULL,
    [IsGroup]               NVARCHAR(36)   NULL,
    [ClientCode]            NVARCHAR(50)   NULL,
    [ClientName]            NVARCHAR(255)  NULL,
    [IsBlocked]             NVARCHAR(36)   NULL,
    [Visibility]            NVARCHAR(255)  NULL,
    [Age]                   INT            NULL,
    [AgeGroup]              NVARCHAR(10)   NULL,
    [City]                  NVARCHAR(255)  NULL,
    [CreatedDate]           DATETIME2(0)   NULL,
    [PartnerCode]           NVARCHAR(50)   NULL,
    [FullName]              NVARCHAR(500)  NULL,
    [IsNonResident]         NVARCHAR(36)   NULL,
    [NoPaymentNotification] NVARCHAR(36)   NULL,
    [Gender]                NVARCHAR(50)   NULL,
    [PostalAddress]         NVARCHAR(500)  NULL,
    [Country]               NVARCHAR(255)  NULL,
    [MobilePhone1]          NVARCHAR(50)   NULL,
    [MobilePhone2]          NVARCHAR(50)   NULL,
    [Phones]                NVARCHAR(255)  NULL,
    [FiscalCode]            NVARCHAR(50)   NULL,
    [LegalAddress]          NVARCHAR(500)  NULL,
    [RegistrationDate]      DATETIME2(0)   NULL,
    [Language]              NVARCHAR(50)   NULL,
    [NoEmailNotifications]  NVARCHAR(36)   NULL,
    [NoPromoSMS]            NVARCHAR(36)   NULL,
    [OrganizationType]      NVARCHAR(500)  NULL,
    [GroupOwner]            VARCHAR(36)    NULL,
    [GroupID]               NVARCHAR(5)    NULL,
    CONSTRAINT PK_2tbl_Gold_Dim_Clients PRIMARY KEY CLUSTERED (ClientID)
);
GO

-- Prepare source data with organization type and group affiliation
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
        gb.[СоставГруппАффилированныхЛиц Контрагент ID] AS GroupOwner,
        ga.[ГруппыАффилированныхЛиц Код] AS GroupID
    FROM [ATK].[mis].[Silver_Справочники.Контрагенты] s
    LEFT JOIN [ATK].[dbo].[Справочники.ФормыПредприятия] fp
        ON fp.[ФормыПредприятия Наименование] = s.[Контрагенты Форма Организации]
    LEFT JOIN [ATK].[dbo].[РегистрыСведений.СоставГруппАффилированныхЛиц] gb
        ON gb.[СоставГруппАффилированныхЛиц Контрагент ID] = s.[Контрагенты ID]
    LEFT JOIN [ATK].[dbo].[Справочники.ГруппыАффилированныхЛиц] ga
        ON ga.[ГруппыАффилированныхЛиц ID] = gb.[СоставГруппАффилированныхЛиц Группа Аффилированных Лиц ID]
),
AgeCalc AS (
    SELECT *,
        CASE 
            WHEN DOB IS NULL THEN NULL
            WHEN DOB > CAST(SYSDATETIME() AS date) THEN NULL
            ELSE DATEDIFF(YEAR, DOB, CAST(SYSDATETIME() AS date))
                 - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, DOB, CAST(SYSDATETIME() AS date)), DOB) > CAST(SYSDATETIME() AS date) THEN 1 ELSE 0 END
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
        GroupOwner, GroupID
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
-- Insert only the latest per ClientID
INSERT INTO mis.[2tbl_Gold_Dim_Clients] (
    [ClientID],[ParentID],[BranchID],
    [IsDeleted],[IsGroup],[ClientCode],[ClientName],[IsBlocked],[Visibility],
    [Age],[AgeGroup],[City],[CreatedDate],[PartnerCode],[FullName],[IsNonResident],[NoPaymentNotification],
    [Gender],[PostalAddress],[Country],[MobilePhone1],[MobilePhone2],[Phones],
    [FiscalCode],[LegalAddress],[RegistrationDate],[Language],
    [NoEmailNotifications],[NoPromoSMS],[OrganizationType],
    [GroupOwner],[GroupID]
)
SELECT
    ClientID, ParentID, BranchID,
    IsDeleted, IsGroup, ClientCode, ClientName, IsBlocked, Visibility,
    Age, AgeGroup, City, CreatedDate, PartnerCode, FullName, IsNonResident, NoPaymentNotification,
    Gender, PostalAddress, Country, MobilePhone1, MobilePhone2, Phones,
    FiscalCode, LegalAddress, RegistrationDate, [Language],
    NoEmailNotifications, NoPromoSMS, OrganizationType,
    GroupOwner, GroupID
FROM Dedup
WHERE rn = 1;
GO

-- Create indexes
CREATE NONCLUSTERED INDEX IX_Clients_Branch    ON mis.[2tbl_Gold_Dim_Clients](BranchID)   INCLUDE (ClientName, IsBlocked);
CREATE NONCLUSTERED INDEX IX_Clients_AgeGroup  ON mis.[2tbl_Gold_Dim_Clients](AgeGroup)  INCLUDE (City, Country);
CREATE NONCLUSTERED INDEX IX_Clients_IsDeleted ON mis.[2tbl_Gold_Dim_Clients](IsDeleted) INCLUDE (ClientName);
CREATE NONCLUSTERED INDEX IX_Clients_Group     ON mis.[2tbl_Gold_Dim_Clients](GroupOwner, GroupID);
GO
