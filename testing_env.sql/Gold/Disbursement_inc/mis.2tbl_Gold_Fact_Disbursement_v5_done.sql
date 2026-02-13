USE [ATK];
GO

/* ============================
   Cleanup temp tables
============================ */
IF OBJECT_ID('tempdb..#Base')       IS NOT NULL DROP TABLE #Base;
IF OBJECT_ID('tempdb..#Status')     IS NOT NULL DROP TABLE #Status;
IF OBJECT_ID('tempdb..#Final')      IS NOT NULL DROP TABLE #Final;
IF OBJECT_ID('tempdb..#PartnerTemp') IS NOT NULL DROP TABLE #PartnerTemp;

-- Drop target table if exists
IF OBJECT_ID('mis.[Gold_Fact_Disbursement1]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_Disbursement1];
GO

/* ============================
   Create target table
============================ */
CREATE TABLE mis.[Gold_Fact_Disbursement1] 
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
    LastFilialID       NVARCHAR(36)   NULL,
    LastEmployeeID     NVARCHAR(36)   NULL,
    IRR                DECIMAL(18,2)  NULL,
    IRR_Client         DECIMAL(18,2)  NULL,
    Qty                INT            NULL,
    NewExisting_Client NVARCHAR(20)   NULL,
    EmployeePositionID NVARCHAR(36)   NULL,
    PartnerID          NVARCHAR(36)   NULL,
    First_PartnerID    NVARCHAR(36)   NULL,
    PartnerName        NVARCHAR(255)  NULL,
    First_PartnerName  NVARCHAR(255)  NULL,
    First_PartnerID_2023 NVARCHAR(36) NULL,
    First_PartnerID_2024 NVARCHAR(36) NULL,
    First_PartnerID_2025 NVARCHAR(36) NULL,
    CreatedAt          DATETIME       NOT NULL DEFAULT GETDATE()
);
GO

/* ============================
   Build #Base
============================ */
SELECT
    d.[ДанныеКредитовВыданных Кредит ID]                AS CreditID,
    k.[Кредиты Владелец]                                AS ClientID,
    d.[ДанныеКредитовВыданных Дата Выдачи]             AS DisbursementDate,
    d.[ДанныеКредитовВыданных Валюта Кредита ID]       AS CurrencyID,
    finalAmount.ChosenAmount                             AS CreditAmount,
    ROUND(finalAmount.ChosenAmount * ISNULL(rate.Rate,1),2) AS CreditAmountInMDL,
    d.[ДанныеКредитовВыданных Валюта Кредита]          AS CreditCurrency,
    firstR.[ФилиалID]                                   AS FirstFilialID,
    firstR.[ЭкспертID]                                  AS FirstEmployeeID,
    COALESCE(lastR.[ФилиалID], firstR.[ФилиалID])       AS LastFilialID,
    COALESCE(lastR.[ЭкспертID], firstR.[ЭкспертID])     AS LastEmployeeID,
    irr.IRR,
    irr.IRR_Client,
    emp.EmployeePositionID,
    proto_refin.[ПротоколКомитета Сумма Рефинансирования Кредита] AS CreditRefinancingAmount,
    ROW_NUMBER() OVER (
        PARTITION BY d.[ДанныеКредитовВыданных Кредит ID]
        ORDER BY d.[ДанныеКредитовВыданных Дата Выдачи]
    ) AS rn
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
    SELECT TOP 1 r.[ОтветственныеПоКредитамВыданным Филиал ID] AS [ФилиалID],
                  r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS [ЭкспертID]
    FROM [ATK].[mis].[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным] r
    WHERE r.[ОтветственныеПоКредитамВыданным Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
    ORDER BY r.[ОтветственныеПоКредитамВыданным Период] ASC
) firstR
OUTER APPLY (
    SELECT TOP 1 r.[ОтветственныеПоКредитамВыданным Филиал ID] AS [ФилиалID],
                  r.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS [ЭкспертID]
    FROM [ATK].[mis].[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным] r
    WHERE r.[ОтветственныеПоКредитамВыданным Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
      AND r.[ОтветственныеПоКредитамВыданным Период] <= EOMONTH(d.[ДанныеКредитовВыданных Дата Выдачи])
    ORDER BY r.[ОтветственныеПоКредитамВыданным Период] DESC
) lastR
OUTER APPLY (
    SELECT TOP 1 
        IRR_Client = ROUND(COALESCE(doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая],0),2),
        IRR = ROUND(COALESCE(
            CASE 
                WHEN doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Годовая] IS NOT NULL
                     AND doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Годовая]<100
                    THEN doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Годовая]
                ELSE doc.[УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая]
            END,0),2)
    FROM [ATK].[mis].[Bronze_Документы.УстановкаДанныхКредита] doc
    WHERE doc.[УстановкаДанныхКредита Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
    ORDER BY doc.[УстановкаДанныхКредита Дата] ASC
) irr
OUTER APPLY (
    SELECT TOP 1 e.[СотрудникиДанныеПоЗарплате Должность ID] AS EmployeePositionID
    FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате] e
    WHERE e.[СотрудникиДанныеПоЗарплате Сотрудник ID] = COALESCE(lastR.[ЭкспертID], firstR.[ЭкспертID])
    ORDER BY e.[СотрудникиДанныеПоЗарплате Период] DESC
) emp
OUTER APPLY (
    SELECT TOP 1 p2.[ПротоколКомитета Сумма Рефинансирования Кредита]
    FROM [ATK].[mis].[Bronze_Документы.ПротоколКомитета] p2
    WHERE p2.[ПротоколКомитета Кредит ID] = d.[ДанныеКредитовВыданных Кредит ID]
    ORDER BY p2.[ПротоколКомитета Дата] DESC, p2.[ПротоколКомитета ID] DESC
) proto_refin
OUTER APPLY (
    SELECT ChosenAmount = CASE
        WHEN k.[Кредиты Цель Кредита ID] = 'B9D1CEBE56F4877143FDF0DD7CAE2AE4'
            THEN ISNULL(proto_refin.[ПротоколКомитета Сумма Рефинансирования Кредита], d.[ДанныеКредитовВыданных Сумма Кредита])
        ELSE d.[ДанныеКредитовВыданных Сумма Кредита]
    END
) finalAmount
WHERE d.[ДанныеКредитовВыданных Кредитный Продукт] NOT LIKE N'Medier%';
GO

