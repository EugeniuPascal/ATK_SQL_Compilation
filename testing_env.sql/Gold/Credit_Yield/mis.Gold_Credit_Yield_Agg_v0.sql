USE [ATK];
GO
SET NOCOUNT ON;

-- Drop table if exists
IF OBJECT_ID(N'mis.[Gold_Fact_Credit_Yield_Agg]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_Credit_Yield_Agg];
GO

-- Create table
CREATE TABLE mis.[Gold_Fact_Credit_Yield_Agg]
(
    CreditID       VARCHAR(36)    NOT NULL,
    AccountCtRRef  VARCHAR(36)    NOT NULL,
    Fld11925       VARCHAR(50)    NOT NULL,
    PeriodMonth    DATE           NOT NULL,  -- last day of the month
    Sum_Fld11923   DECIMAL(18, 2) NOT NULL,
    TotalYield     DECIMAL(18, 2) NULL,     -- appears only on the row with largest Sum_Fld11923

);
GO

-- Aggregate monthly sums
WITH MonthlyAgg AS
(
    SELECT
        CreditID,
        [_AccountCtRRef] AS AccountCtRRef,
        [_Fld11925]      AS Fld11925,
        EOMONTH([_Period]) AS PeriodMonth,
        SUM([_Fld11923]) AS Sum_Fld11923
    FROM [ATK].[mis].[Silver_Credit_Yield]
    --WHERE CreditID = 'b77f00155d65140c11eef7e7ec1e7a70'
      WHERE [_Period] >= '2024-11-01'
      AND [_AccountCtRRef] IN (
            'B8A9001CC441144C11E5FDB834628F2F', 
            'B8A9001CC441144C11E5FDB834628F23', 
            'B38C894C41AEE10B43EAFA590E4635D5',
            '88CEB222E1B1FCF94A954629A8B3928D',
            '80D600155D010F0111E6F34CC1101057'
      )
    GROUP BY
        CreditID,
        [_AccountCtRRef],
        [_Fld11925],
        EOMONTH([_Period])
),
MonthlyTotal AS
(
    SELECT
        CreditID,
        PeriodMonth,
        SUM(Sum_Fld11923) AS TotalYield,
        MAX(Sum_Fld11923) AS MaxSum  -- find the largest row
    FROM MonthlyAgg
    GROUP BY CreditID, PeriodMonth
)
-- Insert into final table
INSERT INTO mis.[Gold_Fact_Credit_Yield_Agg]
(
    CreditID,
    AccountCtRRef,
    Fld11925,
    PeriodMonth,
    Sum_Fld11923,
    TotalYield
)
SELECT
    m.CreditID,
    m.AccountCtRRef,
    m.Fld11925,
    m.PeriodMonth,
    m.Sum_Fld11923,
    CASE WHEN m.Sum_Fld11923 = t.MaxSum THEN t.TotalYield ELSE NULL END
FROM MonthlyAgg m
JOIN MonthlyTotal t
    ON m.CreditID = t.CreditID AND m.PeriodMonth = t.PeriodMonth
ORDER BY m.CreditID, m.PeriodMonth, m.AccountCtRRef, m.Fld11925;
GO
