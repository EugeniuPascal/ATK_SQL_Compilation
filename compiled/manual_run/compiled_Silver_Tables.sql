-- Compiled SQL bundle (Silver) with Logging (Dynamic Execution)
-- Generated: 2026-02-26 10:59:43
-- Source folder: C:\ATK_Project\sql_scripts\Silver
-- Files (5):
--   mis.Silver_Employee_User.sql
--   mis.Silver_CommiteeProtocol.sql
--   mis.Silver_Restruct_SCD.sql
--   mis.Silver_RestructState_SCD.sql
--   mis.Silver_Restruct_Merged_SCD.sql
----------------------------------------------------------------------------------------------------

SET NOCOUNT ON;

DECLARE @StartTime DATETIME;
DECLARE @EndTime DATETIME;
DECLARE @Status NVARCHAR(50);
DECLARE @sql NVARCHAR(MAX);

DECLARE @FailureNote NVARCHAR(MAX);

----------------------------------------------------------------------------------------------------
-- Start of: mis.Silver_Employee_User.sql
----------------------------------------------------------------------------------------------------
BEGIN
    SET @StartTime = GETDATE();
    SET @Status = 'Running';

    BEGIN TRY
        SET @FailureNote = '';
        SET @sql = N'USE [ATK];

IF OBJECT_ID(''mis.[Silver_Employee_User]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Silver_Employee_User];

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
WHERE u.[Пользователи Пометка Удаления] <> ''01'';
';
        EXEC sys.sp_executesql @sql;
        SET @Status = 'Success';
    END TRY
    BEGIN CATCH
        SET @Status = 'Failed';
        SET @FailureNote = CONCAT(
            'Msg: ', ERROR_MESSAGE(),
            ' | Line: ', ERROR_LINE(),
            ' | Number: ', ERROR_NUMBER()
        );
    END CATCH;

    SET @EndTime = GETDATE();
    INSERT INTO mis.Silver_Proc_Exec_Log (TableName, StartTime, EndTime, Status, Failure_Note)
    VALUES ('mis.Silver_Employee_User', @StartTime, @EndTime, @Status, @FailureNote);
END

----------------------------------------------------------------------------------------------------
-- End of: mis.Silver_Employee_User.sql
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Start of: mis.Silver_CommiteeProtocol.sql
----------------------------------------------------------------------------------------------------
BEGIN
    SET @StartTime = GETDATE();
    SET @Status = 'Running';

    BEGIN TRY
        SET @FailureNote = '';
        SET @sql = N'USE [ATK];

IF OBJECT_ID(''mis.[Silver_CommiteeProtocol]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Silver_CommiteeProtocol];

CREATE TABLE mis.[Silver_CommiteeProtocol]
(
    [ПротоколКомитета Дата]                DATETIME NULL,
	[ПротоколКомитета Дата Решения]        DATETIME NULL,
	[ПротоколКомитета Кредит ID]           VARCHAR(36) NOT NULL,
    [ПротоколКомитета ID]	               VARCHAR(36) NOT NULL,
	[ПротоколКомитета Заявка ID]           VARCHAR(36) NOT NULL,
    [ПротоколКомитета Сумма на Выдачу]	   DECIMAL(15, 2) NULL,
	[ПротоколКомитета Сумма Рефинансирования Кредита] DECIMAL(15, 2) NULL,
	[ПротоколКомитета Назначение Использования Кредита] NVARCHAR(150) NULL,
	[ПротоколКомитета Категория Риска AML]  NVARCHAR(256) NULL,
	[] VARCHAR(36) NOT NULL,
	[ПротоколКомитета Комитет]            NVARCHAR(156) NULL,
	[ПротоколКомитета Партнер]  NVARCHAR(256) NULL
	
);

INSERT INTO mis.[Silver_CommiteeProtocol] 
(
    [ПротоколКомитета Дата],
	[ПротоколКомитета Дата Решения],
	[ПротоколКомитета Кредит ID], 
	[ПротоколКомитета ID],
	[ПротоколКомитета Заявка ID],
    [ПротоколКомитета Сумма на Выдачу],
	[ПротоколКомитета Сумма Рефинансирования Кредита],
	[ПротоколКомитета Назначение Использования Кредита],
	[ПротоколКомитета Категория Риска AML],
	[ПротоколКомитета Это Зеленый Кредит],
	[ПротоколКомитета Комитет],
	[ПротоколКомитета Партнер]
)
SELECT
    [ПротоколКомитета Дата],
	[ПротоколКомитета Дата Решения],
	[ПротоколКомитета Кредит ID], 
	[ПротоколКомитета ID],
	[ПротоколКомитета Заявка ID],
    [ПротоколКомитета Сумма на Выдачу],
	[ПротоколКомитета Сумма Рефинансирования Кредита],
	[ПротоколКомитета Назначение Использования Кредита],
	[ПротоколКомитета Категория Риска AML],
	[ПротоколКомитета Это Зеленый Кредит],
	[ПротоколКомитета Комитет],
	[ПротоколКомитета Партнер]
	
