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


