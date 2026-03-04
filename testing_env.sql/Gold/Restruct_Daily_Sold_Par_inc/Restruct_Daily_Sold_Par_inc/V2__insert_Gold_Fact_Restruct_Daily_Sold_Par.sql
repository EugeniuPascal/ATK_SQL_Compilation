USE [ATK];
SET NOCOUNT ON;

/* ================== PARAMETERS ================== */
DECLARE @DateFrom date = '2024-01-01';
DECLARE @DateTo   date = '2026-12-31';

PRINT N'=== Rebuilding [mis].[Gold_Fact_Restruct_Daily_Sold_Par] for period '
      + CONVERT(varchar(10), @DateFrom, 23) + N' — ' + CONVERT(varchar(10), @DateTo, 23) + N' ===';
	  
DELETE FROM [mis].[Gold_Fact_Restruct_Daily_Sold_Par]
WHERE SoldDate BETWEEN @DateFrom AND @DateTo;


/* ================== CLEAN TEMP ================== */
IF OBJECT_ID('tempdb..#Base') IS NOT NULL DROP TABLE #Base;
IF OBJECT_ID('tempdb..#MaxDays') IS NOT NULL DROP TABLE #MaxDays;
IF OBJECT_ID('tempdb..#Flag') IS NOT NULL DROP TABLE #Flag;
IF OBJECT_ID('tempdb..#RespEarliest') IS NOT NULL DROP TABLE #RespEarliest;
IF OBJECT_ID('tempdb..#Joined_raw') IS NOT NULL DROP TABLE #Joined_raw;
IF OBJECT_ID('tempdb..#Joined') IS NOT NULL DROP TABLE #Joined;
IF OBJECT_ID('tempdb..#IRR') IS NOT NULL DROP TABLE #IRR;
IF OBJECT_ID('tempdb..#Responsible') IS NOT NULL DROP TABLE #Responsible;

SELECT
    [ОтветственныеПоКредитамВыданным Кредит ID] AS CreditID,
    [ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS EmployeeID,
    [ОтветственныеПоКредитамВыданным Филиал ID] AS BranchID,
    CAST([ОтветственныеПоКредитамВыданным Период] AS DATE) AS Period
INTO #Responsible
FROM mis.[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным];

CREATE NONCLUSTERED INDEX IX_Resp_Credit_Period ON #Responsible(CreditID, Period);

-- IRR temp
SELECT
    [УстановкаДанныхКредита Кредит ID] AS CreditID,
    [УстановкаДанныхКредита Внутренняя Норма Доходности Годовая] AS IRR_Year,
    [УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая] AS IRR_Client,
    CAST([УстановкаДанныхКредита Дата] AS DATE) AS IRRDate
INTO #IRR
FROM mis.[Bronze_Документы.УстановкаДанныхКредита]
WHERE [УстановкаДанныхКредита Кредит ID] IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_IRR ON #IRR(CreditID, IRRDate DESC);

---------------------------------------------------------
-- STEP 1: BASE
---------------------------------------------------------
;WITH cte AS (
    SELECT
        CAST(s.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS DATE) AS SoldDate,
        s.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
        s.[СуммыЗадолженностиПоПериодамПросрочки Клиент ID] AS ClientID,
        s.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] AS Balance_Total,
        s.[СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки Кредит] AS DaysBucket_Credit,
        s.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого] AS DaysFact_Total,
        s.[СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки МСФО] AS DaysIFRS,
        r.StateName AS [Starea imprumutului],
        r.TypeName_Sticky AS [Tipul de restructurare],
        ROW_NUMBER() OVER (
            PARTITION BY
                s.[СуммыЗадолженностиПоПериодамПросрочки Клиент ID],
                s.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID],
                CAST(s.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS DATE)
            ORDER BY s.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] DESC
        ) AS rn,
        -- latest IRR for SoldDate
        (SELECT TOP (1)
            CASE WHEN i.IRR_Year < 100 THEN i.IRR_Year ELSE i.IRR_Client END
         FROM #IRR i
         WHERE i.CreditID = s.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
           AND i.IRRDate <= CAST(s.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS DATE)
         ORDER BY i.IRRDate DESC
        ) AS IRR_Rate
    FROM [ATK].[mis].[Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] s
    LEFT JOIN [ATK].[mis].[Silver_Restruct_Merged_SCD] r
        ON r.CreditID = s.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
       AND CAST(s.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS DATE) BETWEEN r.ValidFrom AND r.ValidTo
    WHERE s.[СуммыЗадолженностиПоПериодамПросрочки Дата] BETWEEN @DateFrom AND @DateTo
	--AND s.[СуммыЗадолженностиПоПериодамПросрочки Клиент ID] = 'BA930018FEFB2E3711DD78D34164392D'
)
SELECT *
INTO #Base
FROM cte
WHERE rn = 1;

