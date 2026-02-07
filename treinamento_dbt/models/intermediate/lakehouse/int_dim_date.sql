WITH source_data AS (
    SELECT *
    from {{ ref('stg_lakehouse__taxi') }}
    WHERE year(lpepPickupDatetime) <= 2019 OR year(lpepDropoffDatetime) <= 2019
),
date_bounds AS (
    SELECT 
        MIN(CAST(lpepPickupDatetime AS DATE)) AS min_date,
        MAX(CAST(lpepPickupDatetime AS DATE)) AS max_date
    FROM source_data
),
-- Number generator (0 to 9)
ten_rows AS (
    SELECT 1 AS n UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL
    SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
),
-- Multiplier to generate a large sequence of days
number_series AS (
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM ten_rows a
    CROSS JOIN ten_rows b
    CROSS JOIN ten_rows c
    CROSS JOIN ten_rows d
    CROSS JOIN ten_rows e
),
-- Intermediate CTE: Generates raw dates first
raw_dates AS (
    SELECT 
        CAST(DATEADD(DAY, ns.n, db.min_date) AS DATE) AS date_value
    FROM date_bounds db
    CROSS JOIN number_series ns
    WHERE ns.n <= DATEDIFF(DAY, db.min_date, db.max_date)
)
-- FINAL SELECT: Calculates all time dimensions
SELECT 
    date_value AS date,
    
    -- Basic Information
    YEAR(date_value) AS year,
    MONTH(date_value) AS month,
    DAY(date_value) AS day_of_month,
    
    -- Text Formatting (Depends on server language settings, e.g., 'January')
    CAST(DATENAME(MONTH, date_value) AS VARCHAR(20)) AS month_name,
    CAST(LEFT(DATENAME(MONTH, date_value), 3) AS VARCHAR(3)) AS month_name_abbrev,
    CAST(DATENAME(WEEKDAY, date_value) AS VARCHAR(20)) AS day_of_week_name,
    CAST(LEFT(DATENAME(WEEKDAY, date_value), 3) AS VARCHAR(3)) AS day_of_week_abbrev,
    
    -- Day of Week Number (1 to 7). Note: Depends on SET DATEFIRST
    DATEPART(WEEKDAY, date_value) AS day_of_week_num,
    
    -- Weekend Indicator
    -- Note: Ensure your session is in English or adjust 'Saturday'/'Sunday' accordingly
    CASE 
        WHEN DATENAME(WEEKDAY, date_value) IN ('Saturday', 'Sunday') THEN 1 
        ELSE 0 
    END AS is_weekend,

    -- Quarter
    DATEPART(QUARTER, date_value) AS quarter,
    CAST(YEAR(date_value) AS VARCHAR(4)) + '-Q' + CAST(DATEPART(QUARTER, date_value) AS VARCHAR(1)) AS year_quarter, -- Ex: 2019-Q1

    -- Bimester (Math: (Month-1)/2 + 1)
    ((MONTH(date_value) - 1) / 2) + 1 AS bimester,
    
    -- Semester
    CASE WHEN MONTH(date_value) <= 6 THEN 1 ELSE 2 END AS semester,
    CAST(YEAR(date_value) AS VARCHAR(4)) + '-S' + CAST(CASE WHEN MONTH(date_value) <= 6 THEN 1 ELSE 2 END AS VARCHAR(1)) AS year_semester, -- Ex: 2019-S1

    -- Fortnight (Rule: Day <= 15 is the 1st fortnight)
    CASE WHEN DAY(date_value) <= 15 THEN 1 ELSE 2 END AS fortnight,
    
    -- Day of Year (1 to 365/366)
    DATEPART(DAYOFYEAR, date_value) AS day_of_year,
    
    -- Week of Year (1 to 53)
    DATEPART(WEEK, date_value) AS week_of_year

FROM raw_dates