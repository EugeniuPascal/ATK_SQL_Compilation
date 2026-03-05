USE [ATK];
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'[mis].[Gold_Dim_Clients]', N'U') IS NOT NULL
    DROP TABLE [mis].[Gold_Dim_Clients];

;WITH EvPhone AS (
    SELECT
          e.[КонтрагентID] AS ClientID
        , PhoneVal = NULLIF(LTRIM(RTRIM(e.[ТелефонМобильный])), '')
        , e.[Дата]
        , e.[ID]
        , rn = ROW_NUMBER() OVER (
            PARTITION BY e.[КонтрагентID]
            ORDER BY e.[Дата] DESC, e.[ID] DESC
        )
    FROM mis.Silver_Events e
    WHERE NULLIF(LTRIM(RTRIM(e.[ТелефонМобильный])), '') IS NOT NULL
),
EvFisk AS (
    SELECT
          e.[КонтрагентID] AS ClientID
        , FiskVal = NULLIF(LTRIM(RTRIM(e.[ФискКод])), '')
        , e.[Дата]
        , e.[ID]
        , rn = ROW_NUMBER() OVER (
            PARTITION BY e.[КонтрагентID]
            ORDER BY e.[Дата] DESC, e.[ID] DESC
        )
    FROM mis.Silver_Events e
    WHERE NULLIF(LTRIM(RTRIM(e.[ФискКод])), '') IS NOT NULL
),
VenitHotare AS (
    SELECT
        v.[Клиент ID] AS ClientID,
        Venit_dupa_hotare =
            CASE
                WHEN SUM(
                    CASE
                        WHEN v.[Вид Дохода] = N'ЗаграничныйДоход'
                             AND v.[Не Получает] IS NOT NULL
                             AND v.[Не Получает] <> 0x01
                        THEN 1 ELSE 0
                    END
                ) > 0 THEN 1 ELSE 0
            END
    FROM [mis].[Bronze_РегистрыСведений.СведенияОПрочихДоходахКлиента] v   
    GROUP BY v.[Клиент ID]
),
CtrBranch AS (
    SELECT
        c.[Контрагенты ID]        AS ClientID,
        c.[Контрагенты Филиал ID] AS [Филиал ID]
    FROM [mis].[Bronze_Справочники.Контрагенты] c
)
SELECT
    g.*,
    ph.PhoneVal AS [ТелефонМобильный_Last],
    ph.[Дата]   AS [ТелефонМобильный_LastDate],
    ph.[ID]     AS [ТелефонМобильный_LastEventID],
    fc.FiskVal  AS [ФискКод_Last],
    fc.[Дата]   AS [ФискКод_LastDate],
    fc.[ID]     AS [ФискКод_LastEventID],
    ISNULL(vh.Venit_dupa_hotare, 0) AS [Venit_dupa_hotare],
    cb.[Филиал ID]                  AS [Филиал ID]
INTO [mis].[Gold_Dim_Clients]
FROM [mis].[Silver_Clients_base] g
LEFT JOIN EvPhone ph
  ON ph.ClientID = g.[ClientID] AND ph.rn = 1
LEFT JOIN EvFisk fc
  ON fc.ClientID = g.[ClientID] AND fc.rn = 1
LEFT JOIN VenitHotare vh
  ON vh.ClientID = g.[ClientID]
LEFT JOIN CtrBranch cb
  ON cb.ClientID = g.[ClientID];
