-- =============================================
-- Compiled Stored Procedure for MSSQL Agent Job (Silver) - Idempotent
-- Generated: 2026-02-06 11:24:38.378231
-- Source folder: C:\ATK_Project\sql_scripts\Silver
-- Files included: 12
--   mis.Silver_CerereOnline_base.sql
--   mis.Silver_Restruct_SCD.sql
--   mis.Silver_RestructState_SCD.sql
--   mis.Silver_Restruct_Merged_SCD.sql
--   mis.Silver_Client_UnhealedFlag.sql
--   mis.Silver_Resp_SCD.sql
--   mis.Silver_Stages_SCD.sql
--   mis.Silver_SCD_GroupMembershipPeriods.sql
--   mis.Silver_Sold_Owner.sql
--   mis.Silver_Limits.sql
--   mis.Silver_Conditions_After_Disb.sql
--   mis.Silver_CPD_TaskDays.sql
-- Requires: SQL Server 2016 SP1+ for CREATE OR ALTER
-- =============================================

USE [ATK];
GO

IF OBJECT_ID('mis.usp_SilverTables', 'P') IS NOT NULL
    DROP PROCEDURE mis.usp_SilverTables;
GO

CREATE PROCEDURE mis.usp_SilverTables
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @sql NVARCHAR(MAX);

    -- Start of: mis.Silver_CerereOnline_base.sql
    SET @sql = N'SET NOCOUNT ON;

IF OBJECT_ID(''mis.[Silver_CerereOnline_base]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Silver_CerereOnline_base];

CREATE TABLE mis.[Silver_CerereOnline_base] 
(
    [ID]                    VARCHAR(36)    NULL,
    [Date]                  DATETIME       NULL,
    [Status]                NVARCHAR(256)  NULL,
    [Posted]                VARCHAR(36)    NULL,
    [BusinessSector]        NVARCHAR(150)  NULL,
    [Type]                  NVARCHAR(100)  NULL,
    [HistoryType]           NVARCHAR(256)  NULL,
    [CreditID]              VARCHAR(36)    NULL,
    [AuthorID]              VARCHAR(36)    NULL,
    [Author]                NVARCHAR(100)  NULL,
    [Purpose]               NVARCHAR(150)  NULL,
    [IsGreen]               NVARCHAR(36)   NULL,
    [ClientID]              VARCHAR(36)    NULL,
    [CreditAmount]          DECIMAL(15,2)  NULL,
    [CurrencyType]          NVARCHAR(36)   NULL,
    [CreditAmountInMDL]     DECIMAL(18,2)  NULL,
    [NewExisting_Client]    NVARCHAR(20)   NULL,
    [RefusalReason]         NVARCHAR(200)  NULL,
    [CreditProduct]         NVARCHAR(150)  NULL,
    [ProductID]             VARCHAR(36)    NULL,
    [CreditProductID]       VARCHAR(36)    NULL,
    [InternetID]            VARCHAR(36)    NULL,
    [EmployeeID]            VARCHAR(36)    NULL,
    [BranchID]              VARCHAR(36)    NULL,
    [PartnerID]             VARCHAR(36)    NULL,
    [Partner]               NVARCHAR(150)  NULL,
    [WebDate]               DATETIME       NULL,
    [WebNr]                 NVARCHAR(50)   NULL,
    [WebPosted]             VARCHAR(36)    NULL,
    [WebIncomeTypeOnline]   NVARCHAR(200)  NULL,
    [WebAge]                INT            NULL,
    [WebSubmissionDate]     DATETIME       NULL,
    [WebCredit]             NVARCHAR(100)  NULL,
    [WebIdentifier]         NVARCHAR(50)   NULL,
    [WebCreditEmployee]     NVARCHAR(50)   NULL,
    [WebMobilePhone]        NVARCHAR(20)   NULL,
    [WebSentForReview]      NVARCHAR(36)   NULL,
    [WebGender]             NVARCHAR(256)  NULL,
    [WebStatus]             NVARCHAR(256)  NULL,
    [WebCreditTerm]         INT            NULL,
    [WebBranchID]           VARCHAR(36)    NULL,
    [CommitteeDecisionDate] DATETIME       NULL
);