FROM [ATK].[mis].[Bronze_Документы.ПротоколКомитета];';
        EXEC sys.sp_executesql @sql;
        SET @Status = 'Success';
    END TRY
    BEGIN CATCH
        SET @Status = 'Failed';
        SET @FailureNote = CONCAT(
            'Msg: ', ERROR_MESSAGE(),
            ' | Line: ', ERROR_LINE(),
            ' | Number: ', ERROR_NUMBER()
        );
    END CATCH;

    SET @EndTime = GETDATE();
    INSERT INTO mis.Silver_Proc_Exec_Log (TableName, StartTime, EndTime, Status, Failure_Note)
    VALUES ('mis.Silver_CommiteeProtocol', @StartTime, @EndTime, @Status, @FailureNote);
END

----------------------------------------------------------------------------------------------------
-- End of: mis.Silver_CommiteeProtocol.sql
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Start of: mis.Silver_Restruct_SCD.sql
----------------------------------------------------------------------------------------------------
BEGIN
    SET @StartTime = GETDATE();
    SET @Status = 'Running';

    BEGIN TRY
        SET @FailureNote = '';
        SET @sql = N'USE ATK;

SET NOCOUNT ON;

IF OBJECT_ID(''mis.Silver_Restruct_SCD'',''U'') IS NULL
BEGIN
    CREATE TABLE mis.Silver_Restruct_SCD 
	(
        CreditID        VARCHAR(36)   NOT NULL,
        ValidFrom       DATE          NOT NULL,
        ValidTo         DATE          NOT NULL,
        TypeName        NVARCHAR(200) NULL,
        Reason          NVARCHAR(500) NULL,
        NonCommSeenUpTo BIT           NOT NULL,
        CONSTRAINT PK_Silver_Restruct_SCD PRIMARY KEY (CreditID, ValidFrom)
    );
END
ELSE
BEGIN
    TRUNCATE TABLE mis.Silver_Restruct_SCD;
END

