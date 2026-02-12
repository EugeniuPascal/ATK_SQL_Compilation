USE [ATK];
GO


IF OBJECT_ID('mis.[Gold_Dim_Limits]', 'U') IS NULL
BEGIN
    CREATE TABLE mis.[Gold_Dim_Limits]
    (
        [LimitRegistrationID] VARCHAR(36) PRIMARY KEY,
        [LimitRegistrationDate] DATETIME,
        [AuthorID] VARCHAR(36),
        [AuthorName] NVARCHAR(255),
        [UsageType] NVARCHAR(255),
        [LimitType] NVARCHAR(255),
        [OperationType] NVARCHAR(255),
        [DecisionDate] DATETIME,
        [BaseDocumentType] NVARCHAR(255),
        [BaseDocumentKind] NVARCHAR(255),
        [BaseDocumentID] VARCHAR(36),
        [ValidityMonths] INT,
        [CommitteeID] VARCHAR(36),
        [CommitteeName] NVARCHAR(255),
        [Comment] NVARCHAR(MAX),
        [CreditExpertID] VARCHAR(36),
        [CreditExpertName] NVARCHAR(255),
        [LimitRegLimitID] VARCHAR(36),
        [LimitRegistrationName] NVARCHAR(255),
        [MainClientID] VARCHAR(36),
        [MainClientName] NVARCHAR(255),
        [CommitteeChairmanID] VARCHAR(36),
        [CommitteeChairmanName] NVARCHAR(255),
        [MIRepresentativeID] VARCHAR(36),
        [MIRepresentativeName] NVARCHAR(255),
        [RejectionReasonID] VARCHAR(36),
        [RejectionReason] NVARCHAR(255),
        [RejectionReasonDescription] NVARCHAR(MAX),
        [RegistrationStatus] NVARCHAR(100),
        [ApprovedAmount] DECIMAL(18,2),
        [DecisionText] NVARCHAR(MAX),
        [BranchID] VARCHAR(36),
        [BranchName] NVARCHAR(255),
        [ExcessPercentage] DECIMAL(10,2),
        [SummaryData] NVARCHAR(MAX),
        [SubmissionDate] DATETIME,
        [IsSummaryCompleted] BIT,
        [AffiliatedGroupID] VARCHAR(36),
        [AffiliatedGroupName] NVARCHAR(255),
        [ConsolidatedBalance] DECIMAL(18,2),
        [EffectiveStartDate] DATETIME,
        [AnalysisType] NVARCHAR(255),
        [UnsecuredAmount] DECIMAL(18,2),
        [UnsecuredAmountComment] NVARCHAR(MAX),
        [IsIndividualGuaranteeAnalyzed] BIT,
        [ProceduralUnsecuredAmount] DECIMAL(18,2),
        [LimitID] VARCHAR(36),
        [LimitDeletedFlag] CHAR(2),
        [LimitCode] NVARCHAR(100),
        [LimitName] NVARCHAR(255),
        [LimitCatalog] NVARCHAR(500),
        [GroupOwner] VARCHAR(36),
        [GroupNameFull] NVARCHAR(255),
        [EmployeeID] VARCHAR(36)
    );
END
GO

IF OBJECT_ID('tempdb..#LatestGroups') IS NOT NULL DROP TABLE #LatestGroups;
IF OBJECT_ID('tempdb..#LatestGroupsFinal') IS NOT NULL DROP TABLE #LatestGroupsFinal;


SELECT
    sg.[СоставГруппАффилированныхЛиц Контрагент ID] AS ClientID,
    sg.[СоставГруппАффилированныхЛиц Группа Аффилированных Лиц ID] AS GroupID,
    sg.[СоставГруппАффилированныхЛиц Период] AS Period,
    d.[РегистрацияЛимита ID] AS LimitRegID
INTO #LatestGroups
FROM [ATK].[dbo].[РегистрыСведений.СоставГруппАффилированныхЛиц] sg
JOIN [ATK].[dbo].[Документы.РегистрацияЛимита] d
    ON sg.[СоставГруппАффилированныхЛиц Контрагент ID] = d.[РегистрацияЛимита Основной Клиент ID]
   AND sg.[СоставГруппАффилированныхЛиц Период] <= d.[РегистрацияЛимита Дата]
