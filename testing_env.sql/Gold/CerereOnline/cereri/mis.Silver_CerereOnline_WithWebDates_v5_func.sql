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
    , TotalWorkMinutes    bigint      NOT NULL
    , CONSTRAINT PK__CalAll PRIMARY KEY CLUSTERED ([Date])
);

CREATE TABLE #Dim_WorkCalendar_MonFri_08_18
(
      [Date]            date        NOT NULL
    , IsWeekend         bit         NOT NULL
    , WorkStartDttm     datetime2(0) NOT NULL
    , WorkEndDttm       datetime2(0) NOT NULL
    , WorkMinutesPerDay int         NOT NULL
    , TotalWorkMinutes    bigint      NOT NULL
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
    [Date], IsWeekend, WorkStartDttm, WorkEndDttm, WorkMinutesPerDay, TotalWorkMinutes
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
    [Date], IsWeekend, WorkStartDttm, WorkEndDttm, WorkMinutesPerDay, TotalWorkMinutes
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
-- 1) Drop and recreate target table
--------------------------------------------------------------------------------
IF OBJECT_ID('mis.[Silver_CerereOnline_WithWebDates]', 'U') IS NOT NULL
    DROP TABLE mis.[Silver_CerereOnline_WithWebDates];

CREATE TABLE mis.[Silver_CerereOnline_WithWebDates]
(
      [ID]                        VARCHAR(36)    NULL
    , [CreditID]                  VARCHAR(36)    NULL
    , [AuthorID]                  VARCHAR(36)    NULL
    , [Data depunerii cererii]    DATETIME2(0)  NULL
    , [Data inaintare la CC]      DATETIME2(0)  NULL
    , [Data procesarii]           DATETIME2(0)  NULL
    , [Data Votarii]              DATETIME2(0)  NULL
    , [Tip Рассмотрения Заявки]   NVARCHAR(100) NULL
    , [Tip Рассмотрения Заявки RO] NVARCHAR(50)  NULL
    , [Autor Votare]              NVARCHAR(100) NULL
    , [AutorVotare ID]            VARCHAR(36)   NULL
    , [Autor decizie]             NVARCHAR(100) NULL
    , [AutorDecizie ID]           VARCHAR(36)   NULL
    , [Кредиты Сегмент Доходов]   NVARCHAR(100) NULL
    , [Viteza de decizie]          DECIMAL(18,2) NULL
    , [Viteza de votare]           DECIMAL(18,2) NULL
    , [Viteza de procesare]        DECIMAL(18,2) NULL
    , [Analyse]                    DECIMAL(18,2) NULL
    , [Viteza de votare CC]        DECIMAL(18,2) NULL
    , [CC]                         DECIMAL(18,2) NULL
    , [Disbusement speed]           DECIMAL(18,2) NULL
    , [Total speed]                 DECIMAL(18,2) NULL
    , [Timpul de asteptare]         DECIMAL(18,2) NULL
    , [Viteza de decizie CC]        DECIMAL(18,2) NULL
    , [Viteza debursare(dupa procesare)] DECIMAL(18,2) NULL
    , [Viteza debursare(dupa Decizie)]   DECIMAL(18,2) NULL
    , [Depasire norma viteza]      BIT           NULL
    , [LoadDttm_Ext]               DATETIME      NOT NULL DEFAULT GETDATE()
);
GO

