WITH data AS (
    SELECT *
    FROM {{ ref ('int_dim_location') }}
)
SELECT 
    location_id,
    sk_location_id
FROM data
ORDER BY location_id