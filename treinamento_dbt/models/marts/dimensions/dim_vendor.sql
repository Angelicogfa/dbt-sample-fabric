WITH data AS (
    SELECT *
    FROM {{ ref ('int_dim_vendor') }}
)
SELECT 
    vendor_id,
    vendor_name,
    vendor_abbreviation
FROM data
ORDER BY vendor_id