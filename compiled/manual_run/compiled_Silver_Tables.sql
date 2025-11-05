-- Compiled SQL bundle
-- Generated: 2025-11-05 11:18:47
-- Source folder: C:\ATK_Project\sql_scripts\Silver
-- Files (6):
--   mis.Silver_Restruct_SCD.sql
--   mis.Silver_RestructState_SCD.sql
--   mis.Silver_Restruct_Merged_SCD.sql
--   mis.Silver_Client_UnhealedFlag.sql
--   mis.Silver_Resp_SCD.sql
--   mis.Silver_Stages_SCD.sql
----------------------------------------------------------------------------------------------------

SET NOCOUNT ON;

----------------------------------------------------------------------------------------------------
-- Start of: mis.Silver_Restruct_SCD.sql
----------------------------------------------------------------------------------------------------
-- Создаём целевую SCD-таблицу (если ещё нет)
IF OBJECT_ID('[ATK].[mis].[Silver_Restruct_SCD]','U') IS NULL
CREATE TABLE [ATK].[mis].[Silver_Restruct_SCD] (
    CreditID        varchar(64)   NOT NULL,
    ValidFrom       date          NOT NULL,
    ValidTo         date          NOT NULL,   -- '9999-12-31' для открытого интервала
    TypeName        nvarchar(200) NULL,
    Reason          nvarchar(500) NULL,
    NonCommSeenUpTo bit           NOT NULL,
    CONSTRAINT PK_Silver_Restruct_SCD PRIMARY KEY (CreditID, ValidFrom)
);
ELSE
TRUNCATE TABLE [ATK].[mis].[Silver_Restruct_SCD];
GO

