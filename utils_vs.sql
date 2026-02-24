
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
FROM [ATK].[mis].[Gold_Dim_Employees]
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


  				


SELECT 
    [УстановкаДанныхКредита Кредит ID],
    COUNT(DISTINCT [УстановкаДанныхКредита Ставка Процента]) AS CountDistinctRates
FROM dbo.[Документы.УстановкаДанныхКредита]
GROUP BY [УстановкаДанныхКредита Кредит ID]
HAVING COUNT(DISTINCT [УстановкаДанныхКредита Ставка Процента]) > 1



SELECT [РеструктурированныеКредиты Кредит ID], COUNT(*) AS CreditCount
FROM [ATK].[dbo].[РегистрыСведений.РеструктурированныеКредиты]
WHERE [РеструктурированныеКредиты Период] > '2024-01-01'
GROUP BY [РеструктурированныеКредиты Кредит ID]
HAVING COUNT(*) > 1;


SELECT [СостоянияРеструктурированныхКредитов Кредит ID]
FROM [ATK].[dbo].[РегистрыСведений.СостоянияРеструктурированныхКредитов]
GROUP BY [СостоянияРеструктурированныхКредитов Кредит ID]
HAVING 
    COUNT(DISTINCT [СостоянияРеструктурированныхКредитов Состояние Реструктурированного Кредита]) > 1;



-- CTE for credits with more than one state
WITH MultipleStates AS (
    SELECT [СостоянияРеструктурированныхКредитов Кредит ID] AS CreditID
    FROM [ATK].[dbo].[РегистрыСведений.СостоянияРеструктурированныхКредитов]
    GROUP BY [СостоянияРеструктурированныхКредитов Кредит ID]
    HAVING COUNT(DISTINCT [СостоянияРеструктурированныхКредитов Состояние Реструктурированного Кредита]) > 1
)


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
  
  
  
  

SELECT TOP(50) * FROM [Microinvest_Copy_Full].[dbo].[_AccRg11917]
WHERE [_AccountCtRRef] IN
   ( --id la tip de venit 
    0x80D600155D010F0111E6F2229F3A5AA5,
    0x80E400155D01450411E90ED7629FC7F0,
    0x80FC00155D65040111EB6C9D67F167BB,
    0x80FC00155D65040111EB6C9D67F167BC,
    0x810400155D65040111EBFA088C98B04C,
    0x810400155D65040111EBFA088C98B04D,
    0x810700155D65040111EC13F80D473A48,
    0x8AC8B71528C28EBB4E72A39BF38D536D,
    0x922A74BCC79B4E9941AF6907D5CD5631,
    0xB8A9001CC441144C11E5FDB834628E24,
    0xB8A9001CC441144C11E5FDB834628E25,
    0xB8A9001CC441144C11E5FDB834628E26,
    0xB8A9001CC441144C11E5FDB834628E27, --dobinda
    0xB8A9001CC441144C11E5FDB834628E28,
    0xB8A9001CC441144C11E5FDB834628E29,
    0xB8A9001CC441144C11E5FDB834628E2A,
    0xB8A9001CC441144C11E5FDB834628E2B,
    0xB8A9001CC441144C11E5FDB834628E2C,
    0xB8A9001CC441144C11E5FDB834628E2D,
    0xB8A9001CC441144C11E5FDB834628E2E, --Comision Administrare
    0xB8A9001CC441144C11E5FDB834628E2F,
    0xB8A9001CC441144C11E5FDB834628E30,
    0xB8A9001CC441144C11E5FDB834628E31,
    0xB8A9001CC441144C11E5FDB834628E32,
    0xB8A9001CC441144C11E5FDB834628E33
	)
AND [_ValueDt2_RRRef] = 0x812500155d65040111ece1892bc9762d --credit id
ORDER BY _Period DESC
  
 -------------------------------------------
 SELECT TOP (1000) [CondID] -- Gold_Fact_ConditionsAfterDisb_Last
      ,[CPDDate] --Gold_Fact_ConditionsAfterDisb_Last( fistdate -closed)
      ,[CreditID] 
      ,[ClientID] 
      ,[GroupOwner]
      ,[BranchID]
      ,[SoldCredit]
      ,[SoldClient]
      ,[SoldGroup]
      ,[LoadDttm]
      ,[BranchID2] BranchLast
     
  FROM [ATK].[mis].[2tbl_Gold_Fact_CPD_Sold_v2]
  
  
  



