USE [ATK];
SET NOCOUNT ON;

--------------------------------------------------------------------------------
-- [mis].[2tbl_Gold_Sold_Owner]
-- Источник: [mis].[Gold_Fact_Sold_Par] + GroupOwner из [mis].[Gold_Dim_GroupMembershipPeriods]
-- Условие: SoldDate >= '2025-01-01'
--------------------------------------------------------------------------------

IF OBJECT_ID(N'[mis].[2tbl_Gold_Sold_Owner]', N'U') IS NOT NULL
    DROP TABLE [mis].[2tbl_Gold_Sold_Owner];

SELECT
       sp.SoldDate,
       sp.ClientID,
       sp.CreditID,
       sp.SoldAmount,
       sp.BranchShadow,
       sp.EmployeeID,
       sp.BranchID,
       gm_pick.GroupOwner
INTO [mis].[2tbl_Gold_Sold_Owner]
FROM [ATK].[mis].[Gold_Fact_Sold_Par] sp
OUTER APPLY (
    SELECT TOP (1)
           gm.GroupOwner
    FROM [ATK].[mis].[Gold_Dim_GroupMembershipPeriods] gm
    WHERE gm.PersonID = sp.ClientID
      AND sp.SoldDate >= gm.PeriodStart
      AND sp.SoldDate <  gm.PeriodEnd
      AND ISNULL(gm.ExcludedFlag, 0) = 0
      AND ISNULL(gm.ActiveFlag,   1) = 1
    ORDER BY gm.PeriodStart DESC, gm.RowNumber DESC
) gm_pick
WHERE sp.SoldDate >= '2025-01-01';

--------------------------------------------------------------------------------
-- Индексы (рекомендовано для скорости по датам/клиентам/кредитам)
--------------------------------------------------------------------------------
CREATE CLUSTERED INDEX CIX_2tbl_Gold_Sold_Owner_SoldDate
ON [mis].[2tbl_Gold_Sold_Owner] (SoldDate, ClientID, CreditID);

CREATE NONCLUSTERED INDEX IX_2tbl_Gold_Sold_Owner_ClientID
ON [mis].[2tbl_Gold_Sold_Owner] (ClientID, SoldDate)
INCLUDE (CreditID, SoldAmount, GroupOwner, BranchID, EmployeeID, BranchShadow);

CREATE NONCLUSTERED INDEX IX_2tbl_Gold_Sold_Owner_CreditID
ON [mis].[2tbl_Gold_Sold_Owner] (CreditID, SoldDate)
INCLUDE (ClientID, SoldAmount, GroupOwner);
