USE [ATK];
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID('mis.[Gold_Fact_CPD_Sold]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_CPD_Sold];

CREATE TABLE mis.[Gold_Fact_CPD_Sold]
(
    CondID       VARCHAR(36) NOT NULL,
    CPDDate      DATE        NOT NULL,
    CreditID     VARCHAR(36) NULL,
    ClientID     VARCHAR(36) NOT NULL,
    GroupOwner   VARCHAR(36) NULL,
    BranchID     VARCHAR(36) NULL,
    BranchID1    VARCHAR(36) NULL,
    BranchID2    VARCHAR(36) NULL,
    SoldCredit   DECIMAL(18,2) DEFAULT 0,
    SoldClient   DECIMAL(18,2) DEFAULT 0,
    SoldGroup    DECIMAL(18,2) DEFAULT 0,
    CreditRisk   NVARCHAR(64) NULL,
    LegalRisk    NVARCHAR(64) NULL,
    LoadDttm     DATETIME NOT NULL

);

------------------------------------------------------------
-- 0) Границы Sold (на всякий случай)
------------------------------------------------------------
DECLARE @AsOfDate date =
(
    SELECT MAX(f.SoldDate)
    FROM [ATK].[mis].[Silver_Sold_Owner] f
);

IF @AsOfDate IS NULL
    THROW 50002, 'Sold is empty: [ATK].[mis].[Silver_Sold_Owner].', 1;

------------------------------------------------------------
-- 1) Подготовка: добавляем колонки (если нет) + чистим таблицу
------------------------------------------------------------
IF COL_LENGTH('mis.Gold_Fact_CPD_Sold', 'CreditRisk') IS NULL
    EXEC('ALTER TABLE [mis].[Gold_Fact_CPD_Sold] ADD [CreditRisk] varchar(64) NULL;');

IF COL_LENGTH('mis.Gold_Fact_CPD_Sold', 'LegalRisk') IS NULL
    EXEC('ALTER TABLE [mis].[Gold_Fact_CPD_Sold] ADD [LegalRisk] varchar(64) NULL;');

IF COL_LENGTH('mis.Gold_Fact_CPD_Sold', 'BranchID1') IS NULL
    EXEC('ALTER TABLE [mis].[Gold_Fact_CPD_Sold] ADD [BranchID1] varchar(36) NULL;');

IF COL_LENGTH('mis.Gold_Fact_CPD_Sold', 'BranchID2') IS NULL
    EXEC('ALTER TABLE [mis].[Gold_Fact_CPD_Sold] ADD [BranchID2] varchar(36) NULL;');

TRUNCATE TABLE [ATK].[mis].[Gold_Fact_CPD_Sold];

------------------------------------------------------------
-- 2) NeedDates / NeedClients
------------------------------------------------------------
DROP TABLE IF EXISTS #need_dates;
DROP TABLE IF EXISTS #need_clients;

SELECT DISTINCT td.CPDDate AS NeedDate
INTO #need_dates
FROM [ATK].[mis].[Silver_CPD_TaskDays] td;

CREATE UNIQUE CLUSTERED INDEX CX_need_dates ON #need_dates(NeedDate);

SELECT DISTINCT td.ClientID
INTO #need_clients
FROM [ATK].[mis].[Silver_CPD_TaskDays] td;

CREATE UNIQUE CLUSTERED INDEX CX_need_clients ON #need_clients(ClientID);

------------------------------------------------------------
-- 2.1) Client Branch fallback из контрагентов
------------------------------------------------------------
DROP TABLE IF EXISTS #client_branch;

SELECT
      nc.ClientID
    , CAST(k.[Контрагенты Филиал ID] AS varchar(36)) AS ClientBranchID
INTO #client_branch
FROM #need_clients nc
LEFT JOIN [ATK].[mis].[Bronze_Справочники.Контрагенты] k
  ON k.[Контрагенты ID] = nc.ClientID;

CREATE UNIQUE CLUSTERED INDEX CX_client_branch ON #client_branch (ClientID);

------------------------------------------------------------
-- 3) SoldDaily + SoldClient
------------------------------------------------------------
DROP TABLE IF EXISTS #sold_daily;
DROP TABLE IF EXISTS #sold_client;

