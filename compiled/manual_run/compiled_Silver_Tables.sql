-- Compiled SQL bundle
-- Generated: 2026-01-16 10:01:40
-- Source folder: C:\ATK_Project\sql_scripts\Silver
-- Files (7):
--   mis.Silver_Restruct_SCD.sql
--   mis.Silver_RestructState_SCD.sql
--   mis.Silver_Restruct_Merged_SCD.sql
--   mis.Silver_Client_UnhealedFlag.sql
--   mis.Silver_Resp_SCD.sql
--   mis.Silver_Stages_SCD.sql
--   mis.Silver_SCD_GroupMembershipPeriods.sql
----------------------------------------------------------------------------------------------------

SET NOCOUNT ON;

----------------------------------------------------------------------------------------------------
-- Start of: mis.Silver_Restruct_SCD.sql
----------------------------------------------------------------------------------------------------
USE ATK;
GO

SET NOCOUNT ON;

IF OBJECT_ID('mis.Silver_Restruct_SCD','U') IS NULL
BEGIN
    CREATE TABLE mis.Silver_Restruct_SCD 
	(
        CreditID        VARCHAR(36)   NOT NULL,
        ValidFrom       DATE          NOT NULL,
        ValidTo         DATE          NOT NULL,
        TypeName        NVARCHAR(200) NULL,
        Reason          NVARCHAR(500) NULL,
        NonCommSeenUpTo BIT           NOT NULL,
        CONSTRAINT PK_Silver_Restruct_SCD PRIMARY KEY (CreditID, ValidFrom)
    );
END
ELSE
BEGIN
    TRUNCATE TABLE mis.Silver_Restruct_SCD;
END

