IF OBJECT_ID('mis.Silver_Restruct_SCD','U') IS NULL
BEGIN
    CREATE TABLE mis.Silver_Restruct_SCD (
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
        MAX(CASE WHEN TypeName = N'НекоммерческаяРеструктуризация' THEN 1 ELSE 0 END)
            OVER (PARTITION BY CreditID ORDER BY PeriodDate
                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS NonCommSeenUpTo
    FROM dedup
)
INSERT INTO mis.Silver_Restruct_SCD
    (CreditID, ValidFrom, ValidTo, TypeName, Reason, NonCommSeenUpTo)
SELECT
    CreditID,
    ValidFrom,
    COALESCE(DATEADD(day,-1, NextFrom), CONVERT(DATE,'9999-12-31')) AS ValidTo,
    TypeName,
    Reason,
    NonCommSeenUpTo
FROM rng;