;WITH Base AS (
    SELECT
        z.[ЗаявкаНаКредит ID] AS [ID],
        z.[ЗаявкаНаКредит Дата] AS [Date],
        z.[ЗаявкаНаКредит Состояние Заявки] AS [Status],
        z.[ЗаявкаНаКредит Проведен] AS [Posted],
        z.[ЗаявкаНаКредит Бизнес Сектор Экономики] AS [BusinessSector],
        z.[ЗаявкаНаКредит Вид Заявки] AS [Type],
        z.[ЗаявкаНаКредит Вид Кредитной Истории] AS [HistoryType],
        z.[ЗаявкаНаКредит Кредит ID] AS [CreditID],
        z.[ЗаявкаНаКредит Автор ID] AS [AuthorID],
        z.[ЗаявкаНаКредит Автор] AS [Author],
        z.[ЗаявкаНаКредит Цель Кредита] AS [Purpose],
        z.[ЗаявкаНаКредит Это Зеленый Кредит] AS [IsGreen],
        z.[ЗаявкаНаКредит Клиент ID] AS [ClientID],
        z.[ЗаявкаНаКредит Сумма Кредита] AS [CreditAmount],
        z.[ЗаявкаНаКредит Валюта] AS [CurrencyType],
        z.[ЗаявкаНаКредит Дата] AS [CreditAppDate],
        z.[ЗаявкаНаКредит Причина Отказа] AS [RefusalReason],
        z.[ЗаявкаНаКредит Кредитный Продукт] AS [CreditProduct],
        z.[ЗаявкаНаКредит Финансовый Продукт ID] AS [ProductID],
        z.[ЗаявкаНаКредит Кредитный Продукт ID] AS [CreditProductID],
        z.[ЗаявкаНаКредит Заявка Клиента Интернет ID] AS [InternetID],
        z.[ЗаявкаНаКредит Кредитный Эксперт ID] AS [EmployeeID],
        z.[ЗаявкаНаКредит Филиал ID] AS [BranchID],
        z.[ЗаявкаНаКредит Партнер ID] AS [PartnerID],
        z.[ЗаявкаНаКредит Партнер] AS [Partner],
        o.[ОбъединеннаяИнтернетЗаявка Дата] AS [WebDate],
        o.[ОбъединеннаяИнтернетЗаявка Номер] AS [WebNr],
        o.[ОбъединеннаяИнтернетЗаявка Проведен] AS [WebPosted],
        o.[ОбъединеннаяИнтернетЗаявка Вид Доходов Онлайн] AS [WebIncomeTypeOnline],
        o.[ОбъединеннаяИнтернетЗаявка Возраст] AS [WebAge],
        o.[ОбъединеннаяИнтернетЗаявка Дата Отправки на Рассмотрение] AS [WebSubmissionDate],
        o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит] AS [WebCredit],
        o.[ОбъединеннаяИнтернетЗаявка Идентификатор] AS [WebIdentifier],
        o.[ОбъединеннаяИнтернетЗаявка Кредитный Эксперт] AS [WebCreditEmployee],
        o.[ОбъединеннаяИнтернетЗаявка Номер Телефона Мобильный] AS [WebMobilePhone],
        o.[ОбъединеннаяИнтернетЗаявка Отправлена на Рассмотрение] AS [WebSentForReview],
        o.[ОбъединеннаяИнтернетЗаявка Пол] AS [WebGender],
        o.[ОбъединеннаяИнтернетЗаявка Состояние Заявки] AS [WebStatus],
        o.[ОбъединеннаяИнтернетЗаявка Срок Кредита] AS [WebCreditTerm],
        o.[ОбъединеннаяИнтернетЗаявка Филиал ID] AS [WebBranchID],
        COALESCE(
            z.[ЗаявкаНаКредит Клиент ID],
            o.[ОбъединеннаяИнтернетЗаявка Идентификатор],
            o.[ОбъединеннаяИнтернетЗаявка Номер Телефона Мобильный],
            o.[ОбъединеннаяИнтернетЗаявка Автор ID],
            o.[ОбъединеннаяИнтернетЗаявка ID]
        ) AS ClientKey,
        c.[ПротоколКомитета Дата Решения] AS [CommitteeDecisionDate]
    FROM [ATK].[mis].[Bronze_Документы.ЗаявкаНаКредит] z
    LEFT JOIN [ATK].[mis].[Bronze_Документы.ОбъединеннаяИнтернетЗаявка] o
        ON z.[ЗаявкаНаКредит ID] = o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
		AND (o.[ОбъединеннаяИнтернетЗаявка Пометка Удаления] = ''00''
	    OR o.[ОбъединеннаяИнтернетЗаявка Пометка Удаления] IS NULL)
    LEFT JOIN [ATK].[mis].[Bronze_Документы.ПротоколКомитета] c
        ON c.[ПротоколКомитета Заявка ID] = z.[ЗаявкаНаКредит ID]

    UNION ALL

    SELECT
        NULL AS [ID], NULL AS [Date], NULL AS [Status], NULL AS [Posted],
        NULL AS [BusinessSector], NULL AS [Type], NULL AS [HistoryType],
        NULL AS [CreditID], NULL AS [AuthorID], NULL AS [Author], NULL AS [Purpose],
        NULL AS [IsGreen], NULL AS [ClientID], NULL AS [CreditAmount],
        NULL AS [CurrencyType], NULL AS [CreditAppDate],     
        NULL AS [RefusalReason], NULL AS [CreditProduct], NULL AS [ProductID],
        NULL AS [CreditProductID], NULL AS [InternetID], NULL AS [EmployeeID], NULL AS [BranchID],
        NULL AS [PartnerID], NULL AS [Partner],
        o.[ОбъединеннаяИнтернетЗаявка Дата],
        o.[ОбъединеннаяИнтернетЗаявка Номер],
        o.[ОбъединеннаяИнтернетЗаявка Проведен],
        o.[ОбъединеннаяИнтернетЗаявка Вид Доходов Онлайн],
        o.[ОбъединеннаяИнтернетЗаявка Возраст],
        o.[ОбъединеннаяИнтернетЗаявка Дата Отправки на Рассмотрение],
        o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит],
        o.[ОбъединеннаяИнтернетЗаявка Идентификатор],
        o.[ОбъединеннаяИнтернетЗаявка Кредитный Эксперт],
        o.[ОбъединеннаяИнтернетЗаявка Номер Телефона Мобильный],
        o.[ОбъединеннаяИнтернетЗаявка Отправлена на Рассмотрение],
        o.[ОбъединеннаяИнтернетЗаявка Пол],
        o.[ОбъединеннаяИнтернетЗаявка Состояние Заявки],
        o.[ОбъединеннаяИнтернетЗаявка Срок Кредита],
        o.[ОбъединеннаяИнтернетЗаявка Филиал ID],
        COALESCE(
            o.[ОбъединеннаяИнтернетЗаявка Идентификатор],
            o.[ОбъединеннаяИнтернетЗаявка Номер Телефона Мобильный],
            o.[ОбъединеннаяИнтернетЗаявка Автор ID],
            o.[ОбъединеннаяИнтернетЗаявка ID]
        ) AS ClientKey,
        NULL AS [CommitteeDecisionDate]
    FROM [ATK].[mis].[Bronze_Документы.ОбъединеннаяИнтернетЗаявка] o
    LEFT JOIN [ATK].[mis].[Bronze_Документы.ЗаявкаНаКредит] z
        ON z.[ЗаявкаНаКредит ID] = o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
    WHERE z.[ЗаявкаНаКредит ID] IS NULL
       OR o.[ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID] = ''00000000000000000000000000000000''
	   AND (o.[ОбъединеннаяИнтернетЗаявка Пометка Удаления] = ''00''
	   OR o.[ОбъединеннаяИнтернетЗаявка Пометка Удаления] IS NULL)
)
INSERT INTO mis.[Silver_CerereOnline_base] 
(
    [ID],[Date],[Status],[Posted],[BusinessSector],[Type],[HistoryType],
    [CreditID],[AuthorID],[Author],[Purpose],[IsGreen],[ClientID],
    [CreditAmount],[CurrencyType], [CreditAmountInMDL],[NewExisting_Client],
    [RefusalReason],[CreditProduct],[ProductID],[CreditProductID],
    [InternetID],[EmployeeID],[BranchID],[PartnerID],[Partner],
    [WebDate],[WebNr],[WebPosted],[WebIncomeTypeOnline],[WebAge],
    [WebSubmissionDate],[WebCredit],[WebIdentifier],[WebCreditEmployee],
    [WebMobilePhone],[WebSentForReview],[WebGender],[WebStatus],
    [WebCreditTerm],[WebBranchID],[CommitteeDecisionDate]
)
SELECT
    b.[ID], b.[Date], b.[Status], b.[Posted],
    b.[BusinessSector], b.[Type], b.[HistoryType],
    b.[CreditID], b.[AuthorID], b.[Author], b.[Purpose],
    b.[IsGreen], b.[ClientID], b.[CreditAmount], b.[CurrencyType],
    ROUND(b.[CreditAmount] * ISNULL(v.[Валюта Курс], 1), 2) AS [CreditAmountInMDL],
    CASE
        WHEN b.CreditAmount IS NULL OR b.CreditAmount <= 0 THEN N''Cancelled''
        WHEN ROW_NUMBER() OVER (PARTITION BY b.ClientKey ORDER BY b.WebDate) = 1 THEN N''New''
        ELSE N''Existing''
    END AS [NewExisting_Client],
    b.[RefusalReason], b.[CreditProduct], b.[ProductID], b.[CreditProductID],
    b.[InternetID], b.[EmployeeID], b.[BranchID], b.[PartnerID], b.[Partner],
    b.[WebDate], b.[WebNr], b.[WebPosted], b.[WebIncomeTypeOnline], b.[WebAge],
    b.[WebSubmissionDate], b.[WebCredit], b.[WebIdentifier], b.[WebCreditEmployee],
    b.[WebMobilePhone], b.[WebSentForReview], b.[WebGender], b.[WebStatus],
    b.[WebCreditTerm], b.[WebBranchID], b.[CommitteeDecisionDate]
