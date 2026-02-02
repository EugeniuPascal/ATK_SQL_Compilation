USE [ATK];
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID('mis.fn_WorkMinutesSigned', 'FN') IS NOT NULL
    DROP FUNCTION mis.fn_WorkMinutesSigned;
GO

CREATE FUNCTION mis.fn_WorkMinutesSigned
(
      @A           datetime2(0)
    , @B           datetime2(0)
    , @StartMinute int
    , @EndMinute   int
)
RETURNS decimal(18,2)
AS
BEGIN
    IF @A IS NULL OR @B IS NULL RETURN NULL;
    IF @StartMinute IS NULL OR @EndMinute IS NULL RETURN NULL;
    IF @EndMinute <= @StartMinute RETURN NULL;

    DECLARE @Sign int = CASE WHEN @B >= @A THEN 1 ELSE -1 END;
    DECLARE @S datetime2(0) = CASE WHEN @B >= @A THEN @A ELSE @B END;
    DECLARE @E datetime2(0) = CASE WHEN @B >= @A THEN @B ELSE @A END;

    IF @E <= @S RETURN NULL;

    DECLARE @SD date = CAST(@S AS date);
    DECLARE @ED date = CAST(@E AS date);

    DECLARE @Minutes float = 0.0;

    DECLARE @DayStart datetime2(0);
    DECLARE @DayEnd   datetime2(0);

    IF @SD = @ED
    BEGIN
        SET @DayStart = DATEADD(minute, @StartMinute, CAST(@SD AS datetime2(0)));
        SET @DayEnd   = DATEADD(minute, @EndMinute,   CAST(@SD AS datetime2(0)));

        DECLARE @From datetime2(0) = CASE WHEN @S > @DayStart THEN @S ELSE @DayStart END;
        DECLARE @To   datetime2(0) = CASE WHEN @E < @DayEnd   THEN @E ELSE @DayEnd   END;

        IF @To > @From
            SET @Minutes = DATEDIFF_BIG(second, @From, @To) / 60.0;
        ELSE
            SET @Minutes = 0.0;
    END
    ELSE
    BEGIN
        -- start day
        SET @DayStart = DATEADD(minute, @StartMinute, CAST(@SD AS datetime2(0)));
        SET @DayEnd   = DATEADD(minute, @EndMinute,   CAST(@SD AS datetime2(0)));

        DECLARE @From1 datetime2(0) = CASE WHEN @S > @DayStart THEN @S ELSE @DayStart END;
        IF @DayEnd > @From1
            SET @Minutes = @Minutes + (DATEDIFF_BIG(second, @From1, @DayEnd) / 60.0);

        -- full days between
        DECLARE @FullDays int = DATEDIFF(day, DATEADD(day, 1, @SD), @ED);
        IF @FullDays > 0
            SET @Minutes = @Minutes + (@FullDays * (@EndMinute - @StartMinute));

        -- end day
        SET @DayStart = DATEADD(minute, @StartMinute, CAST(@ED AS datetime2(0)));
        SET @DayEnd   = DATEADD(minute, @EndMinute,   CAST(@ED AS datetime2(0)));

        DECLARE @To2 datetime2(0) = CASE WHEN @E < @DayEnd THEN @E ELSE @DayEnd END;
        IF @To2 > @DayStart
            SET @Minutes = @Minutes + (DATEDIFF_BIG(second, @DayStart, @To2) / 60.0);
    END

    RETURN CAST(ROUND(@Minutes, 2) AS decimal(18,2)) * CAST(@Sign AS decimal(18,2));
END;
GO
