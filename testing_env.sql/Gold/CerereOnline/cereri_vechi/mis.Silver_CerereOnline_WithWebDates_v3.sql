USE [ATK];
SET NOCOUNT ON;
SET XACT_ABORT ON;

--------------------------------------------------------------------------------
-- 0) Рабочий календарь: Пн–Вс 08:00–20:00 (720 мин)
--------------------------------------------------------------------------------

-- Drop temp table if it exists
IF OBJECT_ID('tempdb..#Dim_WorkCalendar_08_20_19') IS NOT NULL
    DROP TABLE #Dim_WorkCalendar_08_20_19;

-- Create temp table with primary key
CREATE TABLE #Dim_WorkCalendar_08_20_19
(
      [Date]               DATE        NOT NULL
    , IsWeekend            BIT         NOT NULL
    , WorkStartDttm        DATETIME2(0) NOT NULL
    , WorkEndDttm          DATETIME2(0) NOT NULL
    , WorkMinutesPerDay    INT         NOT NULL
    , TotalWorkMinutes     BIGINT      NOT NULL
    
);

--------------------------------------------------------------------------------
-- Fill calendar
--------------------------------------------------------------------------------

DECLARE @CalStart DATE = '2023-01-01';
DECLARE @CalEnd   DATE = DATEADD(YEAR, 5, CONVERT(DATE, GETDATE()));  -- 5 years ahead

;WITH N AS
(
    SELECT TOP (DATEDIFF(DAY, @CalStart, @CalEnd) + 1)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
),
d AS
(
    SELECT DATEADD(DAY, n, @CalStart) AS [Date]
    FROM N
),
x AS
(
    SELECT 
          [Date]
        , WDay = (DATEDIFF(DAY, '19000101', [Date]) % 7) + 1  -- 1=Mon..7=Sun
    FROM d
),
y AS
(
    SELECT
          [Date]
        , IsWeekend = CASE WHEN WDay IN (6,7) THEN 1 ELSE 0 END
        , WorkStartDttm     = DATEADD(MINUTE, 8*60,  CAST([Date] AS datetime2(0)))  -- 08:00
        , WorkEndDttm       = DATEADD(MINUTE, 20*60, CAST([Date] AS datetime2(0)))  -- 20:00
        , WorkMinutesPerDay = 720
    FROM x
)
INSERT INTO #Dim_WorkCalendar_08_20_19
(
    [Date], IsWeekend, WorkStartDttm, WorkEndDttm, WorkMinutesPerDay, TotalWorkMinutes
)
SELECT
      [Date]
    , IsWeekend
    , WorkStartDttm
    , WorkEndDttm
    , WorkMinutesPerDay
    , SUM(CAST(WorkMinutesPerDay AS BIGINT)) OVER (ORDER BY [Date] ROWS UNBOUNDED PRECEDING) AS TotalWorkMinutes
FROM y;


--------------------------------------------------------------------------------
-- 1) Rebuild таблицы
--------------------------------------------------------------------------------
IF OBJECT_ID('mis.[Gold_Fact_CerereOnline]','U') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_CerereOnline];

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
INTO mis.[Gold_Fact_CerereOnline]
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
LEFT JOIN #Dim_WorkCalendar_08_20_19 cal_sd_dec ON cal_sd_dec.[Date] = dec_dates.SD
LEFT JOIN #Dim_WorkCalendar_08_20_19 cal_ed_dec ON cal_ed_dec.[Date] = dec_dates.ED
LEFT JOIN #Dim_WorkCalendar_08_20_19 cal_mid_end_dec
  ON cal_mid_end_dec.[Date] = DATEADD(day,-1, dec_dates.ED)
LEFT JOIN #Dim_WorkCalendar_08_20_19 cal_mid_start_dec
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
LEFT JOIN #Dim_WorkCalendar_08_20_19 cal_sd_vot ON cal_sd_vot.[Date] = vot_dates.SD
LEFT JOIN #Dim_WorkCalendar_08_20_19 cal_ed_vot ON cal_ed_vot.[Date] = vot_dates.ED
LEFT JOIN #Dim_WorkCalendar_08_20_19 cal_mid_end_vot
  ON cal_mid_end_vot.[Date] = DATEADD(day,-1, vot_dates.ED)
LEFT JOIN #Dim_WorkCalendar_08_20_19 cal_mid_start_vot
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
LEFT JOIN #Dim_WorkCalendar_08_20_19 cal_sd_prc ON cal_sd_prc.[Date] = prc_dates.SD
LEFT JOIN #Dim_WorkCalendar_08_20_19 cal_ed_prc ON cal_ed_prc.[Date] = prc_dates.ED
LEFT JOIN #Dim_WorkCalendar_08_20_19 cal_mid_end_prc
  ON cal_mid_end_prc.[Date] = DATEADD(day,-1, prc_dates.ED)
LEFT JOIN #Dim_WorkCalendar_08_20_19 cal_mid_start_prc
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
