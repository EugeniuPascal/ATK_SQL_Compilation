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
    [PartnerBranchCode]             NVARCHAR(3) NOT NULL,
    [PartnerBranchName]             NVARCHAR(150) NULL,
    [PartnerBranchAddress]          NVARCHAR(100) NULL,

    [PartnerOwnerName]              NVARCHAR(150) NULL,

    [DealerID]                      VARCHAR(36) NULL,
    [DealerDefaultEmployeeID]       VARCHAR(36) NULL,
    [DealerDefaultEmployeeName]     NVARCHAR(50) NULL,
    [DealerOrgRepID]                VARCHAR(36) NULL,
    [DealerOrgRepName]              NVARCHAR(50) NULL,
    [DealerCabinetID]               VARCHAR(36) NULL,
    [DealerCabinetType]             NVARCHAR(25) NULL,
    [Contact_Info]                  NVARCHAR(150) NULL
);
GO

;WITH ContactInfoRanked AS
(
    SELECT
        ci.[КонтактнаяИнформация Объект ID] AS ObjectID,
        ci.[КонтактнаяИнформация Поле 2]    AS Contact_Info,
        ROW_NUMBER() OVER
        (
            PARTITION BY ci.[КонтактнаяИнформация Объект ID]
            ORDER BY CASE ci.[КонтактнаяИнформация Вид]
                         WHEN '9BD07509DFA6385644A4DA59663DE54A' THEN 1
                         WHEN '855E215869755D34405C9E2F87D961A6' THEN 2
                         ELSE 3
                     END
        ) AS rn
    FROM dbo.[РегистрыСведений.КонтактнаяИнформация] ci
    WHERE ci.[КонтактнаяИнформация Вид] IN
          (
              '9BD07509DFA6385644A4DA59663DE54A',
              '855E215869755D34405C9E2F87D961A6'
          )
)
INSERT INTO mis.[Gold_Dim_PartnersBranch]
(
    PartnerBranchID,
    PartnerBranchDeletedFlag,
    PartnerBranchOwner,
    PartnerBranchCode,
    PartnerBranchName,
    PartnerBranchAddress,
    PartnerOwnerName,
    DealerID,
    DealerDefaultEmployeeID,
    DealerDefaultEmployeeName,
    DealerOrgRepID,
    DealerOrgRepName,
    DealerCabinetID,
    DealerCabinetType,
    Contact_Info
)
SELECT
    f.[ФилиалыКонтрагентов ID],
    f.[ФилиалыКонтрагентов Пометка Удаления],
    f.[ФилиалыКонтрагентов Владелец],
    f.[ФилиалыКонтрагентов Код],
    f.[ФилиалыКонтрагентов Наименование],
    f.[ФилиалыКонтрагентов Адрес],

    k.[Контрагенты Наименование],

    d.[Дилеры ID],
    d.[Дилеры Эксперт по Умолчанию ID],
    d.[Дилеры Эксперт по Умолчанию],
    d.[Дилеры Представитель Организации ID],
    d.[Дилеры Представитель Организации],
    d.[Дилеры Вид Кабинета ID],
    d.[Дилеры Вид Кабинета],

    ci.Contact_Info
FROM mis.[Bronze_Справочники.ФилиалыКонтрагентов] f
LEFT JOIN mis.[Bronze_Справочники.Дилеры] d
       ON d.[Дилеры Владелец] = f.[ФилиалыКонтрагентов ID]
LEFT JOIN mis.[Bronze_Справочники.Контрагенты] k
       ON k.[Контрагенты ID] = f.[ФилиалыКонтрагентов Владелец]
LEFT JOIN ContactInfoRanked ci
       ON ci.ObjectID = k.[Контрагенты ID]
      AND ci.rn = 1;
GO