SELECT
      f.SoldDate
    , f.ClientID
    , f.CreditID
    , CAST(f.BranchID   AS varchar(36)) AS BranchID
    , CAST(f.GroupOwner AS varchar(36)) AS GroupOwner
    , SUM(COALESCE(f.SoldAmount,0))     AS SoldCredit
INTO #sold_daily
FROM [ATK].[mis].[Silver_Sold_Owner] f
JOIN #need_dates   d ON d.NeedDate = f.SoldDate
JOIN #need_clients c ON c.ClientID = f.ClientID
GROUP BY
      f.SoldDate
    , f.ClientID
    , f.CreditID
    , CAST(f.BranchID   AS varchar(36))
    , CAST(f.GroupOwner AS varchar(36));

CREATE CLUSTERED INDEX CX_sold_daily ON #sold_daily (ClientID, SoldDate);
CREATE INDEX IX_sold_daily_date_credit ON #sold_daily (SoldDate, CreditID);

SELECT
      SoldDate
    , ClientID
    , SUM(SoldCredit) AS SoldClient
INTO #sold_client
FROM #sold_daily
GROUP BY SoldDate, ClientID;

CREATE UNIQUE CLUSTERED INDEX CX_sold_client ON #sold_client (ClientID, SoldDate);

------------------------------------------------------------
-- 4) GroupOwner на дату (membership)
------------------------------------------------------------
DROP TABLE IF EXISTS #grp_day;

CREATE TABLE #grp_day
(
      CondID     varchar(36) NOT NULL
    , ClientID   varchar(36) NOT NULL
    , CPDDate    date        NOT NULL
    , GroupOwner varchar(36) NULL
);

INSERT INTO #grp_day (CondID, ClientID, CPDDate, GroupOwner)
SELECT
      td.CondID
    , td.ClientID
    , td.CPDDate
    , g.GroupOwner
FROM [ATK].[mis].[Silver_CPD_TaskDays] td
OUTER APPLY
(
    SELECT TOP (1)
        CAST(gm.GroupOwner AS varchar(36)) AS GroupOwner
    FROM [ATK].[mis].[Gold_Dim_GroupMembershipPeriods] gm
    WHERE gm.PersonID = td.ClientID
      AND td.CPDDate >= CAST(gm.PeriodStart AS date)
      AND td.CPDDate <  CAST(gm.PeriodEnd   AS date)
    ORDER BY gm.PeriodStart DESC
) g;

CREATE INDEX IX_grp_day_client_date ON #grp_day (ClientID, CPDDate);
CREATE INDEX IX_grp_day_cond_date   ON #grp_day (CondID, CPDDate);

------------------------------------------------------------
-- 5) SoldGroup (только нужные группы и даты)
------------------------------------------------------------
DROP TABLE IF EXISTS #need_groups;
DROP TABLE IF EXISTS #sold_group;

SELECT DISTINCT GroupOwner
INTO #need_groups
FROM #grp_day
WHERE GroupOwner IS NOT NULL AND GroupOwner <> '';

CREATE UNIQUE CLUSTERED INDEX CX_need_groups ON #need_groups(GroupOwner);

SELECT
      f.SoldDate
    , CAST(f.GroupOwner AS varchar(36)) AS GroupOwner
    , SUM(COALESCE(f.SoldAmount,0))     AS SoldGroup
INTO #sold_group
FROM [ATK].[mis].[Silver_Sold_Owner] f
JOIN #need_dates  d ON d.NeedDate = f.SoldDate
JOIN #need_groups g ON g.GroupOwner = CAST(f.GroupOwner AS varchar(36))
GROUP BY
      f.SoldDate,
      CAST(f.GroupOwner AS varchar(36));

CREATE UNIQUE CLUSTERED INDEX CX_sold_group ON #sold_group (GroupOwner, SoldDate);

------------------------------------------------------------
-- 6) Status as-of (CreditRisk/LegalRisk)
------------------------------------------------------------
DROP TABLE IF EXISTS #cpd_status;

CREATE TABLE #cpd_status
(
      CondID     varchar(36) NOT NULL
    , CPDDate    date        NOT NULL
    , CreditRisk varchar(64) NULL
    , LegalRisk  varchar(64) NULL
);