;WITH src AS (
    SELECT
        r.[РеструктурированныеКредиты Кредит ID] AS CreditID,
        CAST(r.[РеструктурированныеКредиты Период] AS date)       AS PeriodDate, -- считаем на лету
        r.[РеструктурированныеКредиты Тип Реструктуризации Долга] AS TypeName,
        r.[РеструктурированныеКредиты Причина Реструктуризации]   AS Reason,
        ROW_NUMBER() OVER (
            PARTITION BY
                r.[РеструктурированныеКредиты Кредит ID],
                CAST(r.[РеструктурированныеКредиты Период] AS date)
            ORDER BY r.[РеструктурированныеКредиты Период] DESC
        ) AS rn
    FROM [ATK].[mis].[Bronze_РегистрыСведений.РеструктурированныеКредиты] r
),
dedup AS (  -- по одному событию на день/кредит
    SELECT CreditID, PeriodDate, TypeName, Reason
    FROM src
    WHERE rn = 1
),
rng AS (    -- считаем интервалы
    SELECT
        CreditID,
        PeriodDate AS ValidFrom,
        LEAD(PeriodDate) OVER (PARTITION BY CreditID ORDER BY PeriodDate) AS NextFrom,
        TypeName,
        Reason,
        -- флаг: «Некоммерческая… встречалась когда-либо ДО/НА этот интервал»
        MAX(CASE WHEN TypeName = N'НекоммерческаяРеструктуризация' THEN 1 ELSE 0 END)
            OVER (PARTITION BY CreditID ORDER BY PeriodDate
                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS NonCommSeenUpTo
    FROM dedup
)
INSERT INTO [ATK].[mis].[Silver_Restruct_SCD]
    (CreditID, ValidFrom, ValidTo, TypeName, Reason, NonCommSeenUpTo)
SELECT
    CreditID,
    ValidFrom,
    COALESCE(DATEADD(day,-1, NextFrom), CONVERT(date,'9999-12-31')) AS ValidTo,
    TypeName,
    Reason,
    NonCommSeenUpTo
FROM rng;
GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.Silver_Restruct_SCD.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Silver_RestructState_SCD.sql
----------------------------------------------------------------------------------------------------
IF OBJECT_ID('[ATK].[mis].[Silver_RestructState_SCD]','U') IS NULL
CREATE TABLE [ATK].[mis].[Silver_RestructState_SCD] (
    CreditID   varchar(64)   NOT NULL,
    ValidFrom  date          NOT NULL,
    ValidTo    date          NOT NULL,
    StateName  nvarchar(200) NULL,
    CONSTRAINT PK_Silver_RestructState_SCD PRIMARY KEY (CreditID, ValidFrom)
);
ELSE
TRUNCATE TABLE [ATK].[mis].[Silver_RestructState_SCD];
GO

;WITH src AS (
    SELECT
        s.[СостоянияРеструктурированныхКредитов Кредит ID] AS CreditID,
        CAST(s.[СостоянияРеструктурированныхКредитов Период] AS date) AS PeriodDate,
        s.[СостоянияРеструктурированныхКредитов Состояние Реструктурированного Кредита] AS StateName,
        ROW_NUMBER() OVER (
            PARTITION BY
                s.[СостоянияРеструктурированныхКредитов Кредит ID],
                CAST(s.[СостоянияРеструктурированныхКредитов Период] AS date)
            ORDER BY s.[СостоянияРеструктурированныхКредитов Период] DESC
        ) AS rn
    FROM [ATK].[mis].[Bronze_РегистрыСведений.СостоянияРеструктурированныхКредитов] s
),
dedup AS (
    SELECT CreditID, PeriodDate, StateName
    FROM src WHERE rn = 1
),
rng AS (
    SELECT
        CreditID,
        PeriodDate AS ValidFrom,
        LEAD(PeriodDate) OVER (PARTITION BY CreditID ORDER BY PeriodDate) AS NextFrom,
        StateName
    FROM dedup
)
INSERT INTO [ATK].[mis].[Silver_RestructState_SCD]
    (CreditID, ValidFrom, ValidTo, StateName)
SELECT
    CreditID,
    ValidFrom,
    COALESCE(DATEADD(day,-1, NextFrom), CONVERT(date,'9999-12-31')) AS ValidTo,
    StateName
FROM rng;
GO
----------------------------------------------------------------------------------------------------
-- End of:   mis.Silver_RestructState_SCD.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Silver_Restruct_Merged_SCD.sql
----------------------------------------------------------------------------------------------------
/* ===== Создание / приведение схемы ===== */
IF OBJECT_ID('[ATK].[mis].[Silver_Restruct_Merged_SCD]','U') IS NULL
BEGIN
    CREATE TABLE [ATK].[mis].[Silver_Restruct_Merged_SCD] (
        CreditID        varchar(64)   NOT NULL,
        ValidFrom       date          NOT NULL,
        ValidTo         date          NOT NULL,
        TypeName        nvarchar(200) NULL,
        Reason          nvarchar(500) NULL,
        StateName       nvarchar(200) NULL,
        TypeName_Sticky nvarchar(200) NULL,   -- «Некоммерческая…» прилипает вперёд
        CreditStatus    nvarchar(200) NULL,   -- <<< НОВОЕ: статус кредита (Активен/Закрыт и т.п.)
        ClientID        varchar(64)   NULL,   -- владелец кредита
        CONSTRAINT PK_Silver_Restruct_Merged_SCD PRIMARY KEY (CreditID, ValidFrom)
    );
END
ELSE
BEGIN
    /* Добавим недостающие колонки, если их нет */
    IF COL_LENGTH('ATK.mis.Silver_Restruct_Merged_SCD', 'ClientID') IS NULL
        ALTER TABLE [ATK].[mis].[Silver_Restruct_Merged_SCD] ADD ClientID varchar(64) NULL;

    IF COL_LENGTH('ATK.mis.Silver_Restruct_Merged_SCD', 'CreditStatus') IS NULL
        ALTER TABLE [ATK].[mis].[Silver_Restruct_Merged_SCD] ADD CreditStatus nvarchar(200) NULL;

    TRUNCATE TABLE [ATK].[mis].[Silver_Restruct_Merged_SCD];
END;
GO

/* ===== Построение объединённой SCD с учётом статуса кредита ===== */
;WITH borders AS (
    /* точки изменения типа/причины реструктуризации */
    SELECT CreditID, CAST(ValidFrom AS date) AS ValidFrom
    FROM   [ATK].[mis].[Silver_Restruct_SCD]
    UNION
    /* точки изменения состояния реструктуризации */
    SELECT CreditID, CAST(ValidFrom AS date) AS ValidFrom
    FROM   [ATK].[mis].[Silver_RestructState_SCD]
    UNION
    /* точки изменения статуса кредита (берём только активные записи регистра) */
    SELECT
        s.[СтатусыКредитовВыданных Кредит ID] AS CreditID,
        CAST(s.[СтатусыКредитовВыданных Период] AS date) AS ValidFrom
    FROM [ATK].[mis].[Bronze_РегистрыСведений.СтатусыКредитовВыданных] s
    WHERE s.[СтатусыКредитовВыданных Активность] = 1
),
grid AS (
    SELECT
        CreditID,
        ValidFrom,
        LEAD(ValidFrom) OVER (PARTITION BY CreditID ORDER BY ValidFrom) AS NextFrom
    FROM borders
),
slices AS (
    SELECT
        CreditID,
        ValidFrom,
        COALESCE(DATEADD(day,-1, NextFrom), CONVERT(date,'9999-12-31')) AS ValidTo
    FROM grid
),
/* На начало каждого среза подтягиваем: Type/Reason, State и CreditStatus */
joined AS (
    SELECT
        z.CreditID,
        z.ValidFrom,
        z.ValidTo,
        r.TypeName,
        r.Reason,
        r.NonCommSeenUpTo,
        s.StateName,
        cs.[СтатусыКредитовВыданных Статус] AS CreditStatus,  -- активный статус на дату среза
        /* локальный флаг для липкости */
        COALESCE(r.NonCommSeenUpTo, 0) AS SeenNcHere
    FROM slices z
    OUTER APPLY (
        SELECT TOP (1) rr.TypeName, rr.Reason, rr.NonCommSeenUpTo
        FROM [ATK].[mis].[Silver_Restruct_SCD] rr
        WHERE rr.CreditID = z.CreditID
          AND rr.ValidFrom <= z.ValidFrom
          AND rr.ValidTo   >= z.ValidFrom
        ORDER BY rr.ValidFrom DESC
    ) r
    OUTER APPLY (
        SELECT TOP (1) ss.StateName
        FROM [ATK].[mis].[Silver_RestructState_SCD] ss
        WHERE ss.CreditID = z.CreditID
          AND ss.ValidFrom <= z.ValidFrom
          AND ss.ValidTo   >= z.ValidFrom
        ORDER BY ss.ValidFrom DESC
    ) s
    OUTER APPLY (
        /* активный статус на начало среза */
        SELECT TOP (1) s2.[СтатусыКредитовВыданных Статус]
        FROM [ATK].[mis].[Bronze_РегистрыСведений.СтатусыКредитовВыданных] s2
        WHERE s2.[СтатусыКредитовВыданных Кредит ID] = z.CreditID
          AND s2.[СтатусыКредитовВыданных Активность] = 1
          AND CAST(s2.[СтатусыКредитовВыданных Период] AS date) <= z.ValidFrom
        ORDER BY s2.[СтатусыКредитовВыданных Период] DESC
    ) cs
),
stick AS (
    SELECT
        j.*,
        /* «липкость» некоммерческой реструктуризации */
        MAX(j.SeenNcHere) OVER (
            PARTITION BY j.CreditID
            ORDER BY j.ValidFrom
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS SeenNcCumulative
    FROM joined j
)
INSERT INTO [ATK].[mis].[Silver_Restruct_Merged_SCD]
    (CreditID, ValidFrom, ValidTo, TypeName, Reason, StateName, TypeName_Sticky, CreditStatus, ClientID)
SELECT
    st.CreditID,
    st.ValidFrom,
    st.ValidTo,
    st.TypeName,
    st.Reason,
    st.StateName,
    CASE WHEN st.SeenNcCumulative = 1
         THEN N'НекоммерческаяРеструктуризация'
         ELSE st.TypeName
    END AS TypeName_Sticky,
    st.CreditStatus,  -- добавили статус кредита на периоде
    cr.[Кредиты Владелец] AS ClientID
FROM stick st
LEFT JOIN [ATK].[mis].[Bronze_Справочники.Кредиты] cr
       ON cr.[Кредиты ID] = st.CreditID;
GO

/* (необязательно) Индексы для ускорения дальнейших расчётов */
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE object_id = OBJECT_ID('[ATK].[mis].[Silver_Restruct_Merged_SCD]')
                 AND name = 'IX_Merged_ForIntervals')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Merged_ForIntervals
        ON [ATK].[mis].[Silver_Restruct_Merged_SCD] (CreditID, ValidFrom)
        INCLUDE (ValidTo, StateName, TypeName, Reason, CreditStatus, TypeName_Sticky, ClientID);
END;
----------------------------------------------------------------------------------------------------
-- End of:   mis.Silver_Restruct_Merged_SCD.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Silver_Client_UnhealedFlag.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
GO
SET NOCOUNT ON;

------------------------------------------------------------
-- 0) Ensure target table exists
------------------------------------------------------------
IF OBJECT_ID('[ATK].[mis].[Silver_Client_UnhealedFlag]', 'U') IS NULL
BEGIN
    CREATE TABLE [ATK].[mis].[Silver_Client_UnhealedFlag] (
        ClientID    VARCHAR(64) NOT NULL,
        SoldDate    DATE        NOT NULL,
        HasUnhealed BIT         NOT NULL,
        CONSTRAINT PK_Silver_Client_UnhealedFlag1 PRIMARY KEY (ClientID, SoldDate)
    );
