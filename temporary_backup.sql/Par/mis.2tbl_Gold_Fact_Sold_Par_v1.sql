USE [ATK];
GO
SET NOCOUNT ON;

DECLARE @DateFrom DATE = '2024-01-01';

-----------------------------------------------------
-- Drop + recreate GOLD table
-----------------------------------------------------
IF OBJECT_ID('mis.[2tbl_Gold_Fact_Sold_Par]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Fact_Sold_Par];

CREATE TABLE mis.[2tbl_Gold_Fact_Sold_Par] (
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
) WITH (DATA_COMPRESSION = PAGE);

-----------------------------------------------------
-- Insert with independent OUTER APPLY for restructured info
-----------------------------------------------------
INSERT INTO mis.[2tbl_Gold_Fact_Sold_Par] WITH (TABLOCK)
SELECT
    sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS SoldDate,
    sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
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
    rs_state.RestructuredCreditState,
    rs_restruct.RestructuringReason,
    rs_restruct.RestructuringDebtType

FROM mis.[Silver_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] sd
JOIN mis.[Silver_Справочники.Кредиты] k
    ON k.[Кредиты ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]

-----------------------------------------------------
-- PAR values
-----------------------------------------------------
OUTER APPLY (
    SELECT
        SUM(CASE WHEN sd2.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого] > 0
            THEN sd2.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE 0 END) AS Par_0_IFRS,
        SUM(CASE WHEN sd2.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого] > 30
            THEN sd2.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE 0 END) AS Par_30_IFRS,
        SUM(CASE WHEN sd2.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого] > 60
            THEN sd2.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE 0 END) AS Par_60_IFRS,
        SUM(CASE WHEN sd2.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого] > 90
            THEN sd2.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] ELSE 0 END) AS Par_90_IFRS
    FROM mis.[Silver_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] sd2
    WHERE sd2.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
      AND sd2.[СуммыЗадолженностиПоПериодамПросрочки Дата] = sd.[СуммыЗадолженностиПоПериодамПросрочки Дата]
) par

-----------------------------------------------------
-- Shadow branch
-----------------------------------------------------
OUTER APPLY (
    SELECT TOP(1)
        sh2.[КредитыВТеневыхФилиалах Филиал] AS BranchShadow
    FROM mis.[Silver_РегистрыСведений.КредитыВТеневыхФилиалах] sh2
    WHERE sh2.[КредитыВТеневыхФилиалах Кредит ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
    ORDER BY sh2.[КредитыВТеневыхФилиалах Период] DESC
) sh

-----------------------------------------------------
-- Responsible + Branch
-----------------------------------------------------
OUTER APPLY (
    SELECT TOP(1)
        r2.[ОтветственныеПоКредитамВыданным Кредитный Эксперт ID] AS EmployeeID,
        r2.[ОтветственныеПоКредитамВыданным Филиал ID] AS BranchID
    FROM mis.[Silver_РегистрыСведений.ОтветственныеПоКредитамВыданным] r2
    WHERE r2.[ОтветственныеПоКредитамВыданным Кредит ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
    ORDER BY r2.[ОтветственныеПоКредитамВыданным Период] DESC
) resp

-----------------------------------------------------
-- Employee position
-----------------------------------------------------
OUTER APPLY (
    SELECT TOP(1)
        e2.[СотрудникиДанныеПоЗарплате Должность ID] AS EmployeePositionID
    FROM mis.[Silver_РегистрыСведений.СотрудникиДанныеПоЗарплате] e2
    WHERE e2.[СотрудникиДанныеПоЗарплате Сотрудник ID] = resp.EmployeeID
    ORDER BY e2.[СотрудникиДанныеПоЗарплате Период] DESC
) ep

-----------------------------------------------------
-- IRR
-----------------------------------------------------
OUTER APPLY (
    SELECT TOP(1)
        i2.[УстановкаДанныхКредита Внутренняя Норма Доходности Годовая] AS IRR_Year,
        i2.[УстановкаДанныхКредита Внутренняя Норма Доходности Клиент Годовая] AS IRR_Client
    FROM mis.[Silver_Документы.УстановкаДанныхКредита] i2
    WHERE i2.[УстановкаДанныхКредита Кредит ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
    ORDER BY i2.[УстановкаДанныхКредита Дата] DESC
) irr

-----------------------------------------------------
-- Latest Restructured State
-----------------------------------------------------
OUTER APPLY (
    SELECT TOP(1)
        s.[СостоянияРеструктурированныхКредитов Состояние Реструктурированного Кредита] AS RestructuredCreditState
    FROM mis.[Silver_РегистрыСведений.СостоянияРеструктурированныхКредитов] s
    WHERE s.[СостоянияРеструктурированныхКредитов Кредит ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
      AND (CAST(s.[СостоянияРеструктурированныхКредитов Период] AS DATE) <= sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] 
	  OR s.[СостоянияРеструктурированныхКредитов Период] IS NULL)
    ORDER BY 
     s.[СостоянияРеструктурированныхКредитов Период] DESC
) rs_state

-----------------------------------------------------
-- Latest Restructuring Reason + Debt
-----------------------------------------------------
OUTER APPLY (
    SELECT TOP(1)
        r.[РеструктурированныеКредиты Причина Реструктуризации] AS RestructuringReason,
        r.[РеструктурированныеКредиты Тип Реструктуризации Долга] AS RestructuringDebtType
    FROM mis.[Silver_РегистрыСведений.РеструктурированныеКредиты] r
    WHERE r.[РеструктурированныеКредиты Кредит ID] = sd.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID]
      AND (CAST(r.[РеструктурированныеКредиты Период] AS DATE) <= sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] OR r.[РеструктурированныеКредиты Период] IS NULL)
    ORDER BY 
    r.[РеструктурированныеКредиты Период] DESC
) rs_restruct

WHERE sd.[СуммыЗадолженностиПоПериодамПросрочки Дата] >= @DateFrom
  AND sd.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] <> 0

