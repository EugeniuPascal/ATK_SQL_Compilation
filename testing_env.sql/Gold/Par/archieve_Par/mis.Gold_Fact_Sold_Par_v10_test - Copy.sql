USE [ATK];
SET NOCOUNT ON;

DECLARE @DateFrom DATE = '2023-09-01';

-----------------------------------------------------
-- Drop & recreate main GOLD table with single Par column
-----------------------------------------------------
DROP TABLE IF EXISTS mis.[Gold_Fact_Sold_Par];

CREATE TABLE mis.[Gold_Fact_Sold_Par] (
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
-- Step 1: Prepare temp tables
-----------------------------------------------------

-- Shadow Branch
IF OBJECT_ID('tempdb..#ShadowBranch') IS NOT NULL DROP TABLE #ShadowBranch;
SELECT 
    [КредитыВТеневыхФилиалах Кредит ID] AS CreditID,
    [КредитыВТеневыхФилиалах Филиал] AS BranchShadow,
    [КредитыВТеневыхФилиалах Период] AS Period
INTO #ShadowBranch
FROM mis.[Bronze_РегистрыСведений.КредитыВТеневыхФилиалах];

CREATE NONCLUSTERED INDEX IX_Shadow_Credit_Period ON #ShadowBranch (CreditID, Period);

-- MaxDays per client per date
IF OBJECT_ID('tempdb..#MaxDays') IS NOT NULL DROP TABLE #MaxDays;
SELECT
    [СуммыЗадолженностиПоПериодамПросрочки Клиент ID] AS ClientID,
    [СуммыЗадолженностиПоПериодамПросрочки Дата] AS SoldDate,
    MAX([СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки Кредит]) AS MaxDaysPerClientDay
INTO #MaxDays
FROM mis.[Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки]
GROUP BY
    [СуммыЗадолженностиПоПериодамПросрочки Клиент ID],
    [СуммыЗадолженностиПоПериодамПросрочки Дата];

CREATE NONCLUSTERED INDEX IX_MaxDays_Client_SoldDate ON #MaxDays(ClientID, SoldDate);

-- Responsible
IF OBJECT_ID('tempdb..#Responsible') IS NOT NULL DROP TABLE #Responsible;
SELECT
    [ОтветственныеПоКредитамВыданным Кредит ID] AS CreditID,
    [ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS EmployeeID,
    [ОтветственныеПоКредитамВыданным Филиал ID] AS BranchID,
    [ОтветственныеПоКредитамВыданным Период] AS Period
INTO #Responsible
FROM mis.[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным];

CREATE NONCLUSTERED INDEX IX_Resp_Credit_Period ON #Responsible (CreditID, Period);

-- Employee Position
IF OBJECT_ID('tempdb..#EmployeePos') IS NOT NULL DROP TABLE #EmployeePos;
SELECT
    [СотрудникиДанныеПоЗарплате Сотрудник ID] AS EmployeeID,
    [СотрудникиДанныеПоЗарплате Должность ID] AS PositionID,
    [СотрудникиДанныеПоЗарплате Период] AS Period
INTO #EmployeePos
FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате]
WHERE [СотрудникиДанныеПоЗарплате Период] >= DATEADD(year,-1,@DateFrom);

CREATE CLUSTERED INDEX CX_EmployeePos_Emp_Period ON #EmployeePos (EmployeeID, Period);

-- IRR
IF OBJECT_ID('tempdb..#IRR') IS NOT NULL DROP TABLE #IRR;
SELECT
    [УстановкаДанныхКредита Кредит ID] AS CreditID,
    [УстановкаДанныхКредита Внутренняя Норма Доходности Годовая] AS IRR_Year,
    [УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая] AS IRR_Client,
    [УстановкаДанныхКредита Дата] AS IRRDate
INTO #IRR
FROM mis.[Bronze_Документы.УстановкаДанныхКредита]
WHERE [УстановкаДанныхКредита Кредит ID] IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_IRR_Credit_Date ON #IRR (CreditID, IRRDate DESC);

-----------------------------------------------------
-- Step 2: Insert Gold Fact with closest-period logic
-----------------------------------------------------
INSERT INTO mis.[Gold_Fact_Sold_Par] WITH (TABLOCK)
(
    SoldDate, ClientID, CreditID, SoldAmount, NumberOfOverdueDaysIFRS, IRR_Values,
    BranchShadow, EmployeeID, BranchID, EmployeePositionID, Par
)
SELECT
    sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS SoldDate,
    sd.[СуммыЗадолженностиПоПериодамПросрочки Клиент ID] AS ClientID,
    sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
    sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] AS SoldAmount,
    sd.[СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки МСФО] AS NumberOfOverdueDaysIFRS,

    -- IRR Values
    ROUND(
        COALESCE(
            CASE WHEN irr.IRR_Year IS NOT NULL AND irr.IRR_Year < 100 THEN irr.IRR_Year
                 ELSE irr.IRR_Client
            END, 0
        ) * sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит], 2
    ) AS IRR_Values,

    -- Branch Shadow
    sh.BranchShadow,

    -- Employee Responsible
    r.EmployeeID,
    r.BranchID,

    -- Employee Position
    empPos.PositionID AS EmployeePositionID,

    -- Single Par column
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

