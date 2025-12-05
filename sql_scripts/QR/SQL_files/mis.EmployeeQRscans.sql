USE [ATK];
SET NOCOUNT ON;

-- Step 1: Create target table if it doesn't exist
IF OBJECT_ID('[mis].[EmployeeQRscans]', 'U') IS NULL
BEGIN
    CREATE TABLE [mis].[EmployeeQRscans] 
	(
        EmployeeID VARCHAR(50) NOT NULL PRIMARY KEY,
        EmployeeName NVARCHAR(200) NULL,
        BranchID VARCHAR(50) NULL,
        BranchName NVARCHAR(200) NULL,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE()
    );
END

-- Step 2: Insert distinct employees from source table, ignoring duplicates
;WITH LatestEmployees AS (
    SELECT
        [ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS EmployeeID,
        [ОтветственныеПоКредитамВыданным Кредитный Эксперт] AS EmployeeName,
        [ОтветственныеПоКредитамВыданным Филиал ID] AS BranchID,
        [ОтветственныеПоКредитамВыданным Филиал] AS BranchName,
        ROW_NUMBER() OVER (
            PARTITION BY [ОтветственныеПоКредитамВыданным Кредитный Эксперт ID]
            ORDER BY [ОтветственныеПоКредитамВыданным Филиал ID] DESC
        ) AS rn
    FROM [ATK].[mis].[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным]
    WHERE [ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] IS NOT NULL
      AND [ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] <> '00000000000000000000000000000000'
)
INSERT INTO mis.EmployeeQRscans (EmployeeID, EmployeeName, BranchID, BranchName)
SELECT EmployeeID, EmployeeName, BranchID, BranchName
FROM LatestEmployees
WHERE rn = 1
  AND NOT EXISTS (
      SELECT 1 
      FROM mis.EmployeeQRscans e
      WHERE e.EmployeeID = LatestEmployees.EmployeeID
  );

-- Step 3: Confirm inserted rows
SELECT COUNT(*) AS TotalEmployees FROM mis.EmployeeQRscans;
SELECT * FROM mis.EmployeeQRscans;
