USE [ATK];
GO
SET NOCOUNT ON;

DECLARE @DateFrom DATE = '2024-01-01';

IF OBJECT_ID('mis.[2tbl_Gold_Fact_Sold_Par]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Fact_Sold_Par];

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
-- Step 1: MaxPastDays + PAR calculation
-----------------------------------------------------
IF OBJECT_ID('tempdb..#MaxPastDays') IS NOT NULL DROP TABLE #MaxPastDays;

;WITH cte AS (
    SELECT 
        k.[Кредиты Владелец] AS OwnerID,
        sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS SoldDate,
        SUM(CASE WHEN sd.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого] > 0 
            THEN sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE 0 END) AS Par_0_IFRS,
        SUM(CASE WHEN sd.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого] > 30 
            THEN sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE 0 END) AS Par_30_IFRS,
        SUM(CASE WHEN sd.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого] > 60 
            THEN sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE 0 END) AS Par_60_IFRS,
        SUM(CASE WHEN sd.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого] > 90 
            THEN sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE 0 END) AS Par_90_IFRS
    FROM mis.[Silver_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] sd
    JOIN mis.[Silver_Справочники.Кредиты] k
      ON k.[Кредиты ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
    WHERE sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= @DateFrom
      AND sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] <> 0
    GROUP BY k.[Кредиты Владелец], sd.[СуммыЗадолженностиПоПериодамПросрочки Дата]
)
SELECT * INTO #MaxPastDays FROM cte;

CREATE UNIQUE CLUSTERED INDEX CX_MaxPastDays ON #MaxPastDays (OwnerID, SoldDate);

-----------------------------------------------------
-- Step 2: Latest Shadow Branch
-----------------------------------------------------
IF OBJECT_ID('tempdb..#ShadowBranch') IS NOT NULL DROP TABLE #ShadowBranch;

;WITH cte AS (
    SELECT *,
        ROW_NUMBER() OVER(PARTITION BY [КредитыВТеневыхФилиалах Кредит ID]
                          ORDER BY [КредитыВТеневыхФилиалах Период] DESC) AS rn
    FROM mis.[Silver_РегистрыСведений.КредитыВТеневыхФилиалах]
)
SELECT
    [КредитыВТеневыхФилиалах Кредит ID] AS CreditID,
    [КредитыВТеневыхФилиалах Филиал] AS BranchShadow
INTO #ShadowBranch
FROM cte WHERE rn = 1;

CREATE CLUSTERED INDEX CX_ShadowBranch ON #ShadowBranch (CreditID);

-----------------------------------------------------
-- Step 3: Responsible + Position
-----------------------------------------------------
IF OBJECT_ID('tempdb..#Responsible') IS NOT NULL DROP TABLE #Responsible;

