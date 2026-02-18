USE [ATK];
GO
SET NOCOUNT ON;

IF OBJECT_ID('mis.[Gold_Fact_CerereOnline]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_CerereOnline];
GO

CREATE TABLE mis.[Gold_Fact_CerereOnline] 
(
    [ID]                    VARCHAR(36)    NULL,
    [Date]                  DATETIME       NULL,
    [Status]                NVARCHAR(256)  NULL,
    [Posted]                VARCHAR(36)    NULL,
    [BusinessSector]        NVARCHAR(150)  NULL,
    [Type]                  NVARCHAR(100)  NULL,
    [HistoryType]           NVARCHAR(256)  NULL,
    [CreditID]              VARCHAR(36)    NULL,
    [AuthorID]              VARCHAR(36)    NULL,
    [Author]                NVARCHAR(100)  NULL,
    [Purpose]               NVARCHAR(150)  NULL,
    [IsGreen]               NVARCHAR(36)   NULL,
    [ClientID]              VARCHAR(36)    NULL,
    [CreditAmount]          DECIMAL(15,2)  NULL,
    [CurrencyType]          NVARCHAR(36)   NULL,
    [CreditAmountInMDL]     DECIMAL(18,2)  NULL,
    [NewExisting_Client]    NVARCHAR(20)   NULL,
    [RefusalReason]         NVARCHAR(200)  NULL,
    [CreditProduct]         NVARCHAR(150)  NULL,
    [ProductID]             VARCHAR(36)    NULL,
    [CreditProductID]       VARCHAR(36)    NULL,
    [InternetID]            VARCHAR(36)    NULL,
    [EmployeeID]            VARCHAR(36)    NULL,
    [BranchID]              VARCHAR(36)    NULL,
    [PartnerID]             VARCHAR(36)    NULL,
    [Partner]               NVARCHAR(150)  NULL,
    [WebDate]               DATETIME       NULL,
    [WebNr]                 NVARCHAR(50)   NULL,
    [WebPosted]             VARCHAR(36)    NULL,
    [WebIncomeTypeOnline]   NVARCHAR(200)  NULL,
    [WebAge]                INT            NULL,
    [WebSubmissionDate]     DATETIME       NULL,
    [WebCredit]             NVARCHAR(100)  NULL,
    [WebIdentifier]         NVARCHAR(50)   NULL,
    [WebCreditEmployee]     NVARCHAR(50)   NULL,
    [WebMobilePhone]        NVARCHAR(20)   NULL,
    [WebSentForReview]      NVARCHAR(36)   NULL,
    [WebGender]             NVARCHAR(256)  NULL,
    [WebStatus]             NVARCHAR(256)  NULL,
    [WebCreditTerm]         INT            NULL,
    [WebBranchID]           VARCHAR(36)    NULL,
	[ContactPerson]         NVARCHAR(100)  NULL,
	[ContactPersonPhone]     NVARCHAR(50)   NULL,
    [CommitteeDecisionDate] DATETIME       NULL,
	[CommitteeDecision]     NVARCHAR(256)  NULL,
	
     



--------------------------------------------------------------------------------
-- 0) Setup & variables
--------------------------------------------------------------------------------
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @TargetPosID varchar(36);
DECLARE @FromDate    datetime;

SET @TargetPosID = '812b00155d65040111ed03ac01bd0d94';
SET @FromDate    = '2015-01-01T00:00:00';

--------------------------------------------------------------------------------
-- 0A) Calendars (temp) - NO named constraints (avoid PK name collisions)
--------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#Dim_WorkCalendar_All_08_20') IS NOT NULL DROP TABLE #Dim_WorkCalendar_All_08_20;
IF OBJECT_ID('tempdb..#Dim_WorkCalendar_MonFri_08_18') IS NOT NULL DROP TABLE #Dim_WorkCalendar_MonFri_08_18;

