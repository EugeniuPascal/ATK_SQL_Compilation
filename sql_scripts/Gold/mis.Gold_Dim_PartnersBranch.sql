USE [ATK];
GO

IF OBJECT_ID('mis.[Gold_Dim_PartnersBranch]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Dim_PartnersBranch];
GO

CREATE TABLE mis.[Gold_Dim_PartnersBranch]
(
    [PartnerBranchID]               VARCHAR(36) NOT NULL,
    [PartnerBranchDeletedFlag]      VARCHAR(36) NOT NULL,
    [PartnerBranchOwner]            VARCHAR(36) NOT NULL,
    [PartnerBranchCode]             NVARCHAR(3)   NOT NULL,
    [PartnerBranchName]             NVARCHAR(150) NULL,
    [PartnerBranchAddress]          NVARCHAR(100) NULL,

    [DealerID]                      VARCHAR(36) NULL,
    [DealerDefaultEmployeeID]         VARCHAR(36) NULL,
    [DealerDefaultEmployeeName]       NVARCHAR(50) NULL,
    [DealerOrgRepID]                VARCHAR(36) NULL,
    [DealerOrgRepName]              NVARCHAR(50) NULL

);
GO

INSERT INTO mis.[Gold_Dim_PartnersBranch]
(
    [PartnerBranchID],
    [PartnerBranchDeletedFlag],
    [PartnerBranchOwner],
    [PartnerBranchCode],
    [PartnerBranchName],
    [PartnerBranchAddress],

    [DealerID],
    [DealerDefaultEmployeeID],
    [DealerDefaultEmployeeName],
    [DealerOrgRepID],
    [DealerOrgRepName]
)
SELECT
    f.[ФилиалыКонтрагентов ID] AS PartnerBranchID,
    f.[ФилиалыКонтрагентов Пометка Удаления] AS PartnerBranchDeletedFlag,
    f.[ФилиалыКонтрагентов Владелец] AS PartnerBranchOwner,
    f.[ФилиалыКонтрагентов Код] AS PartnerBranchCode,
    f.[ФилиалыКонтрагентов Наименование] AS PartnerBranchName,
    f.[ФилиалыКонтрагентов Адрес] AS PartnerBranchAddress,

    d.[Дилеры ID] AS DealerID,
    d.[Дилеры Эксперт по Умолчанию ID] AS DealerDefaultEmployeeID ,
    d.[Дилеры Эксперт по Умолчанию] AS DealerDefaultEmployeeName,
    d.[Дилеры Представитель Организации ID] AS DealerOrgRepID,
    d.[Дилеры Представитель Организации] AS DealerOrgRepName
FROM mis.[Bronze_Справочники.ФилиалыКонтрагентов] f
LEFT JOIN mis.[Bronze_Справочники.Дилеры] d
  ON d.[Дилеры Владелец] = f.[ФилиалыКонтрагентов ID];
GO