USE ATK
USE ATK
GO
SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME LIKE 'Контрагенты Тестовый Контрагент'

SELECT 
TABLE_SCHEMA,
TABLE_NAME,
COLUMN_NAME, 
DATA_TYPE, 
CHARACTER_MAXIMUM_LENGTH, 
NUMERIC_PRECISION, 
NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
AND TABLE_NAME = 'Справочники.Контрагенты'
AND COLUMN_NAME = 'Контрагенты Тестовый Контрагент';

SELECT TOP (5) [ФормыПредприятия ID]
FROM [ATK].[dbo].[Справочники.ФормыПредприятия];

SELECT TOP (5) [ФормыПредприятия ID]
FROM [ATK].[dbo].[Справочники.Кредиты]

SELECT TOP (5) [ФормыПредприятия ID]
FROM [ATK].[dbo].[Справочники.ФормыПредприятия]
WHERE [ФормыПредприятия ID] IS NOT NULL;


SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME LIKE '%Кредиты ID%'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

SELECT 
COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
AND TABLE_NAME = 'Документы.ЗаявкаНаКредит';

SELECT 
    COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Документы.ЗаявкаНаКредит'
  AND (
        COLUMN_NAME LIKE 'ЗаявкаНаКредит Бизнес Сектор Экономики' OR
        COLUMN_NAME LIKE 'ЗаявкаНаКредит Вид Заявки' OR
        COLUMN_NAME LIKE 'ЗаявкаНаКредит Клиент ID' OR
        COLUMN_NAME LIKE 'ЗаявкаНаКредит Кредит ID' OR
        COLUMN_NAME LIKE 'ЗаявкаНаКредит Цель Кредита' OR
        COLUMN_NAME LIKE 'ЗаявкаНаКредит Это Зеленый Кредит'
      );

SELECT COUNT(*) AS TotalRows
FROM [ATK].[dbo].[Справочники.Контрагенты];

SELECT [Кредиты ID], COUNT(*) AS cnt
FROM [Dim_Credits]
GROUP BY [Кредиты ID]
HAVING COUNT(*) > 1;

--check if jobs RAN
EXEC msdb.dbo.sp_help_jobhistory 
    @job_name = 'usp_CompileSilverTables',
    @mode = 'FULL';
	
SELECT *
FROM [ATK].[mis].[2tbl_Gold_Dim_Employees]
WHERE HireDate IS NOT NULL
AND EmployeeID IS NOT NULL
AND BirthDate IS NOT NULL
AND DismissalDate IS NOT NULL
AND Position IS NOT NULL
AND TimesheetNumber IS NOT NULL
AND ExperienceYears IS NOT NULL
AND ExperienceMonths IS NOT NULL
AND EmploymentPeriod IS NOT NULL
AND EmployeePositionID IS NOT NULL
AND EmployeePosition IS NOT NULL
AND EmployeeCode IS NOT NULL
AND EmployeeName IS NOT NULL