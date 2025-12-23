USE [ATK];
SET NOCOUNT ON;

DECLARE @DateFrom date = '2023-09-01';
DECLARE @DateTo   date = '2026-12-31';

PRINT N'=== Compiled [mis].[Gold_Fact_Restruct_Daily_Min] for Period '
      + CONVERT(varchar(10), @DateFrom, 23) + N' — ' + CONVERT(varchar(10), @DateTo, 23) + N' ===';

BEGIN TRAN;

IF OBJECT_ID('tempdb..#Base')         IS NOT NULL DROP TABLE #Base;
IF OBJECT_ID('tempdb..#MaxDays')      IS NOT NULL DROP TABLE #MaxDays;
IF OBJECT_ID('tempdb..#Flag')         IS NOT NULL DROP TABLE #Flag;
IF OBJECT_ID('tempdb..#RespEarliest') IS NOT NULL DROP TABLE #RespEarliest;
IF OBJECT_ID('tempdb..#Joined_raw')   IS NOT NULL DROP TABLE #Joined_raw;
IF OBJECT_ID('tempdb..#Joined')       IS NOT NULL DROP TABLE #Joined;
IF OBJECT_ID('tempdb..#IRR')          IS NOT NULL DROP TABLE #IRR;
IF OBJECT_ID('tempdb..#EmployeePos')  IS NOT NULL DROP TABLE #EmployeePos;

IF OBJECT_ID('[mis].[Gold_Fact_Restruct_Daily_Min]', 'U') IS NOT NULL
    DROP TABLE [mis].[Gold_Fact_Restruct_Daily_Min];

CREATE TABLE [mis].[Gold_Fact_Restruct_Daily_Min] 
(
    SoldDate date NOT NULL,
    CreditID varchar(64) NOT NULL,
    ClientID varchar(64) NOT NULL,
    Balance_Total money NULL,
    DaysBucket_Credit int NULL,
    DaysFact_Total int NULL,
    DaysIFRS int NULL,
    IRR_Values DECIMAL(18,6) NULL,
    StateName_Final nvarchar(200) NULL,
    TypeName_Sticky_Final nvarchar(200) NULL,
    CreditStatus_Base nvarchar(200) NULL,
    LastBranchID varchar(64) NULL,
    LastEmployeeID varchar(64) NULL,
    IsSpecialBranch bit NULL,
    SegmentIFRS nvarchar(20) NULL,
    ParIFRS nvarchar(20) NULL,
    StageName nvarchar(200) NULL,
    EmployeePositionID varchar(36) NULL,
    CONSTRAINT PK_Gold_Fact_RestructDailyMin
        PRIMARY KEY (ClientID, CreditID, SoldDate)
);

-- Step 1: Base
;WITH cte AS (
    SELECT
        s.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS SoldDate,
        s.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
        s.[СуммыЗадолженностиПоПериодамПросрочки Клиент ID] AS ClientID,
        s.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] AS Balance_Total,
        s.[СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки Кредит] AS DaysBucket_Credit,
        s.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого] AS DaysFact_Total,
        s.[СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки МСФО] AS DaysIFRS,
        r.StateName AS StateName_Final,
        r.TypeName_Sticky AS TypeName_Sticky_Final,
        r.CreditStatus AS CreditStatus_Base,
        ROW_NUMBER() OVER (
            PARTITION BY s.[СуммыЗадолженностиПоПериодамПросрочки Клиент ID],
                         s.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID],
                         s.[СуммыЗадолженностиПоПериодамПросрочки Дата]
            ORDER BY s.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] DESC,
                     s.[СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки Кредит] DESC
        ) AS rn
    FROM [ATK].[mis].[Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] s
    LEFT JOIN [ATK].[mis].[Silver_Restruct_Merged_SCD] r
           ON r.CreditID = s.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
          AND s.[СуммыЗадолженностиПоПериодамПросрочки Дата] BETWEEN r.ValidFrom AND r.ValidTo
    WHERE s.[СуммыЗадолженностиПоПериодамПросрочки Дата] BETWEEN @DateFrom AND @DateTo
)
SELECT *
INTO #Base
FROM cte WHERE rn = 1;

CREATE CLUSTERED INDEX CIX_Base ON #Base (ClientID, SoldDate, CreditID);

-- Step 1.1: MaxDays
SELECT ClientID, SoldDate, MAX(DaysFact_Total) AS MaxDaysPerClientDay
INTO #MaxDays
FROM #Base
GROUP BY ClientID, SoldDate;

