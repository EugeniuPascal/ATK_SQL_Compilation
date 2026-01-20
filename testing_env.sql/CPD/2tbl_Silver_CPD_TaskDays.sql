USE [ATK];
SET NOCOUNT ON;
SET XACT_ABORT ON;

------------------------------------------------------------
-- Full rebuild. Фильтр по клиенту:
-- NULL = все клиенты
------------------------------------------------------------
DECLARE @OpenDttm datetime2(0) = '1753-01-01T00:00:00';
DECLARE @ClientIDFilter varchar(36) = NULL;  -- или '80CD00155D01451511E8DC61B3AE0565'

------------------------------------------------------------
-- 0) Границы Sold (для развёртки диапазона)
-- ✅ NEW SOURCE:
-- [ATK].[mis].[Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки]
-- Поле даты = [СуммыЗадолженностиПоПериодамПросрочки Дата]
------------------------------------------------------------
DECLARE @MinSoldDate date =
(
    SELECT MIN(f.[СуммыЗадолженностиПоПериодамПросрочки Дата])
    FROM [ATK].[mis].[Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] f
);

DECLARE @AsOfDate date =
(
    SELECT MAX(f.[СуммыЗадолженностиПоПериодамПросрочки Дата])
    FROM [ATK].[mis].[Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] f
);

IF @AsOfDate IS NULL OR @MinSoldDate IS NULL
    THROW 50002,
          'Sold range is NULL: [ATK].[mis].[Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] is empty.',
          1;

DECLARE @MaxN int = DATEDIFF(day, @MinSoldDate, @AsOfDate) + 1;
IF @MaxN < 1 SET @MaxN = 1;

------------------------------------------------------------
-- 1) Создаём таблицы (если нет)
------------------------------------------------------------
IF OBJECT_ID('mis.2tbl_Silver_CPD_TaskHeader','U') IS NULL
BEGIN
    CREATE TABLE [mis].[2tbl_Silver_CPD_TaskHeader]
    (
        CondID       varchar(36)   NOT NULL,
        ClientID     varchar(36)   NOT NULL,
        TaskCreditID varchar(36)   NULL,

        DateFrom     date          NOT NULL,

        -- ✅ DoneDttm/DoneDate считаем от "Дата закрытия"
        DoneDttm     datetime2(0)  NOT NULL,
        DoneDate     date          NULL,

        DateFromAdj  date          NOT NULL,
        DateToAdj    date          NOT NULL,

        LoadDttm     datetime      NOT NULL,

        CONSTRAINT PK_2tbl_Silver_CPD_TaskHeader PRIMARY KEY CLUSTERED (CondID)
    );

    CREATE INDEX IX_TaskHeader_Client_Dates
        ON [mis].[2tbl_Silver_CPD_TaskHeader] (ClientID, DateFromAdj, DateToAdj)
        INCLUDE (TaskCreditID, DateFrom, DoneDate);
END;

IF OBJECT_ID('mis.2tbl_Silver_CPD_TaskDays','U') IS NULL
BEGIN
    CREATE TABLE [mis].[2tbl_Silver_CPD_TaskDays]
    (
        CondID       varchar(36) NOT NULL,
        CPDDate      date        NOT NULL,
        ClientID     varchar(36) NOT NULL,
        TaskCreditID varchar(36) NULL,
        LoadDttm     datetime    NOT NULL
    );

    CREATE CLUSTERED INDEX CX_TaskDays_Client_Date
        ON [mis].[2tbl_Silver_CPD_TaskDays] (ClientID, CPDDate, CondID);

    CREATE INDEX IX_TaskDays_Cond_Date
        ON [mis].[2tbl_Silver_CPD_TaskDays] (CondID, CPDDate)
        INCLUDE (ClientID, TaskCreditID);
END;

------------------------------------------------------------
-- 2) Full rebuild Header
------------------------------------------------------------
TRUNCATE TABLE [mis].[2tbl_Silver_CPD_TaskHeader];

