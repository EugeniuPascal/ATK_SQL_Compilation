USE [ATK];
SET NOCOUNT ON;

DECLARE @DateFrom DATE = '2024-01-01';

-----------------------------------------------------
-- Drop & recreate main GOLD table
-----------------------------------------------------
DROP TABLE IF EXISTS mis.[2tbl_Gold_Fact_Sold_Par];

CREATE TABLE mis.[2tbl_Gold_Fact_Sold_Par] (
    SoldDate      DATE         NOT NULL,
    CreditID      VARCHAR(36)  NOT NULL,
    SoldAmount    DECIMAL(18,2) NULL,
    IRR_Values    DECIMAL(18,6) NULL,
    BranchShadow  NVARCHAR(100) NULL,
    ExpertID      VARCHAR(36) NULL,
    BranchID      VARCHAR(36) NULL,
    Par_0_IFRS    DECIMAL(18,6) NULL,
    Par_30_IFRS   DECIMAL(18,6) NULL,
    Par_60_IFRS   DECIMAL(18,6) NULL,
    Par_90_IFRS   DECIMAL(18,6) NULL
)
WITH (DATA_COMPRESSION = PAGE);

-----------------------------------------------------
-- Step 1: Max Past Days
-----------------------------------------------------
IF OBJECT_ID('tempdb..#MaxPastDays') IS NOT NULL DROP TABLE #MaxPastDays;
SELECT 
    k.[Кредиты Владелец] AS OwnerID,
    sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS ParDate,
    MAX(sd.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого]) AS MaxPastDays
INTO #MaxPastDays
FROM mis.[Silver_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] sd
JOIN mis.[Silver_Справочники.Кредиты] k
  ON k.[Кредиты ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
WHERE sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] IS NOT NULL
  AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= @DateFrom
GROUP BY k.[Кредиты Владелец], sd.[СуммыЗадолженностиПоПериодамПросрочки Дата];

CREATE CLUSTERED INDEX IX_MaxPastDays_Owner_ParDate ON #MaxPastDays (OwnerID, ParDate);

-----------------------------------------------------
-- Step 2: Shadow Branch latest per CreditID
-----------------------------------------------------
IF OBJECT_ID('tempdb..#ShadowBranchLatest') IS NOT NULL DROP TABLE #ShadowBranchLatest;
;WITH ShadowRanked AS (
    SELECT
        CreditID = x.[КредитыВТеневыхФилиалах Кредит ID],
        BranchShadow = x.[КредитыВТеневыхФилиалах Филиал],
        Period = x.[КредитыВТеневыхФилиалах Период],
        ROW_NUMBER() OVER(PARTITION BY x.[КредитыВТеневыхФилиалах Кредит ID] ORDER BY x.[КредитыВТеневыхФилиалах Период] DESC) AS rn
    FROM mis.[Silver_РегистрыСведений.КредитыВТеневыхФилиалах] x
) 
SELECT CreditID, BranchShadow, Period
INTO #ShadowBranchLatest
FROM ShadowRanked
WHERE rn = 1;

CREATE CLUSTERED INDEX IX_Shadow_Credit ON #ShadowBranchLatest(CreditID);

-----------------------------------------------------
-- Step 3: Responsible / Expert latest per CreditID
-----------------------------------------------------
IF OBJECT_ID('tempdb..#ResponsibleLatest') IS NOT NULL DROP TABLE #ResponsibleLatest;
;WITH RespRanked AS (
    SELECT
        CreditID = r.[ОтветственныеПоКредитамВыданным Кредит ID],
        ExpertID = r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID],
        BranchID = r.[ОтветственныеПоКредитамВыданным Филиал ID],
        Period = r.[ОтветственныеПоКредитамВыданным Период],
        ROW_NUMBER() OVER(PARTITION BY r.[ОтветственныеПоКредитамВыданным Кредит ID] ORDER BY r.[ОтветственныеПоКредитамВыданным Период] DESC) AS rn
    FROM mis.[Silver_РегистрыСведений.ОтветственныеПоКредитамВыданным] r
) 
SELECT CreditID, ExpertID, BranchID, Period
INTO #ResponsibleLatest
FROM RespRanked
WHERE rn = 1;

