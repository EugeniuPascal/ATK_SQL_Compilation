USE [ATK];
SET NOCOUNT ON;

/* ================== ПАРАМЕТРЫ ================== */
DECLARE @DateFrom date = '2024-01-01';
DECLARE @DateTo   date = '2025-12-31';

PRINT N'=== Пересборка [mis].[Gold_Par_Restruct_Daily_Min1] за период '
      + CONVERT(varchar(10), @DateFrom, 23) + N' — ' + CONVERT(varchar(10), @DateTo, 23) + N' ===';

/* ========== Очистка temp-таблиц (повторный запуск) ========== */
IF OBJECT_ID('tempdb..#Base')         IS NOT NULL DROP TABLE #Base;
IF OBJECT_ID('tempdb..#MaxDays')      IS NOT NULL DROP TABLE #MaxDays;
IF OBJECT_ID('tempdb..#Flag')         IS NOT NULL DROP TABLE #Flag;
IF OBJECT_ID('tempdb..#RespEarliest') IS NOT NULL DROP TABLE #RespEarliest;
IF OBJECT_ID('tempdb..#Joined_raw')   IS NOT NULL DROP TABLE #Joined_raw;
IF OBJECT_ID('tempdb..#Joined')       IS NOT NULL DROP TABLE #Joined;

/* ================== ЦЕЛЕВАЯ ТАБЛИЦА ================== */
IF OBJECT_ID('[mis].[Gold_Par_Restruct_Daily_Min1]', 'U') IS NOT NULL
BEGIN
    DROP TABLE [mis].[Gold_Par_Restruct_Daily_Min1];
    PRINT N'Старая таблица удалена.';
END;

