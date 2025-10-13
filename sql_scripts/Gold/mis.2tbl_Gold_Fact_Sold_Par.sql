USE [ATK];
GO
SET NOCOUNT ON;

DECLARE @DateFrom DATE = '2024-01-01';

-----------------------------------------------------
-- Drop + recreate main GOLD table
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
    EmployeePositionID       VARCHAR(36)  NULL,
    Par_0_IFRS               DECIMAL(18,6) NULL,
    Par_30_IFRS              DECIMAL(18,6) NULL,
    Par_60_IFRS              DECIMAL(18,6) NULL,
    Par_90_IFRS              DECIMAL(18,6) NULL,
    RestructuredCreditState  NVARCHAR(256) NULL,
    RestructuringReason      NVARCHAR(256) NULL,
    RestructuringDebtType    NVARCHAR(256) NULL
) WITH (DATA_COMPRESSION = PAGE);

-----------------------------------------------------
-- Step 1: Max Past Days
-----------------------------------------------------
IF OBJECT_ID('tempdb..#MaxPastDays') IS NOT NULL DROP TABLE #MaxPastDays;
CREATE TABLE #MaxPastDays (
    OwnerID     VARCHAR(36) NOT NULL,
    ParDate     DATE        NOT NULL,
    MaxPastDays INT         NULL
);

INSERT INTO #MaxPastDays
SELECT 
    k.[Кредиты Владелец],
    sd.[СуммыЗадолженностиПоПериодамПросрочки Дата],
    MAX(sd.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого])
FROM mis.[Silver_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] sd
LEFT JOIN mis.[Silver_Справочники.Кредиты] k
  ON k.[Кредиты ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
WHERE sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] <> 0
  AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= @DateFrom
GROUP BY k.[Кредиты Владелец], sd.[СуммыЗадолженностиПоПериодамПросрочки Дата];

CREATE UNIQUE NONCLUSTERED INDEX IX_MaxPastDays ON #MaxPastDays (OwnerID, ParDate);

-----------------------------------------------------
-- Step 2: Shadow Branch
-----------------------------------------------------
IF OBJECT_ID('tempdb..#ShadowBranch') IS NOT NULL DROP TABLE #ShadowBranch;
CREATE TABLE #ShadowBranch (
    CreditID     VARCHAR(36)   NOT NULL,
    BranchShadow NVARCHAR(100) NULL,
    Period       DATE          NULL
);

INSERT INTO #ShadowBranch
SELECT 
    [КредитыВТеневыхФилиалах Кредит ID],
    [КредитыВТеневыхФилиалах Филиал],
    [КредитыВТеневыхФилиалах Период]
FROM mis.[Silver_РегистрыСведений.КредитыВТеневыхФилиалах];

CREATE NONCLUSTERED INDEX IX_Shadow_Credit_Period ON #ShadowBranch (CreditID, Period);

-----------------------------------------------------
-- Step 3: Responsible / Employee
-----------------------------------------------------
IF OBJECT_ID('tempdb..#Responsible') IS NOT NULL DROP TABLE #Responsible;
CREATE TABLE #Responsible (
    CreditID   VARCHAR(36) NOT NULL,
    EmployeeID VARCHAR(36) NULL,
    BranchID   VARCHAR(36) NULL,
    Period     DATE        NULL
);

INSERT INTO #Responsible
SELECT
    [ОтветственныеПоКредитамВыданным Кредит ID],
    [ОтветственныеПоКредитамВыданным Кредитный Эксперт ID],
    [ОтветственныеПоКредитамВыданным Филиал ID],
    [ОтветственныеПоКредитамВыданным Период]
FROM mis.[Silver_РегистрыСведений.ОтветственныеПоКредитамВыданным];

CREATE NONCLUSTERED INDEX IX_Resp_Credit_Period ON #Responsible (CreditID, Period);

-----------------------------------------------------
-- Step 3.1: Employee Position
-----------------------------------------------------
IF OBJECT_ID('tempdb..#EmployeePos') IS NOT NULL DROP TABLE #EmployeePos;
CREATE TABLE #EmployeePos (
    EmployeeID VARCHAR(36) NOT NULL,
    PositionID VARCHAR(36) NULL,
    Period     DATE        NULL
);