--------------------------------------------------------------------------------
-- 2) CTEs for source data
--------------------------------------------------------------------------------
;WITH d_src AS
(
    SELECT
          d.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID] AS CerereOnlineID
        , CAST(d.[ОбъединеннаяИнтернетЗаявка Дата] AS datetime2(0)) AS [Data depunerii cererii]
        , CAST(d.[ОбъединеннаяИнтернетЗаявка Дата Отправки на Рассмотрение] AS datetime2(0)) AS [Data inaintare la CC]
        , CAST(d.[ОбъединеннаяИнтернетЗаявка Дата Взятия в Работу] AS datetime2(0)) AS [Data procesarii]
        , d.[ОбъединеннаяИнтернетЗаявка Тип Рассмотрения Заявки] AS [Tip Рассмотрения Заявки]
        , ROW_NUMBER() OVER
          (
              PARTITION BY d.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
              ORDER BY
                    CAST(d.[ОбъединеннаяИнтернетЗаявка Дата] AS datetime2(0)) DESC
                  , d.[ОбъединеннаяИнтернетЗаявка ID] DESC
          ) AS rn
    FROM [ATK].[dbo].[Документы.ОбъединеннаяИнтернетЗаявка] d
    WHERE ISNULL(d.[ОбъединеннаяИнтернетЗаявка Проведен], 0) = 0
      AND ISNULL(d.[ОбъединеннаяИнтернетЗаявка Пометка Удаления], 0) = 0
      AND d.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID] IS NOT NULL
),
d_last AS
(
    SELECT
          CerereOnlineID
        , [Data depunerii cererii]
        , [Data inaintare la CC]
        , [Data procesarii]
        , [Tip Рассмотрения Заявки]
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
              ORDER BY
                    CAST(p.[ПротоколКомитета Дата] AS datetime2(0)) DESC
                  , p.[ПротоколКомитета ID] DESC
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
        , [Autor Votare] =
            m.[ПротоколКомитета.ЧленыКомитета Член Комитета]
        , [AutorVotare ID] =
            m.[ПротоколКомитета.ЧленыКомитета Член Комитета ID]
        , rn = ROW_NUMBER() OVER
            (
                PARTITION BY pl.CerereOnlineID
                ORDER BY
                      CASE
                          WHEN NULLIF(
                                   CAST(m.[ПротоколКомитета.ЧленыКомитета Дата Голоса] AS datetime2(0)),
                                   CAST('1753-01-01T00:00:00' AS datetime2(0))
                               ) IS NULL
                          THEN 1 ELSE 0
                      END
                    , NULLIF(
                          CAST(m.[ПротоколКомитета.ЧленыКомитета Дата Голоса] AS datetime2(0)),
                          CAST('1753-01-01T00:00:00' AS datetime2(0))
                      ) ASC
                    , m.[ПротоколКомитета.ЧленыКомитета Член Комитета ID] ASC
            )
    FROM proto_last pl
    LEFT JOIN [ATK].[dbo].[Документы.ПротоколКомитета.ЧленыКомитета] m
      ON m.[ПротоколКомитета ID] = pl.ProtocolID
),
votes_min AS
(
    SELECT
          CerereOnlineID
        , VoteDate         AS [Data Votarii]
        , [Autor Votare]   AS [Autor Votare]
        , [AutorVotare ID] AS [AutorVotare ID]
    FROM votes_ranked
    WHERE rn = 1
),
credits_dim AS
(
    SELECT
          c.[Кредиты ID] AS [Кредиты ID]
        , MAX(c.[Кредиты Сегмент Доходов]) AS [Кредиты Сегмент Доходов]
    FROM [ATK].[mis].[Bronze_Справочники.Кредиты] c
    GROUP BY c.[Кредиты ID]
),
users_dim AS
(
    SELECT
          u.[Пользователи ID] AS [AuthorID]
        , MAX(u.[Пользователи Сотрудник ID]) AS [AutorDecizie ID]
        , MAX(u.[Пользователи Сотрудник])    AS [Autor decizie]
    FROM [ATK].[dbo].[Справочники.Пользователи] u
    GROUP BY u.[Пользователи ID]
)
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

