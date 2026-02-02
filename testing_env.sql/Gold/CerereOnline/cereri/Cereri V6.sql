USE [ATK];
SET NOCOUNT ON;
SET XACT_ABORT ON;

--------------------------------------------------------------------------------
-- 0) Helper functions:
--    1) mis.fn_WorkMinutesSigned         -> ALL days (как было)
--    2) mis.fn_WorkMinutesSigned_MonFri  -> Mon-Fri only (как в Cereri v2)
--------------------------------------------------------------------------------
IF OBJECT_ID('mis.fn_WorkMinutesSigned', 'FN') IS NOT NULL
    DROP FUNCTION mis.fn_WorkMinutesSigned;
GO

CREATE FUNCTION mis.fn_WorkMinutesSigned
(
      @A           datetime2(0)
    , @B           datetime2(0)
    , @StartMinute int
    , @EndMinute   int
)
RETURNS decimal(18,2)
AS
BEGIN
    IF @A IS NULL OR @B IS NULL RETURN NULL;
    IF @StartMinute IS NULL OR @EndMinute IS NULL RETURN NULL;
    IF @EndMinute <= @StartMinute RETURN NULL;

    DECLARE @Sign int = CASE WHEN @B >= @A THEN 1 ELSE -1 END;
    DECLARE @S datetime2(0) = CASE WHEN @B >= @A THEN @A ELSE @B END;
    DECLARE @E datetime2(0) = CASE WHEN @B >= @A THEN @B ELSE @A END;

    IF @E <= @S RETURN NULL;

    DECLARE @SD date = CAST(@S AS date);
    DECLARE @ED date = CAST(@E AS date);

    DECLARE @Minutes float = 0.0;

    DECLARE @DayStart datetime2(0);
    DECLARE @DayEnd   datetime2(0);

    IF @SD = @ED
    BEGIN
        SET @DayStart = DATEADD(minute, @StartMinute, CAST(@SD AS datetime2(0)));
        SET @DayEnd   = DATEADD(minute, @EndMinute,   CAST(@SD AS datetime2(0)));

        DECLARE @From datetime2(0) = CASE WHEN @S > @DayStart THEN @S ELSE @DayStart END;
        DECLARE @To   datetime2(0) = CASE WHEN @E < @DayEnd   THEN @E ELSE @DayEnd   END;

        IF @To > @From
            SET @Minutes = DATEDIFF_BIG(second, @From, @To) / 60.0;
        ELSE
            SET @Minutes = 0.0;
    END
    ELSE
    BEGIN
        -- start day
        SET @DayStart = DATEADD(minute, @StartMinute, CAST(@SD AS datetime2(0)));
        SET @DayEnd   = DATEADD(minute, @EndMinute,   CAST(@SD AS datetime2(0)));

        DECLARE @From1 datetime2(0) = CASE WHEN @S > @DayStart THEN @S ELSE @DayStart END;
        IF @DayEnd > @From1
            SET @Minutes = @Minutes + (DATEDIFF_BIG(second, @From1, @DayEnd) / 60.0);

        -- full days between
        DECLARE @FullDays int = DATEDIFF(day, DATEADD(day, 1, @SD), @ED);
        IF @FullDays > 0
            SET @Minutes = @Minutes + (@FullDays * (@EndMinute - @StartMinute));

        -- end day
        SET @DayStart = DATEADD(minute, @StartMinute, CAST(@ED AS datetime2(0)));
        SET @DayEnd   = DATEADD(minute, @EndMinute,   CAST(@ED AS datetime2(0)));

        DECLARE @To2 datetime2(0) = CASE WHEN @E < @DayEnd THEN @E ELSE @DayEnd END;
        IF @To2 > @DayStart
            SET @Minutes = @Minutes + (DATEDIFF_BIG(second, @DayStart, @To2) / 60.0);
    END

    RETURN CAST(ROUND(@Minutes, 2) AS decimal(18,2)) * CAST(@Sign AS decimal(18,2));
END;
GO

IF OBJECT_ID('mis.fn_WorkMinutesSigned_MonFri', 'FN') IS NOT NULL
    DROP FUNCTION mis.fn_WorkMinutesSigned_MonFri;
GO

