USE [ATK];
GO
SET NOCOUNT ON;

----------------------------------------
-- Drop temp tables if exist
----------------------------------------
IF OBJECT_ID('tempdb..#Base')   IS NOT NULL DROP TABLE #Base;
IF OBJECT_ID('tempdb..#Status') IS NOT NULL DROP TABLE #Status;
IF OBJECT_ID('tempdb..#Final')  IS NOT NULL DROP TABLE #Final;

----------------------------------------
-- Drop target table if exists
----------------------------------------
IF OBJECT_ID('mis.[Gold_Fact_Disbursement2]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_Disbursement2];
GO

----------------------------------------
-- Create target table
----------------------------------------
CREATE TABLE mis.[Gold_Fact_Disbursement2] 
(
    CreditID           NVARCHAR(36)   NOT NULL,
    ClientID           NVARCHAR(36)   NULL,
    DisbursementDate   DATETIME2      NULL,
    CurrencyID         NVARCHAR(36)   NULL,
    CreditAmount       DECIMAL(18,2)  NULL,
    CreditAmountInMDL  DECIMAL(18,2)  NULL,
    CreditCurrency     NVARCHAR(50)   NULL,

    FirstFilialID      NVARCHAR(36)   NULL,
    FirstEmployeeID    NVARCHAR(36)   NULL,
    FirstPositionID    NVARCHAR(36)   NULL,
    FirstPosition      NVARCHAR(100)  NULL,

    LastFilialID       NVARCHAR(36)   NULL,
    LastEmployeeID     NVARCHAR(36)   NULL,
    LastPositionID     NVARCHAR(36)   NULL,
    LastPosition       NVARCHAR(100)  NULL,

    IRR                DECIMAL(18,2)  NULL,
    IRR_Client         DECIMAL(18,2)  NULL,
    Qty                INT            NULL,
    NewExisting_Client NVARCHAR(20)   NULL,

    CreatedAt          DATETIME       NOT NULL DEFAULT GETDATE()
);
GO

----------------------------------------
-- Build #Base
----------------------------------------
SELECT
    d.[ДанныеКредитовВыданных Кредит ID] AS CreditID,
    k.[Кредиты Владелец] AS ClientID,
    d.[ДанныеКредитовВыданных Дата Выдачи] AS DisbursementDate,
    d.[ДанныеКредитовВыданных Валюта Кредита ID] AS CurrencyID,

    finalAmount.ChosenAmount AS CreditAmount,
    ROUND(finalAmount.ChosenAmount * ISNULL(rate.Rate,1),2) AS CreditAmountInMDL,
    d.[ДанныеКредитовВыданных Валюта Кредита] AS CreditCurrency,

    -- First assignment
    firstR.FilialID AS FirstFilialID,
    firstR.EmployeeID AS FirstEmployeeID,
    firstPos.PositionID AS FirstPositionID,
    firstPos.Position AS FirstPosition,

    -- Last assignment
    lastR.FilialID AS LastFilialID,
    lastR.EmployeeID AS LastEmployeeID,
    lastPos.PositionID AS LastPositionID,
    lastPos.Position AS LastPosition,

    irr.IRR,
    irr.IRR_Client,

    ROW_NUMBER() OVER (
        PARTITION BY d.[ДанныеКредитовВыданных Кредит ID]
        ORDER BY d.[ДанныеКредитовВыданных Дата Выдачи]
    ) AS rn

INTO #Base
FROM [ATK].[mis].[Bronze_РегистрыСведений.ДанныеКредитовВыданных] d
JOIN [ATK].[mis].[Bronze_Справочники.Кредиты] k
    ON k.[Кредиты ID] = d.[ДанныеКредитовВыданных Кредит ID]

-- Currency rate
OUTER APPLY (
    SELECT TOP 1 v.[Валюта Курс] AS Rate
    FROM [ATK].[mis].[Bronze_РегистрыСведений.Валюта] v
    WHERE v.[Валюта Валюта ID] = d.[ДанныеКредитовВыданных Валюта Кредита ID]
      AND v.[Валюта Период] <= d.[ДанныеКредитовВыданных Дата Выдачи]
    ORDER BY v.[Валюта Период] DESC
) rate

-- First responsible
OUTER APPLY (
    SELECT TOP 1
        r.[ОтветственныеПоКредитамВыданным Филиал ID] AS FilialID,
        r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS EmployeeID
    FROM [ATK].[mis].[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным] r
    WHERE r.[ОтветственныеПоКредитамВыданным Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
    ORDER BY r.[ОтветственныеПоКредитамВыданным Период] ASC
) firstR

-- Last responsible
OUTER APPLY (
    SELECT TOP 1
        r.[ОтветственныеПоКредитамВыданным Филиал ID] AS FilialID,
        r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS EmployeeID
    FROM [ATK].[mis].[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным] r
    WHERE r.[ОтветственныеПоКредитамВыданным Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
    ORDER BY r.[ОтветственныеПоКредитамВыданным Период] DESC
) lastR

-- First position (earliest before DisbursementDate)
OUTER APPLY (
    SELECT TOP 1
        e.[СотрудникиДанныеПоЗарплате Должность ID] AS PositionID,
        e.[СотрудникиДанныеПоЗарплате Должность] AS Position
    FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате] e
    WHERE e.[СотрудникиДанныеПоЗарплате Сотрудник ID] = firstR.EmployeeID
      AND e.[СотрудникиДанныеПоЗарплате Период] <= d.[ДанныеКредитовВыданных Дата Выдачи]
    ORDER BY e.[СотрудникиДанныеПоЗарплате Период] ASC
) firstPos

-- Last position (latest before DisbursementDate)
OUTER APPLY (
    SELECT TOP 1
        e.[СотрудникиДанныеПоЗарплате Должность ID] AS PositionID,
        e.[СотрудникиДанныеПоЗарплате Должность] AS Position
    FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате] e
    WHERE e.[СотрудникиДанныеПоЗарплате Сотрудник ID] = firstR.EmployeeID
      AND e.[СотрудникиДанныеПоЗарплате Период] <= d.[ДанныеКредитовВыданных Дата Выдачи]
    ORDER BY e.[СотрудникиДанныеПоЗарплате Период] DESC
) lastPos

-- IRR
OUTER APPLY (
    SELECT TOP 1
        IRR_Client = ROUND(COALESCE(doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая],0),2),
        IRR = ROUND(
            COALESCE(
                CASE
                    WHEN doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Годовая] < 100
                        THEN doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Годовая]
                    ELSE doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая]
                END,0),2)
    FROM [ATK].[mis].[Bronze_Документы.УстановкаДанныхКредита] doc
    WHERE doc.[УстановкаДанныхКредита Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
    ORDER BY doc.[УстановкаДанныхКредита Дата] DESC
) irr

