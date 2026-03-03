USE [ATK];
GO

IF OBJECT_ID('mis.Dim_BlacklistClients', 'U') IS NOT NULL
    DROP TABLE mis.Dim_BlacklistClients;
GO

SELECT 
    [КонтрагентыВЧерномСписке IDNO],
    [КонтрагентыВЧерномСписке Клиент ID],
    [КонтрагентыВЧерномСписке Комментарий],
    [КонтрагентыВЧерномСписке Решение Комитета],
    [КонтрагентыВЧерномСписке Статус]
INTO mis.Dim_BlacklistClients
FROM
(
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY [КонтрагентыВЧерномСписке Клиент ID]
               ORDER BY [КонтрагентыВЧерномСписке Период] DESC  
           ) AS rn
    FROM [ATK].[dbo].[РегистрыСведений.КонтрагентыВЧерномСписке]
) AS LastStatus
WHERE rn = 1
  AND [КонтрагентыВЧерномСписке Статус] = 'Активный';
GO