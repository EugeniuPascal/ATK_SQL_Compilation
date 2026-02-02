USE [ATK];
SET NOCOUNT ON;
SET XACT_ABORT ON;


IF OBJECT_ID('mis.fn_WorkMinutesSigned_MonFri', 'FN') IS NOT NULL
    DROP FUNCTION mis.fn_WorkMinutesSigned_MonFri;
GO

CREATE FUNCTION mis.fn_WorkMinutesSigned_MonFri
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

    -- 1900-01-01 = Monday => 1=Mon..7=Sun (без DATEFIRST)
    DECLARE @WSD int = (DATEDIFF(day, CONVERT(date,'19000101'), @SD) % 7) + 1;
    DECLARE @WED int = (DATEDIFF(day, CONVERT(date,'19000101'), @ED) % 7) + 1;

    DECLARE @DayStart datetime2(0);
    DECLARE @DayEnd   datetime2(0);

    -- same day
    IF @SD = @ED
    BEGIN
        IF @WSD BETWEEN 1 AND 5
        BEGIN
            SET @DayStart = DATEADD(minute, @StartMinute, CAST(@SD AS datetime2(0)));
            SET @DayEnd   = DATEADD(minute, @EndMinute,   CAST(@SD AS datetime2(0)));

            DECLARE @From datetime2(0) = CASE WHEN @S > @DayStart THEN @S ELSE @DayStart END;
            DECLARE @To   datetime2(0) = CASE WHEN @E < @DayEnd   THEN @E ELSE @DayEnd   END;

            IF @To > @From
                SET @Minutes = DATEDIFF_BIG(second, @From, @To) / 60.0;
        END

        RETURN CAST(ROUND(@Minutes, 2) AS decimal(18,2)) * CAST(@Sign AS decimal(18,2));
    END

    -- start day (Mon-Fri)
    IF @WSD BETWEEN 1 AND 5
    BEGIN
        SET @DayStart = DATEADD(minute, @StartMinute, CAST(@SD AS datetime2(0)));
        SET @DayEnd   = DATEADD(minute, @EndMinute,   CAST(@SD AS datetime2(0)));

        DECLARE @From1 datetime2(0) = CASE WHEN @S > @DayStart THEN @S ELSE @DayStart END;
        IF @DayEnd > @From1
            SET @Minutes = @Minutes + (DATEDIFF_BIG(second, @From1, @DayEnd) / 60.0);
    END

    -- full days between (only weekdays)
    DECLARE @MStart date = DATEADD(day, 1, @SD);
    DECLARE @MEnd   date = DATEADD(day,-1, @ED);

    IF @MStart <= @MEnd
    BEGIN
        DECLARE @TotalDays int = DATEDIFF(day, @MStart, @MEnd) + 1;
        DECLARE @FullWeeks int = @TotalDays / 7;
        DECLARE @Rem      int = @TotalDays % 7;

        DECLARE @Weekdays int = @FullWeeks * 5;

        DECLARE @i int = 0;
        WHILE @i < @Rem
        BEGIN
            DECLARE @d date = DATEADD(day, @i, @MStart);
            DECLARE @wd int = (DATEDIFF(day, CONVERT(date,'19000101'), @d) % 7) + 1;
            IF @wd BETWEEN 1 AND 5 SET @Weekdays += 1;
            SET @i += 1;
        END

        SET @Minutes = @Minutes + (@Weekdays * (@EndMinute - @StartMinute));
    END

    -- end day (Mon-Fri)
    IF @WED BETWEEN 1 AND 5
    BEGIN
        SET @DayStart = DATEADD(minute, @StartMinute, CAST(@ED AS datetime2(0)));
        SET @DayEnd   = DATEADD(minute, @EndMinute,   CAST(@ED AS datetime2(0)));

        DECLARE @To2 datetime2(0) = CASE WHEN @E < @DayEnd THEN @E ELSE @DayEnd END;
        IF @To2 > @DayStart
            SET @Minutes = @Minutes + (DATEDIFF_BIG(second, @DayStart, @To2) / 60.0);
    END

    RETURN CAST(ROUND(@Minutes, 2) AS decimal(18,2)) * CAST(@Sign AS decimal(18,2));
END;
GO
