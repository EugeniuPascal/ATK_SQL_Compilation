USE [ATK];
SET NOCOUNT ON;


IF OBJECT_ID(N'mis.[Gold_Fact_ConditionsAfterDisb_Last]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_ConditionsAfterDisb_Last];


CREATE TABLE mis.[Gold_Fact_ConditionsAfterDisb_Last] 
(
      [Period]                  DATETIME2(0)     NULL,
      [ObjectType]              VARCHAR(36)      NULL,
      [ObjectID]                VARCHAR(36)      NULL,
      [ID]                      VARCHAR(36)      NOT NULL,
      [ConditionType]           NVARCHAR(256)    NULL,
      [ConditionObjectType]     VARCHAR(36)      NULL,
      [ConditionObject_S]       NVARCHAR(500)    NULL,
      [AdditionalPercent]       DECIMAL(4,2)     NULL,
      [Deadline]                DATETIME2(0)     NULL,
      [ExecutorID]              VARCHAR(36)      NULL,
      [Executor]                NVARCHAR(100)    NULL,
      [IssueDate]               DATETIME2(0)     NULL,
      [Completed]               VARCHAR(36)      NULL,
      [CompletionDate]          DATETIME2(0)     NULL,
      [Comment]                 NVARCHAR(1000)   NULL,
      [Checked]                 VARCHAR(36)      NULL,
      [IsAdditionalCondition]   VARCHAR(36)      NULL,
      [Cancelled]               VARCHAR(36)      NULL,
      [CreditRisk]              NVARCHAR(256)    NULL,
      [LegalRisk]               NVARCHAR(256)    NULL,
      [ApprovedByCommittee]     VARCHAR(36)      NULL,
      [CollateralID]            VARCHAR(36)      NULL,
      [Collateral]              NVARCHAR(200)    NULL,
      [CancelledByID]           VARCHAR(36)      NULL,
      [CancelledBy]             NVARCHAR(200)    NULL,
      [CheckedByID]             VARCHAR(36)      NULL,
      [CheckedBy]               NVARCHAR(200)    NULL,
      [ChangeDate]              DATETIME2(0)     NULL,
      [SourceType]              VARCHAR(36)      NULL,
      [SourceKind]              VARCHAR(36)      NULL,
      [SourceID]                VARCHAR(36)      NULL,
      [ResponsibleID]           VARCHAR(36)      NULL,
      [Responsible]             NVARCHAR(200)    NULL,
      [CheckDate]               DATETIME2(0)     NULL,
      [CancelDate]              DATETIME2(0)     NULL,
      [CloseDate]               DATETIME2(0)     NULL,
      [CreditID_Found]          VARCHAR(36)      NULL,
      [ClientID]                VARCHAR(36)      NULL
);

;WITH src AS
(
    SELECT
          r.[УсловияПослеВыдачиКредита Период] AS [Period],
          r.[УсловияПослеВыдачиКредита Объект Tип] AS [ObjectType],
          r.[УсловияПослеВыдачиКредита Объект ID] AS [ObjectID],
          r.[УсловияПослеВыдачиКредита ИД] AS [ID],
          r.[УсловияПослеВыдачиКредита Тип Условия] AS [ConditionType],
          r.[УсловияПослеВыдачиКредита Объект Условия Tип] AS [ConditionObjectType],
          r.[УсловияПослеВыдачиКредита Объект Условия _S] AS [ConditionObject_S],
          r.[УсловияПослеВыдачиКредита Доп Проценты] AS [AdditionalPercent],
          r.[УсловияПослеВыдачиКредита Срок Выполнения] AS [Deadline],
          r.[УсловияПослеВыдачиКредита Исполнитель ID] AS [ExecutorID],
          r.[УсловияПослеВыдачиКредита Исполнитель] AS [Executor],
          r.[УсловияПослеВыдачиКредита Дата Выдачи] AS [IssueDate],
          r.[УсловияПослеВыдачиКредита Выполнено] AS [Completed],
          r.[УсловияПослеВыдачиКредита Дата Выполнения] AS [CompletionDate],
          r.[УсловияПослеВыдачиКредита Комментарий] AS [Comment],
          r.[УсловияПослеВыдачиКредита Проверено] AS [Checked],
          r.[УсловияПослеВыдачиКредита Это Доп Условия] AS [IsAdditionalCondition],
          r.[УсловияПослеВыдачиКредита Аннулирован] AS [Cancelled],
          r.[УсловияПослеВыдачиКредита Кредитный Риск] AS [CreditRisk],
          r.[УсловияПослеВыдачиКредита Юридический Риск] AS [LegalRisk],
          r.[УсловияПослеВыдачиКредита Одобренно Комитетом] AS [ApprovedByCommittee],
          r.[УсловияПослеВыдачиКредита Залог ID] AS [CollateralID],
          r.[УсловияПослеВыдачиКредита Залог] AS [Collateral],
          r.[УсловияПослеВыдачиКредита Автор Аннулирования ID] AS [CancelledByID],
          r.[УсловияПослеВыдачиКредита Автор Аннулирования] AS [CancelledBy],
          r.[УсловияПослеВыдачиКредита Автор Проверки ID] AS [CheckedByID],
          r.[УсловияПослеВыдачиКредита Автор Проверки] AS [CheckedBy],
          r.[УсловияПослеВыдачиКредита Дата Изменения] AS [ChangeDate],
          r.[УсловияПослеВыдачиКредита Источник Tип] AS [SourceType],
          r.[УсловияПослеВыдачиКредита Источник Вид] AS [SourceKind],
          r.[УсловияПослеВыдачиКредита Источник ID] AS [SourceID],
          r.[УсловияПослеВыдачиКредита Ответственный ID] AS [ResponsibleID],
          r.[УсловияПослеВыдачиКредита Ответственный] AS [Responsible],

          ROW_NUMBER() OVER (
              PARTITION BY r.[УсловияПослеВыдачиКредита ИД]
              ORDER BY r.[УсловияПослеВыдачиКредита Период] DESC,
                       r.[УсловияПослеВыдачиКредита Дата Изменения] DESC
          ) AS rn
    FROM [ATK].[dbo].[РегистрыСведений.УсловияПослеВыдачиКредита] r
    WHERE r.[УсловияПослеВыдачиКредита Объект Tип] = 8
),
lastrow AS
(
    SELECT
          s.*,
          CASE WHEN s.[Checked] = 1 THEN s.[Period] END AS [CheckDate],
          CASE WHEN s.[Cancelled] = 1 THEN s.[Period] END AS [CancelDate],
          CASE WHEN s.[Checked] = 1 OR s.[Cancelled] = 1 THEN s.[Period] END AS [CloseDate]
    FROM src s
    WHERE s.rn = 1
)


INSERT INTO mis.[Gold_Fact_ConditionsAfterDisb_Last] 
(
      [Period], [ObjectType], [ObjectID], [ID], [ConditionType],
      [ConditionObjectType], [ConditionObject_S], [AdditionalPercent], [Deadline],
      [ExecutorID], [Executor], [IssueDate], [Completed], [CompletionDate],
      [Comment], [Checked], [IsAdditionalCondition], [Cancelled], [CreditRisk],
      [LegalRisk], [ApprovedByCommittee], [CollateralID], [Collateral],
      [CancelledByID], [CancelledBy], [CheckedByID], [CheckedBy],
      [ChangeDate], [SourceType], [SourceKind], [SourceID],
      [ResponsibleID], [Responsible], [CheckDate], [CancelDate], [CloseDate],
      [CreditID_Found], [ClientID]
)
SELECT
      s.[Period],
      s.[ObjectType],
      s.[ObjectID],
      s.[ID],
      s.[ConditionType],
      s.[ConditionObjectType],
      s.[ConditionObject_S],
      s.[AdditionalPercent],
      s.[Deadline],
      s.[ExecutorID],
      s.[Executor],
      s.[IssueDate],
      s.[Completed],
      s.[CompletionDate],
      s.[Comment],
      s.[Checked],
      s.[IsAdditionalCondition],
      s.[Cancelled],
      s.[CreditRisk],
      s.[LegalRisk],
      s.[ApprovedByCommittee],
      s.[CollateralID],
      s.[Collateral],
      s.[CancelledByID],
      s.[CancelledBy],
      s.[CheckedByID],
      s.[CheckedBy],
      s.[ChangeDate],
      s.[SourceType],
      s.[SourceKind],
      s.[SourceID],
      s.[ResponsibleID],
      s.[Responsible],
      s.[CheckDate],
      s.[CancelDate],
      s.[CloseDate],
      c.[Кредиты ID],
      COALESCE(c.[Кредиты Владелец], lim.[LastClient ID], grp.[GroupClient ID])
FROM lastrow s
LEFT JOIN [ATK].[mis].[Bronze_Справочники.Кредиты] c
       ON c.[Кредиты ID] = s.[ObjectID]
OUTER APPLY
(
    SELECT TOP (1) l.[LastClient ID]
    FROM [ATK].[mis].[Silver_Limits] l
    WHERE l.[Limit ID] = s.[ObjectID]
    ORDER BY l.[Last CreateDate] DESC, l.[Last DecisionDate] DESC
) lim
OUTER APPLY
(
    SELECT TOP (1) g.[ГруппыАффилированныхЛиц Владелец] AS [GroupClient ID]
    FROM [ATK].[dbo].[Справочники.ГруппыАффилированныхЛиц] g
    WHERE g.[ГруппыАффилированныхЛиц ID] = s.[ObjectID]
      AND g.[ГруппыАффилированныхЛиц Пометка Удаления] = 0
    ORDER BY g.[ГруппыАффилированныхЛиц Версия Данных] DESC
) grp;


CREATE UNIQUE CLUSTERED INDEX CX_ConditionsAfterDisb_Last
ON [mis].[Gold_Fact_ConditionsAfterDisb_Last] ([ID]);

CREATE INDEX IX_ConditionsAfterDisb_Last_ObjectID
ON [mis].[Gold_Fact_ConditionsAfterDisb_Last] ([ObjectID]);

CREATE INDEX IX_ConditionsAfterDisb_Last_CreditFound
ON [mis].[Gold_Fact_ConditionsAfterDisb_Last] ([CreditID_Found]);

CREATE INDEX IX_ConditionsAfterDisb_Last_ClientID
ON [mis].[Gold_Fact_ConditionsAfterDisb_Last] ([ClientID]);