WHERE d.[РегистрацияЛимита Проведен] = '01'
  AND d.[РегистрацияЛимита Пометка Удаления] = '00';

;WITH CTE_Latest AS
(
    SELECT *,
           ROW_NUMBER() OVER(PARTITION BY LimitRegID ORDER BY Period DESC) AS rn
    FROM #LatestGroups
)
SELECT *
INTO #LatestGroupsFinal
FROM CTE_Latest
WHERE rn = 1;


INSERT INTO mis.[Gold_Dim_Limits]
(
    [LimitRegistrationID],
    [LimitRegistrationDate],
    [AuthorID],
    [AuthorName],
    [UsageType],
    [LimitType],
    [OperationType],
    [DecisionDate],
    [BaseDocumentType],
    [BaseDocumentKind],
    [BaseDocumentID],
    [ValidityMonths],
    [CommitteeID],
    [CommitteeName],
    [Comment],
    [CreditExpertID],
    [CreditExpertName],
    [LimitRegLimitID],
    [LimitRegistrationName],
    [MainClientID],
    [MainClientName],
    [CommitteeChairmanID],
    [CommitteeChairmanName],
    [MIRepresentativeID],
    [MIRepresentativeName],
    [RejectionReasonID],
    [RejectionReason],
    [RejectionReasonDescription],
    [RegistrationStatus],
    [ApprovedAmount],
    [DecisionText],
    [BranchID],
    [BranchName],
    [ExcessPercentage],
    [SummaryData],
    [SubmissionDate],
    [IsSummaryCompleted],
    [AffiliatedGroupID],
    [AffiliatedGroupName],
    [ConsolidatedBalance],
    [EffectiveStartDate],
    [AnalysisType],
    [UnsecuredAmount],
    [UnsecuredAmountComment],
    [IsIndividualGuaranteeAnalyzed],
    [ProceduralUnsecuredAmount],
    [LimitID],
    [LimitDeletedFlag],
    [LimitCode],
    [LimitName],
    [LimitCatalog],
    [GroupOwner],
    [GroupNameFull],
    [EmployeeID]
)
SELECT  
     d.[РегистрацияЛимита ID]                       AS [LimitRegistrationID],
     d.[РегистрацияЛимита Дата]                     AS [LimitRegistrationDate],
     d.[РегистрацияЛимита Автор ID]                 AS [AuthorID],
     d.[РегистрацияЛимита Автор]                    AS [AuthorName],
     d.[РегистрацияЛимита Вид Использования]        AS [UsageType],
     d.[РегистрацияЛимита Вид Лимита]               AS [LimitType],
     d.[РегистрацияЛимита Вид Операции]             AS [OperationType],
     d.[РегистрацияЛимита Дата Решения]             AS [DecisionDate],
     d.[РегистрацияЛимита Документ Основание Tип]   AS [BaseDocumentType],
     d.[РегистрацияЛимита Документ Основание Вид]   AS [BaseDocumentKind],
     d.[РегистрацияЛимита Документ Основание ID]    AS [BaseDocumentID],
     d.[РегистрацияЛимита Количество Месяцев Действия Лимита]     AS [ValidityMonths],
     d.[РегистрацияЛимита Комитет ID]               AS [CommitteeID],
     d.[РегистрацияЛимита Комитет]                  AS [CommitteeName],
     d.[РегистрацияЛимита Комментарий]              AS [Comment],
     d.[РегистрацияЛимита Кредитный Эксперт ID]     AS [CreditExpertID],
     d.[РегистрацияЛимита Кредитный Эксперт]        AS [CreditExpertName],
     d.[РегистрацияЛимита Лимит ID]                 AS [LimitRegLimitID],
     d.[РегистрацияЛимита Лимит]                    AS [LimitRegistrationName],
     d.[РегистрацияЛимита Основной Клиент ID]       AS [MainClientID],
     d.[РегистрацияЛимита Основной Клиент]          AS [MainClientName],
     d.[РегистрацияЛимита Председатель Комитета ID] AS [CommitteeChairmanID],
     d.[РегистрацияЛимита Председатель Комитета]    AS [CommitteeChairmanName],
     d.[РегистрацияЛимита Представитель MI ID]      AS [MIRepresentativeID],
     d.[РегистрацияЛимита Представитель MI]         AS [MIRepresentativeName],
     d.[РегистрацияЛимита Причина Отказа ID]        AS [RejectionReasonID],
     d.[РегистрацияЛимита Причина Отказа]           AS [RejectionReason],
     d.[РегистрацияЛимита Причина Отказа Описание]  AS [RejectionReasonDescription],
     d.[РегистрацияЛимита Состояние]                AS [RegistrationStatus],
     d.[РегистрацияЛимита Сумма]                    AS [ApprovedAmount],
     d.[РегистрацияЛимита Текст Решения]            AS [DecisionText],
     d.[РегистрацияЛимита Филиал ID]                AS [BranchID],
     d.[РегистрацияЛимита Филиал]                   AS [BranchName],
     d.[РегистрацияЛимита Процент Превышения Лимита]       AS [ExcessPercentage],
     d.[РегистрацияЛимита Данные Резюме]                   AS [SummaryData],
     d.[РегистрацияЛимита Дата Отправки на Рассмотрение]   AS [SubmissionDate],
     d.[РегистрацияЛимита Резюме Заполнено]                AS [IsSummaryCompleted],
     d.[РегистрацияЛимита Группа Аффилированных Лиц ID]    AS [AffiliatedGroupID],
     d.[РегистрацияЛимита Группа Аффилированных Лиц]       AS [AffiliatedGroupName],
     d.[РегистрацияЛимита Консолидированное Сальдо]        AS [ConsolidatedBalance],
     d.[РегистрацияЛимита Начало Действия]                 AS [EffectiveStartDate],
     d.[РегистрацияЛимита Тип Анализа Лимита]              AS [AnalysisType],
     d.[РегистрацияЛимита Сумма к Выдаче без Залога]       AS [UnsecuredAmount],
     d.[РегистрацияЛимита Комментарий Сумма к Выдаче без Залога]                   AS [UnsecuredAmountComment],
     d.[РегистрацияЛимита Предложенное Поручительство Анализировано Индивидуально] AS [IsIndividualGuaranteeAnalyzed],
     d.[РегистрацияЛимита В Соответствии с Процедурой Сумма к Выдаче без Залога]   AS [ProceduralUnsecuredAmount],

     l.[Лимиты ID]                                    AS [LimitID],
     l.[Лимиты Пометка Удаления]                      AS [LimitDeletedFlag],
     l.[Лимиты Код]                                   AS [LimitCode],
     l.[Лимиты Наименование]                          AS [LimitName],
     l.[Лимиты Каталог Сохранения Файлов]             AS [LimitCatalog],

     COALESCE(g.[ГруппыАффилированныхЛиц Владелец], d.[РегистрацияЛимита Основной Клиент ID])  AS [GroupOwner],
     g.[ГруппыАффилированныхЛиц Наименование]         AS [GroupNameFull],
     k.[Контрагенты Сотрудник ID]                     AS [EmployeeID]
