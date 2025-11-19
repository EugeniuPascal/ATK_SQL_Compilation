USE [ATK];
SET NOCOUNT ON;

DECLARE @DateFrom DATE = '2023-09-01';

-----------------------------------------------------
-- Drop & recreate main GOLD table with single Par column
-----------------------------------------------------
DROP TABLE IF EXISTS mis.[Gold_Fact_Sold_Par];

CREATE TABLE mis.[Gold_Fact_Sold_Par] 
(
    SoldDate                DATE         NOT NULL,	
	ClientID                VARCHAR(36)  NULL,
    CreditID                VARCHAR(36)  NOT NULL,
    SoldAmount              DECIMAL(18,2) NULL,
    NumberOfOverdueDaysIFRS DECIMAL(15,2) NULL,
    IRR_Values              DECIMAL(18,6) NULL,
    BranchShadow            NVARCHAR(100) NULL,
    EmployeeID              VARCHAR(36)  NULL,
    BranchID                VARCHAR(36)  NULL,
    EmployeePositionID      VARCHAR(36)  NULL,
    Par                     NVARCHAR(20) NULL
) WITH (DATA_COMPRESSION = PAGE);

-----------------------------------------------------
-- Step 1: Shadow Branch, Responsible, EmployeePos, IRR temp tables
-- NOTE: cast periods/dates to DATE to avoid time-of-day mismatches
-----------------------------------------------------

-- Shadow Branch
IF OBJECT_ID('tempdb..#ShadowBranch') IS NOT NULL DROP TABLE #ShadowBranch;
SELECT 
    [КредитыВТеневыхФилиалах Кредит ID] AS CreditID,
    [КредитыВТеневыхФилиалах Филиал] AS BranchShadow,
    CAST([КредитыВТеневыхФилиалах Период] AS DATE) AS Period
INTO #ShadowBranch
FROM mis.[Bronze_РегистрыСведений.КредитыВТеневыхФилиалах];

CREATE NONCLUSTERED INDEX IX_Shadow_Credit_Period ON #ShadowBranch (CreditID, Period);

-- MaxDays per client per date (SoldDate already as DATE)
IF OBJECT_ID('tempdb..#MaxDays') IS NOT NULL DROP TABLE #MaxDays;
SELECT
    [СуммыЗадолженностиПоПериодамПросрочки Клиент ID] AS ClientID,
    CAST([СуммыЗадолженностиПоПериодамПросрочки Дата] AS DATE) AS SoldDate,
    MAX([СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого]) AS MaxDaysPerClientDay
INTO #MaxDays
FROM mis.[Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки]
GROUP BY
    [СуммыЗадолженностиПоПериодамПросрочки Клиент ID],
    CAST([СуммыЗадолженностиПоПериодамПросрочки Дата] AS DATE);

CREATE NONCLUSTERED INDEX IX_MaxDays_Client_SoldDate ON #MaxDays(ClientID, SoldDate);

-- Responsible (cast Period -> DATE)
IF OBJECT_ID('tempdb..#Responsible') IS NOT NULL DROP TABLE #Responsible;
SELECT
    [ОтветственныеПоКредитамВыданным Кредит ID] AS CreditID,
    [ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS EmployeeID,
    [ОтветственныеПоКредитамВыданным Филиал ID] AS BranchID,
    CAST([ОтветственныеПоКредитамВыданным Период] AS DATE) AS Period
INTO #Responsible
FROM mis.[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным];

CREATE NONCLUSTERED INDEX IX_Resp_Credit_Period ON #Responsible (CreditID, Period);

-- Employee Position (cast Period -> DATE)
IF OBJECT_ID('tempdb..#EmployeePos') IS NOT NULL DROP TABLE #EmployeePos;
SELECT
    [СотрудникиДанныеПоЗарплате Сотрудник ID] AS EmployeeID,
    [СотрудникиДанныеПоЗарплате Должность ID] AS PositionID,
    CAST([СотрудникиДанныеПоЗарплате Период] AS DATE) AS Period
INTO #EmployeePos
FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате]
WHERE CAST([СотрудникиДанныеПоЗарплате Период] AS DATE) >= DATEADD(YEAR,-1,@DateFrom);

CREATE CLUSTERED INDEX CX_EmployeePos_Emp_Period ON #EmployeePos (EmployeeID, Period);

-- IRR (cast to DATE)
IF OBJECT_ID('tempdb..#IRR') IS NOT NULL DROP TABLE #IRR;
SELECT
    [УстановкаДанныхКредита Кредит ID] AS CreditID,
    [УстановкаДанныхКредита Внутренняя Норма Доходности Годовая] AS IRR_Year,
    [УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая] AS IRR_Client,
    CAST([УстановкаДанныхКредита Дата] AS DATE) AS IRRDate
