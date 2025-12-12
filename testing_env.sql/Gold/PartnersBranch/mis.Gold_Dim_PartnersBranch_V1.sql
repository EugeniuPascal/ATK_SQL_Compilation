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
	
	[PartnerOwnerName]              NVARCHAR(150) NULL,

    [DealerID]                      VARCHAR(36) NULL,
    [DealerDefaultEmployeeID]         VARCHAR(36) NULL,
    [DealerDefaultEmployeeName]       NVARCHAR(50) NULL,
    [DealerOrgRepID]                VARCHAR(36) NULL,
    [DealerOrgRepName]              NVARCHAR(50) NULL,
    [DealerCabinetID]               VARCHAR(36) NULL,
	[DealerCabinetType]             NVARCHAR(25) NULL
    
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
	
	[PartnerOwnerName],

    [DealerID],
    [DealerDefaultEmployeeID],
    [DealerDefaultEmployeeName],
    [DealerOrgRepID],
    [DealerOrgRepName],
	[DealerCabinetID],
	[DealerCabinetType]
)
SELECT
    f.[ФилиалыКонтрагентов ID] AS PartnerBranchID,
    f.[ФилиалыКонтрагентов Пометка Удаления] AS PartnerBranchDeletedFlag,
    f.[ФилиалыКонтрагентов Владелец] AS PartnerBranchOwner,
    f.[ФилиалыКонтрагентов Код] AS PartnerBranchCode,
    f.[ФилиалыКонтрагентов Наименование] AS PartnerBranchName,
    f.[ФилиалыКонтрагентов Адрес] AS PartnerBranchAddress,
	
	k.[Контрагенты Наименование] AS PartnerOwnerName,

    d.[Дилеры ID] AS DealerID,
    d.[Дилеры Эксперт по Умолчанию ID] AS DealerDefaultEmployeeID ,
    d.[Дилеры Эксперт по Умолчанию] AS DealerDefaultEmployeeName,
    d.[Дилеры Представитель Организации ID] AS DealerOrgRepID,
    d.[Дилеры Представитель Организации] AS DealerOrgRepName,
	d.[Дилеры Вид Кабинета ID] AS DealerCabinetID,
	d.[Дилеры Вид Кабинета] AS DealerCabinetType
	
FROM mis.[Bronze_Справочники.ФилиалыКонтрагентов] f
LEFT JOIN mis.[Bronze_Справочники.Дилеры] d
     ON d.[Дилеры Владелец] = f.[ФилиалыКонтрагентов ID]
LEFT JOIN mis.[Bronze_Справочники.Контрагенты] k
     ON k.[Контрагенты ID] = f.[ФилиалыКонтрагентов Владелец];
GO

