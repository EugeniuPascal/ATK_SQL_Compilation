USE [ATK];
GO

-- Drop the gold table if it exists
IF OBJECT_ID('mis.[2tbl_Gold_Dim_PartnersBranch]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_PartnersBranch];
GO

-- Create gold table with only essential columns
CREATE TABLE mis.[2tbl_Gold_Dim_PartnersBranch]
(
    [PartnerBranchID]               VARCHAR(36) NOT NULL,
    [PartnerBranchDeletedFlag]      VARCHAR(36) NOT NULL,
    [PartnerBranchOwner]            VARCHAR(36) NOT NULL,
    [PartnerBranchCode]             NVARCHAR(3)   NOT NULL,
    [PartnerBranchName]             NVARCHAR(150) NULL,
    [PartnerBranchAddress]          NVARCHAR(100) NULL,
    [PartnerBranchMainBrandID]      VARCHAR(36) NOT NULL,

    [DealerID]                      VARCHAR(36) NULL,
    [DealerDefaultExpertID]         VARCHAR(36) NULL,
    [DealerDefaultExpertName]       NVARCHAR(50) NULL,
    [DealerOrgRepID]                VARCHAR(36) NULL,
    [DealerOrgRepName]              NVARCHAR(50) NULL

);
GO

-- Insert data from silvers
INSERT INTO mis.[2tbl_Gold_Dim_PartnersBranch]
(
    [PartnerBranchID],
    [PartnerBranchDeletedFlag],
    [PartnerBranchOwner],
    [PartnerBranchCode],
    [PartnerBranchName],
    [PartnerBranchAddress],
    [PartnerBranchMainBrandID],

    [DealerID],
    [DealerDefaultExpertID],
    [DealerDefaultExpertName],
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
    f.[ФилиалыКонтрагентов Основная Торговая Марка ID] AS PartnerBranchMainBrandID,

    d.[Дилеры ID] AS DealerID,
    d.[Дилеры Эксперт по Умолчанию ID] AS DealerDefaultExpertID ,
    d.[Дилеры Эксперт по Умолчанию] AS DealerDefaultExpertName,
    d.[Дилеры Представитель Организации ID] AS DealerOrgRepID,
    d.[Дилеры Представитель Организации] AS DealerOrgRepName
FROM mis.[Silver_Справочники.ФилиалыКонтрагентов] f
LEFT JOIN mis.[Silver_Справочники.Дилеры] d
  ON d.[Дилеры Владелец] = f.[ФилиалыКонтрагентов ID];
GO