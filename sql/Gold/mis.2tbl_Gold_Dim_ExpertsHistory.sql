USE [ATK];
GO


IF OBJECT_ID('mis.[2tbl_Gold_Dim_ExpertsHistory]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_ExpertsHistory];
GO


CREATE TABLE mis.[2tbl_Gold_Dim_ExpertsHistory] (
    Period       DATETIME      NULL,
    Registrar_TRef NVARCHAR(100) NULL,
    ID           VARCHAR(36)   NOT NULL,
    RowNumber    INT           NULL,
    IsActive     VARCHAR(36)   NULL,
    Credit_ID    VARCHAR(36)   NULL,
    Credit       NVARCHAR(100) NULL,
    Filial_ID    VARCHAR(36)   NULL,
    Filial       NVARCHAR(100) NULL,
    Expert_ID    VARCHAR(36)   NULL,
    Expert       NVARCHAR(100) NULL,
    DateTo       DATETIME      NULL
);
GO

INSERT INTO mis.[2tbl_Gold_Dim_ExpertsHistory] (
    Period,
    Registrar_TRef,
    ID,
    RowNumber,
    IsActive,
    Credit_ID,
    Credit,
    Filial_ID,
    Filial,
    Expert_ID,
    Expert,
    DateTo
)
SELECT
    [ОтветственныеПоКредитамВыданным Период]                    AS Period,
    [ОтветственныеПоКредитамВыданным Регистратор _TRef]         AS Registrar_TRef,
    [ОтветственныеПоКредитамВыданным ID]                        AS ID,         
    [ОтветственныеПоКредитамВыданным Номер Строки]              AS RowNumber,
    [ОтветственныеПоКредитамВыданным Активность]                AS IsActive,
    [ОтветственныеПоКредитамВыданным Кредит ID]                 AS Credit_ID,
    [ОтветственныеПоКредитамВыданным Кредит]                    AS Credit,
    [ОтветственныеПоКредитамВыданным Филиал ID]                 AS Filial_ID,
    [ОтветственныеПоКредитамВыданным Филиал]                    AS Filial,
    [ОтветственныеПоКредитамВыданным Кредитный Эксперт ID]      AS Expert_ID,
    [ОтветственныеПоКредитамВыданным Кредитный Эксперт]         AS Expert,
    ISNULL(
        LEAD([ОтветственныеПоКредитамВыданным Период]) OVER (
            PARTITION BY [ОтветственныеПоКредитамВыданным Кредит ID]
            ORDER BY [ОтветственныеПоКредитамВыданным Период], [ОтветственныеПоКредитамВыданным Номер Строки]
        ),
        CONVERT(DATETIME, '2222-01-01', 120)
    )                                                           AS DateTo
FROM [ATK].[mis].[Silver_РегистрыСведений.ОтветственныеПоКредитамВыданным];
GO