;WITH src AS (
    SELECT
        r.[РеструктурированныеКредиты Кредит ID] AS CreditID,
        CAST(r.[РеструктурированныеКредиты Период] AS DATE) AS PeriodDate,
        r.[РеструктурированныеКредиты Тип Реструктуризации Долга] AS TypeName,
        r.[РеструктурированныеКредиты Причина Реструктуризации] AS Reason,
        ROW_NUMBER() OVER (
            PARTITION BY
                r.[РеструктурированныеКредиты Кредит ID],
                CAST(r.[РеструктурированныеКредиты Период] AS DATE)
            ORDER BY r.[РеструктурированныеКредиты Период] DESC
        ) AS rn
    FROM mis.[Bronze_РегистрыСведений.РеструктурированныеКредиты] r
),
dedup AS (
    SELECT CreditID, PeriodDate, TypeName, Reason
    FROM src
    WHERE rn = 1
),
rng AS (
    SELECT
        CreditID,
        PeriodDate AS ValidFrom,
        LEAD(PeriodDate) OVER (PARTITION BY CreditID ORDER BY PeriodDate) AS NextFrom,
        TypeName,
        Reason,
        MAX(CASE WHEN TypeName = N''НекоммерческаяРеструктуризация'' THEN 1 ELSE 0 END)
            OVER (PARTITION BY CreditID ORDER BY PeriodDate
                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS NonCommSeenUpTo
    FROM dedup
)
INSERT INTO mis.Silver_Restruct_SCD
    (CreditID, ValidFrom, ValidTo, TypeName, Reason, NonCommSeenUpTo)
SELECT
    CreditID,
    ValidFrom,
    COALESCE(DATEADD(day,-1, NextFrom), CONVERT(DATE,''9999-12-31'')) AS ValidTo,
    TypeName,
    Reason,
    NonCommSeenUpTo
FROM rng;
';
        EXEC sys.sp_executesql @sql;
        SET @Status = 'Success';
    END TRY
    BEGIN CATCH
        SET @Status = 'Failed';
        SET @FailureNote = CONCAT(
            'Msg: ', ERROR_MESSAGE(),
            ' | Line: ', ERROR_LINE(),
            ' | Number: ', ERROR_NUMBER()
        );
    END CATCH;

    SET @EndTime = GETDATE();
    INSERT INTO mis.Silver_Proc_Exec_Log (TableName, StartTime, EndTime, Status, Failure_Note)
    VALUES ('mis.Silver_Restruct_SCD', @StartTime, @EndTime, @Status, @FailureNote);
END

----------------------------------------------------------------------------------------------------
-- End of: mis.Silver_Restruct_SCD.sql
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Start of: mis.Silver_RestructState_SCD.sql
----------------------------------------------------------------------------------------------------
BEGIN
    SET @StartTime = GETDATE();
    SET @Status = 'Running';

    BEGIN TRY
        SET @FailureNote = '';
        SET @sql = N'USE ATK;

SET NOCOUNT ON;

IF OBJECT_ID(''mis.Silver_RestructState_SCD'',''U'') IS NULL
BEGIN
    CREATE TABLE mis.Silver_RestructState_SCD 
	(
        CreditID   VARCHAR(36)   NOT NULL,
        ValidFrom  DATE          NOT NULL,
        ValidTo    DATE          NOT NULL,
        StateName  NVARCHAR(50)  NULL,
        CONSTRAINT PK_Silver_RestructState_SCD PRIMARY KEY (CreditID, ValidFrom)
    );
END
ELSE
BEGIN
    TRUNCATE TABLE mis.Silver_RestructState_SCD;
END

;WITH src AS (
    SELECT
        s.[СостоянияРеструктурированныхКредитов Кредит ID] AS CreditID,
        CAST(s.[СостоянияРеструктурированныхКредитов Период] AS DATE) AS PeriodDate,
        s.[СостоянияРеструктурированныхКредитов Состояние Реструктурированного Кредита] AS StateName,
        ROW_NUMBER() OVER (
            PARTITION BY
                s.[СостоянияРеструктурированныхКредитов Кредит ID],
                CAST(s.[СостоянияРеструктурированныхКредитов Период] AS DATE)
            ORDER BY s.[СостоянияРеструктурированныхКредитов Период] DESC
        ) AS rn
    FROM mis.[Bronze_РегистрыСведений.СостоянияРеструктурированныхКредитов] s
),
dedup AS (
    SELECT CreditID, PeriodDate, StateName
    FROM src
    WHERE rn = 1
),
rng AS (
    SELECT
        CreditID,
        PeriodDate AS ValidFrom,
        LEAD(PeriodDate) OVER (PARTITION BY CreditID ORDER BY PeriodDate) AS NextFrom,
        StateName
    FROM dedup
)

SELECT
    CreditID,
    ValidFrom,
    COALESCE(DATEADD(day,-1, NextFrom), CONVERT(DATE,''9999-12-31'')) AS ValidTo,
    StateName
FROM rng;
';
        EXEC sys.sp_executesql @sql;
        SET @Status = 'Success';
    END TRY
    BEGIN CATCH
        SET @Status = 'Failed';
        SET @FailureNote = CONCAT(
            'Msg: ', ERROR_MESSAGE(),
            ' | Line: ', ERROR_LINE(),
            ' | Number: ', ERROR_NUMBER()
        );
    END CATCH;

    SET @EndTime = GETDATE();
    INSERT INTO mis.Silver_Proc_Exec_Log (TableName, StartTime, EndTime, Status, Failure_Note)
    VALUES ('mis.Silver_RestructState_SCD', @StartTime, @EndTime, @Status, @FailureNote);
END

----------------------------------------------------------------------------------------------------
-- End of: mis.Silver_RestructState_SCD.sql
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Start of: mis.Silver_Restruct_Merged_SCD.sql
----------------------------------------------------------------------------------------------------
BEGIN
    SET @StartTime = GETDATE();
    SET @Status = 'Running';

    BEGIN TRY
        SET @FailureNote = '';
        SET @sql = N'USE ATK;

SET NOCOUNT ON;

------------------------------------------------------------
-- 0) Ensure table exists
------------------------------------------------------------
IF OBJECT_ID(''mis.Silver_Restruct_Merged_SCD'',''U'') IS NULL
BEGIN
    CREATE TABLE mis.Silver_Restruct_Merged_SCD 
    (
        CreditID        VARCHAR(36)   NOT NULL,
        ValidFrom       DATE          NOT NULL,
        ValidTo         DATE          NOT NULL,
        TypeName        NVARCHAR(200) NULL,
        Reason          NVARCHAR(500) NULL,
        StateName       NVARCHAR(200) NULL,
        TypeName_Sticky NVARCHAR(200) NULL,
        CreditStatus    NVARCHAR(200) NULL,
        ClientID        VARCHAR(36)   NULL,
        CONSTRAINT PK_Silver_Restruct_Merged_SCD PRIMARY KEY (CreditID, ValidFrom)
    );
END
ELSE
BEGIN
    TRUNCATE TABLE mis.Silver_Restruct_Merged_SCD;
