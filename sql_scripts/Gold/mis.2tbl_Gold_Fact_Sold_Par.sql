USE [ATK];
SET NOCOUNT ON;

DECLARE @DateFrom DATE = '2024-01-01';

-----------------------------------------------------
-- Drop & recreate main GOLD table
-----------------------------------------------------
DROP TABLE IF EXISTS mis.[2tbl_Gold_Fact_Sold_Par];

CREATE TABLE mis.[2tbl_Gold_Fact_Sold_Par] (
    SoldDate                 DATE         NOT NULL,
    CreditID                 VARCHAR(36)  NOT NULL,
    SoldAmount               DECIMAL(18,2) NULL,
	NumberOfOverdueDaysIFRS  DECIMAL(15,2) NULL,
    IRR_Values               DECIMAL(18,6) NULL,
    BranchShadow             NVARCHAR(100) NULL,
    EmployeeID               VARCHAR(36)  NULL,
    BranchID                 VARCHAR(36)  NULL,
    EmployeePositionID       VARCHAR(36) NULL,
    Par_0_IFRS               DECIMAL(18,6) NULL,
    Par_30_IFRS              DECIMAL(18,6) NULL,
    Par_60_IFRS              DECIMAL(18,6) NULL,
    Par_90_IFRS              DECIMAL(18,6) NULL
) WITH (DATA_COMPRESSION = PAGE);

-----------------------------------------------------
-- Step 1: Max Past Days (explicit temp table)
-----------------------------------------------------
IF OBJECT_ID('tempdb..#MaxPastDays') IS NOT NULL DROP TABLE #MaxPastDays;
CREATE TABLE #MaxPastDays (
    OwnerID   VARCHAR(36) NOT NULL,
    ParDate   DATE        NOT NULL,
    MaxPastDays INT       NULL
);

INSERT INTO #MaxPastDays (OwnerID, ParDate, MaxPastDays)
SELECT 
    k.[Кредиты Владелец] AS OwnerID,
    sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS ParDate,
    MAX(sd.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого]) AS MaxPastDays
FROM mis.[Silver_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] sd
LEFT JOIN mis.[Silver_Справочники.Кредиты] k
  ON k.[Кредиты ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
WHERE sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] <> 0
  AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= @DateFrom
GROUP BY k.[Кредиты Владелец], sd.[СуммыЗадолженностиПоПериодамПросрочки Дата];

CREATE UNIQUE NONCLUSTERED INDEX IX_MaxPastDays_Owner_ParDate ON #MaxPastDays (OwnerID, ParDate);

-----------------------------------------------------
-- Step 2: Shadow Branch (explicit temp table)
-----------------------------------------------------
IF OBJECT_ID('tempdb..#ShadowBranch') IS NOT NULL DROP TABLE #ShadowBranch;
CREATE TABLE #ShadowBranch (
    CreditID     VARCHAR(36)  NOT NULL,
    BranchShadow NVARCHAR(100) NULL,
    Period       DATE         NULL
);

INSERT INTO #ShadowBranch (CreditID, BranchShadow, Period)
SELECT 
    x.[КредитыВТеневыхФилиалах Кредит ID] AS CreditID,
    x.[КредитыВТеневыхФилиалах Филиал] AS BranchShadow,
    x.[КредитыВТеневыхФилиалах Период] AS Period
FROM mis.[Silver_РегистрыСведений.КредитыВТеневыхФилиалах] x;

CREATE NONCLUSTERED INDEX IX_Shadow_Credit_Period ON #ShadowBranch (CreditID, Period);

-----------------------------------------------------
-- Step 3: Responsible / Employee (explicit temp table)
-----------------------------------------------------
IF OBJECT_ID('tempdb..#Responsible') IS NOT NULL DROP TABLE #Responsible;
CREATE TABLE #Responsible (
    CreditID VARCHAR(36) NOT NULL,
    EmployeeID VARCHAR(36) NULL,
    BranchID VARCHAR(36) NULL,
    Period   DATE        NULL
);

