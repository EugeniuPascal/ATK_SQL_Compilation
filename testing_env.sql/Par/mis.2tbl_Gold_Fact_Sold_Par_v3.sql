USE [ATK];
GO
SET NOCOUNT ON;

DECLARE @DateFrom DATE = '2024-01-01';

IF OBJECT_ID('mis.[2tbl_Gold_Fact_Sold_Par1]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Fact_Sold_Par1];

CREATE TABLE mis.[2tbl_Gold_Fact_Sold_Par1] (
    [SoldDate]                 DATE         NOT NULL,
    [CreditID]                 VARCHAR(36)  NOT NULL,
    [SoldAmount]               DECIMAL(18,2) NULL,
    [NumberOfOverdueDaysIFRS]  DECIMAL(15,2) NULL,
    [IRR_Values]               DECIMAL(18,6) NULL,
    [BranchShadow]             NVARCHAR(100) NULL,
    [EmployeeID]               VARCHAR(36)  NULL,
    [BranchID]                 VARCHAR(36)  NULL,
    [EmployeePositionID]       VARCHAR(36)  NULL,
    [Par_0_IFRS]               DECIMAL(18,6) NULL,
    [Par_30_IFRS]              DECIMAL(18,6) NULL,
    [Par_60_IFRS]              DECIMAL(18,6) NULL,
    [Par_90_IFRS]              DECIMAL(18,6) NULL,
    [RestructuredCreditState]  NVARCHAR(256) NULL,
    [RestructuringReason]      NVARCHAR(256) NULL,
    [RestructuringDebtType]    NVARCHAR(256) NULL
);

-----------------------------------------------------
-- Step 1: Base credit data with sticky flags
-----------------------------------------------------
;WITH CreditBase AS (
    SELECT
        sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS SoldDate,
        sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
        sd.[СуммыЗадолженностиПоПериодамПросрочки Клиент ID] AS ClientID,
        sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] AS SoldAmount,
        sd.[СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки МСФО] AS NumberOfOverdueDaysIFRS,

        ROUND(
            COALESCE(
                CASE WHEN irr.IRR_Year < 100 THEN irr.IRR_Year ELSE irr.IRR_Client END, 0
            ) * sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит],
            2
        ) AS IRR_Values,

        sh.BranchShadow,
        resp.EmployeeID,
        resp.BranchID,
        ep.EmployeePositionID,
        par.Par_0_IFRS,
        par.Par_30_IFRS,
        par.Par_60_IFRS,
        par.Par_90_IFRS,
        rs_restruct.RestructuringReason,
        rs_restruct.OriginalDebtType,

        CASE
            WHEN rs_state.RestructuredCreditState = N'НеИзлеченный' THEN 'Nevindecat'
            WHEN rs_state.RestructuredCreditState IS NULL THEN NULL
            ELSE 'Vindecat'
        END AS StickyRestructuredCreditState

    FROM mis.[Silver_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] AS sd
    JOIN mis.[Silver_Справочники.Кредиты] AS k
        ON k.[Кредиты ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]

    OUTER APPLY (
        SELECT
            CASE WHEN sd.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого] > 0
                THEN sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE 0 END AS Par_0_IFRS,
            CASE WHEN sd.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого] > 30
                THEN sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE 0 END AS Par_30_IFRS,
            CASE WHEN sd.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого] > 60
                THEN sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE 0 END AS Par_60_IFRS,
            CASE WHEN sd.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого] > 90
                THEN sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE 0 END AS Par_90_IFRS
    ) AS par
    OUTER APPLY (
        SELECT TOP(1) sh2.[КредитыВТеневыхФилиалах Филиал] AS BranchShadow
        FROM mis.[Silver_РегистрыСведений.КредитыВТеневыхФилиалах] AS sh2
        WHERE sh2.[КредитыВТеневыхФилиалах Кредит ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
        ORDER BY sh2.[КредитыВТеневыхФилиалах Период] DESC
    ) AS sh
    OUTER APPLY (
        SELECT TOP(1)
            r2.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS EmployeeID,
            r2.[ОтветственныеПоКредитамВыданным Филиал ID] AS BranchID
        FROM mis.[Silver_РегистрыСведений.ОтветственныеПоКредитамВыданным] AS r2
        WHERE r2.[ОтветственныеПоКредитамВыданным Кредит ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
        ORDER BY r2.[ОтветственныеПоКредитамВыданным Период] DESC
    ) AS resp
    OUTER APPLY (
        SELECT TOP(1) e2.[СотрудникиДанныеПоЗарплате Должность ID] AS EmployeePositionID
        FROM mis.[Silver_РегистрыСведений.СотрудникиДанныеПоЗарплате] AS e2
        WHERE e2.[СотрудникиДанныеПоЗарплате Сотрудник ID] = resp.EmployeeID
        ORDER BY e2.[СотрудникиДанныеПоЗарплате Период] DESC
    ) AS ep
    OUTER APPLY (
        SELECT TOP(1)
            i2.[УстановкаДанныхКредита Внутренняя Норма Доходности Годовая] AS IRR_Year,
            i2.[УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая] AS IRR_Client
        FROM mis.[Silver_Документы.УстановкаДанныхКредита] AS i2
        WHERE i2.[УстановкаДанныхКредита Кредит ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
        ORDER BY i2.[УстановкаДанныхКредита Дата] DESC
    ) AS irr
    OUTER APPLY (
        SELECT TOP(1)
            CASE WHEN s.[СостоянияРеструктурированныхКредитов Состояние Реструктурированного Кредита] = N'НеИзлеченный'
                 THEN 'Nevindecat'
                 ELSE 'Vindecat'
            END AS RestructuredCreditState
        FROM mis.[Silver_РегистрыСведений.СостоянияРеструктурированныхКредитов] AS s
        WHERE s.[СостоянияРеструктурированныхКредитов Кредит ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
          AND CAST(s.[СостоянияРеструктурированныхКредитов Период] AS DATE) <= sd.[СуммыЗадолженностиПоПериодамПросрочки Дата]
        ORDER BY s.[СостоянияРеструктурированныхКредитов Период] DESC
    ) AS rs_state
    OUTER APPLY (
        SELECT TOP(1)
            r.[РеструктурированныеКредиты Тип Реструктуризации Долга] AS OriginalDebtType,
            r.[РеструктурированныеКредиты Причина Реструктуризации] AS RestructuringReason
        FROM mis.[Silver_РегистрыСведений.РеструктурированныеКредиты] AS r
        WHERE r.[РеструктурированныеКредиты Кредит ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
          AND CAST(r.[РеструктурированныеКредиты Период] AS DATE) <= sd.[СуммыЗадолженностиПоПериодамПросрочки Дата]
        ORDER BY r.[РеструктурированныеКредиты Период] DESC
    ) AS rs_restruct
    WHERE sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= @DateFrom
      AND sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] <> 0
), 
-- Step 2: Lock debt type per credit
DebtLocked AS (
    SELECT *,
        CASE 
            WHEN MAX(CASE WHEN OriginalDebtType = N'НекоммерческаяРеструктуризация' THEN 1 ELSE 0 END) 
                 OVER(PARTITION BY CreditID ORDER BY SoldDate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) = 1
            THEN 'Restructurizare non-comerciala'
            WHEN OriginalDebtType = N'КоммерческаяРеструктуризация' THEN 'Restructurizare comerciala'
            ELSE NULL
        END AS LockedDebtType
    FROM CreditBase
),
-- Step 3: Client-day contamination
ClientDayContamination AS (
    SELECT *,
        CASE 
            WHEN MAX(CASE WHEN StickyRestructuredCreditState = 'Nevindecat' THEN 1 ELSE 0 END)
                 OVER(PARTITION BY ClientID, SoldDate) = 1
                 AND StickyRestructuredCreditState = 'Vindecat' THEN 'NevindecatContaminat'
            WHEN StickyRestructuredCreditState = 'Nevindecat' THEN 'Nevindecat'
            ELSE StickyRestructuredCreditState
        END AS ContaminatedCreditState,
        CASE
            WHEN MAX(CASE WHEN LockedDebtType = 'Restructurizare non-comerciala' AND StickyRestructuredCreditState = 'Nevindecat' THEN 1 ELSE 0 END)
                 OVER(PARTITION BY ClientID, SoldDate) = 1
                 AND LockedDebtType = 'Restructurizare comerciala' THEN 'Restructurizare non-comerciala'
            ELSE LockedDebtType
        END AS ContaminatedDebtType
    FROM DebtLocked
)
-----------------------------------------------------
-- Step 4: Final insert
-----------------------------------------------------
INSERT INTO mis.[2tbl_Gold_Fact_Sold_Par1] WITH (TABLOCK)
SELECT
    SoldDate,
    CreditID,
    SoldAmount,
    NumberOfOverdueDaysIFRS,
    IRR_Values,
    BranchShadow,
    EmployeeID,
    BranchID,
    EmployeePositionID,
    Par_0_IFRS,
    Par_30_IFRS,
    Par_60_IFRS,
    Par_90_IFRS,
    ContaminatedCreditState AS RestructuredCreditState,
    RestructuringReason,
    ContaminatedDebtType AS RestructuringDebtType
FROM ClientDayContamination
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