CREATE FUNCTION mis.fn_WorkMinutesSigned_MonFri
(
      @A           datetime2(0)
    , @B           datetime2(0)
    , @StartMinute int
    , @EndMinute   int
)
RETURNS decimal(18,2)
AS
BEGIN
    IF @A IS NULL OR @B IS NULL RETURN NULL;
    IF @StartMinute IS NULL OR @EndMinute IS NULL RETURN NULL;
    IF @EndMinute <= @StartMinute RETURN NULL;

    DECLARE @Sign int = CASE WHEN @B >= @A THEN 1 ELSE -1 END;
    DECLARE @S datetime2(0) = CASE WHEN @B >= @A THEN @A ELSE @B END;
    DECLARE @E datetime2(0) = CASE WHEN @B >= @A THEN @B ELSE @A END;

    IF @E <= @S RETURN NULL;

    DECLARE @SD date = CAST(@S AS date);
    DECLARE @ED date = CAST(@E AS date);

    DECLARE @Minutes float = 0.0;

    -- 1900-01-01 = Monday => 1=Mon..7=Sun (без DATEFIRST)
    DECLARE @WSD int = (DATEDIFF(day, CONVERT(date,'19000101'), @SD) % 7) + 1;
    DECLARE @WED int = (DATEDIFF(day, CONVERT(date,'19000101'), @ED) % 7) + 1;

    DECLARE @DayStart datetime2(0);
    DECLARE @DayEnd   datetime2(0);

    -- same day
    IF @SD = @ED
    BEGIN
        IF @WSD BETWEEN 1 AND 5
        BEGIN
            SET @DayStart = DATEADD(minute, @StartMinute, CAST(@SD AS datetime2(0)));
            SET @DayEnd   = DATEADD(minute, @EndMinute,   CAST(@SD AS datetime2(0)));

            DECLARE @From datetime2(0) = CASE WHEN @S > @DayStart THEN @S ELSE @DayStart END;
            DECLARE @To   datetime2(0) = CASE WHEN @E < @DayEnd   THEN @E ELSE @DayEnd   END;

            IF @To > @From
                SET @Minutes = DATEDIFF_BIG(second, @From, @To) / 60.0;
        END

        RETURN CAST(ROUND(@Minutes, 2) AS decimal(18,2)) * CAST(@Sign AS decimal(18,2));
    END

    -- start day (Mon-Fri)
    IF @WSD BETWEEN 1 AND 5
    BEGIN
        SET @DayStart = DATEADD(minute, @StartMinute, CAST(@SD AS datetime2(0)));
        SET @DayEnd   = DATEADD(minute, @EndMinute,   CAST(@SD AS datetime2(0)));

        DECLARE @From1 datetime2(0) = CASE WHEN @S > @DayStart THEN @S ELSE @DayStart END;
        IF @DayEnd > @From1
            SET @Minutes = @Minutes + (DATEDIFF_BIG(second, @From1, @DayEnd) / 60.0);
    END

    -- full days between (only weekdays)
    DECLARE @MStart date = DATEADD(day, 1, @SD);
    DECLARE @MEnd   date = DATEADD(day,-1, @ED);

    IF @MStart <= @MEnd
    BEGIN
        DECLARE @TotalDays int = DATEDIFF(day, @MStart, @MEnd) + 1;
        DECLARE @FullWeeks int = @TotalDays / 7;
        DECLARE @Rem      int = @TotalDays % 7;

        DECLARE @Weekdays int = @FullWeeks * 5;

        DECLARE @i int = 0;
        WHILE @i < @Rem
        BEGIN
            DECLARE @d date = DATEADD(day, @i, @MStart);
            DECLARE @wd int = (DATEDIFF(day, CONVERT(date,'19000101'), @d) % 7) + 1;
            IF @wd BETWEEN 1 AND 5 SET @Weekdays += 1;
            SET @i += 1;
        END

        SET @Minutes = @Minutes + (@Weekdays * (@EndMinute - @StartMinute));
    END

    -- end day (Mon-Fri)
    IF @WED BETWEEN 1 AND 5
    BEGIN
        SET @DayStart = DATEADD(minute, @StartMinute, CAST(@ED AS datetime2(0)));
        SET @DayEnd   = DATEADD(minute, @EndMinute,   CAST(@ED AS datetime2(0)));

        DECLARE @To2 datetime2(0) = CASE WHEN @E < @DayEnd THEN @E ELSE @DayEnd END;
        IF @To2 > @DayStart
            SET @Minutes = @Minutes + (DATEDIFF_BIG(second, @DayStart, @To2) / 60.0);
    END

    RETURN CAST(ROUND(@Minutes, 2) AS decimal(18,2)) * CAST(@Sign AS decimal(18,2));
