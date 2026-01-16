USE [ATK];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

------------------------------------------------------------
-- 0) Drop and recreate Gold_Fact_CPD_Sold
------------------------------------------------------------
IF OBJECT_ID(N'mis.[Gold_Fact_CPD_Sold]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_CPD_Sold];
GO

CREATE TABLE mis.[Gold_Fact_CPD_Sold]
(
      CondID        VARCHAR(36)     NOT NULL,
      CPDDate       DATE            NOT NULL,
      CreditID      VARCHAR(36)     NULL,
      ClientID      VARCHAR(36)     NULL,
      GroupOwner    VARCHAR(36)     NULL,
      BranchID      VARCHAR(36)     NULL,
      BranchID1     VARCHAR(36)     NULL,
      BranchID2     VARCHAR(36)     NULL,
      SoldCredit    DECIMAL(18,2)   NULL,
      SoldClient    DECIMAL(18,2)   NULL,
      SoldGroup     DECIMAL(18,2)   NULL,
      CreditRisk    VARCHAR(64)     NULL,
      LegalRisk     VARCHAR(64)     NULL,
      LoadDttm      DATETIME2(0)    NOT NULL
);
GO

------------------------------------------------------------
-- 1) Determine latest SoldDate from Debt register
------------------------------------------------------------
DECLARE @AsOfDate date =
(
    SELECT MAX(d.[СуммыЗадолженностиПоПериодамПросрочки Дата])
    FROM mis.[Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] d
);

IF @AsOfDate IS NULL
    THROW 50002, 'Debt register is empty.', 1;

------------------------------------------------------------
-- 2) Prepare temp tables for CPD dates and clients
------------------------------------------------------------
DROP TABLE IF EXISTS #need_dates, #need_clients;

SELECT DISTINCT td.CPDDate AS NeedDate
INTO #need_dates
FROM mis.[2tbl_Silver_CPD_TaskDays] td;

CREATE UNIQUE CLUSTERED INDEX CX_need_dates ON #need_dates (NeedDate);

SELECT DISTINCT td.ClientID
INTO #need_clients
FROM mis.[2tbl_Silver_CPD_TaskDays] td;

CREATE UNIQUE CLUSTERED INDEX CX_need_clients ON #need_clients (ClientID);

------------------------------------------------------------
-- 3) Client Branch fallback
------------------------------------------------------------
DROP TABLE IF EXISTS #client_branch;

SELECT
      nc.ClientID,
      CAST(k.[Контрагенты Филиал ID] AS VARCHAR(36)) AS ClientBranchID
INTO #client_branch
FROM #need_clients nc
LEFT JOIN mis.[Bronze_Справочники.Контрагенты] k
  ON k.[Контрагенты ID] = nc.ClientID;

CREATE UNIQUE CLUSTERED INDEX CX_client_branch ON #client_branch (ClientID);

------------------------------------------------------------
-- 4) SOLD DAILY (Debt register)
------------------------------------------------------------
DROP TABLE IF EXISTS #sold_daily;

SELECT
      d.[СуммыЗадолженностиПоПериодамПросрочки Дата]       AS SoldDate,
      d.[СуммыЗадолженностиПоПериодамПросрочки Клиент ID] AS ClientID,
      d.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
      SUM(COALESCE(d.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит],0)) AS SoldCredit
INTO #sold_daily
FROM mis.[Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] d
JOIN #need_dates nd ON nd.NeedDate = d.[СуммыЗадолженностиПоПериодамПросрочки Дата]
JOIN #need_clients nc ON nc.ClientID = d.[СуммыЗадолженностиПоПериодамПросрочки Клиент ID]
GROUP BY
      d.[СуммыЗадолженностиПоПериодамПросрочки Дата],
      d.[СуммыЗадолженностиПоПериодамПросрочки Клиент ID],
      d.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID];

CREATE CLUSTERED INDEX CX_sold_daily ON #sold_daily (ClientID, SoldDate);
CREATE INDEX IX_sold_daily_date_credit ON #sold_daily (SoldDate, CreditID);

------------------------------------------------------------
-- 5) SOLD CLIENT
------------------------------------------------------------
DROP TABLE IF EXISTS #sold_client;

SELECT
      SoldDate,
      ClientID,
      SUM(SoldCredit) AS SoldClient
INTO #sold_client
FROM #sold_daily
GROUP BY SoldDate, ClientID;

CREATE UNIQUE CLUSTERED INDEX CX_sold_client ON #sold_client (ClientID, SoldDate);

------------------------------------------------------------
-- 6) GROUP OWNER AS-OF DATE
------------------------------------------------------------
DROP TABLE IF EXISTS #grp_day;

CREATE TABLE #grp_day
(
      CondID     VARCHAR(36) NOT NULL,
      ClientID   VARCHAR(36) NOT NULL,
      CPDDate    DATE        NOT NULL,
      GroupOwner VARCHAR(36) NULL
);

INSERT INTO #grp_day
SELECT
      td.CondID,
      td.ClientID,
      td.CPDDate,
      CAST(gm.GroupOwner AS VARCHAR(36))
FROM mis.[2tbl_Silver_CPD_TaskDays] td
OUTER APPLY
(
    SELECT TOP (1) gm.GroupOwner
    FROM mis.Gold_Dim_GroupMembershipPeriods gm
    WHERE gm.PersonID = td.ClientID
      AND td.CPDDate >= CAST(gm.PeriodStart AS DATE)
      AND td.CPDDate <  CAST(gm.PeriodEnd   AS DATE)
    ORDER BY gm.PeriodStart DESC
) gm;

