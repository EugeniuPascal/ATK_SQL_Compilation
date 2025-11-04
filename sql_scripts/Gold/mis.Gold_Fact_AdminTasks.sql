USE [ATK];
GO

IF OBJECT_ID('mis.[Gold_Fact_AdminTasks]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_AdminTasks];
GO

CREATE TABLE mis.[Gold_Fact_AdminTasks]
(
    -- Existing AdminTask columns
    [AdminTask_ID] VARCHAR(36) NOT NULL,
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
    [СведенияОНаправленияхНаВыплату Направление на Выплату ID] VARCHAR(36) NULL,
    [СведенияОНаправленияхНаВыплату Направление на Выплату] VARCHAR(100) NULL,
    [СведенияОНаправленияхНаВыплату SLA] DECIMAL (8, 3) NULL,
    [СведенияОНаправленияхНаВыплату Максимальное Время Выполнения] DECIMAL(8, 3) NULL,
    [СведенияОНаправленияхНаВыплату Дата Создания] DATETIME NULL,
    [СведенияОНаправленияхНаВыплату Дата Взятия в Работу] DATETIME NULL,
    [СведенияОНаправленияхНаВыплату Дата Утверждения] DATETIME NULL,
    [СведенияОНаправленияхНаВыплату Дата Пометки Удаления] DATETIME NULL,
    [СведенияОНаправленияхНаВыплату Тип Направления на Выплату ID] VARCHAR(36) NULL,
    [СведенияОНаправленияхНаВыплату Тип Направления на Выплату] NVARCHAR(30) NULL,
    
    [НаправлениеНаВыплату ID] VARCHAR(36) NULL,
    [НаправлениеНаВыплату Категория Риска AML] NVARCHAR(256) NULL
);
GO

;WITH AllTasks AS (
    -- Your full SELECT
    SELECT
        a.[ЗадачаАдминистратораКредитов ID] AS AdminTask_ID,
        a.[ЗадачаАдминистратораКредитов Пометка Удаления] AS AdminTask_Deleted,
        a.[ЗадачаАдминистратораКредитов Дата] AS AdminTask_Date,
        a.[ЗадачаАдминистратораКредитов Номер] AS AdminTask_Number,
        a.[ЗадачаАдминистратораКредитов Выполнена] AS AdminTask_Completed,
        a.[ЗадачаАдминистратораКредитов Автор ID] AS AdminTask_Author_ID,
        a.[ЗадачаАдминистратораКредитов Автор] AS AdminTask_Author,
        a.[ЗадачаАдминистратораКредитов Филиал ID] AS AdminTask_Branch_ID,
        a.[ЗадачаАдминистратораКредитов Филиал] AS AdminTask_Branch,
        a.[ЗадачаАдминистратораКредитов Категория Задачи ID] AS AdminTask_Category_ID,
        a.[ЗадачаАдминистратораКредитов Категория Задачи] AS AdminTask_Category,
        a.[ЗадачаАдминистратораКредитов Тип Задачи ID] AS AdminTask_Type_ID,
        a.[ЗадачаАдминистратораКредитов Тип Задачи] AS AdminTask_Type,
        a.[ЗадачаАдминистратораКредитов Описание Задачи] AS AdminTask_Description,
        a.[ЗадачаАдминистратораКредитов Задача Основание ID] AS AdminTask_Base_ID,
        a.[ЗадачаАдминистратораКредитов Источник Тип] AS AdminTask_Source_Type,
        a.[ЗадачаАдминистратораКредитов Источник Вид] AS AdminTask_Source_View,
        a.[ЗадачаАдминистратораКредитов Источник ID] AS AdminTask_Source_ID,
        a.[ЗадачаАдминистратораКредитов Клиент ID] AS AdminTask_Client_ID,
        a.[ЗадачаАдминистратораКредитов Клиент] AS AdminTask_Client,
        a.[ЗадачаАдминистратораКредитов Кредит ID] AS AdminTask_Credit_ID,
        a.[ЗадачаАдминистратораКредитов Кредит] AS AdminTask_Credit,
        a.[ЗадачаАдминистратораКредитов Лимит ID] AS AdminTask_Limit_ID,
        a.[ЗадачаАдминистратораКредитов Лимит] AS AdminTask_Limit,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Статус] AS AdminTask_CurrentStatus,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Статус ID] AS AdminTask_CurrentStatus_ID,
        a.[ЗадачаАдминистратораКредитов Дата Выполнения] AS AdminTask_CompletionDate,
        a.[ЗадачаАдминистратораКредитов Текущий Комментарий] AS AdminTask_CurrentComment,
        hist_tasktype.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей SLA] AS AdminTask_SLA,
        hist_tasktype.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей KPI] AS AdminTask_KPI,
        a.[ЗадачаАдминистратораКредитов Количество Задач] AS AdminTask_TaskCount,
        a.[ЗадачаАдминистратораКредитов Приоритет Задачи] AS AdminTask_Priority,
        a.[ЗадачаАдминистратораКредитов Приоритет Задачи ID] AS AdminTask_Priority_ID,
        a.[ЗадачаАдминистратораКредитов Исполнитель] AS AdminTask_Executor,

        t.[ТипыЗадачАдминистратораКредитов Пометка Удаления] AS TaskType_Deleted,
        t.[ТипыЗадачАдминистратораКредитов Родитель ID] AS TaskType_Parent_ID,
        t.[ТипыЗадачАдминистратораКредитов Это Группа] AS TaskType_IsGroup,
        t.[ТипыЗадачАдминистратораКредитов Код] AS TaskType_Code,
        t.[ТипыЗадачАдминистратораКредитов Наименование] AS TaskType_Name,
        t.[ТипыЗадачАдминистратораКредитов Реквизит Доп Упорядочивания] AS TaskType_Order,
        hist_tasktype.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей SLA] AS TaskType_SLA,
        hist_tasktype.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей KPI] AS TaskType_KPI,
        t.[ТипыЗадачАдминистратораКредитов Запрет Редактирования Количества Задач] AS TaskType_BlockEditCount,
        hist_tasktype.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей Максимальное Время Выполнения] AS TaskType_MaxTime,

        COALESCE(wait_hours.WaitHours, 0) AS WaitHours,
        COALESCE(total_hours.TotalHours, 0) AS TotalHours,
        COALESCE(in_progress.InProgress, 0) AS InProgress,

        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID] AS StatusHistory_ID,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Номер Строки] AS StatusHistory_RowNumber,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Статус] AS StatusHistory_Status,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Пользователь ID] AS StatusHistory_UserID,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Пользователь] AS StatusHistory_User,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Дата Начала] AS StatusHistory_StartDate,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Дата Окончания] AS StatusHistory_EndDate,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Комментарий] AS StatusHistory_Comment,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Время в Секундах] AS StatusHistory_Seconds,

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
        doc.[НаправлениеНаВыплату ID],
        doc.[НаправлениеНаВыплату Категория Риска AML],
        
        ROW_NUMBER() OVER(PARTITION BY a.[ЗадачаАдминистратораКредитов ID] ORDER BY sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Дата Окончания] DESC) AS rn

    FROM [ATK].[mis].[Bronze_Задачи.ЗадачаАдминистратораКредитов] a
    LEFT JOIN [ATK].[mis].[Bronze_Справочники.ТипыЗадачАдминистратораКредитов] t
        ON a.[ЗадачаАдминистратораКредитов Тип Задачи ID] = t.[ТипыЗадачАдминистратораКредитов ID]
    OUTER APPLY
    (
        SELECT *
        FROM [ATK].[mis].[Bronze_Задачи.ЗадачаАдминистратораКредитов.ИсторияСтатусов] s
        WHERE s.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID] = a.[ЗадачаАдминистратораКредитов ID]
    ) sh
    OUTER APPLY
    (
        SELECT SUM(CAST(s2.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Время в Секундах] AS FLOAT))/3600.0 AS TotalHours
        FROM [ATK].[mis].[Bronze_Задачи.ЗадачаАдминистратораКредитов.ИсторияСтатусов] s2
        WHERE s2.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID] = a.[ЗадачаАдминистратораКредитов ID]
    ) total_hours
    OUTER APPLY
    (
        SELECT SUM(CAST(s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Время в Секундах] AS FLOAT))/3600.0 AS WaitHours
        FROM [ATK].[mis].[Bronze_Задачи.ЗадачаАдминистратораКредитов.ИсторияСтатусов] s3
        WHERE s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID] = a.[ЗадачаАдминистратораКредитов ID]
          AND s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Статус] = N'ВОжидании'
    ) wait_hours
    OUTER APPLY
    (
        SELECT SUM(CAST(s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Время в Секундах] AS FLOAT))/3600.0 AS InProgress
        FROM [ATK].[mis].[Bronze_Задачи.ЗадачаАдминистратораКредитов.ИсторияСтатусов] s3
        WHERE s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID] = a.[ЗадачаАдминистратораКредитов ID]
          AND s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Статус] = N'ВРаботе'
    ) in_progress
    OUTER APPLY
    (
        SELECT TOP 1 *
        FROM [ATK].[mis].[Bronze_Справочники.ТипыЗадачАдминистратораКредитов_ИсторияПоказателей] hist
        WHERE hist.[ТипыЗадачАдминистратораКредитов ID] = t.[ТипыЗадачАдминистратораКредитов ID]
          AND hist.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей Дата Изменения] <= a.[ЗадачаАдминистратораКредитов Дата]
        ORDER BY hist.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей Дата Изменения] DESC
    ) hist_tasktype
    OUTER APPLY
    (
        SELECT TOP 1 *
        FROM [ATK].[mis].[Bronze_Документы.НаправлениеНаВыплату] d
        WHERE d.[НаправлениеНаВыплату Кредит ID] = a.[ЗадачаАдминистратораКредитов Кредит ID]
        ORDER BY d.[НаправлениеНаВыплату Дата] DESC
    ) doc
    OUTER APPLY
    (
        SELECT TOP 1 *
        FROM [ATK].[mis].[Bronze_РегистрыСведений.СведенияОНаправленияхНаВыплату] p
        WHERE p.[СведенияОНаправленияхНаВыплату Направление на Выплату ID] = doc.[НаправлениеНаВыплату ID]
    ) pay
)
INSERT INTO mis.[Gold_Fact_AdminTasks] (
    [AdminTask_ID], [AdminTask_Deleted], [AdminTask_Date], [AdminTask_Number], [AdminTask_Completed],
    [AdminTask_Author_ID], [AdminTask_Author], [AdminTask_Branch_ID], [AdminTask_Branch],
    [AdminTask_Category_ID], [AdminTask_Category], [AdminTask_Type_ID], [AdminTask_Type],
    [AdminTask_Description], [AdminTask_Base_ID], [AdminTask_Source_Type], [AdminTask_Source_View],
    [AdminTask_Source_ID], [AdminTask_Client_ID], [AdminTask_Client], [AdminTask_Credit_ID], [AdminTask_Credit],
    [AdminTask_Limit_ID], [AdminTask_Limit], [AdminTask_CurrentStatus], [AdminTask_CurrentStatus_ID],
    [AdminTask_CompletionDate], [AdminTask_CurrentComment], [AdminTask_SLA], [AdminTask_KPI],
    [AdminTask_TaskCount], [AdminTask_Priority], [AdminTask_Priority_ID], [AdminTask_Executor],
    [TaskType_Deleted], [TaskType_Parent_ID], [TaskType_IsGroup], [TaskType_Code], [TaskType_Name],
    [TaskType_Order], [TaskType_SLA], [TaskType_KPI], [TaskType_BlockEditCount], [TaskType_MaxTime],
    [WaitHours], [TotalHours], [InProgress],
    [StatusHistory_ID], [StatusHistory_RowNumber], [StatusHistory_Status], [StatusHistory_UserID],
    [StatusHistory_User], [StatusHistory_StartDate], [StatusHistory_EndDate], [StatusHistory_Comment],
    [StatusHistory_Seconds],
    [СведенияОНаправленияхНаВыплату Направление на Выплату ID], [СведенияОНаправленияхНаВыплату Направление на Выплату],
    [СведенияОНаправленияхНаВыплату SLA], [СведенияОНаправленияхНаВыплату Максимальное Время Выполнения],
    [СведенияОНаправленияхНаВыплату Дата Создания], [СведенияОНаправленияхНаВыплату Дата Взятия в Работу],
    [СведенияОНаправленияхНаВыплату Дата Утверждения], [СведенияОНаправленияхНаВыплату Дата Пометки Удаления],
    [СведенияОНаправленияхНаВыплату Тип Направления на Выплату ID], [СведенияОНаправленияхНаВыплату Тип Направления на Выплату],
    [НаправлениеНаВыплату ID], [НаправлениеНаВыплату Категория Риска AML]
)
SELECT
    AdminTask_ID, AdminTask_Deleted, AdminTask_Date, AdminTask_Number, AdminTask_Completed,
    AdminTask_Author_ID, AdminTask_Author, AdminTask_Branch_ID, AdminTask_Branch,
    AdminTask_Category_ID, AdminTask_Category, AdminTask_Type_ID, AdminTask_Type,
    AdminTask_Description, AdminTask_Base_ID, AdminTask_Source_Type, AdminTask_Source_View,
    AdminTask_Source_ID, AdminTask_Client_ID, AdminTask_Client, AdminTask_Credit_ID, AdminTask_Credit,
    AdminTask_Limit_ID, AdminTask_Limit, AdminTask_CurrentStatus, AdminTask_CurrentStatus_ID,
    AdminTask_CompletionDate, AdminTask_CurrentComment, AdminTask_SLA, AdminTask_KPI,
    AdminTask_TaskCount, AdminTask_Priority, AdminTask_Priority_ID, AdminTask_Executor,
    TaskType_Deleted, TaskType_Parent_ID, TaskType_IsGroup, TaskType_Code, TaskType_Name,
    TaskType_Order, TaskType_SLA, TaskType_KPI, TaskType_BlockEditCount, TaskType_MaxTime,
    WaitHours, TotalHours, InProgress,
    StatusHistory_ID, StatusHistory_RowNumber, StatusHistory_Status, StatusHistory_UserID,
    StatusHistory_User, StatusHistory_StartDate, StatusHistory_EndDate, StatusHistory_Comment,
    StatusHistory_Seconds,
    [СведенияОНаправленияхНаВыплату Направление на Выплату ID], [СведенияОНаправленияхНаВыплату Направление на Выплату],
    [СведенияОНаправленияхНаВыплату SLA], [СведенияОНаправленияхНаВыплату Максимальное Время Выполнения],
    [СведенияОНаправленияхНаВыплату Дата Создания], [СведенияОНаправленияхНаВыплату Дата Взятия в Работу],
    [СведенияОНаправленияхНаВыплату Дата Утверждения], [СведенияОНаправленияхНаВыплату Дата Пометки Удаления],
    [СведенияОНаправленияхНаВыплату Тип Направления на Выплату ID], [СведенияОНаправленияхНаВыплату Тип Направления на Выплату],
    [НаправлениеНаВыплату ID], [НаправлениеНаВыплату Категория Риска AML]
FROM AllTasks
WHERE rn = 1;