;WITH src AS (
    SELECT
        r.[РеструктурированныеКредиты Кредит ID] AS CreditID,
        CAST(r.[РеструктурированныеКредиты Период] AS DATE) AS PeriodDate,
        r.[РеструктурированныеКредиты Тип Реструктуризации Долга] AS TypeName,
        r.[РеструктурированныеКредиты Причина Реструктуризации] AS Reason,
        ROW_NUMBER() OVER (
            PARTITION BY
                r.[РеструктурированныеКредиты Кредит ID],
                CAST(r.[РеструктурированныеКредиты Период] AS DATE)
            ORDER BY r.[РеструктурированныеКредиты Период] DESC
        ) AS rn
    FROM mis.[Bronze_РегистрыСведений.РеструктурированныеКредиты] r
),
dedup AS (
    SELECT CreditID, PeriodDate, TypeName, Reason
    FROM src
    WHERE rn = 1
),
rng AS (
    SELECT
        CreditID,
        PeriodDate AS ValidFrom,
        LEAD(PeriodDate) OVER (PARTITION BY CreditID ORDER BY PeriodDate) AS NextFrom,
        TypeName,
        Reason,
        MAX(CASE WHEN TypeName = N'НекоммерческаяРеструктуризация' THEN 1 ELSE 0 END)
            OVER (PARTITION BY CreditID ORDER BY PeriodDate
                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS NonCommSeenUpTo
    FROM dedup
)
INSERT INTO mis.Silver_Restruct_SCD
    (CreditID, ValidFrom, ValidTo, TypeName, Reason, NonCommSeenUpTo)
SELECT
    CreditID,
    ValidFrom,
    COALESCE(DATEADD(day,-1, NextFrom), CONVERT(DATE,'9999-12-31')) AS ValidTo,
    TypeName,
    Reason,
    NonCommSeenUpTo
FROM rng;
----------------------------------------------------------------------------------------------------
-- End of:   mis.Silver_Restruct_SCD.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Silver_RestructState_SCD.sql
----------------------------------------------------------------------------------------------------
USE ATK;
GO

SET NOCOUNT ON;

IF OBJECT_ID('mis.Silver_RestructState_SCD','U') IS NULL
BEGIN
    CREATE TABLE mis.Silver_RestructState_SCD 
	(
        CreditID   VARCHAR(36)   NOT NULL,
        ValidFrom  DATE          NOT NULL,
        ValidTo    DATE          NOT NULL,
        StateName  NVARCHAR(50)  NULL,
        CONSTRAINT PK_Silver_RestructState_SCD PRIMARY KEY (CreditID, ValidFrom)
    );
END
ELSE
BEGIN
    TRUNCATE TABLE mis.Silver_RestructState_SCD;
END

;WITH src AS (
    SELECT
        s.[СостоянияРеструктурированныхКредитов Кредит ID] AS CreditID,
        CAST(s.[СостоянияРеструктурированныхКредитов Период] AS DATE) AS PeriodDate,
        s.[СостоянияРеструктурированныхКредитов Состояние Реструктурированного Кредита] AS StateName,
        ROW_NUMBER() OVER (
            PARTITION BY
                s.[СостоянияРеструктурированныхКредитов Кредит ID],
                CAST(s.[СостоянияРеструктурированныхКредитов Период] AS DATE)
            ORDER BY s.[СостоянияРеструктурированныхКредитов Период] DESC
        ) AS rn
    FROM mis.[Bronze_РегистрыСведений.СостоянияРеструктурированныхКредитов] s
),
dedup AS (
    SELECT CreditID, PeriodDate, StateName
    FROM src
    WHERE rn = 1
),
rng AS (
    SELECT
        CreditID,
        PeriodDate AS ValidFrom,
        LEAD(PeriodDate) OVER (PARTITION BY CreditID ORDER BY PeriodDate) AS NextFrom,
        StateName
    FROM dedup
)
INSERT INTO mis.Silver_RestructState_SCD
    (CreditID, ValidFrom, ValidTo, StateName)
SELECT
    CreditID,
    ValidFrom,
    COALESCE(DATEADD(day,-1, NextFrom), CONVERT(DATE,'9999-12-31')) AS ValidTo,
    StateName
FROM rng;
----------------------------------------------------------------------------------------------------
-- End of:   mis.Silver_RestructState_SCD.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Silver_Restruct_Merged_SCD.sql
----------------------------------------------------------------------------------------------------
USE ATK;
GO

SET NOCOUNT ON;

IF OBJECT_ID('mis.Silver_Restruct_Merged_SCD','U') IS NULL
BEGIN
    CREATE TABLE mis.Silver_Restruct_Merged_SCD 
	(
        CreditID        VARCHAR(36)   NOT NULL,
        ValidFrom       DATE          NOT NULL,
        ValidTo         DATE          NOT NULL,
        TypeName        NVARCHAR(200) NULL,
        Reason          NVARCHAR(500) NULL,
        StateName       NVARCHAR(200) NULL,
        TypeName_Sticky NVARCHAR(200) NULL,
        CreditStatus    NVARCHAR(200) NULL,
        ClientID        VARCHAR(36)   NULL,
        CONSTRAINT PK_Silver_Restruct_Merged_SCD PRIMARY KEY (CreditID, ValidFrom)
    );
END
ELSE
BEGIN
    IF COL_LENGTH('mis.Silver_Restruct_Merged_SCD', 'ClientID') IS NULL
        ALTER TABLE mis.Silver_Restruct_Merged_SCD ADD ClientID varchar(64) NULL;

    IF COL_LENGTH('mis.Silver_Restruct_Merged_SCD', 'CreditStatus') IS NULL
        ALTER TABLE mis.Silver_Restruct_Merged_SCD ADD CreditStatus nvarchar(200) NULL;

    TRUNCATE TABLE mis.Silver_Restruct_Merged_SCD;
END;

;WITH borders AS (
    SELECT CreditID, CAST(ValidFrom AS DATE) AS ValidFrom
    FROM   mis.Silver_Restruct_SCD
    UNION
    SELECT CreditID, CAST(ValidFrom AS DATE) AS ValidFrom
    FROM   mis.Silver_RestructState_SCD
    UNION
    SELECT
        s.[СтатусыКредитовВыданных Кредит ID] AS CreditID,
        CAST(s.[СтатусыКредитовВыданных Период] AS DATE) AS ValidFrom
    FROM mis.[Bronze_РегистрыСведений.СтатусыКредитовВыданных] s
    WHERE s.[СтатусыКредитовВыданных Активность] = 1
),
grid AS (
    SELECT CreditID, ValidFrom,
           LEAD(ValidFrom) OVER (PARTITION BY CreditID ORDER BY ValidFrom) AS NextFrom
    FROM borders
),
slices AS (
    SELECT CreditID, ValidFrom,
           COALESCE(DATEADD(day,-1, NextFrom), CONVERT(DATE,'9999-12-31')) AS ValidTo
    FROM grid
),
joined AS (
    SELECT z.CreditID, z.ValidFrom, z.ValidTo,
           r.TypeName, r.Reason, r.NonCommSeenUpTo,
           s.StateName,
           cs.[СтатусыКредитовВыданных Статус] AS CreditStatus,
           COALESCE(r.NonCommSeenUpTo,0) AS SeenNcHere
    FROM slices z
    OUTER APPLY (
        SELECT TOP (1) rr.TypeName, rr.Reason, rr.NonCommSeenUpTo
        FROM mis.Silver_Restruct_SCD rr
        WHERE rr.CreditID = z.CreditID
          AND rr.ValidFrom <= z.ValidFrom
          AND rr.ValidTo   >= z.ValidFrom
        ORDER BY rr.ValidFrom DESC
    ) r
    OUTER APPLY (
        SELECT TOP (1) ss.StateName
        FROM mis.Silver_RestructState_SCD ss
        WHERE ss.CreditID = z.CreditID
          AND ss.ValidFrom <= z.ValidFrom
          AND ss.ValidTo   >= z.ValidFrom
        ORDER BY ss.ValidFrom DESC
    ) s
    OUTER APPLY (
        SELECT TOP (1) s2.[СтатусыКредитовВыданных Статус]
        FROM mis.[Bronze_РегистрыСведений.СтатусыКредитовВыданных] s2
        WHERE s2.[СтатусыКредитовВыданных Кредит ID] = z.CreditID
          AND s2.[СтатусыКредитовВыданных Активность] = 1
          AND CAST(s2.[СтатусыКредитовВыданных Период] AS DATE) <= z.ValidFrom
        ORDER BY s2.[СтатусыКредитовВыданных Период] DESC
    ) cs
),
stick AS (
    SELECT j.*,
           MAX(j.SeenNcHere) OVER 
		   (PARTITION BY j.CreditID 
		   ORDER BY j.ValidFrom
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
		   ) AS SeenNcCumulative
    FROM joined j
)
INSERT INTO mis.Silver_Restruct_Merged_SCD
    (CreditID, ValidFrom, ValidTo, TypeName, Reason, StateName, TypeName_Sticky, CreditStatus, ClientID)
SELECT st.CreditID, st.ValidFrom, st.ValidTo,
       st.TypeName, st.Reason, 
	   st.StateName,
       CASE WHEN st.SeenNcCumulative = 1 THEN N'НекоммерческаяРеструктуризация'
            ELSE st.TypeName END AS TypeName_Sticky,
       st.CreditStatus,
       cr.[Кредиты Владелец] AS ClientID
FROM stick st
LEFT JOIN mis.[Bronze_Справочники.Кредиты] cr
       ON cr.[Кредиты ID] = st.CreditID;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID('mis.Silver_Restruct_Merged_SCD')
      AND name = 'IX_Merged_ForIntervals')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Merged_ForIntervals
        ON mis.Silver_Restruct_Merged_SCD (CreditID, ValidFrom)
        INCLUDE (ValidTo, StateName, TypeName, Reason, CreditStatus, TypeName_Sticky, ClientID);