INSERT INTO #EmployeePos
SELECT
    emp.[СотрудникиДанныеПоЗарплате Сотрудник ID],
    emp.[СотрудникиДанныеПоЗарплате Должность ID],
    emp.[СотрудникиДанныеПоЗарплате Период]
FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате] emp
WHERE emp.[СотрудникиДанныеПоЗарплате Период] >= DATEADD(year,-1,@DateFrom);

CREATE CLUSTERED INDEX CX_EmployeePos ON #EmployeePos (EmployeeID, Period);

-----------------------------------------------------
-- Step 4: IRR Data
-----------------------------------------------------
IF OBJECT_ID('tempdb..#IRR') IS NOT NULL DROP TABLE #IRR;
CREATE TABLE #IRR (
    CreditID   VARCHAR(36)   NOT NULL,
    IRR_Year   DECIMAL(18,6) NULL,
    IRR_Client DECIMAL(18,6) NULL,
    IRRDate    DATETIME2     NULL
);

INSERT INTO #IRR
SELECT
    [УстановкаДанныхКредита Кредит ID],
    [УстановкаДанныхКредита Внутренняя Норма Доходности Годовая],
    [УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая],
    [УстановкаДанныхКредита Дата]
FROM mis.[Silver_Документы.УстановкаДанныхКредита]
WHERE [УстановкаДанныхКредита Кредит ID] IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_IRR_Credit_Date ON #IRR (CreditID, IRRDate DESC);

-----------------------------------------------------
-- Step 5: Range helpers (inclusive start, exclusive end)
-----------------------------------------------------
;WITH RespRanges AS (
    SELECT CreditID, EmployeeID, BranchID,
           Period AS ValidFrom,
           LEAD(Period) OVER (PARTITION BY CreditID ORDER BY Period) AS ValidTo
    FROM #Responsible
),
ShadowRanges AS (
    SELECT CreditID, BranchShadow,
           Period AS ValidFrom,
           LEAD(Period) OVER (PARTITION BY CreditID ORDER BY Period) AS ValidTo
    FROM #ShadowBranch
),
EmpPosRanges AS (
    SELECT EmployeeID, PositionID,
           Period AS ValidFrom,
           LEAD(Period) OVER (PARTITION BY EmployeeID ORDER BY Period) AS ValidTo
    FROM #EmployeePos
)

-----------------------------------------------------
-- Final insert
-----------------------------------------------------
INSERT INTO mis.[2tbl_Gold_Fact_Sold_Par] WITH (TABLOCK)
(
    SoldDate, CreditID, SoldAmount, NumberOfOverdueDaysIFRS, IRR_Values,
    BranchShadow, EmployeeID, BranchID, EmployeePositionID,
    Par_0_IFRS, Par_30_IFRS, Par_60_IFRS, Par_90_IFRS,
    RestructuredCreditState, RestructuringReason, RestructuringDebtType
)
SELECT
    sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS SoldDate,
    sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
    sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] AS SoldAmount,
    sd.[СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки МСФО] AS NumberOfOverdueDaysIFRS,

    -- IRR calc (uses alias irr provided by OUTER APPLY below)
    ROUND(
        COALESCE(
            CASE WHEN irr.IRR_Year IS NOT NULL AND irr.IRR_Year < 100 THEN irr.IRR_Year ELSE irr.IRR_Client END, 0
        ) * sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит], 2
    ) AS IRR_Values,

    sh.BranchShadow,
    r.EmployeeID,
    r.BranchID,
    emp.PositionID,

    CASE WHEN mpd.MaxPastDays > 0  THEN sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE 0 END AS Par_0_IFRS,
    CASE WHEN mpd.MaxPastDays > 30 THEN sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE 0 END AS Par_30_IFRS,
    CASE WHEN mpd.MaxPastDays > 60 THEN sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE 0 END AS Par_60_IFRS,
    CASE WHEN mpd.MaxPastDays > 90 THEN sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE 0 END AS Par_90_IFRS,

    -- Last-known state / reason / type ON OR BEFORE SoldDate (no overlaps, no +1 day)
    rr_state.LastState AS RestructuredCreditState,
    rr_reason.LastReason AS RestructuringReason,
    rr_reason.LastDebtType AS RestructuringDebtType
