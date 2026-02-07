WITH data AS (
    SELECT *
    FROM {{ ref ('int_dim_time') }}
)
SELECT 
    time,
    hour,
    minute,
    time_24h,
    period_of_day,
    is_rush_hour
FROM data
ORDER BY time