CREATE UNIQUE CLUSTERED INDEX CIX_MaxDays ON #MaxDays (ClientID, SoldDate);

-- Step 1.2: Flags
SELECT ClientID, SoldDate
INTO #Flag
FROM [ATK].[mis].[Silver_Client_UnhealedFlag]
WHERE HasUnhealed = 1 AND SoldDate BETWEEN @DateFrom AND @DateTo;

CREATE UNIQUE CLUSTERED INDEX CIX_Flag ON #Flag (ClientID, SoldDate);

-- Step 2: Earliest resp
;WITH MinFrom AS (
    SELECT CreditID, MIN(ValidFrom) AS MinValidFrom
    FROM [ATK].[mis].[Silver_Resp_SCD]
    GROUP BY CreditID
)
SELECT r.CreditID, r.FinalBranchID, r.FinalExpertID, r.IsSpecialBranch
INTO #RespEarliest
FROM [ATK].[mis].[Silver_Resp_SCD] r
JOIN MinFrom m ON r.CreditID = m.CreditID AND r.ValidFrom = m.MinValidFrom;

CREATE UNIQUE CLUSTERED INDEX CIX_RespEarliest ON #RespEarliest (CreditID);

-- Step 2.1: EmployeePos
SELECT [СотрудникиДанныеПоЗарплате Сотрудник ID] AS EmployeeID,
       [СотрудникиДанныеПоЗарплате Должность ID] AS EmployeePositionID,
       CAST([СотрудникиДанныеПоЗарплате Период] AS DATE) AS Period
INTO #EmployeePos
FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате]
WHERE CAST([СотрудникиДанныеПоЗарплате Период] AS DATE) >= DATEADD(YEAR,-1,@DateFrom);

CREATE CLUSTERED INDEX CX_EmployeePos ON #EmployeePos (EmployeeID, Period);

-- Step 3: IRR
SELECT [УстановкаДанныхКредита Кредит ID] AS CreditID,
       [УстановкаДанныхКредита Внутренняя Норма Доходности Годовая] AS IRR_Year,
       [УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая] AS IRR_Client,
       CAST([УстановкаДанныхКредита Дата] AS DATE) AS IRRDate
INTO #IRR
FROM mis.[Bronze_Документы.УстановкаДанныхКредита]
WHERE [УстановкаДанныхКредита Кредит ID] IS NOT NULL;

CREATE INDEX IX_IRR ON #IRR (CreditID, IRRDate DESC);

-- Step 3.1: Join all
;WITH Joined AS (
SELECT
    b.*,
    ROUND(
    COALESCE(
        CASE WHEN irr.IRR_Year IS NOT NULL AND irr.IRR_Year < 100 THEN irr.IRR_Year
                ELSE irr.IRR_Client
             END, 0
        ) * b.Balance_Total, 2
    ) AS IRR_Values,
    COALESCE(r_curr.FinalBranchID,e.FinalBranchID) AS LastBranchID,
    COALESCE(r_curr.FinalExpertID,e.FinalExpertID) AS LastEmployeeID,
    COALESCE(r_curr.IsSpecialBranch,e.IsSpecialBranch) AS IsSpecialBranch,
    s.StageName AS CurrentStage,
    empPos.EmployeePositionID
FROM #Base b
OUTER APPLY (
    SELECT TOP 1 * FROM [ATK].[mis].[Silver_Resp_SCD] r
    WHERE r.CreditID = b.CreditID AND b.SoldDate BETWEEN r.ValidFrom AND r.ValidTo
    ORDER BY r.ValidFrom DESC
) r_curr
LEFT JOIN #RespEarliest e ON e.CreditID = b.CreditID
LEFT JOIN [ATK].[mis].[Silver_Stages_SCD] s
       ON s.CreditID = b.CreditID AND b.SoldDate BETWEEN s.ValidFrom AND s.ValidTo
LEFT JOIN #IRR irr ON irr.CreditID = b.CreditID AND irr.IRRDate <= b.SoldDate
OUTER APPLY (
    SELECT TOP 1 ep.EmployeePositionID
    FROM #EmployeePos ep
    WHERE ep.EmployeeID = r_curr.FinalExpertID AND ep.Period <= b.SoldDate
    ORDER BY ep.Period DESC
) empPos
)
SELECT *
INTO #Joined_raw
FROM Joined;

