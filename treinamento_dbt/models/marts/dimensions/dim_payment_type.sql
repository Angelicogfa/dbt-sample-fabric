WITH data AS (
    SELECT *
    FROM {{ ref ('int_dim_payment_type') }}
)
SELECT 
    payment_type,
    payment_type_name
FROM data
ORDER BY payment_type