SELECT
      f.*
    , d.[Data depunerii cererii]
    , v.[Data Votarii]
    , v.[Autor Votare]
    , v.[AutorVotare ID]
    , u.[Autor decizie]
    , u.[AutorDecizie ID]
    , d.[Data inaintare la CC]
    , d.[Data procesarii]
    , d.[Tip Рассмотрения Заявки]

    , CASE
          WHEN v.[AutorVotare ID] = '813100155D65040111ED171A45F42146' THEN N'Fara sunet'
          WHEN d.[Tip Рассмотрения Заявки] = N'БезЗвонка'               THEN N'Fara sunet'
          WHEN d.[Tip Рассмотрения Заявки] = N'Стандартный'             THEN N'Standart'
          ELSE NULL
      END AS [Tip Рассмотрения Заявки RO]

    , cr.[Кредиты Сегмент Доходов]

    , dec_calc.WorkMinutesSigned AS [Viteza de decizie]
    , vot_calc.WorkMinutesSigned AS [Viteza de votare]
    , prc_calc.WorkMinutesSigned AS [Viteza de procesare]

    , CASE
          WHEN vot_calc.WorkMinutesSigned IS NULL THEN NULL
          WHEN (
                 cr.[Кредиты Сегмент Доходов] LIKE N'Ipoteca%'
              OR cr.[Кредиты Сегмент Доходов] LIKE N'HIL%'
              OR cr.[Кредиты Сегмент Доходов] =    N'Consum non-business'
               )
               AND vot_calc.WorkMinutesSigned > 420 THEN 1
          WHEN vot_calc.WorkMinutesSigned > 120 THEN 1
          ELSE 0
      END AS [Depasire norma viteza]

    , GETDATE() AS LoadDttm_Ext
INTO mis.[Silver_CerereOnline_WithWebDates]
FROM [ATK].[mis].[Silver_CerereOnline] f
LEFT JOIN d_last      d  ON d.CerereOnlineID = f.[ID]
LEFT JOIN votes_min   v  ON v.CerereOnlineID = f.[ID]
LEFT JOIN credits_dim cr ON cr.[Кредиты ID]   = f.[CreditID]
LEFT JOIN users_dim   u  ON u.[AuthorID]      = f.[AuthorID]


--------------------------------------------------------------------------------
-- 1A) Viteza de decizie = CommitteeDecisionDate - Data depunerii cererii
--------------------------------------------------------------------------------
OUTER APPLY (SELECT A = d.[Data depunerii cererii],
                    B = CAST(f.[CommitteeDecisionDate] AS datetime2(0))) dec_in
OUTER APPLY
(
    SELECT
          Sign = CASE WHEN dec_in.A IS NULL OR dec_in.B IS NULL THEN NULL
                      WHEN dec_in.B >= dec_in.A THEN 1 ELSE -1 END
        , S    = CASE WHEN dec_in.A IS NULL OR dec_in.B IS NULL THEN NULL
                      WHEN dec_in.B >= dec_in.A THEN dec_in.A ELSE dec_in.B END
        , E    = CASE WHEN dec_in.A IS NULL OR dec_in.B IS NULL THEN NULL
                      WHEN dec_in.B >= dec_in.A THEN dec_in.B ELSE dec_in.A END
) dec_pair
OUTER APPLY (SELECT SD = CAST(dec_pair.S AS date), ED = CAST(dec_pair.E AS date)) dec_dates
LEFT JOIN #Dim_WorkCalendar_All_08_20 cal_sd_dec ON cal_sd_dec.[Date] = dec_dates.SD
LEFT JOIN #Dim_WorkCalendar_All_08_20 cal_ed_dec ON cal_ed_dec.[Date] = dec_dates.ED
LEFT JOIN #Dim_WorkCalendar_All_08_20 cal_mid_end_dec
  ON cal_mid_end_dec.[Date] = DATEADD(day,-1, dec_dates.ED)
LEFT JOIN #Dim_WorkCalendar_All_08_20 cal_mid_start_dec
  ON cal_mid_start_dec.[Date] = dec_dates.SD
