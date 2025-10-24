DECLARE @DateFrom date = '2024-01-01';
DECLARE @DateTo   date = '2025-12-31';
 
-- 1) PAR → #par (нужные поля, остаток ≠ 0)
IF OBJECT_ID('tempdb..#par') IS NOT NULL DROP TABLE #par;
 
SELECT
    SoldDate = CAST(p.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS date),
    CreditID = p.[СуммыЗадолженностиПоПериодамПросрочки Кредит ID],
    ClientID = p.[СуммыЗадолженностиПоПериодамПросрочки Клиент ID],
    DaysOverdue_Credit = p.[СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки Кредит],
    DaysOverdue_Actual = p.[СуммыЗадолженностиПоПериодамПросрочки Фактическое Количество Дней Просрочки Итого],
    DaysOverdue_IFRS   = p.[СуммыЗадолженностиПоПериодамПросрочки Количество Дней Просрочки МСФО],
    LP_Balance         = p.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит]
INTO #par
FROM [ATK].[mis].[Silver_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки] p
WHERE CAST(p.[СуммыЗадолженностиПоПериодамПросрочки Дата] AS date) BETWEEN @DateFrom AND @DateTo
  AND p.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] IS NOT NULL
  AND p.[СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] <> 0;
 
CREATE CLUSTERED INDEX CX_par ON #par (SoldDate, CreditID);
CREATE NONCLUSTERED INDEX IX_par_client ON #par (ClientID, SoldDate);
 
-- 2) Кредиты → #ids
IF OBJECT_ID('tempdb..#ids') IS NOT NULL DROP TABLE #ids;
CREATE TABLE #ids ( CreditID varchar(64) NOT NULL PRIMARY KEY CLUSTERED );
 
INSERT INTO #ids (CreditID)
SELECT DISTINCT CreditID FROM #par WHERE CreditID IS NOT NULL;
 
-- 3) Усечённый merged-SCD → #merged
IF OBJECT_ID('tempdb..#merged') IS NOT NULL DROP TABLE #merged;
 
SELECT
    m.CreditID, m.ValidFrom, m.ValidTo,
    m.TypeName_Sticky, m.StateName, m.Reason
INTO #merged
FROM [ATK].[mis].[2tbl_Silver_Restruct_Merged_SCD] m
JOIN #ids i ON i.CreditID = m.CreditID
WHERE m.ValidFrom <= @DateTo
  AND m.ValidTo   >= @DateFrom;
 
CREATE CLUSTERED INDEX CX_merged ON #merged (CreditID, ValidFrom);
CREATE NONCLUSTERED INDEX IX_merged_to ON #merged (CreditID, ValidTo)
    INCLUDE (TypeName_Sticky, StateName, Reason);
 
-- 4) Последняя причина Некоммерческой → #nc_last
IF OBJECT_ID('tempdb..#nc_last') IS NOT NULL DROP TABLE #nc_last;
 
;WITH nc AS (
    SELECT r.CreditID, r.ValidFrom, r.Reason,
           rn = ROW_NUMBER() OVER (PARTITION BY r.CreditID ORDER BY r.ValidFrom DESC)
    FROM [ATK].[mis].[2tbl_Silver_Restruct_SCD] r
    JOIN #ids i ON i.CreditID = r.CreditID
    WHERE r.TypeName = N'НекоммерческаяРеструктуризация'
      AND r.ValidFrom <= @DateTo
)
SELECT CreditID, LastNonCommReason = Reason
INTO #nc_last
FROM nc
WHERE rn = 1;
 
ALTER TABLE #nc_last ADD CONSTRAINT PK_nc_last PRIMARY KEY CLUSTERED (CreditID);
 
-- 5) Финальная таблица GOLD (ровно 10 полей)
IF OBJECT_ID('[ATK].[mis].[2tbl_Gold_Par_Restruct_Daily_Min]','U') IS NOT NULL
    DROP TABLE [ATK].[mis].[2tbl_Gold_Par_Restruct_Daily_Min];
 
;WITH Joined AS (
    SELECT
        p.SoldDate, p.CreditID, p.ClientID,
        p.DaysOverdue_Credit, p.DaysOverdue_Actual, p.DaysOverdue_IFRS, p.LP_Balance,
        mr.TypeName_Sticky,
        mr.StateName       AS RestructState_Base,
        mr.Reason,
        cu.HasUnhealed     AS HasUnhealedClientDay,
        ncl.LastNonCommReason
    FROM #par p
    LEFT JOIN #merged mr
           ON mr.CreditID = p.CreditID
          AND p.SoldDate BETWEEN mr.ValidFrom AND mr.ValidTo
    LEFT JOIN [ATK].[mis].[2tbl_Silver_Client_UnhealedFlag] cu
           ON cu.ClientID = p.ClientID
          AND cu.SoldDate = p.SoldDate
    LEFT JOIN #nc_last ncl
           ON ncl.CreditID = p.CreditID
)
SELECT
    SoldDate,
    CreditID,
    ClientID,
    DaysOverdue_Credit,
    DaysOverdue_Actual,
    DaysOverdue_IFRS,
    LP_Balance,
    RestructType_Final =
        CASE WHEN COALESCE(HasUnhealedClientDay,0) = 1
             THEN N'НекоммерческаяРеструктуризация'
             ELSE TypeName_Sticky
        END,
    RestructState_Final =
        CASE 
             WHEN COALESCE(HasUnhealedClientDay,0) = 1
              AND ISNULL(RestructState_Base, N'') <> N'НеИзлеченный'
                 THEN N'Nevindecat contaminat'
             WHEN COALESCE(HasUnhealedClientDay,0) = 1
                 THEN N'НеИзлеченный'
             ELSE RestructState_Base
        END,
    RestructReason_Final =
        CASE WHEN COALESCE(HasUnhealedClientDay,0) = 1
             THEN COALESCE(LastNonCommReason, Reason)
             ELSE Reason
        END
INTO [ATK].[mis].[2tbl_Gold_Par_Restruct_Daily_Min]
FROM Joined
OPTION (RECOMPILE);
 
-- Индексы под выборки
CREATE INDEX IX_Gold_Min__SoldDate_Credit
ON [ATK].[mis].[2tbl_Gold_Par_Restruct_Daily_Min] (SoldDate, CreditID)
INCLUDE (ClientID, RestructType_Final, RestructState_Final, RestructReason_Final, LP_Balance);
 
CREATE INDEX IX_Gold_Min__Client_SoldDate
ON [ATK].[mis].[2tbl_Gold_Par_Restruct_Daily_Min] (ClientID, SoldDate)
INCLUDE (CreditID, RestructType_Final, RestructState_Final);