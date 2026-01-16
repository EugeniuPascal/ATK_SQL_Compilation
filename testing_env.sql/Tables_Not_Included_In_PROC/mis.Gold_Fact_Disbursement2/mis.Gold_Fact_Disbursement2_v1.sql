USE [ATK];
GO

IF OBJECT_ID('tempdb..#Base')   IS NOT NULL DROP TABLE #Base;
IF OBJECT_ID('tempdb..#Status') IS NOT NULL DROP TABLE #Status;
IF OBJECT_ID('tempdb..#Final')  IS NOT NULL DROP TABLE #Final;

IF OBJECT_ID('mis.[Gold_Fact_Disbursement2]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_Disbursement2];
GO

CREATE TABLE mis.[Gold_Fact_Disbursement2] 
(
    CreditID           NVARCHAR(36)   NOT NULL,
    ClientID           NVARCHAR(36)   NULL,
    DisbursementDate   DATETIME2      NULL,
    CurrencyID         NVARCHAR(36)   NULL,
    CreditAmount       DECIMAL(18,2)  NULL,
    CreditAmountInMDL  DECIMAL(18,2)  NULL,
    CreditCurrency     NVARCHAR(50)   NULL,
    FirstFilialID      NVARCHAR(36)   NULL,
    FirstEmployeeID    NVARCHAR(36)   NULL,
    EmployeePosition   NVARCHAR(100)  NULL,
    LastFilialID       NVARCHAR(36)   NULL,
    LastEmployeeID     NVARCHAR(36)   NULL,
    IRR                DECIMAL(18,2)  NULL,
    IRR_Client         DECIMAL(18,2)  NULL,
    Qty                INT            NULL,
    NewExisting_Client NVARCHAR(20)   NULL,
    EmployeePositionID NVARCHAR(36)   NULL,
    CreatedAt          DATETIME       NOT NULL DEFAULT GETDATE()
);
GO

/* ============================
   Build #Base
============================ */
SELECT
    d.[ДанныеКредитовВыданных Кредит ID]                 AS CreditID,
    k.[Кредиты Владелец]                                 AS ClientID,
    d.[ДанныеКредитовВыданных Дата Выдачи]               AS DisbursementDate,
    d.[ДанныеКредитовВыданных Валюта Кредита ID]         AS CurrencyID,
    finalAmount.ChosenAmount                              AS CreditAmount,
    ROUND(finalAmount.ChosenAmount * ISNULL(rate.Rate, 1), 2) AS CreditAmountInMDL,
    d.[ДанныеКредитовВыданных Валюта Кредита]            AS CreditCurrency,
    firstR.[ФилиалID]                                     AS FirstFilialID,
    firstR.[ЭкспертID]                                    AS FirstEmployeeID,
    COALESCE(lastR_month.[ФилиалID], firstR.[ФилиалID])   AS LastFilialID,
    COALESCE(lastR_month.[ЭкспертID], firstR.[ЭкспертID]) AS LastEmployeeID,
    irr.IRR                                               AS IRR,
    irr.IRR_Client                                        AS IRR_Client,
    emp.EmployeePositionID                                 AS EmployeePositionID,
    emp.EmployeePosition,
    proto_refin.[ПротоколКомитета Сумма Рефинансирования Кредита] AS CreditRefinancingAmount,
    rn = ROW_NUMBER() OVER (
            PARTITION BY d.[ДанныеКредитовВыданных Кредит ID]
            ORDER BY d.[ДанныеКредитовВыданных Дата Выдачи]
         )
INTO #Base
FROM [ATK].[mis].[Bronze_РегистрыСведений.ДанныеКредитовВыданных] d
INNER JOIN [ATK].[mis].[Bronze_Справочники.Кредиты] k
    ON k.[Кредиты ID] = d.[ДанныеКредитовВыданных Кредит ID]

OUTER APPLY (
    SELECT TOP 1 v.[Валюта Курс] AS Rate
    FROM [ATK].[mis].[Bronze_РегистрыСведений.Валюта] v
    WHERE v.[Валюта Валюта ID] = d.[ДанныеКредитовВыданных Валюта Кредита ID]
      AND v.[Валюта Период] <= d.[ДанныеКредитовВыданных Период]
    ORDER BY v.[Валюта Период] DESC
) rate

OUTER APPLY (
    SELECT TOP 1
           r.[ОтветственныеПоКредитамВыданным Филиал ID]            AS [ФилиалID],
           r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID]  AS [ЭкспертID]
    FROM [ATK].[mis].[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным] r
    WHERE r.[ОтветственныеПоКредитамВыданным Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
    ORDER BY r.[ОтветственныеПоКредитамВыданным Период] ASC
) firstR

OUTER APPLY (
    SELECT TOP 1
           r.[ОтветственныеПоКредитамВыданным Филиал ID]            AS [ФилиалID],
           r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID]  AS [ЭкспертID]
    FROM [ATK].[mis].[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным] r
    WHERE r.[ОтветственныеПоКредитамВыданным Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
      AND r.[ОтветственныеПоКредитамВыданным Период] <= EOMONTH(d.[ДанныеКредитовВыданных Дата Выдачи])
    ORDER BY r.[ОтветственныеПоКредитамВыданным Период] DESC
) lastR_month

OUTER APPLY (
    SELECT TOP 1
        IRR_Client = ROUND(COALESCE(doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая], 0), 2),
        IRR = ROUND(COALESCE(
                CASE
                    WHEN doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Годовая] IS NOT NULL
                     AND doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Годовая] < 100
                        THEN doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Годовая]
                    ELSE doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая]
                END, 0), 2)
    FROM [ATK].[mis].[Bronze_Документы.УстановкаДанныхКредита] doc
    WHERE doc.[УстановкаДанныхКредита Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
    ORDER BY doc.[УстановкаДанныхКредита Дата] ASC
) irr