END;
GO

--------------------------------------------------------------------------------
-- 0A) Calendar tables (temp) "по примеру графика"
--     1) #Dim_WorkCalendar_All_08_20    -> Mon-Sun, 08:00-20:00 (720)
--     2) #Dim_WorkCalendar_MonFri_08_18 -> Mon-Fri, 08:00-18:00 (600), weekend=0
--------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#Dim_WorkCalendar_All_08_20') IS NOT NULL DROP TABLE #Dim_WorkCalendar_All_08_20;
IF OBJECT_ID('tempdb..#Dim_WorkCalendar_MonFri_08_18') IS NOT NULL DROP TABLE #Dim_WorkCalendar_MonFri_08_18;

CREATE TABLE #Dim_WorkCalendar_All_08_20
(
      [Date]            date        NOT NULL
    , IsWeekend         bit         NOT NULL
    , WorkStartDttm     datetime2(0) NOT NULL
    , WorkEndDttm       datetime2(0) NOT NULL
    , WorkMinutesPerDay int         NOT NULL
    , CumWorkMinutes    bigint      NOT NULL
    , CONSTRAINT PK__CalAll PRIMARY KEY CLUSTERED ([Date])
);

CREATE TABLE #Dim_WorkCalendar_MonFri_08_18
(
      [Date]            date        NOT NULL
    , IsWeekend         bit         NOT NULL
    , WorkStartDttm     datetime2(0) NOT NULL
    , WorkEndDttm       datetime2(0) NOT NULL
    , WorkMinutesPerDay int         NOT NULL
    , CumWorkMinutes    bigint      NOT NULL
    , CONSTRAINT PK__CalMonFri PRIMARY KEY CLUSTERED ([Date])
);

DECLARE @CalStart date = '2023-01-01';
DECLARE @CalEnd   date = DATEADD(year, 5, CONVERT(date, GETDATE()));

;WITH N AS
(
    SELECT TOP (DATEDIFF(day, @CalStart, @CalEnd) + 1)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
),
d AS
(
    SELECT [Date] = DATEADD(day, n, @CalStart)
    FROM N
),
x AS
(
    SELECT
          [Date]
        , WDay = (DATEDIFF(day, CONVERT(date,'19000101'), [Date]) % 7) + 1  -- 1=Mon..7=Sun
    FROM d
),
src AS
(
    SELECT
          [Date]
        , WDay
        , IsWeekend = CASE WHEN WDay IN (6,7) THEN 1 ELSE 0 END
    FROM x
)
INSERT INTO #Dim_WorkCalendar_All_08_20
(
    [Date], IsWeekend, WorkStartDttm, WorkEndDttm, WorkMinutesPerDay, CumWorkMinutes
)
SELECT
      s.[Date]
    , s.IsWeekend
    , DATEADD(minute, 8*60,  CAST(s.[Date] AS datetime2(0)))  -- 08:00
    , DATEADD(minute, 20*60, CAST(s.[Date] AS datetime2(0)))  -- 20:00
    , 720
    , SUM(CAST(720 AS bigint)) OVER (ORDER BY s.[Date] ROWS UNBOUNDED PRECEDING)
FROM src s;

;WITH N AS
(
    SELECT TOP (DATEDIFF(day, @CalStart, @CalEnd) + 1)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
),
d AS
(
    SELECT [Date] = DATEADD(day, n, @CalStart)
    FROM N
),
x AS
(
    SELECT
          [Date]
        , WDay = (DATEDIFF(day, CONVERT(date,'19000101'), [Date]) % 7) + 1
    FROM d
),
src AS
(
    SELECT
          [Date]
        , WDay
        , IsWeekend = CASE WHEN WDay IN (6,7) THEN 1 ELSE 0 END
    FROM x
)
INSERT INTO #Dim_WorkCalendar_MonFri_08_18
(
    [Date], IsWeekend, WorkStartDttm, WorkEndDttm, WorkMinutesPerDay, CumWorkMinutes
)
SELECT
      s.[Date]
    , s.IsWeekend
    , DATEADD(minute, 8*60,  CAST(s.[Date] AS datetime2(0)))  -- 08:00
    , DATEADD(minute, 18*60, CAST(s.[Date] AS datetime2(0)))  -- 18:00
    , CASE WHEN s.WDay BETWEEN 1 AND 5 THEN 600 ELSE 0 END
    , SUM(CAST(CASE WHEN s.WDay BETWEEN 1 AND 5 THEN 600 ELSE 0 END AS bigint))
        OVER (ORDER BY s.[Date] ROWS UNBOUNDED PRECEDING)