CREATE TABLE #Dim_WorkCalendar_All_08_20
(
      [Date]            date        NOT NULL PRIMARY KEY CLUSTERED
    , IsWeekend         bit         NOT NULL
    , WorkStartDttm     datetime2(0) NOT NULL
    , WorkEndDttm       datetime2(0) NOT NULL
    , WorkMinutesPerDay int         NOT NULL
    , CumWorkMinutes    bigint      NOT NULL
);

CREATE TABLE #Dim_WorkCalendar_MonFri_08_18
(
      [Date]            date        NOT NULL PRIMARY KEY CLUSTERED
    , IsWeekend         bit         NOT NULL
    , WorkStartDttm     datetime2(0) NOT NULL
    , WorkEndDttm       datetime2(0) NOT NULL
    , WorkMinutesPerDay int         NOT NULL
    , CumWorkMinutes    bigint      NOT NULL
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
d AS (SELECT [Date] = DATEADD(day, n, @CalStart) FROM N),
x AS (SELECT [Date], WDay = (DATEDIFF(day, CONVERT(date,'19000101'), [Date]) % 7) + 1 FROM d),
src AS (SELECT [Date], WDay, IsWeekend = CASE WHEN WDay IN (6,7) THEN 1 ELSE 0 END FROM x)
INSERT INTO #Dim_WorkCalendar_All_08_20
([Date], IsWeekend, WorkStartDttm, WorkEndDttm, WorkMinutesPerDay, CumWorkMinutes)
SELECT
      s.[Date]
    , s.IsWeekend
    , DATEADD(minute,  8*60, CAST(s.[Date] AS datetime2(0)))
    , DATEADD(minute, 20*60, CAST(s.[Date] AS datetime2(0)))
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
d AS (SELECT [Date] = DATEADD(day, n, @CalStart) FROM N),
x AS (SELECT [Date], WDay = (DATEDIFF(day, CONVERT(date,'19000101'), [Date]) % 7) + 1 FROM d),
src AS (SELECT [Date], WDay, IsWeekend = CASE WHEN WDay IN (6,7) THEN 1 ELSE 0 END FROM x)
INSERT INTO #Dim_WorkCalendar_MonFri_08_18
([Date], IsWeekend, WorkStartDttm, WorkEndDttm, WorkMinutesPerDay, CumWorkMinutes)
SELECT
      s.[Date]
    , s.IsWeekend
    , DATEADD(minute,  8*60, CAST(s.[Date] AS datetime2(0)))
    , DATEADD(minute, 18*60, CAST(s.[Date] AS datetime2(0)))
    , CASE WHEN s.WDay BETWEEN 1 AND 5 THEN 600 ELSE 0 END
    , SUM(CAST(CASE WHEN s.WDay BETWEEN 1 AND 5 THEN 600 ELSE 0 END AS bigint))
        OVER (ORDER BY s.[Date] ROWS UNBOUNDED PRECEDING)
FROM src s;

--------------------------------------------------------------------------------
-- 1) Rebuild GOLD table from base
--------------------------------------------------------------------------------
IF OBJECT_ID('mis.Gold_Fact_CerereOnline','U') IS NOT NULL
    DROP TABLE mis.Gold_Fact_CerereOnline;

SELECT f.*
INTO mis.Gold_Fact_CerereOnline
FROM [ATK].[mis].[Silver_CerereOnline_base] f
WHERE f.[Date] >= @FromDate;

--------------------------------------------------------------------------------
-- 1B) Indexes for faster joins/updates
--------------------------------------------------------------------------------
CREATE INDEX IX_CerereOnline_ID       ON mis.Gold_Fact_CerereOnline([ID]);
CREATE INDEX IX_CerereOnline_CreditID ON mis.Gold_Fact_CerereOnline([CreditID]);
CREATE INDEX IX_CerereOnline_AuthorID ON mis.Gold_Fact_CerereOnline([AuthorID]);
CREATE INDEX IX_CerereOnline_Date     ON mis.Gold_Fact_CerereOnline([Date]);