/* ============================
   Partner propagation (deduped)
============================ */
WITH FirstPartner AS (
    SELECT
        d.[ДанныеКредитовВыданных Кредит ID] AS CreditID,
        k.[Кредиты Владелец] AS OwnerID,   -- FIXED ALIAS
        d.[ДанныеКредитовВыданных Дата Выдачи] AS DisbursementDate,
        cr.[ЗаявкаНаКредит Партнер ID] AS PartnerID,
        cr.[ЗаявкаНаКредит Партнер] AS PartnerName
    FROM [ATK].[mis].[Bronze_РегистрыСведений.ДанныеКредитовВыданных] d
    INNER JOIN [ATK].[mis].[Bronze_Справочники.Кредиты] k
        ON k.[Кредиты ID] = d.[ДанныеКредитовВыданных Кредит ID]
    LEFT JOIN [ATK].[mis].[Bronze_Документы.ЗаявкаНаКредит] cr
        ON d.[ДанныеКредитовВыданных Кредит ID] = cr.[ЗаявкаНаКредит Кредит ID]
),
PartnerWithRules AS (
    SELECT *,
        CASE 
            WHEN DisbursementDate = '1753-01-01' THEN NULL
            WHEN PartnerID = '00000000000000000000000000000000' THEN NULL
            ELSE PartnerID
        END AS PartnerID_Valid,
        CASE
            WHEN DisbursementDate = '1753-01-01' THEN NULL
            WHEN PartnerID = '00000000000000000000000000000000' THEN NULL
            ELSE PartnerName
        END AS PartnerName_Valid
    FROM FirstPartner
),
ClientFirstCredit AS (
    SELECT 
        OwnerID,
        MIN(DisbursementDate) AS FirstCreditDate
    FROM PartnerWithRules
    GROUP BY OwnerID
),
Propagated AS (
    SELECT p.*,
        FIRST_VALUE(PartnerID_Valid) OVER (
            PARTITION BY p.OwnerID
            ORDER BY p.DisbursementDate, p.CreditID
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS First_PartnerID,

        FIRST_VALUE(PartnerName_Valid) OVER (
            PARTITION BY p.OwnerID
            ORDER BY p.DisbursementDate, p.CreditID
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS First_PartnerName,

        CASE 
            WHEN YEAR(cfc.FirstCreditDate) = 2023 THEN
                FIRST_VALUE(PartnerID_Valid) OVER (
                    PARTITION BY p.OwnerID
                    ORDER BY p.DisbursementDate, p.CreditID
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                )
        END AS First_PartnerID_2023,

        CASE 
            WHEN YEAR(cfc.FirstCreditDate) = 2024 THEN
                FIRST_VALUE(PartnerID_Valid) OVER (
                    PARTITION BY p.OwnerID
                    ORDER BY p.DisbursementDate, p.CreditID
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                )
        END AS First_PartnerID_2024,

        CASE 
            WHEN YEAR(cfc.FirstCreditDate) = 2025 THEN
                FIRST_VALUE(PartnerID_Valid) OVER (
                    PARTITION BY p.OwnerID
                    ORDER BY p.DisbursementDate, p.CreditID
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                )
        END AS First_PartnerID_2025
    FROM PartnerWithRules p
    INNER JOIN ClientFirstCredit cfc
        ON p.OwnerID = cfc.OwnerID
),
Dedup AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY CreditID
            ORDER BY DisbursementDate, CreditID
        ) AS rn
    FROM Propagated
)
SELECT *
INTO #PartnerTemp
FROM Dedup
WHERE rn = 1;

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
    b.FirstFilialID, b.FirstEmployeeID, b.LastFilialID, b.LastEmployeeID,
    b.IRR, b.IRR_Client, 1 AS Qty,
    b.EmployeePositionID,
    p.PartnerID AS [ЗаявкаНаКредит Партнер ID],
    p.First_PartnerID,
    p.PartnerName AS [ЗаявкаНаКредит Партнер],
    p.First_PartnerName,
    p.First_PartnerID_2023,
    p.First_PartnerID_2024,
    p.First_PartnerID_2025
