/* ===== Создание / приведение схемы ===== */
IF OBJECT_ID('[ATK].[mis].[Silver_Restruct_Merged_SCD]','U') IS NULL
BEGIN
    CREATE TABLE [ATK].[mis].[Silver_Restruct_Merged_SCD] (
        CreditID        varchar(64)   NOT NULL,
        ValidFrom       date          NOT NULL,
        ValidTo         date          NOT NULL,
        TypeName        nvarchar(200) NULL,
        Reason          nvarchar(500) NULL,
        StateName       nvarchar(200) NULL,
        TypeName_Sticky nvarchar(200) NULL,   -- «Некоммерческая…» прилипает вперёд
        CreditStatus    nvarchar(200) NULL,   -- <<< НОВОЕ: статус кредита (Активен/Закрыт и т.п.)
        ClientID        varchar(64)   NULL,   -- владелец кредита
        CONSTRAINT PK_Silver_Restruct_Merged_SCD PRIMARY KEY (CreditID, ValidFrom)
    );
END
ELSE
BEGIN
    /* Добавим недостающие колонки, если их нет */
    IF COL_LENGTH('ATK.mis.Silver_Restruct_Merged_SCD', 'ClientID') IS NULL
        ALTER TABLE [ATK].[mis].[Silver_Restruct_Merged_SCD] ADD ClientID varchar(64) NULL;

    IF COL_LENGTH('ATK.mis.Silver_Restruct_Merged_SCD', 'CreditStatus') IS NULL
        ALTER TABLE [ATK].[mis].[Silver_Restruct_Merged_SCD] ADD CreditStatus nvarchar(200) NULL;

    TRUNCATE TABLE [ATK].[mis].[Silver_Restruct_Merged_SCD];
END;
GO

/* ===== Построение объединённой SCD с учётом статуса кредита ===== */
;WITH borders AS (
    /* точки изменения типа/причины реструктуризации */
    SELECT CreditID, CAST(ValidFrom AS date) AS ValidFrom
    FROM   [ATK].[mis].[Silver_Restruct_SCD]
    UNION
    /* точки изменения состояния реструктуризации */
    SELECT CreditID, CAST(ValidFrom AS date) AS ValidFrom
    FROM   [ATK].[mis].[Silver_RestructState_SCD]
    UNION
    /* точки изменения статуса кредита (берём только активные записи регистра) */
    SELECT
        s.[СтатусыКредитовВыданных Кредит ID] AS CreditID,
        CAST(s.[СтатусыКредитовВыданных Период] AS date) AS ValidFrom
    FROM [ATK].[mis].[Bronze_РегистрыСведений.СтатусыКредитовВыданных] s
    WHERE s.[СтатусыКредитовВыданных Активность] = 1
),
grid AS (
    SELECT
        CreditID,
        ValidFrom,
        LEAD(ValidFrom) OVER (PARTITION BY CreditID ORDER BY ValidFrom) AS NextFrom
    FROM borders
),
slices AS (
    SELECT
        CreditID,
        ValidFrom,
        COALESCE(DATEADD(day,-1, NextFrom), CONVERT(date,'9999-12-31')) AS ValidTo
    FROM grid
),
/* На начало каждого среза подтягиваем: Type/Reason, State и CreditStatus */
joined AS (
    SELECT
        z.CreditID,
        z.ValidFrom,
        z.ValidTo,
        r.TypeName,
        r.Reason,
        r.NonCommSeenUpTo,
        s.StateName,
        cs.[СтатусыКредитовВыданных Статус] AS CreditStatus,  -- активный статус на дату среза
        /* локальный флаг для липкости */
        COALESCE(r.NonCommSeenUpTo, 0) AS SeenNcHere
    FROM slices z
    OUTER APPLY (
        SELECT TOP (1) rr.TypeName, rr.Reason, rr.NonCommSeenUpTo
        FROM [ATK].[mis].[Silver_Restruct_SCD] rr
        WHERE rr.CreditID = z.CreditID
          AND rr.ValidFrom <= z.ValidFrom
          AND rr.ValidTo   >= z.ValidFrom
        ORDER BY rr.ValidFrom DESC
    ) r
    OUTER APPLY (
        SELECT TOP (1) ss.StateName
        FROM [ATK].[mis].[Silver_RestructState_SCD] ss
        WHERE ss.CreditID = z.CreditID
          AND ss.ValidFrom <= z.ValidFrom
          AND ss.ValidTo   >= z.ValidFrom
        ORDER BY ss.ValidFrom DESC
    ) s
    OUTER APPLY (
        /* активный статус на начало среза */
        SELECT TOP (1) s2.[СтатусыКредитовВыданных Статус]
        FROM [ATK].[mis].[Bronze_РегистрыСведений.СтатусыКредитовВыданных] s2
        WHERE s2.[СтатусыКредитовВыданных Кредит ID] = z.CreditID
          AND s2.[СтатусыКредитовВыданных Активность] = 1
          AND CAST(s2.[СтатусыКредитовВыданных Период] AS date) <= z.ValidFrom
        ORDER BY s2.[СтатусыКредитовВыданных Период] DESC
    ) cs
),
stick AS (
    SELECT
        j.*,
        /* «липкость» некоммерческой реструктуризации */
        MAX(j.SeenNcHere) OVER (
            PARTITION BY j.CreditID
            ORDER BY j.ValidFrom
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS SeenNcCumulative
    FROM joined j
)
INSERT INTO [ATK].[mis].[Silver_Restruct_Merged_SCD]
    (CreditID, ValidFrom, ValidTo, TypeName, Reason, StateName, TypeName_Sticky, CreditStatus, ClientID)
SELECT
    st.CreditID,
    st.ValidFrom,
    st.ValidTo,
    st.TypeName,
    st.Reason,
    st.StateName,
    CASE WHEN st.SeenNcCumulative = 1
         THEN N'НекоммерческаяРеструктуризация'
         ELSE st.TypeName
    END AS TypeName_Sticky,
    st.CreditStatus,  -- добавили статус кредита на периоде
    cr.[Кредиты Владелец] AS ClientID
FROM stick st
LEFT JOIN [ATK].[mis].[Bronze_Справочники.Кредиты] cr
       ON cr.[Кредиты ID] = st.CreditID;
GO

/* (необязательно) Индексы для ускорения дальнейших расчётов */
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE object_id = OBJECT_ID('[ATK].[mis].[Silver_Restruct_Merged_SCD]')
                 AND name = 'IX_Merged_ForIntervals')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Merged_ForIntervals
        ON [ATK].[mis].[Silver_Restruct_Merged_SCD] (CreditID, ValidFrom)
        INCLUDE (ValidTo, StateName, TypeName, Reason, CreditStatus, TypeName_Sticky, ClientID);
END;
