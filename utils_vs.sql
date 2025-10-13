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



SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME LIKE 'СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки МСФО'

СекторыЭкономики Основной Раздел'

СекторыЭкономики Сектор Экономики EFSE'



SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME LIKE 'Контрагенты Сектор Экономики'

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
AND COLUMN_NAME = 'Контрагенты Сектор Экономики';

SELECT 
COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
AND TABLE_NAME = 'РегистрыСведений.СведенияОНаправленияхНаВыплату';

SELECT COUNT(*) FROM [ATK].[dbo].[Задачи.ЗадачаАдминистратораКредитов]
--98 193
SELECT COUNT(*) FROM [ATK].[dbo].[Задачи.ЗадачаАдминистратораКредитов.ИсторияСтатусов]
--411 279


SELECT TOP (5) *
FROM [ATK].[dbo].[Задачи.ЗадачаАдминистратораКредитов]

SELECT TOP (5) *
FROM [ATK].[dbo].[Задачи.ЗадачаАдминистратораКредитов.ИсторияСтатусов]

SELECT TOP (5) *
FROM [ATK].[dbo].[Справочники.ТипыЗадачАдминистратораКредитов]

SELECT TOP (5) *
FROM [ATK].[dbo].[Справочники.ТипыЗадачАдминистратораКредитов_ИсторияПоказателей]

SELECT TOP (5) *
FROM [ATK].[dbo].[Документы.НаправлениеНаВыплату]

SELECT TOP (5) *
FROM [ATK].[dbo].[РегистрыСведений.СведенияОНаправленияхНаВыплату]

SELECT a.[ЗадачаАдминистратораКредитов Тип Задачи ID], 
       a.[ЗадачаАдминистратораКредитов Кредит ID],
	   a.[ЗадачаАдминистратораКредитов ID],
       t.[ТипыЗадачАдминистратораКредитов ID],
       s.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID], 
       s2.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID], 
	   s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID],
	   hist.[ТипыЗадачАдминистратораКредитов ID], 
	   pay.[СведенияОНаправленияхНаВыплату Направление на Выплату ID],
	   doc.[НаправлениеНаВыплату Кредит ID],
	   doc.[НаправлениеНаВыплату ID]
FROM [ATK].[dbo].[Задачи.ЗадачаАдминистратораКредитов] AS a
INNER JOIN [ATK].[dbo].[Справочники.ТипыЗадачАдминистратораКредитов] AS t
  ON a.[ЗадачаАдминистратораКредитов Тип Задачи ID] = t.[ТипыЗадачАдминистратораКредитов ID]
INNER JOIN [ATK].[dbo].[Задачи.ЗадачаАдминистратораКредитов.ИсторияСтатусов] AS s
  ON  s.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID] = a.[ЗадачаАдминистратораКредитов ID]
INNER JOIN [ATK].[dbo].[Задачи.ЗадачаАдминистратораКредитов.ИсторияСтатусов] AS s2
  ON s2.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID] = a.[ЗадачаАдминистратораКредитов ID]
INNER JOIN [ATK].[dbo].[Задачи.ЗадачаАдминистратораКредитов.ИсторияСтатусов] AS s3
  ON s3.[ЗадачаАдминистратораКредитов.ИсторияСтатусов ID] = a.[ЗадачаАдминистратораКредитов ID]
INNER JOIN [ATK].[dbo].[Справочники.ТипыЗадачАдминистратораКредитов_ИсторияПоказателей] AS hist
  ON hist.[ТипыЗадачАдминистратораКредитов ID] = t.[ТипыЗадачАдминистратораКредитов ID]
INNER JOIN [ATK].[dbo].[Документы.НаправлениеНаВыплату] AS doc
  ON doc.[НаправлениеНаВыплату Кредит ID] = a.[ЗадачаАдминистратораКредитов Кредит ID]
INNER JOIN [ATK].[dbo].[РегистрыСведений.СведенияОНаправленияхНаВыплату] AS pay
  ON pay.[СведенияОНаправленияхНаВыплату Направление на Выплату ID] = doc.[НаправлениеНаВыплату ID];


SELECT TOP (5) *
  FROM [ATK].[mis].[2tbl_Gold_Fact_AdminTasks]
  WHERE StatusHistory_Status <> 'ВыполненаБезуспешно'
  AND StatusHistory_Status <> 'ВыполненаУспешно'
  WHERE [AdminTask_Number] = '000093327'


SELECT TOP (5) *
FROM [ATK].[dbo].[Справочники.ТипыЗадачАдминистратораКредитов]
WHERE [ТипыЗадачАдминистратораКредитов ID] = '812800155D65040111ECEA7FC384A9B3'


SELECT TOP (5) *
FROM [ATK].[dbo].[Справочники.ТипыЗадачАдминистратораКредитов_ИсторияПоказателей]
--WHERE [ТипыЗадачАдминистратораКредитов_ИсторияПоказателей Номер Строки] = 3
WHERE [ТипыЗадачАдминистратораКредитов ID] = '812800155D65040111ECEA7FC384A9B3'

SELECT TOP (5) *
FROM [ATK].[dbo].[Задачи.ЗадачаАдминистратораКредитов] 
--WHERE [ТипыЗадачАдминистратораКредитов_ИсторияПоказателей Номер Строки] = 3
WHERE [ЗадачаАдминистратораКредитов Тип Задачи ID] = '812800155D65040111ECEA7FC384A9B3'