OUTER APPLY
(
    SELECT WorkMinutes =
    CASE
        WHEN dec_pair.S IS NULL OR dec_pair.E IS NULL OR dec_pair.E <= dec_pair.S THEN NULL

        WHEN dec_dates.SD = dec_dates.ED THEN
            CASE
                WHEN
                    (CASE WHEN cal_sd_dec.WorkStartDttm > dec_pair.S THEN cal_sd_dec.WorkStartDttm ELSE dec_pair.S END)
                    <
                    (CASE WHEN cal_sd_dec.WorkEndDttm   < dec_pair.E THEN cal_sd_dec.WorkEndDttm   ELSE dec_pair.E END)
                THEN DATEDIFF_BIG(
                        second,
                        CASE WHEN cal_sd_dec.WorkStartDttm > dec_pair.S THEN cal_sd_dec.WorkStartDttm ELSE dec_pair.S END,
                        CASE WHEN cal_sd_dec.WorkEndDttm   < dec_pair.E THEN cal_sd_dec.WorkEndDttm   ELSE dec_pair.E END
                     ) / 60.0
                ELSE 0.0
            END

        ELSE
            (
                CASE
                    WHEN (CASE WHEN cal_sd_dec.WorkStartDttm > dec_pair.S THEN cal_sd_dec.WorkStartDttm ELSE dec_pair.S END)
                         < cal_sd_dec.WorkEndDttm
                    THEN DATEDIFF_BIG(
                            second,
                            CASE WHEN cal_sd_dec.WorkStartDttm > dec_pair.S THEN cal_sd_dec.WorkStartDttm ELSE dec_pair.S END,
                            cal_sd_dec.WorkEndDttm
                         ) / 60.0
                    ELSE 0.0
                END
            )
            +
            (
                CASE
                    WHEN DATEADD(day,1, dec_dates.SD) <= DATEADD(day,-1, dec_dates.ED)
                    THEN CAST(
                            COALESCE(cal_mid_end_dec.TotalWorkMinutes, 0)
                          - COALESCE(cal_mid_start_dec.TotalWorkMinutes, 0)
                         AS float)
                    ELSE 0.0
                END
            )
            +
            (
                CASE
                    WHEN cal_ed_dec.WorkStartDttm
                         <
                         (CASE WHEN cal_ed_dec.WorkEndDttm < dec_pair.E THEN cal_ed_dec.WorkEndDttm ELSE dec_pair.E END)
                    THEN DATEDIFF_BIG(
                            second,
                            cal_ed_dec.WorkStartDttm,
                            CASE WHEN cal_ed_dec.WorkEndDttm < dec_pair.E THEN cal_ed_dec.WorkEndDttm ELSE dec_pair.E END
                         ) / 60.0
                    ELSE 0.0
                END
            )
    END
) dec_wm
OUTER APPLY
(
    SELECT WorkMinutesSigned =
        CASE
            WHEN dec_pair.Sign IS NULL OR dec_wm.WorkMinutes IS NULL THEN NULL
            ELSE CAST(ROUND(dec_wm.WorkMinutes, 2) AS decimal(18,2)) * CAST(dec_pair.Sign AS decimal(18,2))
        END
) dec_calc

--------------------------------------------------------------------------------
-- 1B) Viteza de votare = Data Votarii - Data depunerii cererii
--------------------------------------------------------------------------------
OUTER APPLY (SELECT A = d.[Data depunerii cererii],
                    B = v.[Data Votarii]) vot_in
OUTER APPLY
(
    SELECT
          Sign = CASE WHEN vot_in.A IS NULL OR vot_in.B IS NULL THEN NULL
                      WHEN vot_in.B >= vot_in.A THEN 1 ELSE -1 END
        , S    = CASE WHEN vot_in.A IS NULL OR vot_in.B IS NULL THEN NULL
                      WHEN vot_in.B >= vot_in.A THEN vot_in.A ELSE vot_in.B END
        , E    = CASE WHEN vot_in.A IS NULL OR vot_in.B IS NULL THEN NULL
                      WHEN vot_in.B >= vot_in.A THEN vot_in.B ELSE vot_in.A END
) vot_pair
OUTER APPLY (SELECT SD = CAST(vot_pair.S AS date), ED = CAST(vot_pair.E AS date)) vot_dates
LEFT JOIN #Dim_WorkCalendar_All_08_20 cal_sd_vot ON cal_sd_vot.[Date] = vot_dates.SD
LEFT JOIN #Dim_WorkCalendar_All_08_20 cal_ed_vot ON cal_ed_vot.[Date] = vot_dates.ED
LEFT JOIN #Dim_WorkCalendar_All_08_20 cal_mid_end_vot
  ON cal_mid_end_vot.[Date] = DATEADD(day,-1, vot_dates.ED)
LEFT JOIN #Dim_WorkCalendar_All_08_20 cal_mid_start_vot
  ON cal_mid_start_vot.[Date] = vot_dates.SD
