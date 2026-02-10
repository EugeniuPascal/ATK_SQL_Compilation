USE [ATK];
GO

IF OBJECT_ID('mis.[Gold_Dim_Events]', 'U') IS NULL
BEGIN
    CREATE TABLE mis.[Gold_Dim_Events]
    (
        Event_Period        DATETIME        NOT NULL,
        Event_ID            VARCHAR(36)     NOT NULL PRIMARY KEY,
        Event_ClientID      VARCHAR(36)     NOT NULL,
        Event_Status        NVARCHAR(256)   NULL,
        Event_Kind          NVARCHAR(256)   NULL,
        Event_Type          NVARCHAR(256)   NULL,
        Event_Project       NVARCHAR(150)   NULL,
        Event_Content       NVARCHAR(1000)  NULL,
        Event_ResponsibleID VARCHAR(36)     NOT NULL,
        Event_Responsible   NVARCHAR(1000)  NULL,
        Event_NextDateEvent DATETIME        NOT NULL,
        Event_NextKindEvent NVARCHAR(256)   NULL,
        Event_BranchID      VARCHAR(36)     NOT NULL,
        Event_Branch_Name   NVARCHAR(256)   NULL,
        EmployeePosition    NVARCHAR(100)   NULL,
        EmployeeBranch      NVARCHAR(100)   NULL
    );
END
GO

IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IX_Salary_Employee_Period' 
      AND object_id = OBJECT_ID('mis.[Bronze_РегистрыСведений.СотрудникиДанныеПоЗарплате]')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Salary_Employee_Period
    ON mis.[Bronze_РегистрыСведений.СотрудникиДанныеПоЗарплате]
    (
        [СотрудникиДанныеПоЗарплате Сотрудник ID],
        [СотрудникиДанныеПоЗарплате Период] DESC
    )
    INCLUDE ([СотрудникиДанныеПоЗарплате Должность],
             [СотрудникиДанныеПоЗарплате Филиал]);
END
GO

INSERT INTO mis.[Gold_Dim_Events]
(
    Event_Period,
    Event_ID,
    Event_ClientID,
    Event_Status,
    Event_Kind,
    Event_Type,
    Event_Project,
    Event_Content,
    Event_ResponsibleID,
    Event_Responsible,
    Event_NextDateEvent,
    Event_NextKindEvent,
    Event_BranchID,
    Event_Branch_Name,
    EmployeePosition,
    EmployeeBranch
)
SELECT
    e.[СведенияОСобытиях Период],
    e.[СведенияОСобытиях ID],
    e.[СведенияОСобытиях Контрагент ID],
    e.[СведенияОСобытиях Состояние События],
    e.[СведенияОСобытиях Вид События],
    e.[СведенияОСобытиях Тип События],
    e.[СведенияОСобытиях Проект],
    e.[СведенияОСобытиях Содержание События],
    e.[СведенияОСобытиях Ответственный ID],
    e.[СведенияОСобытиях Ответственный],
    e.[СведенияОСобытиях Дата Следующего События],
    e.[СведенияОСобытиях Вид Следующего События],
    e.[СведенияОСобытиях Филиал ID],
    e.[СведенияОСобытиях Филиал],
    s.[СотрудникиДанныеПоЗарплате Должность],
    s.[СотрудникиДанныеПоЗарплате Филиал]
FROM [ATK].[dbo].[РегистрыСведений.СведенияОСобытиях] e
OUTER APPLY
(
    SELECT TOP 1
           p.[СотрудникиДанныеПоЗарплате Должность],
           p.[СотрудникиДанныеПоЗарплате Филиал]
    FROM mis.[Bronze_РегистрыСведений.СотрудникиДанныеПоЗарплате] p
    WHERE p.[СотрудникиДанныеПоЗарплате Сотрудник ID] = e.[СведенияОСобытиях Ответственный ID]
      AND p.[СотрудникиДанныеПоЗарплате Период] <= e.[СведенияОСобытиях Период]
    ORDER BY p.[СотрудникиДанныеПоЗарплате Период] DESC
) s
WHERE NOT EXISTS (
    SELECT 1
    FROM mis.[Gold_Dim_Events] g
    WHERE g.Event_ID = e.[СведенияОСобытиях ID]
);
GO