--------------------------------------------------------------------------------
-- 2) Ensure required columns (add only if missing)
--------------------------------------------------------------------------------
IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Data autorizarii') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Data autorizarii] datetime2(0) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Data depunerii cererii') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Data depunerii cererii] datetime2(0) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Data votarii') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Data votarii] datetime2(0) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Autor Votare') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Autor Votare] nvarchar(255) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'AutorVotare ID') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [AutorVotare ID] varchar(36) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Autor Votare Position') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Autor Votare Position] varchar(36) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Autor decizie') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Autor decizie] nvarchar(255) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'AutorDecizie ID') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [AutorDecizie ID] varchar(36) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Кредиты Сегмент Доходов') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Кредиты Сегмент Доходов] nvarchar(255) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Tip Рассмотрения Заявки RO') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Tip Рассмотрения Заявки RO] nvarchar(50) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Viteza de decizie') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Viteza de decizie] decimal(18,2) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Viteza de votare') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Viteza de votare] decimal(18,2) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Viteza de procesare') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Viteza de procesare] decimal(18,2) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Analyse') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Analyse] decimal(18,2) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Viteza de votare CC') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Viteza de votare CC] decimal(18,2) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'CC') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [CC] decimal(18,2) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Disbusement speed') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Disbusement speed] decimal(18,2) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Total speed') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Total speed] decimal(18,2) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Timpul de asteptare') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Timpul de asteptare] decimal(18,2) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Viteza de decizie CC') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Viteza de decizie CC] decimal(18,2) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Viteza debursare(dupa procesare)') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Viteza debursare(dupa procesare)] decimal(18,2) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Viteza debursare(dupa Decizie)') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Viteza debursare(dupa Decizie)] decimal(18,2) NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'Depasire norma viteza') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline ADD [Depasire norma viteza] bit NULL;

IF COL_LENGTH('mis.Gold_Fact_CerereOnline', 'LoadDttm_Ext') IS NULL
    ALTER TABLE mis.Gold_Fact_CerereOnline
        ADD [LoadDttm_Ext] datetime NOT NULL
            CONSTRAINT DF_Gold_Fact_CerereOnline_LoadDttm DEFAULT (GETDATE());

--------------------------------------------------------------------------------
-- 3) FAST ENRICH: restrict heavy work to only IDs from rebuilt table
--    VoteDate logic: FIRST vote, prefer TargetPos; fallback to chair (ProtocolDate)
--    Position logic: from ATK.mis.dev_Silver_EmployeesPosition_SCD (SCD by date)
--------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#t') IS NOT NULL DROP TABLE #t;

SELECT
      ID   = t.[ID]
    , CreditID              = MAX(t.[CreditID])
    , AuthorID              = MAX(t.[AuthorID])
    , BranchID              = MAX(t.[BranchID])
    , CommitteeDecisionDate = MAX(t.[CommitteeDecisionDate])
INTO #t
FROM mis.Gold_Fact_CerereOnline t
WHERE t.[ID] IS NOT NULL
GROUP BY t.[ID];

CREATE UNIQUE CLUSTERED INDEX CIX_t_ID ON #t([ID]);
CREATE INDEX IX_t_CreditID ON #t([CreditID]);
CREATE INDEX IX_t_AuthorID ON #t([AuthorID]);

