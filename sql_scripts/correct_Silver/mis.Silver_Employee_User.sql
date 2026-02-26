USE [ATK];
GO

IF OBJECT_ID('mis.[Silver_Employee_User]', 'U') IS NOT NULL
    DROP TABLE mis.[Silver_Employee_User];
GO


CREATE TABLE mis.[Silver_Employee_User]
(
    [SalaryPeriod]        DATETIME      NULL,
    [EmployeeID]          VARCHAR(36)   NULL,
    [PositionName]        NVARCHAR(100) NULL,
    [PositionID]          VARCHAR(36)   NULL,
    [BranchName]          NVARCHAR(100) NULL,

    [UserID]              VARCHAR(36)   NULL,
    [IsDeleted]           VARCHAR(36)   NULL,
    [UserName]            NVARCHAR(100) NULL,
    [Primary_EmployeeGroup] NVARCHAR(256) NULL,
    [Employee_UserID]     VARCHAR(36)   NULL,
    [EmployeeName]        NVARCHAR(40)  NULL,
    [CashDeskID]          VARCHAR(36)   NULL,
    [CashDeskName]        NVARCHAR(50)  NULL,
    [IsConnected]         INT           NULL,
    [IsDisabled]          INT           NULL,
    [MI_RepresentativeID] VARCHAR(36)   NULL,
    [MI_RepresentativeName] NVARCHAR(55) NULL,
    [IsInvalid]           VARCHAR(36)   NULL,
    [DepartmentName]      NVARCHAR(10)  NULL,
    [PersonName]          NVARCHAR(10)  NULL,
    [IsSys_User]          VARCHAR(36)   NULL,
    [IsPrepared]          VARCHAR(36)   NULL,
    [IB_ID]               VARCHAR(36)   NULL,
    [ServiceID]           VARCHAR(36)   NULL,
    [IB_Properties]       VARCHAR(36)   NULL,
    [DebtRemind]          VARCHAR(36)   NULL,
    [ClientID]            VARCHAR(36)   NULL
);
GO


INSERT INTO mis.[Silver_Employee_User]
SELECT 

    a.[СотрудникиДанныеПоЗарплате Период]        AS SalaryPeriod,
    a.[СотрудникиДанныеПоЗарплате Сотрудник ID] AS EmployeeID,
    a.[СотрудникиДанныеПоЗарплате Должность]    AS PositionName,
    a.[СотрудникиДанныеПоЗарплате Должность ID] AS PositionID,
    a.[СотрудникиДанныеПоЗарплате Филиал]       AS BranchName,

    -- Users
    u.[Пользователи ID]                           AS UserID,
    u.[Пользователи Пометка Удаления]            AS IsDeleted,
    u.[Пользователи Наименование]                AS UserName,
    u.[Пользователи Основная Группа Сотрудников] AS Primary_EmployeeGroup,
    u.[Пользователи Сотрудник ID]                AS Employee_UserID,
    u.[Пользователи Сотрудник]                   AS EmployeeName,
    u.[Пользователи Касса ID]                    AS CashDeskID,
    u.[Пользователи Касса]                       AS CashDeskName,
    u.[Пользователи Подключен]                   AS IsConnected,
    u.[Пользователи Отключить]                   AS IsDisabled,
    u.[Пользователи Представитель MI ID]         AS MI_RepresentativeID,
    u.[Пользователи Представитель MI]            AS MI_RepresentativeName,
    u.[Пользователи Недействителен]              AS IsInvalid,
    u.[Пользователи Подразделение]               AS DepartmentName,
    u.[Пользователи Физическое Лицо]             AS PersonName,
    u.[Пользователи Служебный]                   AS IsSys_User,
    u.[Пользователи Подготовлен]                 AS IsPrepared,
    u.[Пользователи Идентификатор Пользователя ИБ]    AS IB_ID,
    u.[Пользователи Идентификатор Пользователя Сервиса] AS ServiceID,
    u.[Пользователи Свойства Пользователя ИБ]         AS IB_Properties,
    u.[Пользователи Напоминать о Задолженности Поставщики] AS DebtRemind,
    u.[Пользователи Контрагент ID]                    AS ClientID
FROM [ATK].[mis].[Bronze_РегистрыСведений.СотрудникиДанныеПоЗарплате] a
LEFT JOIN [ATK].[dbo].[Справочники.Пользователи] u
    ON u.[Пользователи Сотрудник ID] = a.[СотрудникиДанныеПоЗарплате Сотрудник ID]
WHERE u.[Пользователи Пометка Удаления] <> '01';
