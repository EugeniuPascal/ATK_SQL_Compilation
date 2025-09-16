USE [ATK];
GO

IF OBJECT_ID('mis.[2tbl_Gold_Fact_CerereCredit]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Fact_CerereCredit];
GO

CREATE TABLE mis.[2tbl_Gold_Fact_CerereCredit] (
    AppID                VARCHAR(36)   NOT NULL,
    Date                 DATETIME      NULL,
    Nr                   NVARCHAR(50)  NULL,
    Posted               VARCHAR(36)   NOT NULL,
    Author               NVARCHAR(256) NULL,
    Agro                 NVARCHAR(256) NULL,
    AlternativeSector    NVARCHAR(150) NULL,
    BusinessOrg          NVARCHAR(100) NULL,
    BusinessSector       NVARCHAR(150) NULL,
    Currency             NVARCHAR(50)  NULL,
    Type                 NVARCHAR(100) NULL,
    CreditHistType       NVARCHAR(256) NULL,
    CollateralType       NVARCHAR(256) NULL,
    RefusalType          NVARCHAR(256) NULL,
    PaymentType          NVARCHAR(256) NULL,
    DebtRestructType     NVARCHAR(256) NULL,
    EnergyEffType        NVARCHAR(150) NULL,
    Dealer               NVARCHAR(150) NULL,
    ClientWebID          VARCHAR(36)   NULL,
    ClientWeb            NVARCHAR(100) NULL,
    Identifier           NVARCHAR(50)  NULL,
    ClientName           NVARCHAR(100) NULL,
    LoanPurposeCat       NVARCHAR(256) NULL,
    EnergyEffCat         NVARCHAR(150) NULL,
    ClientID             VARCHAR(36)   NULL,
    Client               NVARCHAR(100) NULL,
    FamilyTotal          INT           NULL,
    FamilyDependants     INT           NULL,
    CommitteeID          VARCHAR(36)   NULL,
    Committee            NVARCHAR(150) NULL,
    CreditID             VARCHAR(36)   NULL,
    CreditProdID         VARCHAR(36)   NULL,
    CreditExpertID       VARCHAR(36)   NULL,
    CreditExpert         NVARCHAR(50)  NULL,
    RefusalReason        NVARCHAR(200) NULL,
    CommitteeProtID      VARCHAR(36)   NULL,
    CommitteeProt        NVARCHAR(100) NULL,
    CommitteeDecision    NVARCHAR(256) NULL,
    EconSector           NVARCHAR(150) NULL,
    FinalScore           DECIMAL(10,2) NULL,
    Status               NVARCHAR(256) NULL,
    LoanTerm             INT           NULL,
    WorkExpTotal         INT           NULL,
    LoanAmount           DECIMAL(18,2) NULL,
    FinRiskLevel         DECIMAL(10,2) NULL,
    BranchID             VARCHAR(36)   NULL,
    PartnerBranch        NVARCHAR(150) NULL,
    FinProdID            VARCHAR(36)   NULL,
    FinProd              NVARCHAR(100) NULL,
    LoanPurpose          NVARCHAR(100) NULL,
    IsGreenLoan          NVARCHAR(36)  NULL
);
GO

INSERT INTO mis.[2tbl_Gold_Fact_CerereCredit] (
    AppID, Date, Nr, Posted, Author, Agro, AlternativeSector,
    BusinessOrg, BusinessSector, Currency, Type, CreditHistType, CollateralType,
    RefusalType, PaymentType, DebtRestructType, EnergyEffType, Dealer,
    ClientWebID, ClientWeb, Identifier, ClientName, LoanPurposeCat, EnergyEffCat,
    ClientID, Client, FamilyTotal, FamilyDependants, CommitteeID, Committee,
    CreditID, CreditProdID, CreditExpertID, CreditExpert, RefusalReason,
    CommitteeProtID, CommitteeProt, CommitteeDecision, EconSector, FinalScore,
    Status, LoanTerm, WorkExpTotal, LoanAmount, FinRiskLevel,
    BranchID, PartnerBranch, FinProdID, FinProd, LoanPurpose, IsGreenLoan
)
SELECT
    [ЗаявкаНаКредит ID], [ЗаявкаНаКредит Дата], [ЗаявкаНаКредит Номер], [ЗаявкаНаКредит Проведен],
    [ЗаявкаНаКредит Автор], [ЗаявкаНаКредит Агро], [ЗаявкаНаКредит Альтернативный Сектор Экономики],
    [ЗаявкаНаКредит Бизнес Организация], [ЗаявкаНаКредит Бизнес Сектор Экономики], [ЗаявкаНаКредит Валюта],
    [ЗаявкаНаКредит Вид Заявки], [ЗаявкаНаКредит Вид Кредитной Истории], [ЗаявкаНаКредит Вид Обеспечения],
    [ЗаявкаНаКредит Вид Отказа], [ЗаявкаНаКредит Вид Перечисления], [ЗаявкаНаКредит Вид Реструктуризации Долга],
    [ЗаявкаНаКредит Вид Энергетической Эффективности], [ЗаявкаНаКредит Дилер], [ЗаявкаНаКредит Заявка Клиента Интернет ID],
    [ЗаявкаНаКредит Заявка Клиента Интернет], [ЗаявкаНаКредит Идентификатор], [ЗаявкаНаКредит Имя Клиента],
    [ЗаявкаНаКредит Категория Цель Кредита], [ЗаявкаНаКредит Категория Энергетической Эффективности],
    [ЗаявкаНаКредит Клиент ID], [ЗаявкаНаКредит Клиент], [ЗаявкаНаКредит Количество Членов Семьи Итого],
    [ЗаявкаНаКредит Количество Членов Семьи на Иждевении], [ЗаявкаНаКредит Комитет ID], [ЗаявкаНаКредит Комитет],
    [ЗаявкаНаКредит Кредит ID], [ЗаявкаНаКредит Кредитный Продукт ID], [ЗаявкаНаКредит Кредитный Эксперт ID],
    [ЗаявкаНаКредит Кредитный Эксперт], [ЗаявкаНаКредит Причина Отказа], [ЗаявкаНаКредит Протокол Комитета ID],
    [ЗаявкаНаКредит Протокол Комитета], [ЗаявкаНаКредит Решение Комитета], [ЗаявкаНаКредит Сектор Экономики],
    [ЗаявкаНаКредит Скоринг Финальная Оценка], [ЗаявкаНаКредит Состояние Заявки], [ЗаявкаНаКредит Срок Кредита],
    [ЗаявкаНаКредит Стаж Работы Общий], [ЗаявкаНаКредит Сумма Кредита], [ЗаявкаНаКредит Уровень Финансового Риска],
    [ЗаявкаНаКредит Филиал ID], [ЗаявкаНаКредит Филиал Партнера], [ЗаявкаНаКредит Финансовый Продукт ID],
    [ЗаявкаНаКредит Финансовый Продукт], [ЗаявкаНаКредит Цель Кредита], [ЗаявкаНаКредит Это Зеленый Кредит]
FROM [ATK].[mis].[Silver_Документы.ЗаявкаНаКредит]
WHERE [ЗаявкаНаКредит Проведен] = 1
AND [ЗаявкаНаКредит Дата] >= '2023-01-01';
GO

CREATE NONCLUSTERED INDEX IX_CC_Date   ON mis.[2tbl_Gold_Fact_CerereCredit](Date);
CREATE NONCLUSTERED INDEX IX_CC_Client ON mis.[2tbl_Gold_Fact_CerereCredit](ClientID) 
    INCLUDE (LoanAmount, Status);
GO
