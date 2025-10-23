-- Создаём/очищаем целевую SCD-таблицу состояний
IF OBJECT_ID('[ATK].[mis].[2tbl_Silver_RestructState_SCD]','U') IS NULL
    CREATE TABLE [ATK].[mis].[2tbl_Silver_RestructState_SCD] (
        CreditID   varchar(64)   NOT NULL,
        ValidFrom  date          NOT NULL,
        ValidTo    date          NOT NULL,   -- '9999-12-31' для открытого интервала
        StateName  nvarchar(200) NULL,
        CONSTRAINT PK_Silver_RestructState_SCD PRIMARY KEY (CreditID, ValidFrom)
    );
ELSE
    TRUNCATE TABLE [ATK].[mis].[2tbl_Silver_RestructState_SCD];
GO
 
;WITH src AS (
    SELECT
        s.[СостоянияРеструктурированныхКредитов Кредит ID] AS CreditID,
        CAST(s.[СостоянияРеструктурированныхКредитов Период] AS date) AS PeriodDate,
        s.[СостоянияРеструктурированныхКредитов Состояние Реструктурированного Кредита] AS StateName,
        ROW_NUMBER() OVER (
            PARTITION BY s.[СостоянияРеструктурированныхКредитов Кредит ID],
                         CAST(s.[СостоянияРеструктурированныхКредитов Период] AS date)
            ORDER BY s.[СостоянияРеструктурированныхКредитов Период] DESC
        ) AS rn
    FROM [ATK].[mis].[Silver_РегистрыСведений.СостоянияРеструктурированныхКредитов] s
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
INSERT INTO [ATK].[mis].[2tbl_Silver_RestructState_SCD] (CreditID, ValidFrom, ValidTo, StateName)
SELECT
    CreditID,
    ValidFrom,
    COALESCE(DATEADD(day,-1, NextFrom), CONVERT(date,'9999-12-31')) AS ValidTo,
    StateName
FROM rng;
GO