END
GO

------------------------------------------------------------
-- 1) Prepare parameters
------------------------------------------------------------
DECLARE @DateFrom date = '2024-01-01';
DECLARE @DateTo   date = '2025-12-31';
DECLARE @Today    date = CAST(GETDATE() AS date);
IF (@DateTo > @Today) SET @DateTo = @Today;

------------------------------------------------------------
-- 2) Clean up existing data only in range
------------------------------------------------------------
DELETE FROM [ATK].[mis].[Silver_Client_UnhealedFlag]
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
INSERT INTO [ATK].[mis].[Silver_Client_UnhealedFlag] (ClientID, SoldDate, HasUnhealed)
SELECT m.ClientID, d.SoldDate, CAST(1 AS bit)
FROM #Dates d
JOIN (
    SELECT DISTINCT ClientID
    FROM [ATK].[mis].[Silver_Restruct_Merged_SCD]
    WHERE ClientID IS NOT NULL AND ClientID <> ''
) c ON 1=1
JOIN [ATK].[mis].[Silver_Restruct_Merged_SCD] m
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
USE [ATK];
SET NOCOUNT ON;

PRINT N'=== Пересборка [mis].[Silver_Resp_SCD] с протяжкой НЕ-спец значений (множественные спец-филиалы) ===';