OUTER APPLY (
    SELECT TOP 1 
           e.[СотрудникиДанныеПоЗарплате Должность ID] AS EmployeePositionID,
           e.[СотрудникиДанныеПоЗарплате Должность]    AS EmployeePosition
    FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате] e
    WHERE e.[СотрудникиДанныеПоЗарплате Сотрудник ID] = COALESCE(lastR_month.[ЭкспертID], firstR.[ЭкспертID])
      AND e.[СотрудникиДанныеПоЗарплате Период] <= d.[ДанныеКредитовВыданных Дата Выдачи]
    ORDER BY e.[СотрудникиДанныеПоЗарплате Период] DESC
) emp

OUTER APPLY (
    SELECT TOP 1 p.[ПротоколКомитета Сумма на Выдачу]
    FROM [ATK].[mis].[Bronze_Документы.ПротоколКомитета] p
    WHERE p.[ПротоколКомитета Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
    ORDER BY p.[ПротоколКомитета Дата] DESC, p.[ПротоколКомитета ID] DESC
) proto

OUTER APPLY (
    SELECT TOP 1 p2.[ПротоколКомитета Сумма Рефинансирования Кредита]
    FROM [ATK].[mis].[Bronze_Документы.ПротоколКомитета] p2
    WHERE p2.[ПротоколКомитета Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
    ORDER BY p2.[ПротоколКомитета Дата] DESC, p2.[ПротоколКомитета ID] DESC
) proto_refin

OUTER APPLY (
    SELECT 
        ChosenAmount = CASE
            WHEN k.[Кредиты Цель Кредита ID] = 'B9D1CEBE56F4877143FDF0DD7CAE2AE4'
                 THEN ISNULL(proto.[ПротоколКомитета Сумма на Выдачу], d.[ДанныеКредитовВыданных Сумма Кредита])
            ELSE d.[ДанныеКредитовВыданных Сумма Кредита]
        END
) finalAmount

WHERE d.[ДанныеКредитовВыданных Кредитный Продукт] NOT LIKE N'Medier%'
  AND d.[ДанныеКредитовВыданных Дата Выдачи] >= '2023-09-01';
GO

/* ============================
   Build #Status (cancel/restore)
============================ */
WITH BaseIDs AS (
    SELECT DISTINCT CreditID FROM #Base
),
Cancels AS (
    SELECT a.[АнулированныеКредитыПартнеров Кредит ID] AS CreditID,
           MAX(a.[АнулированныеКредитыПартнеров Период]) AS CancelPeriod
    FROM [ATK].[mis].[Bronze_РегистрыСведений.АнулированныеКредитыПартнеров] a
    INNER JOIN BaseIDs b ON b.CreditID = a.[АнулированныеКредитыПартнеров Кредит ID]
    WHERE a.[АнулированныеКредитыПартнеров Кредит Анулирован] = N'01'
    GROUP BY a.[АнулированныеКредитыПартнеров Кредит ID]
),
Restores AS (
    SELECT a.[АнулированныеКредитыПартнеров Кредит ID] AS CreditID,
           MAX(a.[АнулированныеКредитыПартнеров Период]) AS RestorePeriod
    FROM [ATK].[mis].[Bronze_РегистрыСведений.АнулированныеКредитыПартнеров] a
    INNER JOIN BaseIDs b ON b.CreditID = a.[АнулированныеКредитыПартнеров Кредит ID]
    WHERE a.[АнулированныеКредитыПартнеров Кредит Восстановлен] = N'00'
    GROUP BY a.[АнулированныеКредитыПартнеров Кредит ID]
)
SELECT b.CreditID,
       c.CancelPeriod,
       r.RestorePeriod
INTO #Status
FROM BaseIDs b
LEFT JOIN Cancels  c ON c.CreditID = b.CreditID
LEFT JOIN Restores r ON r.CreditID = b.CreditID;
GO

/* ============================
   Build #Final
============================ */
SELECT
    b.CreditID, b.ClientID, b.DisbursementDate, b.CurrencyID,
    b.CreditAmount, b.CreditAmountInMDL, b.CreditCurrency,
    b.FirstFilialID, b.FirstEmployeeID, b.EmployeePosition,
    b.LastFilialID, b.LastEmployeeID,
    b.IRR, b.IRR_Client, 1 AS Qty,
    b.EmployeePositionID
INTO #Final
FROM #Base b
WHERE b.rn = 1;

-- Cancel rows
INSERT INTO #Final
SELECT
    b.CreditID, b.ClientID, s.CancelPeriod, b.CurrencyID,
    -b.CreditAmount, -b.CreditAmountInMDL, b.CreditCurrency,
    b.FirstFilialID, b.FirstEmployeeID, b.EmployeePosition,
    b.LastFilialID, b.LastEmployeeID,
    b.IRR, b.IRR_Client, -1 AS Qty,
    b.EmployeePositionID
FROM #Status s
JOIN #Base b ON b.CreditID = s.CreditID AND b.rn = 1
WHERE s.CancelPeriod IS NOT NULL
  AND s.CancelPeriod >= b.DisbursementDate;

-- Restore rows
INSERT INTO #Final
SELECT
    b.CreditID, b.ClientID, s.RestorePeriod, b.CurrencyID,
    b.CreditAmount, b.CreditAmountInMDL, b.CreditCurrency,
    b.FirstFilialID, b.FirstEmployeeID, b.EmployeePosition,
    b.LastFilialID, b.LastEmployeeID,
    b.IRR, b.IRR_Client, 1 AS Qty,
    b.EmployeePositionID
FROM #Status s
JOIN #Base b ON b.CreditID = s.CreditID AND b.rn = 1
WHERE s.RestorePeriod IS NOT NULL
  AND s.RestorePeriod >= b.DisbursementDate
  AND (s.CancelPeriod IS NULL OR s.RestorePeriod > s.CancelPeriod);
GO

/* ============================
   Insert into final table
============================ */
WITH AllSeq AS (
    SELECT
        f.*,
        ROW_NUMBER() OVER (
            PARTITION BY f.ClientID
            ORDER BY f.DisbursementDate, f.CreditID
        ) AS rn_all
    FROM #Final f
)
INSERT INTO mis.[Gold_Fact_Disbursement2]
(
    CreditID, ClientID, DisbursementDate, CurrencyID, CreditAmount, CreditAmountInMDL,
    CreditCurrency, FirstFilialID, FirstEmployeeID, LastFilialID, LastEmployeeID,
    IRR, IRR_Client, Qty, NewExisting_Client,
    EmployeePositionID, EmployeePosition
)
SELECT
    a.CreditID, a.ClientID, a.DisbursementDate, a.CurrencyID, a.CreditAmount, a.CreditAmountInMDL,
    a.CreditCurrency, a.FirstFilialID, a.FirstEmployeeID, a.LastFilialID, a.LastEmployeeID,
    a.IRR, a.IRR_Client, a.Qty,
    CASE
        WHEN a.CreditAmount > 0 AND a.rn_all = 1 THEN N'New'
        WHEN a.CreditAmount > 0 THEN N'Existing'
        ELSE N'Cancelled'
    END AS NewExisting_Client,
    a.EmployeePositionID,
    a.EmployeePosition
FROM AllSeq AS a
LEFT JOIN dbo.[Справочники.Контрагенты] AS c
    ON a.ClientID = c.[Контрагенты ID]
WHERE c.[Контрагенты Тестовый Контрагент] = 00;
GO

/* ============================
   Indexes
============================ */
CREATE CLUSTERED INDEX CIX_Disbursement_DisbursementDate_ClientID
ON mis.[Gold_Fact_Disbursement2] (DisbursementDate ASC, ClientID ASC);

CREATE NONCLUSTERED INDEX IX_Disbursement_CreditID
ON mis.[Gold_Fact_Disbursement2] (CreditID);

CREATE NONCLUSTERED INDEX IX_Disbursement_FirstFilialID
ON mis.[Gold_Fact_Disbursement2] (FirstFilialID);

CREATE NONCLUSTERED INDEX IX_Disbursement_LastFilialID
ON mis.[Gold_Fact_Disbursement2] (LastFilialID);

CREATE NONCLUSTERED INDEX IX_Disbursement_NewExisting
ON mis.[Gold_Fact_Disbursement2] (NewExisting_Client);

CREATE NONCLUSTERED INDEX IX_Disbursement_ClientID
ON mis.[Gold_Fact_Disbursement2] (ClientID);
GO

/* ============================
   Cleanup temp tables
============================ */
DROP TABLE #Base;
DROP TABLE #Status;
DROP TABLE #Final;
