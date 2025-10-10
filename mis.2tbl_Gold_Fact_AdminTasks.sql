USE [ATK];
GO

IF OBJECT_ID('mis.[2tbl_Gold_Fact_AdminTasks]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Fact_AdminTasks];
GO


CREATE TABLE mis.[2tbl_Gold_Fact_AdminTasks]
(
    -- Existing AdminTask columns
    [AdminTask_ID] VARCHAR(36) NOT NULL,
    [AdminTask_RowVersion] ROWVERSION NULL,
    [AdminTask_Deleted] VARCHAR(36) NOT NULL,
    [AdminTask_Date] DATETIME NULL,
    [AdminTask_Number] NVARCHAR(50) NOT NULL,
    [AdminTask_Completed] VARCHAR(36) NOT NULL,
    [AdminTask_Author_ID] VARCHAR(36) NOT NULL,
    [AdminTask_Author] NVARCHAR(150) NOT NULL,
    [AdminTask_Branch_ID] VARCHAR(36) NOT NULL,
    [AdminTask_Branch] NVARCHAR(150) NULL,
    [AdminTask_Category_ID] VARCHAR(36) NOT NULL,
    [AdminTask_Category] NVARCHAR(250) NOT NULL,
    [AdminTask_Type_ID] VARCHAR(36) NOT NULL,
    [AdminTask_Type] NVARCHAR(250) NOT NULL,
    [AdminTask_Description] NVARCHAR(1050) NOT NULL,
    [AdminTask_Base_ID] VARCHAR(36) NOT NULL,
    [AdminTask_Source_Type] VARCHAR(36) NOT NULL,
    [AdminTask_Source_View] VARCHAR(36) NOT NULL,
    [AdminTask_Source_ID] VARCHAR(36) NOT NULL,
    [AdminTask_Client_ID] VARCHAR(36) NOT NULL,
    [AdminTask_Client] NVARCHAR(150) NULL,
    [AdminTask_Credit_ID] VARCHAR(36) NOT NULL,
    [AdminTask_Credit] NVARCHAR(150) NULL,
    [AdminTask_Limit_ID] VARCHAR(36) NOT NULL,
    [AdminTask_Limit] NVARCHAR(150) NULL,
    [AdminTask_CurrentStatus] NVARCHAR(256) NULL,
    [AdminTask_CurrentStatus_ID] VARCHAR(36) NULL,
    [AdminTask_CompletionDate] DATETIME NULL,
    [AdminTask_CurrentComment] NVARCHAR(1000) NULL,
    [AdminTask_SLA] INT NULL,
    [AdminTask_KPI] DECIMAL(6,2) NULL,
    [AdminTask_TaskCount] INT NULL,
    [AdminTask_Priority] NVARCHAR(256) NULL,
    [AdminTask_Priority_ID] VARCHAR(36) NULL,
    [AdminTask_Executor] VARCHAR(36) NULL,

    -- Task type columns
    [TaskType_Deleted] VARCHAR(36) NULL,
    [TaskType_Parent_ID] VARCHAR(36) NULL,
    [TaskType_IsGroup] BIT NULL,
    [TaskType_Code] NVARCHAR(50) NULL,
    [TaskType_Name] NVARCHAR(250) NULL,
    [TaskType_Order] INT NULL,
    [TaskType_SLA] INT NULL,
    [TaskType_KPI] DECIMAL(6,2) NULL,
    [TaskType_BlockEditCount] BIT NULL,
    [TaskType_MaxTime] INT NULL,

    -- Hours
    [WaitHours] DECIMAL(18,2) NULL,
    [TotalHours] DECIMAL(18,2) NULL,
	[InProgress] DECIMAL(18,2) NULL,

    -- Status history
    [StatusHistory_ID] VARCHAR(36) NULL,
    [StatusHistory_RowNumber] INT NULL,
    [StatusHistory_Status] NVARCHAR(256) NULL,
    [StatusHistory_UserID] VARCHAR(36) NULL,
    [StatusHistory_User] NVARCHAR(150) NULL,
    [StatusHistory_StartDate] DATETIME NULL,
    [StatusHistory_EndDate] DATETIME NULL,
    [StatusHistory_Comment] NVARCHAR(1000) NULL,
    [StatusHistory_Seconds] INT NULL,

    -- New columns from СведенияОНаправленияхНаВыплату
    [НаправлениеSLA_ID] VARCHAR(36) NULL,
    [НаправлениеSLA_Name] NVARCHAR(250) NULL,
    [НаправлениеSLA_SLA] INT NULL,
    [НаправлениеSLA_MaxTime] INT NULL,
    [НаправлениеSLA_CreateDate] DATETIME NULL,
    [НаправлениеSLA_WorkDate] DATETIME NULL,
    [НаправлениеSLA_ApprovalDate] DATETIME NULL,
    [НаправлениеSLA_DeletedDate] DATETIME NULL,
    [НаправлениеSLA_TypeID] VARCHAR(36) NULL,
    [НаправлениеSLA_TypeName] NVARCHAR(250) NULL,
    [НаправлениеDoc_ID] VARCHAR(36) NULL
);
GO

INSERT INTO mis.[2tbl_Gold_Fact_AdminTasks]
(
    [AdminTask_ID],
    [AdminTask_Deleted],
    [AdminTask_Date],
    [AdminTask_Number],
    [AdminTask_Completed],
    [AdminTask_Author_ID],
    [AdminTask_Author],
    [AdminTask_Branch_ID],
    [AdminTask_Branch],
    [AdminTask_Category_ID],
    [AdminTask_Category],
    [AdminTask_Type_ID],
    [AdminTask_Type],
    [AdminTask_Description],
    [AdminTask_Base_ID],
    [AdminTask_Source_Type],
    [AdminTask_Source_View],
    [AdminTask_Source_ID],
    [AdminTask_Client_ID],
    [AdminTask_Client],
    [AdminTask_Credit_ID],
    [AdminTask_Credit],
    [AdminTask_Limit_ID],
    [AdminTask_Limit],
    [AdminTask_CurrentStatus],
    [AdminTask_CurrentStatus_ID],
    [AdminTask_CompletionDate],
    [AdminTask_CurrentComment],
    [AdminTask_SLA],
    [AdminTask_KPI],
    [AdminTask_TaskCount],
    [AdminTask_Priority],
    [AdminTask_Priority_ID],
    [AdminTask_Executor],

    [TaskType_Deleted],
    [TaskType_Parent_ID],
    [TaskType_IsGroup],
    [TaskType_Code],
    [TaskType_Name],
    [TaskType_Order],
    [TaskType_SLA],
    [TaskType_KPI],
    [TaskType_BlockEditCount],
    [TaskType_MaxTime],

    [WaitHours],
    [TotalHours],
	[InProgress],

    [StatusHistory_ID],
    [StatusHistory_RowNumber],
    [StatusHistory_Status],
    [StatusHistory_UserID],
    [StatusHistory_User],
    [StatusHistory_StartDate],
    [StatusHistory_EndDate],
    [StatusHistory_Comment],
    [StatusHistory_Seconds],

    [НаправлениеSLA_ID],
    [НаправлениеSLA_Name],
    [НаправлениеSLA_SLA],
    [НаправлениеSLA_MaxTime],
    [НаправлениеSLA_CreateDate],
    [НаправлениеSLA_WorkDate],
    [НаправлениеSLA_ApprovalDate],
    [НаправлениеSLA_DeletedDate],
    [НаправлениеSLA_TypeID],
    [НаправлениеSLA_TypeName],
    [НаправлениеDoc_ID]
)
SELECT
    a.[ЗадачаАдминистратораКредитов ID],
    a.[ЗадачаАдминистратораКредитов Пометка Удаления],
    a.[ЗадачаАдминистратораКредитов Дата],
    a.[ЗадачаАдминистратораКредитов Номер],
    a.[ЗадачаАдминистратораКредитов Выполнена],
    a.[ЗадачаАдминистратораКредитов Автор ID],
    a.[ЗадачаАдминистратораКредитов Автор],
    a.[ЗадачаАдминистратораКредитов Филиал ID],
    a.[ЗадачаАдминистратораКредитов Филиал],
    a.[ЗадачаАдминистратораКредитов Категория Задачи ID],
    a.[ЗадачаАдминистратораКредитов Категория Задачи],
    a.[ЗадачаАдминистратораКредитов Тип Задачи ID],
    a.[ЗадачаАдминистратораКредитов Тип Задачи],
    a.[ЗадачаАдминистратораКредитов Описание Задачи],
    a.[ЗадачаАдминистратораКредитов Задача Основание ID],
    a.[ЗадачаАдминистратораКредитов Источник Тип],
    a.[ЗадачаАдминистратораКредитов Источник Вид],
    a.[ЗадачаАдминистратораКредитов Источник ID],
    a.[ЗадачаАдминистратораКредитов Клиент ID],
    a.[ЗадачаАдминистратораКредитов Клиент],
    a.[ЗадачаАдминистратораКредитов Кредит ID],
    a.[ЗадачаАдминистратораКредитов Кредит],
    a.[ЗадачаАдминистратораКредитов Лимит ID],
    a.[ЗадачаАдминистратораКредитов Лимит],
    sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Статус],
    sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Статус ID],
    a.[ЗадачаАдминистратораКредитов Дата Выполнения],
    a.[ЗадачаАдминистратораКредитов Текущий Комментарий],
    hist_tasktype.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей SLA],
    hist_tasktype.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей KPI],
    a.[ЗадачаАдминистратораКредитов Количество Задач],
    a.[ЗадачаАдминистратораКредитов Приоритет Задачи],
    a.[ЗадачаАдминистратораКредитов Приоритет Задачи ID],
    a.[ЗадачаАдминистратораКредитов Исполнитель],

    t.[ТипыЗадачАдминистратораКредитов Пометка Удаления],
    t.[ТипыЗадачАдминистратораКредитов Родитель ID],
    t.[ТипыЗадачАдминистратораКредитов Это Группа],
    t.[ТипыЗадачАдминистратораКредитов Код],
    t.[ТипыЗадачАдминистратораКредитов Наименование],
    t.[ТипыЗадачАдминистратораКредитов Реквизит Доп Упорядочивания],
    hist_tasktype.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей SLA],
    hist_tasktype.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей KPI],
    t.[ТипыЗадачАдминистратораКредитов Запрет Редактирования Количества Задач],
    hist_tasktype.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей Максимальное Время Выполнения],

    COALESCE(wait_hours.WaitHours, 0) AS WaitHours,
    COALESCE(total_hours.TotalHours, 0) AS TotalHours,
	COALESCE(in_progress.InProgress, 0) AS InProgress,

    sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID],
    sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Номер Строки],
    sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Статус],
    sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Пользователь ID],
    sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Пользователь],
    sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Дата Начала],
    sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Дата Окончания],
    sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Комментарий],
    sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Время в Секундах],

    pay.[СведенияОНаправленияхНаВыплату Направление на Выплату ID],
    pay.[СведенияОНаправленияхНаВыплату Направление на Выплату],
    pay.[СведенияОНаправленияхНаВыплату SLA],
    pay.[СведенияОНаправленияхНаВыплату Максимальное Время Выполнения],
    pay.[СведенияОНаправленияхНаВыплату Дата Создания],
    pay.[СведенияОНаправленияхНаВыплату Дата Взятия в Работу],
    pay.[СведенияОНаправленияхНаВыплату Дата Утверждения],
    pay.[СведенияОНаправленияхНаВыплату Дата Пометки Удаления],
    pay.[СведенияОНаправленияхНаВыплату Тип Направления на Выплату ID],
    pay.[СведенияОНаправленияхНаВыплату Тип Направления на Выплату],
    doc.[НаправлениеНаВыплату ID] AS НаправлениеDoc_ID