FROM [ATK].[dbo].[Документы.РегистрацияЛимита] d
LEFT JOIN [ATK].[dbo].[Справочники.Лимиты] l
       ON d.[РегистрацияЛимита Лимит ID] = l.[Лимиты ID]
LEFT JOIN #LatestGroupsFinal lg
       ON lg.LimitRegID = d.[РегистрацияЛимита ID]
LEFT JOIN [ATK].[dbo].[Справочники.ГруппыАффилированныхЛиц] g
       ON lg.GroupID = g.[ГруппыАффилированныхЛиц ID]
LEFT JOIN [ATK].[dbo].[Справочники.Контрагенты] k
       ON k.[Контрагенты ID] = COALESCE(g.[ГруппыАффилированныхЛиц Владелец], d.[РегистрацияЛимита Основной Клиент ID])
WHERE d.[РегистрацияЛимита Проведен] = '01'
  AND d.[РегистрацияЛимита Пометка Удаления] = '00'
  AND NOT EXISTS
  (
      SELECT 1
      FROM mis.[Gold_Dim_Limits] gl
      WHERE gl.LimitRegistrationID = d.[РегистрацияЛимита ID]
  );

DROP TABLE IF EXISTS #LatestGroups;
DROP TABLE IF EXISTS #LatestGroupsFinal;
