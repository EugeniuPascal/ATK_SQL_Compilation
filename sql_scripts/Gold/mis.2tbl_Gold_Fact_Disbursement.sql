USE [ATK];
GO

/* ============================
   Clean up
   ============================ */
IF OBJECT_ID('tempdb..#Base')   IS NOT NULL DROP TABLE #Base;
IF OBJECT_ID('tempdb..#Status') IS NOT NULL DROP TABLE #Status;
IF OBJECT_ID('tempdb..#Final')  IS NOT NULL DROP TABLE #Final;

IF OBJECT_ID('mis.[2tbl_Gold_Fact_Disbursement]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Fact_Disbursement];
GO

/* ============================
   Target table
   (ID lengths aligned to 36)
   ============================ */
CREATE TABLE mis.[2tbl_Gold_Fact_Disbursement] (
    CreditID           NVARCHAR(36)   NOT NULL,
    ClientID           NVARCHAR(36)   NULL,
    DisbursementDate   DATETIME2      NULL,
    CurrencyID         NVARCHAR(36)   NULL,
    CreditAmount       DECIMAL(18,2)  NULL,
    CreditAmountInMDL  DECIMAL(18,2)  NULL,
    CreditCurrency     NVARCHAR(50)   NULL,
    FirstFilialID      NVARCHAR(36)   NULL,
    FirstExpertID      NVARCHAR(36)   NULL,
    LastFilialID       NVARCHAR(36)   NULL,
    LastExpertID       NVARCHAR(36)   NULL,
    IRR                DECIMAL(18,6)  NULL,
    IRR_Client         DECIMAL(18,6)  NULL,
    Qty                INT            NULL,
    NewExisting_Client NVARCHAR(20)   NULL,
    CreatedAt          DATETIME       NOT NULL DEFAULT GETDATE()
);
GO

/* ============================
   Base rows
   - one per disbursed tranche
   - rn=1 = first tranche per credit
   - last expert/filial as of end of disbursement month
   ============================ */
SELECT
    d.[ДанныеКредитовВыданных Кредит ID]                 AS CreditID,
    k.[Кредиты Владелец]                                 AS ClientID,
    d.[ДанныеКредитовВыданных Дата Выдачи]               AS DisbursementDate,
    d.[ДанныеКредитовВыданных Валюта Кредита ID]         AS CurrencyID,
    d.[ДанныеКредитовВыданных Сумма Кредита]             AS CreditAmount,
    ROUND(d.[ДанныеКредитовВыданных Сумма Кредита] * ISNULL(rate.Rate, 1), 2)
                                                         AS CreditAmountInMDL,
    d.[ДанныеКредитовВыданных Валюта Кредита]            AS CreditCurrency,
    firstR.[ФилиалID]                                     AS FirstFilialID,
    firstR.[ЭкспертID]                                    AS FirstExpertID,
    COALESCE(lastR_month.[ФилиалID], firstR.[ФилиалID])   AS LastFilialID,
    COALESCE(lastR_month.[ЭкспертID], firstR.[ЭкспертID]) AS LastExpertID,
    irr.IRR                                               AS IRR,
    irr.IRR_Client                                        AS IRR_Client,
    rn = ROW_NUMBER() OVER (
            PARTITION BY d.[ДанныеКредитовВыданных Кредит ID]
            ORDER BY d.[ДанныеКредитовВыданных Дата Выдачи]
         )
INTO #Base
FROM [ATK].[mis].[Silver_РегистрыСведений.ДанныеКредитовВыданных] d
INNER JOIN [ATK].[mis].[Silver_Справочники.Кредиты] k
    ON k.[Кредиты ID] = d.[ДанныеКредитовВыданных Кредит ID]
OUTER APPLY (
    SELECT TOP 1 v.[Валюта Курс] AS Rate
    FROM [ATK].[mis].[Silver_РегистрыСведений.Валюта] v
    WHERE v.[Валюта Валюта ID] = d.[ДанныеКредитовВыданных Валюта Кредита ID]
      AND v.[Валюта Период] <= d.[ДанныеКредитовВыданных Период]
    ORDER BY v.[Валюта Период] DESC
) rate
OUTER APPLY (
    /* earliest responsible overall */
    SELECT TOP 1
           r.[ОтветственныеПоКредитамВыданным Филиал ID]            AS [ФилиалID],
           r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID]  AS [ЭкспертID]
    FROM [ATK].[mis].[Silver_РегистрыСведений.ОтветственныеПоКредитамВыданным] r
    WHERE r.[ОтветственныеПоКредитамВыданным Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
    ORDER BY r.[ОтветственныеПоКредитамВыданным Период] ASC
) firstR
OUTER APPLY (
    /* last responsible AS OF end of disbursement month */
    SELECT TOP 1
           r.[ОтветственныеПоКредитамВыданным Филиал ID]            AS [ФилиалID],
           r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID]  AS [ЭкспертID]
    FROM [ATK].[mis].[Silver_РегистрыСведений.ОтветственныеПоКредитамВыданным] r
    WHERE r.[ОтветственныеПоКредитамВыданным Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
      AND r.[ОтветственныеПоКредитамВыданным Период] <= EOMONTH(d.[ДанныеКредитовВыданных Дата Выдачи])
    ORDER BY r.[ОтветственныеПоКредитамВыданным Период] DESC
) lastR_month
OUTER APPLY (
    SELECT TOP 1 
        COALESCE(
            NULLIF(doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Годовая], 9999.999999),
            doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая]
        ) AS IRR,
        doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая] AS IRR_Client
    FROM [ATK].[mis].[Silver_Документы.УстановкаДанныхКредита] doc
    WHERE doc.[УстановкаДанныхКредита Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
    ORDER BY doc.[УстановкаДанныхКредита Дата] DESC
) irr
WHERE d.[ДанныеКредитовВыданных Кредитный Продукт] NOT LIKE N'Medier%'
  AND d.[ДанныеКредитовВыданных Дата Выдачи] >= '2024-01-01';
