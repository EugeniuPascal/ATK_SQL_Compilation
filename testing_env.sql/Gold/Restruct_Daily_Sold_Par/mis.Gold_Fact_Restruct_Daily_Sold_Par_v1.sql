
USE [ATK];
SET NOCOUNT ON;

/* ================== ПАРАМЕТРЫ ================== */
DECLARE @DateFrom date = '2023-09-01';
DECLARE @DateTo   date = '2026-12-31';

PRINT N'=== Пересборка [mis].[Gold_Fact_Restruct_Daily_Sold_Par] за период '
      + CONVERT(varchar(10), @DateFrom, 23) + N' — ' + CONVERT(varchar(10), @DateTo, 23) + N' ===';

BEGIN TRAN;

/* ========== Очистка temp-таблиц ========== */
DROP TABLE IF EXISTS #Base, #MaxDays, #Flag, #RespEarliest, #Joined_raw, #Joined, #IRR;

/* ================== ЦЕЛЕВАЯ ТАБЛИЦА ================== */
IF OBJECT_ID('[mis].[Gold_Fact_Restruct_Daily_Sold_Par]', 'U') IS NOT NULL
    DROP TABLE [mis].[Gold_Fact_Restruct_Daily_Sold_Par];

CREATE TABLE [mis].[Gold_Fact_Restruct_Daily_Sold_Par] 
(
    SoldDate               date          NOT NULL,
    CreditID               varchar(36)   NOT NULL,
    ClientID               varchar(36)   NOT NULL,
    Balance_Total          money         NULL,
    IRR_Values             DECIMAL(18,6) NULL,
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
    
        PRIMARY KEY (ClientID, CreditID, SoldDate)
);

---------------------------------------------------------
-- IRR TEMP TABLE (DATE EFFECTIVE)
---------------------------------------------------------
SELECT
    [УстановкаДанныхКредита Кредит ID] AS CreditID,
    [УстановкаДанныхКредита Внутренняя Норма Доходности Годовая] AS IRR_Year,
    [УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая] AS IRR_Client,
    CAST([УстановкаДанныхКредита Дата] AS DATE) AS IRRDate
INTO #IRR
FROM mis.[Bronze_Документы.УстановкаДанныхКредита]
WHERE [УстановкаДанныхКредита Кредит ID] IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_IRR_Credit_Date
ON #IRR (CreditID, IRRDate DESC);

---------------------------------------------------------
-- STEP 1. BASE (DEDUP + IRR RATE)
---------------------------------------------------------
PRINT N'Шаг 1 — подготовка базы...';

;WITH cte AS (
    SELECT
        CAST(s.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS DATE) AS SoldDate,
        s.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
        s.[СуммыЗадолженностиПоПериодамПросрочки Клиент ID] AS ClientID,
        s.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] AS Balance_Total,
        s.[СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки Кредит] AS DaysBucket_Credit,
        s.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого] AS DaysFact_Total,
        s.[СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки МСФО] AS DaysIFRS,

        -- IRR RATE (date-effective)
        irr.IRR_Value,

        r.StateName            AS StateName_Final,
        r.TypeName_Sticky      AS TypeName_Sticky_Final,
        r.CreditStatus         AS CreditStatus_Base,

        ROW_NUMBER() OVER (
            PARTITION BY
                s.[СуммыЗадолженностиПоПериодамПросрочки Клиент ID],
                s.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID],
                CAST(s.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS DATE)
            ORDER BY
                s.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] DESC,
                s.[СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки Кредит] DESC
        ) AS rn
    FROM [ATK].[mis].[Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] s
	    OUTER APPLY (
        SELECT TOP (1)
            CASE
                WHEN i.IRR_Year < 100 THEN i.IRR_Year
                ELSE i.IRR_Client
            END AS IRR_Value
        FROM #IRR i
        WHERE i.CreditID = s.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
          AND i.IRRDate <= CAST(s.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS DATE)
        ORDER BY i.IRRDate DESC
    ) irr
    LEFT JOIN [ATK].[mis].[Silver_Restruct_Merged_SCD] r
           ON r.CreditID = s.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
          AND s.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= r.ValidFrom
          AND s.[СуммыЗадолженностиПоПериодамПросрочки Дата] <= r.ValidTo
    WHERE s.[СуммыЗадолженностиПоПериодамПросрочки Дата] BETWEEN @DateFrom AND @DateTo
	AND s.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID] = '813c00155d65040111ed283cc958b111'
    
)
SELECT
    SoldDate,
    CreditID,
    ClientID,
    Balance_Total,
    IRR_Value,
    DaysBucket_Credit,
    DaysFact_Total,
    DaysIFRS,
    StateName_Final,
    TypeName_Sticky_Final,
    CreditStatus_Base
