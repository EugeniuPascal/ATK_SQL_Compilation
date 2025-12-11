USE [ATK];
GO

IF OBJECT_ID('mis.[Gold_Fact_Comments]', 'U') IS NOT NULL
    DROP TABLE mis.[Gold_Fact_Comments];
GO

CREATE TABLE mis.[Gold_Fact_Comments]
(
    CommentID VARCHAR(36) NOT NULL PRIMARY KEY,
    AllComments NVARCHAR(MAX) NULL
);
GO

SELECT 
    [КомментарийКУсловиямПослеВыдачи ИД] AS CommentID,
    CONVERT(VARCHAR(10), [КомментарийКУсловиямПослеВыдачи Период], 120) AS Period,
    [КомментарийКУсловиямПослеВыдачи Исполнитель] AS Executor,
    [КомментарийКУсловиямПослеВыдачи Комментарий] AS Comment
INTO #FilteredComments
FROM [ATK].[dbo].[РегистрыСведений.КомментарийКУсловиямПослеВыдачи]
WHERE [КомментарийКУсловиямПослеВыдачи Объект Tип] = '08'
  AND [КомментарийКУсловиямПослеВыдачи Клиент] IS NOT NULL;
GO

INSERT INTO mis.[Gold_Fact_Comments] (CommentID, AllComments)
SELECT 
    fc1.CommentID,
    STUFF(
        (
            SELECT CHAR(13) + CHAR(10) +
                   CONCAT(fc2.Period, ' ', fc2.Executor, ': ', fc2.Comment)
            FROM #FilteredComments fc2
            WHERE fc2.CommentID = fc1.CommentID
            ORDER BY fc2.Period
            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 2, ''
    ) AS AllComments
FROM (SELECT DISTINCT CommentID FROM #FilteredComments) fc1;
GO

DROP TABLE #FilteredComments;
GO