INTO #IRR
FROM mis.[Bronze_Документы.УстановкаДанныхКредита]
WHERE [УстановкаДанныхКредита Кредит ID] IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_IRR_Credit_Date ON #IRR (CreditID, IRRDate DESC);

-----------------------------------------------------
-- Step 2: SourceData (pre-cast SoldDate) and insert Gold Fact
-----------------------------------------------------
;WITH SourceData AS (
    SELECT
        CAST([СуммыЗадолженностиПоПериодамПросрочки Дата] AS DATE) AS SoldDate,
        [СуммыЗадолженностиПоПериодамПросрочки Клиент ID] AS ClientID,
        [СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
        [СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] AS SoldAmount,
        [СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки МСФО] AS NumberOfOverdueDaysIFRS
    FROM mis.[Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки]
    WHERE [СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] <> 0
      AND CAST([СуммыЗадолженностиПоПериодамПросрочки Дата] AS DATE) >= @DateFrom
)
INSERT INTO mis.[Gold_Fact_Sold_Par] WITH (TABLOCK)
(
    SoldDate, ClientID, CreditID, SoldAmount, NumberOfOverdueDaysIFRS, IRR_Values,
    BranchShadow, EmployeeID, BranchID, EmployeePositionID, Par
)
SELECT
    sd.SoldDate,
    sd.ClientID,
    sd.CreditID,
    sd.SoldAmount,
    sd.NumberOfOverdueDaysIFRS,

    -- IRR Values (latest IRR where IRRDate <= SoldDate)
    ROUND(
        COALESCE(
            CASE WHEN irr.IRR_Year IS NOT NULL AND irr.IRR_Year < 100 THEN irr.IRR_Year
                 ELSE irr.IRR_Client
            END, 0
        ) * sd.SoldAmount, 2
    ) AS IRR_Values,

    -- BranchShadow: latest shadow row with Period <= SoldDate
    sh.BranchShadow,

    -- Employee & Branch: latest responsible row with Period <= SoldDate
    r.EmployeeID,
    r.BranchID,

    -- EmployeePositionID: latest employee position row (by Period) for r.EmployeeID where Period <= SoldDate
    empPos.PositionID AS EmployeePositionID,

    -- Par by MaxDays (max days per client per date)
    CASE
        WHEN md.MaxDaysPerClientDay BETWEEN 1   AND 30  THEN N'Par0'
        WHEN md.MaxDaysPerClientDay BETWEEN 31  AND 60  THEN N'Par30'
        WHEN md.MaxDaysPerClientDay BETWEEN 61  AND 90  THEN N'Par60'
        WHEN md.MaxDaysPerClientDay BETWEEN 91  AND 180 THEN N'Par90'
        WHEN md.MaxDaysPerClientDay BETWEEN 181 AND 270 THEN N'Par180'
        WHEN md.MaxDaysPerClientDay BETWEEN 271 AND 360 THEN N'Par270'
        WHEN md.MaxDaysPerClientDay > 360           THEN N'Par360'
        ELSE NULL
    END AS Par

FROM SourceData sd


-- latest Responsible row for the credit where Period <= SoldDate
OUTER APPLY (
    SELECT TOP (1)
        rr.EmployeeID,
        rr.BranchID
    FROM #Responsible rr
    WHERE rr.CreditID = sd.CreditID
      AND rr.Period <= sd.SoldDate
    ORDER BY rr.Period DESC
) AS r

-- latest Employee position for the picked employee where Period <= SoldDate
OUTER APPLY (
    SELECT TOP (1) ep.PositionID
    FROM #EmployeePos ep
    WHERE ep.EmployeeID = r.EmployeeID
      AND ep.Period <= sd.SoldDate
    ORDER BY ep.Period DESC
) AS empPos

-- latest ShadowBranch for credit where Period <= SoldDate
OUTER APPLY (
    SELECT TOP (1) sb.BranchShadow
    FROM #ShadowBranch sb
    WHERE sb.CreditID = sd.CreditID
      AND sb.Period <= sd.SoldDate
    ORDER BY sb.Period DESC
) AS sh

-- MaxDays join (exact sold date)
LEFT JOIN #MaxDays md
    ON md.ClientID = sd.ClientID
   AND md.SoldDate = sd.SoldDate

-- IRR lookup (already used above via outer apply in IRR_Values)
OUTER APPLY (
    SELECT TOP (1) i.IRR_Year, i.IRR_Client
    FROM #IRR i
    WHERE i.CreditID = sd.CreditID
      AND i.IRRDate <= sd.SoldDate
    ORDER BY i.IRRDate DESC
) AS irr
;
-----------------------------------------------------
-- Columnstore
-----------------------------------------------------
CREATE CLUSTERED COLUMNSTORE INDEX CCSI_Gold_Fact_Sold_Par
ON mis.[Gold_Fact_Sold_Par];

-- Drop temp tables
DROP TABLE IF EXISTS #ShadowBranch, #Responsible, #EmployeePos, #IRR, #MaxDays;
