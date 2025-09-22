USE [ATK];
SET NOCOUNT ON;

DECLARE @DateFrom DATE = '2024-01-01';

-- Drop & recreate main GOLD table
DROP TABLE IF EXISTS mis.[2tbl_Gold_Fact_Sold_Par];

CREATE TABLE mis.[2tbl_Gold_Fact_Sold_Par] (
    SoldDate      DATE         NOT NULL,
    CreditID      VARCHAR(36)  NOT NULL,
    SoldAmount    DECIMAL(18,2) NULL,
    IRR_Values    DECIMAL(18,6) NULL,
    BranchShadow  NVARCHAR(100) NULL,
    ExpertID      VARCHAR(36)  NULL,
    BranchID      VARCHAR(36)  NULL,
    Par_0_IFRS    DECIMAL(18,6) NULL,
    Par_30_IFRS   DECIMAL(18,6) NULL,
    Par_60_IFRS   DECIMAL(18,6) NULL,
    Par_90_IFRS   DECIMAL(18,6) NULL
)
WITH (DATA_COMPRESSION = PAGE);

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
JOIN mis.[Silver_Справочники.Кредиты] k
  ON k.[Кредиты ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
WHERE sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] > 0
  AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= @DateFrom
GROUP BY k.[Кредиты Владелец], sd.[СуммыЗадолженностиПоПериодамПросрочки Дата];

CREATE UNIQUE NONCLUSTERED INDEX IX_MaxPastDays_Owner_ParDate ON #MaxPastDays (OwnerID, ParDate);

-----------------------------------------------------
-- Step 2: Shadow Branch (explicit temp table)
-----------------------------------------------------
IF OBJECT_ID('tempdb..#ShadowBranch') IS NOT NULL DROP TABLE #ShadowBranch;
CREATE TABLE #ShadowBranch (
    CreditID   VARCHAR(36)  NOT NULL,
    BranchShadow NVARCHAR(100) NULL,
    Period     DATE         NULL
);

INSERT INTO #ShadowBranch (CreditID, BranchShadow, Period)
SELECT 
    x.[КредитыВТеневыхФилиалах Кредит ID] AS CreditID,
    x.[КредитыВТеневыхФилиалах Филиал] AS BranchShadow,
    x.[КредитыВТеневыхФилиалах Период] AS Period
FROM mis.[Silver_РегистрыСведений.КредитыВТеневыхФилиалах] x;

CREATE NONCLUSTERED INDEX IX_Shadow_Credit_Period ON #ShadowBranch (CreditID, Period);

-----------------------------------------------------
-- Step 3: Responsible / Expert (explicit temp table)
-----------------------------------------------------
IF OBJECT_ID('tempdb..#Responsible') IS NOT NULL DROP TABLE #Responsible;
CREATE TABLE #Responsible (
    CreditID VARCHAR(36) NOT NULL,
    ExpertID VARCHAR(36) NULL,
    BranchID VARCHAR(36) NULL,
    Period   DATE        NULL
);

INSERT INTO #Responsible (CreditID, ExpertID, BranchID, Period)
SELECT
    r.[ОтветственныеПоКредитамВыданным Кредит ID] AS CreditID,
    r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS ExpertID,
    r.[ОтветственныеПоКредитамВыданным Филиал ID] AS BranchID,
    r.[ОтветственныеПоКредитамВыданным Период] AS Period
FROM mis.[Silver_РегистрыСведений.ОтветственныеПоКредитамВыданным] r;

CREATE NONCLUSTERED INDEX IX_Resp_Credit_Period ON #Responsible (CreditID, Period);

-----------------------------------------------------
-- Step 4: IRR last (explicit temp table)
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
FROM mis.[Silver_Документы.УстановкаДанныхКредита] i;

CREATE NONCLUSTERED INDEX IX_IRR_Credit_Date ON #IRR (CreditID, IRRDate);

-----------------------------------------------------
-- Step 5: Main Insert (single latest responsible)
-----------------------------------------------------
INSERT INTO mis.[2tbl_Gold_Fact_Sold_Par] WITH (TABLOCK)
(
    SoldDate, CreditID, SoldAmount, IRR_Values, BranchShadow, ExpertID, BranchID,
    Par_0_IFRS, Par_30_IFRS, Par_60_IFRS, Par_90_IFRS
)
SELECT
    sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS SoldDate,
    sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
    sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] AS SoldAmount,
    
-- IRR Values with conditional logic
ROUND(
    COALESCE(
        CASE 
            WHEN ir.IRR_Year IS NOT NULL AND ir.IRR_Year < 100 
                THEN ir.IRR_Year
            ELSE ir.IRR_Client
        END,
        0
    )
    * sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит], 2
) AS IRR_Values,
    
    -- Shadow Branch (latest <= SoldDate)
    sh.BranchShadow,
    
    -- ExpertID from latest responsible
    r.ExpertID,
    
    r.BranchID AS BranchID,
    
    -- ParNas IFRS
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

-- Shadow Branch: pick latest shadow row <= SoldDate
OUTER APPLY (
    SELECT TOP(1) sb.BranchShadow
    FROM #ShadowBranch sb
    WHERE sb.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
      AND sb.Period <= EOMONTH(sd.[СуммыЗадолженностиПоПериодамПросрочки Дата])
    ORDER BY sb.Period DESC
) sh

-- Responsible: pick latest responsible row <= SoldDate
OUTER APPLY (
    SELECT TOP(1) rr.ExpertID, rr.BranchID
    FROM #Responsible rr
    WHERE rr.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
      AND rr.Period <= EOMONTH(sd.[СуммыЗадолженностиПоПериодамПросрочки Дата])
    ORDER BY rr.Period DESC
) r

-- IRR latest
OUTER APPLY (
    SELECT TOP(1) i.IRR_Year, i.IRR_Client
    FROM #IRR i
    WHERE i.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
    ORDER BY i.IRRDate DESC
) ir

WHERE sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] > 0
  AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= @DateFrom;

-----------------------------------------------------
-- Columnstore
-----------------------------------------------------
CREATE CLUSTERED COLUMNSTORE INDEX CCSI_2tbl_Gold_Fact_Sold_Par
ON mis.[2tbl_Gold_Fact_Sold_Par];

-- Drop temp tables
DROP TABLE IF EXISTS #MaxPastDays, #ShadowBranch, #Responsible, #IRR;