OUTER APPLY (
    SELECT d.[ДанныеКредитовВыданных Сумма Кредита] AS ChosenAmount
) finalAmount

WHERE d.[ДанныеКредитовВыданных Кредитный Продукт] NOT LIKE N'Medier%'
  AND d.[ДанныеКредитовВыданных Дата Выдачи] >= '2023-09-01';
GO

----------------------------------------
-- Build #Status (cancel/restore)
----------------------------------------
WITH BaseIDs AS (
    SELECT DISTINCT CreditID FROM #Base
),
Cancels AS (
    SELECT a.[АнулированныеКредитыПартнеров Кредит ID] AS CreditID,
           MAX(a.[АнулированныеКредитыПартнеров Период]) AS CancelPeriod
    FROM [ATK].[mis].[Bronze_РегистрыСведений.АнулированныеКредитыПартнеров] a
    INNER JOIN BaseIDs b ON b.CreditID = a.[АнулированныеКредитыПартнеров Кредит ID]
    WHERE a.[АнулированныеКредитыПартнеров Кредит Анулирован] = N'01'
    GROUP BY a.[АнулированныеКредитыПартнеров Кредит ID]
),
Restores AS (
    SELECT a.[АнулированныеКредитыПартнеров Кредит ID] AS CreditID,
           MAX(a.[АнулированныеКредитыПартнеров Период]) AS RestorePeriod
    FROM [ATK].[mis].[Bronze_РегистрыСведений.АнулированныеКредитыПартнеров] a
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

----------------------------------------
-- Build #Final
----------------------------------------
SELECT
    b.CreditID, b.ClientID, b.DisbursementDate, b.CurrencyID,
    b.CreditAmount, b.CreditAmountInMDL, b.CreditCurrency,
    b.FirstFilialID, b.FirstEmployeeID, b.FirstPositionID, b.FirstPosition,
    b.LastFilialID, b.LastEmployeeID, b.LastPositionID, b.LastPosition,
    b.IRR, b.IRR_Client, 1 AS Qty
INTO #Final
FROM #Base b
WHERE b.rn = 1;

-- Cancels
INSERT INTO #Final
SELECT
    b.CreditID, b.ClientID, s.CancelPeriod, b.CurrencyID,
    -b.CreditAmount, -b.CreditAmountInMDL, b.CreditCurrency,
    b.FirstFilialID, b.FirstEmployeeID, b.FirstPositionID, b.FirstPosition,
    b.LastFilialID, b.LastEmployeeID, b.LastPositionID, b.LastPosition,
    b.IRR, b.IRR_Client, -1 AS Qty
FROM #Status s
JOIN #Base b ON b.CreditID = s.CreditID AND b.rn = 1
WHERE s.CancelPeriod IS NOT NULL
  AND s.CancelPeriod >= b.DisbursementDate;

-- Restores
INSERT INTO #Final
SELECT
    b.CreditID, b.ClientID, s.RestorePeriod, b.CurrencyID,
    b.CreditAmount, b.CreditAmountInMDL, b.CreditCurrency,
    b.FirstFilialID, b.FirstEmployeeID, b.FirstPositionID, b.FirstPosition,
    b.LastFilialID, b.LastEmployeeID, b.LastPositionID, b.LastPosition,
    b.IRR, b.IRR_Client, 1 AS Qty
FROM #Status s
JOIN #Base b ON b.CreditID = s.CreditID AND b.rn = 1
WHERE s.RestorePeriod IS NOT NULL
  AND s.RestorePeriod >= b.DisbursementDate
  AND (s.CancelPeriod IS NULL OR s.RestorePeriod > s.CancelPeriod);
GO

----------------------------------------
-- Insert into final table
----------------------------------------
WITH AllSeq AS (
    SELECT
        f.*,
        ROW_NUMBER() OVER (
            PARTITION BY f.ClientID
            ORDER BY f.DisbursementDate, f.CreditID
        ) AS rn_all
    FROM #Final f
)
INSERT INTO mis.[Gold_Fact_Disbursement2]
(
    CreditID, ClientID, DisbursementDate, CurrencyID, CreditAmount, CreditAmountInMDL,
    CreditCurrency, FirstFilialID, FirstEmployeeID, FirstPositionID, FirstPosition,
    LastFilialID, LastEmployeeID, LastPositionID, LastPosition,
    IRR, IRR_Client, Qty, NewExisting_Client
)
SELECT
    a.CreditID,
    a.ClientID,
    a.DisbursementDate,
    a.CurrencyID,
    a.CreditAmount,
    a.CreditAmountInMDL,
    a.CreditCurrency,
-- =========================
-- FIRST (null if LAST exists)
-- =========================
CASE 
    WHEN a.LastFilialID IS NOT NULL 
         AND a.LastFilialID <> a.FirstFilialID
    THEN NULL
    ELSE a.FirstFilialID
END AS FirstFilialID,

CASE 
    WHEN a.LastEmployeeID IS NOT NULL 
         AND a.LastEmployeeID <> a.FirstEmployeeID
    THEN NULL
    ELSE a.FirstEmployeeID
END AS FirstEmployeeID,

CASE 
    WHEN a.LastPositionID IS NOT NULL 
         AND a.LastPositionID <> a.FirstPositionID
    THEN NULL
    ELSE a.FirstPositionID
END AS FirstPositionID,

CASE 
    WHEN a.LastPositionID IS NOT NULL 
         AND a.LastPositionID <> a.FirstPositionID
    THEN NULL
    ELSE a.FirstPosition
END AS FirstPosition,

-- =========================
-- LAST (fallback to FIRST)
-- =========================
CASE 
    WHEN a.LastFilialID IS NOT NULL 
         AND a.LastFilialID <> a.FirstFilialID
    THEN a.LastFilialID
    ELSE a.FirstFilialID
END AS LastFilialID,

CASE 
    WHEN a.LastEmployeeID IS NOT NULL 
         AND a.LastEmployeeID <> a.FirstEmployeeID
    THEN a.LastEmployeeID
    ELSE a.FirstEmployeeID
END AS LastEmployeeID,

CASE 
    WHEN a.LastPositionID IS NOT NULL 
         AND a.LastPositionID <> a.FirstPositionID
    THEN a.LastPositionID
    ELSE a.FirstPositionID
END AS LastPositionID,

CASE 
    WHEN a.LastPositionID IS NOT NULL 
         AND a.LastPositionID <> a.FirstPositionID
    THEN a.LastPosition
    ELSE a.FirstPosition
END AS LastPosition,

    a.IRR,
    a.IRR_Client,
    a.Qty,

    CASE
        WHEN a.CreditAmount > 0 AND a.rn_all = 1 THEN N'New'
        WHEN a.CreditAmount > 0 THEN N'Existing'
        ELSE N'Cancelled'
    END AS NewExisting_Client
FROM AllSeq a;
GO

----------------------------------------
-- Indexes
----------------------------------------
CREATE CLUSTERED INDEX CIX_Disbursement_DisbursementDate_ClientID
ON mis.[Gold_Fact_Disbursement2] (DisbursementDate ASC, ClientID ASC);

CREATE NONCLUSTERED INDEX IX_Disbursement_CreditID
ON mis.[Gold_Fact_Disbursement2] (CreditID);

CREATE NONCLUSTERED INDEX IX_Disbursement_FirstFilialID
ON mis.[Gold_Fact_Disbursement2] (FirstFilialID);

CREATE NONCLUSTERED INDEX IX_Disbursement_LastFilialID
ON mis.[Gold_Fact_Disbursement2] (LastFilialID);

CREATE NONCLUSTERED INDEX IX_Disbursement_NewExisting
ON mis.[Gold_Fact_Disbursement2] (NewExisting_Client);

CREATE NONCLUSTERED INDEX IX_Disbursement_ClientID
ON mis.[Gold_Fact_Disbursement2] (ClientID);
GO

----------------------------------------
-- Cleanup temp tables
----------------------------------------
DROP TABLE #Base;
DROP TABLE #Status;
DROP TABLE #Final;
GO
