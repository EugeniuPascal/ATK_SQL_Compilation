USE [ATK];
SET NOCOUNT ON;
SET XACT_ABORT ON;


IF OBJECT_ID('mis.Silver_EmployeesPosition_SCD','U') IS NOT NULL
    DROP TABLE mis.Silver_EmployeesPosition_SCD;

CREATE TABLE mis.Silver_EmployeesPosition_SCD
(
      EmployeeID   varchar(36)   NOT NULL
    , PositionID   varchar(36)   NULL
    , PositionName nvarchar(255) NULL
    , BranchName   nvarchar(255) NULL

    , ValidFrom    datetime2(0)  NOT NULL
    , ValidTo      datetime2(0)  NOT NULL
    , IsCurrent    bit           NOT NULL

    , RowHash      varbinary(32) NOT NULL
    , SourcePeriod datetime2(0)  NOT NULL

    , CONSTRAINT PK_Silver_EmployeesPosition_SCD
        PRIMARY KEY CLUSTERED (EmployeeID, ValidFrom)
);

;WITH src0 AS
(
    SELECT
          PeriodDttm   = CAST(s.[СотрудникиДанныеПоЗарплате Период] AS datetime2(0))
        , EmployeeID   = CAST(s.[СотрудникиДанныеПоЗарплате Сотрудник ID] AS varchar(36))
        , PositionName = s.[СотрудникиДанныеПоЗарплате Должность]
        , PositionID   = CAST(s.[СотрудникиДанныеПоЗарплате Должность ID] AS varchar(36))
        , BranchName   = s.[СотрудникиДанныеПоЗарплате Филиал]
    FROM [ATK].[mis].[Bronze_РегистрыСведений.СотрудникиДанныеПоЗарплате] s
    WHERE s.[СотрудникиДанныеПоЗарплате Сотрудник ID] IS NOT NULL
      AND s.[СотрудникиДанныеПоЗарплате Период] IS NOT NULL
),
dedup AS
(
    SELECT *
    FROM
    (
        SELECT
              *
            , rn = ROW_NUMBER() OVER
              (
                PARTITION BY EmployeeID, PeriodDttm
                ORDER BY
                    ISNULL(PositionID,'') DESC,
                    ISNULL(BranchName,N'') DESC,
                    ISNULL(PositionName,N'') DESC
              )
        FROM src0
    ) x
    WHERE rn = 1
),
hashed AS
(
    SELECT
          PeriodDttm, EmployeeID, PositionID, PositionName, BranchName
        , RowHash = HASHBYTES(
            'SHA2_256',
            CONCAT(
                ISNULL(PositionID,''), '|',
                ISNULL(CONVERT(nvarchar(255), BranchName), N'')
            )
          )
    FROM dedup
),
chg AS
(
    SELECT
          *
        , PrevHash = LAG(RowHash) OVER (PARTITION BY EmployeeID ORDER BY PeriodDttm)
    FROM hashed
),
starts AS
(
    SELECT
          EmployeeID, PositionID, PositionName, BranchName
        , ValidFrom    = PeriodDttm
        , RowHash
        , SourcePeriod = PeriodDttm
    FROM chg
    WHERE PrevHash IS NULL OR PrevHash <> RowHash
),
scd AS
(
    SELECT
          s.*
        , NextFrom = LEAD(ValidFrom) OVER (PARTITION BY EmployeeID ORDER BY ValidFrom)
    FROM starts s
)
INSERT INTO mis.Silver_EmployeesPosition_SCD
(
    EmployeeID, PositionID, PositionName, BranchName,
    ValidFrom, ValidTo, IsCurrent,
    RowHash, SourcePeriod
)
SELECT
      EmployeeID, PositionID, PositionName, BranchName
    , ValidFrom
    , CASE
        WHEN NextFrom IS NULL THEN CONVERT(datetime2(0),'9999-12-31 23:59:59')
        ELSE DATEADD(second, -1, NextFrom)
      END AS ValidTo
    , CASE WHEN NextFrom IS NULL THEN 1 ELSE 0 END AS IsCurrent
    , RowHash
    , SourcePeriod
FROM scd;

CREATE INDEX IX_Silver_EmployeesPosition_SCD_Current
ON mis.Silver_EmployeesPosition_SCD(EmployeeID, IsCurrent)
INCLUDE(PositionID, PositionName, BranchName, ValidFrom, ValidTo);

CREATE INDEX IX_Silver_EmployeesPosition_SCD_AsOf
ON mis.Silver_EmployeesPosition_SCD(EmployeeID, ValidFrom, ValidTo)
INCLUDE(PositionID, PositionName, BranchName);