FROM src s;

--------------------------------------------------------------------------------
-- 1) Rebuild target table from f.* only (убираем дубли колонок!)
--------------------------------------------------------------------------------
IF OBJECT_ID('mis.Silver_CerereOnline_WithWebDates','U') IS NOT NULL
    DROP TABLE mis.Silver_CerereOnline_WithWebDates;

SELECT f.*
INTO mis.Silver_CerereOnline_WithWebDates
FROM [ATK].[mis].[Gold_Fact_CerereOnline] f;

--------------------------------------------------------------------------------
-- 2) Ensure required columns (add only if missing)
--------------------------------------------------------------------------------
IF COL_LENGTH('mis.Silver_CerereOnline_WithWebDates', 'Data autorizarii') IS NULL
    ALTER TABLE mis.Silver_CerereOnline_WithWebDates ADD [Data autorizarii] datetime2(0) NULL;

IF COL_LENGTH('mis.Silver_CerereOnline_WithWebDates', 'Autor Votare') IS NULL
    ALTER TABLE mis.Silver_CerereOnline_WithWebDates ADD [Autor Votare] nvarchar(255) NULL;

IF COL_LENGTH('mis.Silver_CerereOnline_WithWebDates', 'AutorVotare ID') IS NULL
    ALTER TABLE mis.Silver_CerereOnline_WithWebDates ADD [AutorVotare ID] varchar(36) NULL;

IF COL_LENGTH('mis.Silver_CerereOnline_WithWebDates', 'Autor decizie') IS NULL
    ALTER TABLE mis.Silver_CerereOnline_WithWebDates ADD [Autor decizie] nvarchar(255) NULL;

IF COL_LENGTH('mis.Silver_CerereOnline_WithWebDates', 'AutorDecizie ID') IS NULL
    ALTER TABLE mis.Silver_CerereOnline_WithWebDates ADD [AutorDecizie ID] varchar(36) NULL;

IF COL_LENGTH('mis.Silver_CerereOnline_WithWebDates', 'Кредиты Сегмент Доходов') IS NULL
    ALTER TABLE mis.Silver_CerereOnline_WithWebDates ADD [Кредиты Сегмент Доходов] nvarchar(255) NULL;

IF COL_LENGTH('mis.Silver_CerereOnline_WithWebDates', 'Tip Рассмотрения Заявки RO') IS NULL
    ALTER TABLE mis.Silver_CerereOnline_WithWebDates ADD [Tip Рассмотрения Заявки RO] nvarchar(50) NULL;

IF COL_LENGTH('mis.Silver_CerereOnline_WithWebDates', 'Viteza de decizie') IS NULL
    ALTER TABLE mis.Silver_CerereOnline_WithWebDates ADD [Viteza de decizie] decimal(18,2) NULL;

IF COL_LENGTH('mis.Silver_CerereOnline_WithWebDates', 'Viteza de votare') IS NULL
    ALTER TABLE mis.Silver_CerereOnline_WithWebDates ADD [Viteza de votare] decimal(18,2) NULL;

IF COL_LENGTH('mis.Silver_CerereOnline_WithWebDates', 'Viteza de procesare') IS NULL
    ALTER TABLE mis.Silver_CerereOnline_WithWebDates ADD [Viteza de procesare] decimal(18,2) NULL;

IF COL_LENGTH('mis.Silver_CerereOnline_WithWebDates', 'Analyse') IS NULL
    ALTER TABLE mis.Silver_CerereOnline_WithWebDates ADD [Analyse] decimal(18,2) NULL;

IF COL_LENGTH('mis.Silver_CerereOnline_WithWebDates', 'Viteza de votare CC') IS NULL
    ALTER TABLE mis.Silver_CerereOnline_WithWebDates ADD [Viteza de votare CC] decimal(18,2) NULL;