FROM mis.[Silver_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] sd
JOIN mis.[Silver_Справочники.Кредиты] k
  ON k.[Кредиты ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
LEFT JOIN #MaxPastDays mpd
  ON mpd.OwnerID = k.[Кредиты Владелец]
 AND mpd.ParDate = sd.[СуммыЗадолженностиПоПериодамПросрочки Дата]
LEFT JOIN RespRanges r
  ON r.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
 AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата]
     BETWEEN r.ValidFrom AND DATEADD(DAY,-1, ISNULL(r.ValidTo,'9999-12-31'))
LEFT JOIN EmpPosRanges emp
  ON emp.EmployeeID = r.EmployeeID
 AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата]
     BETWEEN emp.ValidFrom AND DATEADD(DAY,-1, ISNULL(emp.ValidTo,'9999-12-31'))
LEFT JOIN ShadowRanges sh
  ON sh.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
 AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата]
     BETWEEN sh.ValidFrom AND DATEADD(DAY,-1, ISNULL(sh.ValidTo,'9999-12-31'))

-- IMPORTANT: pick latest IRR (this defines alias "irr" used in SELECT)
OUTER APPLY (
    SELECT TOP (1) i.IRR_Year, i.IRR_Client
    FROM #IRR i
    WHERE i.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
      AND CAST(i.IRRDate AS DATE) <= sd.[СуммыЗадолженностиПоПериодамПросрочки Дата]
    ORDER BY i.IRRDate DESC
) AS irr

-- Last-known state from Состояния… (inclusive)
OUTER APPLY (
    SELECT TOP (1)
        sr.[СостоянияРеструктурированныхКредитов Состояние Реструктурированного Кредита] AS LastState
    FROM [ATK].[dbo].[РегистрыСведений.СостоянияРеструктурированныхКредитов] sr
    WHERE sr.[СостоянияРеструктурированныхКредитов Кредит ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
      AND sr.[СостоянияРеструктурированныхКредитов Период] <= sd.[СуммыЗадолженностиПоПериодамПросрочки Дата]
    ORDER BY sr.[СостоянияРеструктурированныхКредитов Период] DESC
) rr_state

-- Last-known reason/type from РеструктурированныеКредиты (inclusive)
OUTER APPLY (
    SELECT TOP (1)
        rk.[РеструктурированныеКредиты Причина Реструктуризации] AS LastReason,
        rk.[РеструктурированныеКредиты Тип Реструктуризации Долга] AS LastDebtType
    FROM [ATK].[dbo].[РегистрыСведений.РеструктурированныеКредиты] rk
    WHERE rk.[РеструктурированныеКредиты Кредит ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
      AND rk.[РеструктурированныеКредиты Период] <= sd.[СуммыЗадолженностиПоПериодамПросрочки Дата]
    ORDER BY rk.[РеструктурированныеКредиты Период] DESC
) rr_reason

WHERE sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] <> 0
  AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= @DateFrom;
  --AND sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID] = '812100155D65040111ECC06922E57355';

-----------------------------------------------------
-- Final: Columnstore Index + cleanup
-----------------------------------------------------
CREATE CLUSTERED COLUMNSTORE INDEX CCSI_2tbl_Gold_Fact_Sold_Par
ON mis.[2tbl_Gold_Fact_Sold_Par];

DROP TABLE IF EXISTS #MaxPastDays, #ShadowBranch, #Responsible, #IRR, #EmployeePos;

-----------------------------------------------------
-- (Optional) helpful indexes for APPLY lookups:
-- CREATE NONCLUSTERED INDEX IX_Sost_Credit_Period
--   ON [ATK].[dbo].[РегистрыСведений.СостоянияРеструктурированныхКредитов]
--   ( [СостоянияРеструктурированныхКредитов Кредит ID],
--     [СостоянияРеструктурированныхКредитов Период] DESC );
-- CREATE NONCLUSTERED INDEX IX_RK_Credit_Period
--   ON [ATK].[dbo].[РегистрыСведений.РеструктурированныеКредиты]
--   ( [РеструктурированныеКредиты Кредит ID],
--     [РеструктурированныеКредиты Период] DESC );
-----------------------------------------------------