INSERT INTO #cpd_status (CondID, CPDDate, CreditRisk, LegalRisk)
SELECT
      td.CondID
    , td.CPDDate
    , s.CreditRisk
    , s.LegalRisk
FROM [ATK].[mis].[Silver_CPD_TaskDays] td
OUTER APPLY
(
    SELECT TOP (1)
          CAST(cpd.CreditRisk AS varchar(64)) AS CreditRisk
        , CAST(cpd.LegalRisk  AS varchar(64)) AS LegalRisk
    FROM [ATK].[mis].[Gold_Fact_CPD] cpd
    WHERE cpd.ID = td.CondID
      AND CAST(cpd.Period AS date) <= td.CPDDate
    ORDER BY CAST(cpd.Period AS date) DESC
) s;

CREATE INDEX IX_cpd_status ON #cpd_status (CondID, CPDDate);

------------------------------------------------------------
-- 6.1) BranchID1/BranchID2 из Silver_Resp_SCD по (CreditID, CPDDate)
------------------------------------------------------------
DROP TABLE IF EXISTS #resp_keys;
DROP TABLE IF EXISTS #resp_day;

SELECT DISTINCT k.CreditID, k.CPDDate
INTO #resp_keys
FROM
(
    SELECT sd.CreditID, sd.SoldDate AS CPDDate
    FROM #sold_daily sd
    UNION
    SELECT td.TaskCreditID AS CreditID, td.CPDDate
    FROM [ATK].[mis].[Silver_CPD_TaskDays] td
    WHERE td.TaskCreditID IS NOT NULL AND LTRIM(RTRIM(td.TaskCreditID)) <> ''
) k;

CREATE UNIQUE CLUSTERED INDEX CX_resp_keys ON #resp_keys (CreditID, CPDDate);

CREATE TABLE #resp_day
(
      CreditID  varchar(36) NOT NULL
    , CPDDate   date        NOT NULL
    , BranchID1 varchar(36) NULL
    , BranchID2 varchar(36) NULL
);

INSERT INTO #resp_day (CreditID, CPDDate, BranchID1, BranchID2)
SELECT
      rk.CreditID
    , rk.CPDDate
    , CAST(r.BranchID      AS varchar(36)) AS BranchID1
    , CAST(r.FinalBranchID AS varchar(36)) AS BranchID2
FROM #resp_keys rk
OUTER APPLY
(
    SELECT TOP (1)
        r.BranchID,
        r.FinalBranchID
    FROM [ATK].[mis].[Silver_Resp_SCD] r
    WHERE r.CreditID = rk.CreditID
      AND rk.CPDDate >= CAST(r.ValidFrom AS date)
      AND rk.CPDDate <  CAST(r.ValidTo   AS date)
    ORDER BY r.ValidFrom DESC
) r;

CREATE UNIQUE CLUSTERED INDEX CX_resp_day ON #resp_day (CreditID, CPDDate);

