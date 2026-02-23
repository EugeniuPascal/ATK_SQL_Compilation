CREATE TABLE mis.[Silver_Proc_Exec_Log]
(
    ProcedureName NVARCHAR(255),
    TableName NVARCHAR(255),
    StartTime DATETIME,
    EndTime DATETIME,
    Status NVARCHAR(50), -- 'Running', 'Success', 'Failed'

    -- Computed column for execution duration in h, min, sec
    Duration AS (
        CASE 
            WHEN DATEDIFF(SECOND, StartTime, EndTime) < 60 THEN 
                CAST(DATEDIFF(SECOND, StartTime, EndTime) AS NVARCHAR(10)) + 'sec'
            WHEN DATEDIFF(SECOND, StartTime, EndTime) < 3600 THEN 
                CAST(DATEDIFF(MINUTE, StartTime, EndTime) AS NVARCHAR(10)) + 'min ' +
                CAST(DATEDIFF(SECOND, StartTime, EndTime) % 60 AS NVARCHAR(10)) + 'sec'
            ELSE
                CAST(DATEDIFF(HOUR, StartTime, EndTime) AS NVARCHAR(10)) + 'h ' +
                CAST(DATEDIFF(MINUTE, StartTime, EndTime) % 60 AS NVARCHAR(10)) + 'min ' +
                CAST(DATEDIFF(SECOND, StartTime, EndTime) % 60 AS NVARCHAR(10)) + 'sec'
        END
    ) PERSISTED,

    -- Automatic insertion timestamp
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE()
);