CREATE TABLE [mis].[Gold_Par_Restruct_Daily_Min1] (
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
    CONSTRAINT PK_Gold_ParRestructDailyMin
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

-- Индексы под будущие join/агрегации
CREATE CLUSTERED INDEX CIX_Base_ClientDateCredit
ON #Base (ClientID, SoldDate, CreditID);

CREATE NONCLUSTERED INDEX IX_Base_CreditDate
ON #Base (CreditID, SoldDate)
INCLUDE (Balance_Total, DaysBucket_Credit, DaysFact_Total, DaysIFRS,
         StateName_Final, TypeName_Sticky_Final, CreditStatus_Base);

PRINT N'✅ Шаг 1: строк ' + CONVERT(varchar(30), @@ROWCOUNT);

/* ===== ШАГ 1.1. MaxDaysPerClientDay (быстро, без оконной) ===== */
SELECT
    b.ClientID,
    b.SoldDate,
    MAX(b.DaysFact_Total) AS MaxDaysPerClientDay
INTO #MaxDays
FROM #Base b
GROUP BY b.ClientID, b.SoldDate;

CREATE UNIQUE CLUSTERED INDEX CIX_MaxDays ON #MaxDays (ClientID, SoldDate);

/* ================== ШАГ 1.2. Флаги ================== */
SELECT f.ClientID, f.SoldDate
INTO #Flag
FROM [ATK].[mis].[Silver_Client_UnhealedFlag] f
WHERE f.HasUnhealed = 1
  AND f.SoldDate >= @DateFrom
  AND f.SoldDate <= @DateTo;

CREATE UNIQUE CLUSTERED INDEX CIX_Flag ON #Flag (ClientID, SoldDate);

/* ======= ШАГ 2. Самая ранняя запись ответственных (fallback) ======= */
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
  ON m.CreditID = r.CreditID
 AND m.MinValidFrom = r.ValidFrom;

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

    COALESCE(r_curr.FinalBranchID,  e.FinalBranchID)    AS LastBranchID,
    COALESCE(r_curr.FinalExpertID,  e.FinalExpertID)    AS LastExpertID,
    COALESCE(r_curr.IsSpecialBranch, e.IsSpecialBranch) AS IsSpecialBranch
INTO #Joined_raw
FROM #Base b
OUTER APPLY (
    SELECT TOP (1) r.*
    FROM [ATK].[mis].[Silver_Resp_SCD] r
    WHERE r.CreditID = b.CreditID
      AND b.SoldDate >= r.ValidFrom
      AND b.SoldDate <= r.ValidTo
    ORDER BY r.ValidFrom DESC
) r_curr
LEFT JOIN #RespEarliest e
       ON e.CreditID = b.CreditID
OPTION (RECOMPILE);

-- Индексы под дальнейшие шаги
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
    END AS ParIFRS
INTO #Joined
FROM #Joined_raw jr
JOIN #MaxDays md
  ON md.ClientID = jr.ClientID
 AND md.SoldDate = jr.SoldDate;

CREATE CLUSTERED INDEX CIX_Joined_ClientDate
ON #Joined (ClientID, SoldDate, CreditID);

/* ================ ШАГ 5. Вставка результата ================= */
PRINT N'Шаг 3 — вставка результата...';

INSERT /*+ TABLOCK */ INTO [mis].[Gold_Par_Restruct_Daily_Min1] WITH (TABLOCK)
(
    SoldDate, CreditID, ClientID,
    Balance_Total, DaysBucket_Credit, DaysFact_Total, DaysIFRS,
    StateName_Final, TypeName_Sticky_Final, CreditStatus_Base,
    LastBranchID, LastExpertID, IsSpecialBranch, SegmentIFRS, ParIFRS
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

    j.ParIFRS
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
SELECT @cnt = COUNT_BIG(*) FROM [mis].[Gold_Par_Restruct_Daily_Min1];
PRINT N'🏁 Готово. Строк: ' + CONVERT(varchar(30), @cnt);

/*===== РЕКОМЕНДУЕМЫЕ ИНДЕКСЫ (если есть права) =====*/
--1) На источник ответственных:
CREATE INDEX IX_RespSCD_Credit_FromTo
ON [ATK].[mis].[Silver_Resp_SCD](CreditID, ValidFrom, ValidTo)
INCLUDE (FinalBranchID, FinalExpertID, IsSpecialBranch);

/*-- 2) На итоговую под типовые запросы:*/
CREATE INDEX IX_ParMin_SoldDate   ON [mis].[Gold_Par_Restruct_Daily_Min1](SoldDate);
CREATE INDEX IX_ParMin_ClientDate ON [mis].[Gold_Par_Restruct_Daily_Min1](ClientID, SoldDate)
INCLUDE (ParIFRS, SegmentIFRS, Balance_Total, CreditID);

USE [ATK];
SET NOCOUNT ON;

/* ================== ПАРАМЕТРЫ ================== */
DECLARE @DateFrom date = '2024-01-01';
DECLARE @DateTo   date = '2025-12-31';

PRINT N'=== Пересборка [mis].[Gold_Par_Restruct_Daily_Min1] за период '
      + CONVERT(varchar(10), @DateFrom, 23) + N' — ' + CONVERT(varchar(10), @DateTo, 23) + N' ===';

/* ========== Очистка temp-таблиц (повторный запуск) ========== */
IF OBJECT_ID('tempdb..#Base')         IS NOT NULL DROP TABLE #Base;
IF OBJECT_ID('tempdb..#MaxDays')      IS NOT NULL DROP TABLE #MaxDays;
IF OBJECT_ID('tempdb..#Flag')         IS NOT NULL DROP TABLE #Flag;
IF OBJECT_ID('tempdb..#RespEarliest') IS NOT NULL DROP TABLE #RespEarliest;
IF OBJECT_ID('tempdb..#Joined_raw')   IS NOT NULL DROP TABLE #Joined_raw;
IF OBJECT_ID('tempdb..#Joined')       IS NOT NULL DROP TABLE #Joined;

/* ================== ЦЕЛЕВАЯ ТАБЛИЦА ================== */
IF OBJECT_ID('[mis].[Gold_Par_Restruct_Daily_Min1]', 'U') IS NOT NULL
BEGIN
    DROP TABLE [mis].[Gold_Par_Restruct_Daily_Min1];
    PRINT N'Старая таблица удалена.';
END;

CREATE TABLE [mis].[Gold_Par_Restruct_Daily_Min1] (
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
    CONSTRAINT PK_Gold_ParRestructDailyMinV2
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

-- Индексы под будущие join/агрегации
CREATE CLUSTERED INDEX CIX_Base_ClientDateCredit
ON #Base (ClientID, SoldDate, CreditID);

CREATE NONCLUSTERED INDEX IX_Base_CreditDate
ON #Base (CreditID, SoldDate)
INCLUDE (Balance_Total, DaysBucket_Credit, DaysFact_Total, DaysIFRS,
         StateName_Final, TypeName_Sticky_Final, CreditStatus_Base);

PRINT N'✅ Шаг 1: строк ' + CONVERT(varchar(30), @@ROWCOUNT);

/* ===== ШАГ 1.1. MaxDaysPerClientDay (быстро, без оконной) ===== */
SELECT
    b.ClientID,
    b.SoldDate,
    MAX(b.DaysFact_Total) AS MaxDaysPerClientDay
INTO #MaxDays
FROM #Base b
GROUP BY b.ClientID, b.SoldDate;

CREATE UNIQUE CLUSTERED INDEX CIX_MaxDays ON #MaxDays (ClientID, SoldDate);

/* ================== ШАГ 1.2. Флаги ================== */
SELECT f.ClientID, f.SoldDate
INTO #Flag
FROM [ATK].[mis].[Silver_Client_UnhealedFlag] f
WHERE f.HasUnhealed = 1
  AND f.SoldDate >= @DateFrom
  AND f.SoldDate <= @DateTo;

CREATE UNIQUE CLUSTERED INDEX CIX_Flag ON #Flag (ClientID, SoldDate);

/* ======= ШАГ 2. Самая ранняя запись ответственных (fallback) ======= */
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
  ON m.CreditID = r.CreditID
 AND m.MinValidFrom = r.ValidFrom;

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

    COALESCE(r_curr.FinalBranchID,  e.FinalBranchID)    AS LastBranchID,
    COALESCE(r_curr.FinalExpertID,  e.FinalExpertID)    AS LastExpertID,
    COALESCE(r_curr.IsSpecialBranch, e.IsSpecialBranch) AS IsSpecialBranch
INTO #Joined_raw
FROM #Base b
OUTER APPLY (
    SELECT TOP (1) r.*
    FROM [ATK].[mis].[Silver_Resp_SCD] r
    WHERE r.CreditID = b.CreditID
      AND b.SoldDate >= r.ValidFrom
      AND b.SoldDate <= r.ValidTo
    ORDER BY r.ValidFrom DESC
) r_curr
LEFT JOIN #RespEarliest e
       ON e.CreditID = b.CreditID
OPTION (RECOMPILE);

-- Индексы под дальнейшие шаги
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
    END AS ParIFRS
INTO #Joined
FROM #Joined_raw jr
JOIN #MaxDays md
  ON md.ClientID = jr.ClientID
 AND md.SoldDate = jr.SoldDate;

CREATE CLUSTERED INDEX CIX_Joined_ClientDate
ON #Joined (ClientID, SoldDate, CreditID);

/* ================ ШАГ 5. Вставка результата ================= */
PRINT N'Шаг 3 — вставка результата...';

INSERT /*+ TABLOCK */ INTO [mis].[Gold_Par_Restruct_Daily_Min1] WITH (TABLOCK)
(
    SoldDate, CreditID, ClientID,
    Balance_Total, DaysBucket_Credit, DaysFact_Total, DaysIFRS,
    StateName_Final, TypeName_Sticky_Final, CreditStatus_Base,
    LastBranchID, LastExpertID, IsSpecialBranch, SegmentIFRS, ParIFRS
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

    j.ParIFRS
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
SELECT @cnt = COUNT_BIG(*) FROM [mis].[Gold_Par_Restruct_Daily_Min1];
PRINT N'🏁 Готово. Строк: ' + CONVERT(varchar(30), @cnt);

/*===== РЕКОМЕНДУЕМЫЕ ИНДЕКСЫ (если есть права) =====*/
--1) На источник ответственных:
CREATE INDEX IX_RespSCD_Credit_FromTo
ON [ATK].[mis].[Silver_Resp_SCD](CreditID, ValidFrom, ValidTo)
INCLUDE (FinalBranchID, FinalExpertID, IsSpecialBranch);

/*-- 2) На итоговую под типовые запросы:*/
CREATE INDEX IX_ParMin_SoldDate   ON [mis].[Gold_Par_Restruct_Daily_Min1](SoldDate);
CREATE INDEX IX_ParMin_ClientDate ON [mis].[Gold_Par_Restruct_Daily_Min1](ClientID, SoldDate)
INCLUDE (ParIFRS, SegmentIFRS, Balance_Total, CreditID);