INTO #Final
FROM #Base b
LEFT JOIN #PartnerTemp p ON b.CreditID = p.CreditID
WHERE b.rn = 1;

-- Apply cancel
INSERT INTO #Final
SELECT
    f.CreditID, f.ClientID, s.CancelPeriod, f.CurrencyID,
    -f.CreditAmount, -f.CreditAmountInMDL, f.CreditCurrency,
    f.FirstFilialID, f.FirstEmployeeID, f.LastFilialID, f.LastEmployeeID,
    f.IRR, f.IRR_Client, -1 AS Qty,
    f.EmployeePositionID,
    f.[ЗаявкаНаКредит Партнер ID], f.First_PartnerID, f.[ЗаявкаНаКредит Партнер], f.First_PartnerName,
    f.First_PartnerID_2023, f.First_PartnerID_2024, f.First_PartnerID_2025
FROM #Status s
JOIN #Final f ON f.CreditID = s.CreditID
WHERE s.CancelPeriod IS NOT NULL
  AND s.CancelPeriod >= f.DisbursementDate;

-- Apply restore
INSERT INTO #Final
SELECT
    f.CreditID, f.ClientID, s.RestorePeriod, f.CurrencyID,
    f.CreditAmount, f.CreditAmountInMDL, f.CreditCurrency,
    f.FirstFilialID, f.FirstEmployeeID, f.LastFilialID, f.LastEmployeeID,
    f.IRR, f.IRR_Client, 1 AS Qty,
    f.EmployeePositionID,
    f.[ЗаявкаНаКредит Партнер ID], f.First_PartnerID, f.[ЗаявкаНаКредит Партнер], f.First_PartnerName,
    f.First_PartnerID_2023, f.First_PartnerID_2024, f.First_PartnerID_2025
FROM #Status s
JOIN #Final f ON f.CreditID = s.CreditID
WHERE s.RestorePeriod IS NOT NULL
  AND s.RestorePeriod >= f.DisbursementDate
  AND (s.CancelPeriod IS NULL OR s.RestorePeriod > s.CancelPeriod);
GO

/* ============================
   Insert into Gold_Fact_Disbursement1
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
INSERT INTO mis.[Gold_Fact_Disbursement1]
(
    CreditID, ClientID, DisbursementDate, CurrencyID, CreditAmount, CreditAmountInMDL,
    CreditCurrency, FirstFilialID, FirstEmployeeID, LastFilialID, LastEmployeeID,
    IRR, IRR_Client, Qty, NewExisting_Client, EmployeePositionID,
    PartnerID, First_PartnerID, PartnerName, First_PartnerName,
    First_PartnerID_2023, First_PartnerID_2024, First_PartnerID_2025
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
    a.[ЗаявкаНаКредит Партнер ID],
    a.First_PartnerID,
    a.[ЗаявкаНаКредит Партнер],
    a.First_PartnerName,
    a.First_PartnerID_2023,
    a.First_PartnerID_2024,
    a.First_PartnerID_2025
FROM AllSeq a
LEFT JOIN dbo.[Справочники.Контрагенты] c
    ON a.ClientID = c.[Контрагенты ID]
WHERE c.[Контрагенты Тестовый Контрагент] = 0
 --AND a.ClientID = '80E100155D010F0111E75660E6F01BD3';
GO

/* ============================
   Indexes
============================ */
CREATE CLUSTERED INDEX CIX_Disbursement_DisbursementDate_ClientID
ON mis.[Gold_Fact_Disbursement1] (DisbursementDate ASC, ClientID ASC);

CREATE NONCLUSTERED INDEX IX_Disbursement_CreditID
ON mis.[Gold_Fact_Disbursement1] (CreditID);

CREATE NONCLUSTERED INDEX IX_Disbursement_FirstFilialID
ON mis.[Gold_Fact_Disbursement1] (FirstFilialID);

CREATE NONCLUSTERED INDEX IX_Disbursement_LastFilialID
ON mis.[Gold_Fact_Disbursement1] (LastFilialID);
GO

/* ============================
   Cleanup temp tables
============================ */
DROP TABLE IF EXISTS #Base;
DROP TABLE IF EXISTS #PartnerTemp;
DROP TABLE IF EXISTS #Status;
DROP TABLE IF EXISTS #Final;
GO
