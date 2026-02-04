IF OBJECT_ID('mis.Gold_Fact_Disbursement', 'U') IS NULL
BEGIN
    CREATE TABLE mis.Gold_Fact_Disbursement
    (
        CreditID           NVARCHAR(36)   NOT NULL,
        ClientID           NVARCHAR(36)   NULL,
        DisbursementDate   DATETIME2      NOT NULL,
        CurrencyID         NVARCHAR(36)   NULL,
        CreditAmount       DECIMAL(18,2)  NULL,
        CreditAmountInMDL  DECIMAL(18,2)  NULL,
        CreditCurrency     NVARCHAR(50)   NULL,
        FirstFilialID      NVARCHAR(36)   NULL,
        FirstEmployeeID    NVARCHAR(36)   NULL,
        EmployeePosition   NVARCHAR(100)  NULL,
        LastFilialID       NVARCHAR(36)   NULL,
        LastEmployeeID     NVARCHAR(36)   NULL,
        IRR                DECIMAL(18,2)  NULL,
        IRR_Client         DECIMAL(18,2)  NULL,
        Qty                INT            NOT NULL,
        NewExisting_Client NVARCHAR(20)   NULL,
        EmployeePositionID NVARCHAR(36)   NULL,
        CreatedAt          DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
        LastCalculatedAt   DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_Gold_Fact_Disbursement PRIMARY KEY (CreditID, DisbursementDate, Qty)
    );
END;
GO