CREATE CLUSTERED INDEX CIX_Base ON #Base(ClientID, SoldDate, CreditID);

---------------------------------------------------------
-- STEP 1.1 MAX DAYS
---------------------------------------------------------
SELECT ClientID, SoldDate, MAX(DaysFact_Total) AS MaxDaysPerClientDay
INTO #MaxDays
FROM #Base
GROUP BY ClientID, SoldDate;

CREATE UNIQUE CLUSTERED INDEX CIX_MaxDays ON #MaxDays(ClientID, SoldDate);

---------------------------------------------------------
-- STEP 1.2 FLAGS
---------------------------------------------------------
SELECT DISTINCT ClientID, SoldDate
INTO #Flag
FROM [ATK].[mis].[Silver_Client_UnhealedFlag]
WHERE HasUnhealed = 1
  AND SoldDate BETWEEN @DateFrom AND @DateTo;

CREATE UNIQUE CLUSTERED INDEX CIX_Flag ON #Flag(ClientID, SoldDate);

---------------------------------------------------------
-- STEP 2: Earliest Responsible
---------------------------------------------------------
;WITH MinFrom AS (
    SELECT CreditID, MIN(ValidFrom) AS MinValidFrom
    FROM [ATK].[mis].[Silver_Resp_SCD]
    GROUP BY CreditID
)
SELECT r.CreditID, r.FinalBranchID, r.FinalExpertID 

INTO #RespEarliest
FROM [ATK].[mis].[Silver_Resp_SCD] r
JOIN MinFrom m ON r.CreditID = m.CreditID AND r.ValidFrom = m.MinValidFrom;

---------------------------------------------------------
-- STEP 3 JOIN RESPONSIBLE (SOURCE-BASED)
---------------------------------------------------------
SELECT
    b.*,
    COALESCE(r_curr.FinalBranchID, e.FinalBranchID) AS LastBranchID,
    COALESCE(r_curr.FinalExpertID, e.FinalExpertID) AS LastEmployeeID,
    f.EmployeeID,
    f.BranchID,
    s.StageName AS CurrentStage
INTO #Joined_raw
FROM #Base b
OUTER APPLY (
    SELECT TOP (1) *
    FROM [ATK].[mis].[Silver_Resp_SCD] r
    WHERE r.CreditID = b.CreditID
      AND b.SoldDate BETWEEN r.ValidFrom AND r.ValidTo
    ORDER BY r.ValidFrom DESC
) r_curr
LEFT JOIN #RespEarliest e ON e.CreditID = b.CreditID
LEFT JOIN [ATK].[mis].[Silver_Stages_SCD] s
  ON s.CreditID = b.CreditID
 AND b.SoldDate BETWEEN s.ValidFrom AND s.ValidTo
OUTER APPLY (
    SELECT TOP (1)
        rr.EmployeeID,
        rr.BranchID
    FROM #Responsible rr
    WHERE rr.CreditID = b.CreditID
      AND rr.Period <= b.SoldDate
    ORDER BY rr.Period DESC
) AS f;

CREATE CLUSTERED INDEX CIX_JR ON #Joined_raw(ClientID, SoldDate);

---------------------------------------------------------
-- STEP 4 PAR
---------------------------------------------------------
SELECT
    jr.*,
    CASE 
        WHEN md.MaxDaysPerClientDay BETWEEN 1  AND 30  THEN N'Par0'
        WHEN md.MaxDaysPerClientDay BETWEEN 31 AND 60  THEN N'Par30'
        WHEN md.MaxDaysPerClientDay BETWEEN 61 AND 90  THEN N'Par60'
        WHEN md.MaxDaysPerClientDay BETWEEN 91 AND 180 THEN N'Par90'
        WHEN md.MaxDaysPerClientDay BETWEEN 181 AND 270 THEN N'Par180'
        WHEN md.MaxDaysPerClientDay BETWEEN 271 AND 360 THEN N'Par270'
        WHEN md.MaxDaysPerClientDay > 360           THEN N'Par360'
        ELSE NULL
    END AS ParIFRS