FROM mis.[Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] sd

-- Responsible closest period
OUTER APPLY (
    SELECT TOP (1) EmployeeID, BranchID
    FROM #Responsible rr
    WHERE rr.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
    ORDER BY 
        CASE WHEN rr.Period <= sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] THEN 0 ELSE 1 END,
        ABS(DATEDIFF(DAY, rr.Period, sd.[СуммыЗадолженностиПоПериодамПросрочки Дата])) ASC
) AS r

-- Employee Position closest period
OUTER APPLY (
    SELECT TOP (1) PositionID
    FROM #EmployeePos ep
    WHERE ep.EmployeeID = r.EmployeeID
    ORDER BY 
        CASE WHEN ep.Period <= sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] THEN 0 ELSE 1 END,
        ABS(DATEDIFF(DAY, ep.Period, sd.[СуммыЗадолженностиПоПериодамПросрочки Дата])) ASC
) AS empPos

-- Shadow Branch closest period
OUTER APPLY (
    SELECT TOP (1) BranchShadow
    FROM #ShadowBranch sb
    WHERE sb.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
    ORDER BY 
        CASE WHEN sb.Period <= sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] THEN 0 ELSE 1 END,
        ABS(DATEDIFF(DAY, sb.Period, sd.[СуммыЗадолженностиПоПериодамПросрочки Дата])) ASC
) AS sh

-- MaxDays join
LEFT JOIN #MaxDays md
    ON md.ClientID = sd.[СуммыЗадолженностиПоПериодамПросрочки Клиент ID]
   AND md.SoldDate = sd.[СуммыЗадолженностиПоПериодамПросрочки Дата]

-- IRR lookup
OUTER APPLY (
    SELECT TOP (1) i.IRR_Year, i.IRR_Client
    FROM #IRR i
    WHERE i.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
      AND CAST(i.IRRDate AS DATE) <= CAST(sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS DATE)
    ORDER BY i.IRRDate DESC
) AS irr

WHERE sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] <> 0
  AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= @DateFrom
  AND [СуммыЗадолженностиПоПериодамПросрочки Кредит ID] = 'B7FE00155D65140C11F0B6338A70F584';

-----------------------------------------------------
-- Columnstore
-----------------------------------------------------
CREATE CLUSTERED COLUMNSTORE INDEX CCSI_Gold_Fact_Sold_Par
ON mis.[Gold_Fact_Sold_Par];

-- Drop temp tables
DROP TABLE IF EXISTS #ShadowBranch, #Responsible, #EmployeePos, #IRR, #MaxDays;
