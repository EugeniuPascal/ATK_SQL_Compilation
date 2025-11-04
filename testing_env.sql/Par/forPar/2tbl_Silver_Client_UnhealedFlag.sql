USE [ATK];
GO
SET NOCOUNT ON;

------------------------------------------------------------
-- 0) Ensure target table exists
------------------------------------------------------------
IF OBJECT_ID('[ATK].[mis].[2tbl_Silver_Client_UnhealedFlag1]', 'U') IS NULL
BEGIN
    CREATE TABLE [ATK].[mis].[2tbl_Silver_Client_UnhealedFlag1] (
        ClientID    VARCHAR(64) NOT NULL,
        SoldDate    DATE        NOT NULL,
        HasUnhealed BIT         NOT NULL,
        CONSTRAINT PK_Silver_Client_UnhealedFlag1 PRIMARY KEY (ClientID, SoldDate)
    );
END
GO

------------------------------------------------------------
-- 1) Prepare parameters
------------------------------------------------------------
DECLARE @DateFrom date = '2024-01-01';
DECLARE @DateTo   date = '2025-12-31';
DECLARE @Today    date = CAST(GETDATE() AS date);
IF (@DateTo > @Today) SET @DateTo = @Today;

------------------------------------------------------------
-- 2) Clean up existing data only in range
------------------------------------------------------------
DELETE FROM [ATK].[mis].[2tbl_Silver_Client_UnhealedFlag1]
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
INSERT INTO [ATK].[mis].[2tbl_Silver_Client_UnhealedFlag1] (ClientID, SoldDate, HasUnhealed)
SELECT m.ClientID, d.SoldDate, CAST(1 AS bit)
FROM #Dates d
JOIN (
    SELECT DISTINCT ClientID
    FROM [ATK].[mis].[2tbl_Silver_Restruct_Merged_SCD1]
    WHERE ClientID IS NOT NULL AND ClientID <> ''
) c ON 1=1
JOIN [ATK].[mis].[2tbl_Silver_Restruct_Merged_SCD1] m
  ON m.ClientID = c.ClientID
 AND d.SoldDate BETWEEN m.ValidFrom AND m.ValidTo
 AND m.TypeName_Sticky IS NOT NULL
 AND m.StateName = N'НеИзлеченный'
 AND LTRIM(RTRIM(m.CreditStatus)) IN (N'Выдан', N'Активен', N'Открыт')
GROUP BY m.ClientID, d.SoldDate;
