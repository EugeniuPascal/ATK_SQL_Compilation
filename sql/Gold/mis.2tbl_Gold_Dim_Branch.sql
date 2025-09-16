USE [ATK];
GO

-- Drop the table if it exists
IF OBJECT_ID(N'mis.[2tbl_Gold_Dim_Branch]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_Branch];
GO

-- Create the table
CREATE TABLE mis.[2tbl_Gold_Dim_Branch] (
    BranchID NVARCHAR(100) NOT NULL,
    BranchCode NVARCHAR(50) NULL,
    BranchName NVARCHAR(255) NULL,
    DistrictName NVARCHAR(255) NULL,
    ActivityType NVARCHAR(255) NULL,
    EFSERegion NVARCHAR(255) NULL,
    Address NVARCHAR(500) NULL,
    Phones NVARCHAR(255) NULL,
    Email NVARCHAR(255) NULL,
    PrintBranchName NVARCHAR(255) NULL,
    Latitude DECIMAL(9, 6) NULL,
    Longitude DECIMAL(9, 6) NULL,
    --BranchCity NVARCHAR(255) NULL,
    BranchDepartment NVARCHAR(255) NULL,
    BranchRegion NVARCHAR(255) NULL
);
GO

WITH LastSvedeniya AS (
    SELECT 
        [СведенияОФилиалах Филиал ID],
        [СведенияОФилиалах Дирекция],
        [СведенияОФилиалах Регион],
        ROW_NUMBER() OVER (
            PARTITION BY [СведенияОФилиалах Филиал ID] 
            ORDER BY [СведенияОФилиалах Период] DESC
        ) AS rn
    FROM [ATK].[dbo].[РегистрыСведений.СведенияОФилиалах]
)
INSERT INTO mis.[2tbl_Gold_Dim_Branch] (
    BranchID,
    BranchCode,
    BranchName,
    DistrictName,
    ActivityType,
    EFSERegion,
    Address,
    Phones,
    Email,
    PrintBranchName,
    Latitude,
    Longitude,
   --BranchCity,
    BranchDepartment,
    BranchRegion
)
SELECT
    f.[Филиалы ID] AS [BranchID],
    f.[Филиалы Код],
    f.[Филиалы Наименование],
    f.[Филиалы Наименование Района],
    f.[Филиалы Вид Деятельности],
    f.[Филиалы Регион EFSE],
    f.[Филиалы Адрес],
    f.[Филиалы Телефоны],
    f.[Филиалы Электронный Адрес],
    f.[Филиалы Наименование Филиала для Печати],
    f.[Филиалы Координаты Широта],
    f.[Филиалы Координаты Долгота],
    --f.[Филиалы Город],
    s.[СведенияОФилиалах Дирекция],
    s.[СведенияОФилиалах Регион]
FROM [ATK].[dbo].[Справочники.Филиалы] f
LEFT JOIN LastSvedeniya s
    ON f.[Филиалы ID] = s.[СведенияОФилиалах Филиал ID]
    AND s.rn = 1;
GO