;WITH cte AS (
    SELECT *,
        ROW_NUMBER() OVER(PARTITION BY [ОтветственныеПоКредитамВыданным Кредит ID]
                          ORDER BY [ОтветственныеПоКредитамВыданным Период] DESC) AS rn
    FROM mis.[Silver_РегистрыСведений.ОтветственныеПоКредитамВыданным]
)
SELECT
    [ОтветственныеПоКредитамВыданным Кредит ID] AS CreditID,
    [ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS EmployeeID,
    [ОтветственныеПоКредитамВыданным Филиал ID] AS BranchID
INTO #Responsible
FROM cte WHERE rn = 1;

CREATE CLUSTERED INDEX CX_Responsible ON #Responsible (CreditID);

-----------------------------------------------------
-- Step 4: Employee Positions
-----------------------------------------------------
IF OBJECT_ID('tempdb..#EmployeePos') IS NOT NULL DROP TABLE #EmployeePos;

;WITH cte AS (
    SELECT *,
        ROW_NUMBER() OVER(PARTITION BY [СотрудникиДанныеПоЗарплате Сотрудник ID]
                          ORDER BY [СотрудникиДанныеПоЗарплате Период] DESC) AS rn
    FROM mis.[Silver_РегистрыСведений.СотрудникиДанныеПоЗарплате]
)
SELECT
    [СотрудникиДанныеПоЗарплате Сотрудник ID] AS EmployeeID,
    [СотрудникиДанныеПоЗарплате Должность ID] AS PositionID
INTO #EmployeePos
FROM cte WHERE rn = 1;

CREATE CLUSTERED INDEX CX_EmployeePos ON #EmployeePos (EmployeeID);

-----------------------------------------------------
-- Step 5: Latest IRR
-----------------------------------------------------
IF OBJECT_ID('tempdb..#IRR') IS NOT NULL DROP TABLE #IRR;

;WITH cte AS (
    SELECT *,
        ROW_NUMBER() OVER(PARTITION BY [УстановкаДанныхКредита Кредит ID]
                          ORDER BY [УстановкаДанныхКредита Дата] DESC) AS rn
    FROM mis.[Silver_Документы.УстановкаДанныхКредита]
)
SELECT
    [УстановкаДанныхКредита Кредит ID] AS CreditID,
    [УстановкаДанныхКредита Внутренняя Норма Доходности Годовая] AS IRR_Year,
    [УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая] AS IRR_Client
INTO #IRR
FROM cte WHERE rn = 1;

CREATE CLUSTERED INDEX CX_IRR ON #IRR (CreditID);

-----------------------------------------------------
-- Step 6: Restructured Credits
-----------------------------------------------------
IF OBJECT_ID('tempdb..#Restructured') IS NOT NULL DROP TABLE #Restructured;

-- Combine both sources into one table first
SELECT
    s.[СостоянияРеструктурированныхКредитов Кредит ID] AS CreditID,
    s.[СостоянияРеструктурированныхКредитов Период] AS PeriodState,
    s.[СостоянияРеструктурированныхКредитов Состояние Реструктурированного Кредита] AS RestructuredCreditState,
    r.[РеструктурированныеКредиты Период] AS PeriodReason,
    r.[РеструктурированныеКредиты Причина Реструктуризации] AS RestructuringReason,
    r.[РеструктурированныеКредиты Тип Реструктуризации Долга] AS RestructuringDebtType
INTO #Restructured
FROM mis.[Silver_РегистрыСведений.СостоянияРеструктурированныхКредитов] s
LEFT JOIN mis.[Silver_РегистрыСведений.РеструктурированныеКредиты] r
    ON s.[СостоянияРеструктурированныхКредитов Кредит ID] = r.[РеструктурированныеКредиты Кредит ID];

CREATE CLUSTERED INDEX CX_Restructured ON #Restructured (CreditID, PeriodState, PeriodReason);

-----------------------------------------------------
-- Step 7: Final Insert with proper historical lookup (keep NULLs)
-----------------------------------------------------
INSERT INTO mis.[2tbl_Gold_Fact_Sold_Par] WITH (TABLOCK)
SELECT
    sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS SoldDate,
    sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
    sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] AS SoldAmount,
    sd.[СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки МСФО] AS NumberOfOverdueDaysIFRS,
    ROUND(COALESCE(CASE WHEN i.IRR_Year < 100 THEN i.IRR_Year ELSE i.IRR_Client END, 0)
          * sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит], 2) AS IRR_Values,
    sh.BranchShadow,
    r.EmployeeID,
    r.BranchID,
    e.PositionID AS EmployeePositionID,
    mpd.Par_0_IFRS,
    mpd.Par_30_IFRS,
    mpd.Par_60_IFRS,
    mpd.Par_90_IFRS,
    state.RestructuredCreditState,
    reason.RestructuringReason,
    reason.RestructuringDebtType
FROM mis.[Silver_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] sd
JOIN mis.[Silver_Справочники.Кредиты] k
  ON k.[Кредиты ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
LEFT JOIN #MaxPastDays mpd 
    ON mpd.OwnerID = k.[Кредиты Владелец] 
   AND mpd.SoldDate = sd.[СуммыЗадолженностиПоПериодамПросрочки Дата]
LEFT JOIN #ShadowBranch sh 
    ON sh.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
LEFT JOIN #Responsible r   
    ON r.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
LEFT JOIN #EmployeePos e   
    ON e.EmployeeID = r.EmployeeID
LEFT JOIN #IRR i           
    ON i.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]

-- Lookup latest RestructuredCreditState (respect NULLs)
OUTER APPLY (
    SELECT TOP(1)
        s.RestructuredCreditState
    FROM #Restructured s
    WHERE s.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
      AND (CAST(s.PeriodState AS DATE) <= sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] OR s.PeriodState IS NULL)
    ORDER BY 
        CASE WHEN s.PeriodState IS NOT NULL THEN 1 ELSE 0 END DESC,
        s.PeriodState DESC
) state

-- Lookup latest RestructuringReason / DebtType (respect NULLs)
OUTER APPLY (
    SELECT TOP(1)
        r.RestructuringReason,
        r.RestructuringDebtType
    FROM #Restructured r
    WHERE r.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
      AND (CAST(r.PeriodReason AS DATE) <= sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] OR r.PeriodReason IS NULL)
    ORDER BY 
        CASE WHEN r.PeriodReason IS NOT NULL THEN 1 ELSE 0 END DESC,
        r.PeriodReason DESC
) reason

WHERE sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= @DateFrom
  AND sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] <> 0

-----------------------------------------------------
-- Step 8: Columnstore index + cleanup
-----------------------------------------------------


DROP TABLE IF EXISTS #MaxPastDays, #ShadowBranch, #Responsible, #EmployeePos, #IRR, #Restructured;

