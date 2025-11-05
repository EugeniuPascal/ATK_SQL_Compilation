-- Создаём целевую SCD-таблицу (если ещё нет)
IF OBJECT_ID('[ATK].[mis].[Silver_Restruct_SCD]','U') IS NULL
CREATE TABLE [ATK].[mis].[Silver_Restruct_SCD] (
    CreditID        varchar(64)   NOT NULL,
    ValidFrom       date          NOT NULL,
    ValidTo         date          NOT NULL,   -- '9999-12-31' для открытого интервала
    TypeName        nvarchar(200) NULL,
    Reason          nvarchar(500) NULL,
    NonCommSeenUpTo bit           NOT NULL,
    CONSTRAINT PK_Silver_Restruct_SCD PRIMARY KEY (CreditID, ValidFrom)
);
ELSE
TRUNCATE TABLE [ATK].[mis].[Silver_Restruct_SCD];
GO

;WITH src AS (
    SELECT
        r.[РеструктурированныеКредиты Кредит ID] AS CreditID,
        CAST(r.[РеструктурированныеКредиты Период] AS date)       AS PeriodDate, -- считаем на лету
        r.[РеструктурированныеКредиты Тип Реструктуризации Долга] AS TypeName,
        r.[РеструктурированныеКредиты Причина Реструктуризации]   AS Reason,
        ROW_NUMBER() OVER (
            PARTITION BY
                r.[РеструктурированныеКредиты Кредит ID],
                CAST(r.[РеструктурированныеКредиты Период] AS date)
            ORDER BY r.[РеструктурированныеКредиты Период] DESC
        ) AS rn
    FROM [ATK].[mis].[Bronze_РегистрыСведений.РеструктурированныеКредиты] r
),
dedup AS (  -- по одному событию на день/кредит
    SELECT CreditID, PeriodDate, TypeName, Reason
    FROM src
    WHERE rn = 1
),
rng AS (    -- считаем интервалы
    SELECT
        CreditID,
        PeriodDate AS ValidFrom,
        LEAD(PeriodDate) OVER (PARTITION BY CreditID ORDER BY PeriodDate) AS NextFrom,
        TypeName,
        Reason,
        -- флаг: «Некоммерческая… встречалась когда-либо ДО/НА этот интервал»
        MAX(CASE WHEN TypeName = N'НекоммерческаяРеструктуризация' THEN 1 ELSE 0 END)
            OVER (PARTITION BY CreditID ORDER BY PeriodDate
                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS NonCommSeenUpTo
    FROM dedup
)
INSERT INTO [ATK].[mis].[Silver_Restruct_SCD]
    (CreditID, ValidFrom, ValidTo, TypeName, Reason, NonCommSeenUpTo)
SELECT
    CreditID,
    ValidFrom,
    COALESCE(DATEADD(day,-1, NextFrom), CONVERT(date,'9999-12-31')) AS ValidTo,
    TypeName,
    Reason,
    NonCommSeenUpTo
FROM rng;
GO