FROM Base b
LEFT JOIN [ATK].[mis].[Bronze_Справочники.Контрагенты] AS c
    ON b.[ClientID] = c.[Контрагенты ID]
OUTER APPLY (
    SELECT TOP 1 v.[Валюта Курс]
    FROM [ATK].[mis].[Bronze_РегистрыСведений.Валюта] v
    WHERE v.[Валюта Валюта] = b.[CurrencyType]
      AND v.[Валюта Период] <= b.[CreditAppDate]
    ORDER BY v.[Валюта Период] DESC
) AS v
WHERE c.[Контрагенты Тестовый Контрагент] = 0;';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.Silver_Restruct_SCD.sql
    SET @sql = N'SET NOCOUNT ON;

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
FROM rng;';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.Silver_RestructState_SCD.sql
    SET @sql = N'SET NOCOUNT ON;

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
INSERT INTO mis.Silver_RestructState_SCD
    (CreditID, ValidFrom, ValidTo, StateName)
SELECT
    CreditID,
    ValidFrom,
    COALESCE(DATEADD(day,-1, NextFrom), CONVERT(DATE,''9999-12-31'')) AS ValidTo,
    StateName
FROM rng;';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.Silver_Restruct_Merged_SCD.sql
    SET @sql = N'SET NOCOUNT ON;

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
    IF COL_LENGTH(''mis.Silver_Restruct_Merged_SCD'', ''ClientID'') IS NULL
        ALTER TABLE mis.Silver_Restruct_Merged_SCD ADD ClientID varchar(64) NULL;

    IF COL_LENGTH(''mis.Silver_Restruct_Merged_SCD'', ''CreditStatus'') IS NULL
        ALTER TABLE mis.Silver_Restruct_Merged_SCD ADD CreditStatus nvarchar(200) NULL;

    TRUNCATE TABLE mis.Silver_Restruct_Merged_SCD;
END;

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
END;';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.Silver_Client_UnhealedFlag.sql
    SET @sql = N'SET NOCOUNT ON;

IF OBJECT_ID(''mis.Silver_Client_UnhealedFlag'', ''U'') IS NULL
BEGIN
    CREATE TABLE mis.Silver_Client_UnhealedFlag 
	(
        ClientID    VARCHAR(36) NOT NULL,
        SoldDate    DATE        NOT NULL,
        HasUnhealed BIT         NOT NULL,
        CONSTRAINT PK_Silver_Client_UnhealedFlag1 PRIMARY KEY (ClientID, SoldDate)
    );
END;




DECLARE @DateFrom date = ''2023-09-01'';
DECLARE @DateTo   date = ''2026-12-31'';
DECLARE @Today    date = CAST(GETDATE() AS date);
IF (@DateTo > @Today) SET @DateTo = @Today;




DELETE FROM mis.Silver_Client_UnhealedFlag
WHERE SoldDate BETWEEN @DateFrom AND @DateTo;