GO

SELECT COUNT(*) AS BaseRows FROM #Base;
GO

/* ============================
   Status (cancel/restore)
   - cancel = '01'  -> negative row
   - restore = '00' -> positive row
   Build only for credits present in #Base
   ============================ */
WITH BaseIDs AS (
    SELECT DISTINCT CreditID FROM #Base
),
Cancels AS (
    SELECT a.[АнулированныеКредитыПартнеров Кредит ID] AS CreditID,
           MAX(a.[АнулированныеКредитыПартнеров Период]) AS CancelPeriod
    FROM [ATK].[mis].[Silver_РегистрыСведений.АнулированныеКредитыПартнеров] a
    INNER JOIN BaseIDs b ON b.CreditID = a.[АнулированныеКредитыПартнеров Кредит ID]
    WHERE a.[АнулированныеКредитыПартнеров Кредит Анулирован] = N'01'
    GROUP BY a.[АнулированныеКредитыПартнеров Кредит ID]
),
Restores AS (
    SELECT a.[АнулированныеКредитыПартнеров Кредит ID] AS CreditID,
           MAX(a.[АнулированныеКредитыПартнеров Период]) AS RestorePeriod
    FROM [ATK].[mis].[Silver_РегистрыСведений.АнулированныеКредитыПартнеров] a
    INNER JOIN BaseIDs b ON b.CreditID = a.[АнулированныеКредитыПартнеров Кредит ID]
    WHERE a.[АнулированныеКредитыПартнеров Кредит Восстановлен] = N'00'
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

SELECT COUNT(*) AS StatusRows FROM #Status;
GO

/* ============================
   Build #Final:
   + Disbursement (qty=+1)
   + Cancel (qty=-1, negative amounts)  — only if >= disbursement
   + Restore (qty=+1, positive amounts) — only if >= disbursement AND > cancel
   ============================ */
SELECT
    b.CreditID, b.ClientID, b.DisbursementDate, b.CurrencyID,
    b.CreditAmount, b.CreditAmountInMDL, b.CreditCurrency,
    b.FirstFilialID, b.FirstExpertID, b.LastFilialID, b.LastExpertID,
    b.IRR, b.IRR_Client, 1 AS Qty
INTO #Final
FROM #Base b
WHERE b.rn = 1;

-- Cancel rows (negative amounts) — only when cancel is on/after disbursement
INSERT INTO #Final
SELECT
    b.CreditID, b.ClientID, s.CancelPeriod, b.CurrencyID,
    -b.CreditAmount, -b.CreditAmountInMDL, b.CreditCurrency,
    b.FirstFilialID, b.FirstExpertID, b.LastFilialID, b.LastExpertID,
    b.IRR, b.IRR_Client, -1 AS Qty
FROM #Status s
JOIN #Base b ON b.CreditID = s.CreditID AND b.rn = 1
WHERE s.CancelPeriod IS NOT NULL
  AND s.CancelPeriod >= b.DisbursementDate;

-- Restore rows (positive amounts) — only if after cancel and on/after disbursement
INSERT INTO #Final
SELECT
    b.CreditID, b.ClientID, s.RestorePeriod, b.CurrencyID,
    b.CreditAmount, b.CreditAmountInMDL, b.CreditCurrency,
    b.FirstFilialID, b.FirstExpertID, b.LastFilialID, b.LastExpertID,
    b.IRR, b.IRR_Client, 1 AS Qty
FROM #Status s
JOIN #Base b ON b.CreditID = s.CreditID AND b.rn = 1
WHERE s.RestorePeriod IS NOT NULL
  AND s.RestorePeriod >= b.DisbursementDate
  AND (s.CancelPeriod IS NULL OR s.RestorePeriod > s.CancelPeriod);  -- prevents same-day duplicate
GO

SELECT COUNT(*) AS FinalRows FROM #Final;
GO

/* ============================
   Insert to target
   - Order by date only (sign ignored)
   - First encounter for a client:
       if positive => New
       else positives => Existing
       negatives => Cancelled
   ============================ */
WITH AllSeq AS (
    SELECT
        f.*,
        ROW_NUMBER() OVER (
            PARTITION BY f.ClientID
            ORDER BY f.DisbursementDate, f.CreditID
        ) AS rn_all
    FROM #Final f
)
INSERT INTO mis.[2tbl_Gold_Fact_Disbursement]
(
    CreditID, ClientID, DisbursementDate, CurrencyID, CreditAmount, CreditAmountInMDL,
    CreditCurrency, FirstFilialID, FirstExpertID, LastFilialID, LastExpertID,
    IRR, IRR_Client, Qty, NewExisting_Client
)
SELECT
    CreditID, ClientID, DisbursementDate, CurrencyID, CreditAmount, CreditAmountInMDL,
    CreditCurrency, FirstFilialID, FirstExpertID, LastFilialID, LastExpertID,
    IRR, IRR_Client, Qty,
    CASE
        WHEN CreditAmount > 0 AND rn_all = 1 THEN N'New'
        WHEN CreditAmount > 0 THEN N'Existing'
        ELSE N'Cancelled'
    END AS NewExisting_Client
FROM AllSeq;
GO

/* ============================
   Indexes
   ============================ */
CREATE CLUSTERED INDEX CIX_Disbursement_DisbursementDate_ClientID
ON mis.[2tbl_Gold_Fact_Disbursement] (DisbursementDate ASC, ClientID ASC);

CREATE NONCLUSTERED INDEX IX_Disbursement_CreditID
ON mis.[2tbl_Gold_Fact_Disbursement] (CreditID);

CREATE NONCLUSTERED INDEX IX_Disbursement_FirstFilialID
ON mis.[2tbl_Gold_Fact_Disbursement] (FirstFilialID);

CREATE NONCLUSTERED INDEX IX_Disbursement_LastFilialID
ON mis.[2tbl_Gold_Fact_Disbursement] (LastFilialID);

CREATE NONCLUSTERED INDEX IX_Disbursement_NewExisting
ON mis.[2tbl_Gold_Fact_Disbursement] (NewExisting_Client);

CREATE NONCLUSTERED INDEX IX_Disbursement_ClientID
ON mis.[2tbl_Gold_Fact_Disbursement] (ClientID);
GO

/* ============================
   Optional: event-level uniqueness (avoids accidental dup loads)
   ============================ */
-- CREATE UNIQUE INDEX UX_Disb_UniqueEvent
-- ON mis.[2tbl_Gold_Fact_Disbursement] (CreditID, DisbursementDate, Qty)
-- WITH (IGNORE_DUP_KEY = ON);
-- GO

/* ============================
   Cleanup
   ============================ */
DROP TABLE #Base;
DROP TABLE #Status;
DROP TABLE #Final;
GO