-- d_last
IF OBJECT_ID('tempdb..#d_last') IS NOT NULL DROP TABLE #d_last;
;WITH d_src AS
(
    SELECT
          d.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID] AS CerereOnlineID
        , CAST(d.[ОбъединеннаяИнтернетЗаявка Дата] AS datetime2(0)) AS Dep
        , CAST(d.[ОбъединеннаяИнтернетЗаявка Дата Отправки на Рассмотрение] AS datetime2(0)) AS InCC
        , CAST(d.[ОбъединеннаяИнтернетЗаявка Дата Взятия в Работу] AS datetime2(0)) AS ProcDttm
        , d.[ОбъединеннаяИнтернетЗаявка Тип Рассмотрения Заявки] AS Tip
        , rn = ROW_NUMBER() OVER
          (
              PARTITION BY d.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
              ORDER BY CAST(d.[ОбъединеннаяИнтернетЗаявка Дата] AS datetime2(0)) DESC,
                       d.[ОбъединеннаяИнтернетЗаявка ID] DESC
          )
    FROM [ATK].[dbo].[Документы.ОбъединеннаяИнтернетЗаявка] d
    JOIN #t tt ON tt.[ID] = d.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
    WHERE ISNULL(d.[ОбъединеннаяИнтернетЗаявка Проведен], 0) = 0
      AND ISNULL(d.[ОбъединеннаяИнтернетЗаявка Пометка Удаления], 0) = 0
)
SELECT CerereOnlineID, Dep, InCC, ProcDttm, Tip
INTO #d_last
FROM d_src
WHERE rn = 1;

CREATE UNIQUE CLUSTERED INDEX CIX_dlast_ID ON #d_last(CerereOnlineID);

-- proto_last (ВАЖНО: учитываем Вид Комитета = ПредоставлениеКредита)
IF OBJECT_ID('tempdb..#proto_last') IS NOT NULL DROP TABLE #proto_last;
;WITH p_src AS
(
    SELECT
          p.[ПротоколКомитета Заявка ID] AS CerereOnlineID
        , p.[ПротоколКомитета ID]        AS ProtocolID
        , CAST(p.[ПротоколКомитета Дата] AS datetime2(0)) AS ProtocolDate
        , p.[ПротоколКомитета Председатель Комитета]       AS ChairName
        , p.[ПротоколКомитета Председатель Комитета ID]    AS ChairEmployeeID
        , rn = ROW_NUMBER() OVER
          (
              PARTITION BY p.[ПротоколКомитета Заявка ID]
              ORDER BY CAST(p.[ПротоколКомитета Дата] AS datetime2(0)) DESC,
                       p.[ПротоколКомитета ID] DESC
          )
    FROM [ATK].[dbo].[Документы.ПротоколКомитета] p
    JOIN #t tt ON tt.[ID] = p.[ПротоколКомитета Заявка ID]
    WHERE ISNULL(p.[ПротоколКомитета Пометка Удаления], 0) = 0
      AND ISNULL(p.[ПротоколКомитета Вид Комитета], N'') = N'ПредоставлениеКредита'
)
SELECT CerereOnlineID, ProtocolID, ProtocolDate, ChairName, ChairEmployeeID
INTO #proto_last
FROM p_src
WHERE rn = 1;

CREATE UNIQUE CLUSTERED INDEX CIX_proto_ID ON #proto_last(CerereOnlineID);
CREATE INDEX IX_proto_ProtocolID ON #proto_last(ProtocolID);

-- members for these protocols only
IF OBJECT_ID('tempdb..#members') IS NOT NULL DROP TABLE #members;
SELECT
      pl.CerereOnlineID
    , VoteDate =
        NULLIF(
            CAST(m.[ПротоколКомитета.ЧленыКомитета Дата Голоса] AS datetime2(0)),
            CAST('1753-01-01T00:00:00' AS datetime2(0))
        )
    , MemberName = m.[ПротоколКомитета.ЧленыКомитета Член Комитета]
    , MemberEmployeeID = m.[ПротоколКомитета.ЧленыКомитета Член Комитета ID]
INTO #members
FROM #proto_last pl
LEFT JOIN [ATK].[dbo].[Документы.ПротоколКомитета.ЧленыКомитета] m
  ON m.[ПротоколКомитета ID] = pl.ProtocolID;

CREATE INDEX IX_members_ID  ON #members(CerereOnlineID);
CREATE INDEX IX_members_emp ON #members(MemberEmployeeID);

