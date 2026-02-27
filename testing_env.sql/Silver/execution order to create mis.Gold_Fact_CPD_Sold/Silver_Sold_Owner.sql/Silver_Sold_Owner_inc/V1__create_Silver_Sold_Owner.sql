USE [ATK];
SET NOCOUNT ON;

IF OBJECT_ID('mis.[Silver_Sold_Owner]', 'U') IS NULL
BEGIN
    CREATE TABLE mis.[Silver_Sold_Owner]
    (
          [SoldDate]   DATETIME        NOT NULL,
          [ClientID]   VARCHAR(36)     NULL,
          [CreditID]   VARCHAR(36)     NULL,
          [SoldAmount] DECIMAL(18,2)   NULL,
          [BranchID]   VARCHAR(36)     NULL,
          [GroupOwner] VARCHAR(36)     NULL
    );
END
GO
