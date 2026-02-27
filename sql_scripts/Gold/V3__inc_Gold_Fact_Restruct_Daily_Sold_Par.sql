USE [ATK];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

---------------------------------------------------------
-- PARAMETERS (incremental window)
---------------------------------------------------------
DECLARE @DateFrom date = DATEADD(day, -60, CAST(GETDATE() AS date));
DECLARE @DateTo   date = CAST(GETDATE() AS date);

PRINT N'=== Incremental load [mis].[Gold_Fact_Restruct_Daily_Sold_Par] '
    + CONVERT(varchar(10), @DateFrom, 23)
    + N' → '
    + CONVERT(varchar(10), @DateTo, 23) + N' ===';

---------------------------------------------------------
-- DELETE TARGET WINDOW (idempotent)
---------------------------------------------------------
DELETE FROM [mis].[Gold_Fact_Restruct_Daily_Sold_Par]
WHERE SoldDate BETWEEN @DateFrom AND @DateTo;

---------------------------------------------------------
-- CLEAN TEMP
---------------------------------------------------------
IF OBJECT_ID('tempdb..#Base')          IS NOT NULL DROP TABLE #Base;
IF OBJECT_ID('tempdb..#MaxDays')       IS NOT NULL DROP TABLE #MaxDays;
IF OBJECT_ID('tempdb..#Flag')          IS NOT NULL DROP TABLE #Flag;
IF OBJECT_ID('tempdb..#RespEarliest')  IS NOT NULL DROP TABLE #RespEarliest;
IF OBJECT_ID('tempdb..#Joined_raw')    IS NOT NULL DROP TABLE #Joined_raw;
IF OBJECT_ID('tempdb..#Joined')        IS NOT NULL DROP TABLE #Joined;
IF OBJECT_ID('tempdb..#IRR')           IS NOT NULL DROP TABLE #IRR;
IF OBJECT_ID('tempdb..#Responsible')   IS NOT NULL DROP TABLE #Responsible;

---------------------------------------------------------
-- RESPONSIBLE (source-based)
---------------------------------------------------------
SELECT
    [ОтветственныеПоКредитамВыданным Кредит ID] AS CreditID,
    [ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS EmployeeID,
    [ОтветственныеПоКредитамВыданным Филиал ID] AS BranchID,
    CAST([ОтветственныеПоКредитамВыданным Период] AS date) AS Period
INTO #Responsible
FROM mis.[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным];

CREATE NONCLUSTERED INDEX IX_Resp ON #Responsible (CreditID, Period);

---------------------------------------------------------
-- IRR
---------------------------------------------------------
SELECT
    [УстановкаДанныхКредита Кредит ID] AS CreditID,
    [УстановкаДанныхКредита Внутренняя Норма Доходности Годовая] AS IRR_Year,
    [УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая] AS IRR_Client,
    CAST([УстановкаДанныхКредита Дата] AS date) AS IRRDate
INTO #IRR
FROM mis.[Bronze_Документы.УстановкаДанныхКредита]
WHERE [УстановкаДанныхКредита Кредит ID] IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_IRR ON #IRR (CreditID, IRRDate DESC);

---------------------------------------------------------
-- BASE
---------------------------------------------------------
;WITH cte AS (
    SELECT
        CAST(s.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS date) AS SoldDate,
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
                CAST(s.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS date)
            ORDER BY s.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] DESC
        ) AS rn,
        (
            SELECT TOP (1)
                CASE WHEN i.IRR_Year < 100 THEN i.IRR_Year ELSE i.IRR_Client END
            FROM #IRR i
            WHERE i.CreditID = s.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
              AND i.IRRDate <= CAST(s.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS date)
            ORDER BY i.IRRDate DESC
        ) AS IRR_Rate
    FROM mis.[Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] s
    LEFT JOIN mis.[Silver_Restruct_Merged_SCD] r
        ON r.CreditID = s.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
       AND CAST(s.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS date)
           BETWEEN r.ValidFrom AND r.ValidTo
    WHERE s.[СуммыЗадолженностиПоПериодамПросрочки Дата]
          BETWEEN @DateFrom AND @DateTo
)
SELECT *
INTO #Base
FROM cte
WHERE rn = 1;

---------------------------------------------------------
-- MAX DAYS
---------------------------------------------------------
SELECT ClientID, SoldDate, MAX(DaysFact_Total) AS MaxDaysPerClientDay
INTO #MaxDays
FROM #Base
GROUP BY ClientID, SoldDate;