FROM [ATK].[mis].[Silver_Задачи.ЗадачаАдминистратораКредитов] a
LEFT JOIN [ATK].[mis].[Silver_Справочники.ТипыЗадачАдминистратораКредитов] t
    ON a.[ЗадачаАдминистратораКредитов Тип Задачи ID] = t.[ТипыЗадачАдминистратораКредитов ID]
OUTER APPLY
(
    SELECT TOP 1 *
    FROM [ATK].[mis].[Silver_Задачи.ЗадачаАдминистратораКредитов.ИсторияСтатусов] s
    WHERE s.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID] = a.[ЗадачаАдминистратораКредитов ID]
    ORDER BY s.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Номер Строки] DESC
) sh
OUTER APPLY
(
    SELECT SUM(CAST(s2.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Время в Секундах] AS FLOAT))/3600.0 AS TotalHours
    FROM [ATK].[mis].[Silver_Задачи.ЗадачаАдминистратораКредитов.ИсторияСтатусов] s2
    WHERE s2.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID] = a.[ЗадачаАдминистратораКредитов ID]
) total_hours
OUTER APPLY
(
    SELECT SUM(CAST(s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Время в Секундах] AS FLOAT))/3600.0 AS WaitHours
    FROM [ATK].[mis].[Silver_Задачи.ЗадачаАдминистратораКредитов.ИсторияСтатусов] s3
    WHERE s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID] = a.[ЗадачаАдминистратораКредитов ID]
      AND s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Статус] = N'ВОжидании'
) wait_hours

    OUTER APPLY (
        SELECT SUM(CAST(s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Время в Секундах] AS FLOAT))/3600.0 AS InProgress
        FROM [ATK].[mis].[Silver_Задачи.ЗадачаАдминистратораКредитов.ИсторияСтатусов] s3
        WHERE s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID] = a.[ЗадачаАдминистратораКредитов ID]
         AND s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Статус] = N'ВРаботе'
    ) in_progress

OUTER APPLY
(
    SELECT TOP 1 *
    FROM [ATK].[dbo].[Справочники.ТипыЗадачАдминистратораКредитов_ИсторияПоказателей] hist
    WHERE hist.[ТипыЗадачАдминистратораКредитов ID] = t.[ТипыЗадачАдминистратораКредитов ID]
      AND hist.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей Дата Изменения] <= a.[ЗадачаАдминистратораКредитов Дата]
    ORDER BY hist.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей Дата Изменения] DESC
) hist_tasktype
LEFT JOIN [ATK].[dbo].[Документы.НаправлениеНаВыплату] AS doc
    ON doc.[НаправлениеНаВыплату Кредит ID] = a.[ЗадачаАдминистратораКредитов Кредит ID]
LEFT JOIN [ATK].[dbo].[РегистрыСведений.СведенияОНаправленияхНаВыплату] AS pay
    ON pay.[СведенияОНаправленияхНаВыплату Направление на Выплату ID] = doc.[НаправлениеНаВыплату ID];
GO
