INSERT INTO mis.[Gold_Dim_Event_Responsible]
(
    EventDocumentID,
    EventRowNumber,
    ClientType,
    ClientKind,
    ClientID,
    EventStatus,
    ResponsibleID,
    ResponsibleName,
    SelectionFlag,
    NewResponsibleID,
    NewResponsibleName,
    NewBranchID,
    NewBranchName,
    AffiliatedGroupID,
    AffiliatedGroupName
)
SELECT
    [УстановкаОтветственныхПоКредитамИКлиентам ID]                             AS EventDocumentID,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Номер Строки]           AS EventRowNumber,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Клиент Tип]             AS ClientType,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Клиент Вид]             AS ClientKind,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Клиент ID]              AS ClientID,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Состояние События]      AS EventStatus,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Ответственный ID]       AS ResponsibleID,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Ответственный]          AS ResponsibleName,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Отметка Выбора]         AS SelectionFlag,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Новый Ответственный ID] AS NewResponsibleID,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Новый Ответственный]    AS NewResponsibleName,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Новый Филиал ID]        AS NewBranchID,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Новый Филиал]           AS NewBranchName,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Группа Аффилированных Лиц ID]  AS AffiliatedGroupID,
    [УстановкаОтветственныхПоКредитамИКлиентам.События Группа Аффилированных Лиц]     AS AffiliatedGroupName
	
FROM [ATK].[dbo].[Документы.УстановкаОтветственныхПоКредитамИКлиентам.События] e
WHERE NOT EXISTS (
    SELECT 1
    FROM mis.[Gold_Dim_Event_Responsible] g
    WHERE g.EventDocumentID = e.[УстановкаОтветственныхПоКредитамИКлиентам ID]
      AND g.EventRowNumber  = e.[УстановкаОтветственныхПоКредитамИКлиентам.События Номер Строки]
);
