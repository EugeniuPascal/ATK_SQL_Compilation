USE ATK;
GO

SET NOCOUNT ON;

IF OBJECT_ID('mis.Silver_Client_UnhealedFlag', 'U') IS NULL
BEGIN
    CREATE TABLE mis.Silver_Client_UnhealedFlag 
	(
        ClientID    VARCHAR(64) NOT NULL,
        SoldDate    DATE        NOT NULL,
        HasUnhealed BIT         NOT NULL,
        CONSTRAINT PK_Silver_Client_UnhealedFlag1 PRIMARY KEY (ClientID, SoldDate)
    );
END;

------------------------------------------------------------
-- 1) Prepare parameters
------------------------------------------------------------
DECLARE @DateFrom date = '2023-09-01';
DECLARE @DateTo   date = '2025-12-31';
DECLARE @Today    date = CAST(GETDATE() AS date);
IF (@DateTo > @Today) SET @DateTo = @Today;

------------------------------------------------------------
-- 2) Clean up existing data only in range
------------------------------------------------------------
DELETE FROM mis.Silver_Client_UnhealedFlag
WHERE SoldDate BETWEEN @DateFrom AND @DateTo;

------------------------------------------------------------
-- 3) Local table of dates
------------------------------------------------------------
IF OBJECT_ID('tempdb..#Dates','U') IS NOT NULL DROP TABLE #Dates;

;WITH N AS (
    SELECT TOP (DATEDIFF(day,@DateFrom,@DateTo)+1)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
SELECT DATEADD(day,n,@DateFrom) AS SoldDate
INTO #Dates
FROM N;

CREATE UNIQUE CLUSTERED INDEX CIX_Dates ON #Dates(SoldDate);

------------------------------------------------------------
-- 4) Insert only distinct client×day where conditions hold
------------------------------------------------------------
INSERT INTO mis.Silver_Client_UnhealedFlag 
           (ClientID, SoldDate, HasUnhealed)
SELECT m.ClientID, d.SoldDate, CAST(1 AS bit)
FROM #Dates d
JOIN (
    SELECT DISTINCT ClientID
    FROM mis.Silver_Restruct_Merged_SCD
    WHERE ClientID IS NOT NULL AND ClientID <> ''
) c ON 1=1
JOIN mis.Silver_Restruct_Merged_SCD m
  ON m.ClientID = c.ClientID
 AND d.SoldDate BETWEEN m.ValidFrom AND m.ValidTo
 AND m.TypeName_Sticky IS NOT NULL
 AND m.StateName = N'НеИзлеченный'
 AND LTRIM(RTRIM(m.CreditStatus)) IN (N'Выдан', N'Активен', N'Открыт')
GROUP BY m.ClientID, d.SoldDate;