IF OBJECT_ID(''tempdb..#Dates'',''U'') IS NOT NULL DROP TABLE #Dates;

;WITH N AS (
    SELECT TOP (DATEDIFF(day,@DateFrom,@DateTo)+1)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
SELECT DATEADD(day,n,@DateFrom) AS SoldDate
INTO #Dates
FROM N;

CREATE UNIQUE CLUSTERED INDEX CIX_Dates ON #Dates(SoldDate);




INSERT INTO mis.Silver_Client_UnhealedFlag 
           (ClientID, SoldDate, HasUnhealed)
SELECT m.ClientID, d.SoldDate, CAST(1 AS bit)
FROM #Dates d
JOIN (
    SELECT DISTINCT ClientID
    FROM mis.Silver_Restruct_Merged_SCD
    WHERE ClientID IS NOT NULL AND ClientID <> ''''
) c ON 1=1
JOIN mis.Silver_Restruct_Merged_SCD m
  ON m.ClientID = c.ClientID
 AND d.SoldDate BETWEEN m.ValidFrom AND m.ValidTo
 AND m.TypeName_Sticky IS NOT NULL
 AND m.StateName = N''НеИзлеченный''
 AND LTRIM(RTRIM(m.CreditStatus)) IN (N''Выдан'', N''Активен'', N''Открыт'')
GROUP BY m.ClientID, d.SoldDate;';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.Silver_Resp_SCD.sql
    SET @sql = N'SET NOCOUNT ON;




DECLARE @SpecialBranches TABLE (BranchID VARCHAR(36) PRIMARY KEY);

INSERT INTO @SpecialBranches (BranchID)
VALUES
  (''B73A00155D65140C11EDCF8EFC5B26C5''),
  (''B8934CC39235AB0B41675ED45E7EE551''),
  (''B7D800155D65140C11F0316FD846B283''),
  (''80FE00155D65040111EB7DB987EF3B3A''),
  (''80FE00155D01451511EA2246DC87677D'');




IF OBJECT_ID(''mis.Silver_Resp_SCD'', ''U'') IS NOT NULL
    DROP TABLE mis.Silver_Resp_SCD;

CREATE TABLE mis.Silver_Resp_SCD 
(
    CreditID        VARCHAR(36) NOT NULL,
    ValidFrom       DATE        NOT NULL,
    ValidTo         DATE        NOT NULL,
    BranchID        VARCHAR(36) NULL,
    ExpertID        VARCHAR(36) NULL,
    IsSpecialBranch BIT         NOT NULL,
    FinalBranchID   VARCHAR(36) NULL,
    FinalExpertID   VARCHAR(36) NULL,
    CONSTRAINT PK_Resp_SCD PRIMARY KEY (CreditID, ValidFrom)
);




DECLARE @DateFrom DATE = ''2023-09-01'';

IF OBJECT_ID(''tempdb..#RespBaseRaw'') IS NOT NULL DROP TABLE #RespBaseRaw;
IF OBJECT_ID(''tempdb..#RespBase'') IS NOT NULL DROP TABLE #RespBase;

SELECT
    r.[ОтветственныеПоКредитамВыданным Кредит ID] AS CreditID,
    CAST(r.[ОтветственныеПоКредитамВыданным Период] AS DATE) AS PeriodDate,
    r.[ОтветственныеПоКредитамВыданным Филиал ID] AS BranchID,
    r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS ExpertID,
    ROW_NUMBER() OVER (
        PARTITION BY r.[ОтветственныеПоКредитамВыданным Кредит ID],
                     CAST(r.[ОтветственныеПоКредитамВыданным Период] AS DATE)
        ORDER BY r.[ОтветственныеПоКредитамВыданным Номер Строки] DESC,
                 r.[ОтветственныеПоКредитамВыданным ID] DESC
    ) AS rn
INTO #RespBaseRaw
FROM mis.[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным] r
WHERE r.[ОтветственныеПоКредитамВыданным Активность] = 1
  AND CAST(r.[ОтветственныеПоКредитамВыданным Период] AS DATE) >= @DateFrom;

SELECT CreditID, PeriodDate, BranchID, ExpertID
INTO #RespBase
FROM #RespBaseRaw
WHERE rn = 1;

DROP TABLE #RespBaseRaw;




;WITH stage AS (
    SELECT
        r.CreditID,
        r.PeriodDate AS ValidFrom,
        LEAD(r.PeriodDate) OVER (PARTITION BY r.CreditID ORDER BY r.PeriodDate) AS NextFrom,
        r.BranchID,
        r.ExpertID,
        CASE WHEN EXISTS (SELECT 1 FROM @SpecialBranches sb WHERE sb.BranchID = r.BranchID)
             THEN 1 ELSE 0 END AS IsSpecialBranch
    FROM #RespBase r
)
INSERT INTO mis.Silver_Resp_SCD
(
    CreditID, ValidFrom, ValidTo,
    BranchID, ExpertID,
    IsSpecialBranch, FinalBranchID, FinalExpertID
)
SELECT
    s.CreditID,
    s.ValidFrom,
    COALESCE(DATEADD(DAY,-1,s.NextFrom), ''9999-12-31'') AS ValidTo,
    s.BranchID,
    s.ExpertID,
    s.IsSpecialBranch,
    
    COALESCE(nsb.LastBranchID, s.BranchID) AS FinalBranchID,
    COALESCE(nsb.LastExpertID, s.ExpertID) AS FinalExpertID
FROM stage s
OUTER APPLY
(
    SELECT TOP 1 r.BranchID AS LastBranchID, r.ExpertID AS LastExpertID
    FROM #RespBase r
    WHERE r.CreditID = s.CreditID
      AND r.BranchID NOT IN (SELECT BranchID FROM @SpecialBranches)
      AND r.PeriodDate <= s.ValidFrom
    ORDER BY r.PeriodDate DESC
) nsb;

DROP TABLE #RespBase;';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.Silver_Stages_SCD.sql
    SET @sql = N'SET NOCOUNT ON;




IF OBJECT_ID(''mis.Silver_Stages_SCD'',''U'') IS NULL
BEGIN
    CREATE TABLE mis.Silver_Stages_SCD 
	(
        CreditID   VARCHAR(36)   NOT NULL,
        ValidFrom  DATE          NOT NULL,
        ValidTo    DATE          NOT NULL,
        StageName  NVARCHAR(50)  NULL,
        CONSTRAINT PK_Silver_Stages_SCD PRIMARY KEY (CreditID, ValidFrom)
    );
END
ELSE
BEGIN
    TRUNCATE TABLE mis.Silver_Stages_SCD;
END;




;WITH src AS (
    SELECT
        CAST([СтадииКредитов Период] AS DATE) AS PeriodDate,
        [СтадииКредитов Кредит ID]           AS CreditID,
        [СтадииКредитов Стадия]              AS StageName,
        [СтадииКредитов ID]                  AS RowId
    FROM dbo.[РегистрыСведений.СтадииКредитов]
    WHERE [СтадииКредитов Кредит ID] IS NOT NULL
      AND [СтадииКредитов Период]    IS NOT NULL
),
dedup AS (
    SELECT
        CreditID, PeriodDate, StageName,
        ROW_NUMBER() OVER (PARTITION BY CreditID, PeriodDate ORDER BY RowId DESC) AS rn
    FROM src
),
day_rows AS (
    SELECT CreditID, PeriodDate, StageName
    FROM dedup
    WHERE rn = 1
),
borders AS (
    SELECT
        d.CreditID,
        d.PeriodDate AS ValidFrom,
        d.StageName,
        LAG(d.StageName) OVER (PARTITION BY d.CreditID ORDER BY d.PeriodDate) AS PrevStage
    FROM day_rows d
),
starts AS (
    SELECT CreditID, ValidFrom, StageName
    FROM borders
    WHERE ISNULL(PrevStage, N''#NULL#'') <> ISNULL(StageName, N''#NULL#'')
       OR PrevStage IS NULL
),
grid AS (
    SELECT
        CreditID,
        StageName,
        ValidFrom,
        LEAD(ValidFrom) OVER (PARTITION BY CreditID ORDER BY ValidFrom) AS NextFrom
    FROM starts
),
slices AS (
    SELECT
        CreditID,
        StageName,
        ValidFrom,
        COALESCE(DATEADD(day,-1,NextFrom), CONVERT(DATE,''9999-12-31'')) AS ValidTo
    FROM grid
)
INSERT INTO mis.Silver_Stages_SCD 
           (CreditID, ValidFrom, ValidTo, StageName)
SELECT CreditID, ValidFrom, ValidTo, StageName
FROM slices;




DECLARE @schema sysname = N''mis'';
DECLARE @table  sysname = N''Silver_Stages_SCD'';
DECLARE @stat   sysname = N''IX_Stages_ForIntervals'';
DECLARE @obj_id int = OBJECT_ID(QUOTENAME(@schema)+N''.''+QUOTENAME(@table));

IF @obj_id IS NOT NULL
BEGIN
    IF EXISTS (SELECT 1 FROM sys.stats  WHERE object_id=@obj_id AND name=@stat)
       AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=@obj_id AND name=@stat)
    BEGIN
        DECLARE @sql NVARCHAR(4000)=
            N''DROP STATISTICS ''+QUOTENAME(@schema)+N''.''+QUOTENAME(@table)+N''.''+QUOTENAME(@stat)+N'';'';
        EXEC (@sql);
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=@obj_id AND name=@stat)
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Stages_ForIntervals
            ON mis.Silver_Stages_SCD (CreditID, ValidFrom)
            INCLUDE (ValidTo, StageName);
    END;
END;';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.Silver_SCD_GroupMembershipPeriods.sql
    SET @sql = N'IF OBJECT_ID(''mis.[Silver_SCD_GroupMembershipPeriods]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Silver_SCD_GroupMembershipPeriods];

CREATE TABLE mis.[Silver_SCD_GroupMembershipPeriods]
(
    GroupID        VARCHAR(36) NOT NULL,
    PersonID       VARCHAR(36) NULL,
    PersonName     NVARCHAR(255) NOT NULL,
    GroupName      NVARCHAR(255) NULL,
    GroupOwner     VARCHAR(36) NULL,
    PeriodStart    DATETIME2(0) NOT NULL,
    PeriodEnd      DATETIME2(0) NOT NULL
);

WITH Events AS (
    SELECT
        sg.[СоставГруппАффилированныхЛиц Группа Аффилированных Лиц ID] AS GroupID,
        sg.[СоставГруппАффилированныхЛиц Контрагент ID] AS PersonID,
        sg.[СоставГруппАффилированныхЛиц Контрагент] AS PersonName,
        sg.[СоставГруппАффилированныхЛиц Период] AS PeriodOriginal,
        sg.[СоставГруппАффилированныхЛиц Исключен] AS ExcludedFlag,
        sg.[СоставГруппАффилированныхЛиц Группа Аффилированных Лиц] AS GroupName,
        g.[ГруппыАффилированныхЛиц Владелец] AS GroupOwner,
        CASE WHEN sg.[СоставГруппАффилированныхЛиц Исключен] = ''00''
             THEN ''Included''
             ELSE ''Excluded''
        END AS EventType,
        g.[ГруппыАффилированныхЛиц Пометка Удаления] AS DeletionFlag
    FROM [ATK].[dbo].[РегистрыСведений.СоставГруппАффилированныхЛиц] sg
    LEFT JOIN [ATK].[dbo].[Справочники.ГруппыАффилированныхЛиц] g
        ON g.[ГруппыАффилированныхЛиц ID] =
           sg.[СоставГруппАффилированныхЛиц Группа Аффилированных Лиц ID]
),
Dedup AS (
    SELECT *
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (
                   PARTITION BY
                       GroupID, PersonID, PersonName, GroupName,
                       GroupOwner, EventType, DeletionFlag
                   ORDER BY (SELECT NULL)
               ) AS rn
        FROM Events
    ) d
    WHERE rn = 1
),
Ordered AS (
    SELECT
        *,
        LEAD(PeriodOriginal) OVER (
            PARTITION BY GroupID, PersonName 
            ORDER BY PeriodOriginal
        ) AS NextDate,
        LEAD(EventType) OVER (
            PARTITION BY GroupID, PersonName 
            ORDER BY PeriodOriginal
        ) AS NextType
    FROM Dedup
)

INSERT INTO mis.[Silver_SCD_GroupMembershipPeriods]
(
    GroupID,
    PersonID,
    PersonName,
    GroupName,
    GroupOwner,
    PeriodStart,
    PeriodEnd
)
SELECT
      GroupID,
      PersonID,
      PersonName,
      GroupName,
      GroupOwner,
      PeriodOriginal AS PeriodStart,
      CASE 
        WHEN NextType = ''Excluded''
            THEN DATEADD(SECOND, -1, NextDate)
        ELSE CONVERT(DATETIME2, ''2222-01-01 00:00:00'')
      END AS PeriodEnd
FROM Ordered
WHERE EventType = ''Included''
  AND DeletionFlag = ''00''
ORDER BY GroupID, PersonName, PeriodOriginal;';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.Silver_Sold_Owner.sql
    SET @sql = N'SET NOCOUNT ON;

IF OBJECT_ID(''mis.[Silver_Sold_Owner]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Silver_Sold_Owner];

CREATE TABLE mis.[Silver_Sold_Owner]
(
      [SoldDate]   DATETIME        NOT NULL,
      [ClientID]   VARCHAR(36)     NULL,
      [CreditID]   VARCHAR(36)     NULL,
      [SoldAmount] DECIMAL(18,2)   NULL,
      [BranchID]   VARCHAR(36)     NULL,
      [GroupOwner] VARCHAR(36)     NULL
);

WITH SoldCTE AS (
    SELECT
        CAST([СуммыЗадолженностиПоПериодамПросрочки Дата] AS DATE) AS SoldDate,
        [СуммыЗадолженностиПоПериодамПросрочки Клиент ID] AS ClientID,
        [СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
        [СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] AS SoldAmount
    FROM mis.[Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки]
    WHERE [СуммыЗадолженностиПоПериодамПросрочки Дата] >= ''2025-01-01''
)
INSERT INTO mis.[Silver_Sold_Owner] (SoldDate, ClientID, CreditID, SoldAmount, BranchID, GroupOwner)
SELECT
       s.SoldDate,
       s.ClientID,
       s.CreditID,
       s.SoldAmount,
       b.[ОтветственныеПоКредитамВыданным Филиал ID] AS BranchID,
       gm.GroupOwner
FROM SoldCTE s
LEFT JOIN mis.[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным] b
       ON b.[ОтветственныеПоКредитамВыданным Кредит ID] = s.CreditID

OUTER APPLY (
    SELECT TOP 1 gm.GroupOwner
    FROM [ATK].[mis].[Silver_SCD_GroupMembershipPeriods] gm
    WHERE gm.PersonID = s.ClientID
      AND s.SoldDate >= gm.PeriodStart
      AND s.SoldDate <  gm.PeriodEnd
    ORDER BY gm.PeriodStart DESC
) gm;

CREATE CLUSTERED INDEX CIX_Silver_Sold_Owner_SoldDate
ON [mis].[Silver_Sold_Owner] (SoldDate, ClientID, CreditID);

CREATE NONCLUSTERED INDEX IX_Silver_Sold_Owner_ClientID
ON [mis].[Silver_Sold_Owner] (ClientID, SoldDate)
INCLUDE (CreditID, SoldAmount, GroupOwner, BranchID);

CREATE NONCLUSTERED INDEX IX_Silver_Sold_Owner_CreditID
ON [mis].[Silver_Sold_Owner] (CreditID, SoldDate)
INCLUDE (ClientID, SoldAmount, GroupOwner, BranchID);';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.Silver_Limits.sql
    SET @sql = N'SET NOCOUNT ON;

IF OBJECT_ID(N''mis.[Silver_Limits]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Silver_Limits];


CREATE TABLE mis.[Silver_Limits] 
(
      [Limit ID]               VARCHAR(36)    NOT NULL,
      [Limit Code]             NVARCHAR(50)   NULL,
      [Limit Name]             NVARCHAR(255)  NULL,

      
      [FirstSet Operation Type] NVARCHAR(50)  NULL,
      [FirstSet CreateDate]     DATETIME2(0)  NULL,
      [FirstSet DecisionDate]   DATETIME2(0)  NULL,
      [FirstFilial ID]          VARCHAR(36)   NULL,
      [FirstExpert ID]          VARCHAR(36)   NULL,
      [FirstClient ID]          VARCHAR(36)   NULL,
      [FirstSet Amount]         DECIMAL(18,2) NULL,

      
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
        WHERE r.[Operation Type] = N''Установка''
    ) x
    WHERE x.rn = 1
),

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




CREATE UNIQUE CLUSTERED INDEX CX_Silver_Limits
ON mis.[Silver_Limits] ([Limit ID]);';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.Silver_Conditions_After_Disb.sql
    SET @sql = N'SET NOCOUNT ON;

IF OBJECT_ID(''mis.[Silver_Conditions_After_Disb]'', ''U'') IS NOT NULL
    DROP TABLE mis.[Silver_Conditions_After_Disb];

CREATE TABLE mis.[Silver_Conditions_After_Disb]
(
      [Период] DATETIME NOT NULL,
      [Объект Tип] VARCHAR(36), 
      [Объект ID] VARCHAR(36),
      [ИД] VARCHAR(36),
      [Тип Условия] NVARCHAR(256),
      [Объект Условия Tип] VARCHAR(36),
      [Объект Условия _S] NVARCHAR(500),
      [Доп Проценты] DECIMAL(4,2),
      [Срок Выполнения] DATETIME NULL,
      [Исполнитель ID] VARCHAR(36),
      [Исполнитель] NVARCHAR(56),
      [Дата Выдачи] DATETIME NULL,
      [Выполнено] VARCHAR(36),
      [Дата Выполнения] DATETIME NULL,
      [Комментарий] NVARCHAR(1000),
      [Проверено] VARCHAR(36),
      [Это Доп Условия] VARCHAR(36),
      [Аннулирован] VARCHAR(36),
      [Кредитный Риск] NVARCHAR(256),
      [Юридический Риск] NVARCHAR(256),
      [Одобренно Комитетом] VARCHAR(36),
      [Залог ID] VARCHAR(36),
      [Залог] NVARCHAR(156),
      [Автор Аннулирования ID] VARCHAR(36),
      [Автор Аннулирования] NVARCHAR(156),
      [Автор Проверки ID] VARCHAR(36),
      [Автор Проверки] NVARCHAR(156),
      [Дата Изменения] DATETIME NULL,
      [Источник Tип] VARCHAR(36),
      [Источник Вид] VARCHAR(36),
      [Источник ID] VARCHAR(36),
      [Ответственный ID] VARCHAR(36),
      [Ответственный] NVARCHAR(156),
      [Дата Проверки] DATETIME NULL,
      [Дата аннулирования] DATETIME NULL,
      [Дата закрытия] DATETIME NULL,
      [CreditID_Found] VARCHAR(36),
      [Client ID] VARCHAR(36)
);

;WITH src AS
(
    SELECT
          r.[УсловияПослеВыдачиКредита Период]
        , r.[УсловияПослеВыдачиКредита Объект Tип]
        , r.[УсловияПослеВыдачиКредита Объект ID]
        , r.[УсловияПослеВыдачиКредита ИД]
        , r.[УсловияПослеВыдачиКредита Тип Условия]
        , r.[УсловияПослеВыдачиКредита Объект Условия Tип]
        , r.[УсловияПослеВыдачиКредита Объект Условия _S]
        , r.[УсловияПослеВыдачиКредита Доп Проценты]
        , r.[УсловияПослеВыдачиКредита Срок Выполнения]
        , r.[УсловияПослеВыдачиКредита Исполнитель ID]
        , r.[УсловияПослеВыдачиКредита Исполнитель]
        , r.[УсловияПослеВыдачиКредита Дата Выдачи]
        , r.[УсловияПослеВыдачиКредита Выполнено]
        , r.[УсловияПослеВыдачиКредита Дата Выполнения]
        , r.[УсловияПослеВыдачиКредита Комментарий]
        , r.[УсловияПослеВыдачиКредита Проверено]
        , r.[УсловияПослеВыдачиКредита Это Доп Условия]
        , r.[УсловияПослеВыдачиКредита Аннулирован]
        , r.[УсловияПослеВыдачиКредита Кредитный Риск]
        , r.[УсловияПослеВыдачиКредита Юридический Риск]
        , r.[УсловияПослеВыдачиКредита Одобренно Комитетом]
        , r.[УсловияПослеВыдачиКредита Залог ID]
        , r.[УсловияПослеВыдачиКредита Залог]
        , r.[УсловияПослеВыдачиКредита Автор Аннулирования ID]
        , r.[УсловияПослеВыдачиКредита Автор Аннулирования]
        , r.[УсловияПослеВыдачиКредита Автор Проверки ID]
        , r.[УсловияПослеВыдачиКредита Автор Проверки]
        , r.[УсловияПослеВыдачиКредита Дата Изменения]
        , r.[УсловияПослеВыдачиКредита Источник Tип]
        , r.[УсловияПослеВыдачиКредита Источник Вид]
        , r.[УсловияПослеВыдачиКредита Источник ID]
        , r.[УсловияПослеВыдачиКредита Ответственный ID]
        , r.[УсловияПослеВыдачиКредита Ответственный]
        , MIN(r.[УсловияПослеВыдачиКредита Период]) OVER (PARTITION BY r.[УсловияПослеВыдачиКредита ИД]) AS FirstPeriod
        , ROW_NUMBER() OVER (PARTITION BY r.[УсловияПослеВыдачиКредита ИД]
                             ORDER BY r.[УсловияПослеВыдачиКредита Период] DESC, 
							          r.[УсловияПослеВыдачиКредита Дата Изменения] DESC) AS rn_last,
	      MAX(CASE WHEN ISNULL(r.[УсловияПослеВыдачиКредита Проверено],0) = 0 THEN 1 ELSE 0 END)
		  OVER(PARTITION BY r.[УсловияПослеВыдачиКредита ИД]
              ORDER BY r.[УсловияПослеВыдачиКредита Период] ASC,
                       r.[УсловияПослеВыдачиКредита Дата Изменения] ASC
              ROWS BETWEEN 1 FOLLOWING AND UNBOUNDED FOLLOWING
          ) AS HasZeroAfter_Verified,

          MAX(CASE WHEN ISNULL(r.[УсловияПослеВыдачиКредита Аннулирован],0) = 0 THEN 1 ELSE 0 END)
             		  OVER(PARTITION BY r.[УсловияПослеВыдачиКредита ИД]
              ORDER BY r.[УсловияПослеВыдачиКредита Период] ASC,
                       r.[УсловияПослеВыдачиКредита Дата Изменения] ASC
              ROWS BETWEEN 1 FOLLOWING AND UNBOUNDED FOLLOWING
          ) AS HasZeroAfter_Cancelled
		  
    FROM [ATK].[mis].[Bronze_РегистрыСведений.УсловияПослеВыдачиКредита] r
    WHERE r.[УсловияПослеВыдачиКредита Объект Tип] = 8
),
dates AS
(
    
    SELECT
          s.[УсловияПослеВыдачиКредита ИД] AS CondID
        , MIN(CASE
                WHEN ISNULL(s.[УсловияПослеВыдачиКредита Проверено],0) = 1
                 AND ISNULL(s.HasZeroAfter_Verified,0) = 0
                THEN s.[УсловияПослеВыдачиКредита Период]
              END) AS VerifyStartPeriod

        
        , MIN(CASE
                WHEN ISNULL(s.[УсловияПослеВыдачиКредита Аннулирован],0) = 1
                 AND ISNULL(s.HasZeroAfter_Cancelled,0) = 0
                THEN s.[УсловияПослеВыдачиКредита Период]
              END) AS CancelStartPeriod
    FROM src s
    GROUP BY s.[УсловияПослеВыдачиКредита ИД]
),
lastrow AS
(
    
    SELECT
          s.*
        , d.VerifyStartPeriod AS [Дата Проверки]
        , d.CancelStartPeriod AS [Дата аннулирования]
        , CASE
              WHEN d.VerifyStartPeriod IS NOT NULL OR d.CancelStartPeriod IS NOT NULL
              THEN COALESCE(d.VerifyStartPeriod, d.CancelStartPeriod)
          END AS [Дата закрытия]
    FROM src s
    LEFT JOIN dates d
      ON d.CondID = s.[УсловияПослеВыдачиКредита ИД]
    WHERE s.rn_last = 1
)
INSERT INTO mis.[Silver_Conditions_After_Disb]
(
      [Период], [Объект Tип], [Объект ID], [ИД], [Тип Условия], [Объект Условия Tип], [Объект Условия _S],
      [Доп Проценты], [Срок Выполнения], [Исполнитель ID], [Исполнитель], [Дата Выдачи], [Выполнено], [Дата Выполнения],
      [Комментарий], [Проверено], [Это Доп Условия], [Аннулирован], [Кредитный Риск], [Юридический Риск],
      [Одобренно Комитетом], [Залог ID], [Залог], [Автор Аннулирования ID], [Автор Аннулирования],
      [Автор Проверки ID], [Автор Проверки], [Дата Изменения], [Источник Tип], [Источник Вид], [Источник ID],
      [Ответственный ID], [Ответственный], [Дата Проверки], [Дата аннулирования], [Дата закрытия],
      [CreditID_Found], [Client ID]
)
SELECT
      s.FirstPeriod AS [Период],
      s.[УсловияПослеВыдачиКредита Объект Tип] AS [Объект Tип],
      s.[УсловияПослеВыдачиКредита Объект ID] AS [Объект ID],
      s.[УсловияПослеВыдачиКредита ИД] AS [ИД],
      s.[УсловияПослеВыдачиКредита Тип Условия] AS [Тип Условия],
      s.[УсловияПослеВыдачиКредита Объект Условия Tип] AS [Объект Условия Tип],
      s.[УсловияПослеВыдачиКредита Объект Условия _S] AS [Объект Условия _S],
      s.[УсловияПослеВыдачиКредита Доп Проценты] AS [Доп Проценты],
      s.[УсловияПослеВыдачиКредита Срок Выполнения] AS [Срок Выполнения],
      s.[УсловияПослеВыдачиКредита Исполнитель ID] AS [Исполнитель ID],
      s.[УсловияПослеВыдачиКредита Исполнитель] AS [Исполнитель],
      s.[УсловияПослеВыдачиКредита Дата Выдачи] AS [Дата Выдачи],
      s.[УсловияПослеВыдачиКредита Выполнено] AS [Выполнено],
      s.[УсловияПослеВыдачиКредита Дата Выполнения] AS [Дата Выполнения],
      s.[УсловияПослеВыдачиКредита Комментарий] AS [Комментарий],
      s.[УсловияПослеВыдачиКредита Проверено] AS [Проверено],
      s.[УсловияПослеВыдачиКредита Это Доп Условия] AS [Это Доп Условия],
      s.[УсловияПослеВыдачиКредита Аннулирован] AS [Аннулирован],
      s.[УсловияПослеВыдачиКредита Кредитный Риск] AS [Кредитный Риск],
      s.[УсловияПослеВыдачиКредита Юридический Риск] AS [Юридический Риск],
      s.[УсловияПослеВыдачиКредита Одобренно Комитетом] AS [Одобренно Комитетом],
      s.[УсловияПослеВыдачиКредита Залог ID] AS [Залог ID],
      s.[УсловияПослеВыдачиКредита Залог] AS [Залог],
      s.[УсловияПослеВыдачиКредита Автор Аннулирования ID] AS [Автор Аннулирования ID],
      s.[УсловияПослеВыдачиКредита Автор Аннулирования] AS [Автор Аннулирования],
      s.[УсловияПослеВыдачиКредита Автор Проверки ID] AS [Автор Проверки ID],
      s.[УсловияПослеВыдачиКредита Автор Проверки] AS [Автор Проверки],
      s.[УсловияПослеВыдачиКредита Дата Изменения] AS [Дата Изменения],
      s.[УсловияПослеВыдачиКредита Источник Tип] AS [Источник Tип],
      s.[УсловияПослеВыдачиКредита Источник Вид] AS [Источник Вид],
      s.[УсловияПослеВыдачиКредита Источник ID] AS [Источник ID],
      s.[УсловияПослеВыдачиКредита Ответственный ID] AS [Ответственный ID],
      s.[УсловияПослеВыдачиКредита Ответственный] AS [Ответственный],
      s.[Дата Проверки] AS [Дата Проверки],
      s.[Дата аннулирования] AS [Дата аннулирования],
      s.[Дата закрытия] AS [Дата закрытия],
      c.[Кредиты ID] AS [CreditID_Found],
      COALESCE(c.[Кредиты Владелец], lim.[LastClient ID], grp.[GroupClient ID]) AS [Client ID]
FROM lastrow s
LEFT JOIN [ATK].[mis].[Bronze_Справочники.Кредиты] c
    ON c.[Кредиты ID] = s.[УсловияПослеВыдачиКредита Объект ID]
OUTER APPLY
(
    SELECT TOP (1) l.[LastClient ID]
    FROM [ATK].[mis].[Silver_Limits] l
    WHERE l.[Limit ID] = s.[УсловияПослеВыдачиКредита Объект ID]
    ORDER BY l.[Last CreateDate] DESC, l.[Last DecisionDate] DESC
) lim
OUTER APPLY
(
    SELECT TOP (1) g.[ГруппыАффилированныхЛиц Владелец] AS [GroupClient ID]
    FROM [ATK].[dbo].[Справочники.ГруппыАффилированныхЛиц] g
    WHERE g.[ГруппыАффилированныхЛиц ID] = s.[УсловияПослеВыдачиКредита Объект ID]
      AND g.[ГруппыАффилированныхЛиц Пометка Удаления] = 0
    ORDER BY g.[ГруппыАффилированныхЛиц Версия Данных] DESC
)grp

CREATE UNIQUE CLUSTERED INDEX CX_ConditionsAfterDisb_Last
ON mis.[Silver_Conditions_After_Disb] ([ИД]);

CREATE INDEX IX_ConditionsAfterDisb_Last_ObjectID
ON mis.[Silver_Conditions_After_Disb] ([Объект ID]);

CREATE INDEX IX_ConditionsAfterDisb_Last_CreditFound
ON mis.[Silver_Conditions_After_Disb] ([CreditID_Found]);

CREATE INDEX IX_ConditionsAfterDisb_Last_ClientID
ON mis.[Silver_Conditions_After_Disb] ([Client ID]);';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    -- Start of: mis.Silver_CPD_TaskDays.sql
    SET @sql = N'SET NOCOUNT ON;
SET XACT_ABORT ON;





DECLARE @OpenDttm datetime2(0) = ''1753-01-01T00:00:00'';
DECLARE @ClientIDFilter varchar(36) = NULL;  







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
          ''Sold range is NULL: [ATK].[mis].[Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] is empty.'',
          1;

DECLARE @MaxN int = DATEDIFF(day, @MinSoldDate, @AsOfDate) + 1;
IF @MaxN < 1 SET @MaxN = 1;




IF OBJECT_ID(''mis.Silver_CPD_TaskHeader'',''U'') IS NULL
BEGIN
    CREATE TABLE [mis].[Silver_CPD_TaskHeader]
    (
        CondID       varchar(36)   NOT NULL,
        ClientID     varchar(36)   NOT NULL,
        TaskCreditID varchar(36)   NULL,

        DateFrom     date          NOT NULL,

        
        DoneDttm     datetime2(0)  NOT NULL,
        DoneDate     date          NULL,

        DateFromAdj  date          NOT NULL,
        DateToAdj    date          NOT NULL,

        LoadDttm     datetime      NOT NULL,

        CONSTRAINT PK_Silver_CPD_TaskHeader PRIMARY KEY CLUSTERED (CondID)
    );

    CREATE INDEX IX_TaskHeader_Client_Dates
        ON [mis].[Silver_CPD_TaskHeader] (ClientID, DateFromAdj, DateToAdj)
        INCLUDE (TaskCreditID, DateFrom, DoneDate);
END;

IF OBJECT_ID(''mis.Silver_CPD_TaskDays'',''U'') IS NULL
BEGIN
    CREATE TABLE [mis].[Silver_CPD_TaskDays]
    (
        CondID       varchar(36) NOT NULL,
        CPDDate      date        NOT NULL,
        ClientID     varchar(36) NOT NULL,
        TaskCreditID varchar(36) NULL,
        LoadDttm     datetime    NOT NULL
    );

    CREATE CLUSTERED INDEX CX_TaskDays_Client_Date
        ON [mis].[Silver_CPD_TaskDays] (ClientID, CPDDate, CondID);

    CREATE INDEX IX_TaskDays_Cond_Date
        ON [mis].[Silver_CPD_TaskDays] (CondID, CPDDate)
        INCLUDE (ClientID, TaskCreditID);
END;




TRUNCATE TABLE [mis].[Silver_CPD_TaskHeader];

INSERT INTO [mis].[Silver_CPD_TaskHeader]
(
    CondID, ClientID, TaskCreditID,
    DateFrom, DoneDttm, DoneDate,
    DateFromAdj, DateToAdj,
    LoadDttm
)
SELECT
      c.[ИД]                                           AS CondID
    , LTRIM(RTRIM(c.[Client ID]))                      AS ClientID
    , NULLIF(LTRIM(RTRIM(c.[CreditID_Found])), '''')     AS TaskCreditID
    , CAST(c.[Период] AS date)                         AS DateFrom

    
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
FROM [ATK].[mis].[Silver_Conditions_After_Disb] c
WHERE c.[ИД] IS NOT NULL
  AND c.[Client ID] IS NOT NULL
  AND c.[Период] IS NOT NULL
  AND (@ClientIDFilter IS NULL OR LTRIM(RTRIM(c.[Client ID])) = @ClientIDFilter);


UPDATE h
SET h.DateToAdj = CASE WHEN h.DateToAdj < h.DateFromAdj THEN h.DateFromAdj ELSE h.DateToAdj END
FROM [mis].[Silver_CPD_TaskHeader] h;




TRUNCATE TABLE [mis].[Silver_CPD_TaskDays];

;WITH N AS
(
    SELECT TOP (@MaxN)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
)
INSERT INTO [mis].[Silver_CPD_TaskDays]
(
    CondID, CPDDate, ClientID, TaskCreditID, LoadDttm
)
SELECT
      h.CondID
    , DATEADD(day, n.n, h.DateFromAdj)                   AS CPDDate
    , h.ClientID
    , NULLIF(LTRIM(RTRIM(h.TaskCreditID)),'''')            AS TaskCreditID
    , GETDATE()
FROM [mis].[Silver_CPD_TaskHeader] h
JOIN N
  ON DATEADD(day, n.n, h.DateFromAdj) <= h.DateToAdj;




SELECT ISNULL(@ClientIDFilter,''(ALL)'') AS ClientIDFilter, COUNT(*) AS CntTasks
FROM [mis].[Silver_CPD_TaskHeader];

SELECT ISNULL(@ClientIDFilter,''(ALL)'') AS ClientIDFilter, COUNT(*) AS CntTaskDays
FROM [mis].[Silver_CPD_TaskDays];';
    BEGIN TRY
        EXEC sys.sp_executesql @sql;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

END
GO
