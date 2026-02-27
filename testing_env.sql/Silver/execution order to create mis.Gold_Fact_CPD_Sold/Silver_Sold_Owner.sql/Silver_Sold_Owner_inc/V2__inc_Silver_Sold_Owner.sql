-- Get last inserted date
DECLARE @LastDate DATETIME;
SELECT @LastDate = MAX(SoldDate) FROM mis.[Silver_Sold_Owner];

IF @LastDate IS NULL
    SET @LastDate = '2025-01-01';  -- first full load

-- Pre-filter Bronze data for new or changed rows
;WITH SoldCTE AS
(
    SELECT
        [СуммыЗадолженностиПоПериодамПросрочки Дата] AS SoldDate,
        [СуммыЗадолженностиПоПериодамПросрочки Клиент ID] AS ClientID,
        [СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
        [СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] AS SoldAmount
    FROM mis.[Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки]
    WHERE [СуммыЗадолженностиПоПериодамПросрочки Дата] >= @LastDate
),
GroupCTE AS
(
    SELECT 
        gm.PersonID,
        gm.GroupOwner,
        gm.PeriodStart,
        gm.PeriodEnd,
        ROW_NUMBER() OVER(PARTITION BY gm.PersonID ORDER BY gm.PeriodStart DESC) AS rn
    FROM [ATK].[mis].[Silver_SCD_GroupMembershipPeriods] gm
),
SourceData AS
(
    SELECT
           s.SoldDate,
           s.ClientID,
           s.CreditID,
           s.SoldAmount,
           b.[ОтветственныеПоКредитамВыданным Филиал ID] AS BranchID,
           g.GroupOwner
    FROM SoldCTE s
    LEFT JOIN mis.[Bronze_РегистрыСведений.ОтветственныеПоКредитамВыданным] b
           ON b.[ОтветственныеПоКредитамВыданным Кредит ID] = s.CreditID
    LEFT JOIN GroupCTE g
           ON g.PersonID = s.ClientID
          AND s.SoldDate >= g.PeriodStart
          AND s.SoldDate <  g.PeriodEnd
          AND g.rn = 1
)
-- Merge into Silver_Sold_Owner
MERGE INTO mis.[Silver_Sold_Owner] AS Target
USING SourceData AS Src
ON Target.SoldDate = Src.SoldDate
   AND Target.ClientID = Src.ClientID
   AND Target.CreditID = Src.CreditID
WHEN MATCHED AND 
     (Target.SoldAmount   <> Src.SoldAmount
      OR Target.BranchID  <> Src.BranchID
      OR Target.GroupOwner<> Src.GroupOwner)
THEN UPDATE SET
      Target.SoldAmount   = Src.SoldAmount,
      Target.BranchID     = Src.BranchID,
      Target.GroupOwner   = Src.GroupOwner
WHEN NOT MATCHED BY TARGET
THEN INSERT (SoldDate, ClientID, CreditID, SoldAmount, BranchID, GroupOwner)
     VALUES (Src.SoldDate, Src.ClientID, Src.CreditID, Src.SoldAmount, Src.BranchID, Src.GroupOwner);