IF COL_LENGTH('mis.Silver_CerereOnline_WithWebDates', 'CC') IS NULL
    ALTER TABLE mis.Silver_CerereOnline_WithWebDates ADD [CC] decimal(18,2) NULL;

IF COL_LENGTH('mis.Silver_CerereOnline_WithWebDates', 'Disbusement speed') IS NULL
    ALTER TABLE mis.Silver_CerereOnline_WithWebDates ADD [Disbusement speed] decimal(18,2) NULL;

IF COL_LENGTH('mis.Silver_CerereOnline_WithWebDates', 'Total speed') IS NULL
    ALTER TABLE mis.Silver_CerereOnline_WithWebDates ADD [Total speed] decimal(18,2) NULL;

IF COL_LENGTH('mis.Silver_CerereOnline_WithWebDates', 'Timpul de asteptare') IS NULL
    ALTER TABLE mis.Silver_CerereOnline_WithWebDates ADD [Timpul de asteptare] decimal(18,2) NULL;

IF COL_LENGTH('mis.Silver_CerereOnline_WithWebDates', 'Viteza de decizie CC') IS NULL
    ALTER TABLE mis.Silver_CerereOnline_WithWebDates ADD [Viteza de decizie CC] decimal(18,2) NULL;

IF COL_LENGTH('mis.Silver_CerereOnline_WithWebDates', 'Viteza debursare(dupa procesare)') IS NULL
    ALTER TABLE mis.Silver_CerereOnline_WithWebDates ADD [Viteza debursare(dupa procesare)] decimal(18,2) NULL;

IF COL_LENGTH('mis.Silver_CerereOnline_WithWebDates', 'Viteza debursare(dupa Decizie)') IS NULL
    ALTER TABLE mis.Silver_CerereOnline_WithWebDates ADD [Viteza debursare(dupa Decizie)] decimal(18,2) NULL;

IF COL_LENGTH('mis.Silver_CerereOnline_WithWebDates', 'Depasire norma viteza') IS NULL
    ALTER TABLE mis.Silver_CerereOnline_WithWebDates ADD [Depasire norma viteza] bit NULL;

IF COL_LENGTH('mis.Silver_CerereOnline_WithWebDates', 'LoadDttm_Ext') IS NULL
    ALTER TABLE mis.Silver_CerereOnline_WithWebDates
        ADD [LoadDttm_Ext] datetime NOT NULL
            CONSTRAINT DF_Silver_CerereOnline_WithWebDates_LoadDttm DEFAULT (GETDATE());
GO

