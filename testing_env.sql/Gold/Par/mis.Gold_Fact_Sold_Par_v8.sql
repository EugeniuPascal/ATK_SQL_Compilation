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
-- Step 1: Shadow Branch, Responsible, EmployeePos, IRR temp tables (same as before)
-----------------------------------------------------
-- Shadow Branch
IF OBJECT_ID('tempdb..#ShadowBranch') IS NOT NULL DROP TABLE #ShadowBranch;
CREATE TABLE #ShadowBranch (
    CreditID     VARCHAR(36) NOT NULL,
    BranchShadow NVARCHAR(100) NULL,
    Period       DATE NULL
);

INSERT INTO #ShadowBranch (CreditID, BranchShadow, Period)
SELECT 
    x.[КредитыВТеневыхФилиалах Кредит ID],
    x.[КредитыВТеневыхФилиалах Филиал],
    x.[КредитыВТеневыхФилиалах Период]
FROM mis.[Bronze_РегистрыСведений.КредитыВТеневыхФилиалах] x;

CREATE NONCLUSTERED INDEX IX_Shadow_Credit_Period ON #ShadowBranch (CreditID, Period);

-- Responsible
IF OBJECT_ID('tempdb..#Responsible') IS NOT NULL DROP TABLE #Responsible;
CREATE TABLE #Responsible (
    CreditID   VARCHAR(36) NOT NULL,
    EmployeeID VARCHAR(36) NULL,
    BranchID   VARCHAR(36) NULL,
    Period     DATE NULL
);

INSERT INTO #Responsible (CreditID, EmployeeID, BranchID, Period)
SELECT
    r.[ОтветственныеПоКредитамВыданным Кредит ID],
    r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID],
    r.[ОтветственныеПоКредитамВыданным Филиал ID],
    r.[ОтветственныеПоКредитамВыданным Период]
FROM mis.[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным] r;

CREATE NONCLUSTERED INDEX IX_Resp_Credit_Period ON #Responsible (CreditID, Period);

-- Employee Position
IF OBJECT_ID('tempdb..#EmployeePos') IS NOT NULL DROP TABLE #EmployeePos;
CREATE TABLE #EmployeePos (
    EmployeeID VARCHAR(36) NOT NULL,
    PositionID VARCHAR(36) NULL,
    Period DATE NULL
);

INSERT INTO #EmployeePos (EmployeeID, PositionID, Period)
SELECT
    emp.[СотрудникиДанныеПоЗарплате Сотрудник ID],
    emp.[СотрудникиДанныеПоЗарплате Должность ID],
    emp.[СотрудникиДанныеПоЗарплате Период]
FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате] emp
WHERE emp.[СотрудникиДанныеПоЗарплате Период] >= DATEADD(year,-1,@DateFrom);

CREATE CLUSTERED INDEX CX_EmployeePos_Emp_Period ON #EmployeePos (EmployeeID, Period);

-- IRR
IF OBJECT_ID('tempdb..#IRR') IS NOT NULL DROP TABLE #IRR;
CREATE TABLE #IRR (
    CreditID VARCHAR(36) NOT NULL,
	ClientID VARCHAR(36)  NOT NULL,
    IRR_Year DECIMAL(18,6) NULL,
    IRR_Client DECIMAL(18,6) NULL,
    IRRDate DATETIME2 NULL
);

INSERT INTO #IRR (CreditID, ClientID, IRR_Year, IRR_Client, IRRDate)
SELECT
    i.[УстановкаДанныхКредита Кредит ID],
	i.[УстановкаДанныхКредита Клиент ID],
    i.[УстановкаДанныхКредита Внутренняя Норма Доходности Годовая],
    i.[УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая],
    i.[УстановкаДанныхКредита Дата]
FROM mis.[Bronze_Документы.УстановкаДанныхКредита] i
WHERE i.[УстановкаДанныхКредита Кредит ID] IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_IRR_Credit_Date ON #IRR (CreditID, IRRDate DESC);

-----------------------------------------------------
-- Step 2: Prepare ranges
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
INSERT INTO mis.[Gold_Fact_Sold_Par] WITH (TABLOCK)
(
    SoldDate, ClientID, CreditID, SoldAmount, NumberOfOverdueDaysIFRS, IRR_Values,
    BranchShadow, EmployeeID, BranchID, EmployeePositionID, Par
)
SELECT
    sd.[СуммыЗадолженностиПоПериодамПросрочки Дата],
	irr.ClientID,
    sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID],
    sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит],
    sd.[СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки МСФО],

    -- IRR Values
    ROUND(
        COALESCE(
            CASE WHEN irr.IRR_Year IS NOT NULL AND irr.IRR_Year < 100 THEN irr.IRR_Year
                 ELSE irr.IRR_Client
            END, 0
        ) * sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит], 2
    ) AS IRR_Values,

    -- Branch
    sh.BranchShadow,

    -- Employee
    r.EmployeeID,
    r.BranchID,
    empPos.PositionID AS EmployeePositionID,

    -- Single Par column
    CASE
        WHEN sd.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого] > 90 THEN N'Par_90_IFRS'
        WHEN sd.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого] > 60 THEN N'Par_60_IFRS'
        WHEN sd.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого] > 30 THEN N'Par_30_IFRS'
        WHEN sd.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого] > 0  THEN N'Par_0_IFRS'
        ELSE NULL
    END AS Par

FROM mis.[Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] sd

-- Responsible
LEFT JOIN RespRanges r
    ON r.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
   AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= r.ValidFrom
   AND (r.ValidTo IS NULL OR sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] < r.ValidTo)

-- EmployeePos
LEFT JOIN EmpPosRanges empPos
    ON empPos.EmployeeID = r.EmployeeID
   AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= empPos.ValidFrom
   AND (empPos.ValidTo IS NULL OR sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] < empPos.ValidTo)

-- Shadow
LEFT JOIN ShadowRanges sh
    ON sh.CreditID = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
   AND sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= sh.ValidFrom
   AND (sh.ValidTo IS NULL OR sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] < sh.ValidTo)

-- IRR
OUTER APPLY (
    SELECT TOP (1) i.IRR_Year, i.IRR_Client, i.ClientID
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
CREATE CLUSTERED COLUMNSTORE INDEX CCSI_Gold_Fact_Sold_Par
ON mis.[Gold_Fact_Sold_Par];

-- Drop temp tables
DROP TABLE IF EXISTS #ShadowBranch, #Responsible, #EmployeePos, #IRR;



