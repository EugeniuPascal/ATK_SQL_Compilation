--this is ingested from an excel FILE

USE [ATK];
GO

IF OBJECT_ID(N'mis.[Gold_Fact_BudgetBranch]', N'U') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_BudgetBranch];
GO

CREATE TABLE mis.[Gold_Fact_BudgetBranch]
  (
    BranchID VARCHAR(36) NULL,
    Month DATETIME,
    Product_Segment NVARCHAR(255) NULL,
	  Product_Adjusted NVARCHAR(255) NULL,
    BranchRegion NVARCHAR(255) NULL,
    BranchName NVARCHAR(500) NULL,
    Disbursed DECIMAL(18,2) NULL,
    Repayments DECIMAL(18,2) NULL,
    LP       DECIMAL(18,2) NULL
   );
GO