--------------------------------------------------------------------------------
-- 3) UPDATE with joins/CTEs
--    ВАЖНО: алиасы как в Cereri v2: Dep / InCC / ProcDttm / Tip
--------------------------------------------------------------------------------
;WITH d_src AS
(
    SELECT
          d.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID] AS CerereOnlineID
        , CAST(d.[ОбъединеннаяИнтернетЗаявка Дата] AS datetime2(0)) AS Dep
        , CAST(d.[ОбъединеннаяИнтернетЗаявка Дата Отправки на Рассмотрение] AS datetime2(0)) AS InCC
        , CAST(d.[ОбъединеннаяИнтернетЗаявка Дата Взятия в Работу] AS datetime2(0)) AS ProcDttm
        , d.[ОбъединеннаяИнтернетЗаявка Тип Рассмотрения Заявки] AS Tip
        , ROW_NUMBER() OVER
          (
              PARTITION BY d.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
              ORDER BY CAST(d.[ОбъединеннаяИнтернетЗаявка Дата] AS datetime2(0)) DESC,
                       d.[ОбъединеннаяИнтернетЗаявка ID] DESC
          ) AS rn
    FROM [ATK].[dbo].[Документы.ОбъединеннаяИнтернетЗаявка] d
    WHERE ISNULL(d.[ОбъединеннаяИнтернетЗаявка Проведен], 0) = 0
      AND ISNULL(d.[ОбъединеннаяИнтернетЗаявка Пометка Удаления], 0) = 0
      AND d.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID] IS NOT NULL
),
d_last AS
(
    SELECT CerereOnlineID, Dep, InCC, ProcDttm, Tip
    FROM d_src
    WHERE rn = 1
),
proto_pick AS
(
    SELECT
          p.[ПротоколКомитета Заявка ID] AS CerereOnlineID
        , p.[ПротоколКомитета ID]        AS ProtocolID
        , ROW_NUMBER() OVER
          (
              PARTITION BY p.[ПротоколКомитета Заявка ID]
              ORDER BY CAST(p.[ПротоколКомитета Дата] AS datetime2(0)) DESC,
                       p.[ПротоколКомитета ID] DESC
          ) AS rn
    FROM [ATK].[dbo].[Документы.ПротоколКомитета] p
    WHERE ISNULL(p.[ПротоколКомитета Пометка Удаления], 0) = 0
      AND p.[ПротоколКомитета Заявка ID] IS NOT NULL
      AND ISNULL(p.[ПротоколКомитета Вид Комитета], N'') = N'ПредоставлениеКредита'
),
proto_last AS
(
    SELECT CerereOnlineID, ProtocolID
    FROM proto_pick
    WHERE rn = 1
),
votes_ranked AS
(
    SELECT
          pl.CerereOnlineID
        , VoteDate =
            NULLIF(
                CAST(m.[ПротоколКомитета.ЧленыКомитета Дата Голоса] AS datetime2(0)),
                CAST('1753-01-01T00:00:00' AS datetime2(0))
            )
        , [Autor Votare]   = m.[ПротоколКомитета.ЧленыКомитета Член Комитета]
        , [AutorVotare ID] = m.[ПротоколКомитета.ЧленыКомитета Член Комитета ID]
        , rn = ROW_NUMBER() OVER
            (
                PARTITION BY pl.CerereOnlineID
                ORDER BY
                      CASE WHEN NULLIF(CAST(m.[ПротоколКомитета.ЧленыКомитета Дата Голоса] AS datetime2(0)),
                                       CAST('1753-01-01T00:00:00' AS datetime2(0))) IS NULL
                           THEN 1 ELSE 0 END,
                      NULLIF(CAST(m.[ПротоколКомитета.ЧленыКомитета Дата Голоса] AS datetime2(0)),
                             CAST('1753-01-01T00:00:00' AS datetime2(0))) ASC,
                      m.[ПротоколКомитета.ЧленыКомитета Член Комитета ID] ASC
            )
    FROM proto_last pl
    LEFT JOIN [ATK].[dbo].[Документы.ПротоколКомитета.ЧленыКомитета] m
      ON m.[ПротоколКомитета ID] = pl.ProtocolID
),
votes_min AS
(
    SELECT CerereOnlineID, VoteDate, [Autor Votare], [AutorVotare ID]
    FROM votes_ranked
    WHERE rn = 1
),
credits_dim AS
(
    SELECT
          c.[Кредиты ID] AS CreditID,
          MAX(c.[Кредиты Сегмент Доходов]) AS IncomeSeg
    FROM [ATK].[mis].[Bronze_Справочники.Кредиты] c
    GROUP BY c.[Кредиты ID]
),
users_dim AS
(
    SELECT
          u.[Пользователи ID] AS AuthorID,
          MAX(u.[Пользователи Сотрудник ID]) AS AutorDecizieID,
          MAX(u.[Пользователи Сотрудник])    AS AutorDecizie
    FROM [ATK].[dbo].[Справочники.Пользователи] u
    GROUP BY u.[Пользователи ID]
),
pay_pick AS
(
    SELECT
          p.[НаправлениеНаВыплату Кредит ID] AS CreditID
        , CAST(p.[НаправлениеНаВыплату Дата] AS datetime2(0)) AS DataAut
        , ROW_NUMBER() OVER
          (
              PARTITION BY p.[НаправлениеНаВыплату Кредит ID]
              ORDER BY CAST(p.[НаправлениеНаВыплату Дата] AS datetime2(0)) DESC,
                       p.[НаправлениеНаВыплату ID] DESC
          ) AS rn
    FROM [ATK].[dbo].[Документы.НаправлениеНаВыплату] p
    WHERE ISNULL(p.[НаправлениеНаВыплату Пометка Удаления], 0) = 0
      AND ISNULL(p.[НаправлениеНаВыплату Проведен], 0) = 0
      AND p.[НаправлениеНаВыплату Кредит ID] IS NOT NULL
),
pay_last AS
(
    SELECT CreditID, DataAut
    FROM pay_pick
    WHERE rn = 1
)
UPDATE t
SET
      t.[Autor Votare]            = v.[Autor Votare]
    , t.[AutorVotare ID]          = v.[AutorVotare ID]
    , t.[Autor decizie]           = u.[AutorDecizie]
    , t.[AutorDecizie ID]         = u.[AutorDecizieID]
    , t.[Кредиты Сегмент Доходов] = cr.IncomeSeg
    , t.[Data autorizarii]        = pay.DataAut

    , t.[Tip Рассмотрения Заявки RO] =
        CASE
            WHEN v.[AutorVotare ID] = '813100155D65040111ED171A45F42146' THEN N'Fara sunet'
            WHEN COALESCE(d.Tip, t.[Tip Рассмотрения Заявки]) = N'БезЗвонка'   THEN N'Fara sunet'
            WHEN COALESCE(d.Tip, t.[Tip Рассмотрения Заявки]) = N'Стандартный' THEN N'Standart'
            ELSE NULL
        END

    --------------------------------------------------------------------------------
    -- OLD speeds (как было): ALL DAYS 08-20
    --------------------------------------------------------------------------------
    , t.[Viteza de decizie] =
        mis.fn_WorkMinutesSigned(
            COALESCE(d.Dep, CAST(t.[Data depunerii cererii] AS datetime2(0))),
            CAST(t.[CommitteeDecisionDate] AS datetime2(0)),
            8*60, 20*60
        )

    , t.[Viteza de votare] =
        mis.fn_WorkMinutesSigned(
            COALESCE(d.Dep, CAST(t.[Data depunerii cererii] AS datetime2(0))),
            CAST(COALESCE(v.VoteDate, t.[Data Votarii]) AS datetime2(0)),
            8*60, 20*60
        )

    , t.[Viteza de procesare] =
        mis.fn_WorkMinutesSigned(
            COALESCE(d.ProcDttm, CAST(t.[Data procesarii] AS datetime2(0))),
            CAST(COALESCE(v.VoteDate, t.[Data Votarii]) AS datetime2(0)),
            8*60, 20*60
        )

    --------------------------------------------------------------------------------
    -- NEW formulas: Mon-Fri only (как ты попросил "не учитывать выходные")
    --------------------------------------------------------------------------------
    , t.[Analyse] =
        mis.fn_WorkMinutesSigned_MonFri(
            COALESCE(d.Dep,  CAST(t.[Data depunerii cererii] AS datetime2(0))),
            COALESCE(d.InCC, CAST(t.[Data inaintare la CC] AS datetime2(0))),
            8*60, 18*60
        )

    , t.[Viteza de votare CC] =
        CASE
            WHEN t.[BranchID] IN
            (
                'B4A7BE35292F478C43E38230566F5F97',
                '80E300155D010F0111E783EB9D2D0BD9',
                '810100155D01451511EA26363FF9CEA0',
                '975B0018FEFB2E3711DD498DDAA682E1',
                'B7B700155D65140C11EFB0AFF47A513B'
            )
            THEN mis.fn_WorkMinutesSigned_MonFri(
                     COALESCE(d.InCC, CAST(t.[Data inaintare la CC] AS datetime2(0))),
                     CAST(COALESCE(v.VoteDate, t.[Data Votarii]) AS datetime2(0)),
                     9*60, 18*60
                 )
            ELSE mis.fn_WorkMinutesSigned_MonFri(
                     COALESCE(d.InCC, CAST(t.[Data inaintare la CC] AS datetime2(0))),
                     CAST(COALESCE(v.VoteDate, t.[Data Votarii]) AS datetime2(0)),
                     8*60, 17*60
                 )
        END

    , t.[CC] =
        mis.fn_WorkMinutesSigned_MonFri(
            COALESCE(d.InCC, CAST(t.[Data inaintare la CC] AS datetime2(0))),
            CAST(t.[CommitteeDecisionDate] AS datetime2(0)),
            8*60, 18*60
        )

    , t.[Disbusement speed] =
        mis.fn_WorkMinutesSigned_MonFri(
            CAST(t.[CommitteeDecisionDate] AS datetime2(0)),
            pay.DataAut,
            8*60, 18*60
        )

    , t.[Total speed] =
        mis.fn_WorkMinutesSigned_MonFri(
            COALESCE(d.Dep, CAST(t.[Data depunerii cererii] AS datetime2(0))),
            pay.DataAut,
            8*60, 18*60
        )

    , t.[Timpul de asteptare] =
        mis.fn_WorkMinutesSigned_MonFri(
            COALESCE(d.Dep,      CAST(t.[Data depunerii cererii] AS datetime2(0))),
            COALESCE(d.ProcDttm, CAST(t.[Data procesarii] AS datetime2(0))),
            9*60, 18*60
        )

    , t.[Viteza de decizie CC] =
        mis.fn_WorkMinutesSigned_MonFri(
            COALESCE(d.Dep, CAST(t.[Data depunerii cererii] AS datetime2(0))),
            CAST(t.[CommitteeDecisionDate] AS datetime2(0)),
            8*60, 18*60
        )

    , t.[Viteza debursare(dupa procesare)] =
        mis.fn_WorkMinutesSigned_MonFri(
            COALESCE(d.ProcDttm, CAST(t.[Data procesarii] AS datetime2(0))),
            pay.DataAut,
            8*60, 18*60
        )

    , t.[Viteza debursare(dupa Decizie)] =
        mis.fn_WorkMinutesSigned_MonFri(
            CAST(t.[CommitteeDecisionDate] AS datetime2(0)),
            pay.DataAut,
            8*60, 18*60
        )

    --------------------------------------------------------------------------------
    -- Depasire norma viteza (оставил как было: ALL DAYS 08-20, чтобы не менять логику)
    --------------------------------------------------------------------------------
    , t.[Depasire norma viteza] =
        CASE
            WHEN mis.fn_WorkMinutesSigned(
                    COALESCE(d.Dep, CAST(t.[Data depunerii cererii] AS datetime2(0))),
                    CAST(COALESCE(v.VoteDate, t.[Data Votarii]) AS datetime2(0)),
                    8*60, 20*60
                 ) IS NULL THEN NULL
            WHEN (
                     cr.IncomeSeg LIKE N'Ipoteca%'
                  OR cr.IncomeSeg LIKE N'HIL%'
                  OR cr.IncomeSeg =  N'Consum non-business'
                 )
                 AND mis.fn_WorkMinutesSigned(
                        COALESCE(d.Dep, CAST(t.[Data depunerii cererii] AS datetime2(0))),
                        CAST(COALESCE(v.VoteDate, t.[Data Votarii]) AS datetime2(0)),
                        8*60, 20*60
                     ) > 420 THEN 1
            WHEN mis.fn_WorkMinutesSigned(
                    COALESCE(d.Dep, CAST(t.[Data depunerii cererii] AS datetime2(0))),
                    CAST(COALESCE(v.VoteDate, t.[Data Votarii]) AS datetime2(0)),
                    8*60, 20*60
                 ) > 120 THEN 1
            ELSE 0
        END

    , t.[LoadDttm_Ext] = GETDATE()