END;
----------------------------------------------------------------------------------------------------
-- End of:   mis.Silver_Restruct_Merged_SCD.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Silver_Client_UnhealedFlag.sql
----------------------------------------------------------------------------------------------------
USE ATK;
GO

SET NOCOUNT ON;

IF OBJECT_ID('mis.Silver_Client_UnhealedFlag', 'U') IS NULL
BEGIN
    CREATE TABLE mis.Silver_Client_UnhealedFlag 
	(
        ClientID    VARCHAR(36) NOT NULL,
        SoldDate    DATE        NOT NULL,
        HasUnhealed BIT         NOT NULL,
        CONSTRAINT PK_Silver_Client_UnhealedFlag1 PRIMARY KEY (ClientID, SoldDate)
    );
END;

------------------------------------------------------------
-- 1) Prepare parameters
------------------------------------------------------------
DECLARE @DateFrom date = '2023-09-01';
DECLARE @DateTo   date = '2026-12-31';
DECLARE @Today    date = CAST(GETDATE() AS date);
IF (@DateTo > @Today) SET @DateTo = @Today;

------------------------------------------------------------
-- 2) Clean up existing data only in range
------------------------------------------------------------
DELETE FROM mis.Silver_Client_UnhealedFlag
WHERE SoldDate BETWEEN @DateFrom AND @DateTo;

