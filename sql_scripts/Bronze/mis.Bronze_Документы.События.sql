USE [ATK];
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'[mis].[Bronze_Документы.События]', N'U') IS NOT NULL
    DROP TABLE [mis].[Bronze_Документы.События];

CREATE TABLE [mis].[Bronze_Документы.События] 
(
      [ID]                         BINARY(16)       NOT NULL,
      [ПометкаУдаления]            BINARY(1)        NULL,
      [Дата]                       DATETIME2        NULL,
      [Проведен]                   BINARY(1)        NULL,
      [Номер]                      NUMERIC(9,0)     NULL,
      [СтатусыТелефонногоЗвонкаID] BINARY(16)       NULL,
      [ДатаСоздания]               DATETIME2        NULL,
      [ДатаПроведения]             DATETIME2        NULL,
      [АвторID]                    BINARY(16)       NULL,
      [КонтрагентID]               BINARY(16)       NULL,
      [КредитID]                   BINARY(16)       NULL,
      [ВидСобытияID]               BINARY(16)       NULL,
      [ОписаниеСобытия]            NVARCHAR(200)    NULL,
      [ОтветственныйID]            VARCHAR(34)      NULL,
      [ПроектID]                   BINARY(16)       NULL,
      [СодержаниеСобытия]          NVARCHAR(max)    NULL,
      [СостояниеСобытияID]         BINARY(16)       NULL,
      [ТипСобытияID]               BINARY(16)       NULL,
      [ТелефонМобильный]           NVARCHAR(15)     NULL,
      [ДатаСледующегоСобытия]      DATETIME2        NULL,
      [ВидСледующегоСобытияID]     BINARY(16)       NULL
);
GO

INSERT INTO [mis].[Bronze_Документы.События]
(
    ID, ПометкаУдаления, Дата, Проведен, Номер,
    СтатусыТелефонногоЗвонкаID, ДатаСоздания,
    ДатаПроведения, АвторID, КонтрагентID,
    КредитID, ВидСобытияID, ОписаниеСобытия,
    ОтветственныйID, ПроектID, СодержаниеСобытия, 
	СостояниеСобытияID, ТипСобытияID, ТелефонМобильный,
    ДатаСледующегоСобытия, ВидСледующегоСобытияID
)
SELECT
    [_IDRRef]        AS ID,
    [_Marked]        AS ПометкаУдаления,
    [_Date_Time]     AS Дата,
    [_Posted]        AS Проведен,
    [_Number]        AS Номер,
    [_Fld21336RRef]  AS СтатусыТелефонногоЗвонкаID,
    [_Fld8291]       AS ДатаСоздания,
    [_Fld21450]      AS ДатаПроведения,
    [_Fld5684RRef]   AS АвторID,
    [_Fld5676_RRRef] AS КонтрагентID,
    [_Fld5677RRef]   AS КредитID,
    [_Fld5690RRef]   AS ВидСобытияID,
    [_Fld5681]       AS ОписаниеСобытия,
    REPLACE(CONVERT(varchar(34), [_Fld5683RRef], 1), '0x', '') AS ОтветственныйID,
    [_Fld5692RRef]   AS ПроектID,
    [_Fld5682]       AS СодержаниеСобытия,
    [_Fld5675RRef]   AS СостояниеСобытияID,
    [_Fld5691RRef]   AS ТипСобытияID,
    [_Fld12268]      AS ТелефонМобильный,
    [_Fld13144]      AS ДатаСледующегоСобытия,
    [_Fld13147RRef]  AS ВидСледующегоСобытияID

FROM [Microinvest_Copy_Full].[dbo].[_Document5671]
WHERE [_Date_Time] >= '2015-01-01';