-- Step 4: ParIFRS
SELECT j.*,
       CASE
           WHEN md.MaxDaysPerClientDay BETWEEN 1 AND 30 THEN N'Par0'
           WHEN md.MaxDaysPerClientDay BETWEEN 31 AND 60 THEN N'Par30'
           WHEN md.MaxDaysPerClientDay BETWEEN 61 AND 90 THEN N'Par60'
           WHEN md.MaxDaysPerClientDay BETWEEN 91 AND 180 THEN N'Par90'
           WHEN md.MaxDaysPerClientDay BETWEEN 181 AND 270 THEN N'Par180'
           WHEN md.MaxDaysPerClientDay BETWEEN 271 AND 360 THEN N'Par270'
           WHEN md.MaxDaysPerClientDay > 360 THEN N'Par360'
           ELSE NULL
       END AS ParIFRS
INTO #Joined
FROM #Joined_raw j
JOIN #MaxDays md ON md.ClientID = j.ClientID AND md.SoldDate = j.SoldDate;

CREATE CLUSTERED INDEX CIX_Joined_ClientDate ON #Joined (ClientID, SoldDate, CreditID);

-- Step 5: Insert with dedup
;WITH Dedup AS (
    SELECT
        j.SoldDate,
        j.CreditID,
        j.ClientID,
        j.Balance_Total,
        j.DaysBucket_Credit,
        j.DaysFact_Total,
        j.DaysIFRS,
        j.IRR_Values,
        j.StateName_Final,
        j.TypeName_Sticky_Final,
        j.CreditStatus_Base,
        j.LastBranchID,
        j.LastEmployeeID,
        j.IsSpecialBranch,
        j.ParIFRS,
        j.CurrentStage,
        j.EmployeePositionID,
        ROW_NUMBER() OVER (PARTITION BY j.ClientID, j.CreditID, j.SoldDate ORDER BY j.SoldDate DESC) AS rn
    FROM #Joined j
)


INSERT INTO [mis].[Gold_Fact_Restruct_Daily_Min]
(SoldDate,CreditID,ClientID,Balance_Total,DaysBucket_Credit,DaysFact_Total,DaysIFRS,IRR_Values,
 StateName_Final,TypeName_Sticky_Final,CreditStatus_Base,LastBranchID,LastEmployeeID,IsSpecialBranch,
 SegmentIFRS,ParIFRS,StageName,EmployeePositionID)
SELECT
    d.SoldDate,
    d.CreditID,
    d.ClientID,
    d.Balance_Total,
    d.DaysBucket_Credit,
    d.DaysFact_Total,
    d.DaysIFRS,
    d.IRR_Values,
    CASE 
	    WHEN d.ClientID IS NOT NULL 
	    AND ISNULL(d.StateName_Final,N'') <> N'НеИзлеченный' 
	    THEN N'Nevindecat contaminat' 
	    ELSE d.StateName_Final 
	END AS StateName_Final,
    CASE 
	    WHEN d.ClientID IS NOT NULL 
		THEN N'НекоммерческаяРеструктуризация' 
		ELSE d.TypeName_Sticky_Final 
	END AS TypeName_Sticky_Final,
    d.CreditStatus_Base,
    d.LastBranchID,
    d.LastEmployeeID,
    d.IsSpecialBranch,
    CASE
        WHEN d.DaysIFRS >= 91 THEN N'e) 90 +'
        WHEN d.DaysIFRS >= 31 THEN N'd) 30 - 90'
        WHEN d.DaysIFRS >= 16 THEN N'c) 16 - 30'
        WHEN d.DaysIFRS >= 4 THEN N'b) 4 - 15'
        ELSE N'a) 0 - 3'
    END,
    d.ParIFRS,
    CASE d.CurrentStage
        WHEN 'Стадия1' THEN 'Stage1'
        WHEN 'Стадия2' THEN 'Stage2'
        WHEN 'Стадия3' THEN 'Stage3'
        ELSE d.CurrentStage
    END,
    d.EmployeePositionID
FROM Dedup d
WHERE d.rn = 1
OPTION (RECOMPILE);

-- Cleanup
DROP TABLE #Base;
DROP TABLE #MaxDays;
DROP TABLE #Flag;
DROP TABLE #RespEarliest;
DROP TABLE #Joined_raw;
DROP TABLE #Joined;
DROP TABLE #IRR;
DROP TABLE #EmployeePos;

-- Summary
DECLARE @cnt bigint;
SELECT @cnt = COUNT_BIG(*) FROM [mis].[Gold_Fact_Restruct_Daily_Min];
PRINT N'🏁 Successfully Inserted. Rows: ' + CONVERT(varchar(30), @cnt);

COMMIT TRAN;