CREATE CLUSTERED INDEX IX_Resp_Credit ON #ResponsibleLatest(CreditID);

-----------------------------------------------------
-- Step 4: IRR latest per CreditID
-----------------------------------------------------
IF OBJECT_ID('tempdb..#IRRLatest') IS NOT NULL DROP TABLE #IRRLatest;
;WITH IRRRanked AS (
    SELECT
        CreditID = i.[УстановкаДанныхКредита Кредит ID],
        IRR_Year = i.[УстановкаДанныхКредита Внутренняя Норма Доходности Годовая],
        IRR_Client = i.[УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая],
        IRRDate = i.[УстановкаДанныхКредита Дата],
        ROW_NUMBER() OVER(PARTITION BY i.[УстановкаДанныхКредита Кредит ID] ORDER BY i.[УстановкаДанныхКредита Дата] DESC) AS rn
    FROM mis.[Silver_Документы.УстановкаДанныхКредита] i
) 
SELECT CreditID, IRR_Year, IRR_Client, IRRDate
INTO #IRRLatest
FROM IRRRanked
WHERE rn = 1;

CREATE CLUSTERED INDEX IX_IRR_Credit ON #IRRLatest(CreditID);

-----------------------------------------------------
-- Step 5: Main Insert
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
    
    CASE 
        WHEN sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] IS NOT NULL
        THEN ROUND(
            COALESCE(
                CASE 
                    WHEN irr.IRR_Year IS NOT NULL AND irr.IRR_Year < 100 THEN irr.IRR_Year
                    ELSE irr.IRR_Client
                END,
                0
            )
            * sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] / 100.0, 2
        )
        ELSE NULL
    END AS IRR_Values,
    
    sh.BranchShadow,
    r.ExpertID,
    r.BranchID,
    
    CASE WHEN mpd.MaxPastDays > 0  THEN sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE NULL END AS Par_0_IFRS,
    CASE WHEN mpd.MaxPastDays > 30 THEN sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE NULL END AS Par_30_IFRS,
    CASE WHEN mpd.MaxPastDays > 60 THEN sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE NULL END AS Par_60_IFRS,
    CASE WHEN mpd.MaxPastDays > 90 THEN sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE NULL END AS Par_90_IFRS

FROM mis.[Silver_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] sd
JOIN mis.[Silver_Справочники.Кредиты] k
  ON k.[Кредиты ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]

-- Join MaxPastDays
LEFT JOIN #MaxPastDays mpd
  ON mpd.OwnerID = k.[Кредиты Владелец]
 AND mpd.ParDate = sd.[СуммыЗадолженностиПоПериодамПросрочки Дата]

-- Join latest ShadowBranch
LEFT JOIN #ShadowBranchLatest sh
  ON sh.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]

-- Join latest Responsible
LEFT JOIN #ResponsibleLatest r
  ON r.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]

-- Join latest IRR
LEFT JOIN #IRRLatest irr
  ON irr.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]

-- Include zero balance for active credits
LEFT JOIN mis.[Silver_РегистрыСведений.СтатусыКредитовВыданных] cs
  ON cs.[СтатусыКредитовВыданных Кредит ID] = k.[Кредиты ID]

WHERE 
    (
        sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] IS NOT NULL
        OR 
        (
            sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] = 0
            AND cs.[СтатусыКредитовВыданных Статус] = 'Active'
        )
    )
    AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= @DateFrom;

-----------------------------------------------------
-- Columnstore
-----------------------------------------------------
CREATE CLUSTERED COLUMNSTORE INDEX CCSI_2tbl_Gold_Fact_Sold_Par
ON mis.[2tbl_Gold_Fact_Sold_Par];

-- Drop temp tables
DROP TABLE IF EXISTS #MaxPastDays, #ShadowBranchLatest, #ResponsibleLatest, #IRRLatest;