END;
------------------------------------------------------------
-- 1) Build SCD intervals
------------------------------------------------------------
;WITH borders AS (
    SELECT CreditID, CAST(ValidFrom AS DATE) AS ValidFrom
    FROM   mis.Silver_Restruct_SCD
    UNION
    SELECT CreditID, CAST(ValidFrom AS DATE) AS ValidFrom
    FROM   mis.Silver_RestructState_SCD
    UNION
    SELECT
        s.[СтатусыКредитовВыданных Кредит ID] AS CreditID,
        CAST(s.[СтатусыКредитовВыданных Период] AS DATE) AS ValidFrom
    FROM mis.[Bronze_РегистрыСведений.СтатусыКредитовВыданных] s
    WHERE s.[СтатусыКредитовВыданных Активность] = 1
),
grid AS (
    SELECT CreditID, ValidFrom,
           LEAD(ValidFrom) OVER (PARTITION BY CreditID ORDER BY ValidFrom) AS NextFrom
    FROM borders
),
slices AS (
    SELECT CreditID, ValidFrom,
           COALESCE(DATEADD(day,-1, NextFrom), CONVERT(DATE,''9999-12-31'')) AS ValidTo
    FROM grid
),
joined AS (
    SELECT z.CreditID, z.ValidFrom, z.ValidTo,
           r.TypeName, r.Reason, r.NonCommSeenUpTo,
           s.StateName,
           cs.[СтатусыКредитовВыданных Статус] AS CreditStatus,
           COALESCE(r.NonCommSeenUpTo,0) AS SeenNcHere
    FROM slices z
    OUTER APPLY (
        SELECT TOP (1) rr.TypeName, rr.Reason, rr.NonCommSeenUpTo
        FROM mis.Silver_Restruct_SCD rr
        WHERE rr.CreditID = z.CreditID
          AND rr.ValidFrom <= z.ValidFrom
          AND rr.ValidTo   >= z.ValidFrom
        ORDER BY rr.ValidFrom DESC
    ) r
    OUTER APPLY (
        SELECT TOP (1) ss.StateName
        FROM mis.Silver_RestructState_SCD ss
        WHERE ss.CreditID = z.CreditID
          AND ss.ValidFrom <= z.ValidFrom
          AND ss.ValidTo   >= z.ValidFrom
        ORDER BY ss.ValidFrom DESC
    ) s
    OUTER APPLY (
        SELECT TOP (1) s2.[СтатусыКредитовВыданных Статус]
        FROM mis.[Bronze_РегистрыСведений.СтатусыКредитовВыданных] s2
        WHERE s2.[СтатусыКредитовВыданных Кредит ID] = z.CreditID
          AND s2.[СтатусыКредитовВыданных Активность] = 1
          AND CAST(s2.[СтатусыКредитовВыданных Период] AS DATE) <= z.ValidFrom
        ORDER BY s2.[СтатусыКредитовВыданных Период] DESC
    ) cs
),
stick AS (
    SELECT j.*,
           MAX(j.SeenNcHere) OVER 
		   (PARTITION BY j.CreditID 
		   ORDER BY j.ValidFrom
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
		   ) AS SeenNcCumulative
    FROM joined j
)
INSERT INTO mis.Silver_Restruct_Merged_SCD
    (CreditID, ValidFrom, ValidTo, TypeName, Reason, StateName, TypeName_Sticky, CreditStatus, ClientID)
SELECT st.CreditID, st.ValidFrom, st.ValidTo,
       st.TypeName, st.Reason, 
	   st.StateName,
       CASE WHEN st.SeenNcCumulative = 1 THEN N''НекоммерческаяРеструктуризация''
            ELSE st.TypeName END AS TypeName_Sticky,
       st.CreditStatus,
       cr.[Кредиты Владелец] AS ClientID
FROM stick st
LEFT JOIN mis.[Bronze_Справочники.Кредиты] cr
       ON cr.[Кредиты ID] = st.CreditID;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(''mis.Silver_Restruct_Merged_SCD'')
      AND name = ''IX_Merged_ForIntervals'')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Merged_ForIntervals
        ON mis.Silver_Restruct_Merged_SCD (CreditID, ValidFrom)
        INCLUDE (ValidTo, StateName, TypeName, Reason, CreditStatus, TypeName_Sticky, ClientID);
END;
';
        EXEC sys.sp_executesql @sql;
        SET @Status = 'Success';
    END TRY
    BEGIN CATCH
        SET @Status = 'Failed';
        SET @FailureNote = CONCAT(
            'Msg: ', ERROR_MESSAGE(),
            ' | Line: ', ERROR_LINE(),
            ' | Number: ', ERROR_NUMBER()
        );
    END CATCH;

    SET @EndTime = GETDATE();
    INSERT INTO mis.Silver_Proc_Exec_Log (TableName, StartTime, EndTime, Status, Failure_Note)
    VALUES ('mis.Silver_Restruct_Merged_SCD', @StartTime, @EndTime, @Status, @FailureNote);
END

----------------------------------------------------------------------------------------------------
-- End of: mis.Silver_Restruct_Merged_SCD.sql
----------------------------------------------------------------------------------------------------

