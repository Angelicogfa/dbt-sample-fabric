WITH data AS (
    SELECT *
    FROM {{ ref ('int_dim_rate_code') }}
)
SELECT 
    rate_code_id,
    rate_code_name,
    is_airport_trip
FROM data
ORDER BY rate_code_id