CREATE INDEX IX_grp_day ON #grp_day (ClientID, CPDDate);

------------------------------------------------------------
-- 7) SOLD GROUP
------------------------------------------------------------
DROP TABLE IF EXISTS #sold_group;

SELECT
      d.SoldDate,
      g.GroupOwner,
      SUM(d.SoldCredit) AS SoldGroup
INTO #sold_group
FROM #sold_daily d
JOIN #grp_day g
  ON g.ClientID = d.ClientID
 AND g.CPDDate  = d.SoldDate
GROUP BY d.SoldDate, g.GroupOwner;

CREATE UNIQUE CLUSTERED INDEX CX_sold_group ON #sold_group (GroupOwner, SoldDate);

------------------------------------------------------------
-- 8) CPD STATUS AS-OF (CreditRisk / LegalRisk)
------------------------------------------------------------
DROP TABLE IF EXISTS #cpd_status;

CREATE TABLE #cpd_status
(
      CondID     VARCHAR(36),
      CPDDate    DATE,
      CreditRisk VARCHAR(64),
      LegalRisk  VARCHAR(64)
);

INSERT INTO #cpd_status
SELECT
      td.CondID,
      td.CPDDate,
      s.CreditRisk,
      s.LegalRisk
FROM mis.[2tbl_Silver_CPD_TaskDays] td
OUTER APPLY
(
    SELECT TOP (1)
          CAST(f.CreditRisk AS VARCHAR(64)) AS CreditRisk,
          CAST(f.LegalRisk  AS VARCHAR(64)) AS LegalRisk
    FROM mis.Gold_Fact_CPD f
    WHERE f.ID = td.CondID
      AND CAST(f.Period AS DATE) <= td.CPDDate
    ORDER BY f.Period DESC
) s;

CREATE INDEX IX_cpd_status ON #cpd_status (CondID, CPDDate);

------------------------------------------------------------
-- 9) RESPONSIBILITY (BranchID1 / BranchID2)
------------------------------------------------------------
DROP TABLE IF EXISTS #resp_day;

SELECT DISTINCT
      k.CreditID,
      k.CPDDate,
      CAST(r.BranchID      AS VARCHAR(36)) AS BranchID1,
      CAST(r.FinalBranchID AS VARCHAR(36)) AS BranchID2
INTO #resp_day
FROM
(
    SELECT CreditID, SoldDate AS CPDDate FROM #sold_daily
    UNION
    SELECT TaskCreditID, CPDDate
    FROM mis.[2tbl_Silver_CPD_TaskDays]
    WHERE TaskCreditID IS NOT NULL
) k
OUTER APPLY
(
    SELECT TOP (1) *
    FROM mis.Silver_Resp_SCD r
    WHERE r.CreditID = k.CreditID
      AND k.CPDDate >= CAST(r.ValidFrom AS DATE)
      AND k.CPDDate <  CAST(r.ValidTo   AS DATE)
    ORDER BY r.ValidFrom DESC
) r;

CREATE UNIQUE CLUSTERED INDEX CX_resp_day ON #resp_day (CreditID, CPDDate);

------------------------------------------------------------
-- 10) FINAL INSERT
------------------------------------------------------------
INSERT INTO mis.Gold_Fact_CPD_Sold
(
      CondID, CPDDate, CreditID, ClientID, GroupOwner,
      BranchID, BranchID1, BranchID2,
      SoldCredit, SoldClient, SoldGroup,
      CreditRisk, LegalRisk, LoadDttm
)
SELECT
      td.CondID,
      td.CPDDate,
      COALESCE(sd.CreditID, td.TaskCreditID, ''),
      td.ClientID,
      COALESCE(gd.GroupOwner, ''),
      COALESCE(cb.ClientBranchID, ''),
      COALESCE(rd.BranchID1, cb.ClientBranchID, ''),
      COALESCE(rd.BranchID2, cb.ClientBranchID, ''),
      COALESCE(sd.SoldCredit, 0),
      COALESCE(sc.SoldClient, 0),
      COALESCE(sg.SoldGroup, 0),
      st.CreditRisk,
      st.LegalRisk,
      GETDATE()
FROM mis.[2tbl_Silver_CPD_TaskDays] td
LEFT JOIN #sold_daily sd
  ON sd.ClientID = td.ClientID
 AND sd.SoldDate = td.CPDDate
 AND sd.CreditID = td.TaskCreditID
LEFT JOIN #sold_client sc
  ON sc.ClientID = td.ClientID AND sc.SoldDate = td.CPDDate
LEFT JOIN #grp_day gd
  ON gd.CondID = td.CondID AND gd.CPDDate = td.CPDDate
LEFT JOIN #sold_group sg
  ON sg.SoldDate = td.CPDDate AND sg.GroupOwner = gd.GroupOwner
LEFT JOIN #cpd_status st
  ON st.CondID = td.CondID AND st.CPDDate = td.CPDDate
LEFT JOIN #resp_day rd
  ON rd.CreditID = td.TaskCreditID AND rd.CPDDate = td.CPDDate
LEFT JOIN #client_branch cb
  ON cb.ClientID = td.ClientID;


