USE ATK;
GO
SET NOCOUNT ON;

------------------------------------------------------------
-- 0) Ensure table exists
------------------------------------------------------------
IF OBJECT_ID('mis.Silver_Restruct_Merged_SCD','U') IS NULL
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
           COALESCE(DATEADD(day,-1, NextFrom), CONVERT(DATE,'9999-12-31')) AS ValidTo
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
       CASE WHEN st.SeenNcCumulative = 1 THEN N'НекоммерческаяРеструктуризация'
            ELSE st.TypeName END AS TypeName_Sticky,
       st.CreditStatus,
       cr.[Кредиты Владелец] AS ClientID
FROM stick st
LEFT JOIN mis.[Bronze_Справочники.Кредиты] cr
       ON cr.[Кредиты ID] = st.CreditID;

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID('mis.Silver_Restruct_Merged_SCD')
      AND name = 'IX_Merged_ForIntervals')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Merged_ForIntervals
        ON mis.Silver_Restruct_Merged_SCD (CreditID, ValidFrom)
        INCLUDE (ValidTo, StateName, TypeName, Reason, CreditStatus, TypeName_Sticky, ClientID);
END;