------------------------------------------------------------
-- 3) Local table of dates
------------------------------------------------------------
IF OBJECT_ID('tempdb..#Dates','U') IS NOT NULL DROP TABLE #Dates;

;WITH N AS (
    SELECT TOP (DATEDIFF(day,@DateFrom,@DateTo)+1)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
SELECT DATEADD(day,n,@DateFrom) AS SoldDate
INTO #Dates
FROM N;

CREATE UNIQUE CLUSTERED INDEX CIX_Dates ON #Dates(SoldDate);

------------------------------------------------------------
-- 4) Insert only distinct client×day where conditions hold
------------------------------------------------------------
INSERT INTO mis.Silver_Client_UnhealedFlag 
           (ClientID, SoldDate, HasUnhealed)
SELECT m.ClientID, d.SoldDate, CAST(1 AS bit)
FROM #Dates d
JOIN (
    SELECT DISTINCT ClientID
    FROM mis.Silver_Restruct_Merged_SCD
    WHERE ClientID IS NOT NULL AND ClientID <> ''
) c ON 1=1
JOIN mis.Silver_Restruct_Merged_SCD m
  ON m.ClientID = c.ClientID
 AND d.SoldDate BETWEEN m.ValidFrom AND m.ValidTo
 AND m.TypeName_Sticky IS NOT NULL
 AND m.StateName = N'НеИзлеченный'
 AND LTRIM(RTRIM(m.CreditStatus)) IN (N'Выдан', N'Активен', N'Открыт')
GROUP BY m.ClientID, d.SoldDate;
----------------------------------------------------------------------------------------------------
-- End of:   mis.Silver_Client_UnhealedFlag.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Silver_Resp_SCD.sql
----------------------------------------------------------------------------------------------------
USE ATK;
GO

SET NOCOUNT ON;

------------------------------------------------------------
-- 0) Набор спец-филиалов (которые нужно ИСКЛЮЧИТЬ и протягивать поверх)
------------------------------------------------------------
DECLARE @SpecialBranches TABLE (BranchID VARCHAR(36) PRIMARY KEY);

INSERT INTO @SpecialBranches (BranchID)
VALUES
  ('B73A00155D65140C11EDCF8EFC5B26C5'),
  ('B8934CC39235AB0B41675ED45E7EE551'),
  ('B7D800155D65140C11F0316FD846B283'),
  ('80FE00155D65040111EB7DB987EF3B3A'),
  ('80FE00155D01451511EA2246DC87677D');

------------------------------------------------------------
-- 1) Пересоздаём таблицу назначения
------------------------------------------------------------
IF OBJECT_ID('mis.Silver_Resp_SCD', 'U') IS NOT NULL
    DROP TABLE mis.Silver_Resp_SCD;

CREATE TABLE mis.Silver_Resp_SCD 
(
    CreditID        VARCHAR(36) NOT NULL,
    ValidFrom       DATE        NOT NULL,
    ValidTo         DATE        NOT NULL,
    BranchID        VARCHAR(36) NULL,
    ExpertID        VARCHAR(36) NULL,
    IsSpecialBranch BIT         NOT NULL,
    FinalBranchID   VARCHAR(36) NULL,
    FinalExpertID   VARCHAR(36) NULL,
    CONSTRAINT PK_Resp_SCD PRIMARY KEY (CreditID, ValidFrom)
);

------------------------------------------------------------
-- 2) База по регистру: одна запись на дату (снимаем дубли)
------------------------------------------------------------
DECLARE @DateFrom DATE = '2023-09-01';

