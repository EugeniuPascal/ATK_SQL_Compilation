------------------------------------------------------------
-- 0) Набор спец-филиалов (которые нужно ИСКЛЮЧИТЬ и протягивать поверх)
------------------------------------------------------------
DECLARE @SpecialBranches TABLE (BranchID varchar(64) PRIMARY KEY);

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

CREATE TABLE mis.Silver_Resp_SCD (
    CreditID        varchar(64) NOT NULL,
    ValidFrom       date        NOT NULL,
    ValidTo         date        NOT NULL,
    BranchID        varchar(64) NULL,
    ExpertID        varchar(64) NULL,
    IsSpecialBranch bit         NOT NULL,
    FinalBranchID   varchar(64) NULL,
    FinalExpertID   varchar(64) NULL,
    CONSTRAINT PK_Resp_SCD PRIMARY KEY (CreditID, ValidFrom)
);

------------------------------------------------------------
-- 2) База по регистру: одна запись на дату (снимаем дубли)
------------------------------------------------------------
DECLARE @DateFrom date = '2023-09-01';

SELECT
    r.[ОтветственныеПоКредитамВыданным Кредит ID]            AS CreditID,
    CAST(r.[ОтветственныеПоКредитамВыданным Период] AS date) AS PeriodDate,
    r.[ОтветственныеПоКредитамВыданным Филиал ID]            AS BranchID,
    r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS ExpertID,
    ROW_NUMBER() OVER (
        PARTITION BY r.[ОтветственныеПоКредитамВыданным Кредит ID],
                     CAST(r.[ОтветственныеПоКредитамВыданным Период] AS date)
        ORDER BY r.[ОтветственныеПоКредитамВыданным Номер Строки] DESC,
                 r.[ОтветственныеПоКредитамВыданным ID] DESC
    ) AS rn
INTO #RespBaseRaw
FROM mis.[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным] r
WHERE r.[ОтветственныеПоКредитамВыданным Активность] = 1
  AND CAST(r.[ОтветственныеПоКредитамВыданным Период] AS date) >= @DateFrom;

SELECT CreditID, PeriodDate, BranchID, ExpertID
INTO #RespBase
FROM #RespBaseRaw
WHERE rn = 1;

DROP TABLE #RespBaseRaw;

------------------------------------------------------------
-- 3) Интервалы + протяжка
------------------------------------------------------------
;WITH stage AS (
    SELECT
        CreditID,
        PeriodDate AS ValidFrom,
        LEAD(PeriodDate) OVER (PARTITION BY CreditID ORDER BY PeriodDate) AS NextFrom,
        BranchID,
        ExpertID,
        CASE WHEN EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = BranchID)
             THEN 1 
			 ELSE 0 
	    END AS IsSpecialBranch,
        COALESCE(
		     SUM(CASE WHEN NOT EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = BranchID)
                 THEN 1 ELSE 0 
			     END
				 ) OVER (PARTITION BY CreditID ORDER BY PeriodDate ROWS UNBOUNDED PRECEDING), 0) AS grp
    FROM #RespBase
)
INSERT INTO mis.Silver_Resp_SCD (
    CreditID, ValidFrom, ValidTo,
    BranchID, ExpertID,
    IsSpecialBranch, FinalBranchID, FinalExpertID
)
SELECT
    s.CreditID,
    s.ValidFrom,
    COALESCE(DATEADD(DAY,-1,s.NextFrom), CONVERT(date,'9999-12-31')) AS ValidTo,
    s.BranchID,
    s.ExpertID,
    s.IsSpecialBranch,
COALESCE(
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = s.BranchID)
             AND s.BranchID IS NOT NULL
        THEN s.BranchID 
    END,
    MAX(ISNULL(
        CASE 
            WHEN NOT EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = s.BranchID)
            THEN s.BranchID 
        END, '')
    ) OVER (PARTITION BY s.CreditID, s.grp),
    s.BranchID
) AS FinalBranchID,

COALESCE(
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = s.BranchID)
             AND s.ExpertID IS NOT NULL
        THEN s.ExpertID 
    END,
    MAX(ISNULL(
        CASE 
            WHEN NOT EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = s.BranchID)
            THEN s.ExpertID 
        END, '')
    ) OVER (PARTITION BY s.CreditID, s.grp),
    s.ExpertID
) AS FinalExpertID
FROM stage s;

DROP TABLE #RespBase;
