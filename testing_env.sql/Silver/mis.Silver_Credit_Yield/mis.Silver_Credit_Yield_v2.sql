USE [ATK];
GO
SET NOCOUNT ON;

IF OBJECT_ID(N'mis.Silver_Credit_Yield', 'U') IS NOT NULL
    DROP TABLE mis.Silver_Credit_Yield;
GO

CREATE TABLE mis.Silver_Credit_Yield
(
    _Period DATETIME2 NOT NULL,

    _RecorderRRef   CHAR(32),

    _AccountDtRRef  CHAR(32),
    _AccountCtRRef  CHAR(32),

    _Fld11918DtRRef CHAR(32),
    _Fld11918CtRRef CHAR(32),
    _Fld11919RRef   CHAR(32),

    _Fld11920       DECIMAL(14,2),
    _Fld11921Dt     DECIMAL(15,3),
    _Fld11921Ct     DECIMAL(15,3),
    _Fld11922Dt     DECIMAL(14,2),
    _Fld11922Ct     DECIMAL(14,2),
    _Fld11923       DECIMAL(14,2),
    _Fld11924Dt     DECIMAL(14,2),
    _Fld11924Ct     DECIMAL(14,2),
    _Fld11925       NVARCHAR(50),

    _ValueDt1_RRRef CHAR(32),
    _KindDt1RRef    CHAR(32),

    _ValueCt1_RRRef CHAR(32),
    _KindCt1RRef    CHAR(32),

    CreditID        CHAR(32),
    _KindDt2RRef    CHAR(32),

    [ПланыСчетов.Основной Код] NVARCHAR(50),
    [ПланыСчетов.Основной Наименование] NVARCHAR(256)
);
GO

DECLARE @DateFrom DATE = DATEADD(MONTH, -14, CAST(GETDATE() AS DATE)); 
DECLARE @DateTo   DATE = CAST(GETDATE() AS DATE);

INSERT INTO mis.Silver_Credit_Yield
(
    _Period,
    _RecorderRRef,

    _AccountDtRRef,
    _AccountCtRRef,

    _Fld11918DtRRef,
    _Fld11918CtRRef,
    _Fld11919RRef,

    _Fld11920,
    _Fld11921Dt,
    _Fld11921Ct,
    _Fld11922Dt,
    _Fld11922Ct,
    _Fld11923,
    _Fld11924Dt,
    _Fld11924Ct,
    _Fld11925,

    _ValueDt1_RRRef,
    _KindDt1RRef,

    _ValueCt1_RRRef,
    _KindCt1RRef,

    CreditID,
    _KindDt2RRef,

    [ПланыСчетов.Основной Код],
    [ПланыСчетов.Основной Наименование]
)
SELECT
    b._Period,
    CONVERT(CHAR(32), b._RecorderRRef, 2),

    CONVERT(CHAR(32), b._AccountDtRRef, 2),
    CONVERT(CHAR(32), b._AccountCtRRef, 2),

    CONVERT(CHAR(32), b._Fld11918DtRRef, 2),
    CONVERT(CHAR(32), b._Fld11918CtRRef, 2),
    CONVERT(CHAR(32), b._Fld11919RRef, 2),

    b._Fld11920,
    b._Fld11921Dt,
    b._Fld11921Ct,
    b._Fld11922Dt,
    b._Fld11922Ct,
    b._Fld11923,
    b._Fld11924Dt,
    b._Fld11924Ct,
    b._Fld11925,

    CONVERT(CHAR(32), b._ValueDt1_RRRef, 2),
    CONVERT(CHAR(32), b._KindDt1RRef, 2),

    CONVERT(CHAR(32), b._ValueCt1_RRRef, 2),
    CONVERT(CHAR(32), b._KindCt1RRef, 2),

    CONVERT(CHAR(32), b._ValueDt2_RRRef, 2) AS CreditID,
    CONVERT(CHAR(32), b._KindDt2RRef, 2),

    c.[ПланыСчетов.Основной Код],
    c.[ПланыСчетов.Основной Наименование]
FROM [Microinvest_Copy_Full].[dbo].[_AccRg11917] b
LEFT JOIN [ATK].[dbo].[ПланыСчетов.Основной] c
    ON c.[ПланыСчетов.Основной ID]
       = CONVERT(CHAR(32), b._AccountCtRRef, 2)
WHERE b._Period >= @DateFrom
  AND b._Period <  @DateTo;
GO
CREATE NONCLUSTERED INDEX IX_CreditYield_Period
ON mis.Silver_Credit_Yield (_Period);

CREATE NONCLUSTERED INDEX IX_CreditYield_CreditID
ON mis.Silver_Credit_Yield (CreditID);

CREATE NONCLUSTERED INDEX IX_CreditYield_Account
ON mis.Silver_Credit_Yield (_AccountCtRRef);

CREATE NONCLUSTERED INDEX IX_CreditYield_Recorder
ON mis.Silver_Credit_Yield (_RecorderRRef);
GO
