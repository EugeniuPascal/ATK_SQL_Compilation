USE [ATK];
GO

-- Drop table if exists
IF OBJECT_ID('mis.[2tbl_Gold_Fact_AdminTasks]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Fact_AdminTasks];
GO

-- Create table
CREATE TABLE mis.[2tbl_Gold_Fact_AdminTasks]
(
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

    [WaitHours] DECIMAL(18,2) NULL,
    [TotalHours] DECIMAL(18,2) NULL,

    [StatusHistory_ID] VARCHAR(36) NULL,
    [StatusHistory_RowNumber] INT NULL,
    [StatusHistory_Status] NVARCHAR(256) NULL,
    [StatusHistory_UserID] VARCHAR(36) NULL,
    [StatusHistory_User] NVARCHAR(150) NULL,
    [StatusHistory_StartDate] DATETIME NULL,
    [StatusHistory_EndDate] DATETIME NULL,
    [StatusHistory_Comment] NVARCHAR(1000) NULL,
    [StatusHistory_Seconds] INT NULL,

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

-- Populate Gold table without duplicates, preferring rows with НаправлениеSLA
WITH AdminTasksWithRowNum AS
(
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
        t.[ТипыЗадачАдминистратораКредитов Запрет Редактирования Количества Задач] AS TaskType_BlockEditCount,
        hist_tasktype.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей Максимальное Время Выполнения] AS TaskType_MaxTime,

        COALESCE(wait_hours.WaitHours, 0) AS WaitHours,
        COALESCE(total_hours.TotalHours, 0) AS TotalHours,

        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID] AS StatusHistory_ID,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Номер Строки] AS StatusHistory_RowNumber,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Статус] AS StatusHistory_Status,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Пользователь ID] AS StatusHistory_UserID,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Пользователь] AS StatusHistory_User,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Дата Начала] AS StatusHistory_StartDate,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Дата Окончания] AS StatusHistory_EndDate,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Комментарий] AS StatusHistory_Comment,
        sh.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Время в Секундах] AS StatusHistory_Seconds,

        pay.[СведенияОНаправленияхНаВыплату Направление на Выплату ID] AS НаправлениеSLA_ID,
        pay.[СведенияОНаправленияхНаВыплату Направление на Выплату] AS НаправлениеSLA_Name,
        pay.[СведенияОНаправленияхНаВыплату SLA] AS НаправлениеSLA_SLA,
        pay.[СведенияОНаправленияхНаВыплату Максимальное Время Выполнения] AS НаправлениеSLA_MaxTime,
        pay.[СведенияОНаправленияхНаВыплату Дата Создания] AS НаправлениеSLA_CreateDate,
        pay.[СведенияОНаправленияхНаВыплату Дата Взятия в Работу] AS НаправлениеSLA_WorkDate,
        pay.[СведенияОНаправленияхНаВыплату Дата Утверждения] AS НаправлениеSLA_ApprovalDate,
        pay.[СведенияОНаправленияхНаВыплату Дата Пометки Удаления] AS НаправлениеSLA_DeletedDate,
        pay.[СведенияОНаправленияхНаВыплату Тип Направления на Выплату ID] AS НаправлениеSLA_TypeID,
        pay.[СведенияОНаправленияхНаВыплату Тип Направления на Выплату] AS НаправлениеSLA_TypeName,
        doc.[НаправлениеНаВыплату ID] AS НаправлениеDoc_ID,

        ROW_NUMBER() OVER (
            PARTITION BY a.[ЗадачаАдминистратораКредитов ID]
            ORDER BY CASE WHEN pay.[СведенияОНаправленияхНаВыплату Направление на Выплату ID] IS NOT NULL THEN 0 ELSE 1 END
        ) AS rn

    FROM [ATK].[mis].[Silver_Задачи.ЗадачаАдминистратораКредитов] a
    LEFT JOIN [ATK].[mis].[Silver_Справочники.ТипыЗадачАдминистратораКредитов] t
        ON a.[ЗадачаАдминистратораКредитов Тип Задачи ID] = t.[ТипыЗадачАдминистратораКредитов ID]
    OUTER APPLY (
        SELECT TOP 1 *
        FROM [ATK].[mis].[Silver_Задачи.ЗадачаАдминистратораКредитов.ИсторияСтатусов] s
        WHERE s.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID] = a.[ЗадачаАдминистратораКредитов ID]
        ORDER BY s.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Номер Строки] DESC
    ) sh
    OUTER APPLY (
        SELECT SUM(CAST(s2.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Время в Секундах] AS FLOAT))/3600.0 AS TotalHours
        FROM [ATK].[mis].[Silver_Задачи.ЗадачаАдминистратораКредитов.ИсторияСтатусов] s2
        WHERE s2.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID] = a.[ЗадачаАдминистратораКредитов ID]
    ) total_hours
    OUTER APPLY (
        SELECT SUM(CAST(s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Время в Секундах] AS FLOAT))/3600.0 AS WaitHours
        FROM [ATK].[mis].[Silver_Задачи.ЗадачаАдминистратораКредитов.ИсторияСтатусов] s3
        WHERE s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID] = a.[ЗадачаАдминистратораКредитов ID]
          AND s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов Статус] = N'ВОжидании'
    ) wait_hours
    OUTER APPLY (
        SELECT TOP 1 *
        FROM [ATK].[dbo].[Справочники.ТипыЗадачАдминистратораКредитов_ИсторияПоказателей] hist
        WHERE hist.[ТипыЗадачАдминистратораКредитов ID] = t.[ТипыЗадачАдминистратораКредитов ID]
          AND hist.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей Дата Изменения] <= a.[ЗадачаАдминистратораКредитов Дата]
        ORDER BY hist.[ТипыЗадачАдминистратораКредитов_ИсторияПоказателей Дата Изменения] DESC
    ) hist_tasktype
    LEFT JOIN [ATK].[dbo].[Документы.НаправлениеНаВыплату] AS doc
        ON doc.[НаправлениеНаВыплату Кредит ID] = a.[ЗадачаАдминистратораКредитов Кредит ID]
    LEFT JOIN [ATK].[dbo].[РегистрыСведений.СведенияОНаправленияхНаВыплату] AS pay
        ON pay.[СведенияОНаправленияхНаВыплату Направление на Выплату ID] = doc.[НаправлениеНаВыплату ID]
)
INSERT INTO mis.[2tbl_Gold_Fact_AdminTasks] (
    [AdminTask_ID],[AdminTask_Deleted],[AdminTask_Date],[AdminTask_Number],
    [AdminTask_Completed],[AdminTask_Author_ID],[AdminTask_Author],[AdminTask_Branch_ID],
    [AdminTask_Branch],[AdminTask_Category_ID],[AdminTask_Category],[AdminTask_Type_ID],
    [AdminTask_Type],[AdminTask_Description],[AdminTask_Base_ID],[AdminTask_Source_Type],
    [AdminTask_Source_View],[AdminTask_Source_ID],[AdminTask_Client_ID],[AdminTask_Client],
    [AdminTask_Credit_ID],[AdminTask_Credit],[AdminTask_Limit_ID],[AdminTask_Limit],
    [AdminTask_CurrentStatus],[AdminTask_CurrentStatus_ID],[AdminTask_CompletionDate],[AdminTask_CurrentComment],
    [AdminTask_SLA],[AdminTask_KPI],[AdminTask_TaskCount],[AdminTask_Priority],
    [AdminTask_Priority_ID],[AdminTask_Executor],[TaskType_Deleted],[TaskType_Parent_ID],
    [TaskType_IsGroup],[TaskType_Code],[TaskType_Name],[TaskType_Order],
    [TaskType_BlockEditCount],[TaskType_MaxTime],
    [WaitHours],[TotalHours],[StatusHistory_ID],[StatusHistory_RowNumber],
    [StatusHistory_Status],[StatusHistory_UserID],[StatusHistory_User],[StatusHistory_StartDate],
    [StatusHistory_EndDate],[StatusHistory_Comment],[StatusHistory_Seconds],
    [НаправлениеSLA_ID],[НаправлениеSLA_Name],[НаправлениеSLA_SLA],[НаправлениеSLA_MaxTime],
    [НаправлениеSLA_CreateDate],[НаправлениеSLA_WorkDate],[НаправлениеSLA_ApprovalDate],[НаправлениеSLA_DeletedDate],
    [НаправлениеSLA_TypeID],[НаправлениеSLA_TypeName],[НаправлениеDoc_ID]
)
SELECT
    [AdminTask_ID],[AdminTask_Deleted],[AdminTask_Date],[AdminTask_Number],
    [AdminTask_Completed],[AdminTask_Author_ID],[AdminTask_Author],[AdminTask_Branch_ID],
    [AdminTask_Branch],[AdminTask_Category_ID],[AdminTask_Category],[AdminTask_Type_ID],
    [AdminTask_Type],[AdminTask_Description],[AdminTask_Base_ID],[AdminTask_Source_Type],
    [AdminTask_Source_View],[AdminTask_Source_ID],[AdminTask_Client_ID],[AdminTask_Client],
    [AdminTask_Credit_ID],[AdminTask_Credit],[AdminTask_Limit_ID],[AdminTask_Limit],
    [AdminTask_CurrentStatus],[AdminTask_CurrentStatus_ID],[AdminTask_CompletionDate],[AdminTask_CurrentComment],
    [AdminTask_SLA],[AdminTask_KPI],[AdminTask_TaskCount],[AdminTask_Priority],
    [AdminTask_Priority_ID],[AdminTask_Executor],[TaskType_Deleted],[TaskType_Parent_ID],
    [TaskType_IsGroup],[TaskType_Code],[TaskType_Name],[TaskType_Order],
    [TaskType_BlockEditCount],[TaskType_MaxTime],
    [WaitHours],[TotalHours],[StatusHistory_ID],[StatusHistory_RowNumber],
    [StatusHistory_Status],[StatusHistory_UserID],[StatusHistory_User],[StatusHistory_StartDate],
    [StatusHistory_EndDate],[StatusHistory_Comment],[StatusHistory_Seconds],
    [НаправлениеSLA_ID],[НаправлениеSLA_Name],[НаправлениеSLA_SLA],[НаправлениеSLA_MaxTime],
    [НаправлениеSLA_CreateDate],[НаправлениеSLA_WorkDate],[НаправлениеSLA_ApprovalDate],[НаправлениеSLA_DeletedDate],
    [НаправлениеSLA_TypeID],[НаправлениеSLA_TypeName],[НаправлениеDoc_ID]
FROM AdminTasksWithRowNum
WHERE rn = 1;
GO