DECLARE @DateFrom date = '2010-01-01';

------------------------------------------------------------
-- 0) Набор спец-филиалов (которые нужно ИСКЛЮЧИТЬ и протягивать поверх)
------------------------------------------------------------
DECLARE @SpecialBranches TABLE (BranchID varchar(64) PRIMARY KEY);

INSERT INTO @SpecialBranches (BranchID)
VALUES
  ('B73A00155D65140C11EDCF8EFC5B26C5'), -- существующий
  ('B8934CC39235AB0B41675ED45E7EE551'),
  ('B7D800155D65140C11F0316FD846B283'),
  ('80FE00155D65040111EB7DB987EF3B3A'),
  ('80FE00155D01451511EA2246DC87677D');

------------------------------------------------------------
-- 1) Пересоздаём таблицу назначения
------------------------------------------------------------
IF OBJECT_ID('[mis].[Silver_Resp_SCD]', 'U') IS NOT NULL
    DROP TABLE [mis].[Silver_Resp_SCD];

CREATE TABLE [mis].[Silver_Resp_SCD] (
    CreditID        varchar(64) NOT NULL,
    ValidFrom       date        NOT NULL,
    ValidTo         date        NOT NULL,
    BranchID        varchar(64) NULL,
    ExpertID        varchar(64) NULL,
    IsSpecialBranch bit         NOT NULL,
    FinalBranchID   varchar(64) NULL,
    FinalExpertID   varchar(64) NULL,
    CONSTRAINT PK_Resp_SCD PRIMARY KEY (CreditID, ValidFrom)
);