SELECT TOP (5)*
FROM [ATK].[dbo].[Справочники.ТипыЗадачАдминистратораКредитов] a
INNER JOIN [ATK].[dbo].[Справочники.ТипыЗадачАдминистратораКредитов_ИсторияПоказателей] b
ON a.[ТипыЗадачАдминистратораКредитов ID] = b.[ТипыЗадачАдминистратораКредитов ID]
WHERE a.[ТипыЗадачАдминистратораКредитов ID] = '812800155D65040111ECEA7FC384A9B3'


SELECT TOP (5) *
  FROM [ATK].[mis].[2tbl_Gold_Fact_AdminTasks]
  WHERE AdminTask_TaskCount = '0'
  WHERE [AdminTask_Date] BETWEEN '2025-09-01' AND '2025-09-30'

  SELECT COUNT(AdminTask_TaskCount) AS TaskNumber
   FROM [ATK].[mis].[2tbl_Gold_Fact_AdminTasks]
  -- WHERE [AdminTask_TaskCount] = 0
  WHERE [AdminTask_Date] BETWEEN '2025-09-01' AND '2025-09-30'
  AND StatusHistory_User = 'Diana Griu'
  AND AdminTask_Type = 'Altele'

  				

  SELECT *
  FROM [ATK].[mis].[2tbl_Gold_Fact_AdminTasks]
  WHERE AdminTask_Number = '000093517'
  WHERE [AdminTask_Date] BETWEEN '2025-09-01' AND '2025-09-30'




pentru soldPar de fixat


SELECT *
FROM [ATK].[dbo].[РегистрыСведений.СостоянияРеструктурированныхКредитов]
WHERE [СостоянияРеструктурированныхКредитов Кредит ID] = '812100155D65040111ECC06922E57355'
ORDER BY [СостоянияРеструктурированныхКредитов Период] ASC

SELECT *
FROM [ATK].[dbo].[РегистрыСведений.РеструктурированныеКредиты]
--WHERE [РеструктурированныеКредиты Период] > '2024-01-01'
WHERE [РеструктурированныеКредиты Кредит ID] = '812100155D65040111ECC06922E57355'
ORDER BY [РеструктурированныеКредиты Период] ASC

SELECT SoldDate, RestructuredCreditState, RestructuringReason, RestructuringDebtType
FROM mis.[2tbl_Gold_Fact_Sold_Par]
WHERE CreditID = '812100155D65040111ECC06922E57355'
ORDER BY SoldDate ASC


SELECT [РеструктурированныеКредиты Кредит ID], COUNT(*) AS CreditCount
FROM [ATK].[dbo].[РегистрыСведений.РеструктурированныеКредиты]
WHERE [РеструктурированныеКредиты Период] > '2024-01-01'
GROUP BY [РеструктурированныеКредиты Кредит ID]
HAVING COUNT(*) > 1;


SELECT a.CreditID, b.[РеструктурированныеКредиты Кредит ID], c.[СостоянияРеструктурированныхКредитов Кредит ID]
FROM mis.[2tbl_Gold_Fact_Sold_Par] AS a
INNER JOIN [ATK].[dbo].[РегистрыСведений.РеструктурированныеКредиты] AS b
ON a.CreditID = b.[РеструктурированныеКредиты Кредит ID]
INNER JOIN [ATK].[dbo].[РегистрыСведений.СостоянияРеструктурированныхКредитов] AS c
ON a.CreditID = c.[СостоянияРеструктурированныхКредитов Кредит ID]


SELECT [СостоянияРеструктурированныхКредитов Кредит ID]
FROM [ATK].[dbo].[РегистрыСведений.СостоянияРеструктурированныхКредитов]
GROUP BY [СостоянияРеструктурированныхКредитов Кредит ID]
HAVING 
    COUNT(DISTINCT [СостоянияРеструктурированныхКредитов Состояние Реструктурированного Кредита]) > 1;


СостоянияРеструктурированныхКредитов Состояние Реструктурированного Кредита
НеИзлеченный
Излеченный

-- CTE for credits with more than one state
WITH MultipleStates AS (
    SELECT [СостоянияРеструктурированныхКредитов Кредит ID] AS CreditID
    FROM [ATK].[dbo].[РегистрыСведений.СостоянияРеструктурированныхКредитов]
    GROUP BY [СостоянияРеструктурированныхКредитов Кредит ID]
    HAVING COUNT(DISTINCT [СостоянияРеструктурированныхКредитов Состояние Реструктурированного Кредита]) > 1
)

-- Join with Sold_Par table
SELECT sp.*
FROM mis.[2tbl_Gold_Fact_Sold_Par] sp
INNER JOIN MultipleStates ms
    ON sp.CreditID = ms.CreditID
ORDER BY sp.SoldDate DESC;


WITH MultiRestructured AS (
    SELECT [РеструктурированныеКредиты Кредит ID] AS CreditID
    FROM [ATK].[dbo].[РегистрыСведений.РеструктурированныеКредиты]
    WHERE [РеструктурированныеКредиты Период] > '2024-01-01'
    GROUP BY [РеструктурированныеКредиты Кредит ID]
    HAVING COUNT(*) > 1
),
MultiState AS (
    SELECT [СостоянияРеструктурированныхКредитов Кредит ID] AS CreditID
    FROM [ATK].[dbo].[РегистрыСведений.СостоянияРеструктурированныхКредитов]
    WHERE [СостоянияРеструктурированныхКредитов Период] > '2024-01-01'
    GROUP BY [СостоянияРеструктурированныхКредитов Кредит ID]
    HAVING COUNT(*) > 1
)
SELECT m.CreditID
FROM MultiRestructured m
INNER JOIN MultiState s ON m.CreditID = s.CreditID;
