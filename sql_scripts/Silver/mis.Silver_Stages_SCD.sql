------------------------------------------------------------
-- 1) Ensure target table exists
------------------------------------------------------------
IF OBJECT_ID('mis.Silver_Stages_SCD','U') IS NULL
BEGIN
    CREATE TABLE mis.Silver_Stages_SCD 
	(
        CreditID   VARCHAR(36)   NOT NULL,
        ValidFrom  DATE          NOT NULL,
        ValidTo    DATE          NOT NULL,
        StageName  NVARCHAR(50)  NULL,
        CONSTRAINT PK_Silver_Stages_SCD PRIMARY KEY (CreditID, ValidFrom)
    );
END
ELSE
BEGIN
    TRUNCATE TABLE mis.Silver_Stages_SCD;
END;

------------------------------------------------------------
-- 2) Rebuild SCD
------------------------------------------------------------
;WITH src AS (
    SELECT
        CAST([СтадииКредитов Период] AS DATE) AS PeriodDate,
        [СтадииКредитов Кредит ID]           AS CreditID,
        [СтадииКредитов Стадия]              AS StageName,
        [СтадииКредитов ID]                  AS RowId
    FROM dbo.[РегистрыСведений.СтадииКредитов]
    WHERE [СтадииКредитов Кредит ID] IS NOT NULL
      AND [СтадииКредитов Период]    IS NOT NULL
),
dedup AS (
    SELECT
        CreditID, PeriodDate, StageName,
        ROW_NUMBER() OVER (PARTITION BY CreditID, PeriodDate ORDER BY RowId DESC) AS rn
    FROM src
),
day_rows AS (
    SELECT CreditID, PeriodDate, StageName
    FROM dedup
    WHERE rn = 1
),
borders AS (
    SELECT
        d.CreditID,
        d.PeriodDate AS ValidFrom,
        d.StageName,
        LAG(d.StageName) OVER (PARTITION BY d.CreditID ORDER BY d.PeriodDate) AS PrevStage
    FROM day_rows d
),
starts AS (
    SELECT CreditID, ValidFrom, StageName
    FROM borders
    WHERE ISNULL(PrevStage, N'#NULL#') <> ISNULL(StageName, N'#NULL#')
       OR PrevStage IS NULL
),
grid AS (
    SELECT
        CreditID,
        StageName,
        ValidFrom,
        LEAD(ValidFrom) OVER (PARTITION BY CreditID ORDER BY ValidFrom) AS NextFrom
    FROM starts
),
slices AS (
    SELECT
        CreditID,
        StageName,
        ValidFrom,
        COALESCE(DATEADD(day,-1,NextFrom), CONVERT(DATE,'9999-12-31')) AS ValidTo
    FROM grid
)
INSERT INTO mis.Silver_Stages_SCD 
           (CreditID, ValidFrom, ValidTo, StageName)
SELECT CreditID, ValidFrom, ValidTo, StageName
FROM slices;

------------------------------------------------------------
-- 3) Index under interval joins
------------------------------------------------------------
DECLARE @schema sysname = N'mis';
DECLARE @table  sysname = N'Silver_Stages_SCD';
DECLARE @stat   sysname = N'IX_Stages_ForIntervals';
DECLARE @obj_id int = OBJECT_ID(QUOTENAME(@schema)+N'.'+QUOTENAME(@table));

IF @obj_id IS NOT NULL
BEGIN
    IF EXISTS (SELECT 1 FROM sys.stats  WHERE object_id=@obj_id AND name=@stat)
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=@obj_id AND name=@stat)
    BEGIN
        DECLARE @sql NVARCHAR(4000)=
            N'DROP STATISTICS '+QUOTENAME(@schema)+N'.'+QUOTENAME(@table)+N'.'+QUOTENAME(@stat)+N';';
        EXEC (@sql);
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=@obj_id AND name=@stat)
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Stages_ForIntervals
            ON mis.Silver_Stages_SCD (CreditID, ValidFrom)
            INCLUDE (ValidTo, StageName);
    END;
END;
