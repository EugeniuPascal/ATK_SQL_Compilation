
[ФилиалыКонтрагентов ID] = [Дилеры Владелец]
[ФилиалыКонтрагентов Владелец] = [Контрагенты ID]

--- IF SOMETHING WRONG AROUND THE DATES always check if Datetime si compaired do Date
USE ATK
GO
SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME LIKE 'Контрагенты Тестовый Контрагент'

SELECT TABLE_SCHEMA, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
AND TABLE_NAME = 'РегистрыСведений.ДанныеКредитовВыданных'
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

  				


SELECT 
    [УстановкаДанныхКредита Кредит ID],
    COUNT(DISTINCT [УстановкаДанныхКредита Ставка Процента]) AS CountDistinctRates
FROM dbo.[Документы.УстановкаДанныхКредита]
GROUP BY [УстановкаДанныхКредита Кредит ID]
HAVING COUNT(DISTINCT [УстановкаДанныхКредита Ставка Процента]) > 1


pentru soldPar de fixat

SELECT [СостоянияРеструктурированныхКредитов Период],[СостоянияРеструктурированныхКредитов Состояние Реструктурированного Кредита]
FROM [ATK].[dbo].[РегистрыСведений.СостоянияРеструктурированныхКредитов]
WHERE [СостоянияРеструктурированныхКредитов Кредит ID] = '810A00155D65040111EC3D57E9373288'
ORDER BY [СостоянияРеструктурированныхКредитов Период] ASC

SELECT [РеструктурированныеКредиты Период],[РеструктурированныеКредиты Причина Реструктуризации], [РеструктурированныеКредиты Тип Реструктуризации Долга]
FROM [ATK].[dbo].[РегистрыСведений.РеструктурированныеКредиты]
--WHERE [РеструктурированныеКредиты Период] > '2024-01-01'
WHERE [РеструктурированныеКредиты Кредит ID] = '810A00155D65040111EC3D57E9373288'
ORDER BY [РеструктурированныеКредиты Период] ASC

SELECT SoldDate, RestructuredCreditState, RestructuringReason, RestructuringDebtType,IRR_Values
Par_0_IFRS, Par_30_IFRS, Par_60_IFRS, Par_90_IFRS
FROM mis.[2tbl_Gold_Fact_Sold_Par1]
--WHERE[СуммыЗадолженностиПоПериодамПросрочки Клиент ID] = '80E900155D65040111EAD70139702DB2'
WHERE CreditID = '812100155D65040111ECC06922E57355' ORDER BY SoldDate ASC

SELECT TOP (5) * FROM mis.[Silver_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки];
SELECT TOP (5) * FROM mis.[Silver_Справочники.Кредиты]
SELECT TOP (5) * FROM mis.[Silver_РегистрыСведений.КредитыВТеневыхФилиалах]
SELECT TOP (5) * FROM mis.[Silver_РегистрыСведений.ОтветственныеПоКредитамВыданным]
SELECT TOP (5) * FROM mis.[Silver_РегистрыСведений.СотрудникиДанныеПоЗарплате]
SELECT TOP (5) * FROM mis.[Silver_Документы.УстановкаДанныхКредита]
SELECT TOP (5) * FROM mis.[Silver_РегистрыСведений.СостоянияРеструктурированныхКредитов]
SELECT TOP (5) * FROM mis.[Silver_РегистрыСведений.РеструктурированныеКредиты]

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

SELECT [СостоянияРеструктурированныхКредитов Период],[СостоянияРеструктурированныхКредитов Состояние Реструктурированного Кредита]
FROM [ATK].[dbo].[РегистрыСведений.СостоянияРеструктурированныхКредитов]
WHERE [СостоянияРеструктурированныхКредитов Период] IS NULL

SELECT [СостоянияРеструктурированныхКредитов Период],[СостоянияРеструктурированныхКредитов Состояние Реструктурированного Кредита]
FROM [ATK].[dbo].[РегистрыСведений.СостоянияРеструктурированныхКредитов]

WHERE [СостоянияРеструктурированныхКредитов Период] IS NULL

SELECT
    [УстановкаДанныхКредита Кредит ID],
    [УстановкаДанныхКредита Дата],
    COUNT(*) AS RecordCount
