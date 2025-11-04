USE [ATK];
SET NOCOUNT ON;

/* 1) Таблица */
IF OBJECT_ID('[ATK].[mis].[Silver_Stages_SCD]','U') IS NULL
BEGIN
    CREATE TABLE [ATK].[mis].[Silver_Stages_SCD] (
        CreditID   varchar(64)   NOT NULL,
        ValidFrom  date          NOT NULL,
        ValidTo    date          NOT NULL,
        StageName  nvarchar(200) NULL,
        CONSTRAINT PK_Silver_Stages_SCD PRIMARY KEY (CreditID, ValidFrom)
    );
END
ELSE
    TRUNCATE TABLE [ATK].[mis].[Silver_Stages_SCD];

/* 2) Пересборка без агрегатов, с сохранением NULL */
;WITH src AS (
    SELECT
        CAST([СтадииКредитов Период] AS date) AS PeriodDate,
        [СтадииКредитов Кредит ID]           AS CreditID,
        [СтадииКредитов Стадия]              AS StageName,
        [СтадииКредитов ID]                  AS RowId
    FROM [ATK].[dbo].[РегистрыСведений.СтадииКредитов]
    WHERE [СтадииКредитов Кредит ID] IS NOT NULL
      AND [СтадииКредитов Период]    IS NOT NULL
),
-- Дедуп внутри дня: берём «последнюю» запись по дате (при множественных — по ID)
dedup AS (
    SELECT
        CreditID, PeriodDate, StageName,
        ROW_NUMBER() OVER (
            PARTITION BY CreditID, PeriodDate
            ORDER BY RowId DESC
        ) AS rn
    FROM src
),
-- Оставляем по одной записи на день
day_rows AS (
    SELECT CreditID, PeriodDate, StageName
    FROM dedup
    WHERE rn = 1
),
-- Границы изменений: учитываем NULL как отдельное значение
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
    WHERE ISNULL(PrevStage,   N'#NULL#') <>
          ISNULL(StageName,   N'#NULL#')
       OR PrevStage IS NULL -- первая запись по кредиту
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
        COALESCE(DATEADD(day,-1,NextFrom), CONVERT(date,'9999-12-31')) AS ValidTo
    FROM grid
)
INSERT INTO [ATK].[mis].[Silver_Stages_SCD] (CreditID, ValidFrom, ValidTo, StageName)
SELECT CreditID, ValidFrom, ValidTo, StageName
FROM slices
ORDER BY CreditID, ValidFrom;

/* 3) Индекс под интервальные джоины (с защитой от конфликта со статистикой) */
DECLARE @schema sysname = N'mis';
DECLARE @table  sysname = N'Silver_Stages_SCD';
DECLARE @stat   sysname = N'IX_Stages_ForIntervals';
DECLARE @obj_id int     = OBJECT_ID(QUOTENAME(@schema)+N'.'+QUOTENAME(@table));

IF @obj_id IS NOT NULL
BEGIN
    IF EXISTS (SELECT 1 FROM sys.stats  WHERE object_id=@obj_id AND name=@stat)
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=@obj_id AND name=@stat)
    BEGIN
        DECLARE @sql nvarchar(4000)=
            N'DROP STATISTICS '+QUOTENAME(@schema)+N'.'+QUOTENAME(@table)+N'.'+QUOTENAME(@stat)+N';';
        EXEC (@sql);
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=@obj_id AND name=@stat)
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Stages_ForIntervals
            ON [mis].[Silver_Stages_SCD] (CreditID, ValidFrom)
            INCLUDE (ValidTo, StageName);
    END;
END;