------------------------------------------------------------
-- 7) INSERT в итоговую таблицу (dynamic SQL)
------------------------------------------------------------
DECLARE @sql nvarchar(max) = N'
-- 7A) Реальные Sold строки (ТОЛЬКО когда TaskCreditID задан)
INSERT INTO [ATK].[mis].[Gold_Fact_CPD_Sold]
(
    CondID, CPDDate, CreditID, ClientID, GroupOwner, BranchID,
    BranchID1, BranchID2,
    SoldCredit, SoldClient, SoldGroup, CreditRisk, LegalRisk, LoadDttm
)
SELECT
      td.CondID
    , td.CPDDate
    , sd.CreditID
    , td.ClientID
    , COALESCE(NULLIF(sd.GroupOwner, ''''), gd.GroupOwner, '''') AS GroupOwner
    , COALESCE(NULLIF(sd.BranchID,   ''''), cb.ClientBranchID, '''') AS BranchID
    , COALESCE(NULLIF(rd.BranchID1,  ''''), cb.ClientBranchID, '''') AS BranchID1
    , COALESCE(NULLIF(rd.BranchID2,  ''''), cb.ClientBranchID, '''') AS BranchID2
    , COALESCE(sd.SoldCredit,0.00)
    , COALESCE(sc.SoldClient,0.00)
    , COALESCE(sg.SoldGroup,0.00)
    , st.CreditRisk
    , st.LegalRisk
    , GETDATE()
FROM [ATK].[mis].[Silver_CPD_TaskDays] td
JOIN #sold_daily sd
  ON sd.ClientID = td.ClientID
 AND sd.SoldDate = td.CPDDate
 AND td.TaskCreditID IS NOT NULL
 AND sd.CreditID = td.TaskCreditID
LEFT JOIN #grp_day gd
  ON gd.CondID = td.CondID AND gd.ClientID = td.ClientID AND gd.CPDDate = td.CPDDate
LEFT JOIN #sold_client sc
  ON sc.ClientID = td.ClientID AND sc.SoldDate = td.CPDDate
LEFT JOIN #sold_group sg
  ON sg.SoldDate = td.CPDDate
 AND sg.GroupOwner = COALESCE(NULLIF(sd.GroupOwner, ''''), gd.GroupOwner, '''')
LEFT JOIN #cpd_status st
  ON st.CondID = td.CondID AND st.CPDDate = td.CPDDate
LEFT JOIN #resp_day rd
  ON rd.CreditID = sd.CreditID AND rd.CPDDate = td.CPDDate
LEFT JOIN #client_branch cb
  ON cb.ClientID = td.ClientID;

-- 7B) Нулевые дни
INSERT INTO [ATK].[mis].[Gold_Fact_CPD_Sold]
(
    CondID, CPDDate, CreditID, ClientID, GroupOwner, BranchID,
    BranchID1, BranchID2,
    SoldCredit, SoldClient, SoldGroup, CreditRisk, LegalRisk, LoadDttm
)
SELECT
      td.CondID
    , td.CPDDate
    , COALESCE(td.TaskCreditID, '''')            AS CreditID
    , td.ClientID
    , COALESCE(gd.GroupOwner, '''')              AS GroupOwner
    , COALESCE(cb.ClientBranchID, '''')          AS BranchID
    , COALESCE(NULLIF(rd.BranchID1,  ''''), cb.ClientBranchID, '''') AS BranchID1
    , COALESCE(NULLIF(rd.BranchID2,  ''''), cb.ClientBranchID, '''') AS BranchID2
    , 0.00                                       AS SoldCredit
    , COALESCE(sc.SoldClient,0.00)               AS SoldClient
    , COALESCE(sg.SoldGroup,0.00)                AS SoldGroup
    , st.CreditRisk
    , st.LegalRisk
    , GETDATE()
FROM [ATK].[mis].[Silver_CPD_TaskDays] td
LEFT JOIN #grp_day gd
  ON gd.CondID = td.CondID AND gd.ClientID = td.ClientID AND gd.CPDDate = td.CPDDate
LEFT JOIN #sold_client sc
  ON sc.ClientID = td.ClientID AND sc.SoldDate = td.CPDDate
LEFT JOIN #sold_group sg
  ON sg.SoldDate = td.CPDDate
 AND sg.GroupOwner = gd.GroupOwner
LEFT JOIN #cpd_status st
  ON st.CondID = td.CondID AND st.CPDDate = td.CPDDate
LEFT JOIN #resp_day rd
  ON rd.CreditID = td.TaskCreditID AND rd.CPDDate = td.CPDDate
LEFT JOIN #client_branch cb
  ON cb.ClientID = td.ClientID
WHERE
    (
        td.TaskCreditID IS NOT NULL
        AND NOT EXISTS
        (
            SELECT 1
            FROM #sold_daily sd
            WHERE sd.ClientID = td.ClientID
              AND sd.SoldDate = td.CPDDate
              AND sd.CreditID = td.TaskCreditID
        )
    )
 OR (
        td.TaskCreditID IS NULL
        AND NOT EXISTS
        (
            SELECT 1
            FROM [ATK].[mis].[Gold_Fact_CPD_Sold] x
            WHERE x.CondID  = td.CondID
              AND x.CPDDate = td.CPDDate
              AND x.CreditID = ''''
        )
    );
';

EXEC sys.sp_executesql @sql;

------------------------------------------------------------
-- 8) Контрольные цифры
------------------------------------------------------------
SELECT
    COUNT(*) AS CntGoldRows,
    COUNT(DISTINCT CondID) AS DistCondID,
    COUNT(DISTINCT ClientID) AS DistClientID
FROM [ATK].[mis].[Gold_Fact_CPD_Sold];