INSERT INTO #Responsible (CreditID, EmployeeID, BranchID, Period)
SELECT
    r.[ОтветственныеПоКредитамВыданным Кредит ID] AS CreditID,
    r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS EmployeeID,
    r.[ОтветственныеПоКредитамВыданным Филиал ID] AS BranchID,
    r.[ОтветственныеПоКредитамВыданным Период] AS Period
FROM mis.[Silver_РегистрыСведений.ОтветственныеПоКредитамВыданным] r;

CREATE NONCLUSTERED INDEX IX_Resp_Credit_Period ON #Responsible (CreditID, Period);

-----------------------------------------------------
-- Step 3.1: Employee Position (explicit temp table) - OPTIMIZED
-----------------------------------------------------
IF OBJECT_ID('tempdb..#EmployeePos') IS NOT NULL DROP TABLE #EmployeePos;
CREATE TABLE #EmployeePos (
    EmployeeID VARCHAR(36) NOT NULL,
    PositionID VARCHAR(36) NULL,
    Period DATE NULL
);

-- Only employees present in #Responsible and recent periods
INSERT INTO #EmployeePos (EmployeeID, PositionID, Period)
SELECT
    emp.[СотрудникиДанныеПоЗарплате Сотрудник ID] AS EmployeeID,
    emp.[СотрудникиДанныеПоЗарплате Должность ID] AS PositionID,
    emp.[СотрудникиДанныеПоЗарплате Период] AS Period
FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате] emp
INNER JOIN (
    SELECT DISTINCT EmployeeID
    FROM #Responsible
    WHERE EmployeeID IS NOT NULL
) rlist
  ON emp.[СотрудникиДанныеПоЗарплате Сотрудник ID] = rlist.EmployeeID
WHERE emp.[СотрудникиДанныеПоЗарплате Период] >= DATEADD(year,-1,@DateFrom);

CREATE CLUSTERED INDEX CX_EmployeePos_Emp_Period 
ON #EmployeePos (EmployeeID, Period);

-----------------------------------------------------
-- Step 4: IRR (keep all records, we'll choose top-1 per sold row via OUTER APPLY)
-----------------------------------------------------
IF OBJECT_ID('tempdb..#IRR') IS NOT NULL DROP TABLE #IRR;
CREATE TABLE #IRR (
    CreditID VARCHAR(36) NOT NULL,
    IRR_Year DECIMAL(18,6) NULL,
    IRR_Client DECIMAL(18,6) NULL,
    IRRDate DATETIME2 NULL
);

INSERT INTO #IRR (CreditID, IRR_Year, IRR_Client, IRRDate)
SELECT
    i.[УстановкаДанныхКредита Кредит ID] AS CreditID,
    i.[УстановкаДанныхКредита Внутренняя Норма Доходности Годовая] AS IRR_Year,
    i.[УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая] AS IRR_Client,
    i.[УстановкаДанныхКредита Дата] AS IRRDate
FROM mis.[Silver_Документы.УстановкаДанныхКредита] i
WHERE i.[УстановкаДанныхКредита Кредит ID] IS NOT NULL;

-- helpful index to speed the OUTER APPLY lookup
CREATE NONCLUSTERED INDEX IX_IRR_Credit_Date ON #IRR (CreditID, IRRDate DESC);

