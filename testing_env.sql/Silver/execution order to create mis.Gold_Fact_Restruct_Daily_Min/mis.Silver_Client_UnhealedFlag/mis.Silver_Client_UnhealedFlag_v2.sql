USE ATK;
GO

SET NOCOUNT ON;

IF OBJECT_ID('mis.Silver_Client_UnhealedFlag', 'U') IS NOT NULL
    TRUNCATE TABLE mis.Silver_Client_UnhealedFlag;
ELSE
BEGIN
    CREATE TABLE mis.Silver_Client_UnhealedFlag 
    (
        ClientID    VARCHAR(36) NOT NULL,
        SoldDate    DATE        NOT NULL,
        HasUnhealed BIT         NOT NULL,
        CONSTRAINT PK_Silver_Client_UnhealedFlag1 
            PRIMARY KEY (ClientID, SoldDate)
    );
END;

------------------------------------------------------------
-- 1) Generate dates from 2015-01-01 to today
------------------------------------------------------------

IF OBJECT_ID('tempdb..#Dates','U') IS NOT NULL DROP TABLE #Dates;

;WITH N AS (
    SELECT TOP (DATEDIFF(day, '2015-01-01', CAST(GETDATE() AS date)) + 1)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.all_objects a 
    CROSS JOIN sys.all_objects b
)
SELECT DATEADD(day, n, '2015-01-01') AS SoldDate
INTO #Dates
FROM N;

CREATE UNIQUE CLUSTERED INDEX CIX_Dates ON #Dates(SoldDate);

------------------------------------------------------------
-- 2) Insert daily unhealed flags
------------------------------------------------------------

INSERT INTO mis.Silver_Client_UnhealedFlag 
           (ClientID, SoldDate, HasUnhealed)
SELECT m.ClientID, d.SoldDate, CAST(1 AS bit)
FROM #Dates d
JOIN mis.Silver_Restruct_Merged_SCD m
  ON d.SoldDate BETWEEN m.ValidFrom AND m.ValidTo
 AND m.TypeName_Sticky IS NOT NULL
 AND m.StateName = N'НеИзлеченный'
 AND LTRIM(RTRIM(m.CreditStatus)) IN (N'Выдан', N'Активен', N'Открыт')
WHERE m.ClientID IS NOT NULL
  AND m.ClientID <> ''
GROUP BY m.ClientID, d.SoldDate;