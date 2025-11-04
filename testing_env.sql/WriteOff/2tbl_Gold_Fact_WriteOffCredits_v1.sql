USE [ATK];
SET NOCOUNT ON;

IF OBJECT_ID('mis.[2tbl_Gold_Fact_WriteOffCredits_v2]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Fact_WriteOffCredits_v2];

SELECT
      w.[Credit_CanceledCreditID]
    , w.[Credit_RowNumber]
    , w.[Credit_AccountID]
    , w.[Credit_Account]
    , w.[Credit_ClientID]
    , w.[Credit_Client]
    , w.[Credit_CreditID]
    , w.[Credit_Credit]
    , w.[Credit_CurrencyID]
    , w.[Credit_Currency]
    , w.[Credit_Amount]
    , w.[Credit_AmountCurrency]
    , w.[Credit_Interest]
    , w.[Credit_InterestCurrency]
    , w.[Credit_Penalty]
    , w.[Credit_PenaltyCurrency]
    , w.[Credit_Commission]
    , w.[Credit_CommissionCurrency]
    , w.[Credit_LineAmount]
    , w.[Credit_LineAmountCurrency]
    , w.[Canceled_CreditDate]
    , w.[Canceled_CreditPosted]
    , w.[Canceled_CreditBase]
    , w.[Canceled_CreditAuthorID]
    , w.[Canceled_DebitAccount]
    , lastResp.FinalBranchID
    , lastResp.FinalExpertID
INTO [ATK].[mis].[2tbl_Gold_Fact_WriteOffCredits_v2]
FROM [ATK].[mis].[2tbl_Gold_Fact_WriteOffCredits] w
OUTER APPLY (
    SELECT TOP (1)
           r.[BranchID] AS FinalBranchID,
           r.[ExpertID] AS FinalExpertID
    FROM [ATK].[mis].[2tbl_Silver_Resp_SCD] r
    WHERE r.[CreditID] = w.[Credit_CreditID]
    ORDER BY 
        ISNULL(CAST(r.[ValidTo] AS date), CONVERT(date,'9999-12-31')) DESC,
        CAST(r.[ValidFrom] AS date) DESC,
        r.[BranchID] DESC,
        r.[ExpertID] DESC
) AS lastResp;

-- Индексы
CREATE INDEX IX_WriteOff_v2_CreditID 
    ON [ATK].[mis].[2tbl_Gold_Fact_WriteOffCredits_v2] ([Credit_CreditID]);

CREATE INDEX IX_WriteOff_v2_Final 
    ON [ATK].[mis].[2tbl_Gold_Fact_WriteOffCredits_v2] ([FinalBranchID], [FinalExpertID]);