SELECT
    r.[ОтветственныеПоКредитамВыданным Кредит ID]            AS CreditID,
    CAST(r.[ОтветственныеПоКредитамВыданным Период] AS DATE) AS PeriodDate,
    r.[ОтветственныеПоКредитамВыданным Филиал ID]            AS BranchID,
    r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS ExpertID,
    ROW_NUMBER() OVER (
        PARTITION BY r.[ОтветственныеПоКредитамВыданным Кредит ID],
                     CAST(r.[ОтветственныеПоКредитамВыданным Период] AS DATE)
        ORDER BY r.[ОтветственныеПоКредитамВыданным Номер Строки] DESC,
                 r.[ОтветственныеПоКредитамВыданным ID] DESC
    ) AS rn
INTO #RespBaseRaw
FROM mis.[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным] r
WHERE r.[ОтветственныеПоКредитамВыданным Активность] = 1
  AND CAST(r.[ОтветственныеПоКредитамВыданным Период] AS DATE) >= @DateFrom;

SELECT CreditID, PeriodDate, BranchID, ExpertID
INTO #RespBase
FROM #RespBaseRaw
WHERE rn = 1;

DROP TABLE #RespBaseRaw;

------------------------------------------------------------
-- 3) Интервалы + протяжка
------------------------------------------------------------
;WITH stage AS (
    SELECT
        CreditID,
        PeriodDate AS ValidFrom,
        LEAD(PeriodDate) OVER (PARTITION BY CreditID ORDER BY PeriodDate) AS NextFrom,
        BranchID,
        ExpertID,
        CASE WHEN EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = BranchID)
             THEN 1 
			 ELSE 0 
	    END AS IsSpecialBranch,
        COALESCE(
		     SUM(CASE WHEN NOT EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = BranchID)
                 THEN 1 ELSE 0 
			     END
				 ) OVER (PARTITION BY CreditID ORDER BY PeriodDate ROWS UNBOUNDED PRECEDING), 0) AS grp
    FROM #RespBase
)
INSERT INTO mis.Silver_Resp_SCD 
(
    CreditID, ValidFrom, ValidTo,
    BranchID, ExpertID,
    IsSpecialBranch, FinalBranchID, FinalExpertID
)
SELECT
    s.CreditID,
    s.ValidFrom,
    COALESCE(DATEADD(DAY,-1,s.NextFrom), CONVERT(DATE,'9999-12-31')) AS ValidTo,
    s.BranchID,
    s.ExpertID,
    s.IsSpecialBranch,
COALESCE(
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = s.BranchID)
             AND s.BranchID IS NOT NULL
        THEN s.BranchID 
    END,
    MAX(ISNULL(
        CASE 
            WHEN NOT EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = s.BranchID)
            THEN s.BranchID 
        END, '')
    ) OVER (PARTITION BY s.CreditID, s.grp),
    s.BranchID
) AS FinalBranchID,

COALESCE(
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = s.BranchID)
             AND s.ExpertID IS NOT NULL
        THEN s.ExpertID 
    END,
    MAX(ISNULL(
        CASE 
            WHEN NOT EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = s.BranchID)
            THEN s.ExpertID 
        END, '')
    ) OVER (PARTITION BY s.CreditID, s.grp),
    s.ExpertID
) AS FinalExpertID
FROM stage s;

DROP TABLE #RespBase;
----------------------------------------------------------------------------------------------------
-- End of:   mis.Silver_Resp_SCD.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Silver_Stages_SCD.sql
----------------------------------------------------------------------------------------------------
USE ATK;
GO

SET NOCOUNT ON;

------------------------------------------------------------
-- 1) Ensure target table exists
------------------------------------------------------------
IF OBJECT_ID('mis.Silver_Stages_SCD','U') IS NULL
BEGIN
    CREATE TABLE mis.Silver_Stages_SCD 
	(
        CreditID   VARCHAR(36)   NOT NULL,
        ValidFrom  DATE          NOT NULL,
        ValidTo    DATE          NOT NULL,
        StageName  NVARCHAR(50)  NULL,
        CONSTRAINT PK_Silver_Stages_SCD PRIMARY KEY (CreditID, ValidFrom)
    );
END
ELSE
BEGIN
    TRUNCATE TABLE mis.Silver_Stages_SCD;
END;