FROM mis.[Silver_Документы.УстановкаДанныхКредита]
GROUP BY
    [УстановкаДанныхКредита Кредит ID],
    [УстановкаДанныхКредита Дата]
HAVING COUNT(*) > 1;

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM mis.[Silver_Документы.УстановкаДанныхКредита]
            GROUP BY [УстановкаДанныхКредита Кредит ID], [УстановкаДанныхКредита Дата]
            HAVING COUNT(*) > 1
        ) THEN '❌ Duplicates exist'
        ELSE '✅ All unique'
    END AS Result;

SELECT * FROM mis.[2tbl_Gold_Fact_Sold_Par]
WHERE CreditID = '810900155D65040111EC1C7EBA15B471'


  SELECT TOP (1000) [ОтветственныеПоКредитамВыданным Период]

      ,[ОтветственныеПоКредитамВыданным Кредит ID]
      ,[ОтветственныеПоКредитамВыданным Кредит]
      ,[ОтветственныеПоКредитамВыданным ID]
      ,[ОтветственныеПоКредитамВыданным Активность]
      ,[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID]
      ,[ОтветственныеПоКредитамВыданным Филиал ID]
      ,[ОтветственныеПоКредитамВыданным Номер Строки]
      ,[ОтветственныеПоКредитамВыданным Филиал]
      ,[ОтветственныеПоКредитамВыданным Кредитный Эксперт]
  FROM [ATK].[mis].[Silver_РегистрыСведений.ОтветственныеПоКредитамВыданным]
  where [ОтветственныеПоКредитамВыданным Кредит ID] = '810900155D65040111EC1C7EBA15B471'

  /*SELECT TOP (5) * FROM mis.[Silver_РегистрыСведений.СотрудникиДанныеПоЗарплате]
SELECT TOP (5) * FROM mis.[Silver_РегистрыСведений.КредитыВТеневыхФилиалах]
SELECT TOP (5) * FROM mis.[Silver_Документы.УстановкаДанныхКредита]
SELECT TOP (5) * FROM mis.[Silver_РегистрыСведений.РеструктурированныеКредиты]*/

SELECT *
FROM [ATK].[mis].[2tbl_Gold_Fact_Sold_Par2]
WHERE [CreditID] IN (
'810900155D65040111EC2C0E0E1C45E4',
'B7C900155D65140C11EFF35114382BB1',
'810900155D65040111EC30D141C07DD6',
'810A00155D65040111EC36EF2177D72E',
'810A00155D65040111EC3D57E9373288',
'810B00155D65040111EC422BD61DAC0A',
'811900155D65040111EC93D6BF9D3695',
'813F00155D65040111ED3FCD43679F7E',
'B72B00155D65140C11ED869B127655AB',
'B72F00155D65140C11EDA62A250B2676',
'B73900155D65140C11EDC70416B16A23',
'B7B400155D65140C11EFA6637B9B7419'
 
)
AND [SoldDate] = '2025-07-31';

SELECT * FROM dbo.[РегистрыСведений.РеструктурированныеКредиты]
WHERE [РеструктурированныеКредиты Кредит ID] = '810900155D65040111EC2C0E0E1C45E4'


SELECT *
FROM [ATK].[mis].[2tbl_Gold_Fact_Sold_Par]



USE [ATK];
GO

SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    i.name AS IndexName,
    CASE 
        WHEN i.type = 1 THEN 'CLUSTERED'
        WHEN i.type = 2 THEN 'NONCLUSTERED'
        WHEN i.type = 3 THEN 'XML'
        WHEN i.type = 4 THEN 'SPATIAL'
        ELSE 'OTHER'
    END AS IndexType,
    i.is_unique,
    i.is_primary_key,
    i.fill_factor,
    i.allow_page_locks,
    i.allow_row_locks
FROM sys.indexes i
JOIN sys.tables t
    ON i.object_id = t.object_id
JOIN sys.schemas s
    ON t.schema_id = s.schema_id
WHERE s.name = 'mis'
  AND i.index_id > 0  -- exclude heaps (index_id = 0)
ORDER BY t.name, i.index_id;