INTO #Base
FROM cte
WHERE rn = 1;

CREATE CLUSTERED INDEX CIX_Base ON #Base (ClientID, SoldDate, CreditID);

---------------------------------------------------------
-- STEP 1.1 MAX DAYS
---------------------------------------------------------
SELECT ClientID, SoldDate, MAX(DaysFact_Total) AS MaxDaysPerClientDay
INTO #MaxDays
FROM #Base
GROUP BY ClientID, SoldDate;

CREATE UNIQUE CLUSTERED INDEX CIX_MaxDays ON #MaxDays (ClientID, SoldDate);

---------------------------------------------------------
-- STEP 1.2 FLAGS
---------------------------------------------------------
SELECT ClientID, SoldDate
INTO #Flag
FROM [ATK].[mis].[Silver_Client_UnhealedFlag]
WHERE HasUnhealed = 1
  AND SoldDate BETWEEN @DateFrom AND @DateTo;

CREATE UNIQUE CLUSTERED INDEX CIX_Flag ON #Flag (ClientID, SoldDate);

---------------------------------------------------------
-- STEP 2 RESPONSIBLE FALLBACK
---------------------------------------------------------
;WITH MinFrom AS (
    SELECT CreditID, MIN(ValidFrom) AS MinValidFrom
    FROM [ATK].[mis].[Silver_Resp_SCD]
    GROUP BY CreditID
)
SELECT r.CreditID, r.FinalBranchID, r.FinalExpertID, r.IsSpecialBranch
INTO #RespEarliest
FROM [ATK].[mis].[Silver_Resp_SCD] r
JOIN MinFrom m
  ON r.CreditID = m.CreditID
 AND r.ValidFrom = m.MinValidFrom;

---------------------------------------------------------
-- STEP 3 JOIN RESPONSIBLE
---------------------------------------------------------
SELECT
    b.*,
    COALESCE(r_curr.FinalBranchID, e.FinalBranchID) AS LastBranchID,
    COALESCE(r_curr.FinalExpertID, e.FinalExpertID) AS LastExpertID,
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
LEFT JOIN #RespEarliest e ON e.CreditID = b.CreditID
LEFT JOIN [ATK].[mis].[Silver_Stages_SCD] s
       ON s.CreditID = b.CreditID
      AND b.SoldDate BETWEEN s.ValidFrom AND s.ValidTo;

---------------------------------------------------------
-- STEP 4 PAR
---------------------------------------------------------
SELECT
    jr.SoldDate,
    jr.CreditID,
    jr.ClientID,
    jr.Balance_Total,
	jr.IRR_Value,
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

---------------------------------------------------------
-- FINAL INSERT
---------------------------------------------------------
INSERT INTO [mis].[Gold_Fact_Restruct_Daily_Sold_Par]
(
    SoldDate,
    CreditID,
    ClientID,
    Balance_Total,
    IRR_Values,
    DaysBucket_Credit,
    DaysFact_Total,
    DaysIFRS,
    StateName_Final,
    TypeName_Sticky_Final,
    CreditStatus_Base,
    LastBranchID,
    LastExpertID,
    IsSpecialBranch,
    SegmentIFRS,
    ParIFRS,
    StageName
)
SELECT
    j.SoldDate,
    j.CreditID,
    j.ClientID,
    Balance_Total,
    ROUND(ISNULL(IRR_Value,0) * Balance_Total, 2) AS IRR_Values,
    DaysBucket_Credit,
    DaysFact_Total,
    DaysIFRS,
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
    CreditStatus_Base,
    LastBranchID,
    LastExpertID,
    IsSpecialBranch,
    CASE
        WHEN DaysIFRS >= 91 THEN N'e) 90 +'
        WHEN DaysIFRS >= 31 THEN N'd) 30 - 90'
        WHEN DaysIFRS >= 16 THEN N'c) 16 - 30'
        WHEN DaysIFRS >= 4  THEN N'b) 4 - 15'
        ELSE N'a) 0 - 3'
    END AS SegmentIFRS,
    ParIFRS,
    CASE CurrentStage
        WHEN 'Стадия1' THEN 'Stage1'
        WHEN 'Стадия2' THEN 'Stage2'
        WHEN 'Стадия3' THEN 'Stage3'
        ELSE CurrentStage
    END
FROM #Joined j
LEFT JOIN #Flag f
  ON f.ClientID = j.ClientID
 AND f.SoldDate = j.SoldDate;

COMMIT TRAN;

PRINT N'🏁 Готово';