-----------------------------------------------------
-- Prepare ranges (ValidFrom, ValidTo) for Responsible, ShadowBranch & EmployeePos
-- and perform final insert (CTEs immediately followed by INSERT)
-----------------------------------------------------
;WITH RespRanges AS (
    SELECT 
        CreditID,
        EmployeeID,
        BranchID,
        Period AS ValidFrom,
        LEAD(Period) OVER (PARTITION BY CreditID ORDER BY Period) AS ValidTo
    FROM #Responsible
),
ShadowRanges AS (
    SELECT
        CreditID,
        BranchShadow,
        Period AS ValidFrom,
        LEAD(Period) OVER (PARTITION BY CreditID ORDER BY Period) AS ValidTo
    FROM #ShadowBranch
),
EmpPosRanges AS (
    SELECT
        EmployeeID,
        PositionID,
        Period AS ValidFrom,
        LEAD(Period) OVER (PARTITION BY EmployeeID ORDER BY Period) AS ValidTo
    FROM #EmployeePos
)
INSERT INTO mis.[2tbl_Gold_Fact_Sold_Par] WITH (TABLOCK)
(
    SoldDate, CreditID, SoldAmount, NumberOfOverdueDaysIFRS, IRR_Values, BranchShadow, EmployeeID, BranchID, EmployeePositionID,
    Par_0_IFRS, Par_30_IFRS, Par_60_IFRS, Par_90_IFRS
)
SELECT
    sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS SoldDate,
    sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
    sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] AS SoldAmount,
    sd.[СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки МСФО] AS NumberOfOverdueDaysIFRS,
    -- IRR Values: pick latest IRR (by datetime) whose date <= SoldDate (cast to date)
    ROUND(
        COALESCE(
            CASE 
                WHEN irr.IRR_Year IS NOT NULL AND irr.IRR_Year < 100 
                    THEN irr.IRR_Year
                ELSE irr.IRR_Client
            END,
            0
        )
        * sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит], 2
    ) AS IRR_Values,
    
    -- BranchShadow from ranges
    sh.BranchShadow,
    
    -- EmployeeID and BranchID from ranges
    r.EmployeeID,
    r.BranchID,
    empPos.PositionID AS EmployeePositionID,

    -- ParNas IFRS buckets
    CASE WHEN mpd.MaxPastDays > 0  THEN sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE 0 END AS Par_0_IFRS,
    CASE WHEN mpd.MaxPastDays > 30 THEN sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE 0 END AS Par_30_IFRS,
    CASE WHEN mpd.MaxPastDays > 60 THEN sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE 0 END AS Par_60_IFRS,
    CASE WHEN mpd.MaxPastDays > 90 THEN sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE 0 END AS Par_90_IFRS

FROM mis.[Silver_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] sd
JOIN mis.[Silver_Справочники.Кредиты] k
  ON k.[Кредиты ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]

-- MaxPastDays
LEFT JOIN #MaxPastDays mpd
  ON mpd.OwnerID = k.[Кредиты Владелец]
 AND mpd.ParDate = sd.[СуммыЗадолженностиПоПериодамПросрочки Дата]

-- Responsible: range join
LEFT JOIN RespRanges r
    ON r.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
   AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= r.ValidFrom
   AND (r.ValidTo IS NULL OR sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] < r.ValidTo)

-- Employee Position: range join
LEFT JOIN EmpPosRanges empPos
    ON empPos.EmployeeID = r.EmployeeID
   AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= empPos.ValidFrom
   AND (empPos.ValidTo IS NULL OR sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] < empPos.ValidTo)

-- Shadow Branch: range join
LEFT JOIN ShadowRanges sh
    ON sh.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
   AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= sh.ValidFrom
   AND (sh.ValidTo IS NULL OR sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] < sh.ValidTo)

-- IRR: pick latest per sold row (no row multiplication)
OUTER APPLY (
    SELECT TOP (1) i.IRR_Year, i.IRR_Client
    FROM #IRR i
    WHERE i.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
      AND CAST(i.IRRDate AS DATE) <= CAST(sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS DATE)
    ORDER BY i.IRRDate DESC
) AS irr

WHERE sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] <> 0
AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= @DateFrom;

-----------------------------------------------------
-- Columnstore
-----------------------------------------------------
CREATE CLUSTERED COLUMNSTORE INDEX CCSI_2tbl_Gold_Fact_Sold_Par
ON mis.[2tbl_Gold_Fact_Sold_Par];

-----------------------------------------------------
-- Drop temp tables
-----------------------------------------------------
DROP TABLE IF EXISTS #MaxPastDays, #ShadowBranch, #Responsible, #IRR, #EmployeePos;
