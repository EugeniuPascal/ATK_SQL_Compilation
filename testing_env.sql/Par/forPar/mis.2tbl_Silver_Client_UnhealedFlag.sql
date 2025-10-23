/* ПАРАМЕТРЫ ДИАПАЗОНА (поставь свои даты) */
DECLARE @DateFrom date = '2024-01-01';
DECLARE @DateTo   date = '2025-12-31';
 
/* 4.1 Таблица для результата */
IF OBJECT_ID('[ATK].[mis].[2tbl_Silver_Client_UnhealedFlag]','U') IS NULL
BEGIN
    CREATE TABLE [ATK].[mis].[2tbl_Silver_Client_UnhealedFlag] (
        ClientID    varchar(64) NOT NULL,
        SoldDate    date        NOT NULL,
        HasUnhealed bit         NOT NULL,
        CONSTRAINT PK_Silver_Client_Unhealed PRIMARY KEY (ClientID, SoldDate)
    );
END
 
/* опционально: «чистим» только пересчитываемый диапазон */
DELETE FROM [ATK].[mis].[2tbl_Silver_Client_UnhealedFlag]
WHERE SoldDate BETWEEN @DateFrom AND @DateTo;
 
/* 4.2 Интервалы по кредитам, где состояние = 'НеИзлеченный' */
WITH UnhealedIntervals AS (
    SELECT
        m.CreditID,
        CASE WHEN m.ValidFrom < @DateFrom THEN @DateFrom ELSE m.ValidFrom END AS FromDate,
        CASE WHEN m.ValidTo   > @DateTo   THEN @DateTo   ELSE m.ValidTo   END AS ToDate
    FROM [ATK].[mis].[2tbl_Silver_Restruct_Merged_SCD] m
    WHERE m.StateName = N'НеИзлеченный'
      AND m.ValidFrom <= @DateTo
      AND m.ValidTo   >= @DateFrom
),
/* 4.3 Tally (генератор чисел) — чтобы развернуть интервалы в отдельные дни */
Nums AS (
    SELECT TOP (40000)                -- хватит ~110 лет; при необходимости увеличь TOP
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
),
/* 4.4 Разворачиваем интервалы в даты */
UnhealedDays AS (
    SELECT ui.CreditID,
           DATEADD(day, n.n, ui.FromDate) AS SoldDate
    FROM UnhealedIntervals ui
    JOIN Nums n
      ON n.n <= DATEDIFF(day, ui.FromDate, ui.ToDate)
),
/* 4.5 Подтягиваем клиента по кредиту */
ByClient AS (
    SELECT dc.[Owner] AS ClientID,
           d.SoldDate
    FROM UnhealedDays d
    JOIN [ATK].[mis].[2tbl_Gold_Dim_Credits] dc
      ON dc.[CreditID] = d.CreditID
)
/* 4.6 Заполняем флаг (агрегируем до Client+Date) */
INSERT INTO [ATK].[mis].[2tbl_Silver_Client_UnhealedFlag] (ClientID, SoldDate, HasUnhealed)
SELECT bc.ClientID,
       bc.SoldDate,
       CAST(1 AS bit) AS HasUnhealed
FROM ByClient bc
GROUP BY bc.ClientID, bc.SoldDate;