------------------------------------------------------------
-- 2) База по регистру: одна запись на дату (снимаем дубли)
------------------------------------------------------------
SELECT
    r.[ОтветственныеПоКредитамВыданным Кредит ID]            AS CreditID,
    CAST(r.[ОтветственныеПоКредитамВыданным Период] AS date) AS PeriodDate,
    r.[ОтветственныеПоКредитамВыданным Филиал ID]            AS BranchID,
    r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS ExpertID,
    ROW_NUMBER() OVER (
        PARTITION BY r.[ОтветственныеПоКредитамВыданным Кредит ID],
                     CAST(r.[ОтветственныеПоКредитамВыданным Период] AS date)
        ORDER BY r.[ОтветственныеПоКредитамВыданным Номер Строки] DESC,
                 r.[ОтветственныеПоКредитамВыданным ID] DESC
    ) AS rn
INTO #RespBaseRaw
FROM [ATK].[mis].[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным] r
WHERE r.[ОтветственныеПоКредитамВыданным Активность] = 1
  AND CAST(r.[ОтветственныеПоКредитамВыданным Период] AS date) >= @DateFrom;

SELECT CreditID, PeriodDate, BranchID, ExpertID
INTO #RespBase
FROM #RespBaseRaw
WHERE rn = 1;

DROP TABLE #RespBaseRaw;

------------------------------------------------------------
-- 3) Интервалы + протяжка:
--    спец-филиалы = те, что входят в @SpecialBranches
------------------------------------------------------------
;WITH stage AS (
    SELECT
        CreditID,
        PeriodDate AS ValidFrom,
        LEAD(PeriodDate) OVER (PARTITION BY CreditID ORDER BY PeriodDate) AS NextFrom,
        BranchID,
        ExpertID,
        CASE WHEN EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = BranchID)
             THEN 1 ELSE 0 END AS IsSpecialBranch,
        -- Номер группы НЕ-спец записей (для каскадной протяжки)
        SUM(CASE WHEN NOT EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = BranchID)
                 THEN 1 ELSE 0 END)
            OVER (PARTITION BY CreditID ORDER BY PeriodDate ROWS UNBOUNDED PRECEDING) AS grp
    FROM #RespBase
)
INSERT INTO [mis].[Silver_Resp_SCD] (
    CreditID, ValidFrom, ValidTo,
    BranchID, ExpertID,
    IsSpecialBranch, FinalBranchID, FinalExpertID
)
SELECT
    s.CreditID,
    s.ValidFrom,
    COALESCE(DATEADD(DAY,-1,s.NextFrom), CONVERT(date,'9999-12-31')) AS ValidTo,
    s.BranchID,
    s.ExpertID,
    s.IsSpecialBranch,
    -- FinalBranchID: текущее НЕ-спец -> оно; иначе последний НЕ-спец в grp; если NULL — исходный BranchID
    COALESCE(
        CASE WHEN NOT EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = s.BranchID)
                  AND s.BranchID IS NOT NULL
             THEN s.BranchID END,
        MAX(CASE WHEN NOT EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = s.BranchID)
                 THEN s.BranchID END)
            OVER (PARTITION BY s.CreditID, s.grp),
        s.BranchID
    ) AS FinalBranchID,
    -- FinalExpertID: по той же логике
    COALESCE(
        CASE WHEN NOT EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = s.BranchID)
                  AND s.ExpertID IS NOT NULL
             THEN s.ExpertID END,
        MAX(CASE WHEN NOT EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = s.BranchID)
                 THEN s.ExpertID END)
            OVER (PARTITION BY s.CreditID, s.grp),
        s.ExpertID
    ) AS FinalExpertID
FROM stage s;

DROP TABLE #RespBase;

------------------------------------------------------------
-- 4) Итог
------------------------------------------------------------
DECLARE @cnt bigint;
SELECT @cnt = COUNT_BIG(*) FROM [mis].[Silver_Resp_SCD];
PRINT N'✅ Готово: [mis].[Silver_Resp_SCD] пересобрана. Строк: ' + CONVERT(varchar(30), @cnt);

