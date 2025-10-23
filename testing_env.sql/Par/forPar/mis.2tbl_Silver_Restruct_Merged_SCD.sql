-- Создаём/очищаем объединённую таблицу Silver
IF OBJECT_ID('[ATK].[mis].[2tbl_Silver_Restruct_Merged_SCD]','U') IS NULL
    CREATE TABLE [ATK].[mis].[2tbl_Silver_Restruct_Merged_SCD] (
        CreditID        varchar(64)   NOT NULL,
        ValidFrom       date          NOT NULL,
        ValidTo         date          NOT NULL,
        TypeName        nvarchar(200) NULL,
        Reason          nvarchar(500) NULL,
        StateName       nvarchar(200) NULL,
        TypeName_Sticky nvarchar(200) NULL,   -- «Некоммерческая…» прилипает вперёд
        CONSTRAINT PK_Silver_Restruct_Merged_SCD PRIMARY KEY (CreditID, ValidFrom)
    );
ELSE
    TRUNCATE TABLE [ATK].[mis].[2tbl_Silver_Restruct_Merged_SCD];
GO
 
;WITH borders AS (
    SELECT CreditID, ValidFrom FROM [ATK].[mis].[2tbl_Silver_Restruct_SCD]
    UNION
    SELECT CreditID, ValidFrom FROM [ATK].[mis].[2tbl_Silver_RestructState_SCD]
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
joined AS (
    SELECT
        z.CreditID,
        z.ValidFrom,
        z.ValidTo,
 
        -- подтягиваем активный на начало среза тип/причину + флаг NonCommSeenUpTo
        r.TypeName,
        r.Reason,
        r.NonCommSeenUpTo,
 
        -- подтягиваем активное состояние
        s.StateName,
 
        -- локальный флаг «видели ли Некоммерческую к этому срезу»
        COALESCE(r.NonCommSeenUpTo, 0) AS SeenNcHere
    FROM slices z
    OUTER APPLY (
        SELECT TOP (1) rr.TypeName, rr.Reason, rr.NonCommSeenUpTo
        FROM [ATK].[mis].[2tbl_Silver_Restruct_SCD] rr
        WHERE rr.CreditID = z.CreditID
          AND rr.ValidFrom <= z.ValidFrom
          AND rr.ValidTo   >= z.ValidFrom
        ORDER BY rr.ValidFrom DESC
    ) AS r
    OUTER APPLY (
        SELECT TOP (1) ss.StateName
        FROM [ATK].[mis].[2tbl_Silver_RestructState_SCD] ss
        WHERE ss.CreditID = z.CreditID
          AND ss.ValidFrom <= z.ValidFrom
          AND ss.ValidTo   >= z.ValidFrom
        ORDER BY ss.ValidFrom DESC
    ) AS s
),
stick AS (
    SELECT
        j.*,
        -- «липкость» как накопительный максимум по кредиту
        MAX(j.SeenNcHere) OVER (
            PARTITION BY j.CreditID
            ORDER BY j.ValidFrom
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS SeenNcCumulative
    FROM joined j
)
INSERT INTO [ATK].[mis].[2tbl_Silver_Restruct_Merged_SCD]
    (CreditID, ValidFrom, ValidTo, TypeName, Reason, StateName, TypeName_Sticky)
SELECT
    CreditID,
    ValidFrom,
    ValidTo,
    TypeName,
    Reason,
    StateName,
    CASE WHEN SeenNcCumulative = 1
         THEN N'НекоммерческаяРеструктуризация'
         ELSE TypeName
    END AS TypeName_Sticky
FROM stick;
GO