SELECT TOP (1000) [SoldDate]
      ,[ClientID]
      ,[CreditID]
      ,[SoldAmount]
      ,[NumberOfOverdueDaysIFRS]
      ,---[IRR_Values] 
      ,[BranchShadow]
      ,[EmployeeID] in resp_scd
      ,[BranchID] in resp_scd
      ,---[EmployeePositionID] 
      ,[Par]
  FROM [ATK].[mis].[Gold_Fact_Sold_Par]
  
  

 
SELECT * 
  FROM [ATK].[mis].[Gold_Fact_Restruct_Daily_Min_test]
  ORDER BY SoldDate DESC;


   SELECT t1.*,
         t2.*
 FROM [ATK].[mis].[Gold_Fact_Restruct_Daily_Min] t1
 INNER JOIN [ATK].[mis].[Gold_Fact_Sold_Par] t2
    ON t1.CreditID = t2.CreditID
	WHERE t1.CreditID = 'B75C00155D65140C11EE6E5FB1250276'
   AND t1.ClientID = t2.ClientID
   AND t1.SoldDate = t2.SoldDate
  ORDER BY t1.SoldDate DESC;
  
  
  ------------------------------------------------------------------------------------------------------------------------
  
  
  SELECT [ЗаявкаНаКредит ID], [ЗаявкаНаКредит Кредит ID]
  FROM [ATK].[mis].[Bronze_Документы.ЗаявкаНаКредит]
  WHERE [ЗаявкаНаКредит ID] = 'B7FD00155D65140C11F0B32251E18C26'
  