-- (опционально) индексы под выборки на дату/кредит:
-- CREATE INDEX IX_Resp_SCD_Credit_FromTo ON [mis].[Silver_Resp_SCD](CreditID, ValidFrom, ValidTo)
--     INCLUDE (BranchID, ExpertID, FinalBranchID, FinalExpertID, IsSpecialBranch);
-- CREATE INDEX IX_Resp_SCD_FromTo ON [mis].[Silver_Resp_SCD](ValidFrom, ValidTo);
----------------------------------------------------------------------------------------------------
-- End of:   mis.Silver_Resp_SCD.sql
----------------------------------------------------------------------------------------------------

GO

----------------------------------------------------------------------------------------------------
-- Start of: mis.Silver_Stages_SCD.sql
----------------------------------------------------------------------------------------------------
USE [ATK];
SET NOCOUNT ON;

/* 1) Таблица */
IF OBJECT_ID('[ATK].[mis].[Silver_Stages_SCD]','U') IS NULL
BEGIN
    CREATE TABLE [ATK].[mis].[Silver_Stages_SCD] (
        CreditID   varchar(64)   NOT NULL,
        ValidFrom  date          NOT NULL,
        ValidTo    date          NOT NULL,
        StageName  nvarchar(200) NULL,
        CONSTRAINT PK_Silver_Stages_SCD PRIMARY KEY (CreditID, ValidFrom)
    );
END
ELSE
    TRUNCATE TABLE [ATK].[mis].[Silver_Stages_SCD];

/* 2) Пересборка без агрегатов, с сохранением NULL */
;WITH src AS (
    SELECT
        CAST([СтадииКредитов Период] AS date) AS PeriodDate,
        [СтадииКредитов Кредит ID]           AS CreditID,
        [СтадииКредитов Стадия]              AS StageName,
        [СтадииКредитов ID]                  AS RowId
    FROM [ATK].[dbo].[РегистрыСведений.СтадииКредитов]
    WHERE [СтадииКредитов Кредит ID] IS NOT NULL
      AND [СтадииКредитов Период]    IS NOT NULL
),
-- Дедуп внутри дня: берём «последнюю» запись по дате (при множественных — по ID)
dedup AS (
    SELECT
        CreditID, PeriodDate, StageName,
        ROW_NUMBER() OVER (
            PARTITION BY CreditID, PeriodDate
            ORDER BY RowId DESC
        ) AS rn
    FROM src
),
-- Оставляем по одной записи на день
day_rows AS (
    SELECT CreditID, PeriodDate, StageName
    FROM dedup
    WHERE rn = 1
),
-- Границы изменений: учитываем NULL как отдельное значение
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
    WHERE ISNULL(PrevStage,   N'#NULL#') <>
          ISNULL(StageName,   N'#NULL#')
       OR PrevStage IS NULL -- первая запись по кредиту
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
        COALESCE(DATEADD(day,-1,NextFrom), CONVERT(date,'9999-12-31')) AS ValidTo
    FROM grid
)
INSERT INTO [ATK].[mis].[Silver_Stages_SCD] (CreditID, ValidFrom, ValidTo, StageName)
SELECT CreditID, ValidFrom, ValidTo, StageName
FROM slices
ORDER BY CreditID, ValidFrom;

/* 3) Индекс под интервальные джоины (с защитой от конфликта со статистикой) */
DECLARE @schema sysname = N'mis';
DECLARE @table  sysname = N'Silver_Stages_SCD';
DECLARE @stat   sysname = N'IX_Stages_ForIntervals';
DECLARE @obj_id int     = OBJECT_ID(QUOTENAME(@schema)+N'.'+QUOTENAME(@table));

IF @obj_id IS NOT NULL
BEGIN
    IF EXISTS (SELECT 1 FROM sys.stats  WHERE object_id=@obj_id AND name=@stat)
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=@obj_id AND name=@stat)
    BEGIN
        DECLARE @sql nvarchar(4000)=
            N'DROP STATISTICS '+QUOTENAME(@schema)+N'.'+QUOTENAME(@table)+N'.'+QUOTENAME(@stat)+N';';
        EXEC (@sql);
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=@obj_id AND name=@stat)
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Stages_ForIntervals
            ON [mis].[Silver_Stages_SCD] (CreditID, ValidFrom)
            INCLUDE (ValidTo, StageName);
    END;
END;
----------------------------------------------------------------------------------------------------
-- End of:   mis.Silver_Stages_SCD.sql
----------------------------------------------------------------------------------------------------

GO