---------------------------------------------------------
-- UNHEALED FLAG
---------------------------------------------------------
SELECT DISTINCT ClientID, SoldDate
INTO #Flag
FROM mis.[Silver_Client_UnhealedFlag]
WHERE HasUnhealed = 1
  AND SoldDate BETWEEN @DateFrom AND @DateTo;

---------------------------------------------------------
-- EARLIEST RESPONSIBLE
---------------------------------------------------------
;WITH MinFrom AS (
    SELECT CreditID, MIN(ValidFrom) AS MinValidFrom
    FROM mis.[Silver_Resp_SCD]
    GROUP BY CreditID
)
SELECT r.CreditID, r.FinalBranchID, r.FinalExpertID

INTO #RespEarliest
FROM mis.[Silver_Resp_SCD] r
JOIN MinFrom m
  ON r.CreditID = m.CreditID
 AND r.ValidFrom = m.MinValidFrom;

---------------------------------------------------------
-- JOIN RESPONSIBLE + STAGE
---------------------------------------------------------
SELECT
    b.*,
    COALESCE(rc.FinalBranchID, e.FinalBranchID) AS LastBranchID,
    COALESCE(rc.FinalExpertID, e.FinalExpertID) AS LastEmployeeID,
    f.EmployeeID,
    f.BranchID,
    st.StageName AS CurrentStage
INTO #Joined_raw
FROM #Base b
OUTER APPLY (
    SELECT TOP (1) *
    FROM mis.[Silver_Resp_SCD] r
    WHERE r.CreditID = b.CreditID
      AND b.SoldDate BETWEEN r.ValidFrom AND r.ValidTo
    ORDER BY r.ValidFrom DESC
) rc
LEFT JOIN #RespEarliest e ON e.CreditID = b.CreditID
LEFT JOIN mis.[Silver_Stages_SCD] st
  ON st.CreditID = b.CreditID
 AND b.SoldDate BETWEEN st.ValidFrom AND st.ValidTo
OUTER APPLY (
    SELECT TOP (1) rr.EmployeeID, rr.BranchID
    FROM #Responsible rr
    WHERE rr.CreditID = b.CreditID
      AND rr.Period <= b.SoldDate
    ORDER BY rr.Period DESC
) f;

---------------------------------------------------------
-- PAR IFRS
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
    END AS ParIFRS
INTO #Joined
FROM #Joined_raw jr
JOIN #MaxDays md
  ON md.ClientID = jr.ClientID
 AND md.SoldDate = jr.SoldDate;

---------------------------------------------------------
-- FINAL INSERT
---------------------------------------------------------
INSERT INTO mis.[Gold_Fact_Restruct_Daily_Sold_Par]
(
    SoldDate, CreditID, ClientID, Balance_Total, IRR_Values,
    DaysBucket_Credit, DaysFact_Total, DaysIFRS,
    [Starea imprumutului], [Tipul de restructurare],
    LastBranchID, LastEmployeeID, BranchID, EmployeeID, 
	SegmentIFRS, ParIFRS, Par, StageName
)
SELECT
    j.SoldDate,
    j.CreditID,
    j.ClientID,
    j.Balance_Total,
    ROUND(ISNULL(j.IRR_Rate,0) * j.Balance_Total, 2),
    j.DaysBucket_Credit,
    j.DaysFact_Total,
    j.DaysIFRS,
    j.[Starea imprumutului],
    j.[Tipul de restructurare],
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
    END,
    j.ParIFRS,
    CASE
        WHEN j.DaysBucket_Credit BETWEEN 1   AND 30  THEN N'Par0'
        WHEN j.DaysBucket_Credit BETWEEN 31  AND 60  THEN N'Par30'
        WHEN j.DaysBucket_Credit BETWEEN 61  AND 90  THEN N'Par60'
        WHEN j.DaysBucket_Credit BETWEEN 91 AND 180 THEN N'Par90'
        WHEN j.DaysBucket_Credit BETWEEN 181 AND 270 THEN N'Par180'
        WHEN j.DaysBucket_Credit BETWEEN 271 AND 360 THEN N'Par270'
        WHEN j.DaysBucket_Credit > 360           THEN N'Par360'
    END,
    CASE j.CurrentStage
        WHEN N'Стадия1' THEN N'Stage1'
        WHEN N'Стадия2' THEN N'Stage2'
        WHEN N'Стадия3' THEN N'Stage3'
        ELSE j.CurrentStage
    END
FROM #Joined j;

PRINT N'🏁 Incremental load completed successfully';