------------------------------------------------------------
-- 2) Rebuild SCD
------------------------------------------------------------
;WITH src AS (
    SELECT
        CAST([СтадииКредитов Период] AS DATE) AS PeriodDate,
        [СтадииКредитов Кредит ID]           AS CreditID,
        [СтадииКредитов Стадия]              AS StageName,
        [СтадииКредитов ID]                  AS RowId
    FROM dbo.[РегистрыСведений.СтадииКредитов]
    WHERE [СтадииКредитов Кредит ID] IS NOT NULL
      AND [СтадииКредитов Период]    IS NOT NULL
),
dedup AS (
    SELECT
        CreditID, PeriodDate, StageName,
        ROW_NUMBER() OVER (PARTITION BY CreditID, PeriodDate ORDER BY RowId DESC) AS rn
    FROM src
),
day_rows AS (
    SELECT CreditID, PeriodDate, StageName
    FROM dedup
    WHERE rn = 1
),
borders AS (
    SELECT
        d.CreditID,
        d.PeriodDate AS ValidFrom,
        d.StageName,
        LAG(d.StageName) OVER (PARTITION BY d.CreditID ORDER BY d.PeriodDate) AS PrevStage
    FROM day_rows d
),
starts AS (
    SELECT CreditID, ValidFrom, StageName
    FROM borders
    WHERE ISNULL(PrevStage, N'#NULL#') <> ISNULL(StageName, N'#NULL#')
       OR PrevStage IS NULL
),
grid AS (
    SELECT
        CreditID,
        StageName,
        ValidFrom,
        LEAD(ValidFrom) OVER (PARTITION BY CreditID ORDER BY ValidFrom) AS NextFrom
    FROM starts
),
slices AS (
    SELECT
        CreditID,
        StageName,
        ValidFrom,
        COALESCE(DATEADD(day,-1,NextFrom), CONVERT(DATE,'9999-12-31')) AS ValidTo
    FROM grid
)
INSERT INTO mis.Silver_Stages_SCD 
           (CreditID, ValidFrom, ValidTo, StageName)
SELECT CreditID, ValidFrom, ValidTo, StageName
FROM slices;

------------------------------------------------------------
-- 3) Index under interval joins
------------------------------------------------------------
DECLARE @schema sysname = N'mis';
DECLARE @table  sysname = N'Silver_Stages_SCD';
DECLARE @stat   sysname = N'IX_Stages_ForIntervals';
DECLARE @obj_id int = OBJECT_ID(QUOTENAME(@schema)+N'.'+QUOTENAME(@table));

IF @obj_id IS NOT NULL
BEGIN
    IF EXISTS (SELECT 1 FROM sys.stats  WHERE object_id=@obj_id AND name=@stat)
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=@obj_id AND name=@stat)
    BEGIN
        DECLARE @sql NVARCHAR(4000)=
            N'DROP STATISTICS '+QUOTENAME(@schema)+N'.'+QUOTENAME(@table)+N'.'+QUOTENAME(@stat)+N';';
        EXEC (@sql);
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=@obj_id AND name=@stat)
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Stages_ForIntervals
            ON mis.Silver_Stages_SCD (CreditID, ValidFrom)
            INCLUDE (ValidTo, StageName);
    END;
END;
----------------------------------------------------------------------------------------------------
-- End of:   mis.Silver_Stages_SCD.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Silver_SCD_GroupMembershipPeriods.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO

IF OBJECT_ID('mis.[Silver_SCD_GroupMembershipPeriods]', 'U') IS NOT NULL
    DROP TABLE mis.[Silver_SCD_GroupMembershipPeriods];
GO

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
SELECT
      GroupID
    , PersonID
    , PersonName
    , GroupName
    , GroupOwner
    , PeriodOriginal AS PeriodStart
    , CASE 
        WHEN NextType = 'Excluded'
            THEN DATEADD(SECOND, -1, NextDate)
        ELSE CONVERT(DATETIME2, '2222-01-01 00:00:00')
      END AS PeriodEnd
FROM Ordered
WHERE EventType = 'Included'
  AND DeletionFlag = '00'
ORDER BY GroupID, PersonName, PeriodOriginal;
----------------------------------------------------------------------------------------------------
-- End of:   mis.Silver_SCD_GroupMembershipPeriods.sql
----------------------------------------------------------------------------------------------------

GO

