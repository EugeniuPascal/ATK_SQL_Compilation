USE [ATK];
GO

-- Drop table if exists
IF OBJECT_ID('mis.[Silver_SCD_GroupMembershipPeriods]', 'U') IS NOT NULL
    DROP TABLE mis.[Silver_SCD_GroupMembershipPeriods];
GO

-- Create table
CREATE TABLE mis.[Silver_SCD_GroupMembershipPeriods]
(
    GroupID        VARCHAR(36) NOT NULL,
    PersonID       VARCHAR(36) NULL,
    PersonName     NVARCHAR(255) NOT NULL,
    GroupName      NVARCHAR(255) NULL,
    GroupOwner     VARCHAR(36) NULL,
    PeriodStart    DATETIME2(0) NOT NULL,
    PeriodEnd      DATETIME2(0) NOT NULL
);
GO

-- CTEs
WITH Events AS (
    SELECT
        sg.[СоставГруппАффилированныхЛиц Группа Аффилированных Лиц ID] AS GroupID,
        sg.[СоставГруппАффилированныхЛиц Контрагент ID] AS PersonID,
        sg.[СоставГруппАффилированныхЛиц Контрагент] AS PersonName,
        sg.[СоставГруппАффилированныхЛиц Период] AS PeriodOriginal,
        sg.[СоставГруппАффилированныхЛиц Исключен] AS ExcludedFlag,
        sg.[СоставГруппАффилированныхЛиц Группа Аффилированных Лиц] AS GroupName,
        g.[ГруппыАффилированныхЛиц Владелец] AS GroupOwner,
        CASE WHEN sg.[СоставГруппАффилированныхЛиц Исключен] = '00'
             THEN 'Included'
             ELSE 'Excluded'
        END AS EventType,
        g.[ГруппыАффилированныхЛиц Пометка Удаления] AS DeletionFlag
    FROM [ATK].[dbo].[РегистрыСведений.СоставГруппАффилированныхЛиц] sg
    LEFT JOIN [ATK].[dbo].[Справочники.ГруппыАффилированныхЛиц] g
        ON g.[ГруппыАффилированныхЛиц ID] =
           sg.[СоставГруппАффилированныхЛиц Группа Аффилированных Лиц ID]
),
Ordered AS (
    SELECT
        *,
        LEAD(PeriodOriginal) OVER (
            PARTITION BY GroupID, PersonName 
            ORDER BY PeriodOriginal
        ) AS NextDate,
        LEAD(EventType) OVER (
            PARTITION BY GroupID, PersonName 
            ORDER BY PeriodOriginal
        ) AS NextType
    FROM Events
)
-- INSERT INTO final table
INSERT INTO mis.[Silver_SCD_GroupMembershipPeriods]
(
    GroupID,
    PersonID,
    PersonName,
    GroupName,
    GroupOwner,
    PeriodStart,
    PeriodEnd
)
SELECT
      GroupID,
      PersonID,
      PersonName,
      GroupName,
      GroupOwner,
      PeriodOriginal AS PeriodStart,
      CASE 
        WHEN NextType = 'Excluded'
            THEN DATEADD(SECOND, -1, NextDate)
        ELSE CONVERT(DATETIME2, '2222-01-01 00:00:00')
      END AS PeriodEnd
FROM Ordered
WHERE EventType = 'Included'
  AND DeletionFlag = '00'
ORDER BY GroupID, PersonName, PeriodOriginal;
