;WITH LatestGroups AS
(
    SELECT
        sg.[СоставГруппАффилированныхЛиц Контрагент ID] AS ClientID,
        sg.[СоставГруппАффилированныхЛиц Группа Аффилированных Лиц ID] AS GroupID,
        sg.[СоставГруппАффилированныхЛиц Период] AS Period,
        d.[РегистрацияЛимита ID] AS LimitRegID,
        ROW_NUMBER() OVER(PARTITION BY d.[РегистрацияЛимита ID] ORDER BY sg.[СоставГруппАффилированныхЛиц Период] DESC) AS rn
    FROM [ATK].[dbo].[РегистрыСведений.СоставГруппАффилированныхЛиц] sg
    JOIN [ATK].[dbo].[Документы.РегистрацияЛимита] d
        ON sg.[СоставГруппАффилированныхЛиц Контрагент ID] = d.[РегистрацияЛимита Основной Клиент ID]
       AND sg.[СоставГруппАффилированныхЛиц Период] <= d.[РегистрацияЛимита Дата]
    WHERE d.[РегистрацияЛимита Проведен] = '01'
      AND d.[РегистрацияЛимита Пометка Удаления] = '00'
)
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
    [BaseDocumentID],
    [ValidityMonths],
    [CommitteeID],
    [CommitteeName],
    [Comment],
    [CreditExpertID],
    [CreditExpertName],
    [LimitRegLimitID],
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
     d.[РегистрацияЛимита Документ Основание ID]    AS [BaseDocumentID],
     d.[РегистрацияЛимита Количество Месяцев Действия Лимита]     AS [ValidityMonths],
     d.[РегистрацияЛимита Комитет ID]               AS [CommitteeID],
     d.[РегистрацияЛимита Комитет]                  AS [CommitteeName],
     d.[РегистрацияЛимита Комментарий]              AS [Comment],
     d.[РегистрацияЛимита Кредитный Эксперт ID]     AS [CreditExpertID],
     d.[РегистрацияЛимита Кредитный Эксперт]        AS [CreditExpertName],
     d.[РегистрацияЛимита Лимит ID]                 AS [LimitRegLimitID],
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
     d.[РегистрацияЛимита Комментарий Сумма к Выдаче без Залога] AS [UnsecuredAmountComment],
     d.[РегистрацияЛимита Предложенное Поручительство Анализировано Индивидуально] AS [IsIndividualGuaranteeAnalyzed],
     d.[РегистрацияЛимита В Соответствии с Процедурой Сумма к Выдаче без Залога]   AS [ProceduralUnsecuredAmount],
     l.[Лимиты ID]                                    AS [LimitID],
     l.[Лимиты Пометка Удаления]                      AS [LimitDeletedFlag],
     l.[Лимиты Код]                                   AS [LimitCode],
     COALESCE(g.[ГруппыАффилированныхЛиц Владелец], d.[РегистрацияЛимита Основной Клиент ID])  AS [GroupOwner],
     g.[ГруппыАффилированныхЛиц Наименование]         AS [GroupNameFull],
     CASE 
         WHEN k.[Контрагенты Сотрудник ID] = '00000000000000000000000000000000' 
         THEN NULL 
         ELSE k.[Контрагенты Сотрудник ID] 
     END AS [EmployeeID]
FROM [ATK].[dbo].[Документы.РегистрацияЛимита] d
LEFT JOIN [ATK].[dbo].[Справочники.Лимиты] l
       ON d.[РегистрацияЛимита Лимит ID] = l.[Лимиты ID]
LEFT JOIN LatestGroups lg
       ON lg.LimitRegID = d.[РегистрацияЛимита ID] AND lg.rn = 1
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
