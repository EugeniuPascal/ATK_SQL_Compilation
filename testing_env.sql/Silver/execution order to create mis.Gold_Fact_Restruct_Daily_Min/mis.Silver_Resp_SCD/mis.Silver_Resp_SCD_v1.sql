USE ATK;
GO

SET NOCOUNT ON;

------------------------------------------------------------
-- 0) Набор спец-филиалов
------------------------------------------------------------
DECLARE @SpecialBranches TABLE (BranchID VARCHAR(36) PRIMARY KEY);

INSERT INTO @SpecialBranches (BranchID)
VALUES
  ('B73A00155D65140C11EDCF8EFC5B26C5'),
  ('B8934CC39235AB0B41675ED45E7EE551'),
  ('B7D800155D65140C11F0316FD846B283'),
  ('80FE00155D65040111EB7DB987EF3B3A'),
  ('80FE00155D01451511EA2246DC87677D');

------------------------------------------------------------
-- 1) Пересоздаём таблицу назначения
------------------------------------------------------------
IF OBJECT_ID('mis.Silver_Resp_SCD', 'U') IS NOT NULL
    DROP TABLE mis.Silver_Resp_SCD;

CREATE TABLE mis.Silver_Resp_SCD 
(
    CreditID        VARCHAR(36) NOT NULL,
    ValidFrom       DATE        NOT NULL,
    ValidTo         DATE        NOT NULL,
    BranchID        VARCHAR(36) NULL,
    ExpertID        VARCHAR(36) NULL,
    IsSpecialBranch BIT         NOT NULL,
    FinalBranchID   VARCHAR(36) NULL,
    FinalExpertID   VARCHAR(36) NULL,
    CONSTRAINT PK_Resp_SCD PRIMARY KEY (CreditID, ValidFrom)
);

------------------------------------------------------------
-- 2) База по регистру: одна запись на дату (снимаем дубли)
------------------------------------------------------------
DECLARE @DateFrom DATE = '2023-09-01';

IF OBJECT_ID('tempdb..#RespBaseRaw') IS NOT NULL DROP TABLE #RespBaseRaw;
IF OBJECT_ID('tempdb..#RespBase') IS NOT NULL DROP TABLE #RespBase;

SELECT
    r.[ОтветственныеПоКредитамВыданным Кредит ID] AS CreditID,
    CAST(r.[ОтветственныеПоКредитамВыданным Период] AS DATE) AS PeriodDate,
    r.[ОтветственныеПоКредитамВыданным Филиал ID] AS BranchID,
    r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS ExpertID,
    ROW_NUMBER() OVER (
        PARTITION BY r.[ОтветственныеПоКредитамВыданным Кредит ID],
                     CAST(r.[ОтветственныеПоКредитамВыданным Период] AS DATE)
        ORDER BY r.[ОтветственныеПоКредитамВыданным Номер Строки] DESC,
                 r.[ОтветственныеПоКредитамВыданным ID] DESC
    ) AS rn
INTO #RespBaseRaw
FROM mis.[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным] r
WHERE r.[ОтветственныеПоКредитамВыданным Активность] = 1
  AND CAST(r.[ОтветственныеПоКредитамВыданным Период] AS DATE) >= @DateFrom;

SELECT CreditID, PeriodDate, BranchID, ExpertID
INTO #RespBase
FROM #RespBaseRaw
WHERE rn = 1;

DROP TABLE #RespBaseRaw;

------------------------------------------------------------
-- 3) Интервалы + протяжка с последним нормальным филиалом
------------------------------------------------------------
;WITH stage AS (
    SELECT
        r.CreditID,
        r.PeriodDate AS ValidFrom,
        LEAD(r.PeriodDate) OVER (PARTITION BY r.CreditID ORDER BY r.PeriodDate) AS NextFrom,
        r.BranchID,
        r.ExpertID,
        CASE WHEN EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = r.BranchID)
             THEN 1 ELSE 0 END AS IsSpecialBranch
    FROM #RespBase r
)
INSERT INTO mis.Silver_Resp_SCD
(
    CreditID, ValidFrom, ValidTo,
    BranchID, ExpertID,
    IsSpecialBranch, FinalBranchID, FinalExpertID
)
SELECT
    s.CreditID,
    s.ValidFrom,
    COALESCE(DATEADD(DAY,-1,s.NextFrom), '9999-12-31') AS ValidTo,
    s.BranchID,
    s.ExpertID,
    s.IsSpecialBranch,
    -- FinalBranchID: pick last non-special branch using OUTER APPLY
    COALESCE(nsb.LastBranchID, s.BranchID) AS FinalBranchID,
    COALESCE(nsb.LastExpertID, s.ExpertID) AS FinalExpertID
FROM stage s
OUTER APPLY
(
    SELECT TOP 1 r.BranchID AS LastBranchID, r.ExpertID AS LastExpertID
    FROM #RespBase r
    WHERE r.CreditID = s.CreditID
      AND r.BranchID NOT IN (SELECT BranchID FROM @SpecialBranches)
      AND r.PeriodDate <= s.ValidFrom
    ORDER BY r.PeriodDate DESC
) nsb;

DROP TABLE #RespBase;
