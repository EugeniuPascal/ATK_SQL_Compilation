USE [ATK];
SET NOCOUNT ON;

PRINT N'=== Пересборка [mis].[2tbl_Silver_Resp_SCD1] с протяжкой НЕ-спец значений (множественные спец-филиалы) ===';

DECLARE @DateFrom date = '2010-01-01';

------------------------------------------------------------
-- 0) Набор спец-филиалов (которые нужно ИСКЛЮЧИТЬ и протягивать поверх)
------------------------------------------------------------
DECLARE @SpecialBranches TABLE (BranchID varchar(64) PRIMARY KEY);

INSERT INTO @SpecialBranches (BranchID)
VALUES
  ('B73A00155D65140C11EDCF8EFC5B26C5'), -- существующий
  ('B8934CC39235AB0B41675ED45E7EE551'),
  ('B7D800155D65140C11F0316FD846B283'),
  ('80FE00155D65040111EB7DB987EF3B3A'),
  ('80FE00155D01451511EA2246DC87677D');

------------------------------------------------------------
-- 1) Пересоздаём таблицу назначения
------------------------------------------------------------
IF OBJECT_ID('[mis].[2tbl_Silver_Resp_SCD1]', 'U') IS NOT NULL
    DROP TABLE [mis].[2tbl_Silver_Resp_SCD1];

CREATE TABLE [mis].[2tbl_Silver_Resp_SCD1] (
    CreditID        varchar(64) NOT NULL,
    ValidFrom       date        NOT NULL,
    ValidTo         date        NOT NULL,
    BranchID        varchar(64) NULL,
    ExpertID        varchar(64) NULL,
    IsSpecialBranch bit         NOT NULL,
    FinalBranchID   varchar(64) NULL,
    FinalExpertID   varchar(64) NULL,
    CONSTRAINT PK_Resp_SCD1 PRIMARY KEY (CreditID, ValidFrom)
);

------------------------------------------------------------
-- 2) База по регистру: одна запись на дату (снимаем дубли)
------------------------------------------------------------
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
FROM [ATK].[mis].[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным] r
WHERE r.[ОтветственныеПоКредитамВыданным Активность] = 1
  AND CAST(r.[ОтветственныеПоКредитамВыданным Период] AS date) >= @DateFrom;

SELECT CreditID, PeriodDate, BranchID, ExpertID
INTO #RespBase
FROM #RespBaseRaw
WHERE rn = 1;

DROP TABLE #RespBaseRaw;

------------------------------------------------------------
-- 3) Интервалы + протяжка:
--    спец-филиалы = те, что входят в @SpecialBranches
------------------------------------------------------------
;WITH stage AS (
    SELECT
        CreditID,
        PeriodDate AS ValidFrom,
        LEAD(PeriodDate) OVER (PARTITION BY CreditID ORDER BY PeriodDate) AS NextFrom,
        BranchID,
        ExpertID,
        CASE WHEN EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = BranchID)
             THEN 1 ELSE 0 END AS IsSpecialBranch,
        -- Номер группы НЕ-спец записей (для каскадной протяжки)
        SUM(CASE WHEN NOT EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = BranchID)
                 THEN 1 ELSE 0 END)
            OVER (PARTITION BY CreditID ORDER BY PeriodDate ROWS UNBOUNDED PRECEDING) AS grp
    FROM #RespBase
)
INSERT INTO [mis].[2tbl_Silver_Resp_SCD1] (
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
    -- FinalBranchID: текущее НЕ-спец -> оно; иначе последний НЕ-спец в grp; если NULL — исходный BranchID
    COALESCE(
        CASE WHEN NOT EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = s.BranchID)
                  AND s.BranchID IS NOT NULL
             THEN s.BranchID END,
        MAX(CASE WHEN NOT EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = s.BranchID)
                 THEN s.BranchID END)
            OVER (PARTITION BY s.CreditID, s.grp),
        s.BranchID
    ) AS FinalBranchID,
    -- FinalExpertID: по той же логике
    COALESCE(
        CASE WHEN NOT EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = s.BranchID)
                  AND s.ExpertID IS NOT NULL
             THEN s.ExpertID END,
        MAX(CASE WHEN NOT EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = s.BranchID)
                 THEN s.ExpertID END)
            OVER (PARTITION BY s.CreditID, s.grp),
        s.ExpertID
    ) AS FinalExpertID
FROM stage s;

DROP TABLE #RespBase;

------------------------------------------------------------
-- 4) Итог
------------------------------------------------------------
DECLARE @cnt bigint;
SELECT @cnt = COUNT_BIG(*) FROM [mis].[2tbl_Silver_Resp_SCD1];
PRINT N'✅ Готово: [mis].[2tbl_Silver_Resp_SCD1] пересобрана. Строк: ' + CONVERT(varchar(30), @cnt);

-- (опционально) индексы под выборки на дату/кредит:
-- CREATE INDEX IX_Resp_SCD_Credit_FromTo ON [mis].[2tbl_Silver_Resp_SCD1](CreditID, ValidFrom, ValidTo)
--     INCLUDE (BranchID, ExpertID, FinalBranchID, FinalExpertID, IsSpecialBranch);
-- CREATE INDEX IX_Resp_SCD_FromTo ON [mis].[2tbl_Silver_Resp_SCD1](ValidFrom, ValidTo);
