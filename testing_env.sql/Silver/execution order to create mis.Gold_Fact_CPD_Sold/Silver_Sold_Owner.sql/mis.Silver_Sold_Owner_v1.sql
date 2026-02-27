USE [ATK];
SET NOCOUNT ON;

IF OBJECT_ID('mis.[Silver_Sold_Owner]', 'U') IS NOT NULL
    DROP TABLE mis.[Silver_Sold_Owner];
GO

CREATE TABLE mis.[Silver_Sold_Owner]
(
      [SoldDate]   DATETIME        NOT NULL,
      [ClientID]   VARCHAR(36)     NULL,
      [CreditID]   VARCHAR(36)     NULL,
      [SoldAmount] DECIMAL(18,2)   NULL,
      [BranchID]   VARCHAR(36)     NULL,
      [GroupOwner] VARCHAR(36)     NULL
);
GO

;WITH SoldCTE AS
(
    SELECT
        [СуммыЗадолженностиПоПериодамПросрочки Дата] AS SoldDate,
        [СуммыЗадолженностиПоПериодамПросрочки Клиент ID] AS ClientID,
        [СуммыЗадолженностиПоПериодамПросрочки Кредит ID] AS CreditID,
        [СуммыЗадолженностиПоПериодамПросрочки Итого Сумма Остаток Кредит] AS SoldAmount
    FROM mis.[Bronze_РегистрыСведений.СуммыЗадолженностиПоПериодамПросрочки]
    WHERE [СуммыЗадолженностиПоПериодамПросрочки Дата] >= '2025-01-01'
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
)
INSERT INTO mis.[Silver_Sold_Owner] (SoldDate, ClientID, CreditID, SoldAmount, BranchID, GroupOwner)
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
      AND g.rn = 1;


CREATE CLUSTERED INDEX CIX_Silver_Sold_Owner_SoldDate
ON [mis].[Silver_Sold_Owner] (SoldDate, ClientID, CreditID);

CREATE NONCLUSTERED INDEX IX_Silver_Sold_Owner_ClientID
ON [mis].[Silver_Sold_Owner] (ClientID, SoldDate)
INCLUDE (CreditID, SoldAmount, GroupOwner, BranchID);

CREATE NONCLUSTERED INDEX IX_Silver_Sold_Owner_CreditID
ON [mis].[Silver_Sold_Owner] (CreditID, SoldDate)
INCLUDE (ClientID, SoldAmount, GroupOwner, BranchID);