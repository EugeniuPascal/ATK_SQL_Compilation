USE [ATK];
SET NOCOUNT ON;

IF OBJECT_ID(N'mis.[Silver_Limits]', 'U') IS NOT NULL
    DROP TABLE mis.[Silver_Limits];


CREATE TABLE mis.[Silver_Limits] 
(
      [Limit ID]               VARCHAR(36)    NOT NULL,
      [Limit Code]             NVARCHAR(50)   NULL,
      [Limit Name]             NVARCHAR(255)  NULL,

      -- First "Set"
      [FirstSet Operation Type] NVARCHAR(50)  NULL,
      [FirstSet CreateDate]     DATETIME2(0)  NULL,
      [FirstSet DecisionDate]   DATETIME2(0)  NULL,
      [FirstFilial ID]          VARCHAR(36)   NULL,
      [FirstExpert ID]          VARCHAR(36)   NULL,
      [FirstClient ID]          VARCHAR(36)   NULL,
      [FirstSet Amount]         DECIMAL(18,2) NULL,

      -- Last operation
      [Last Operation Type]     NVARCHAR(50)  NULL,
      [Last CreateDate]         DATETIME2(0)  NULL,
      [Last DecisionDate]       DATETIME2(0)  NULL,
      [LastFilial ID]           VARCHAR(36)   NULL,
      [LastExpert ID]           VARCHAR(36)   NULL,
      [LastClient ID]           VARCHAR(36)   NULL,
      [Last Amount]             DECIMAL(18,2) NULL,
      [Last State]              NVARCHAR(50)  NULL
);

WITH lim AS (
    SELECT
          l.[Лимиты ID]           AS [Limit ID],
          l.[Лимиты Код]          AS [Limit Code],
          l.[Лимиты Наименование] AS [Limit Name]
    FROM [ATK].[dbo].[Справочники.Лимиты] l
    WHERE ISNULL(l.[Лимиты Пометка Удаления], 0) <> 1
),
reg AS (
    SELECT
          d.[РегистрацияЛимита ID]           AS [Reg ID],
          d.[РегистрацияЛимита Дата]         AS [CreateDate],
          d.[РегистрацияЛимита Номер]        AS [Reg No],
          d.[РегистрацияЛимита Проведен]     AS [Posted],
          d.[РегистрацияЛимита Вид Операции] AS [Operation Type],
          d.[РегистрацияЛимита Дата Решения] AS [DecisionDate],
          d.[РегистрацияЛимита Лимит ID]     AS [Limit ID],
          d.[РегистрацияЛимита Основной Клиент ID] AS [Client ID],
          d.[РегистрацияЛимита Состояние]    AS [State],
          d.[РегистрацияЛимита Сумма]        AS [Amount],
          d.[РегистрацияЛимита Филиал ID]    AS [Filial ID],
          d.[РегистрацияЛимита Кредитный Эксперт ID] AS [Expert ID]
    FROM [ATK].[dbo].[Документы.РегистрацияЛимита] d
    WHERE d.[РегистрацияЛимита Проведен] = 1
),
-- First "Set" per limit
first_set AS (
    SELECT *
    FROM (
        SELECT
              r.[Limit ID],
              r.[CreateDate]     AS [FirstSet CreateDate],
              r.[DecisionDate]   AS [FirstSet DecisionDate],
              r.[Operation Type] AS [FirstSet Operation Type],
              r.[Reg No],
              r.[Reg ID],
              r.[Filial ID]      AS [FirstFilial ID],
              r.[Expert ID]      AS [FirstExpert ID],
              r.[Client ID]      AS [FirstClient ID],
              r.[Amount]         AS [FirstSet Amount],
              ROW_NUMBER() OVER (
                  PARTITION BY r.[Limit ID]
                  ORDER BY r.[CreateDate] ASC, r.[Reg No] ASC, r.[Reg ID] ASC
              ) AS rn
        FROM reg r
        WHERE r.[Operation Type] = N'Установка'
    ) x
    WHERE x.rn = 1
),
-- Last operation per limit (any type)
last_any AS (
    SELECT *
    FROM (
        SELECT
              r.[Limit ID],
              r.[CreateDate]     AS [Last CreateDate],
              r.[DecisionDate]   AS [Last DecisionDate],
              r.[Operation Type] AS [Last Operation Type],
              r.[Reg No],
              r.[Reg ID],
              r.[Filial ID]      AS [LastFilial ID],
              r.[Expert ID]      AS [LastExpert ID],
              r.[Client ID]      AS [LastClient ID],
              r.[Amount]         AS [Last Amount],
              r.[State]          AS [Last State],
              ROW_NUMBER() OVER (
                  PARTITION BY r.[Limit ID]
                  ORDER BY r.[CreateDate] DESC, r.[Reg No] DESC, r.[Reg ID] DESC
              ) AS rn
        FROM reg r
    ) x
    WHERE x.rn = 1
)

INSERT INTO mis.[Silver_Limits] (
      [Limit ID], [Limit Code], [Limit Name],
      [FirstSet Operation Type], [FirstSet CreateDate], [FirstSet DecisionDate],
      [FirstFilial ID], [FirstExpert ID], [FirstClient ID], [FirstSet Amount],
      [Last Operation Type], [Last CreateDate], [Last DecisionDate],
      [LastFilial ID], [LastExpert ID], [LastClient ID], [Last Amount], [Last State]
)
SELECT
      l.[Limit ID], l.[Limit Code], l.[Limit Name],
      fs.[FirstSet Operation Type], fs.[FirstSet CreateDate], fs.[FirstSet DecisionDate],
      fs.[FirstFilial ID], fs.[FirstExpert ID], fs.[FirstClient ID], fs.[FirstSet Amount],
      la.[Last Operation Type], la.[Last CreateDate], la.[Last DecisionDate],
      la.[LastFilial ID], la.[LastExpert ID], la.[LastClient ID], la.[Last Amount], la.[Last State]
FROM lim l
LEFT JOIN first_set fs ON fs.[Limit ID] = l.[Limit ID]
LEFT JOIN last_any  la ON la.[Limit ID] = l.[Limit ID];

-------------------------------------------------------
-- Step 4: Create unique clustered index
-------------------------------------------------------
CREATE UNIQUE CLUSTERED INDEX CX_Silver_Limits
ON mis.[Silver_Limits] ([Limit ID]);