-- positions for members (SCD by date) from dev_Silver_EmployeesPosition_SCD
IF OBJECT_ID('tempdb..#m_pos') IS NOT NULL DROP TABLE #m_pos;
SELECT
      m.CerereOnlineID
    , m.VoteDate
    , m.MemberEmployeeID
    , m.MemberName
    , PosID = ep.PositionID
INTO #m_pos
FROM #members m
LEFT JOIN #proto_last pl
  ON pl.CerereOnlineID = m.CerereOnlineID
OUTER APPLY
(
    SELECT TOP (1) s.PositionID
    FROM [ATK].[mis].[dev_Silver_EmployeesPosition_SCD] s
    WHERE s.EmployeeID = m.MemberEmployeeID
      AND COALESCE(m.VoteDate, pl.ProtocolDate) >= s.ValidFrom
      AND COALESCE(m.VoteDate, pl.ProtocolDate) <  ISNULL(s.ValidTo, '9999-12-31')
    ORDER BY s.ValidFrom DESC
) ep;

CREATE INDEX IX_mpos_ID ON #m_pos(CerereOnlineID);

-- pick FIRST vote: prefer TargetPos, else first among all; if none -> chair (ProtocolDate)
IF OBJECT_ID('tempdb..#vote_final') IS NOT NULL DROP TABLE #vote_final;

;WITH ranked AS
(
    SELECT
          CerereOnlineID
        , VoteDate
        , [Autor Votare]   = MemberName
        , [AutorVotare ID] = MemberEmployeeID
        , rn = ROW_NUMBER() OVER
          (
            PARTITION BY CerereOnlineID
            ORDER BY
                CASE WHEN VoteDate IS NULL THEN 1 ELSE 0 END,
                CASE WHEN PosID = @TargetPosID THEN 0 ELSE 1 END,
                VoteDate ASC,
                MemberEmployeeID ASC
          )
    FROM #m_pos
)
SELECT CerereOnlineID, VoteDate, [Autor Votare], [AutorVotare ID]
INTO #vote_final
FROM ranked
WHERE rn = 1;

INSERT INTO #vote_final(CerereOnlineID, VoteDate, [Autor Votare], [AutorVotare ID])
SELECT
      pl.CerereOnlineID
    , pl.ProtocolDate
    , pl.ChairName
    , pl.ChairEmployeeID