OUTER APPLY
(
    SELECT WorkMinutes =
    CASE
        WHEN vot_pair.S IS NULL OR vot_pair.E IS NULL OR vot_pair.E <= vot_pair.S THEN NULL

        WHEN vot_dates.SD = vot_dates.ED THEN
            CASE
                WHEN
                    (CASE WHEN cal_sd_vot.WorkStartDttm > vot_pair.S THEN cal_sd_vot.WorkStartDttm ELSE vot_pair.S END)
                    <
                    (CASE WHEN cal_sd_vot.WorkEndDttm   < vot_pair.E THEN cal_sd_vot.WorkEndDttm   ELSE vot_pair.E END)
                THEN DATEDIFF_BIG(
                        second,
                        CASE WHEN cal_sd_vot.WorkStartDttm > vot_pair.S THEN cal_sd_vot.WorkStartDttm ELSE vot_pair.S END,
                        CASE WHEN cal_sd_vot.WorkEndDttm   < vot_pair.E THEN cal_sd_vot.WorkEndDttm   ELSE vot_pair.E END
                     ) / 60.0
                ELSE 0.0
            END

        ELSE
            (
                CASE
                    WHEN (CASE WHEN cal_sd_vot.WorkStartDttm > vot_pair.S THEN cal_sd_vot.WorkStartDttm ELSE vot_pair.S END)
                         < cal_sd_vot.WorkEndDttm
                    THEN DATEDIFF_BIG(
                            second,
                            CASE WHEN cal_sd_vot.WorkStartDttm > vot_pair.S THEN cal_sd_vot.WorkStartDttm ELSE vot_pair.S END,
                            cal_sd_vot.WorkEndDttm
                         ) / 60.0
                    ELSE 0.0
                END
            )
            +
            (
                CASE
                    WHEN DATEADD(day,1, vot_dates.SD) <= DATEADD(day,-1, vot_dates.ED)
                    THEN CAST(
                            COALESCE(cal_mid_end_vot.TotalWorkMinutes, 0)
                          - COALESCE(cal_mid_start_vot.TotalWorkMinutes, 0)
                         AS float)
                    ELSE 0.0
                END
            )
            +
            (
                CASE
                    WHEN cal_ed_vot.WorkStartDttm
                         <
                         (CASE WHEN cal_ed_vot.WorkEndDttm < vot_pair.E THEN cal_ed_vot.WorkEndDttm ELSE vot_pair.E END)
                    THEN DATEDIFF_BIG(
                            second,
                            cal_ed_vot.WorkStartDttm,
                            CASE WHEN cal_ed_vot.WorkEndDttm < vot_pair.E THEN cal_ed_vot.WorkEndDttm ELSE vot_pair.E END
                         ) / 60.0
                    ELSE 0.0
                END
            )
    END
) vot_wm
OUTER APPLY
(
    SELECT WorkMinutesSigned =
        CASE
            WHEN vot_pair.Sign IS NULL OR vot_wm.WorkMinutes IS NULL THEN NULL
            ELSE CAST(ROUND(vot_wm.WorkMinutes, 2) AS decimal(18,2)) * CAST(vot_pair.Sign AS decimal(18,2))
        END
) vot_calc

--------------------------------------------------------------------------------
-- 1C) Viteza de procesare = Data Votarii - Data procesarii
--------------------------------------------------------------------------------
OUTER APPLY (SELECT A = d.[Data procesarii],
                    B = v.[Data Votarii]) prc_in