INTO #Joined
FROM #Joined_raw jr
JOIN #MaxDays md
  ON md.ClientID = jr.ClientID
 AND md.SoldDate = jr.SoldDate;

BEGIN TRAN;

WITH FinalDedup AS (
    SELECT
        j.SoldDate,
        j.CreditID,
        j.ClientID,
        j.Balance_Total,
        ROUND(ISNULL(j.IRR_Rate,0) * j.Balance_Total, 2) AS IRR_Values,
        j.DaysBucket_Credit,
        j.DaysFact_Total,
        j.DaysIFRS,
		
        -- Starea logic like Gold_Fact_Restruct_Daily_Min
        CASE
            WHEN f.ClientID IS NOT NULL
                 AND ISNULL(j.[Starea imprumutului], N'') <> N'НеИзлеченный'
            THEN N'Nevindecat contaminat'
            WHEN j.[Starea imprumutului] = N'Излеченный' THEN N'Vindecat'
            WHEN j.[Starea imprumutului] = N'НеИзлеченный' THEN N'Nevindecat'
            ELSE j.[Starea imprumutului]
        END AS [Starea imprumutului],

        -- Tipul de restructurare translated to Romanian
        CASE
            WHEN f.ClientID IS NOT NULL
                 OR j.[Tipul de restructurare] LIKE N'%НекоммерческаяРеструктуризация%'
            THEN N'Restructurizare non-comerciala'
            WHEN j.[Tipul de restructurare] LIKE N'%КоммерческаяРеструктуризация%' THEN N'Restructurizare comerciala'
            ELSE j.[Tipul de restructurare]
        END AS [Tipul de restructurare],

        j.LastBranchID,
        j.LastEmployeeID,
        j.BranchID,
        j.EmployeeID,
        CASE
            WHEN j.DaysIFRS >= 91 THEN N'e) 90 +'
            WHEN j.DaysIFRS >= 31 THEN N'd) 30 - 90'
            WHEN j.DaysIFRS >= 16 THEN N'c) 16 - 30'
            WHEN j.DaysIFRS >= 4  THEN N'b) 4 - 15'
            ELSE N'a) 0 - 3'
        END AS SegmentIFRS,
        j.ParIFRS,
        CASE
            WHEN j.DaysBucket_Credit BETWEEN 1   AND 30  THEN N'Par0'
            WHEN j.DaysBucket_Credit BETWEEN 31  AND 60  THEN N'Par30'
            WHEN j.DaysBucket_Credit BETWEEN 61  AND 90  THEN N'Par60'
            WHEN j.DaysBucket_Credit BETWEEN 91 AND 180 THEN N'Par90'
            WHEN j.DaysBucket_Credit BETWEEN 181 AND 270 THEN N'Par180'
            WHEN j.DaysBucket_Credit BETWEEN 271 AND 360 THEN N'Par270'
            WHEN j.DaysBucket_Credit > 360           THEN N'Par360'
            ELSE NULL
        END AS Par,
        CASE j.CurrentStage
            WHEN 'Стадия1' THEN 'Stage1'
            WHEN 'Стадия2' THEN 'Stage2'
            WHEN 'Стадия3' THEN 'Stage3'
            ELSE j.CurrentStage
        END AS StageName,
        ROW_NUMBER() OVER (
            PARTITION BY j.ClientID, j.CreditID, j.SoldDate
            ORDER BY j.DaysFact_Total DESC, j.Balance_Total DESC
        ) AS rn
    FROM #Joined j
    LEFT JOIN #Flag f ON f.ClientID = j.ClientID AND f.SoldDate = j.SoldDate
)
INSERT INTO [mis].[Gold_Fact_Restruct_Daily_Sold_Par] (
    SoldDate, CreditID, ClientID, Balance_Total, IRR_Values,
    DaysBucket_Credit, DaysFact_Total, DaysIFRS,
    [Starea imprumutului], [Tipul de restructurare], 
    LastBranchID, LastEmployeeID, BranchID, EmployeeID,
	SegmentIFRS, ParIFRS, Par, StageName
)
SELECT
    SoldDate, CreditID, ClientID, Balance_Total, IRR_Values,
    DaysBucket_Credit, DaysFact_Total, DaysIFRS,
    [Starea imprumutului], [Tipul de restructurare], 
    LastBranchID, LastEmployeeID, BranchID, EmployeeID,
	SegmentIFRS, ParIFRS, Par, StageName
FROM FinalDedup
WHERE rn = 1;

COMMIT TRAN;

PRINT N'🏁 Done';