INSERT INTO [mis].[2tbl_Silver_CPD_TaskHeader]
(
    CondID, ClientID, TaskCreditID,
    DateFrom, DoneDttm, DoneDate,
    DateFromAdj, DateToAdj,
    LoadDttm
)
SELECT
      c.[ИД]                                           AS CondID
    , LTRIM(RTRIM(c.[Client ID]))                      AS ClientID
    , NULLIF(LTRIM(RTRIM(c.[CreditID_Found])), '')     AS TaskCreditID
    , CAST(c.[Период] AS date)                         AS DateFrom

    -- ✅ NEW: Done = "Дата закрытия" (если NULL -> считаем как OpenDttm)
    , CAST(COALESCE(c.[Дата закрытия], @OpenDttm) AS datetime2(0)) AS DoneDttm
    , CASE
          WHEN COALESCE(c.[Дата закрытия], @OpenDttm) <> @OpenDttm
          THEN CAST(CAST(c.[Дата закрытия] AS datetime2(0)) AS date)
          ELSE NULL
      END                                              AS DoneDate

    , CASE
          WHEN CAST(c.[Период] AS date) < @MinSoldDate THEN @MinSoldDate
          ELSE CAST(c.[Период] AS date)
      END                                              AS DateFromAdj

    -- ✅ NEW: DateToAdj считаем от DoneDttm (= дата закрытия), иначе AsOfDate
    , CASE
          WHEN CAST(COALESCE(c.[Дата закрытия], @OpenDttm) AS datetime2(0)) <> @OpenDttm
          THEN
              CASE
                  WHEN CAST(CAST(c.[Дата закрытия] AS datetime2(0)) AS date) > @AsOfDate THEN @AsOfDate
                  ELSE CAST(CAST(c.[Дата закрытия] AS datetime2(0)) AS date)
              END
          ELSE @AsOfDate
      END                                              AS DateToAdj

    , GETDATE()
FROM [ATK].[mis].[2tbl_Silver_ConditionsAfterDisb_Last] c
WHERE c.[ИД] IS NOT NULL
  AND c.[Client ID] IS NOT NULL
  AND c.[Период] IS NOT NULL
  AND (@ClientIDFilter IS NULL OR LTRIM(RTRIM(c.[Client ID])) = @ClientIDFilter);

-- защита: DateToAdj >= DateFromAdj
UPDATE h
SET h.DateToAdj = CASE WHEN h.DateToAdj < h.DateFromAdj THEN h.DateFromAdj ELSE h.DateToAdj END
FROM [mis].[2tbl_Silver_CPD_TaskHeader] h;

------------------------------------------------------------
-- 3) Full rebuild Days (развёртка по дням)
------------------------------------------------------------
TRUNCATE TABLE [mis].[2tbl_Silver_CPD_TaskDays];

;WITH N AS
(
    SELECT TOP (@MaxN)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
)
INSERT INTO [mis].[2tbl_Silver_CPD_TaskDays]
(
    CondID, CPDDate, ClientID, TaskCreditID, LoadDttm
)
SELECT
      h.CondID
    , DATEADD(day, n.n, h.DateFromAdj)                   AS CPDDate
    , h.ClientID
    , NULLIF(LTRIM(RTRIM(h.TaskCreditID)),'')            AS TaskCreditID
    , GETDATE()
FROM [mis].[2tbl_Silver_CPD_TaskHeader] h
JOIN N
  ON DATEADD(day, n.n, h.DateFromAdj) <= h.DateToAdj;

------------------------------------------------------------
-- 4) Контроль
------------------------------------------------------------
SELECT ISNULL(@ClientIDFilter,'(ALL)') AS ClientIDFilter, COUNT(*) AS CntTasks
FROM [mis].[2tbl_Silver_CPD_TaskHeader];

SELECT ISNULL(@ClientIDFilter,'(ALL)') AS ClientIDFilter, COUNT(*) AS CntTaskDays
FROM [mis].[2tbl_Silver_CPD_TaskDays];