FROM mis.Silver_CerereOnline_WithWebDates t
LEFT JOIN d_last      d   ON d.CerereOnlineID = t.[ID]
LEFT JOIN votes_min   v   ON v.CerereOnlineID = t.[ID]
LEFT JOIN credits_dim cr  ON cr.CreditID      = t.[CreditID]
LEFT JOIN users_dim   u   ON u.AuthorID       = t.[AuthorID]
LEFT JOIN pay_last    pay ON pay.CreditID     = t.[CreditID];
GO

--------------------------------------------------------------------------------
-- 4) Минимальный контроль
--------------------------------------------------------------------------------
SELECT
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN [Data autorizarii] IS NOT NULL THEN 1 ELSE 0 END) AS HasAutorizarii,
    SUM(CASE WHEN [Analyse] IS NOT NULL THEN 1 ELSE 0 END) AS HasAnalyse,
    SUM(CASE WHEN [CC] IS NOT NULL THEN 1 ELSE 0 END) AS HasCC,
    SUM(CASE WHEN [Viteza de votare CC] IS NOT NULL THEN 1 ELSE 0 END) AS HasVotareCC,
    SUM(CASE WHEN [Depasire norma viteza] = 1 THEN 1 ELSE 0 END) AS DepasireCnt
FROM mis.Silver_CerereOnline_WithWebDates;