FROM #proto_last pl
WHERE NOT EXISTS (SELECT 1 FROM #vote_final v WHERE v.CerereOnlineID = pl.CerereOnlineID);

CREATE UNIQUE CLUSTERED INDEX CIX_vote_ID ON #vote_final(CerereOnlineID);

-- Autor Votare Position (PositionID) for chosen autor (SCD by VoteDate)
IF OBJECT_ID('tempdb..#vote_pos') IS NOT NULL DROP TABLE #vote_pos;
SELECT
      v.CerereOnlineID
    , PositionID = ep.PositionID
INTO #vote_pos
FROM #vote_final v
OUTER APPLY
(
    SELECT TOP (1) s.PositionID
    FROM [ATK].[mis].[dev_Silver_EmployeesPosition_SCD] s
    WHERE s.EmployeeID = v.[AutorVotare ID]
      AND v.VoteDate   >= s.ValidFrom
      AND v.VoteDate   <  ISNULL(s.ValidTo, '9999-12-31')
    ORDER BY s.ValidFrom DESC
) ep;

CREATE UNIQUE CLUSTERED INDEX CIX_vote_pos ON #vote_pos(CerereOnlineID);

-- credits_dim only for needed CreditID
IF OBJECT_ID('tempdb..#credits_dim') IS NOT NULL DROP TABLE #credits_dim;
SELECT c.[Кредиты ID] AS CreditID, MAX(c.[Кредиты Сегмент Доходов]) AS IncomeSeg
INTO #credits_dim
FROM [ATK].[mis].[Bronze_Справочники.Кредиты] c
JOIN (SELECT DISTINCT CreditID FROM #t) x ON x.CreditID = c.[Кредиты ID]
GROUP BY c.[Кредиты ID];
CREATE UNIQUE CLUSTERED INDEX CIX_cr ON #credits_dim(CreditID);

-- users_dim only for needed AuthorID
IF OBJECT_ID('tempdb..#users_dim') IS NOT NULL DROP TABLE #users_dim;
SELECT u.[Пользователи ID] AS AuthorID,
       MAX(u.[Пользователи Сотрудник ID]) AS AutorDecizieID,
       MAX(u.[Пользователи Сотрудник])    AS AutorDecizie
INTO #users_dim
FROM [ATK].[dbo].[Справочники.Пользователи] u
JOIN (SELECT DISTINCT AuthorID FROM #t) x ON x.AuthorID = u.[Пользователи ID]
GROUP BY u.[Пользователи ID];
CREATE UNIQUE CLUSTERED INDEX CIX_usr ON #users_dim(AuthorID);

-- pay_last only for needed CreditID
IF OBJECT_ID('tempdb..#pay_last') IS NOT NULL DROP TABLE #pay_last;
;WITH p AS
(
    SELECT
          p.[НаправлениеНаВыплату Кредит ID] AS CreditID
        , CAST(p.[НаправлениеНаВыплату Дата] AS datetime2(0)) AS DataAut
        , rn = ROW_NUMBER() OVER
          (
              PARTITION BY p.[НаправлениеНаВыплату Кредит ID]
              ORDER BY CAST(p.[НаправлениеНаВыплату Дата] AS datetime2(0)) DESC,
                       p.[НаправлениеНаВыплату ID] DESC
          )
    FROM [ATK].[dbo].[Документы.НаправлениеНаВыплату] p
    JOIN (SELECT DISTINCT CreditID FROM #t) x ON x.CreditID = p.[НаправлениеНаВыплату Кредит ID]
    WHERE ISNULL(p.[НаправлениеНаВыплату Пометка Удаления], 0) = 0
      AND ISNULL(p.[НаправлениеНаВыплату Проведен], 0) = 0
)
SELECT CreditID, DataAut
INTO #pay_last
FROM p
WHERE rn = 1;
CREATE UNIQUE CLUSTERED INDEX CIX_pay ON #pay_last(CreditID);

--------------------------------------------------------------------------------
-- FINAL UPDATE (minutes computed ONCE and reused)
--------------------------------------------------------------------------------
UPDATE t
SET
      t.[Autor Votare]             = v.[Autor Votare]
    , t.[AutorVotare ID]           = v.[AutorVotare ID]
    , t.[Autor Votare Position]    = vp.PositionID
    , t.[Data depunerii cererii]   = d.Dep
    , t.[Data votarii]             = v.VoteDate
    , t.[Autor decizie]            = u.[AutorDecizie]
    , t.[AutorDecizie ID]          = u.[AutorDecizieID]
    , t.[Кредиты Сегмент Доходов]  = cr.IncomeSeg
    , t.[Data autorizarii]         = pay.DataAut

    , t.[Tip Рассмотрения Заявки RO] =
        CASE
            WHEN v.[AutorVotare ID] = '813100155D65040111ED171A45F42146' THEN N'Fara sunet'
            WHEN d.Tip = N'БезЗвонка'   THEN N'Fara sunet'
            WHEN d.Tip = N'Стандартный' THEN N'Standart'
            ELSE NULL
        END

    -- OLD speeds (ALL DAYS 08-20)
    , t.[Viteza de decizie] =
        mis.fn_WorkMinutesSigned(d.Dep, t.[CommitteeDecisionDate], 8*60, 20*60)

    , t.[Viteza de votare] =
        mx.Minutes_DepVote_08_20

    , t.[Viteza de procesare] =
        mis.fn_WorkMinutesSigned(d.ProcDttm, v.VoteDate, 8*60, 20*60)

    -- NEW formulas: Mon-Fri only
    , t.[Analyse] =
        mis.fn_WorkMinutesSigned_MonFri(d.Dep, d.InCC, 8*60, 18*60)

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
            THEN mis.fn_WorkMinutesSigned_MonFri(d.InCC, v.VoteDate, 9*60, 18*60)
            ELSE mis.fn_WorkMinutesSigned_MonFri(d.InCC, v.VoteDate, 8*60, 17*60)
        END

    , t.[CC] =
        mis.fn_WorkMinutesSigned_MonFri(d.InCC, t.[CommitteeDecisionDate], 8*60, 18*60)

    , t.[Disbusement speed] =
        mis.fn_WorkMinutesSigned_MonFri(t.[CommitteeDecisionDate], pay.DataAut, 8*60, 18*60)

    , t.[Total speed] =
        mis.fn_WorkMinutesSigned_MonFri(d.Dep, pay.DataAut, 8*60, 18*60)

    , t.[Timpul de asteptare] =
        mis.fn_WorkMinutesSigned_MonFri(d.Dep, d.ProcDttm, 9*60, 18*60)

    , t.[Viteza de decizie CC] =
        mis.fn_WorkMinutesSigned_MonFri(d.Dep, t.[CommitteeDecisionDate], 8*60, 18*60)

    , t.[Viteza debursare(dupa procesare)] =
        mis.fn_WorkMinutesSigned_MonFri(d.ProcDttm, pay.DataAut, 8*60, 18*60)

    , t.[Viteza debursare(dupa Decizie)] =
        mis.fn_WorkMinutesSigned_MonFri(t.[CommitteeDecisionDate], pay.DataAut, 8*60, 18*60)

    -- Depasire norma viteza (ALL DAYS 08-20) - reuse minutes
    , t.[Depasire norma viteza] =
        CASE
            WHEN mx.Minutes_DepVote_08_20 IS NULL THEN NULL
            WHEN (
                     cr.IncomeSeg LIKE N'Ipoteca%'
                  OR cr.IncomeSeg LIKE N'HIL%'
                  OR cr.IncomeSeg =  N'Consum non-business'
                  OR cr.IncomeSeg =  N'Linia de credit retail'
                 )
                 AND mx.Minutes_DepVote_08_20 > 420 THEN 1
            WHEN (
                     cr.IncomeSeg NOT LIKE N'Ipoteca%'
                 AND cr.IncomeSeg NOT LIKE N'HIL%'
                 AND cr.IncomeSeg <> N'Consum non-business'
                 AND cr.IncomeSeg <> N'Linia de credit retail'
                 )
                 AND mx.Minutes_DepVote_08_20 > 120 THEN 1
            ELSE 0
        END

    , t.[LoadDttm_Ext] = GETDATE()
FROM mis.Gold_Fact_CerereOnline t
JOIN #t tt                  ON tt.[ID] = t.[ID]
LEFT JOIN #d_last d         ON d.CerereOnlineID = t.[ID]
LEFT JOIN #vote_final v     ON v.CerereOnlineID = t.[ID]
LEFT JOIN #vote_pos vp      ON vp.CerereOnlineID = t.[ID]
LEFT JOIN #credits_dim cr   ON cr.CreditID      = t.[CreditID]
LEFT JOIN #users_dim u      ON u.AuthorID       = t.[AuthorID]
LEFT JOIN #pay_last pay     ON pay.CreditID     = t.[CreditID]
OUTER APPLY
(
    SELECT Minutes_DepVote_08_20 =
        CASE WHEN d.Dep IS NULL OR v.VoteDate IS NULL
             THEN NULL
             ELSE mis.fn_WorkMinutesSigned(d.Dep, v.VoteDate, 8*60, 20*60)
        END
) mx;