OUTER APPLY
(
    SELECT
          Sign = CASE WHEN prc_in.A IS NULL OR prc_in.B IS NULL THEN NULL
                      WHEN prc_in.B >= prc_in.A THEN 1 ELSE -1 END
        , S    = CASE WHEN prc_in.A IS NULL OR prc_in.B IS NULL THEN NULL
                      WHEN prc_in.B >= prc_in.A THEN prc_in.A ELSE prc_in.B END
        , E    = CASE WHEN prc_in.A IS NULL OR prc_in.B IS NULL THEN NULL
                      WHEN prc_in.B >= prc_in.A THEN prc_in.B ELSE prc_in.A END
) prc_pair
OUTER APPLY (SELECT SD = CAST(prc_pair.S AS date), ED = CAST(prc_pair.E AS date)) prc_dates
LEFT JOIN #Dim_WorkCalendar_All_08_20 cal_sd_prc ON cal_sd_prc.[Date] = prc_dates.SD
LEFT JOIN #Dim_WorkCalendar_All_08_20 cal_ed_prc ON cal_ed_prc.[Date] = prc_dates.ED
LEFT JOIN #Dim_WorkCalendar_All_08_20 cal_mid_end_prc
  ON cal_mid_end_prc.[Date] = DATEADD(day,-1, prc_dates.ED)
LEFT JOIN #Dim_WorkCalendar_All_08_20 cal_mid_start_prc
  ON cal_mid_start_prc.[Date] = prc_dates.SD
OUTER APPLY
(
    SELECT WorkMinutes =
    CASE
        WHEN prc_pair.S IS NULL OR prc_pair.E IS NULL OR prc_pair.E <= prc_pair.S THEN NULL

        WHEN prc_dates.SD = prc_dates.ED THEN
            CASE
                WHEN
                    (CASE WHEN cal_sd_prc.WorkStartDttm > prc_pair.S THEN cal_sd_prc.WorkStartDttm ELSE prc_pair.S END)
                    <
                    (CASE WHEN cal_sd_prc.WorkEndDttm   < prc_pair.E THEN cal_sd_prc.WorkEndDttm   ELSE prc_pair.E END)
                THEN DATEDIFF_BIG(
                        second,
                        CASE WHEN cal_sd_prc.WorkStartDttm > prc_pair.S THEN cal_sd_prc.WorkStartDttm ELSE prc_pair.S END,
                        CASE WHEN cal_sd_prc.WorkEndDttm   < prc_pair.E THEN cal_sd_prc.WorkEndDttm   ELSE prc_pair.E END
                     ) / 60.0
                ELSE 0.0
            END

        ELSE
            (
                CASE
                    WHEN (CASE WHEN cal_sd_prc.WorkStartDttm > prc_pair.S THEN cal_sd_prc.WorkStartDttm ELSE prc_pair.S END)
                         < cal_sd_prc.WorkEndDttm
                    THEN DATEDIFF_BIG(
                            second,
                            CASE WHEN cal_sd_prc.WorkStartDttm > prc_pair.S THEN cal_sd_prc.WorkStartDttm ELSE prc_pair.S END,
                            cal_sd_prc.WorkEndDttm
                         ) / 60.0
                    ELSE 0.0
                END
            )
            +
            (
                CASE
                    WHEN DATEADD(day,1, prc_dates.SD) <= DATEADD(day,-1, prc_dates.ED)
                    THEN CAST(
                            COALESCE(cal_mid_end_prc.TotalWorkMinutes, 0)
                          - COALESCE(cal_mid_start_prc.TotalWorkMinutes, 0)
                         AS float)
                    ELSE 0.0
                END
            )
            +
            (
                CASE
                    WHEN cal_ed_prc.WorkStartDttm
                         <
                         (CASE WHEN cal_ed_prc.WorkEndDttm < prc_pair.E THEN cal_ed_prc.WorkEndDttm ELSE prc_pair.E END)
                    THEN DATEDIFF_BIG(
                            second,
                            cal_ed_prc.WorkStartDttm,
                            CASE WHEN cal_ed_prc.WorkEndDttm < prc_pair.E THEN cal_ed_prc.WorkEndDttm ELSE prc_pair.E END
                         ) / 60.0
                    ELSE 0.0
                END
            )
    END
) prc_wm
OUTER APPLY
(
    SELECT WorkMinutesSigned =
        CASE
            WHEN prc_pair.Sign IS NULL OR prc_wm.WorkMinutes IS NULL THEN NULL
            ELSE CAST(ROUND(prc_wm.WorkMinutes, 2) AS decimal(18,2)) * CAST(prc_pair.Sign AS decimal(18,2))
        END
) prc_calc
;