SELECT [ОбъединеннаяИнтернетЗаявка ID], [ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
  FROM [ATK].[mis].[Bronze_Документы.ОбъединеннаяИнтернетЗаявка]
  WHERE [ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]='B7FD00155D65140C11F0B32251E18C26'
  

  SELECT * FROM dbo.[Документы.ОбъединеннаяИнтернетЗаявка.РискФакторы]
  WHERE [ОбъединеннаяИнтернетЗаявка ID]= 'B7FD00155D65140C11F0B32251E18C23'
  AND [ОбъединеннаяИнтернетЗаявка.РискФакторы Риск Фактор ID] IN (
        'B74000155D65140C11EDEA76A63D59BC',
        '9DCB83734038510A448E495536F415C8',
        '810500155D65040111EC119B4AF60D86')




  SELECT TOP (1000) [CreditID]
      ,[Owner],[Code] ,[Name],[IssueDate],[Term] ,[Amount] ,[EconomicSectorDetailed] ,[FinancialProductID],[FinancialProduct],[AgroCredit],[LocalityType]
      ,[Currency],[ProductID] ,[Product] ,[Purpose],[RemoveFundingSource],[ContractType],[ContractDate],[IncomeSegment]
      ,[UsagePurpose],[PurposeDescription] ,[ProductType],[EconomicUsageArea]
      ,[SigningSource],[FinancialProductsMainGroup],[IssuedCreditsStatus],[CreditApplicationPartnerID]
      ,[CreditPartnerName],[FirstFilialID],[FirstEmployeeID],[LastFilialID]
      ,[LastEmployeeID],[DealerID],[Source],[LatestOutstandingAmount],[SegmentRevenue]
      ,[GreenCredit],[CommitteeProt_CrPurpose],[CommitteeProt_AMLRiskCat],[DigitalSign],[EconomicSectorEFSE],[EconomicSector],[Agro],[IsFormal]
  FROM [ATK].[mis].[Gold_Dim_Credits]
  WHERE CreditID = 'B7FD00155D65140C11F0B32251E18C25'


  SELECT DISTINCT [ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID]
FROM [ATK].[mis].[Bronze_Документы.ОбъединеннаяИнтернетЗаявка]
WHERE [ОбъединеннаяИнтернетЗаявка Заявка на Кредит ID] LIKE 'B7FD00155D65140C11F0B32251E18C%';

---------------------------------------------------------------------------------------------------------------
SELECT TABLE_SCHEMA, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
AND TABLE_NAME LIKE 'РегистрыБухгалтерии.РегистрПланСчетовОсновной'

  FROM dbo.[РегистрыБухгалтерии.РегистрПланСчетовОсновной]
 -- WHERE [РегистрПланСчетовОсновной ПериодДата] BETWEEN '2025-03-01' AND '2025-03-31' 
 -- AND [РегистрПланСчетовОсновной Содержание] LIKE '%24070004842'

  --AND [РегистрПланСчетовОсновной Счет Дт ID] = 'b77f00155d65140c11eef7e7ec1e7a70'
  --AND [РегистрПланСчетовОсновной Счет Дт ID] = 'b77f00155d65140c11eef7e7ec1e7a70'
  WHERE [РегистрПланСчетовОсновной ID] = '80490018FEFB2E3711DC9DC660C6E26D'
  --WHERE [РегистрПланСчетовОсновной Счет Кт ID] = 'b77f00155d65140c11eef7e7ec1e7a70'
  
  
  
  	SELECT TOP (1000) [_Period]
      ,[_RecorderTRef]
      ,[_RecorderRRef]
      ,[_LineNo]
      ,[_Active]
      ,[_AccountDtRRef]
      ,[_AccountCtRRef]
      ,[_Fld11918DtRRef]
      ,[_Fld11918CtRRef]
      ,[_Fld11919RRef]
      ,[_Fld11920]
      ,[_Fld11921Dt]
      ,[_Fld11921Ct]
      ,[_Fld11922Dt]
      ,[_Fld11922Ct]
      ,[_Fld11923]
      ,[_Fld11924Dt]
      ,[_Fld11924Ct]
      ,[_Fld11925]
      ,[_Fld11926RRef]
      ,[_ValueDt1_TYPE]
      ,[_ValueDt1_RTRef]
      ,[_ValueDt1_RRRef]
      ,[_KindDt1RRef]
      ,[_ValueCt1_TYPE]
      ,[_ValueCt1_RTRef]
      ,[_ValueCt1_RRRef]
      ,[_KindCt1RRef]
      ,[_ValueDt2_TYPE]
      ,[_ValueDt2_RTRef]
      ,[_ValueDt2_RRRef]
      ,[_KindDt2RRef]
      ,[_ValueCt2_TYPE]
      ,[_ValueCt2_RTRef]
      ,[_ValueCt2_RRRef]
      ,[_KindCt2RRef]
      ,[_ValueDt3_TYPE]
      ,[_ValueDt3_RTRef]
      ,[_ValueDt3_RRRef]
      ,[_KindDt3RRef]
      ,[_ValueCt3_TYPE]
      ,[_ValueCt3_RTRef]
      ,[_ValueCt3_RRRef]
      ,[_KindCt3RRef]
  FROM [Microinvest_Copy_Full].[dbo].[_AccRg11917]
--- where [_Fld11925] = N'Sporirea com. de adm. Vasilatii Iurie Cr.: 2234036'
  --where [_ValueDt2_RRRef] =0x812800155D65040111ECED6655ECF45A
  --AND [_RecorderRRef] = 0xB72100155D65140C11ED54711641D562
  where [_ValueDt2_RRRef] = 0x812500155d65040111ece1892bc9762d
  AND _Period >= '2022-09-07T00:00:00'
  AND _Period < '2022-09-08T00:00:00'
  
  
  [_ValueDt2_RRRef] = 0x812500155d65040111ece1892bc9762d = CreditID
  
  
  
  
  /* ============================================================
   Fact_PenaltiesDaily (single-credit build, optimized)
   + Stornare из Fact_PenaltiesNegAdj
   + Penalitate_Achitat считается по счёту …E3F (как Penalitate_SprePlata)
   + Rezerva_suma считается только если Penalitate<>0 И Stornare<>1
   + Penalitate_Adj: CASE WHEN Stornare=1 THEN NegAdj.Penalitate_Adj ELSE Penalitate
   ============================================================ */
USE [ATK];
SET NOCOUNT ON;

DECLARE @DateFrom     date = '2022-05-29';
DECLARE @DateTo       date = '2025-11-01'; -- exclusive
DECLARE @CreditID_bin varbinary(32) = 0x813F00155D65040111ED4559CCFF74D7; -- тест-кредит

/* Целевая таблица: пересоздаём */
DROP TABLE IF EXISTS ATK.dbo.Fact_PenaltiesDaily;

/* 1) GOLD по одному кредиту в окне дат -> #dc_one */
DROP TABLE IF EXISTS #dc_one;

SELECT
    COALESCE(
        TRY_CONVERT(varbinary(32), gdcw.CreditID, 2),
        TRY_CONVERT(varbinary(32), gdcw.CreditID)
    )                                   AS CreditID_bin,
    gdcw.Amount,
    CAST(gdcw.DisbursedDate AS date)    AS DisbursedDate,
    CASE WHEN UPPER(LTRIM(RTRIM(gdcw.Currency))) = 'EUR' THEN 1 ELSE 0 END AS IsEUR
INTO #dc_one
FROM [ATK].[mis].[Gold_Dim_Credits_WithCounterparty_tbl] AS gdcw
WHERE gdcw.DisbursedDate IS NOT NULL
  AND gdcw.DisbursedDate >= @DateFrom
  AND gdcw.DisbursedDate <  @DateTo
  AND COALESCE(
        TRY_CONVERT(varbinary(32), gdcw.CreditID, 2),
        TRY_CONVERT(varbinary(32), gdcw.CreditID)
      ) = @CreditID_bin;

CREATE UNIQUE NONCLUSTERED INDEX IX_dc_one ON #dc_one(CreditID_bin);

/* 2) Подготовим место под свод день × кредит */
DROP TABLE IF EXISTS #FactRaw;

/* 3) Dt/Ct только по этому кредиту → свод в #FactRaw */
;WITH dt AS (
    SELECT
        CAST(src.[_Period] AS date) AS [Date],
        src.[_ValueDt2_RRRef]       AS CreditID_bin,
        CONVERT(char(32), src.[_ValueDt2_RRRef], 2) AS CreditID_hex,

        /* Penalitate = FC2 + AA2 */
        SUM(CASE WHEN src.[_AccountDtRRef] IN (0xB8A9001CC441144C11E5FDB834628FC2,
                                               0x80D600155D010F0111E6F2229F3A5AA2)
                 THEN CASE WHEN dc.IsEUR = 1 THEN src.[_Fld11922Dt] ELSE src.[_Fld11920] END ELSE 0 END) AS Penalitate,

        /* Comision_admin (…AA5) */
        SUM(CASE WHEN src.[_AccountDtRRef] = 0x80D600155D010F0111E6F2229F3A5AA5
                 THEN CASE WHEN dc.IsEUR = 1 THEN src.[_Fld11922Dt] ELSE src.[_Fld11920] END ELSE 0 END) AS Comision_admin,

        /* Comision_debursare (…E2C) */
        SUM(CASE WHEN src.[_AccountDtRRef] = 0xB8A9001CC441144C11E5FDB834628E2C
                 THEN CASE WHEN dc.IsEUR = 1 THEN src.[_Fld11922Dt] ELSE src.[_Fld11920] END ELSE 0 END) AS Comision_debursare,

        /* Dobinda (…E26) */
        SUM(CASE WHEN src.[_AccountDtRRef] = 0xB8A9001CC441144C11E5FDB834628E26
                 THEN CASE WHEN dc.IsEUR = 1 THEN src.[_Fld11922Dt] ELSE src.[_Fld11920] END ELSE 0 END) AS Dobinda,

        /* Acordare_imprumut = DBF + E5D */
        SUM(CASE WHEN src.[_AccountDtRRef] IN (0xB8A9001CC441144C11E5FDB834628DBF,
                                               0xB8A9001CC441144C11E5FDB834628E5D)
                 THEN CASE WHEN dc.IsEUR = 1 THEN src.[_Fld11922Dt] ELSE src.[_Fld11920] END ELSE 0 END) AS Acordare_imprumut,

        /* SprePlata (Dt) */
        SUM(CASE WHEN src.[_AccountDtRRef] = 0xB8A9001CC441144C11E5FDB834628E2C
                 THEN CASE WHEN dc.IsEUR = 1 THEN src.[_Fld11922Dt] ELSE src.[_Fld11920] END ELSE 0 END) AS Comision_debursare_SprePlata,
        SUM(CASE WHEN src.[_AccountDtRRef] = 0xB8A9001CC441144C11E5FDB834628E2E
                 THEN CASE WHEN dc.IsEUR = 1 THEN src.[_Fld11922Dt] ELSE src.[_Fld11920] END ELSE 0 END) AS Comision_administrare_SprePlata,

        /* Penalitate_SprePlata (Dt) = …E3F */
        SUM(CASE WHEN src.[_AccountDtRRef] = 0xB8A9001CC441144C11E5FDB834628E3F
                 THEN CASE WHEN dc.IsEUR = 1 THEN src.[_Fld11922Dt] ELSE src.[_Fld11920] END ELSE 0 END) AS Penalitate_SprePlata,

        /* Achitat = 0 (в Ct) */
        CAST(0 AS decimal(38,10)) AS Comision_debursare_Achitat,
        CAST(0 AS decimal(38,10)) AS Comision_administrare_Achitat,
        CAST(0 AS decimal(38,10)) AS Penalitate_Achitat,

        /* фикс-атрибуты */
        MAX(dc.Amount)                                 AS Amount,
        CAST(MAX(dc.Amount) * 0.0004 AS DECIMAL(19,4)) AS Max_Plafon,
        MAX(dc.DisbursedDate)                          AS DisbursedDate
    FROM [Microinvest_Copy_Full].[dbo].[_AccRg11917] AS src
    JOIN #dc_one dc
      ON dc.CreditID_bin = src.[_ValueDt2_RRRef]
    WHERE src.[_Period] >= @DateFrom
      AND src.[_Period] <  @DateTo
      AND src.[_ValueDt2_RRRef] = @CreditID_bin
    GROUP BY CAST(src.[_Period] AS date), src.[_ValueDt2_RRRef]
),
ct AS (
    SELECT
        CAST(src.[_Period] AS date) AS [Date],
        src.[_ValueCt2_RRRef]       AS CreditID_bin,
        CONVERT(char(32), src.[_ValueCt2_RRRef], 2) AS CreditID_hex,

        /* базовые метрики = 0 */
        CAST(0 AS decimal(38,10)) AS Penalitate,
        CAST(0 AS decimal(38,10)) AS Comision_admin,
        CAST(0 AS decimal(38,10)) AS Comision_debursare,
        CAST(0 AS decimal(38,10)) AS Dobinda,
        CAST(0 AS decimal(38,10)) AS Acordare_imprumut,

        /* SprePlata (Ct) = 0 */
        CAST(0 AS decimal(38,10)) AS Comision_debursare_SprePlata,
        CAST(0 AS decimal(38,10)) AS Comision_administrare_SprePlata,
        CAST(0 AS decimal(38,10)) AS Penalitate_SprePlata,

        /* Achitat (…E2C, …E2E, …E3F) */
        SUM(CASE WHEN src.[_AccountDtRRef] = 0xB8A9001CC441144C11E5FDB834628E2C
                 THEN CASE WHEN dc.IsEUR = 1 THEN src.[_Fld11922Dt] ELSE src.[_Fld11920] END ELSE 0 END) AS Comision_debursare_Achitat,
        SUM(CASE WHEN src.[_AccountDtRRef] = 0xB8A9001CC441144C11E5FDB834628E2E
                 THEN CASE WHEN dc.IsEUR = 1 THEN src.[_Fld11922Dt] ELSE src.[_Fld11920] END ELSE 0 END) AS Comision_administrare_Achitat,
        SUM(CASE WHEN src.[_AccountCtRRef] = 0xB8A9001CC441144C11E5FDB834628E3F
                 THEN CASE WHEN dc.IsEUR = 1 THEN src.[_Fld11922Dt] ELSE src.[_Fld11920] END ELSE 0 END) AS Penalitate_Achitat,

        /* фикс-атрибуты */
        MAX(dc.Amount)                                 AS Amount,
        CAST(MAX(dc.Amount) * 0.0004 AS DECIMAL(19,4)) AS Max_Plafon,
        MAX(dc.DisbursedDate)                          AS DisbursedDate
    FROM [Microinvest_Copy_Full].[dbo].[_AccRg11917] AS src
    JOIN #dc_one dc
      ON dc.CreditID_bin = src.[_ValueCt2_RRRef]
    WHERE src.[_Period] >= @DateFrom
      AND src.[_Period] <  @DateTo
      AND src.[_ValueCt2_RRRef] = @CreditID_bin
    GROUP BY CAST(src.[_Period] AS date), src.[_ValueCt2_RRRef]
)
SELECT
    X.[Date],
    X.CreditID_bin,
    CONVERT(char(32), X.CreditID_bin, 2) AS CreditID_hex,

    SUM(X.Penalitate)              AS Penalitate,
    SUM(X.Comision_admin)          AS Comision_admin,
    SUM(X.Comision_debursare)      AS Comision_debursare,
    SUM(X.Dobinda)                 AS Dobinda,
    SUM(X.Acordare_imprumut)       AS Acordare_imprumut,

    SUM(X.Comision_debursare_SprePlata)     AS Comision_debursare_SprePlata,
    SUM(X.Comision_administrare_SprePlata)  AS Comision_administrare_SprePlata,
    SUM(X.Penalitate_SprePlata)             AS Penalitate_SprePlata,

    SUM(X.Comision_debursare_Achitat)       AS Comision_debursare_Achitat,
    SUM(X.Comision_administrare_Achitat)    AS Comision_administrare_Achitat,
    SUM(X.Penalitate_Achitat)               AS Penalitate_Achitat,

    MAX(X.Amount)                            AS Amount,
    CAST(MAX(X.Amount) * 0.0004 AS DECIMAL(19,4)) AS Max_Plafon,
    MAX(X.DisbursedDate)                     AS DisbursedDate
INTO #FactRaw
FROM (SELECT * FROM dt UNION ALL SELECT * FROM ct) AS X
GROUP BY X.[Date], X.CreditID_bin;

CREATE NONCLUSTERED INDEX IX_FactRaw_Date ON #FactRaw([Date]);

/* 4) Финал ... */
WITH PenalOnly AS (
    SELECT
        fr.CreditID_bin,
        fr.[Date],
        DATEDIFF(day, CONVERT(date,'2000-01-01'), fr.[Date])
      - ROW_NUMBER() OVER (PARTITION BY fr.CreditID_bin ORDER BY fr.[Date]) AS grp_key
    FROM #FactRaw fr
    WHERE ISNULL(fr.Penalitate,0) <> 0
)
SELECT
    fr.[Date],
    fr.CreditID_bin,
    CONVERT(char(32), fr.CreditID_bin, 2) AS CreditID_hex,

    fr.Penalitate,
    fr.Comision_admin,
    fr.Comision_debursare,
    fr.Dobinda,
    fr.Acordare_imprumut,

    fr.Comision_debursare_SprePlata,
    fr.Comision_administrare_SprePlata,
    fr.Penalitate_SprePlata,

    fr.Comision_debursare_Achitat,
    fr.Comision_administrare_Achitat,
    fr.Penalitate_Achitat,

    fr.Amount,
    vals.Max_Plafon,
    fr.DisbursedDate,

    /* Zile_Restanta: подряд дни Penalitate <> 0 */
    CASE WHEN po.grp_key IS NULL THEN 0
         ELSE ROW_NUMBER() OVER (PARTITION BY fr.CreditID_bin, po.grp_key ORDER BY fr.[Date])
    END AS Zile_Restanta,

    /* Depasire_Plafon и Rezerva_suma — из calc2, чтобы совпадала логика с кумулятивами */
    calc2.Depasire_Plafon_Calc AS Depasire_Plafon,
    calc2.Rezerva_suma_Calc   AS Rezerva_suma,

    /* Penalitate_Adj по правилу Stornare */
    calc.Penalitate_Adj_Calc  AS Penalitate_Adj,

    /* корректировки + Stornare (остальные — как в источнике) */
    adj.Comision_admin_Adj,
    adj.Comision_debursare_Adj,
    ISNULL(adj.Stornare, 0)   AS Stornare,

    /* Кумулятивы (старые) */
    SUM(fr.Comision_admin) OVER (
        PARTITION BY fr.CreditID_bin ORDER BY fr.[Date]
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS Comision_admin_Cum,

    SUM(fr.Penalitate) OVER (
        PARTITION BY fr.CreditID_bin ORDER BY fr.[Date]
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS Penalitate_Cum,

    SUM(fr.Comision_administrare_Achitat) OVER (
        PARTITION BY fr.CreditID_bin ORDER BY fr.[Date]
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS Comision_administrare_Achitat_Cum,

    SUM(fr.Penalitate_Achitat) OVER (
        PARTITION BY fr.CreditID_bin ORDER BY fr.[Date]
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS Penalitate_Achitat_Cum,

    /* НОВЫЕ кумулятивы */
    SUM(calc.Penalitate_Adj_Calc) OVER (
        PARTITION BY fr.CreditID_bin ORDER BY fr.[Date]
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS Penalitate_Adj_Cum,

    SUM(calc2.Depasire_Plafon_Calc) OVER (
        PARTITION BY fr.CreditID_bin ORDER BY fr.[Date]
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS Depasire_Plafon_Cum,

    SUM(calc2.Rezerva_suma_Calc) OVER (
        PARTITION BY fr.CreditID_bin ORDER BY fr.[Date]
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS Rezerva_suma_Cum

INTO ATK.dbo.Fact_PenaltiesDaily
FROM #FactRaw AS fr
CROSS APPLY (
    SELECT
        CAST(fr.Amount * 0.0004 AS DECIMAL(19,4)) AS Max_Plafon,
        ISNULL(fr.Comision_admin,0) + ISNULL(fr.Penalitate,0) AS Charges
) AS vals
LEFT JOIN PenalOnly AS po
  ON po.CreditID_bin = fr.CreditID_bin
 AND po.[Date]       = fr.[Date]
LEFT JOIN ATK.dbo.Fact_PenaltiesNegAdj AS adj
  ON adj.CreditID_bin = fr.CreditID_bin
 AND adj.[Date]       = fr.[Date]
/* 4.1) Унифицированные расчёты */
OUTER APPLY (
    SELECT CASE
             WHEN ISNULL(adj.Stornare,0) > 0
               THEN ISNULL(adj.Penalitate_Adj, 0)
             ELSE ISNULL(fr.Penalitate, 0)
           END AS Penalitate_Adj_Calc
) AS calc
OUTER APPLY (
    SELECT
        /* Depasire_Plafon = MAX(0, Charges - Max_Plafon) */
        CASE WHEN (vals.Charges - vals.Max_Plafon) > 0
               THEN (vals.Charges - vals.Max_Plafon)
             ELSE 0
        END AS Depasire_Plafon_Calc,

        /* Rezerva_suma: только при Stornare<>1 и в серии просрочки; только если результат < 0 */
        CASE
          WHEN ISNULL(adj.Stornare,0) <> 1 AND po.grp_key IS NOT NULL THEN
              CASE
                WHEN (ISNULL(fr.Comision_admin,0) + calc.Penalitate_Adj_Calc - vals.Max_Plafon) < 0
                  THEN (ISNULL(fr.Comision_admin,0) + calc.Penalitate_Adj_Calc - vals.Max_Plafon)
                ELSE 0
              END
          ELSE 0
        END AS Rezerva_suma_Calc
) AS calc2;




SELECT TOP (1000) [ПланыСчетов.Основной ID]
      ,[ПланыСчетов.Основной Версия Данных]
      ,[ПланыСчетов.Основной Пометка Удаления]
      ,[ПланыСчетов.Основной Родитель ID]
      ,[ПланыСчетов.Основной Код]
      ,[ПланыСчетов.Основной Наименование]
      ,[ПланыСчетов.Основной Порядок]
      ,[ПланыСчетов.Основной Вид]
      ,[ПланыСчетов.Основной Забалансовый]
      ,[ПланыСчетов.Основной Наименование Осн Язык]
      ,[ПланыСчетов.Основной Порядок в Карточке Долга]
      ,[ПланыСчетов.Основной Пор Инк]
      ,[ПланыСчетов.Основной Количественный]
      ,[ПланыСчетов.Основной Валютный]
  FROM [ATK].[dbo].[ПланыСчетов.Основной]
  
  
  
SELECT *
FROM [ATK].[dbo].[ПланыСчетов.Основной] a
INNER JOIN [Microinvest_Copy_Full].[dbo].[_AccRg11917] b
    ON a.[ПланыСчетов.Основной ID] =
       SUBSTRING(CONVERT(varchar(34), b.[_AccountCtRRef], 2), 3, 32)
WHERE a.[ПланыСчетов.Основной ID] = 'B8A9001CC441144C11E5FDB834628F23';
  