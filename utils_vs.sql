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